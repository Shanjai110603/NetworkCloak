use std::sync::{Arc, Mutex};
use serde_json::Value;

mod process_mapper;
mod wfp_adapter;
mod connection_monitor;
mod ipc_server;

use wfp_adapter::WfpEngine;
use ipc_server::IpcServer;
use connection_monitor::start_monitor;
use process_mapper::find_paths_by_name;

fn main() {
    println!("Network Cloak Background Service starting...");

    // Initialize WFP engine
    let wfp = match WfpEngine::new() {
        Ok(engine) => Arc::new(Mutex::new(engine)),
        Err(e) => {
            eprintln!("Initialization failed: {}", e);
            return;
        }
    };

    println!("WFP Engine initialized successfully.");

    // Initialize Named Pipe IPC Server
    let ipc = IpcServer::new();
    let tx_events = ipc.get_event_sender();

    // Start polling TCP connections and sending events back to Dart client
    start_monitor(tx_events);
    println!("Connection monitor started.");

    // Shared active blocked filenames and already-blocked paths (Item 18 fix)
    // Note on Windows architecture vs Android UID:
    // Windows process name blocking requires dynamic path re-resolution because
    // Windows lacks persistent per-app UIDs across process restarts. WFP application
    // filters bind to full executable disk paths, so a periodic background scan re-resolves
    // blocked filenames to newly launched process paths every 3 seconds.
    let active_blocked_filenames = Arc::new(Mutex::new(Vec::<String>::new()));
    let blocked_paths = Arc::new(Mutex::new(std::collections::HashSet::<String>::new()));

    // Periodic scanner thread for newly launched process instances (Item 18)
    let wfp_scan_clone = wfp.clone();
    let scan_filenames = active_blocked_filenames.clone();
    let scan_blocked_paths = blocked_paths.clone();
    std::thread::spawn(move || {
        loop {
            std::thread::sleep(std::time::Duration::from_secs(3));
            let filenames = {
                let guard = scan_filenames.lock().unwrap();
                guard.clone()
            };
            if filenames.is_empty() {
                continue;
            }
            for app_filename in filenames {
                let paths = find_paths_by_name(&app_filename);
                let mut engine = wfp_scan_clone.lock().unwrap();
                let mut path_set = scan_blocked_paths.lock().unwrap();
                for path in paths {
                    if !path_set.contains(&path) {
                        if engine.block_application(&path).is_ok() {
                            path_set.insert(path);
                        }
                    }
                }
            }
        }
    });

    // Handle commands from Dart client
    let wfp_clone = wfp.clone();
    let active_fn_clone = active_blocked_filenames.clone();
    let blocked_paths_clone = blocked_paths.clone();
    ipc.start(move |val: Value| {
        let command = val.get("method").and_then(|m| m.as_str()).unwrap_or("");
        println!("Received command: {}", command);

        match command {
            "updateRules" => {
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();
                let mut active_fn_guard = active_fn_clone.lock().unwrap();
                let mut path_set_guard = blocked_paths_clone.lock().unwrap();
                active_fn_guard.clear();
                path_set_guard.clear();

                if let Some(rules) = val.get("rules").and_then(|r| r.as_array()) {
                    for rule in rules {
                        let app_id = rule.get("appId").and_then(|a| a.as_str()).unwrap_or("");
                        let action = rule.get("action").and_then(|a| a.as_str()).unwrap_or("");

                        if action == "block" || action == "temporaryBlock" || action == "blockBackground" || action == "ask" {
                            if app_id.contains('\\') {
                                // Direct path block
                                if engine.block_application(app_id).is_ok() {
                                    path_set_guard.insert(app_id.to_string());
                                }
                            } else if !app_id.is_empty() {
                                active_fn_guard.push(app_id.to_string());
                                let paths = find_paths_by_name(app_id);
                                for path in paths {
                                    if engine.block_application(&path).is_ok() {
                                        path_set_guard.insert(path);
                                    }
                                }
                            }
                        }
                    }
                }

                if val.get("blockLan").and_then(|b| b.as_bool()).unwrap_or(false) {
                    let _ = engine.block_remote_ports(&[137, 138, 139, 445]);
                    println!("LAN Exposure blocked (NetBIOS/SMB ports 137-139, 445)");
                }
            }
            "stopFirewall" => {
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();
                active_fn_clone.lock().unwrap().clear();
                blocked_paths_clone.lock().unwrap().clear();
                println!("Firewall stopped, rules cleared.");
            }
            "activateLockdown" => {
                println!("Emergency Lockdown activated.");
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();
                active_fn_clone.lock().unwrap().clear();
                blocked_paths_clone.lock().unwrap().clear();
                let _ = engine.block_all_outbound();
            }
            "deactivateLockdown" => {
                println!("Lockdown deactivated.");
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();
                active_fn_clone.lock().unwrap().clear();
                blocked_paths_clone.lock().unwrap().clear();
            }
            _ => {
                println!("Unknown command: {}", command);
            }
        }
    });

    println!("Named Pipe server listening at \\\\.\\pipe\\network_cloak_pipe");

    // Keep the main thread alive
    loop {
        std::thread::sleep(std::time::Duration::from_secs(60));
    }
}
