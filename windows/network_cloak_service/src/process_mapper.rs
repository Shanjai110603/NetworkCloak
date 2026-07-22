use std::collections::HashMap;
use std::sync::Mutex;
use windows::Win32::Foundation::*;
use windows::Win32::System::Threading::*;
use windows::core::PWSTR;

lazy_static::lazy_static! {
    static ref PATH_CACHE: Mutex<HashMap<u32, String>> = Mutex::new(HashMap::new());
}

/// Resolves a PID to its full executable path.
/// Uses an in-memory cache to minimize process handle opening.
pub fn get_process_path(pid: u32) -> String {
    if pid == 0 {
        return "System Idle Process".to_string();
    }
    if pid == 4 {
        return "System".to_string();
    }

    {
        let cache = PATH_CACHE.lock().unwrap();
        if let Some(path) = cache.get(&pid) {
            return path.clone();
        }
    }

    let path = resolve_process_path(pid);
    let mut cache = PATH_CACHE.lock().unwrap();
    cache.insert(pid, path.clone());
    path
}

fn resolve_process_path(pid: u32) -> String {
    unsafe {
        let handle = match OpenProcess(
            PROCESS_QUERY_LIMITED_INFORMATION,
            FALSE,
            pid,
        ) {
            Ok(h) => h,
            Err(_) => return format!("Process.{}", pid),
        };

        let mut buf = vec![0u16; 1024];
        let mut len = buf.len() as u32;
        let success = QueryFullProcessImageNameW(
            handle,
            PROCESS_NAME_FORMAT(0),
            PWSTR(buf.as_mut_ptr()),
            &mut len,
        );

        let _ = CloseHandle(handle);

        if success.is_ok() {
            String::from_utf16_lossy(&buf[..len as usize])
        } else {
            format!("Process.{}", pid)
        }
    }
}

/// Helper to get the filename (e.g. "chrome.exe") from an absolute path.
pub fn get_filename(path: &str) -> String {
    path.split('\\')
        .last()
        .unwrap_or(path)
        .to_string()
}

/// Lists full paths of all running processes matching the target filename.
pub fn find_paths_by_name(target_name: &str) -> Vec<String> {
    use windows::Win32::System::Diagnostics::ToolHelp::*;

    let mut paths = Vec::new();
    unsafe {
        let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if let Ok(snap) = snapshot {
            let mut entry = PROCESSENTRY32W::default();
            entry.dwSize = std::mem::size_of::<PROCESSENTRY32W>() as u32;

            if Process32FirstW(snap, &mut entry).is_ok() {
                loop {
                    // Extract name from null-terminated wide string
                    let end = entry.szExeFile.iter().position(|&c| c == 0).unwrap_or(entry.szExeFile.len());
                    let name = String::from_utf16_lossy(&entry.szExeFile[..end]);
                    if name.eq_ignore_ascii_case(target_name) {
                        let path = resolve_process_path(entry.th32ProcessID);
                        if !path.starts_with("Process.") {
                            paths.push(path);
                        }
                    }
                    if !Process32NextW(snap, &mut entry).is_ok() {
                        break;
                    }
                }
            }
            let _ = CloseHandle(snap);
        }
    }
    paths.sort();
    paths.dedup();
    paths
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_dedup_paths_removes_non_adjacent_duplicates() {
        let mut paths = vec![
            "C:\\App\\chrome.exe".to_string(),
            "C:\\Program Files\\chrome.exe".to_string(),
            "C:\\App\\chrome.exe".to_string(),
        ];
        paths.sort();
        paths.dedup();
        assert_eq!(paths.len(), 2);
        assert_eq!(paths[0], "C:\\App\\chrome.exe");
        assert_eq!(paths[1], "C:\\Program Files\\chrome.exe");
    }
}
