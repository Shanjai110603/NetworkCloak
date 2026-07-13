use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;
use serde_json::json;
use windows::Win32::Networking::WinSock::AF_INET;
use windows::Win32::NetworkManagement::IpHelper::*;
use crate::process_mapper::{get_process_path, get_filename};

/// Periodically polls TCP and UDP connection tables, maps processes,
/// and sends live connection logs back to the main IPC channel.
pub fn start_monitor(tx: Sender<serde_json::Value>) {
    thread::spawn(move || {
        loop {
            if let Ok(connections) = get_active_connections() {
                for conn in connections {
                    let _ = tx.send(conn);
                }
            }
            thread::sleep(Duration::from_millis(1000));
        }
    });
}

fn get_active_connections() -> Result<Vec<serde_json::Value>, String> {
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

                connections.push(json!({
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
                }));
            }
        }
    }

    Ok(connections)
}
