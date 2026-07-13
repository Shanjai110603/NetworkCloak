use std::ptr;
use windows::core::{GUID, PCWSTR, PWSTR};
use windows::Win32::Foundation::*;
use windows::Win32::NetworkManagement::WindowsFilteringPlatform::*;
use windows::Win32::System::Rpc::RPC_C_AUTHN_DEFAULT;

// A unique sublayer GUID for Network Cloak rules
const NETWORK_CLOAK_SUBLAYER: GUID = GUID::from_u128(0x9a8f27e1_2e4b_4f5a_ba89_8c30ad1bfd4f);

pub struct WfpEngine {
    engine_handle: HANDLE,
    active_filters: Vec<u64>,
}

// Mark WfpEngine thread-safe so it can be used inside Mutex
unsafe impl Send for WfpEngine {}
unsafe impl Sync for WfpEngine {}

impl WfpEngine {
    pub fn new() -> Result<Self, String> {
        unsafe {
            let mut engine_handle = HANDLE::default();
            // Open user-mode engine session
            let status = FwpmEngineOpen0(
                None,
                RPC_C_AUTHN_DEFAULT as u32,
                None,
                None,
                &mut engine_handle,
            );

            if status != 0 {
                return Err(format!("FwpmEngineOpen0 failed: ERROR 0x{:X}", status));
            }

            // Create our custom sublayer so our rules take precedence
            let mut sublayer = FWPM_SUBLAYER0::default();
            sublayer.subLayerKey = NETWORK_CLOAK_SUBLAYER;
            sublayer.displayData.name = PWSTR(windows::core::w!("Network Cloak Sublayer").as_ptr() as *mut _);
            sublayer.weight = 0xFFFF; // Highest user-mode weight

            let status = FwpmSubLayerAdd0(engine_handle, &sublayer, None);
            if status != 0 && status != 0x80320010 { // 0x80320010 is FWP_E_ALREADY_EXISTS
                let _ = FwpmEngineClose0(engine_handle);
                return Err(format!("FwpmSubLayerAdd0 failed: ERROR 0x{:X}", status));
            }

            Ok(Self {
                engine_handle,
                active_filters: Vec::new(),
            })
        }
    }

    /// Add a rule to block all outbound connections for a specific application path.
    pub fn block_application(&mut self, app_path: &str) -> Result<(), String> {
        let app_path_w: Vec<u16> = app_path.encode_utf16().chain(Some(0)).collect();

        unsafe {
            let mut app_id_ptr: *mut FWP_BYTE_BLOB = ptr::null_mut();
            let status = FwpmGetAppIdFromFileName0(
                PCWSTR(app_path_w.as_ptr()),
                &mut app_id_ptr,
            );

            if status != 0 || app_id_ptr.is_null() {
                return Err(format!("FwpmGetAppIdFromFileName0 failed: ERROR 0x{:X}", status));
            }

            // Add filter for IPv4 ALE Connect layer
            if let Err(e) = self.add_block_filter(app_id_ptr, FWPM_LAYER_ALE_AUTH_CONNECT_V4) {
                let _ = FwpmFreeMemory0(&mut (app_id_ptr as *mut std::ffi::c_void));
                return Err(e);
            }

            // Add filter for IPv6 ALE Connect layer
            if let Err(e) = self.add_block_filter(app_id_ptr, FWPM_LAYER_ALE_AUTH_CONNECT_V6) {
                let _ = FwpmFreeMemory0(&mut (app_id_ptr as *mut std::ffi::c_void));
                return Err(e);
            }

            let _ = FwpmFreeMemory0(&mut (app_id_ptr as *mut std::ffi::c_void));
            Ok(())
        }
    }

    unsafe fn add_block_filter(&mut self, app_id_ptr: *mut FWP_BYTE_BLOB, layer_guid: GUID) -> Result<(), String> {
        let mut condition = FWPM_FILTER_CONDITION0::default();
        condition.fieldKey = FWPM_CONDITION_ALE_APP_ID;
        condition.matchType = FWP_MATCH_EQUAL;
        condition.conditionValue.r#type = FWP_BYTE_BLOB_TYPE;
        condition.conditionValue.Anonymous.byteBlob = app_id_ptr;

        let mut filter = FWPM_FILTER0::default();
        filter.displayData.name = PWSTR(windows::core::w!("Network Cloak Block Rule").as_ptr() as *mut _);
        filter.layerKey = layer_guid;
        filter.subLayerKey = NETWORK_CLOAK_SUBLAYER;
        filter.weight.r#type = FWP_EMPTY; // Auto-weight
        filter.numFilterConditions = 1;
        filter.filterCondition = &mut condition;
        filter.action.r#type = FWP_ACTION_BLOCK;

        let mut filter_id: u64 = 0;
        let status = FwpmFilterAdd0(
            self.engine_handle,
            &filter,
            None,
            Some(&mut filter_id),
        );

        if status != 0 {
            return Err(format!("FwpmFilterAdd0 failed for layer: ERROR 0x{:X}", status));
        }

        self.active_filters.push(filter_id);
        Ok(())
    }

    /// Clear all active filters added by this service.
    pub fn clear_rules(&mut self) {
        unsafe {
            for filter_id in self.active_filters.drain(..) {
                let _ = FwpmFilterDeleteById0(self.engine_handle, filter_id);
            }
        }
    }
}

impl Drop for WfpEngine {
    fn drop(&mut self) {
        self.clear_rules();
        unsafe {
            let _ = FwpmEngineClose0(self.engine_handle);
        }
    }
}
