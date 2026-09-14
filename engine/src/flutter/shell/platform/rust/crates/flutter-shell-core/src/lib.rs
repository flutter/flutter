//! Private Rust runtime core for the in-tree Flutter Rust shell.
//!
//! Its C ABI is intentionally small and lockstep-versioned with this Flutter
//! fork. Plugins use `flutter-plugin-sdk`, never this crate directly.

// This crate owns the private C ABI, so exporting fixed C symbols is required.
// Keep unsafe operations forbidden by lint even though the `no_mangle` ABI
// attribute is explicitly marked unsafe in Rust edition 2024.
#![deny(unsafe_op_in_unsafe_fn)]

use std::ffi::c_void;

/// Version of the private Rust/C++ ABI.
pub const SHELL_ABI_VERSION: u32 = 10;
/// Plugin SDK API version expected by this lockstep private runtime.
pub const PLUGIN_SDK_API_VERSION: u32 = 1;

/// Engine-scoped identity of one Flutter view/native window pair.
#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct FlutterRustViewId(pub i64);

impl FlutterRustViewId {
    pub const IMPLICIT: Self = Self(0);
}

/// Physical viewport and display metrics for one Flutter view.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlutterRustViewMetrics {
    pub width: f64,
    pub height: f64,
    pub min_width: f64,
    pub max_width: f64,
    pub min_height: f64,
    pub max_height: f64,
    pub pixel_ratio: f64,
    pub display_width: f64,
    pub display_height: f64,
    pub display_refresh_rate: f64,
}

/// Completion callback for asynchronous add/remove-view operations.
#[repr(C)]
pub struct FlutterRustViewOperationCallbacks {
    pub user_data: *mut c_void,
    pub complete: Option<extern "C" fn(*mut c_void, FlutterRustViewId, i32)>,
}

/// Synchronous regular-window request issued by Flutter's WindowController.
#[repr(C)]
pub struct FlutterRustRegularWindowRequest {
    pub has_size: i32,
    pub width: f64,
    pub height: f64,
    pub title: *const u8,
    pub title_length: u64,
    pub resizable: i32,
    pub has_constraints: i32,
    pub min_width: f64,
    pub min_height: f64,
    pub max_width: f64,
    pub max_height: f64,
}

/// Synchronous dialog-window request issued by Flutter's WindowController.
#[repr(C)]
pub struct FlutterRustDialogWindowRequest {
    pub window: FlutterRustRegularWindowRequest,
    pub has_parent: i32,
    pub parent_view_id: FlutterRustViewId,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustPopupWindowKind {
    Tooltip = 0,
    Popup = 1,
}

/// Synchronous compositor-positioned child-window request.
#[repr(C)]
pub struct FlutterRustPopupWindowRequest {
    pub kind: i32,
    pub parent_view_id: FlutterRustViewId,
    pub min_width: f64,
    pub min_height: f64,
    pub max_width: f64,
    pub max_height: f64,
    pub anchor_x: f64,
    pub anchor_y: f64,
    pub anchor_width: f64,
    pub anchor_height: f64,
    pub parent_anchor: i32,
    pub child_anchor: i32,
    pub offset_x: f64,
    pub offset_y: f64,
    pub constraint_adjustment: u32,
}

/// Synchronous persistent auxiliary-window request.
#[repr(C)]
pub struct FlutterRustSatelliteWindowRequest {
    pub window: FlutterRustRegularWindowRequest,
    pub parent_view_id: FlutterRustViewId,
    pub has_anchor_rect: i32,
    pub anchor_x: f64,
    pub anchor_y: f64,
    pub anchor_width: f64,
    pub anchor_height: f64,
    pub parent_anchor: i32,
    pub child_anchor: i32,
    pub offset_x: f64,
    pub offset_y: f64,
    pub constraint_adjustment: u32,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlutterRustWindowState {
    pub width: f64,
    pub height: f64,
    pub focused: i32,
    pub maximized: i32,
    pub minimized: i32,
    pub fullscreen: i32,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustWindowEvent {
    StateChanged = 0,
    CloseRequested = 1,
    Destroyed = 2,
}

pub type FlutterRustWindowEventCallback = extern "C" fn(FlutterRustViewId, FlutterRustWindowEvent);

#[repr(C)]
pub struct FlutterRustWindowingCallbacks {
    pub user_data: *mut c_void,
    pub create_regular_window: Option<
        extern "C" fn(*mut c_void, *const FlutterRustRegularWindowRequest) -> FlutterRustViewId,
    >,
    pub create_dialog_window: Option<
        extern "C" fn(*mut c_void, *const FlutterRustDialogWindowRequest) -> FlutterRustViewId,
    >,
    pub create_popup_window: Option<
        extern "C" fn(*mut c_void, *const FlutterRustPopupWindowRequest) -> FlutterRustViewId,
    >,
    pub create_satellite_window: Option<
        extern "C" fn(*mut c_void, *const FlutterRustSatelliteWindowRequest) -> FlutterRustViewId,
    >,
    pub destroy_window: Option<extern "C" fn(*mut c_void, FlutterRustViewId)>,
    pub get_window_state:
        Option<extern "C" fn(*mut c_void, FlutterRustViewId, *mut FlutterRustWindowState) -> i32>,
    pub set_window_size: Option<extern "C" fn(*mut c_void, FlutterRustViewId, f64, f64)>,
    pub set_window_constraints:
        Option<extern "C" fn(*mut c_void, FlutterRustViewId, i32, f64, f64, f64, f64)>,
    pub set_window_title: Option<extern "C" fn(*mut c_void, FlutterRustViewId, *const u8, u64)>,
    pub activate_window: Option<extern "C" fn(*mut c_void, FlutterRustViewId)>,
    pub set_window_maximized: Option<extern "C" fn(*mut c_void, FlutterRustViewId, i32)>,
    pub set_window_minimized: Option<extern "C" fn(*mut c_void, FlutterRustViewId, i32)>,
    pub set_window_fullscreen: Option<extern "C" fn(*mut c_void, FlutterRustViewId, i32)>,
    pub set_window_event_callback:
        Option<extern "C" fn(*mut c_void, Option<FlutterRustWindowEventCallback>)>,
    pub set_window_parent:
        Option<extern "C" fn(*mut c_void, FlutterRustViewId, FlutterRustViewId) -> i32>,
}

#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustViewFocusState {
    Unfocused = 0,
    Focused = 1,
}

#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustViewFocusDirection {
    Undefined = 0,
    Forward = 1,
    Backward = 2,
}

/// ABI information returned to C++ before it installs Rust callbacks.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FlutterRustShellAbi {
    pub shell_abi_version: u32,
    pub plugin_sdk_api_version: u32,
}

/// Private callback table used to bind Flutter task scheduling to the Rust
/// host loop. It is ABI-compatible with `rust_bridge.h` and never exposed to
/// application plugins.
#[repr(C)]
pub struct FlutterRustTaskRunnerCallbacks {
    pub user_data: *mut c_void,
    pub schedule_task: Option<extern "C" fn(*mut c_void, *mut c_void, u64, u64)>,
    pub runs_tasks_on_current_thread: Option<extern "C" fn(*mut c_void) -> i32>,
    pub task_runner_destroyed: Option<extern "C" fn(*mut c_void)>,
}

/// Raw Vulkan objects borrowed from Rust/wgpu, ABI-compatible with
/// `FlutterRustVulkanContextData` in `rust_bridge.h`. The extension arrays are
/// borrowed only for the duration of the `FlutterRustShellCreateShell` call.
#[repr(C)]
pub struct FlutterRustVulkanContextData {
    pub get_instance_proc_addr: *mut c_void,
    pub instance: *mut c_void,
    pub physical_device: *mut c_void,
    pub device: *mut c_void,
    pub queue: *mut c_void,
    pub queue_family_index: u32,
    pub instance_extensions: *const *const std::ffi::c_char,
    pub instance_extensions_count: u32,
    pub device_extensions: *const *const std::ffi::c_char,
    pub device_extensions_count: u32,
}

/// A Vulkan swapchain image acquired by the Rust GPU broker, ABI-compatible
/// with `FlutterRustVulkanImage` in `rust_bridge.h`.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct FlutterRustVulkanImage {
    pub image: u64,
    pub format: u32,
    /// Binary semaphore signalled by wgpu after swapchain acquisition.
    pub acquire_semaphore: u64,
    /// Binary semaphore signalled by Impeller after its final image use.
    pub render_semaphore: u64,
}

/// ABI-compatible with `FlutterRustVulkanPresentationCallbacks`.
#[repr(C)]
pub struct FlutterRustVulkanPresentationCallbacks {
    pub user_data: *mut c_void,
    pub acquire_image:
        Option<extern "C" fn(*mut c_void, u32, u32, *mut FlutterRustVulkanImage) -> i32>,
    pub present_image: Option<extern "C" fn(*mut c_void, FlutterRustVulkanImage) -> i32>,
}

/// A plugin-produced Vulkan frame borrowed by Impeller, ABI-compatible with
/// `FlutterRustExternalTextureFrame` in `rust_bridge.h`.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FlutterRustExternalTextureFrame {
    pub image: u64,
    pub image_view: u64,
    pub format: u32,
    pub width: u32,
    pub height: u32,
    pub acquire_semaphore: u64,
    pub render_semaphore: u64,
}

/// ABI-compatible with `FlutterRustExternalTextureCallbacks`.
#[repr(C)]
pub struct FlutterRustExternalTextureCallbacks {
    pub user_data: *mut c_void,
    pub acquire_frame:
        Option<extern "C" fn(*mut c_void, u32, u32, *mut FlutterRustExternalTextureFrame) -> i32>,
    pub release_frame: Option<extern "C" fn(*mut c_void, FlutterRustExternalTextureFrame)>,
}

/// Paths borrowed only for the duration of the `FlutterRustShellCreateShell`
/// call; ABI-compatible with `FlutterRustShellSettings`.
#[repr(C)]
pub struct FlutterRustShellSettings {
    pub assets_path: *const std::ffi::c_char,
    pub icu_data_path: *const std::ffi::c_char,
    /// Path to the AOT-compiled application library (`libapp.so`). Null or
    /// empty when running from a JIT kernel snapshot.
    pub aot_library_path: *const std::ffi::c_char,
}

/// Opaque, one-shot response retained by the host when message handling is
/// asynchronous.
#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FlutterRustPlatformMessageResponseHandle(pub *mut c_void);

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustPlatformMessageDisposition {
    Unhandled = 0,
    Success = 1,
    Pending = 2,
}

pub type FlutterRustPlatformMessageResponseCallback = extern "C" fn(*mut c_void, *const u8, u64);

/// Callback table for framework-to-host platform messages. Byte slices and
/// the response handle are borrowed only for the duration of the callback.
/// Returning `Pending` transfers ownership of a non-null response handle to
/// Rust until it is completed through the bridge.
#[repr(C)]
pub struct FlutterRustPlatformMessageCallbacks {
    pub user_data: *mut c_void,
    pub handle_message: Option<
        extern "C" fn(
            *mut c_void,
            *const u8,
            u64,
            *const u8,
            u64,
            FlutterRustPlatformMessageResponseHandle,
        ) -> FlutterRustPlatformMessageDisposition,
    >,
}

/// Callback table used by Flutter to request a compositor-aligned frame from
/// the Rust window host. A missing callback selects the C++ timer fallback.
#[repr(C)]
pub struct FlutterRustVsyncCallbacks {
    pub user_data: *mut c_void,
    pub request_vsync: Option<extern "C" fn(*mut c_void)>,
}

/// Pointer phases accepted by the private engine bridge.
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustPointerPhase {
    Cancel = 0,
    Add = 1,
    Remove = 2,
    Hover = 3,
    Down = 4,
    Move = 5,
    Up = 6,
}

/// Pointer device kinds accepted by the private engine bridge.
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustPointerDeviceKind {
    Mouse = 0,
    Touch = 1,
}

/// Pointer signal kinds accepted by the private engine bridge.
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustPointerSignalKind {
    None = 0,
    Scroll = 1,
}

/// One winit pointer event, ABI-compatible with `FlutterRustPointerEvent`.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlutterRustPointerEvent {
    pub view_id: FlutterRustViewId,
    pub timestamp_micros: u64,
    pub phase: u32,
    pub device_kind: u32,
    pub signal_kind: u32,
    pub device: i64,
    pub physical_x: f64,
    pub physical_y: f64,
    pub scroll_delta_x: f64,
    pub scroll_delta_y: f64,
    pub buttons: i64,
}

/// Application lifecycle states accepted by the private engine bridge.
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustLifecycleState {
    Detached = 0,
    Resumed = 1,
    Inactive = 2,
    Hidden = 3,
    Paused = 4,
}

/// Key event types accepted by the private engine bridge.
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlutterRustKeyEventType {
    Down = 0,
    Up = 1,
    Repeat = 2,
}

/// Maximum UTF-8 payload carried inline by one private-ABI key event.
pub const FLUTTER_RUST_KEY_CHARACTER_CAPACITY: usize = 64;

/// One winit key event, ABI-compatible with `FlutterRustKeyEvent`.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FlutterRustKeyEvent {
    pub timestamp_micros: u64,
    pub event_type: u32,
    pub physical: u64,
    pub logical: u64,
    pub synthesized: i32,
    pub character_length: u32,
    pub character: [u8; FLUTTER_RUST_KEY_CHARACTER_CAPACITY],
}

/// Returns the ABI versions compiled into the Rust shell runtime.
#[unsafe(no_mangle)]
pub extern "C" fn FlutterRustShellGetAbi() -> FlutterRustShellAbi {
    FlutterRustShellAbi {
        shell_abi_version: SHELL_ABI_VERSION,
        plugin_sdk_api_version: PLUGIN_SDK_API_VERSION,
    }
}

#[cfg(test)]
#[path = "../tests/unit/abi.rs"]
mod tests;
