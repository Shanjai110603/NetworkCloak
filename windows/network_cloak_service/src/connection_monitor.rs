use std::collections::HashSet;
use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;
use serde_json::json;
use windows::Win32::Networking::WinSock::AF_INET;
use windows::Win32::NetworkManagement::IpHelper::*;
use crate::process_mapper::{get_process_path, get_filename};

pub type ConnectionKey = (u32, String, u16);

/// Periodically polls TCP connection tables, maps processes,
/// and sends live connection logs back to the main IPC channel.
pub fn start_monitor(tx: Sender<serde_json::Value>) {
    thread::spawn(move || {
        let mut seen = HashSet::<ConnectionKey>::new();
        loop {
            if let Ok(entries) = get_active_connections() {
                let (new_events, new_seen) = compute_new_events(&seen, entries);
                for conn in new_events {
                    let _ = tx.send(conn);
                }
                seen = new_seen;
            }
            thread::sleep(Duration::from_millis(1000));
        }
    });
}

pub fn compute_new_events(
    previous_seen: &HashSet<ConnectionKey>,
    current_entries: Vec<(serde_json::Value, ConnectionKey)>,
) -> (Vec<serde_json::Value>, HashSet<ConnectionKey>) {
    let mut new_events = Vec::new();
    let mut new_seen = HashSet::new();
    for (event, key) in current_entries {
        if !previous_seen.contains(&key) {
            new_events.push(event);
        }
        new_seen.insert(key);
    }
    (new_events, new_seen)
}

fn get_active_connections() -> Result<Vec<(serde_json::Value, ConnectionKey)>, String> {
    let mut connections = Vec::new();

    // ── TCP Connections ──────────────────────────────────────
    let mut size: u32 = 0;
    unsafe {
        GetExtendedTcpTable(
            None,
            &mut size,
            false,
            AF_INET.0 as u32,
            TCP_TABLE_OWNER_PID_ALL,
            0,
        );
    }

    if size > 0 {
        let mut buffer = vec![0u8; size as usize];
        let status = unsafe {
            GetExtendedTcpTable(
                Some(buffer.as_mut_ptr() as *mut _),
                &mut size,
                false,
                AF_INET.0 as u32,
                TCP_TABLE_OWNER_PID_ALL,
                0,
            )
        };

        if status == 0 {
            let table_ptr = buffer.as_ptr() as *const MIB_TCPTABLE_OWNER_PID;
            let num_entries = unsafe { (*table_ptr).dwNumEntries as usize };
            let rows_ptr = unsafe { std::ptr::addr_of!((*table_ptr).table) as *const MIB_TCPROW_OWNER_PID };

            for i in 0..num_entries {
                let row = unsafe { &*rows_ptr.add(i) };
                
                // State 5 is ESTABLISHED
                if row.dwState != 5 {
                    continue;
                }

                let remote_ip = std::net::Ipv4Addr::from(u32::from_be(row.dwRemoteAddr));
                let remote_port = u16::from_be(row.dwRemotePort as u16);
                let pid = row.dwOwningPid;

                // Ignore localhost connections to avoid cluttering logs
                if remote_ip.is_loopback() || remote_ip.is_unspecified() {
                    continue;
                }

                let path = get_process_path(pid);
                let name = get_filename(&path);

                let key: ConnectionKey = (pid, remote_ip.to_string(), remote_port);
                let event = json!({
                    "type": "ConnectionEvent",
                    "uid": pid, // on Windows we use PID as UID
                    "appId": name,
                    "destHost": remote_ip.to_string(),
                    "destIp": remote_ip.to_string(),
                    "port": remote_port,
                    "protocol": "TCP",
                    "bytes": 0, // detailed bytes require driver, user-mode defaults to 0
                    "allowed": true,
                    "timestamp": json!(std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_millis() as u64)
                });
                connections.push((event, key));
            }
        }
    }

    Ok(connections)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_new_events_suppresses_duplicates() {
        let key1: ConnectionKey = (1234, "8.8.8.8".to_string(), 443);
        let key2: ConnectionKey = (5678, "1.1.1.1".to_string(), 80);

        let entries1 = vec![
            (json!({"conn": 1}), key1.clone()),
            (json!({"conn": 2}), key2.clone()),
        ];

        let mut seen = HashSet::new();
        let (new_events1, new_seen1) = compute_new_events(&seen, entries1);
        assert_eq!(new_events1.len(), 2);
        assert_eq!(new_seen1.len(), 2);

        // Next poll with same active connections
        seen = new_seen1;
        let entries2 = vec![
            (json!({"conn": 1}), key1.clone()),
            (json!({"conn": 2}), key2.clone()),
        ];
        let (new_events2, _) = compute_new_events(&seen, entries2);
        assert_eq!(new_events2.len(), 0, "Duplicate active connections must be suppressed");
    }
}
