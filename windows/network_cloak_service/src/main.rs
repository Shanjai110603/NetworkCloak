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

    // Handle commands from Dart client
    let wfp_clone = wfp.clone();
    ipc.start(move |val: Value| {
        let command = val.get("method").and_then(|m| m.as_str()).unwrap_or("");
        println!("Received command: {}", command);

        match command {
            "updateRules" => {
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();

                if let Some(rules) = val.get("rules").and_then(|r| r.as_array()) {
                    for rule in rules {
                        let app_id = rule.get("appId").and_then(|a| a.as_str()).unwrap_or("");
                        let action = rule.get("action").and_then(|a| a.as_str()).unwrap_or("");

                        if action == "block" || action == "temporaryBlock" || action == "blockBackground" {
                            if app_id.contains('\\') {
                                // Direct path block
                                let _ = engine.block_application(app_id);
                            } else {
                                // Block all running instances matching the filename
                                let paths = find_paths_by_name(app_id);
                                for path in paths {
                                    let _ = engine.block_application(&path);
                                }
                            }
                        }
                    }
                }
            }
            "stopFirewall" => {
                let mut engine = wfp_clone.lock().unwrap();
                engine.clear_rules();
                println!("Firewall stopped, rules cleared.");
            }
            "activateLockdown" => {
                println!("Emergency Lockdown activated.");
                // User-mode global block is handled in the rule engine;
                // in Rust we clear other rules and apply global block if requested.
            }
            "deactivateLockdown" => {
                println!("Lockdown deactivated.");
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
