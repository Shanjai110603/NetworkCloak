use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::os::windows::io::FromRawHandle;
use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;
use serde_json::Value;
use windows::core::PCWSTR;
use windows::Win32::System::Pipes::*;
use windows::Win32::Storage::FileSystem::*;

pub struct IpcServer {
    tx_events: Sender<Value>,
    rx_events: Arc<Mutex<Receiver<Value>>>,
}

impl IpcServer {
    pub fn new() -> Self {
        let (tx, rx) = channel();
        Self {
            tx_events: tx,
            rx_events: Arc::new(Mutex::new(rx)),
        }
    }

    pub fn get_event_sender(&self) -> Sender<Value> {
        self.tx_events.clone()
    }

    pub fn start<F>(&self, on_command: F)
    where
        F: Fn(Value) + Send + Sync + 'static + Clone,
    {
        let rx_events_clone = self.rx_events.clone();
        thread::spawn(move || {
            let pipe_name = windows::core::w!("\\\\.\\pipe\\network_cloak_pipe");

            loop {
                unsafe {
                    // Create Named Pipe instance
                    let pipe_handle = CreateNamedPipeW(
                        PCWSTR(pipe_name.as_ptr()),
                        PIPE_ACCESS_DUPLEX,
                        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
                        1, // Max instances
                        65536,
                        65536,
                        0,
                        None,
                    );

                    if pipe_handle.is_invalid() {
                        thread::sleep(std::time::Duration::from_secs(1));
                        continue;
                    }

                    // Wait for client to connect
                    let connected = ConnectNamedPipe(pipe_handle, None).is_ok()
                        || (windows::Win32::Foundation::GetLastError() == windows::Win32::Foundation::ERROR_PIPE_CONNECTED);

                    if connected {
                        // Create File wrapper around the pipe handle
                        let file = File::from_raw_handle(pipe_handle.0 as *mut _);
                        let file_writer = Arc::new(Mutex::new(file.try_clone().unwrap()));
                        let reader = BufReader::new(file);

                        // Start writer thread to push events to client
                        let rx = rx_events_clone.clone();
                        let writer_handle = file_writer.clone();
                        thread::spawn(move || {
                            let rx_lock = rx.lock().unwrap();
                            while let Ok(event) = rx_lock.recv() {
                                let serialized = serde_json::to_string(&event).unwrap_or_default();
                                let mut w = writer_handle.lock().unwrap();
                                if writeln!(w, "{}", serialized).is_err() {
                                    break; // Pipe closed
                                }
                                let _ = w.flush();
                            }
                        });

                        // Read commands in current thread
                        let on_cmd = on_command.clone();
                        for line in reader.lines() {
                            if let Ok(l) = line {
                                if let Ok(val) = serde_json::from_str::<Value>(&l) {
                                    on_cmd(val);
                                }
                            } else {
                                break; // Pipe disconnected
                            }
                        }
                    }

                    // Close the pipe instance and prepare for next client connection
                    let _ = DisconnectNamedPipe(pipe_handle);
                    let _ = windows::Win32::Foundation::CloseHandle(pipe_handle);
                }
            }
        });
    }
}
