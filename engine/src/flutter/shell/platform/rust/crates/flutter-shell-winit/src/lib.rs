//! Winit-owned native host for the optional Flutter Rust shell.
//!
//! The host keeps Flutter UI/platform task batons in a monotonic task queue.
//! The private C++ bridge will install the callback that executes a due baton.

mod engine;
mod platform;

use engine::{CurrentEngine, EngineBridge};
use platform::{CurrentPlatform, PlatformBackend};

use flutter_plugin_sdk::{
    FlutterRustPlugin, GpuTextures, PixelBufferTexture, PixelBufferTextureBackendHandle,
    PixelBufferTextureFrameBackend, PluginError, Result as PluginResult, TextureDescriptor,
    TextureFormat, WgpuTexture, WgpuTextureBackend, WgpuTextureBackendHandle,
    WgpuTextureFrameBackend,
};
use flutter_plugin_sdk::{MainThreadDispatcher, MainThreadTask, PluginRegistrar};
use flutter_shell_core::{
    FLUTTER_RUST_KEY_CHARACTER_CAPACITY, FlutterRustKeyEvent, FlutterRustKeyEventType,
    FlutterRustLifecycleState, FlutterRustPointerDeviceKind, FlutterRustPointerEvent,
    FlutterRustPointerPhase, FlutterRustPointerSignalKind, FlutterRustTaskRunnerCallbacks,
    FlutterRustViewId, FlutterRustVsyncCallbacks, FlutterRustWindowEventCallback,
};
use flutter_shell_core::{
    FlutterRustDialogWindowRequest, FlutterRustPopupWindowRequest, FlutterRustRegularWindowRequest,
    FlutterRustSatelliteWindowRequest,
};
use flutter_shell_core::{
    FlutterRustPlatformMessageCallbacks, FlutterRustPlatformMessageDisposition,
    FlutterRustPlatformMessageResponseCallback, FlutterRustPlatformMessageResponseHandle,
    FlutterRustShellSettings, FlutterRustViewFocusDirection, FlutterRustViewFocusState,
    FlutterRustViewMetrics, FlutterRustViewOperationCallbacks, FlutterRustVulkanContextData,
    FlutterRustVulkanPresentationCallbacks, FlutterRustWindowEvent, FlutterRustWindowState,
    FlutterRustWindowingCallbacks,
};
use flutter_shell_wgpu::GpuBroker;
use flutter_shell_wgpu::{GpuContext, WgpuTextureRing};
use parking_lot::Mutex;
use serde::{Deserialize, Serialize, de::IgnoredAny};
use serde_json::Value;
use std::ffi::CString;
use std::{
    cell::RefCell,
    collections::{BTreeMap, HashMap, HashSet, VecDeque},
    ffi::c_void,
    path::PathBuf,
    rc::{Rc, Weak},
    sync::Arc,
    sync::atomic::{AtomicBool, Ordering},
    thread::ThreadId,
    time::{Duration, Instant},
};
use winit::monitor::Fullscreen;
use winit::{
    application::ApplicationHandler,
    dpi::{LogicalPosition, LogicalSize},
    event::{
        ButtonSource, ElementState, Ime, KeyEvent as WinitKeyEvent, MouseButton, MouseScrollDelta,
        PointerKind, PointerSource, TouchPhase, WindowEvent,
    },
    event_loop::{ActiveEventLoop, ControlFlow, EventLoop, EventLoopProxy},
    keyboard::{Key, KeyCode, ModifiersState, NamedKey, NativeKey, NativeKeyCode, PhysicalKey},
    window::{
        ImeCapabilities, ImeEnableRequest, ImeHint, ImePurpose, ImeRequest, ImeRequestData, Window,
        WindowAttributes, WindowId,
    },
};
enum HostEvent {
    TaskScheduled,
    VsyncRequested,
    MainThreadTask(MainThreadTask),
    ViewOperationCompleted {
        view_id: FlutterRustViewId,
        operation: ViewOperation,
        succeeded: bool,
    },
    RequestAppExit {
        response: Option<PendingPlatformResponse>,
    },
    ExitRequested,
}
#[derive(Debug, Clone, Copy)]
struct PendingPlatformResponse(usize);

#[derive(Clone)]
struct HostEventSender {
    queue: Arc<Mutex<VecDeque<HostEvent>>>,
    proxy: EventLoopProxy,
}

const MAX_HOST_EVENTS_PER_TURN: usize = 64;

impl HostEventSender {
    fn new(proxy: EventLoopProxy) -> Self {
        Self {
            queue: Arc::new(Mutex::new(VecDeque::new())),
            proxy,
        }
    }

    fn send_event(&self, event: HostEvent) -> Result<(), ()> {
        self.queue.lock().push_back(event);
        self.proxy.wake_up();
        Ok(())
    }

    fn drain(&self) -> Vec<HostEvent> {
        let (events, has_more) = drain_host_event_batch(&self.queue);
        if has_more {
            self.proxy.wake_up();
        }
        events
    }
}

fn drain_host_event_batch(queue: &Mutex<VecDeque<HostEvent>>) -> (Vec<HostEvent>, bool) {
    let mut queue = queue.lock();
    let count = queue.len().min(MAX_HOST_EVENTS_PER_TURN);
    let events = queue.drain(..count).collect();
    (events, !queue.is_empty())
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ViewOperation {
    Add,
    Remove,
}

struct ViewOperationContext {
    wake_proxy: HostEventSender,
    operation: ViewOperation,
}

struct ActiveWindowingContext {
    event_loop: *const dyn ActiveEventLoop,
    windows: Weak<RefCell<WindowRegistry>>,
}

thread_local! {
    static ACTIVE_WINDOWING_CONTEXT: RefCell<Option<ActiveWindowingContext>> = const {
        RefCell::new(None)
    };
}

fn with_active_windowing_context<T>(
    event_loop: &dyn ActiveEventLoop,
    windows: &Rc<RefCell<WindowRegistry>>,
    callback: impl FnOnce() -> T,
) -> T {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        assert!(slot.borrow().is_none(), "nested Rust windowing context");
        *slot.borrow_mut() = Some(ActiveWindowingContext {
            event_loop,
            windows: Rc::downgrade(windows),
        });
    });
    let result = callback();
    ACTIVE_WINDOWING_CONTEXT.with(|slot| *slot.borrow_mut() = None);
    result
}

#[derive(Debug)]
struct NativeWindowRequest {
    title: String,
    width: f64,
    height: f64,
    shrink_wrap: bool,
    resizable: bool,
    constraints: Option<(f64, f64, f64, f64)>,
}

#[derive(Debug)]
struct NativePopupRequest {
    kind: NativeWindowKind,
    parent_view_id: FlutterRustViewId,
    constraints: (f64, f64, f64, f64),
    anchor_rect: (i32, i32, i32, i32),
    parent_anchor: PopupAnchor,
    gravity: PopupAnchor,
    offset: (i32, i32),
    constraint_adjustment: u32,
}

#[derive(Debug)]
struct NativeSatelliteRequest {
    window: NativeWindowRequest,
    parent_view_id: FlutterRustViewId,
    anchor_rect: Option<(f64, f64, f64, f64)>,
    parent_anchor: PopupAnchor,
    gravity: PopupAnchor,
    offset: (f64, f64),
    _constraint_adjustment: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum PopupAnchor {
    None,
    Top,
    Bottom,
    Left,
    Right,
    TopLeft,
    BottomLeft,
    TopRight,
    BottomRight,
}

#[derive(Debug, Clone, Copy)]
pub(crate) struct PopupPlacement {
    pub(crate) width: u32,
    pub(crate) height: u32,
    pub(crate) anchor_rect: (i32, i32, i32, i32),
    pub(crate) anchor: PopupAnchor,
    pub(crate) gravity: PopupAnchor,
    pub(crate) offset: (i32, i32),
    pub(crate) constraint_adjustment: u32,
}

fn popup_anchor(value: i32) -> Option<PopupAnchor> {
    Some(match value {
        0 => PopupAnchor::None,
        1 => PopupAnchor::Top,
        2 => PopupAnchor::Bottom,
        3 => PopupAnchor::Left,
        4 => PopupAnchor::Right,
        5 => PopupAnchor::TopLeft,
        6 => PopupAnchor::BottomLeft,
        7 => PopupAnchor::TopRight,
        8 => PopupAnchor::BottomRight,
        _ => return None,
    })
}

fn popup_gravity_for_child_anchor(value: i32) -> Option<PopupAnchor> {
    Some(match popup_anchor(value)? {
        PopupAnchor::None => PopupAnchor::None,
        PopupAnchor::Top => PopupAnchor::Bottom,
        PopupAnchor::Bottom => PopupAnchor::Top,
        PopupAnchor::Left => PopupAnchor::Right,
        PopupAnchor::Right => PopupAnchor::Left,
        PopupAnchor::TopLeft => PopupAnchor::BottomRight,
        PopupAnchor::BottomLeft => PopupAnchor::TopRight,
        PopupAnchor::TopRight => PopupAnchor::BottomLeft,
        PopupAnchor::BottomRight => PopupAnchor::TopLeft,
    })
}

fn decode_popup_request(request: &FlutterRustPopupWindowRequest) -> Option<NativePopupRequest> {
    let kind = match request.kind {
        0 => NativeWindowKind::Tooltip,
        1 => NativeWindowKind::Popup,
        _ => return None,
    };
    if request.parent_view_id <= FlutterRustViewId::IMPLICIT
        || !valid_constraints(
            request.min_width,
            request.min_height,
            request.max_width,
            request.max_height,
        )
        || ![
            request.anchor_x,
            request.anchor_y,
            request.anchor_width,
            request.anchor_height,
            request.offset_x,
            request.offset_y,
        ]
        .into_iter()
        .all(f64::is_finite)
        || request.anchor_width < 0.0
        || request.anchor_height < 0.0
        || request.constraint_adjustment & !0x3f != 0
    {
        return None;
    }
    Some(NativePopupRequest {
        kind,
        parent_view_id: request.parent_view_id,
        constraints: (
            request.min_width,
            request.min_height,
            request.max_width,
            request.max_height,
        ),
        anchor_rect: (
            request.anchor_x.round() as i32,
            request.anchor_y.round() as i32,
            request.anchor_width.round().max(1.0) as i32,
            request.anchor_height.round().max(1.0) as i32,
        ),
        parent_anchor: popup_anchor(request.parent_anchor)?,
        gravity: popup_gravity_for_child_anchor(request.child_anchor)?,
        offset: (
            request.offset_x.round() as i32,
            request.offset_y.round() as i32,
        ),
        constraint_adjustment: request.constraint_adjustment,
    })
}

fn decode_satellite_request(
    request: &FlutterRustSatelliteWindowRequest,
) -> Option<NativeSatelliteRequest> {
    let window = decode_window_request(&request.window)?;
    if request.parent_view_id <= FlutterRustViewId::IMPLICIT
        || ![
            request.anchor_x,
            request.anchor_y,
            request.anchor_width,
            request.anchor_height,
            request.offset_x,
            request.offset_y,
        ]
        .into_iter()
        .all(f64::is_finite)
        || request.anchor_width < 0.0
        || request.anchor_height < 0.0
        || request.constraint_adjustment & !0x3f != 0
    {
        return None;
    }
    Some(NativeSatelliteRequest {
        window,
        parent_view_id: request.parent_view_id,
        anchor_rect: (request.has_anchor_rect != 0).then_some((
            request.anchor_x,
            request.anchor_y,
            request.anchor_width,
            request.anchor_height,
        )),
        parent_anchor: popup_anchor(request.parent_anchor)?,
        gravity: popup_gravity_for_child_anchor(request.child_anchor)?,
        offset: (request.offset_x, request.offset_y),
        _constraint_adjustment: request.constraint_adjustment,
    })
}

fn decode_window_request(request: &FlutterRustRegularWindowRequest) -> Option<NativeWindowRequest> {
    let title = if request.title_length == 0 {
        "Flutter".to_owned()
    } else {
        if request.title.is_null() {
            return None;
        }
        let length = usize::try_from(request.title_length).ok()?;
        // SAFETY: the caller guarantees a readable byte range for this
        // synchronous callback.
        let bytes = unsafe { std::slice::from_raw_parts(request.title, length) };
        std::str::from_utf8(bytes).ok()?.to_owned()
    };
    let (width, height) = if request.has_size != 0 {
        (request.width, request.height)
    } else {
        (800.0, 600.0)
    };
    if !valid_window_size(width, height) {
        return None;
    }
    let constraints = if request.has_constraints != 0 {
        if !valid_constraints(
            request.min_width,
            request.min_height,
            request.max_width,
            request.max_height,
        ) {
            return None;
        }
        Some((
            request.min_width,
            request.min_height,
            request.max_width,
            request.max_height,
        ))
    } else {
        None
    };
    Some(NativeWindowRequest {
        title,
        width,
        height,
        shrink_wrap: request.has_size == 0,
        resizable: request.resizable != 0,
        constraints,
    })
}

trait WindowingCallbackHost {
    fn create_window(
        &self,
        request: NativeWindowRequest,
        kind: NativeWindowKind,
        parent: Option<FlutterRustViewId>,
    ) -> FlutterRustViewId;

    fn create_popup(&self, request: NativePopupRequest) -> FlutterRustViewId;

    fn create_satellite(&self, request: NativeSatelliteRequest) -> FlutterRustViewId;

    fn destroy_window(&self, view_id: FlutterRustViewId);
}
impl WindowingCallbackHost for ActiveWindowingContext {
    fn create_window(
        &self,
        request: NativeWindowRequest,
        kind: NativeWindowKind,
        parent: Option<FlutterRustViewId>,
    ) -> FlutterRustViewId {
        let Some(windows) = self.windows.upgrade() else {
            return FlutterRustViewId(-1);
        };
        // SAFETY: the context exists only during a live winit callback.
        let event_loop = unsafe { &*self.event_loop };
        let created = windows
            .borrow_mut()
            .create_regular_view(event_loop, request, kind, parent)
            .map_err(|error| log::error!("failed to create Flutter window: {error}"));
        let Ok(created) = created else {
            return FlutterRustViewId(-1);
        };
        add_cpp_shell_view(
            created.shell,
            created.view_id,
            created.metrics,
            created.presentation_callbacks,
            created.event_proxy,
        );
        created.view_id
    }

    fn create_popup(&self, request: NativePopupRequest) -> FlutterRustViewId {
        let Some(windows) = self.windows.upgrade() else {
            return FlutterRustViewId(-1);
        };
        // SAFETY: see create_window.
        let event_loop = unsafe { &*self.event_loop };
        let Ok(created) = windows.borrow_mut().create_popup_view(event_loop, request) else {
            return FlutterRustViewId(-1);
        };
        add_cpp_shell_view(
            created.shell,
            created.view_id,
            created.metrics,
            created.presentation_callbacks,
            created.event_proxy,
        );
        created.view_id
    }

    fn create_satellite(&self, request: NativeSatelliteRequest) -> FlutterRustViewId {
        let Some(windows) = self.windows.upgrade() else {
            return FlutterRustViewId(-1);
        };
        // SAFETY: see create_window.
        let event_loop = unsafe { &*self.event_loop };
        let Ok(created) = windows
            .borrow_mut()
            .create_satellite_view(event_loop, request)
        else {
            return FlutterRustViewId(-1);
        };
        add_cpp_shell_view(
            created.shell,
            created.view_id,
            created.metrics,
            created.presentation_callbacks,
            created.event_proxy,
        );
        created.view_id
    }

    fn destroy_window(&self, view_id: FlutterRustViewId) {
        let Some(windows) = self.windows.upgrade() else {
            return;
        };
        let removals = { windows.borrow_mut().begin_remove_views(view_id) };
        for (view_id, shell, event_proxy) in removals {
            remove_cpp_shell_view(shell, view_id, event_proxy);
        }
    }
}

fn dispatch_create_regular<H: WindowingCallbackHost>(
    host: &H,
    request: *const FlutterRustRegularWindowRequest,
) -> FlutterRustViewId {
    if request.is_null() {
        return FlutterRustViewId(-1);
    }
    // SAFETY: the synchronous caller supplies one complete request.
    let Some(request) = decode_window_request(unsafe { &*request }) else {
        return FlutterRustViewId(-1);
    };
    host.create_window(request, NativeWindowKind::Regular, None)
}

fn dispatch_create_dialog<H: WindowingCallbackHost>(
    host: &H,
    request: *const FlutterRustDialogWindowRequest,
) -> FlutterRustViewId {
    if request.is_null() {
        return FlutterRustViewId(-1);
    }
    // SAFETY: the synchronous caller supplies one complete request.
    let request = unsafe { &*request };
    let Some(window) = decode_window_request(&request.window) else {
        return FlutterRustViewId(-1);
    };
    let parent = (request.has_parent != 0).then_some(request.parent_view_id);
    host.create_window(window, NativeWindowKind::Dialog, parent)
}

fn dispatch_create_popup<H: WindowingCallbackHost>(
    host: &H,
    request: *const FlutterRustPopupWindowRequest,
) -> FlutterRustViewId {
    if request.is_null() {
        return FlutterRustViewId(-1);
    }
    // SAFETY: the synchronous caller supplies one complete request.
    let Some(request) = decode_popup_request(unsafe { &*request }) else {
        return FlutterRustViewId(-1);
    };
    host.create_popup(request)
}

fn dispatch_create_satellite<H: WindowingCallbackHost>(
    host: &H,
    request: *const FlutterRustSatelliteWindowRequest,
) -> FlutterRustViewId {
    if request.is_null() {
        return FlutterRustViewId(-1);
    }
    // SAFETY: the synchronous caller supplies one complete request.
    let Some(request) = decode_satellite_request(unsafe { &*request }) else {
        return FlutterRustViewId(-1);
    };
    host.create_satellite(request)
}

fn dispatch_destroy<H: WindowingCallbackHost>(host: &H, view_id: FlutterRustViewId) {
    if view_id > FlutterRustViewId::IMPLICIT {
        host.destroy_window(view_id);
    }
}
extern "C" fn create_regular_window_callback(
    _user_data: *mut c_void,
    request: *const FlutterRustRegularWindowRequest,
) -> FlutterRustViewId {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let context = slot.borrow();
        let Some(context) = context.as_ref() else {
            return FlutterRustViewId(-1);
        };
        dispatch_create_regular(context, request)
    })
}
extern "C" fn create_dialog_window_callback(
    _user_data: *mut c_void,
    request: *const FlutterRustDialogWindowRequest,
) -> FlutterRustViewId {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let context = slot.borrow();
        let Some(context) = context.as_ref() else {
            return FlutterRustViewId(-1);
        };
        dispatch_create_dialog(context, request)
    })
}
extern "C" fn create_popup_window_callback(
    _user_data: *mut c_void,
    request: *const FlutterRustPopupWindowRequest,
) -> FlutterRustViewId {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let context = slot.borrow();
        let Some(context) = context.as_ref() else {
            return FlutterRustViewId(-1);
        };
        dispatch_create_popup(context, request)
    })
}
extern "C" fn create_satellite_window_callback(
    _user_data: *mut c_void,
    request: *const FlutterRustSatelliteWindowRequest,
) -> FlutterRustViewId {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let context = slot.borrow();
        let Some(context) = context.as_ref() else {
            return FlutterRustViewId(-1);
        };
        dispatch_create_satellite(context, request)
    })
}
extern "C" fn destroy_window_callback(_user_data: *mut c_void, view_id: FlutterRustViewId) {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let context = slot.borrow();
        if let Some(context) = context.as_ref() {
            dispatch_destroy(context, view_id);
        }
    });
}
fn with_window_registry<T>(callback: impl FnOnce(&mut WindowRegistry) -> T) -> Option<T> {
    ACTIVE_WINDOWING_CONTEXT.with(|slot| {
        let windows = slot
            .borrow()
            .as_ref()
            .and_then(|context| context.windows.upgrade())?;
        Some(callback(&mut windows.borrow_mut()))
    })
}
extern "C" fn get_window_state_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    state: *mut FlutterRustWindowState,
) -> i32 {
    if state.is_null() {
        return 0;
    }
    with_window_registry(|windows| {
        let Some(view) = windows.view(view_id) else {
            return 0;
        };
        let logical_size = view
            .window
            .surface_size()
            .to_logical(view.window.scale_factor());
        let value = FlutterRustWindowState {
            width: logical_size.width,
            height: logical_size.height,
            focused: i32::from(view.focused),
            maximized: i32::from(view.window.is_maximized()),
            minimized: i32::from(view.window.is_minimized().unwrap_or(false)),
            fullscreen: i32::from(view.window.fullscreen().is_some()),
        };
        // SAFETY: the synchronous caller provides writable storage for one
        // FlutterRustWindowState and retains it for this callback.
        unsafe { state.write(value) };
        1
    })
    .unwrap_or(0)
}
extern "C" fn set_window_size_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    width: f64,
    height: f64,
) {
    if !valid_window_size(width, height) {
        return;
    }
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            let _ = view
                .window
                .request_surface_size(LogicalSize::new(width, height).into());
        }
    });
}
extern "C" fn set_window_constraints_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    has_constraints: i32,
    min_width: f64,
    min_height: f64,
    max_width: f64,
    max_height: f64,
) {
    let _ = with_window_registry(|windows| {
        let Some(view) = windows.view(view_id) else {
            return;
        };
        if has_constraints == 0 {
            view.window.set_min_surface_size(None);
            view.window.set_max_surface_size(None);
            return;
        }
        if !valid_constraints(min_width, min_height, max_width, max_height) {
            return;
        }
        view.window
            .set_min_surface_size(Some(LogicalSize::new(min_width, min_height).into()));
        view.window.set_max_surface_size(Some(
            LogicalSize::new(finite_maximum(max_width), finite_maximum(max_height)).into(),
        ));
    });
}
extern "C" fn set_window_title_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    title: *const u8,
    title_length: u64,
) {
    let Ok(length) = usize::try_from(title_length) else {
        return;
    };
    if length != 0 && title.is_null() {
        return;
    }
    let bytes = if length == 0 {
        &[][..]
    } else {
        // SAFETY: C++ borrows this Dart-owned range only for the duration
        // of the synchronous callback.
        unsafe { std::slice::from_raw_parts(title, length) }
    };
    let Ok(title) = std::str::from_utf8(bytes) else {
        return;
    };
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            view.window.set_title(title);
        }
    });
}
extern "C" fn activate_window_callback(_user_data: *mut c_void, view_id: FlutterRustViewId) {
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            view.window.focus_window();
        }
    });
}
extern "C" fn set_window_maximized_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    enabled: i32,
) {
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            view.window.set_maximized(enabled != 0);
        }
    });
}
extern "C" fn set_window_minimized_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    enabled: i32,
) {
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            view.window.set_minimized(enabled != 0);
        }
    });
}
extern "C" fn set_window_fullscreen_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    enabled: i32,
) {
    let _ = with_window_registry(|windows| {
        if let Some(view) = windows.view(view_id) {
            let fullscreen = (enabled != 0).then_some(Fullscreen::Borderless(None));
            view.window.set_fullscreen(fullscreen);
        }
    });
}
extern "C" fn set_window_event_callback(
    _user_data: *mut c_void,
    callback: Option<FlutterRustWindowEventCallback>,
) {
    let _ = with_window_registry(|windows| windows.window_event_callback = callback);
}
extern "C" fn set_window_parent_callback(
    _user_data: *mut c_void,
    view_id: FlutterRustViewId,
    parent_view_id: FlutterRustViewId,
) -> i32 {
    with_window_registry(|windows| windows.reparent_satellite(view_id, parent_view_id))
        .is_some_and(|result| result.is_ok())
        .into()
}
fn windowing_callbacks() -> FlutterRustWindowingCallbacks {
    FlutterRustWindowingCallbacks {
        user_data: std::ptr::null_mut(),
        create_regular_window: Some(create_regular_window_callback),
        create_dialog_window: Some(create_dialog_window_callback),
        create_popup_window: Some(create_popup_window_callback),
        create_satellite_window: Some(create_satellite_window_callback),
        destroy_window: Some(destroy_window_callback),
        get_window_state: Some(get_window_state_callback),
        set_window_size: Some(set_window_size_callback),
        set_window_constraints: Some(set_window_constraints_callback),
        set_window_title: Some(set_window_title_callback),
        activate_window: Some(activate_window_callback),
        set_window_maximized: Some(set_window_maximized_callback),
        set_window_minimized: Some(set_window_minimized_callback),
        set_window_fullscreen: Some(set_window_fullscreen_callback),
        set_window_event_callback: Some(set_window_event_callback),
        set_window_parent: Some(set_window_parent_callback),
    }
}
extern "C" fn complete_view_operation(
    user_data: *mut c_void,
    view_id: FlutterRustViewId,
    succeeded: i32,
) {
    if user_data.is_null() {
        return;
    }
    // SAFETY: add/remove_cpp_shell_view allocate exactly one context and
    // C++ guarantees exactly one asynchronous completion callback.
    let context = unsafe { Box::from_raw(user_data.cast::<ViewOperationContext>()) };
    let _ = context
        .wake_proxy
        .send_event(HostEvent::ViewOperationCompleted {
            view_id,
            operation: context.operation,
            succeeded: succeeded != 0,
        });
}
fn create_cpp_shell(
    task_runner: *mut c_void,
    context_data: FlutterRustVulkanContextData,
    presentation_callbacks: flutter_shell_core::FlutterRustVulkanPresentationCallbacks,
    platform_message_callbacks: FlutterRustPlatformMessageCallbacks,
    vsync_callbacks: FlutterRustVsyncCallbacks,
    windowing_callbacks: FlutterRustWindowingCallbacks,
    settings: FlutterRustShellSettings,
) -> *mut c_void {
    unsafe extern "C" {
        fn FlutterRustShellCreateShell(
            task_runner: *mut c_void,
            context_data: FlutterRustVulkanContextData,
            presentation_callbacks: flutter_shell_core::FlutterRustVulkanPresentationCallbacks,
            platform_message_callbacks: FlutterRustPlatformMessageCallbacks,
            vsync_callbacks: FlutterRustVsyncCallbacks,
            windowing_callbacks: FlutterRustWindowingCallbacks,
            settings: FlutterRustShellSettings,
        ) -> *mut c_void;
    }
    // SAFETY: the struct layouts are ABI-compatible with rust_bridge.h.
    unsafe {
        FlutterRustShellCreateShell(
            task_runner,
            context_data,
            presentation_callbacks,
            platform_message_callbacks,
            vsync_callbacks,
            windowing_callbacks,
            settings,
        )
    }
}
fn run_cpp_shell(shell: *mut c_void) -> i32 {
    unsafe extern "C" {
        fn FlutterRustShellRunShell(shell: *mut c_void) -> i32;
    }
    // SAFETY: `shell` was returned by create_cpp_shell and not yet destroyed.
    unsafe { FlutterRustShellRunShell(shell) }
}
fn destroy_cpp_shell(shell: *mut c_void) {
    unsafe extern "C" {
        fn FlutterRustShellDestroyShell(shell: *mut c_void);
    }
    // SAFETY: `shell` was returned by create_cpp_shell.
    unsafe { FlutterRustShellDestroyShell(shell) }
}
fn set_cpp_shell_viewport_metrics(
    shell: *mut c_void,
    view_id: FlutterRustViewId,
    metrics: WindowMetrics,
) {
    unsafe extern "C" {
        fn FlutterRustShellSetViewportMetrics(
            shell: *mut c_void,
            view_id: FlutterRustViewId,
            metrics: FlutterRustViewMetrics,
        );
    }
    // SAFETY: `shell` was returned by create_cpp_shell and not yet destroyed.
    unsafe {
        FlutterRustShellSetViewportMetrics(shell, view_id, metrics.into());
    }
}
fn add_cpp_shell_view(
    shell: *mut c_void,
    view_id: FlutterRustViewId,
    metrics: WindowMetrics,
    presentation_callbacks: flutter_shell_core::FlutterRustVulkanPresentationCallbacks,
    wake_proxy: HostEventSender,
) {
    unsafe extern "C" {
        fn FlutterRustShellAddView(
            shell: *mut c_void,
            view_id: FlutterRustViewId,
            metrics: FlutterRustViewMetrics,
            presentation_callbacks: flutter_shell_core::FlutterRustVulkanPresentationCallbacks,
            callbacks: FlutterRustViewOperationCallbacks,
        );
    }
    let context = Box::new(ViewOperationContext {
        wake_proxy,
        operation: ViewOperation::Add,
    });
    let callbacks = FlutterRustViewOperationCallbacks {
        user_data: Box::into_raw(context).cast(),
        complete: Some(complete_view_operation),
    };
    let metrics = FlutterRustViewMetrics::from(metrics);
    // SAFETY: all tables are ABI-compatible; C++ retains the boxed
    // completion context until it invokes the callback exactly once.
    unsafe { FlutterRustShellAddView(shell, view_id, metrics, presentation_callbacks, callbacks) }
}
fn remove_cpp_shell_view(
    shell: *mut c_void,
    view_id: FlutterRustViewId,
    wake_proxy: HostEventSender,
) {
    unsafe extern "C" {
        fn FlutterRustShellRemoveView(
            shell: *mut c_void,
            view_id: FlutterRustViewId,
            callbacks: FlutterRustViewOperationCallbacks,
        );
    }
    let context = Box::new(ViewOperationContext {
        wake_proxy,
        operation: ViewOperation::Remove,
    });
    let callbacks = FlutterRustViewOperationCallbacks {
        user_data: Box::into_raw(context).cast(),
        complete: Some(complete_view_operation),
    };
    // SAFETY: see add_cpp_shell_view.
    unsafe { FlutterRustShellRemoveView(shell, view_id, callbacks) }
}
fn send_cpp_pointer_event(shell: *mut c_void, event: FlutterRustPointerEvent) {
    unsafe extern "C" {
        fn FlutterRustShellSendPointerEvent(shell: *mut c_void, event: FlutterRustPointerEvent);
    }
    // SAFETY: `shell` was returned by create_cpp_shell and the event is an
    // ABI-compatible value with no borrowed fields.
    unsafe { FlutterRustShellSendPointerEvent(shell, event) }
}
fn send_cpp_lifecycle_event(shell: *mut c_void, state: FlutterRustLifecycleState) {
    unsafe extern "C" {
        fn FlutterRustShellSendLifecycleEvent(shell: *mut c_void, state: u32);
    }
    // SAFETY: `shell` was returned by create_cpp_shell and the state is a
    // value from the private ABI enum.
    unsafe { FlutterRustShellSendLifecycleEvent(shell, state as u32) }
}
fn send_cpp_view_focus_event(
    shell: *mut c_void,
    view_id: FlutterRustViewId,
    state: FlutterRustViewFocusState,
) {
    unsafe extern "C" {
        fn FlutterRustShellSendViewFocusEvent(
            shell: *mut c_void,
            view_id: FlutterRustViewId,
            state: u32,
            direction: u32,
        );
    }
    // SAFETY: the shell is live and all values belong to the private ABI.
    unsafe {
        FlutterRustShellSendViewFocusEvent(
            shell,
            view_id,
            state as u32,
            FlutterRustViewFocusDirection::Undefined as u32,
        )
    }
}
fn send_cpp_key_event(shell: *mut c_void, event: FlutterRustKeyEvent) {
    unsafe extern "C" {
        fn FlutterRustShellSendKeyEvent(shell: *mut c_void, event: FlutterRustKeyEvent);
    }
    // SAFETY: `shell` was returned by create_cpp_shell and the event is an
    // ABI-compatible value containing no borrowed fields.
    unsafe { FlutterRustShellSendKeyEvent(shell, event) }
}
fn send_cpp_platform_message(shell: *mut c_void, channel: &[u8], message: &[u8]) {
    unsafe extern "C" {
        fn FlutterRustShellSendPlatformMessage(
            shell: *mut c_void,
            channel: *const u8,
            channel_size: u64,
            message: *const u8,
            message_size: u64,
        );
    }
    // SAFETY: C++ copies both slices before returning and `shell` remains
    // owned by this application.
    unsafe {
        FlutterRustShellSendPlatformMessage(
            shell,
            channel.as_ptr(),
            channel.len() as u64,
            message.as_ptr(),
            message.len() as u64,
        )
    }
}
fn send_cpp_platform_message_with_response(
    shell: *mut c_void,
    channel: &[u8],
    message: &[u8],
    callback: FlutterRustPlatformMessageResponseCallback,
    user_data: *mut c_void,
) -> bool {
    unsafe extern "C" {
        fn FlutterRustShellSendPlatformMessageWithResponse(
            shell: *mut c_void,
            channel: *const u8,
            channel_size: u64,
            message: *const u8,
            message_size: u64,
            callback: FlutterRustPlatformMessageResponseCallback,
            user_data: *mut c_void,
        ) -> i32;
    }
    // SAFETY: C++ copies both slices and retains only the callback and its
    // owned user data. The callback consumes that data exactly once.
    unsafe {
        FlutterRustShellSendPlatformMessageWithResponse(
            shell,
            channel.as_ptr(),
            channel.len() as u64,
            message.as_ptr(),
            message.len() as u64,
            callback,
            user_data,
        ) != 0
    }
}
fn complete_cpp_platform_message(response: PendingPlatformResponse, envelope: &[u8]) {
    unsafe extern "C" {
        fn FlutterRustShellCompletePlatformMessageResponse(
            response: FlutterRustPlatformMessageResponseHandle,
            envelope: *const u8,
            envelope_size: u64,
        );
    }
    // SAFETY: PendingPlatformResponse represents ownership transferred by
    // C++ after the incoming callback returned Pending. Completion is
    // one-shot and C++ copies the envelope before returning.
    unsafe {
        FlutterRustShellCompletePlatformMessageResponse(
            FlutterRustPlatformMessageResponseHandle(response.0 as *mut c_void),
            envelope.as_ptr(),
            envelope.len() as u64,
        )
    }
}
fn send_cpp_vsync(shell: *mut c_void, frame_interval_nanos: u64) {
    unsafe extern "C" {
        fn FlutterRustShellOnVsync(shell: *mut c_void, frame_interval_nanos: u64);
    }
    // SAFETY: `shell` remains owned by this application and the interval
    // is a plain value in the private ABI.
    unsafe { FlutterRustShellOnVsync(shell, frame_interval_nanos) }
}
fn register_cpp_external_texture(
    shell: *mut c_void,
    callbacks: flutter_shell_core::FlutterRustExternalTextureCallbacks,
) -> i64 {
    unsafe extern "C" {
        fn FlutterRustShellRegisterExternalTexture(
            shell: *mut c_void,
            callbacks: flutter_shell_core::FlutterRustExternalTextureCallbacks,
        ) -> i64;
    }
    unsafe { FlutterRustShellRegisterExternalTexture(shell, callbacks) }
}
fn mark_cpp_external_texture_frame_available(shell: *mut c_void, texture_id: i64) {
    unsafe extern "C" {
        fn FlutterRustShellMarkExternalTextureFrameAvailable(shell: *mut c_void, texture_id: i64);
    }
    unsafe { FlutterRustShellMarkExternalTextureFrameAvailable(shell, texture_id) }
}
type ExternalTextureUnregisteredCallback = unsafe extern "C" fn(*mut c_void);
fn unregister_cpp_external_texture(
    shell: *mut c_void,
    texture_id: i64,
    callback: Option<ExternalTextureUnregisteredCallback>,
    user_data: *mut c_void,
) {
    unsafe extern "C" {
        fn FlutterRustShellUnregisterExternalTexture(
            shell: *mut c_void,
            texture_id: i64,
            callback: Option<ExternalTextureUnregisteredCallback>,
            user_data: *mut c_void,
        );
    }
    unsafe { FlutterRustShellUnregisterExternalTexture(shell, texture_id, callback, user_data) }
}
fn test_recreate_cpp_texture_context(
    shell: *mut c_void,
    callback: ExternalTextureUnregisteredCallback,
    user_data: *mut c_void,
) {
    unsafe extern "C" {
        fn FlutterRustShellTestRecreateTextureContext(
            shell: *mut c_void,
            callback: ExternalTextureUnregisteredCallback,
            user_data: *mut c_void,
        );
    }
    unsafe { FlutterRustShellTestRecreateTextureContext(shell, callback, user_data) }
}

/// Winit host configuration, shared across the platforms this crate will
/// eventually support.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ShellConfig {
    pub title: String,
    pub assets_path: String,
    pub icu_data_path: String,
    /// Path to the AOT-compiled application library (`libapp.so`). Empty
    /// when running from a JIT kernel snapshot.
    pub aot_library_path: String,
    /// Optional append-only stream of `frame width height` records used by
    /// integration tests to verify that presentation remains live.
    pub presentation_stats_path: Option<PathBuf>,
}

/// Failure while starting or running a Rust-shell application.
#[derive(Debug)]
pub enum RunError {
    /// Winit could not create or run the native event loop.
    EventLoop(winit::error::EventLoopError),
    /// The application's source-linked Rust plugins failed to register.
    PluginRegistration(PluginError),
}

impl std::fmt::Display for RunError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::EventLoop(error) => write!(formatter, "native event loop failed: {error}"),
            Self::PluginRegistration(error) => {
                write!(formatter, "Rust plugin registration failed: {error:?}")
            }
        }
    }
}

impl std::error::Error for RunError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::EventLoop(error) => Some(error),
            Self::PluginRegistration(_) => None,
        }
    }
}

impl From<winit::error::EventLoopError> for RunError {
    fn from(error: winit::error::EventLoopError) -> Self {
        Self::EventLoop(error)
    }
}

impl Default for ShellConfig {
    fn default() -> Self {
        Self {
            title: "Flutter Rust Shell".to_owned(),
            assets_path: String::new(),
            icu_data_path: String::new(),
            aot_library_path: String::new(),
            presentation_stats_path: None,
        }
    }
}

/// An opaque Flutter task scheduled on the Rust host loop.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ScheduledTask {
    pub task_runner: usize,
    pub task_baton: u64,
}

/// A monotonic queue for opaque Flutter task batons.
///
/// C++ converts its `fml::TimePoint` to an `Instant` deadline before a
/// baton enters this queue. The task itself remains owned by C++ and is
/// executed only after the host loop returns its baton through the private
/// bridge.
#[derive(Debug, Default)]
pub struct TaskQueue {
    tasks: BTreeMap<Instant, Vec<ScheduledTask>>,
}

impl TaskQueue {
    pub fn schedule(&mut self, task: ScheduledTask, deadline: Instant) {
        self.tasks.entry(deadline).or_default().push(task);
    }

    pub fn next_deadline(&self) -> Option<Instant> {
        self.tasks.first_key_value().map(|(deadline, _)| *deadline)
    }

    pub fn take_due(&mut self, now: Instant) -> Vec<ScheduledTask> {
        let tasks = std::mem::take(&mut self.tasks);
        let mut due = Vec::new();
        for (deadline, task_batons) in tasks {
            if deadline <= now {
                due.extend(task_batons);
            } else {
                self.tasks.insert(deadline, task_batons);
            }
        }
        due
    }
}

const MOUSE_DEVICE_ID: i64 = 0;
const MOUSE_PRIMARY_BUTTON: i64 = 1 << 0;
const MOUSE_SECONDARY_BUTTON: i64 = 1 << 1;
const MOUSE_MIDDLE_BUTTON: i64 = 1 << 2;
const MOUSE_BACK_BUTTON: i64 = 1 << 3;
const MOUSE_FORWARD_BUTTON: i64 = 1 << 4;
const SCROLL_LINE_PIXELS: f64 = 53.0;

#[derive(Debug, Clone, Copy, PartialEq)]
struct WindowMetrics {
    width: u32,
    height: u32,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
    pixel_ratio: f64,
    display_width: u32,
    display_height: u32,
    display_refresh_rate: f64,
}

impl WindowMetrics {
    fn from_window(window: &dyn Window, pixel_ratio: f64) -> Self {
        let size = window.surface_size();
        let (display_width, display_height, display_refresh_rate) = window
            .current_monitor()
            .and_then(|monitor| monitor.current_video_mode())
            .map(|mode| {
                let size = mode.size();
                let refresh_rate = mode
                    .refresh_rate_millihertz()
                    .map_or(0.0, |rate| f64::from(rate.get()) / 1000.0);
                (size.width, size.height, refresh_rate)
            })
            .unwrap_or((size.width, size.height, 0.0));
        Self {
            width: size.width,
            height: size.height,
            min_width: size.width,
            max_width: size.width,
            min_height: size.height,
            max_height: size.height,
            pixel_ratio,
            display_width,
            display_height,
            display_refresh_rate,
        }
    }
    fn with_constraints(
        mut self,
        min_width: f64,
        min_height: f64,
        max_width: f64,
        max_height: f64,
    ) -> Self {
        let scale = self.pixel_ratio;
        self.min_width = (min_width * scale).round().max(0.0) as u32;
        self.min_height = (min_height * scale).round().max(0.0) as u32;
        self.max_width = (max_width * scale).round().max(1.0) as u32;
        self.max_height = (max_height * scale).round().max(1.0) as u32;
        self
    }
}
impl From<WindowMetrics> for FlutterRustViewMetrics {
    fn from(metrics: WindowMetrics) -> Self {
        Self {
            width: metrics.width as f64,
            height: metrics.height as f64,
            min_width: metrics.min_width as f64,
            max_width: metrics.max_width as f64,
            min_height: metrics.min_height as f64,
            max_height: metrics.max_height as f64,
            pixel_ratio: metrics.pixel_ratio,
            display_width: metrics.display_width as f64,
            display_height: metrics.display_height as f64,
            display_refresh_rate: metrics.display_refresh_rate,
        }
    }
}

const DEFAULT_FRAME_INTERVAL_NANOS: u64 = 16_666_667;

fn frame_interval_from_millihertz(refresh_rate: Option<u32>) -> u64 {
    refresh_rate
        .filter(|rate| *rate > 0)
        .map(|rate| 1_000_000_000_000_u64 / u64::from(rate))
        .unwrap_or(DEFAULT_FRAME_INTERVAL_NANOS)
}
fn window_frame_interval_nanos(window: &dyn Window) -> u64 {
    frame_interval_from_millihertz(
        window
            .current_monitor()
            .and_then(|monitor| monitor.current_video_mode())
            .and_then(|mode| mode.refresh_rate_millihertz())
            .map(|rate| rate.get()),
    )
}

#[derive(Debug)]
struct LifecycleState {
    active: bool,
    visible: bool,
    focused: bool,
    last_sent: Option<FlutterRustLifecycleState>,
}

impl LifecycleState {
    fn new() -> Self {
        Self {
            active: false,
            visible: false,
            focused: false,
            last_sent: None,
        }
    }

    fn resumed(&mut self, visible: bool, focused: bool) -> Option<FlutterRustLifecycleState> {
        self.active = true;
        self.visible = visible;
        self.focused = focused;
        self.changed()
    }

    fn suspended(&mut self) -> Option<FlutterRustLifecycleState> {
        self.active = false;
        self.changed()
    }

    fn visibility_changed(&mut self, visible: bool) -> Option<FlutterRustLifecycleState> {
        self.visible = visible;
        self.changed()
    }

    fn focus_changed(&mut self, focused: bool) -> Option<FlutterRustLifecycleState> {
        self.focused = focused;
        self.changed()
    }

    fn detached(&mut self) -> Option<FlutterRustLifecycleState> {
        self.emit(FlutterRustLifecycleState::Detached)
    }

    fn changed(&mut self) -> Option<FlutterRustLifecycleState> {
        let state = if !self.active {
            FlutterRustLifecycleState::Paused
        } else if !self.visible {
            FlutterRustLifecycleState::Hidden
        } else if self.focused {
            FlutterRustLifecycleState::Resumed
        } else {
            FlutterRustLifecycleState::Inactive
        };
        self.emit(state)
    }

    fn emit(&mut self, state: FlutterRustLifecycleState) -> Option<FlutterRustLifecycleState> {
        if self.last_sent == Some(state) {
            return None;
        }
        self.last_sent = Some(state);
        Some(state)
    }
}

const TEXT_INPUT_CHANNEL: &[u8] = b"flutter/textinput";
const PLATFORM_CHANNEL: &[u8] = b"flutter/platform";
const REQUEST_APP_EXIT_MESSAGE: &[u8] =
    br#"{"method":"System.requestAppExit","args":{"type":"cancelable"}}"#;
const KEY_EVENT_CHANNEL: &[u8] = b"flutter/keyevent";
const TEXTURE_FIXTURE_CHANNEL: &[u8] = b"flutter/rust_texture_fixture";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(transparent)]
struct TextInputClientId(i64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
enum TextAffinity {
    #[serde(rename = "TextAffinity.upstream")]
    Upstream,
    #[default]
    #[serde(rename = "TextAffinity.downstream")]
    Downstream,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct TextEditingState {
    text: String,
    selection_base: i64,
    selection_extent: i64,
    #[serde(default)]
    selection_affinity: TextAffinity,
    #[serde(default)]
    selection_is_directional: bool,
    composing_base: i64,
    composing_extent: i64,
}

impl Default for TextEditingState {
    fn default() -> Self {
        Self {
            text: String::new(),
            selection_base: -1,
            selection_extent: -1,
            selection_affinity: TextAffinity::Downstream,
            selection_is_directional: false,
            composing_base: -1,
            composing_extent: -1,
        }
    }
}

impl TextEditingState {
    fn validate(&self) -> bool {
        valid_range_for_text(&self.text, self.selection_base, self.selection_extent, true)
            && valid_range_for_text(&self.text, self.composing_base, self.composing_extent, true)
    }

    fn replace_for_ime(
        &mut self,
        replacement: &str,
        composing: bool,
        composing_cursor: Option<usize>,
    ) -> bool {
        let replacement_length = replacement.encode_utf16().count() as i64;
        let Some(cursor) = composing_cursor
            .map(|byte_index| {
                replacement
                    .get(..byte_index)
                    .map(|prefix| prefix.encode_utf16().count() as i64)
            })
            .unwrap_or(Some(replacement_length))
        else {
            return false;
        };
        let text_length = self.text.encode_utf16().count() as i64;
        let (start, end) = if valid_text_range(
            self.composing_base,
            self.composing_extent,
            text_length,
            false,
        ) {
            ordered_range(self.composing_base, self.composing_extent)
        } else if valid_text_range(
            self.selection_base,
            self.selection_extent,
            text_length,
            false,
        ) {
            ordered_range(self.selection_base, self.selection_extent)
        } else {
            (text_length, text_length)
        };
        let (Some(byte_start), Some(byte_end)) = (
            utf16_index_to_byte(&self.text, start as usize),
            utf16_index_to_byte(&self.text, end as usize),
        ) else {
            return false;
        };
        self.text.replace_range(byte_start..byte_end, replacement);
        self.selection_base = start + cursor;
        self.selection_extent = start + cursor;
        self.selection_affinity = TextAffinity::Downstream;
        self.selection_is_directional = false;
        if composing && !replacement.is_empty() {
            self.composing_base = start;
            self.composing_extent = start + replacement_length;
        } else {
            self.composing_base = -1;
            self.composing_extent = -1;
        }
        true
    }
}

fn valid_text_range(base: i64, extent: i64, length: i64, allow_absent: bool) -> bool {
    (allow_absent && base == -1 && extent == -1)
        || (base >= 0 && extent >= 0 && base <= length && extent <= length)
}

fn valid_range_for_text(text: &str, base: i64, extent: i64, allow_absent: bool) -> bool {
    if allow_absent && base == -1 && extent == -1 {
        return true;
    }
    let length = text.encode_utf16().count() as i64;
    valid_text_range(base, extent, length, false)
        && utf16_index_to_byte(text, base as usize).is_some()
        && utf16_index_to_byte(text, extent as usize).is_some()
}

fn ordered_range(base: i64, extent: i64) -> (i64, i64) {
    (base.min(extent), base.max(extent))
}

fn utf16_index_to_byte(text: &str, target: usize) -> Option<usize> {
    let mut utf16_index = 0;
    for (byte_index, character) in text.char_indices() {
        if utf16_index == target {
            return Some(byte_index);
        }
        utf16_index += character.len_utf16();
        if utf16_index > target {
            return None;
        }
    }
    (utf16_index == target).then_some(text.len())
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct TextInputRect {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
}

impl TextInputRect {
    fn validate(self) -> bool {
        self.x.is_finite()
            && self.y.is_finite()
            && self.width.is_finite()
            && self.height.is_finite()
            && self.width >= 0.0
            && self.height >= 0.0
    }
}

#[derive(Deserialize)]
struct RawMethodCall {
    method: String,
    args: Value,
}

#[derive(Deserialize)]
struct SetClientArguments(TextInputClientId, IgnoredAny);

#[derive(Deserialize)]
struct RectArguments {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
}

#[derive(Debug, Clone, PartialEq)]
enum TextInputCommand {
    SetClient(TextInputClientId),
    SetEditingState(TextEditingState),
    Show,
    Hide,
    ClearClient,
    SetCursorRect(TextInputRect),
    Noop,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ApplicationExitRequest {
    Required,
    Cancelable,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ApplicationExitResponse {
    Exit,
    Cancel,
}

impl ApplicationExitRequest {
    fn decode(message: &[u8]) -> Option<Self> {
        let envelope: Value = serde_json::from_slice(message).ok()?;
        match envelope.get("method")?.as_str()? {
            "SystemNavigator.pop" => Some(Self::Required),
            "System.exitApplication" => {
                match envelope.get("args")?.as_object()?.get("type")?.as_str()? {
                    "required" => Some(Self::Required),
                    "cancelable" => Some(Self::Cancelable),
                    _ => None,
                }
            }
            _ => None,
        }
    }
}

impl ApplicationExitResponse {
    fn decode(message: &[u8]) -> Option<Self> {
        let envelope: Vec<Value> = serde_json::from_slice(message).ok()?;
        match envelope.first()?.get("response")?.as_str()? {
            "exit" => Some(Self::Exit),
            "cancel" => Some(Self::Cancel),
            _ => None,
        }
    }

    fn envelope(self) -> &'static [u8] {
        match self {
            Self::Exit => br#"[{"response":"exit"}]"#,
            Self::Cancel => br#"[{"response":"cancel"}]"#,
        }
    }
}

fn is_initialization_complete(message: &[u8]) -> bool {
    serde_json::from_slice::<Value>(message)
        .ok()
        .and_then(|value| value.get("method")?.as_str().map(str::to_owned))
        .is_some_and(|method| method == "System.initializationComplete")
}

impl TextInputCommand {
    fn decode(message: &[u8]) -> Option<Self> {
        let call: RawMethodCall = serde_json::from_slice(message).ok()?;
        match call.method.as_str() {
            "TextInput.setClient" => {
                let SetClientArguments(client_id, _) = serde_json::from_value(call.args).ok()?;
                Some(Self::SetClient(client_id))
            }
            "TextInput.setEditingState" => {
                let state: TextEditingState = serde_json::from_value(call.args).ok()?;
                state.validate().then_some(Self::SetEditingState(state))
            }
            "TextInput.show" => Some(Self::Show),
            "TextInput.hide" => Some(Self::Hide),
            "TextInput.clearClient" => Some(Self::ClearClient),
            "TextInput.setMarkedTextRect" | "TextInput.setCaretRect" => {
                let rect: RectArguments = serde_json::from_value(call.args).ok()?;
                let rect = TextInputRect {
                    x: rect.x,
                    y: rect.y,
                    width: rect.width,
                    height: rect.height,
                };
                rect.validate().then_some(Self::SetCursorRect(rect))
            }
            "TextInput.updateConfig"
            | "TextInput.setEditableSizeAndTransform"
            | "TextInput.setSelectionRects"
            | "TextInput.setStyle"
            | "TextInput.requestAutofill"
            | "TextInput.finishAutofillContext" => Some(Self::Noop),
            _ => None,
        }
    }
}

struct TextInputInbox {
    commands: Mutex<VecDeque<TextInputCommand>>,
    texture_fixture_messages: Mutex<VecDeque<String>>,
    wake_proxy: HostEventSender,
    exit: Arc<ApplicationExitCoordinator>,
}
struct ApplicationExitCoordinator {
    initialized: AtomicBool,
    pending: AtomicBool,
    wake_proxy: HostEventSender,
}
impl ApplicationExitCoordinator {
    fn begin(&self, response: Option<PendingPlatformResponse>) -> ExitRequestStart {
        if !self.initialized.load(Ordering::Acquire) {
            return ExitRequestStart::NotReady;
        }
        if self
            .pending
            .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
            .is_err()
        {
            return ExitRequestStart::AlreadyPending;
        }
        let _ = self
            .wake_proxy
            .send_event(HostEvent::RequestAppExit { response });
        ExitRequestStart::Started
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ExitRequestStart {
    Started,
    NotReady,
    AlreadyPending,
}

impl TextInputInbox {
    fn new(wake_proxy: HostEventSender) -> Self {
        Self {
            commands: Mutex::new(VecDeque::new()),
            texture_fixture_messages: Mutex::new(VecDeque::new()),
            wake_proxy: wake_proxy.clone(),
            exit: Arc::new(ApplicationExitCoordinator {
                initialized: AtomicBool::new(false),
                pending: AtomicBool::new(false),
                wake_proxy,
            }),
        }
    }
    fn callbacks(&self) -> FlutterRustPlatformMessageCallbacks {
        FlutterRustPlatformMessageCallbacks {
            user_data: std::ptr::from_ref(self).cast_mut().cast(),
            handle_message: Some(handle_platform_message),
        }
    }

    fn drain(&self) -> VecDeque<TextInputCommand> {
        std::mem::take(&mut *self.commands.lock())
    }
    fn drain_texture_fixture_messages(&self) -> VecDeque<String> {
        std::mem::take(&mut *self.texture_fixture_messages.lock())
    }
}
extern "C" fn handle_platform_message(
    user_data: *mut c_void,
    channel: *const u8,
    channel_size: u64,
    message: *const u8,
    message_size: u64,
    response_handle: FlutterRustPlatformMessageResponseHandle,
) -> FlutterRustPlatformMessageDisposition {
    if user_data.is_null() || channel.is_null() || (message.is_null() && message_size != 0) {
        return FlutterRustPlatformMessageDisposition::Unhandled;
    }
    let (Ok(channel_size), Ok(message_size)) =
        (usize::try_from(channel_size), usize::try_from(message_size))
    else {
        return FlutterRustPlatformMessageDisposition::Unhandled;
    };
    // SAFETY: C++ guarantees these byte slices remain valid for the
    // duration of the callback. A zero-length message does not dereference
    // its possibly-null pointer.
    let channel = unsafe { std::slice::from_raw_parts(channel, channel_size) };
    let message = if message_size == 0 {
        &[]
    } else {
        // SAFETY: checked non-null above; C++ owns this range for the call.
        unsafe { std::slice::from_raw_parts(message, message_size) }
    };
    if channel == PLATFORM_CHANNEL {
        let inbox = unsafe { &*user_data.cast::<TextInputInbox>() };
        if is_initialization_complete(message) {
            inbox.exit.initialized.store(true, Ordering::Release);
            return FlutterRustPlatformMessageDisposition::Success;
        }
        let Some(request) = ApplicationExitRequest::decode(message) else {
            return FlutterRustPlatformMessageDisposition::Unhandled;
        };
        if request == ApplicationExitRequest::Required || response_handle.0.is_null() {
            let _ = inbox.wake_proxy.send_event(HostEvent::ExitRequested);
            return FlutterRustPlatformMessageDisposition::Success;
        }
        return match inbox
            .exit
            .begin(Some(PendingPlatformResponse(response_handle.0 as usize)))
        {
            ExitRequestStart::Started => FlutterRustPlatformMessageDisposition::Pending,
            ExitRequestStart::NotReady => {
                let _ = inbox.wake_proxy.send_event(HostEvent::ExitRequested);
                FlutterRustPlatformMessageDisposition::Success
            }
            // The JSON success envelope is null, which the framework
            // deliberately interprets as a canceled exit.
            ExitRequestStart::AlreadyPending => FlutterRustPlatformMessageDisposition::Success,
        };
    }
    if channel == TEXTURE_FIXTURE_CHANNEL {
        let Ok(message) = std::str::from_utf8(message) else {
            return FlutterRustPlatformMessageDisposition::Unhandled;
        };
        let inbox = unsafe { &*user_data.cast::<TextInputInbox>() };
        inbox
            .texture_fixture_messages
            .lock()
            .push_back(message.to_owned());
        let _ = inbox.wake_proxy.send_event(HostEvent::TaskScheduled);
        return FlutterRustPlatformMessageDisposition::Success;
    }
    if channel != TEXT_INPUT_CHANNEL {
        return FlutterRustPlatformMessageDisposition::Unhandled;
    }
    let Some(command) = TextInputCommand::decode(message) else {
        return FlutterRustPlatformMessageDisposition::Unhandled;
    };
    // SAFETY: callbacks() uses the stable address of the boxed inbox, and
    // ShellApplication destroys the C++ shell before dropping that inbox.
    let inbox = unsafe { &*user_data.cast::<TextInputInbox>() };
    inbox.commands.lock().push_back(command);
    let _ = inbox.wake_proxy.send_event(HostEvent::TaskScheduled);
    FlutterRustPlatformMessageDisposition::Success
}
struct PendingApplicationExit {
    coordinator: Arc<ApplicationExitCoordinator>,
    response: Option<PendingPlatformResponse>,
}
extern "C" fn handle_application_exit_response(
    user_data: *mut c_void,
    response: *const u8,
    response_size: u64,
) {
    if user_data.is_null() {
        return;
    }
    // SAFETY: send_cancelable_exit_request transfers exactly one Box to
    // the one-shot C++ response object, which invokes this callback once.
    let pending = unsafe { Box::from_raw(user_data.cast::<PendingApplicationExit>()) };
    let response = usize::try_from(response_size)
        .ok()
        .and_then(|size| {
            if response.is_null() {
                (size == 0).then_some(&[][..])
            } else {
                // SAFETY: C++ borrows its response mapping for this call.
                Some(unsafe { std::slice::from_raw_parts(response, size) })
            }
        })
        .and_then(ApplicationExitResponse::decode)
        // Match the upstream Linux shell: malformed/error responses do
        // not trap an application that the OS asked to close.
        .unwrap_or(ApplicationExitResponse::Exit);
    pending.coordinator.pending.store(false, Ordering::Release);
    if let Some(original) = pending.response {
        complete_cpp_platform_message(original, response.envelope());
    }
    if response == ApplicationExitResponse::Exit {
        let _ = pending
            .coordinator
            .wake_proxy
            .send_event(HostEvent::ExitRequested);
    }
}
fn send_cancelable_exit_request(
    shell: *mut c_void,
    coordinator: Arc<ApplicationExitCoordinator>,
    response: Option<PendingPlatformResponse>,
) {
    let pending = Box::new(PendingApplicationExit {
        coordinator,
        response,
    });
    let user_data = Box::into_raw(pending).cast();
    if !send_cpp_platform_message_with_response(
        shell,
        PLATFORM_CHANNEL,
        REQUEST_APP_EXIT_MESSAGE,
        handle_application_exit_response,
        user_data,
    ) {
        // SAFETY: C++ rejected the send and therefore retained neither the
        // callback nor its user data.
        let pending = unsafe { Box::from_raw(user_data.cast::<PendingApplicationExit>()) };
        pending.coordinator.pending.store(false, Ordering::Release);
        if let Some(original) = pending.response {
            complete_cpp_platform_message(original, ApplicationExitResponse::Exit.envelope());
        }
        let _ = pending
            .coordinator
            .wake_proxy
            .send_event(HostEvent::ExitRequested);
    }
}

#[derive(Default)]
struct TextInputSession {
    active_client: Option<TextInputClientId>,
    editing_state: TextEditingState,
    ime_allowed: bool,
    cursor_rect: Option<TextInputRect>,
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum TextInputEffect {
    /// Enable or disable the platform IME (composition popup) for this window.
    SetImeAllowed(bool),
    /// Move the IME candidate window to avoid covering this screen rect.
    SetCursorRect(TextInputRect),
}

impl TextInputSession {
    fn apply(&mut self, command: TextInputCommand) -> Option<TextInputEffect> {
        match command {
            TextInputCommand::SetClient(client) => {
                self.active_client = Some(client);
                None
            }
            TextInputCommand::SetEditingState(state) => {
                if self.active_client.is_some() {
                    self.editing_state = state;
                }
                None
            }
            TextInputCommand::Show => {
                self.ime_allowed = self.active_client.is_some();
                Some(TextInputEffect::SetImeAllowed(self.ime_allowed))
            }
            TextInputCommand::Hide => {
                self.ime_allowed = false;
                Some(TextInputEffect::SetImeAllowed(false))
            }
            TextInputCommand::ClearClient => {
                self.active_client = None;
                self.editing_state = TextEditingState::default();
                self.ime_allowed = false;
                Some(TextInputEffect::SetImeAllowed(false))
            }
            TextInputCommand::SetCursorRect(rect) => {
                self.cursor_rect = Some(rect);
                Some(TextInputEffect::SetCursorRect(rect))
            }
            TextInputCommand::Noop => None,
        }
    }

    fn ime(&mut self, event: Ime) -> Option<Vec<u8>> {
        let client = self.active_client?;
        let changed = match event {
            Ime::Preedit(text, cursor) => {
                self.editing_state
                    .replace_for_ime(&text, true, cursor.map(|(_, end)| end))
            }
            Ime::Commit(text) => self.editing_state.replace_for_ime(&text, false, None),
            Ime::Enabled | Ime::Disabled | Ime::DeleteSurrounding { .. } => false,
        };
        changed.then(|| self.encode_update(client))
    }

    fn keyboard_text(&mut self, text: &str) -> Option<Vec<u8>> {
        let client = self.active_client?;
        if self.editing_state.composing_base >= 0 || self.editing_state.composing_extent >= 0 {
            return None;
        }
        self.editing_state
            .replace_for_ime(text, false, None)
            .then(|| self.encode_update(client))
    }

    fn encode_update(&self, client: TextInputClientId) -> Vec<u8> {
        #[derive(Serialize)]
        struct UpdateEditingState<'a> {
            method: &'static str,
            args: (TextInputClientId, &'a TextEditingState),
        }
        serde_json::to_vec(&UpdateEditingState {
            method: "TextInputClient.updateEditingState",
            args: (client, &self.editing_state),
        })
        .expect("typed text editing state must serialize")
    }
}

struct PointerState {
    view_id: FlutterRustViewId,
    started_at: Instant,
    physical_x: f64,
    physical_y: f64,
    buttons: i64,
    inside: bool,
    pointer_outside: bool,
}

impl PointerState {
    fn new() -> Self {
        Self::for_view(FlutterRustViewId::IMPLICIT)
    }

    fn for_view(view_id: FlutterRustViewId) -> Self {
        Self {
            view_id,
            started_at: Instant::now(),
            physical_x: 0.0,
            physical_y: 0.0,
            buttons: 0,
            inside: false,
            pointer_outside: true,
        }
    }

    fn mouse_event(
        &self,
        phase: FlutterRustPointerPhase,
        signal_kind: FlutterRustPointerSignalKind,
        scroll_delta_x: f64,
        scroll_delta_y: f64,
    ) -> FlutterRustPointerEvent {
        FlutterRustPointerEvent {
            view_id: self.view_id,
            timestamp_micros: self.started_at.elapsed().as_micros().min(u64::MAX as u128) as u64,
            phase: phase as u32,
            device_kind: FlutterRustPointerDeviceKind::Mouse as u32,
            signal_kind: signal_kind as u32,
            device: MOUSE_DEVICE_ID,
            physical_x: self.physical_x,
            physical_y: self.physical_y,
            scroll_delta_x,
            scroll_delta_y,
            buttons: self.buttons,
        }
    }

    fn entered(&mut self) -> Option<FlutterRustPointerEvent> {
        self.pointer_outside = false;
        self.ensure_added()
    }

    fn ensure_added(&mut self) -> Option<FlutterRustPointerEvent> {
        if self.inside {
            return None;
        }
        self.inside = true;
        Some(self.mouse_event(
            FlutterRustPointerPhase::Add,
            FlutterRustPointerSignalKind::None,
            0.0,
            0.0,
        ))
    }

    fn left(&mut self) -> Option<FlutterRustPointerEvent> {
        self.pointer_outside = true;
        // Keep the mouse added while a drag is captured outside the
        // window. Releasing the last button emits Up followed by Remove.
        if !self.inside || self.buttons != 0 {
            return None;
        }
        self.inside = false;
        Some(self.mouse_event(
            FlutterRustPointerPhase::Remove,
            FlutterRustPointerSignalKind::None,
            0.0,
            0.0,
        ))
    }

    fn moved(&mut self, physical_x: f64, physical_y: f64) -> Vec<FlutterRustPointerEvent> {
        self.physical_x = physical_x;
        self.physical_y = physical_y;
        self.pointer_outside = false;
        let mut events = self.entered().into_iter().collect::<Vec<_>>();
        events.push(self.mouse_event(
            if self.buttons == 0 {
                FlutterRustPointerPhase::Hover
            } else {
                FlutterRustPointerPhase::Move
            },
            FlutterRustPointerSignalKind::None,
            0.0,
            0.0,
        ));
        events
    }

    fn button(&mut self, button: MouseButton, state: ElementState) -> Vec<FlutterRustPointerEvent> {
        let Some(mask) = mouse_button_mask(button) else {
            return Vec::new();
        };
        if state == ElementState::Pressed {
            self.pointer_outside = false;
        }
        let mut events = self.ensure_added().into_iter().collect::<Vec<_>>();
        let phase = match state {
            ElementState::Pressed => {
                if self.buttons & mask != 0 {
                    return events;
                }
                let was_up = self.buttons == 0;
                self.buttons |= mask;
                if was_up {
                    FlutterRustPointerPhase::Down
                } else {
                    FlutterRustPointerPhase::Move
                }
            }
            ElementState::Released => {
                if self.buttons & mask == 0 {
                    return events;
                }
                self.buttons &= !mask;
                if self.buttons == 0 {
                    FlutterRustPointerPhase::Up
                } else {
                    FlutterRustPointerPhase::Move
                }
            }
        };
        events.push(self.mouse_event(phase, FlutterRustPointerSignalKind::None, 0.0, 0.0));
        if self.buttons == 0
            && self.pointer_outside
            && let Some(event) = self.left()
        {
            events.push(event);
        }
        events
    }

    fn scroll(&mut self, delta: MouseScrollDelta) -> Vec<FlutterRustPointerEvent> {
        self.pointer_outside = false;
        let (scroll_delta_x, scroll_delta_y) = match delta {
            MouseScrollDelta::LineDelta(x, y) => (
                f64::from(x) * SCROLL_LINE_PIXELS,
                -f64::from(y) * SCROLL_LINE_PIXELS,
            ),
            MouseScrollDelta::PixelDelta(position) => (position.x, -position.y),
        };
        let mut events = self.entered().into_iter().collect::<Vec<_>>();
        events.push(self.mouse_event(
            if self.buttons == 0 {
                FlutterRustPointerPhase::Hover
            } else {
                FlutterRustPointerPhase::Move
            },
            FlutterRustPointerSignalKind::Scroll,
            scroll_delta_x,
            scroll_delta_y,
        ));
        events
    }

    fn touch(
        &self,
        finger_id: usize,
        physical_x: f64,
        physical_y: f64,
        touch_phase: TouchPhase,
    ) -> FlutterRustPointerEvent {
        let (phase, buttons) = match touch_phase {
            TouchPhase::Started => (FlutterRustPointerPhase::Down, 1),
            TouchPhase::Moved => (FlutterRustPointerPhase::Move, 1),
            TouchPhase::Ended => (FlutterRustPointerPhase::Up, 0),
            TouchPhase::Cancelled => (FlutterRustPointerPhase::Cancel, 0),
        };
        FlutterRustPointerEvent {
            view_id: self.view_id,
            timestamp_micros: self.started_at.elapsed().as_micros().min(u64::MAX as u128) as u64,
            phase: phase as u32,
            device_kind: FlutterRustPointerDeviceKind::Touch as u32,
            signal_kind: FlutterRustPointerSignalKind::None as u32,
            // Reserve device 0 for the mouse. Winit touch IDs commonly
            // begin at zero, while Flutter keys pointer state by device.
            device: touch_device_id(finger_id as u64),
            physical_x,
            physical_y,
            scroll_delta_x: 0.0,
            scroll_delta_y: 0.0,
            buttons,
        }
    }
}

const KEY_VALUE_MASK: u64 = 0x000ffffffff;

struct KeyboardState {
    started_at: Instant,
    modifiers: ModifiersState,
}

impl KeyboardState {
    fn new() -> Self {
        Self {
            started_at: Instant::now(),
            modifiers: ModifiersState::empty(),
        }
    }

    fn modifiers_changed(&mut self, modifiers: ModifiersState) {
        self.modifiers = modifiers;
    }

    fn committed_text<'a>(&self, event: &'a WinitKeyEvent) -> Option<&'a str> {
        committed_key_text(self.modifiers, event.state, event.text.as_deref())
    }

    fn event(&self, event: &WinitKeyEvent, synthesized: bool) -> Option<FlutterRustKeyEvent> {
        make_key_event(
            self.started_at.elapsed().as_micros().min(u64::MAX as u128) as u64,
            event.physical_key,
            &event.logical_key,
            event.text.as_deref(),
            event.state,
            event.repeat,
            synthesized,
        )
    }

    fn raw_event_message(&self, event: &FlutterRustKeyEvent) -> Vec<u8> {
        #[derive(Serialize)]
        #[serde(rename_all = "camelCase")]
        struct RawKeyEvent {
            #[serde(rename = "type")]
            event_type: &'static str,
            keymap: &'static str,
            toolkit: &'static str,
            scan_code: u64,
            key_code: u64,
            modifiers: u32,
            specified_logical_key: u64,
            #[serde(skip_serializing_if = "Option::is_none")]
            unicode_scalar_values: Option<u32>,
        }

        let character = std::str::from_utf8(&event.character[..event.character_length as usize])
            .ok()
            .and_then(|text| {
                let mut characters = text.chars();
                let character = characters.next()?;
                (characters.next().is_none() && !character.is_control()).then_some(character as u32)
            });
        let mut modifiers = 0;
        if self.modifiers.shift_key() {
            modifiers |= 1 << 0;
        }
        if self.modifiers.control_key() {
            modifiers |= 1 << 2;
        }
        if self.modifiers.alt_key() {
            modifiers |= 1 << 3;
        }
        if self.modifiers.meta_key() {
            modifiers |= 1 << 26;
        }
        serde_json::to_vec(&RawKeyEvent {
            event_type: if event.event_type == FlutterRustKeyEventType::Up as u32 {
                "keyup"
            } else {
                "keydown"
            },
            keymap: CurrentPlatform::LEGACY_KEYMAP,
            toolkit: CurrentPlatform::LEGACY_TOOLKIT,
            // The modern key-data packet immediately preceding this
            // compatibility message is authoritative. Preserve the USB
            // usage as a distinct legacy scan code without pretending it
            // is a native GDK keycode.
            scan_code: event.physical & 0xffff,
            key_code: event.logical,
            modifiers,
            specified_logical_key: event.logical,
            unicode_scalar_values: character,
        })
        .expect("typed raw key event must serialize")
    }
}

fn committed_key_text(
    modifiers: ModifiersState,
    state: ElementState,
    text: Option<&str>,
) -> Option<&str> {
    if state != ElementState::Pressed
        || modifiers.control_key()
        || modifiers.meta_key()
        || modifiers.alt_key()
    {
        return None;
    }
    text.filter(|text| !text.is_empty() && text.chars().all(|character| !character.is_control()))
}

fn make_key_event(
    timestamp_micros: u64,
    physical_key: PhysicalKey,
    logical_key: &Key,
    text: Option<&str>,
    state: ElementState,
    repeat: bool,
    synthesized: bool,
) -> Option<FlutterRustKeyEvent> {
    let physical = physical_key_id(physical_key)?;
    let logical = logical_key_id(logical_key, physical_key, physical);
    let event_type = match (state, repeat) {
        (ElementState::Released, _) => FlutterRustKeyEventType::Up,
        (ElementState::Pressed, true) => FlutterRustKeyEventType::Repeat,
        (ElementState::Pressed, false) => FlutterRustKeyEventType::Down,
    };
    let mut character = [0; FLUTTER_RUST_KEY_CHARACTER_CAPACITY];
    let character_length = if state == ElementState::Pressed {
        text.filter(|value| {
            value.len() <= FLUTTER_RUST_KEY_CHARACTER_CAPACITY && !value.as_bytes().contains(&0)
        })
        .map_or(0, |value| {
            character[..value.len()].copy_from_slice(value.as_bytes());
            value.len() as u32
        })
    } else {
        0
    };
    Some(FlutterRustKeyEvent {
        timestamp_micros,
        event_type: event_type as u32,
        physical,
        logical,
        synthesized: i32::from(synthesized),
        character_length,
        character,
    })
}

fn physical_key_id(key: PhysicalKey) -> Option<u64> {
    let usage = match key {
        PhysicalKey::Code(code) => key_code_usb_usage(code)?,
        PhysicalKey::Unidentified(NativeKeyCode::Xkb(code)) => {
            return Some(CurrentPlatform::FALLBACK_KEY_PLANE | u64::from(code));
        }
        PhysicalKey::Unidentified(_) => return None,
    };
    Some(0x00070000 | u64::from(usage))
}

fn key_code_usb_usage(code: KeyCode) -> Option<u16> {
    Some(match code {
        KeyCode::KeyA => 0x04,
        KeyCode::KeyB => 0x05,
        KeyCode::KeyC => 0x06,
        KeyCode::KeyD => 0x07,
        KeyCode::KeyE => 0x08,
        KeyCode::KeyF => 0x09,
        KeyCode::KeyG => 0x0a,
        KeyCode::KeyH => 0x0b,
        KeyCode::KeyI => 0x0c,
        KeyCode::KeyJ => 0x0d,
        KeyCode::KeyK => 0x0e,
        KeyCode::KeyL => 0x0f,
        KeyCode::KeyM => 0x10,
        KeyCode::KeyN => 0x11,
        KeyCode::KeyO => 0x12,
        KeyCode::KeyP => 0x13,
        KeyCode::KeyQ => 0x14,
        KeyCode::KeyR => 0x15,
        KeyCode::KeyS => 0x16,
        KeyCode::KeyT => 0x17,
        KeyCode::KeyU => 0x18,
        KeyCode::KeyV => 0x19,
        KeyCode::KeyW => 0x1a,
        KeyCode::KeyX => 0x1b,
        KeyCode::KeyY => 0x1c,
        KeyCode::KeyZ => 0x1d,
        KeyCode::Digit1 => 0x1e,
        KeyCode::Digit2 => 0x1f,
        KeyCode::Digit3 => 0x20,
        KeyCode::Digit4 => 0x21,
        KeyCode::Digit5 => 0x22,
        KeyCode::Digit6 => 0x23,
        KeyCode::Digit7 => 0x24,
        KeyCode::Digit8 => 0x25,
        KeyCode::Digit9 => 0x26,
        KeyCode::Digit0 => 0x27,
        KeyCode::Enter => 0x28,
        KeyCode::Escape => 0x29,
        KeyCode::Backspace => 0x2a,
        KeyCode::Tab => 0x2b,
        KeyCode::Space => 0x2c,
        KeyCode::Minus => 0x2d,
        KeyCode::Equal => 0x2e,
        KeyCode::BracketLeft => 0x2f,
        KeyCode::BracketRight => 0x30,
        KeyCode::Backslash => 0x31,
        KeyCode::Semicolon => 0x33,
        KeyCode::Quote => 0x34,
        KeyCode::Backquote => 0x35,
        KeyCode::Comma => 0x36,
        KeyCode::Period => 0x37,
        KeyCode::Slash => 0x38,
        KeyCode::CapsLock => 0x39,
        KeyCode::F1 => 0x3a,
        KeyCode::F2 => 0x3b,
        KeyCode::F3 => 0x3c,
        KeyCode::F4 => 0x3d,
        KeyCode::F5 => 0x3e,
        KeyCode::F6 => 0x3f,
        KeyCode::F7 => 0x40,
        KeyCode::F8 => 0x41,
        KeyCode::F9 => 0x42,
        KeyCode::F10 => 0x43,
        KeyCode::F11 => 0x44,
        KeyCode::F12 => 0x45,
        KeyCode::PrintScreen => 0x46,
        KeyCode::ScrollLock => 0x47,
        KeyCode::Pause => 0x48,
        KeyCode::Insert => 0x49,
        KeyCode::Home => 0x4a,
        KeyCode::PageUp => 0x4b,
        KeyCode::Delete => 0x4c,
        KeyCode::End => 0x4d,
        KeyCode::PageDown => 0x4e,
        KeyCode::ArrowRight => 0x4f,
        KeyCode::ArrowLeft => 0x50,
        KeyCode::ArrowDown => 0x51,
        KeyCode::ArrowUp => 0x52,
        KeyCode::NumLock => 0x53,
        KeyCode::NumpadDivide => 0x54,
        KeyCode::NumpadMultiply => 0x55,
        KeyCode::NumpadSubtract => 0x56,
        KeyCode::NumpadAdd => 0x57,
        KeyCode::NumpadEnter => 0x58,
        KeyCode::Numpad1 => 0x59,
        KeyCode::Numpad2 => 0x5a,
        KeyCode::Numpad3 => 0x5b,
        KeyCode::Numpad4 => 0x5c,
        KeyCode::Numpad5 => 0x5d,
        KeyCode::Numpad6 => 0x5e,
        KeyCode::Numpad7 => 0x5f,
        KeyCode::Numpad8 => 0x60,
        KeyCode::Numpad9 => 0x61,
        KeyCode::Numpad0 => 0x62,
        KeyCode::NumpadDecimal => 0x63,
        KeyCode::IntlBackslash => 0x64,
        KeyCode::ContextMenu => 0x65,
        KeyCode::Power => 0x66,
        KeyCode::NumpadEqual => 0x67,
        KeyCode::F13 => 0x68,
        KeyCode::F14 => 0x69,
        KeyCode::F15 => 0x6a,
        KeyCode::F16 => 0x6b,
        KeyCode::F17 => 0x6c,
        KeyCode::F18 => 0x6d,
        KeyCode::F19 => 0x6e,
        KeyCode::F20 => 0x6f,
        KeyCode::F21 => 0x70,
        KeyCode::F22 => 0x71,
        KeyCode::F23 => 0x72,
        KeyCode::F24 => 0x73,
        KeyCode::AudioVolumeMute => 0x7f,
        KeyCode::AudioVolumeUp => 0x80,
        KeyCode::AudioVolumeDown => 0x81,
        KeyCode::ControlLeft => 0xe0,
        KeyCode::ShiftLeft => 0xe1,
        KeyCode::AltLeft => 0xe2,
        KeyCode::MetaLeft => 0xe3,
        KeyCode::ControlRight => 0xe4,
        KeyCode::ShiftRight => 0xe5,
        KeyCode::AltRight => 0xe6,
        KeyCode::MetaRight => 0xe7,
        _ => return None,
    })
}

fn logical_key_id(key: &Key, physical_key: PhysicalKey, physical: u64) -> u64 {
    if let PhysicalKey::Code(code) = physical_key
        && let Some(numpad) = numpad_logical_key(code)
    {
        return numpad;
    }
    match key {
        Key::Character(value) => value
            .chars()
            .next()
            .and_then(|value| value.to_lowercase().next())
            .map_or(
                CurrentPlatform::FALLBACK_KEY_PLANE | (physical & KEY_VALUE_MASK),
                |value| u64::from(value as u32),
            ),
        Key::Named(named) => named_logical_key(*named, physical_key)
            .unwrap_or(CurrentPlatform::FALLBACK_KEY_PLANE | (physical & KEY_VALUE_MASK)),
        Key::Unidentified(NativeKey::Xkb(code)) => {
            CurrentPlatform::FALLBACK_KEY_PLANE | u64::from(*code)
        }
        Key::Unidentified(_) | Key::Dead(_) => {
            CurrentPlatform::FALLBACK_KEY_PLANE | (physical & KEY_VALUE_MASK)
        }
    }
}

fn numpad_logical_key(code: KeyCode) -> Option<u64> {
    Some(match code {
        KeyCode::Numpad0 => 0x00200000230,
        KeyCode::Numpad1 => 0x00200000231,
        KeyCode::Numpad2 => 0x00200000232,
        KeyCode::Numpad3 => 0x00200000233,
        KeyCode::Numpad4 => 0x00200000234,
        KeyCode::Numpad5 => 0x00200000235,
        KeyCode::Numpad6 => 0x00200000236,
        KeyCode::Numpad7 => 0x00200000237,
        KeyCode::Numpad8 => 0x00200000238,
        KeyCode::Numpad9 => 0x00200000239,
        _ => return None,
    })
}

fn named_logical_key(named: NamedKey, physical_key: PhysicalKey) -> Option<u64> {
    Some(match named {
        NamedKey::Backspace => 0x00100000008,
        NamedKey::Tab => 0x00100000009,
        NamedKey::Enter => 0x0010000000d,
        NamedKey::Escape => 0x0010000001b,
        NamedKey::Delete => 0x0010000007f,
        NamedKey::CapsLock => 0x00100000104,
        NamedKey::NumLock => 0x0010000010a,
        NamedKey::ScrollLock => 0x0010000010c,
        NamedKey::ArrowDown => 0x00100000301,
        NamedKey::ArrowLeft => 0x00100000302,
        NamedKey::ArrowRight => 0x00100000303,
        NamedKey::ArrowUp => 0x00100000304,
        NamedKey::End => 0x00100000305,
        NamedKey::Home => 0x00100000306,
        NamedKey::PageDown => 0x00100000307,
        NamedKey::PageUp => 0x00100000308,
        NamedKey::Insert => 0x00100000407,
        NamedKey::ContextMenu => 0x00100000505,
        NamedKey::Pause => 0x00100000509,
        NamedKey::PrintScreen => 0x00100000608,
        NamedKey::F1 => 0x00100000801,
        NamedKey::F2 => 0x00100000802,
        NamedKey::F3 => 0x00100000803,
        NamedKey::F4 => 0x00100000804,
        NamedKey::F5 => 0x00100000805,
        NamedKey::F6 => 0x00100000806,
        NamedKey::F7 => 0x00100000807,
        NamedKey::F8 => 0x00100000808,
        NamedKey::F9 => 0x00100000809,
        NamedKey::F10 => 0x0010000080a,
        NamedKey::F11 => 0x0010000080b,
        NamedKey::F12 => 0x0010000080c,
        NamedKey::Control => match physical_key {
            PhysicalKey::Code(KeyCode::ControlRight) => 0x00200000101,
            _ => 0x00200000100,
        },
        NamedKey::Shift => match physical_key {
            PhysicalKey::Code(KeyCode::ShiftRight) => 0x00200000103,
            _ => 0x00200000102,
        },
        NamedKey::Alt | NamedKey::AltGraph => match physical_key {
            PhysicalKey::Code(KeyCode::AltRight) => 0x00200000105,
            _ => 0x00200000104,
        },
        NamedKey::Meta => match physical_key {
            PhysicalKey::Code(KeyCode::MetaRight) => 0x00200000107,
            _ => 0x00200000106,
        },
        _ => return None,
    })
}

fn mouse_button_mask(button: MouseButton) -> Option<i64> {
    match button {
        MouseButton::Left => Some(MOUSE_PRIMARY_BUTTON),
        MouseButton::Right => Some(MOUSE_SECONDARY_BUTTON),
        MouseButton::Middle => Some(MOUSE_MIDDLE_BUTTON),
        MouseButton::Back => Some(MOUSE_BACK_BUTTON),
        MouseButton::Forward => Some(MOUSE_FORWARD_BUTTON),
        MouseButton::Button6
        | MouseButton::Button7
        | MouseButton::Button8
        | MouseButton::Button9
        | MouseButton::Button10
        | MouseButton::Button11
        | MouseButton::Button12
        | MouseButton::Button13
        | MouseButton::Button14
        | MouseButton::Button15
        | MouseButton::Button16 => None,
        _ => None,
    }
}

fn touch_device_id(winit_id: u64) -> i64 {
    i64::try_from(winit_id)
        .ok()
        .and_then(|id| id.checked_add(1))
        .unwrap_or(i64::MAX)
}

/// Rust-owned state for a single merged Flutter UI/platform task runner.
///
/// The value must have a stable address for as long as C++ retains the
/// callback table returned by [`Self::callbacks`]. A `Box<TaskRunnerHost>`
/// satisfies that requirement. Winit integration owns the box and wakes its
/// loop after scheduling; that wake is added with the C++ shell bootstrap.
pub struct TaskRunnerHost {
    queue: Mutex<TaskQueue>,
    task_runner: Mutex<Option<usize>>,
    wake_proxy: Option<HostEventSender>,
    host_thread: ThreadId,
    destroyed: AtomicBool,
}

impl Default for TaskRunnerHost {
    fn default() -> Self {
        Self::new()
    }
}

impl TaskRunnerHost {
    pub fn new() -> Self {
        Self::with_wake_proxy(None)
    }

    fn with_wake_proxy(wake_proxy: Option<HostEventSender>) -> Self {
        Self {
            queue: Mutex::new(TaskQueue::default()),
            task_runner: Mutex::new(None),
            wake_proxy,
            host_thread: std::thread::current().id(),
            destroyed: AtomicBool::new(false),
        }
    }

    pub fn callbacks(&self) -> FlutterRustTaskRunnerCallbacks {
        FlutterRustTaskRunnerCallbacks {
            user_data: (self as *const Self).cast_mut().cast::<c_void>(),
            schedule_task: Some(schedule_task),
            runs_tasks_on_current_thread: Some(runs_tasks_on_current_thread),
            task_runner_destroyed: Some(task_runner_destroyed),
        }
    }

    pub fn take_due(&self, now: Instant) -> Vec<ScheduledTask> {
        self.queue.lock().take_due(now)
    }

    pub fn is_destroyed(&self) -> bool {
        self.destroyed.load(Ordering::Acquire)
    }

    /// The opaque C++ task runner handle installed by
    /// `install_cpp_task_runner`. Used as the merged Flutter
    /// UI/platform task runner when creating the Rust shell.
    pub fn task_runner_handle(&self) -> *mut c_void {
        self.task_runner
            .lock()
            .expect("the C++ task runner has not been installed yet") as *mut c_void
    }

    fn install_cpp_task_runner(&self) {
        let task_runner = CurrentEngine::create_task_runner(self.callbacks());
        assert!(
            !task_runner.is_null(),
            "C++ failed to create the Flutter Rust task runner"
        );
        *self.task_runner.lock() = Some(task_runner as usize);
    }

    fn dispatch_due_tasks(&self) {
        for task in self.take_due(Instant::now()) {
            CurrentEngine::run_task(task.task_runner as *mut c_void, task.task_baton);
        }
    }

    fn next_deadline(&self) -> Option<Instant> {
        self.queue.lock().next_deadline()
    }
}

impl Drop for TaskRunnerHost {
    fn drop(&mut self) {
        let task_runner = self.task_runner.get_mut().take();
        if let Some(task_runner) = task_runner {
            CurrentEngine::destroy_task_runner(task_runner as *mut c_void);
        }
    }
}

extern "C" fn schedule_task(
    user_data: *mut c_void,
    task_runner: *mut c_void,
    task_baton: u64,
    delay_nanos: u64,
) {
    // SAFETY: callbacks() sets user_data to a stable TaskRunnerHost address,
    // and C++ promises to stop calling it before task_runner_destroyed.
    let host = unsafe { &*user_data.cast::<TaskRunnerHost>() };
    let deadline = Instant::now() + Duration::from_nanos(delay_nanos);
    host.queue.lock().schedule(
        ScheduledTask {
            task_runner: task_runner as usize,
            task_baton,
        },
        deadline,
    );
    if let Some(wake_proxy) = &host.wake_proxy {
        let _ = wake_proxy.send_event(HostEvent::TaskScheduled);
    }
}

extern "C" fn runs_tasks_on_current_thread(user_data: *mut c_void) -> i32 {
    // SAFETY: see schedule_task; this callback has the same lifetime.
    let host = unsafe { &*user_data.cast::<TaskRunnerHost>() };
    i32::from(std::thread::current().id() == host.host_thread)
}

extern "C" fn task_runner_destroyed(user_data: *mut c_void) {
    // SAFETY: see schedule_task; this is the last C++ callback for the host.
    let host = unsafe { &*user_data.cast::<TaskRunnerHost>() };
    host.destroyed.store(true, Ordering::Release);
}

/// Stable Rust-owned endpoint used by C++ to wake the winit loop for the
/// next compositor frame. The atomic coalesces redundant wakeups before
/// winit has observed the first request.
struct VsyncHost {
    wake_proxy: HostEventSender,
    request_pending: AtomicBool,
}
impl VsyncHost {
    fn new(wake_proxy: HostEventSender) -> Self {
        Self {
            wake_proxy,
            request_pending: AtomicBool::new(false),
        }
    }

    fn callbacks(&self, compositor_timing_available: bool) -> FlutterRustVsyncCallbacks {
        FlutterRustVsyncCallbacks {
            user_data: (self as *const Self).cast_mut().cast::<c_void>(),
            request_vsync: compositor_timing_available.then_some(request_vsync),
        }
    }

    fn take_request(&self) -> bool {
        self.request_pending.swap(false, Ordering::AcqRel)
    }
}
extern "C" fn request_vsync(user_data: *mut c_void) {
    // SAFETY: callbacks() points at a boxed VsyncHost which outlives the
    // C++ shell and therefore every request through this callback table.
    let host = unsafe { &*user_data.cast::<VsyncHost>() };
    if host
        .request_pending
        .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
        .is_ok()
        && host
            .wake_proxy
            .send_event(HostEvent::VsyncRequested)
            .is_err()
    {
        host.request_pending.store(false, Ordering::Release);
    }
}

/// C entry point for the private C++ runner executable. `assets_path` and
/// `icu_data_path` are borrowed only for the duration of this call.
/// `aot_library_path` may be null when running from a JIT kernel snapshot;
/// otherwise it is borrowed for the same duration and points at the
/// AOT-compiled application library (`libapp.so`).
/// Returns non-zero once the winit event loop exits normally.
///
/// # Safety
///
/// `assets_path` and `icu_data_path` must be valid, NUL-terminated C
/// strings for the duration of this call. `aot_library_path` must be either
/// null or a valid, NUL-terminated C string for the duration of this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn FlutterRustShellRun(
    assets_path: *const std::ffi::c_char,
    icu_data_path: *const std::ffi::c_char,
    aot_library_path: *const std::ffi::c_char,
) -> i32 {
    // SAFETY: the caller guarantees both pointers are valid, NUL-terminated
    // C strings for the duration of this call, and that aot_library_path is
    // either null or a valid, NUL-terminated C string.
    let config = unsafe {
        ShellConfig {
            assets_path: std::ffi::CStr::from_ptr(assets_path)
                .to_string_lossy()
                .into_owned(),
            icu_data_path: std::ffi::CStr::from_ptr(icu_data_path)
                .to_string_lossy()
                .into_owned(),
            aot_library_path: if aot_library_path.is_null() {
                String::new()
            } else {
                std::ffi::CStr::from_ptr(aot_library_path)
                    .to_string_lossy()
                    .into_owned()
            },
            presentation_stats_path: std::env::var_os("FLUTTER_RUST_PRESENTATION_STATS")
                .map(PathBuf::from),
            ..ShellConfig::default()
        }
    };
    let result = if std::env::var_os("FLUTTER_RUST_TEXTURE_DEMO").is_some() {
        run_texture_fixture(config)
    } else {
        run(config)
    };
    if let Err(error) = &result {
        log::error!("{error}");
    }
    i32::from(result.is_ok())
}

fn run_texture_fixture(config: ShellConfig) -> Result<(), RunError> {
    let texture = Arc::new(Mutex::new(None));
    let plugin_texture = Arc::clone(&texture);
    let pixel_buffer = std::env::var_os("FLUTTER_RUST_PIXEL_BUFFER_TEXTURE_DEMO").is_some();
    run_application_with_fixture(
        config,
        Box::new(move |registrar| {
            DemoTexturePlugin {
                texture: plugin_texture,
                pixel_buffer,
            }
            .register(registrar)
        }),
        Some(DemoTextureFixture {
            texture,
            pixel_buffer,
        }),
    )
}

/// Backs the `log` crate with a plain stderr sink so first-party code and
/// dependencies (winit, wgpu) route diagnostics through `log::*!` instead
/// of raw prints. The level defaults to `Info` and can be overridden with
/// `FLUTTER_RUST_SHELL_LOG` (e.g. `debug`, `warn`).
struct StderrLogger;

impl log::Log for StderrLogger {
    fn enabled(&self, metadata: &log::Metadata<'_>) -> bool {
        metadata.level() <= log::max_level()
    }

    fn log(&self, record: &log::Record<'_>) {
        if self.enabled(record.metadata()) {
            eprintln!(
                "[{}] {}: {}",
                record.level(),
                record.target(),
                record.args()
            );
        }
    }

    fn flush(&self) {}
}

fn init_logging() {
    static LOGGER: StderrLogger = StderrLogger;
    let level = std::env::var("FLUTTER_RUST_SHELL_LOG")
        .ok()
        .and_then(|value| value.parse::<log::LevelFilter>().ok())
        .unwrap_or(log::LevelFilter::Info);
    log::set_max_level(level);
    let _ = log::set_logger(&LOGGER);
}

/// Carries the `AndroidApp` winit's `EventLoopBuilder` needs on Android,
/// where (unlike every other platform) it is not global state and must be
/// supplied explicitly before building the event loop. `android_main` calls
/// [`set_android_app`] before calling [`run_application`]; this keeps
/// `run_application`'s signature identical across platforms.
#[cfg(target_os = "android")]
mod android_app {
    use std::sync::OnceLock;
    use winit::platform::android::activity::AndroidApp;

    static ANDROID_APP: OnceLock<AndroidApp> = OnceLock::new();

    pub(crate) fn take() -> AndroidApp {
        ANDROID_APP
            .get()
            .cloned()
            .expect("set_android_app must be called before run_application on Android")
    }

    pub(crate) fn set(app: AndroidApp) {
        ANDROID_APP
            .set(app)
            .unwrap_or_else(|_| panic!("set_android_app must only be called once"));
    }
}

#[cfg(target_os = "android")]
pub fn set_android_app(app: winit::platform::android::activity::AndroidApp) {
    android_app::set(app);
}

/// Runs an application with no source-linked Rust plugins.
pub fn run(config: ShellConfig) -> Result<(), RunError> {
    run_application(config, |_| Ok(()))
}

/// Runs an application and invokes its generated plugin-registration entry
/// point exactly once after the engine, implicit view, platform dispatcher,
/// and shell capabilities are ready.
///
/// Generated application aggregates pass their
/// `register_application(&mut PluginRegistrar)` function here. Registration
/// occurs on the winit owning thread before the event loop begins normal
/// event delivery.
pub fn run_application<F>(config: ShellConfig, register_application: F) -> Result<(), RunError>
where
    F: FnOnce(&mut PluginRegistrar) -> PluginResult<()> + 'static,
{
    run_application_with_fixture(config, Box::new(register_application), None)
}

type ApplicationRegistration = Box<dyn FnOnce(&mut PluginRegistrar) -> PluginResult<()> + 'static>;

fn register_application_once(
    registration: &mut Option<ApplicationRegistration>,
    registrar: &mut PluginRegistrar,
) -> PluginResult<()> {
    registration
        .take()
        .expect("application plugins registered more than once")(registrar)
}

fn run_application_with_fixture(
    config: ShellConfig,
    register_application: ApplicationRegistration,
    demo_fixture: Option<DemoTextureFixture>,
) -> Result<(), RunError> {
    init_logging();
    #[cfg(target_os = "android")]
    let event_loop = {
        use winit::platform::android::EventLoopBuilderExtAndroid;
        EventLoop::builder()
            .with_android_app(android_app::take())
            .build()?
    };
    #[cfg(not(target_os = "android"))]
    let event_loop = EventLoop::new()?;
    let event_proxy = HostEventSender::new(event_loop.create_proxy());
    let dispatcher_events = event_proxy.clone();
    let main_thread_dispatcher = MainThreadDispatcher::for_shell_inactive(
        move |task| {
            dispatcher_events
                .send_event(HostEvent::MainThreadTask(task))
                .is_ok()
        },
        std::thread::current().id(),
    );
    let plugin_registrar = PluginRegistrar::for_shell(main_thread_dispatcher.clone());
    let registration_error = Arc::new(Mutex::new(None));
    let retained_textures = Arc::new(Mutex::new(Vec::new()));
    let task_runner_host = Box::new(TaskRunnerHost::with_wake_proxy(Some(event_proxy.clone())));
    task_runner_host.install_cpp_task_runner();
    let vsync_host = Box::new(VsyncHost::new(event_proxy.clone()));
    let text_input_inbox = Box::new(TextInputInbox::new(event_proxy.clone()));
    let windows = Rc::new(RefCell::new(WindowRegistry {
        views: HashMap::new(),
        view_windows: HashMap::new(),
        removing_views: HashSet::new(),
        focused_window: None,
        next_view_id: 1,
        event_proxy: event_proxy.clone(),
        shell: None,
        window_event_callback: None,
    }));
    let application = ShellApplication {
        config,
        windows,
        host_events: event_proxy,
        task_runner_host,
        vsync_host,
        vsync_armed: false,
        text_input_inbox,
        text_input_session: TextInputSession::default(),
        lifecycle_state: LifecycleState::new(),
        main_thread_dispatcher,
        plugin_registrar,
        register_application: Some(register_application),
        registration_error: Arc::clone(&registration_error),
        retained_textures,
        demo_fixture,
        demo_texture: None,
    };
    event_loop.run_app(application)?;
    match registration_error.lock().take() {
        Some(error) => Err(RunError::PluginRegistration(error)),
        None => Ok(()),
    }
}
struct ShellApplication {
    config: ShellConfig,
    windows: Rc<RefCell<WindowRegistry>>,
    host_events: HostEventSender,
    task_runner_host: Box<TaskRunnerHost>,
    vsync_host: Box<VsyncHost>,
    vsync_armed: bool,
    text_input_inbox: Box<TextInputInbox>,
    text_input_session: TextInputSession,
    lifecycle_state: LifecycleState,
    main_thread_dispatcher: MainThreadDispatcher,
    plugin_registrar: PluginRegistrar,
    register_application: Option<ApplicationRegistration>,
    registration_error: Arc<Mutex<Option<PluginError>>>,
    retained_textures: Arc<Mutex<Vec<Arc<RegisteredWgpuTexture>>>>,
    demo_fixture: Option<DemoTextureFixture>,
    demo_texture: Option<DemoTexture>,
}
struct DemoTextureFixture {
    texture: Arc<Mutex<Option<DemoTextureHandle>>>,
    pixel_buffer: bool,
}
struct DemoTexture {
    gpu: GpuTextures,
    texture: DemoTextureHandle,
    next_frame: Instant,
    phase: u64,
    frames_on_texture: u8,
    lifecycle_remaining: usize,
    lifecycle_completed: usize,
    lifecycle_status_path: Option<std::path::PathBuf>,
    lifecycle_not_before: Instant,
    pixel_buffer: bool,
    dart_ready: bool,
    pending_replacement: Option<PendingTextureReplacement>,
    context_recreated: Arc<AtomicBool>,
    context_recreate_requested: bool,
    context_recreate_at: usize,
}
struct PendingTextureReplacement {
    texture: DemoTextureHandle,
    acknowledged: bool,
    frames: u8,
    generation: usize,
}
enum DemoTextureHandle {
    Wgpu(WgpuTexture),
    Pixels(PixelBufferTexture),
}
impl DemoTextureHandle {
    fn texture_id(&self) -> i64 {
        match self {
            Self::Wgpu(texture) => texture.texture_id(),
            Self::Pixels(texture) => texture.texture_id(),
        }
    }
}
fn create_demo_texture(
    gpu: &GpuTextures,
    pixel_buffer: bool,
    width: u32,
    height: u32,
) -> PluginResult<DemoTextureHandle> {
    let descriptor = TextureDescriptor {
        width,
        height,
        format: TextureFormat::Rgba8Unorm,
    };
    if pixel_buffer {
        Ok(DemoTextureHandle::Pixels(
            gpu.create_pixel_buffer_texture(descriptor)?,
        ))
    } else {
        Ok(DemoTextureHandle::Wgpu(gpu.create_texture(descriptor)?))
    }
}
struct RegisteredWgpuTexture {
    ring: Box<WgpuTextureRing>,
    texture_id: i64,
    unregistered: AtomicBool,
}
struct ShellWgpuTextureBackend {
    context: Arc<GpuContext>,
    dispatcher: MainThreadDispatcher,
    shell_address: usize,
    retained: Arc<Mutex<Vec<Arc<RegisteredWgpuTexture>>>>,
}
struct ShellWgpuTextureHandle {
    registration: Arc<RegisteredWgpuTexture>,
    dispatcher: MainThreadDispatcher,
    shell_address: usize,
    retained: Arc<Mutex<Vec<Arc<RegisteredWgpuTexture>>>>,
}
struct TextureReclamation {
    texture_id: i64,
    retained: Arc<Mutex<Vec<Arc<RegisteredWgpuTexture>>>>,
}
unsafe extern "C" fn reclaim_external_texture(user_data: *mut c_void) {
    if user_data.is_null() {
        return;
    }
    // SAFETY: unregister transfers one Box<TextureReclamation> to C++,
    // which calls this function exactly once after raster unregister.
    let reclamation = unsafe { Box::from_raw(user_data.cast::<TextureReclamation>()) };
    reclamation
        .retained
        .lock()
        .retain(|registration| registration.texture_id != reclamation.texture_id);
    log::info!(
        "Flutter Rust external texture {} reclaimed",
        reclamation.texture_id
    );
}
unsafe extern "C" fn texture_context_recreated(user_data: *mut c_void) {
    if user_data.is_null() {
        return;
    }
    // SAFETY: the test hook consumes exactly one Arc raw pointer after its
    // raster-thread destroy/create notification pair completes.
    let completed = unsafe { Arc::from_raw(user_data.cast::<AtomicBool>()) };
    completed.store(true, Ordering::Release);
    log::info!("Flutter Rust texture context recreation completed");
}
impl ShellWgpuTextureHandle {
    fn unregister(&self) {
        if self
            .registration
            .unregistered
            .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
            .is_err()
        {
            return;
        }
        let shell_address = self.shell_address;
        let texture_id = self.registration.texture_id;
        let reclamation = Box::new(TextureReclamation {
            texture_id,
            retained: Arc::clone(&self.retained),
        });
        if self
            .dispatcher
            .dispatch(move || {
                let reclamation_address = Box::into_raw(reclamation);
                unregister_cpp_external_texture(
                    shell_address as *mut c_void,
                    texture_id,
                    Some(reclaim_external_texture),
                    reclamation_address.cast::<c_void>(),
                );
            })
            .is_err()
        {
            self.registration
                .unregistered
                .store(false, Ordering::Release);
        }
    }
}
#[async_trait::async_trait]
impl PixelBufferTextureBackendHandle for ShellWgpuTextureHandle {
    fn texture_id(&self) -> i64 {
        self.registration.texture_id
    }

    fn try_next_frame(&self) -> PluginResult<Arc<dyn PixelBufferTextureFrameBackend>> {
        PixelBufferTextureBackendHandle::try_next_frame(self.registration.ring.as_ref())
    }

    async fn next_frame(&self) -> PluginResult<Arc<dyn PixelBufferTextureFrameBackend>> {
        PixelBufferTextureBackendHandle::next_frame(self.registration.ring.as_ref()).await
    }
}
impl Drop for ShellWgpuTextureHandle {
    fn drop(&mut self) {
        self.registration.ring.shutdown();
        self.unregister();
    }
}
#[async_trait::async_trait]
impl WgpuTextureBackendHandle for ShellWgpuTextureHandle {
    fn texture_id(&self) -> i64 {
        self.registration.texture_id
    }

    fn try_next_frame(&self) -> PluginResult<Arc<dyn WgpuTextureFrameBackend>> {
        WgpuTextureBackendHandle::try_next_frame(self.registration.ring.as_ref())
    }

    async fn next_frame(&self) -> PluginResult<Arc<dyn WgpuTextureFrameBackend>> {
        WgpuTextureBackendHandle::next_frame(self.registration.ring.as_ref()).await
    }
}
impl WgpuTextureBackend for ShellWgpuTextureBackend {
    fn create_texture(
        &self,
        descriptor: TextureDescriptor,
    ) -> PluginResult<Arc<dyn WgpuTextureBackendHandle>> {
        if !self.dispatcher.is_main_thread() {
            return Err(PluginError::Unsupported);
        }
        if descriptor.format != TextureFormat::Rgba8Unorm {
            return Err(PluginError::InvalidDescriptor);
        }
        let ring = self
            .context
            .create_texture_ring(descriptor.width, descriptor.height)
            .map_err(|_| PluginError::InvalidDescriptor)?;
        let texture_id =
            register_cpp_external_texture(self.shell_address as *mut c_void, ring.callbacks());
        if texture_id <= 0 {
            return Err(PluginError::Shutdown);
        }
        let dispatcher = self.dispatcher.clone();
        let shell_address = self.shell_address;
        ring.set_registration(texture_id, move |texture_id| {
            dispatcher
                .dispatch(move || {
                    mark_cpp_external_texture_frame_available(
                        shell_address as *mut c_void,
                        texture_id,
                    );
                })
                .map_err(|_| PluginError::Shutdown)
        });
        let registration = Arc::new(RegisteredWgpuTexture {
            ring,
            texture_id,
            unregistered: AtomicBool::new(false),
        });
        self.retained.lock().push(Arc::clone(&registration));
        Ok(Arc::new(ShellWgpuTextureHandle {
            registration,
            dispatcher: self.dispatcher.clone(),
            shell_address: self.shell_address,
            retained: Arc::clone(&self.retained),
        }))
    }

    fn create_pixel_buffer_texture(
        &self,
        descriptor: TextureDescriptor,
    ) -> PluginResult<Arc<dyn PixelBufferTextureBackendHandle>> {
        if !self.dispatcher.is_main_thread() {
            return Err(PluginError::Unsupported);
        }
        if descriptor.format != TextureFormat::Rgba8Unorm {
            return Err(PluginError::InvalidDescriptor);
        }
        let ring = self
            .context
            .create_pixel_buffer_texture_ring(descriptor.width, descriptor.height)
            .map_err(|_| PluginError::InvalidDescriptor)?;
        let texture_id =
            register_cpp_external_texture(self.shell_address as *mut c_void, ring.callbacks());
        if texture_id <= 0 {
            return Err(PluginError::Shutdown);
        }
        let dispatcher = self.dispatcher.clone();
        let shell_address = self.shell_address;
        ring.set_registration(texture_id, move |texture_id| {
            dispatcher
                .dispatch(move || {
                    mark_cpp_external_texture_frame_available(
                        shell_address as *mut c_void,
                        texture_id,
                    );
                })
                .map_err(|_| PluginError::Shutdown)
        });
        let registration = Arc::new(RegisteredWgpuTexture {
            ring,
            texture_id,
            unregistered: AtomicBool::new(false),
        });
        self.retained.lock().push(Arc::clone(&registration));
        Ok(Arc::new(ShellWgpuTextureHandle {
            registration,
            dispatcher: self.dispatcher.clone(),
            shell_address: self.shell_address,
            retained: Arc::clone(&self.retained),
        }))
    }
}
struct DemoTexturePlugin {
    texture: Arc<Mutex<Option<DemoTextureHandle>>>,
    pixel_buffer: bool,
}
impl FlutterRustPlugin for DemoTexturePlugin {
    fn register(&self, registrar: &mut PluginRegistrar) -> PluginResult<()> {
        let texture = create_demo_texture(registrar.gpu()?, self.pixel_buffer, 256, 256)?;
        *self.texture.lock() = Some(texture);
        Ok(())
    }
}
struct WindowRegistry {
    views: HashMap<WindowId, ViewWindow>,
    view_windows: HashMap<FlutterRustViewId, WindowId>,
    removing_views: HashSet<FlutterRustViewId>,
    focused_window: Option<WindowId>,
    next_view_id: i64,
    event_proxy: HostEventSender,
    shell: Option<*mut c_void>,
    window_event_callback: Option<FlutterRustWindowEventCallback>,
}

struct ViewWindow {
    view_id: FlutterRustViewId,
    kind: NativeWindowKind,
    parent_view_id: Option<FlutterRustViewId>,
    // The broker must be destroyed before its native window. Keeping it
    // first makes that ordering automatic when a view leaves the map.
    gpu_broker: Box<GpuBroker>,
    window: Arc<dyn Window>,
    // A transient child's native parent must outlive its relationship.
    _parent_window: Option<Arc<dyn Window>>,
    pointer_state: PointerState,
    keyboard_state: KeyboardState,
    visible: bool,
    focused: bool,
}

struct RemovedViewState {
    _view: ViewWindow,
    callback: Option<FlutterRustWindowEventCallback>,
}
struct CreatedRegularView {
    shell: *mut c_void,
    view_id: FlutterRustViewId,
    metrics: WindowMetrics,
    presentation_callbacks: FlutterRustVulkanPresentationCallbacks,
    event_proxy: HostEventSender,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum NativeWindowKind {
    Regular,
    Dialog,
    Tooltip,
    Popup,
    Satellite,
}

impl ShellApplication {
    fn start_demo_texture_fixture(&mut self) {
        let Some(fixture) = self.demo_fixture.take() else {
            return;
        };
        let texture = fixture
            .texture
            .lock()
            .take()
            .expect("demo application registrar did not create its texture");
        let texture_id = texture.texture_id();
        log::info!("Flutter Rust demo texture ID: {texture_id}");
        if let Some(path) = std::env::var_os("FLUTTER_RUST_TEXTURE_ID_FILE") {
            std::fs::write(path, format!("{texture_id}\n"))
                .expect("failed to write demo texture ID");
        }
        let lifecycle_remaining = std::env::var("FLUTTER_RUST_TEXTURE_LIFECYCLE_ITERATIONS")
            .ok()
            .and_then(|value| value.parse().ok())
            .unwrap_or(0);
        self.demo_texture = Some(DemoTexture {
            gpu: self
                .plugin_registrar
                .gpu()
                .expect("demo texture GPU capability disappeared")
                .clone(),
            texture,
            next_frame: Instant::now() + Duration::from_millis(16),
            phase: 0,
            frames_on_texture: 0,
            lifecycle_remaining,
            lifecycle_completed: 0,
            lifecycle_status_path: std::env::var_os("FLUTTER_RUST_TEXTURE_LIFECYCLE_STATUS")
                .map(std::path::PathBuf::from),
            lifecycle_not_before: Instant::now() + Duration::from_secs(1),
            pixel_buffer: fixture.pixel_buffer,
            dart_ready: false,
            pending_replacement: None,
            context_recreated: Arc::new(AtomicBool::new(false)),
            context_recreate_requested: false,
            context_recreate_at: lifecycle_remaining / 2,
        });
    }
}

impl Drop for ShellApplication {
    fn drop(&mut self) {
        self.main_thread_dispatcher.shutdown_for_shell();
        let mut windows = self.windows.borrow_mut();
        if let Some(shell) = windows.shell.take() {
            let demo = self.demo_texture.take();
            drop(demo);
            for registration in self.retained_textures.lock().iter() {
                registration.unregistered.store(true, Ordering::Release);
                // The C++ operation is idempotent. Repeat it here even if
                // handle drop tried to enqueue it, because dispatcher
                // shutdown suppresses queued callbacks during teardown.
                unregister_cpp_external_texture(
                    shell,
                    registration.texture_id,
                    None,
                    std::ptr::null_mut(),
                );
            }
            destroy_cpp_shell(shell);
            // Unregister posts to the raster runner. Shell destruction
            // drains and joins that runner before the callback owner and
            // its Vulkan semaphores are released here.
            self.retained_textures.lock().clear();
        }

        // Each ViewWindow declares its broker before its Arc<Window>, so
        // clearing the map tears down every swapchain before its native
        // Wayland surface.
        windows.views.clear();
        windows.view_windows.clear();
    }
}

impl ApplicationHandler for ShellApplication {
    fn can_create_surfaces(&mut self, event_loop: &dyn ActiveEventLoop) {
        if !self
            .windows
            .borrow()
            .view_windows
            .contains_key(&FlutterRustViewId::IMPLICIT)
        {
            let attributes = WindowAttributes::default().with_title(&self.config.title);
            let window: Arc<dyn Window> = Arc::from(
                event_loop
                    .create_window(attributes)
                    .expect("winit failed to create the Flutter Rust Shell window"),
            );
            let gpu_broker = Box::new(
                GpuBroker::new(
                    Arc::clone(&window),
                    self.config.presentation_stats_path.clone(),
                )
                .expect("winit Vulkan surface creation failed"),
            );
            let size = window.surface_size();
            gpu_broker
                .configure(size.width, size.height)
                .expect("winit Vulkan surface configuration failed");
            {
                let assets_path = CString::new(self.config.assets_path.as_str())
                    .expect("assets path contains a NUL byte");
                let icu_data_path = CString::new(self.config.icu_data_path.as_str())
                    .expect("icu data path contains a NUL byte");
                let aot_library_path = if self.config.aot_library_path.is_empty() {
                    None
                } else {
                    Some(
                        CString::new(self.config.aot_library_path.as_str())
                            .expect("aot library path contains a NUL byte"),
                    )
                };
                let settings = FlutterRustShellSettings {
                    assets_path: assets_path.as_ptr(),
                    icu_data_path: icu_data_path.as_ptr(),
                    aot_library_path: aot_library_path
                        .as_ref()
                        .map_or(std::ptr::null(), |path| path.as_ptr()),
                };
                let presentation_callbacks = gpu_broker.presentation_callbacks();
                let platform_message_callbacks = self.text_input_inbox.callbacks();
                let vsync_callbacks = self
                    .vsync_host
                    .callbacks(CurrentPlatform::is_wayland(event_loop));
                let task_runner_handle = self.task_runner_host.task_runner_handle();
                let shell = gpu_broker
                    .with_vulkan_context(|context_data| {
                        let instance_extensions: Vec<CString> = context_data
                            .instance_extensions
                            .iter()
                            .map(|name| {
                                CString::new(name.as_str())
                                    .expect("extension name contains a NUL byte")
                            })
                            .collect();
                        let instance_extension_ptrs: Vec<*const std::ffi::c_char> =
                            instance_extensions
                                .iter()
                                .map(|name| name.as_ptr())
                                .collect();
                        let device_extensions: Vec<CString> = context_data
                            .device_extensions
                            .iter()
                            .map(|name| {
                                CString::new(name.as_str())
                                    .expect("extension name contains a NUL byte")
                            })
                            .collect();
                        let device_extension_ptrs: Vec<*const std::ffi::c_char> =
                            device_extensions.iter().map(|name| name.as_ptr()).collect();
                        let ffi_context_data = FlutterRustVulkanContextData {
                            get_instance_proc_addr: context_data.get_instance_proc_addr
                                as *mut c_void,
                            instance: context_data.instance as *mut c_void,
                            physical_device: context_data.physical_device as *mut c_void,
                            device: context_data.device as *mut c_void,
                            queue: context_data.queue as *mut c_void,
                            queue_family_index: context_data.queue_family_index,
                            instance_extensions: instance_extension_ptrs.as_ptr(),
                            instance_extensions_count: instance_extension_ptrs.len() as u32,
                            device_extensions: device_extension_ptrs.as_ptr(),
                            device_extensions_count: device_extension_ptrs.len() as u32,
                        };
                        create_cpp_shell(
                            task_runner_handle,
                            ffi_context_data,
                            presentation_callbacks,
                            platform_message_callbacks,
                            vsync_callbacks,
                            windowing_callbacks(),
                            settings,
                        )
                    })
                    .expect("wgpu Vulkan context extraction failed");
                assert!(
                    !shell.is_null(),
                    "C++ failed to create the Flutter Rust shell"
                );
                assert!(
                    run_cpp_shell(shell) != 0,
                    "the Flutter Rust shell failed to start running"
                );
                // The engine has no valid view to schedule frames for
                // until it knows the implicit view's size.
                set_cpp_shell_viewport_metrics(
                    shell,
                    FlutterRustViewId::IMPLICIT,
                    WindowMetrics::from_window(window.as_ref(), window.scale_factor()),
                );
                let gpu_backend = Arc::new(ShellWgpuTextureBackend {
                    context: gpu_broker.shared_context(),
                    dispatcher: self.main_thread_dispatcher.clone(),
                    shell_address: shell as usize,
                    retained: Arc::clone(&self.retained_textures),
                });
                assert!(
                    self.plugin_registrar
                        .install_gpu_for_shell(GpuTextures::for_shell(gpu_backend)),
                    "GPU capability installed more than once"
                );
                self.windows.borrow_mut().shell = Some(shell);
            }

            let window_id = window.id();
            let visible = size.width > 0 && size.height > 0;
            let focused = window.has_focus();
            let mut windows = self.windows.borrow_mut();
            windows.views.insert(
                window_id,
                ViewWindow {
                    view_id: FlutterRustViewId::IMPLICIT,
                    kind: NativeWindowKind::Regular,
                    parent_view_id: None,
                    gpu_broker,
                    window,
                    _parent_window: None,
                    pointer_state: PointerState::new(),
                    keyboard_state: KeyboardState::new(),
                    visible,
                    focused,
                },
            );
            windows
                .view_windows
                .insert(FlutterRustViewId::IMPLICIT, window_id);
            if focused {
                windows.focused_window = Some(window_id);
            }
            drop(windows);
            assert!(
                self.main_thread_dispatcher.start_for_shell(),
                "main-thread dispatcher started more than once"
            );
            if let Err(error) = register_application_once(
                &mut self.register_application,
                &mut self.plugin_registrar,
            ) {
                *self.registration_error.lock() = Some(error);
                event_loop.exit();
                return;
            }
            self.start_demo_texture_fixture();
        }
        let (visible, focused) = self.windows.borrow().aggregate_window_state();
        let state = self.lifecycle_state.resumed(visible, focused);
        self.send_lifecycle_event(state);
    }

    fn suspended(&mut self, _: &dyn ActiveEventLoop) {
        let state = self.lifecycle_state.suspended();
        self.send_lifecycle_event(state);
    }

    fn window_event(
        &mut self,
        event_loop: &dyn ActiveEventLoop,
        window_id: WindowId,
        event: WindowEvent,
    ) {
        let Some(view_id) = self
            .windows
            .borrow()
            .views
            .get(&window_id)
            .map(|view| view.view_id)
        else {
            return;
        };
        match event {
            WindowEvent::SurfaceResized(size) => {
                let (metrics, visible) = {
                    let mut windows = self.windows.borrow_mut();
                    let view = windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared");
                    view.gpu_broker
                        .configure(size.width, size.height)
                        .expect("winit Vulkan surface reconfiguration failed");
                    view.visible = size.width > 0 && size.height > 0;
                    let metrics = WindowMetrics::from_window(
                        view.window.as_ref(),
                        view.window.scale_factor(),
                    );
                    (metrics, windows.aggregate_window_state().0)
                };
                self.windows.borrow().update_satellite_visibility(view_id);
                if let Some(shell) = { self.windows.borrow().shell } {
                    set_cpp_shell_viewport_metrics(shell, view_id, metrics);
                }
                {
                    let callback = { self.windows.borrow().window_event_callback };
                    if let Some(callback) = callback {
                        callback(view_id, FlutterRustWindowEvent::StateChanged);
                    }
                }
                let state = self.lifecycle_state.visibility_changed(visible);
                self.send_lifecycle_event(state);
            }
            WindowEvent::ScaleFactorChanged {
                scale_factor: _scale_factor,
                ..
            } => {
                let metrics = {
                    let mut windows = self.windows.borrow_mut();
                    let view = windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared");
                    let size = view.window.surface_size();
                    view.gpu_broker
                        .configure(size.width, size.height)
                        .expect("winit Vulkan surface reconfiguration failed");
                    WindowMetrics::from_window(view.window.as_ref(), _scale_factor)
                };
                if let Some(shell) = { self.windows.borrow().shell } {
                    set_cpp_shell_viewport_metrics(shell, view_id, metrics);
                }
                {
                    let callback = { self.windows.borrow().window_event_callback };
                    if let Some(callback) = callback {
                        callback(view_id, FlutterRustWindowEvent::StateChanged);
                    }
                }
            }
            WindowEvent::Focused(focused) => {
                let any_focused = {
                    let mut windows = self.windows.borrow_mut();
                    windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared")
                        .focused = focused;
                    if focused {
                        windows.focused_window = Some(window_id);
                    } else if windows.focused_window == Some(window_id) {
                        windows.focused_window = None;
                    }
                    windows.aggregate_window_state().1
                };
                let state = self.lifecycle_state.focus_changed(any_focused);
                self.send_lifecycle_event(state);
                if let Some(shell) = { self.windows.borrow().shell } {
                    send_cpp_view_focus_event(
                        shell,
                        view_id,
                        if focused {
                            FlutterRustViewFocusState::Focused
                        } else {
                            FlutterRustViewFocusState::Unfocused
                        },
                    );
                }
                {
                    let callback = { self.windows.borrow().window_event_callback };
                    if let Some(callback) = callback {
                        callback(view_id, FlutterRustWindowEvent::StateChanged);
                    }
                }
            }
            WindowEvent::KeyboardInput {
                event,
                is_synthetic,
                ..
            } => {
                let (committed_text, key_event) = {
                    let mut windows = self.windows.borrow_mut();
                    let keyboard = &mut windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared")
                        .keyboard_state;
                    let committed_text = keyboard.committed_text(&event).map(str::to_owned);
                    let key_event = keyboard.event(&event, is_synthetic).map(|event| {
                        let raw_message = keyboard.raw_event_message(&event);
                        (event, raw_message)
                    });
                    (committed_text, key_event)
                };
                if let Some((event, raw_message)) = key_event {
                    self.send_key_event(event);
                    self.send_raw_key_event(&raw_message);
                }
                if let Some(message) = committed_text
                    .as_deref()
                    .and_then(|text| self.text_input_session.keyboard_text(text))
                {
                    self.send_text_input_update(&message);
                }
            }
            WindowEvent::ModifiersChanged(modifiers) => {
                self.windows
                    .borrow_mut()
                    .views
                    .get_mut(&window_id)
                    .expect("known window disappeared")
                    .keyboard_state
                    .modifiers_changed(modifiers.state());
            }
            WindowEvent::Ime(event) => {
                if let Some(message) = self.text_input_session.ime(event) {
                    self.send_text_input_update(&message);
                }
            }
            WindowEvent::PointerEntered {
                position,
                kind: PointerKind::Mouse | PointerKind::Unknown,
                ..
            } => {
                let event = {
                    let mut windows = self.windows.borrow_mut();
                    let pointer = &mut windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared")
                        .pointer_state;
                    pointer.physical_x = position.x;
                    pointer.physical_y = position.y;
                    pointer.entered()
                };
                if let Some(event) = event {
                    self.send_pointer_events([event]);
                }
            }
            WindowEvent::PointerLeft {
                kind: PointerKind::Mouse | PointerKind::Unknown,
                ..
            } => {
                let event = {
                    let mut windows = self.windows.borrow_mut();
                    windows
                        .views
                        .get_mut(&window_id)
                        .expect("known window disappeared")
                        .pointer_state
                        .left()
                };
                if let Some(event) = event {
                    self.send_pointer_events([event]);
                }
            }
            WindowEvent::PointerMoved {
                position, source, ..
            } => {
                let mut windows = self.windows.borrow_mut();
                let pointer = &mut windows
                    .views
                    .get_mut(&window_id)
                    .expect("known window disappeared")
                    .pointer_state;
                match source {
                    PointerSource::Touch { finger_id, .. } => {
                        let event = pointer.touch(
                            finger_id.into_raw(),
                            position.x,
                            position.y,
                            TouchPhase::Moved,
                        );
                        drop(windows);
                        self.send_pointer_events([event]);
                    }
                    _ => {
                        let events = pointer.moved(position.x, position.y);
                        drop(windows);
                        self.send_pointer_events(events);
                    }
                }
            }
            WindowEvent::PointerButton {
                state,
                position,
                button,
                ..
            } => {
                let mut windows = self.windows.borrow_mut();
                let pointer = &mut windows
                    .views
                    .get_mut(&window_id)
                    .expect("known window disappeared")
                    .pointer_state;
                match button {
                    ButtonSource::Touch { finger_id, .. } => {
                        let event = pointer.touch(
                            finger_id.into_raw(),
                            position.x,
                            position.y,
                            match state {
                                ElementState::Pressed => TouchPhase::Started,
                                ElementState::Released => TouchPhase::Ended,
                            },
                        );
                        drop(windows);
                        self.send_pointer_events([event]);
                    }
                    button => {
                        pointer.physical_x = position.x;
                        pointer.physical_y = position.y;
                        let events = button
                            .mouse_button()
                            .map_or_else(Vec::new, |button| pointer.button(button, state));
                        drop(windows);
                        self.send_pointer_events(events);
                    }
                }
            }
            WindowEvent::MouseWheel { delta, .. } => {
                let events = self
                    .windows
                    .borrow_mut()
                    .views
                    .get_mut(&window_id)
                    .expect("known window disappeared")
                    .pointer_state
                    .scroll(delta);
                self.send_pointer_events(events);
            }
            WindowEvent::RedrawRequested => {
                if self.vsync_armed {
                    self.vsync_armed = false;
                    if let Some(shell) = { self.windows.borrow().shell } {
                        let interval = {
                            let windows = self.windows.borrow();
                            let view = windows
                                .views
                                .get(&window_id)
                                .expect("known window disappeared");
                            window_frame_interval_nanos(view.window.as_ref())
                        };
                        send_cpp_vsync(shell, interval);
                    }
                }
            }
            WindowEvent::CloseRequested => {
                if view_id == FlutterRustViewId::IMPLICIT {
                    if self.text_input_inbox.exit.begin(None) != ExitRequestStart::NotReady {
                        return;
                    }
                    let state = self.lifecycle_state.detached();
                    self.send_lifecycle_event(state);
                    event_loop.exit();
                } else {
                    {
                        let callback = { self.windows.borrow().window_event_callback };
                        if let Some(callback) = callback {
                            callback(view_id, FlutterRustWindowEvent::CloseRequested);
                        }
                    }
                }
            }
            WindowEvent::Destroyed => {
                if view_id == FlutterRustViewId::IMPLICIT {
                    let state = self.lifecycle_state.detached();
                    self.send_lifecycle_event(state);
                    event_loop.exit();
                } else {
                    {
                        let removals = { self.windows.borrow_mut().begin_remove_views(view_id) };
                        for (view_id, shell, event_proxy) in removals {
                            remove_cpp_shell_view(shell, view_id, event_proxy);
                        }
                    }
                }
            }
            _ => {}
        }
    }

    fn proxy_wake_up(&mut self, event_loop: &dyn ActiveEventLoop) {
        for event in self.host_events.drain() {
            match event {
                HostEvent::TaskScheduled => {}
                HostEvent::VsyncRequested => {
                    if self.vsync_host.take_request() && !self.windows.borrow().views.is_empty() {
                        self.vsync_armed = true;
                        for view in self.windows.borrow().views.values() {
                            view.window.request_redraw();
                        }
                    }
                }
                HostEvent::MainThreadTask(task) => task(),
                HostEvent::ViewOperationCompleted {
                    view_id,
                    operation,
                    succeeded,
                } => match (operation, succeeded) {
                    (ViewOperation::Add, true) => {
                        log::debug!("Flutter view {} was added", view_id.0);
                        let windows = self.windows.borrow();
                        if let Some(window_id) = windows.view_windows.get(&view_id)
                            && let Some(view) = windows.views.get(window_id)
                        {
                            view.window.request_redraw();
                        }
                    }
                    (ViewOperation::Add, false) | (ViewOperation::Remove, true) => {
                        if operation == ViewOperation::Add {
                            log::error!("Flutter rejected view {}", view_id.0);
                        }
                        let removed = self.windows.borrow_mut().take_view_state(view_id);
                        let _callback = removed.as_ref().and_then(|removed| removed.callback);
                        // Native window destruction can synchronously produce
                        // more winit events. Drop it only after releasing the
                        // registry's RefCell borrow.
                        drop(removed);
                        if let Some(callback) = _callback {
                            callback(view_id, FlutterRustWindowEvent::Destroyed);
                        }
                        // The implicit window has its own close/destroy exit
                        // path; a non-implicit view being the last one closed
                        // must also terminate the run loop, or the process
                        // never exits once all windows are gone.
                        if self.windows.borrow().views.is_empty() {
                            let state = self.lifecycle_state.detached();
                            self.send_lifecycle_event(state);
                            event_loop.exit();
                        }
                    }
                    (ViewOperation::Remove, false) => {
                        log::error!("Flutter failed to remove view {}", view_id.0);
                        self.windows.borrow_mut().removing_views.remove(&view_id);
                    }
                },
                HostEvent::RequestAppExit { response } => {
                    let shell = self.windows.borrow().shell;
                    if let Some(shell) = shell {
                        send_cancelable_exit_request(
                            shell,
                            Arc::clone(&self.text_input_inbox.exit),
                            response,
                        );
                    } else {
                        self.text_input_inbox
                            .exit
                            .pending
                            .store(false, Ordering::Release);
                        if let Some(response) = response {
                            complete_cpp_platform_message(
                                response,
                                ApplicationExitResponse::Exit.envelope(),
                            );
                        }
                        let state = self.lifecycle_state.detached();
                        self.send_lifecycle_event(state);
                        event_loop.exit();
                    }
                }
                HostEvent::ExitRequested => {
                    let state = self.lifecycle_state.detached();
                    self.send_lifecycle_event(state);
                    event_loop.exit();
                }
            }
        }
    }

    fn about_to_wait(&mut self, event_loop: &dyn ActiveEventLoop) {
        with_active_windowing_context(event_loop, &self.windows, || {
            self.task_runner_host.dispatch_due_tasks();
        });
        self.apply_text_input_commands();
        if let Some(demo) = &mut self.demo_texture {
            for message in self.text_input_inbox.drain_texture_fixture_messages() {
                if message == "ready" {
                    demo.dart_ready = true;
                } else if let Some(id) = message.strip_prefix("ack ")
                    && id.parse::<i64>().ok()
                        == demo
                            .pending_replacement
                            .as_ref()
                            .map(|pending| pending.texture.texture_id())
                {
                    demo.pending_replacement
                        .as_mut()
                        .expect("checked pending replacement")
                        .acknowledged = true;
                }
            }
        }
        if let Some(demo) = &mut self.demo_texture
            && Instant::now() >= demo.next_frame
        {
            let angle = demo.phase as f64 * 0.04;
            let color = [
                angle.sin() * 0.5 + 0.5,
                (angle + 2.094).sin() * 0.5 + 0.5,
                (angle + 4.189).sin() * 0.5 + 0.5,
                1.0,
            ];
            let presented = match &demo.texture {
                DemoTextureHandle::Wgpu(texture) => {
                    if let Ok(mut frame) = texture.try_next_frame() {
                        frame
                            .render(move |_, encoder, view| {
                                let _pass =
                                    encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                                        label: Some("Flutter Rust plugin demo clear"),
                                        color_attachments: &[Some(
                                            wgpu::RenderPassColorAttachment {
                                                view,
                                                depth_slice: None,
                                                resolve_target: None,
                                                ops: wgpu::Operations {
                                                    load: wgpu::LoadOp::Clear(wgpu::Color {
                                                        r: color[0],
                                                        g: color[1],
                                                        b: color[2],
                                                        a: color[3],
                                                    }),
                                                    store: wgpu::StoreOp::Store,
                                                },
                                            },
                                        )],
                                        ..Default::default()
                                    });
                            })
                            .expect("failed to record demo frame");
                        frame.present().expect("failed to present demo frame");
                        true
                    } else {
                        false
                    }
                }
                DemoTextureHandle::Pixels(texture) => {
                    if let Ok(mut frame) = texture.try_next_frame() {
                        frame
                            .write_pixels(move |pixels, _row_bytes| {
                                let rgba = [
                                    (color[0] * 255.0) as u8,
                                    (color[1] * 255.0) as u8,
                                    (color[2] * 255.0) as u8,
                                    255,
                                ];
                                for pixel in pixels.chunks_exact_mut(4) {
                                    pixel.copy_from_slice(&rgba);
                                }
                            })
                            .expect("failed to write demo pixels");
                        frame.present().expect("failed to present demo pixels");
                        true
                    } else {
                        false
                    }
                }
            };
            if presented {
                demo.frames_on_texture = demo.frames_on_texture.saturating_add(1);
            }
            if let Some(pending) = &mut demo.pending_replacement
                && pending.acknowledged
            {
                let replacement_presented = match &pending.texture {
                    DemoTextureHandle::Wgpu(texture) => {
                        if let Ok(mut frame) = texture.try_next_frame() {
                            frame
                                .render(move |_, encoder, view| {
                                    let _pass =
                                        encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                                            label: Some("Flutter Rust replacement clear"),
                                            color_attachments: &[Some(
                                                wgpu::RenderPassColorAttachment {
                                                    view,
                                                    depth_slice: None,
                                                    resolve_target: None,
                                                    ops: wgpu::Operations {
                                                        load: wgpu::LoadOp::Clear(
                                                            wgpu::Color::BLUE,
                                                        ),
                                                        store: wgpu::StoreOp::Store,
                                                    },
                                                },
                                            )],
                                            ..Default::default()
                                        });
                                })
                                .expect("failed to record replacement frame");
                            frame
                                .present()
                                .expect("failed to present replacement frame");
                            true
                        } else {
                            false
                        }
                    }
                    DemoTextureHandle::Pixels(texture) => {
                        if let Ok(mut frame) = texture.try_next_frame() {
                            frame
                                .write_pixels(|pixels, _| pixels.fill(0x5f))
                                .expect("failed to write replacement pixels");
                            frame
                                .present()
                                .expect("failed to present replacement pixels");
                            true
                        } else {
                            false
                        }
                    }
                };
                if replacement_presented {
                    pending.frames = pending.frames.saturating_add(1);
                }
            }
            if demo
                .pending_replacement
                .as_ref()
                .is_some_and(|pending| pending.frames >= 4)
            {
                let pending = demo
                    .pending_replacement
                    .take()
                    .expect("checked pending replacement");
                let texture_id = pending.texture.texture_id();
                drop(std::mem::replace(&mut demo.texture, pending.texture));
                demo.lifecycle_remaining -= 1;
                demo.lifecycle_completed = pending.generation;
                demo.lifecycle_not_before = Instant::now() + Duration::from_millis(100);
                if let Some(path) = &demo.lifecycle_status_path {
                    std::fs::write(path, format!("{} {texture_id}\n", pending.generation))
                        .expect("failed to update texture replacement status");
                }
            }
            if !demo.context_recreate_requested
                && demo.context_recreate_at > 0
                && demo.lifecycle_completed >= demo.context_recreate_at
                && demo.pending_replacement.is_none()
                && let Some(shell) = self.windows.borrow().shell
            {
                demo.context_recreate_requested = true;
                let completed = Arc::into_raw(Arc::clone(&demo.context_recreated));
                test_recreate_cpp_texture_context(
                    shell,
                    texture_context_recreated,
                    completed.cast_mut().cast(),
                );
            }
            if demo.dart_ready
                && demo.pending_replacement.is_none()
                && demo.lifecycle_remaining > 0
                && Instant::now() >= demo.lifecycle_not_before
                && (!demo.context_recreate_requested
                    || demo.context_recreated.load(Ordering::Acquire))
            {
                let generation = demo.lifecycle_completed + 1;
                let width = 96 + (generation as u32 * 37) % 321;
                let height = 96 + (generation as u32 * 53) % 257;
                demo.pixel_buffer = !demo.pixel_buffer;
                let next = create_demo_texture(&demo.gpu, demo.pixel_buffer, width, height)
                    .expect("failed to recreate lifecycle-stress texture");
                let texture_id = next.texture_id();
                let kind = if demo.pixel_buffer { "pixels" } else { "wgpu" };
                log::info!(
                    "Flutter Rust texture lifecycle generation {generation}: ID {texture_id}, {width}x{height}, {kind}"
                );
                if let Some(shell) = self.windows.borrow().shell {
                    send_cpp_platform_message(
                        shell,
                        TEXTURE_FIXTURE_CHANNEL,
                        format!("{texture_id} {width} {height} {kind} {generation}").as_bytes(),
                    );
                }
                demo.pending_replacement = Some(PendingTextureReplacement {
                    texture: next,
                    acknowledged: false,
                    frames: 0,
                    generation,
                });
            }
            demo.phase += 1;
            demo.next_frame = Instant::now() + Duration::from_millis(16);
        }
        let task_deadline = self.task_runner_host.next_deadline();
        let next_deadline = match (task_deadline, self.demo_texture.as_ref()) {
            (Some(task), Some(demo)) => Some(task.min(demo.next_frame)),
            (Some(task), None) => Some(task),
            (None, Some(demo)) => Some(demo.next_frame),
            (None, None) => None,
        };
        match next_deadline {
            Some(deadline) => event_loop.set_control_flow(ControlFlow::WaitUntil(deadline)),
            None => event_loop.set_control_flow(ControlFlow::Wait),
        }
    }
}

impl WindowRegistry {
    fn view(&self, view_id: FlutterRustViewId) -> Option<&ViewWindow> {
        self.view_windows
            .get(&view_id)
            .and_then(|window_id| self.views.get(window_id))
    }
    fn create_regular_view(
        &mut self,
        event_loop: &dyn ActiveEventLoop,
        request: NativeWindowRequest,
        kind: NativeWindowKind,
        parent_view_id: Option<FlutterRustViewId>,
    ) -> Result<CreatedRegularView, String> {
        let shrink_wrap = request.shrink_wrap;
        let layout_constraints =
            request
                .constraints
                .unwrap_or((0.0, 0.0, f64::INFINITY, f64::INFINITY));
        let shell = self
            .shell
            .ok_or_else(|| "Flutter shell is not running".to_owned())?;
        let implicit_window_id = self
            .view_windows
            .get(&FlutterRustViewId::IMPLICIT)
            .copied()
            .ok_or_else(|| "implicit Flutter view is missing".to_owned())?;
        let context = self
            .views
            .get(&implicit_window_id)
            .ok_or_else(|| "implicit native window is missing".to_owned())?
            .gpu_broker
            .shared_context();
        let parent_window = match parent_view_id {
            Some(parent_view_id) => {
                if self.removing_views.contains(&parent_view_id) {
                    return Err("dialog parent is being destroyed".to_owned());
                }
                let parent = self
                    .view(parent_view_id)
                    .ok_or_else(|| "window parent does not belong to this engine".to_owned())?;
                if kind == NativeWindowKind::Satellite
                    && !matches!(
                        parent.kind,
                        NativeWindowKind::Regular | NativeWindowKind::Dialog
                    )
                {
                    return Err("satellite parent must be a regular or dialog window".to_owned());
                }
                Some(Arc::clone(&parent.window))
            }
            None => None,
        };
        let mut attributes = WindowAttributes::default()
            .with_title(request.title)
            .with_surface_size(LogicalSize::new(request.width, request.height))
            .with_resizable(request.resizable);
        attributes = CurrentPlatform::prepare_window_attributes(attributes, kind);
        if let Some((min_width, min_height, max_width, max_height)) = request.constraints {
            attributes = attributes
                .with_min_surface_size(LogicalSize::new(min_width, min_height))
                .with_max_surface_size(LogicalSize::new(
                    finite_maximum(max_width),
                    finite_maximum(max_height),
                ));
        }
        let window: Arc<dyn Window> = Arc::from(
            event_loop
                .create_window(attributes)
                .map_err(|error| error.to_string())?,
        );
        if let Some(parent_window) = parent_window.as_ref() {
            CurrentPlatform::set_dialog_parent(window.as_ref(), parent_window.as_ref())?;
        }
        let gpu_broker = Box::new(GpuBroker::from_context(context, Arc::clone(&window), None)?);
        let size = window.surface_size();
        gpu_broker.configure(size.width, size.height)?;
        let view_id = FlutterRustViewId(self.next_view_id);
        self.next_view_id = self
            .next_view_id
            .checked_add(1)
            .ok_or_else(|| "Flutter view ID space exhausted".to_owned())?;
        let window_id = window.id();
        let metrics = WindowMetrics::from_window(window.as_ref(), window.scale_factor());
        let metrics = if shrink_wrap {
            metrics.with_constraints(
                layout_constraints.0,
                layout_constraints.1,
                layout_constraints.2,
                layout_constraints.3,
            )
        } else {
            metrics
        };
        let callbacks = gpu_broker.presentation_callbacks();
        self.views.insert(
            window_id,
            ViewWindow {
                view_id,
                kind,
                parent_view_id,
                gpu_broker,
                window,
                _parent_window: parent_window,
                pointer_state: PointerState::for_view(view_id),
                keyboard_state: KeyboardState::new(),
                visible: size.width > 0 && size.height > 0,
                focused: false,
            },
        );
        self.view_windows.insert(view_id, window_id);
        Ok(CreatedRegularView {
            shell,
            view_id,
            metrics,
            presentation_callbacks: callbacks,
            event_proxy: self.event_proxy.clone(),
        })
    }
    fn create_popup_view(
        &mut self,
        event_loop: &dyn ActiveEventLoop,
        request: NativePopupRequest,
    ) -> Result<CreatedRegularView, String> {
        let shell = self
            .shell
            .ok_or_else(|| "Flutter shell is not running".to_owned())?;
        if self.removing_views.contains(&request.parent_view_id) {
            return Err("popup parent is being destroyed".to_owned());
        }
        let parent_window = Arc::clone(
            &self
                .view(request.parent_view_id)
                .ok_or_else(|| "popup parent does not belong to this engine".to_owned())?
                .window,
        );
        let implicit_window_id = self
            .view_windows
            .get(&FlutterRustViewId::IMPLICIT)
            .copied()
            .ok_or_else(|| "implicit Flutter view is missing".to_owned())?;
        let context = self
            .views
            .get(&implicit_window_id)
            .ok_or_else(|| "implicit native window is missing".to_owned())?
            .gpu_broker
            .shared_context();
        let (min_width, min_height, max_width, max_height) = request.constraints;
        let initial_width = min_width.max(1.0).min(finite_maximum(max_width)).round() as u32;
        let initial_height = min_height.max(1.0).min(finite_maximum(max_height)).round() as u32;
        let window: Arc<dyn Window> = Arc::from(CurrentPlatform::create_popup(
            event_loop,
            parent_window.as_ref(),
            PopupPlacement {
                width: initial_width,
                height: initial_height,
                anchor_rect: request.anchor_rect,
                anchor: request.parent_anchor,
                gravity: request.gravity,
                offset: request.offset,
                constraint_adjustment: request.constraint_adjustment,
            },
            matches!(request.kind, NativeWindowKind::Popup),
        )?);
        let gpu_broker = Box::new(GpuBroker::from_context(context, Arc::clone(&window), None)?);
        let size = window.surface_size();
        gpu_broker.configure(size.width, size.height)?;
        let view_id = FlutterRustViewId(self.next_view_id);
        self.next_view_id = self
            .next_view_id
            .checked_add(1)
            .ok_or_else(|| "Flutter view ID space exhausted".to_owned())?;
        let window_id = window.id();
        let metrics = WindowMetrics::from_window(window.as_ref(), window.scale_factor())
            .with_constraints(min_width, min_height, max_width, max_height);
        let callbacks = gpu_broker.presentation_callbacks();
        self.views.insert(
            window_id,
            ViewWindow {
                view_id,
                kind: request.kind,
                parent_view_id: Some(request.parent_view_id),
                gpu_broker,
                window,
                _parent_window: Some(parent_window),
                pointer_state: PointerState::for_view(view_id),
                keyboard_state: KeyboardState::new(),
                visible: size.width > 0 && size.height > 0,
                focused: false,
            },
        );
        self.view_windows.insert(view_id, window_id);
        Ok(CreatedRegularView {
            shell,
            view_id,
            metrics,
            presentation_callbacks: callbacks,
            event_proxy: self.event_proxy.clone(),
        })
    }
    fn create_satellite_view(
        &mut self,
        event_loop: &dyn ActiveEventLoop,
        request: NativeSatelliteRequest,
    ) -> Result<CreatedRegularView, String> {
        let NativeSatelliteRequest {
            window,
            parent_view_id,
            anchor_rect,
            parent_anchor,
            gravity,
            offset,
            _constraint_adjustment: _,
        } = request;
        let created = self.create_regular_view(
            event_loop,
            window,
            NativeWindowKind::Satellite,
            Some(parent_view_id),
        )?;
        self.position_satellite(
            created.view_id,
            parent_view_id,
            anchor_rect,
            parent_anchor,
            gravity,
            offset,
        );
        Ok(created)
    }
    fn position_satellite(
        &self,
        view_id: FlutterRustViewId,
        parent_view_id: FlutterRustViewId,
        anchor_rect: Option<(f64, f64, f64, f64)>,
        parent_anchor: PopupAnchor,
        gravity: PopupAnchor,
        offset: (f64, f64),
    ) {
        let Some(child) = self.view(view_id).map(|view| Arc::clone(&view.window)) else {
            return;
        };
        let Some(parent) = self
            .view(parent_view_id)
            .map(|view| Arc::clone(&view.window))
        else {
            return;
        };
        // Standard Wayland deliberately does not expose absolute toplevel
        // placement. X11 and other backends that do expose it honor the
        // initial WindowPositioner here.
        let Ok(parent_position) = parent.outer_position() else {
            return;
        };
        let scale = parent.scale_factor();
        let parent_position = parent_position.to_logical::<f64>(scale);
        let parent_size = parent.outer_size().to_logical::<f64>(scale);
        let (x, y, width, height) =
            anchor_rect.unwrap_or((0.0, 0.0, parent_size.width, parent_size.height));
        let (anchor_x, anchor_y) = anchor_point(x, y, width, height, parent_anchor);
        let child_size = child.outer_size().to_logical::<f64>(child.scale_factor());
        let (child_x, child_y) = child_origin_offset(child_size, gravity);
        child.set_outer_position(winit::dpi::Position::Logical(
            winit::dpi::LogicalPosition::new(
                parent_position.x + anchor_x + child_x + offset.0,
                parent_position.y + anchor_y + child_y + offset.1,
            ),
        ));
    }
    fn reparent_satellite(
        &mut self,
        view_id: FlutterRustViewId,
        parent_view_id: FlutterRustViewId,
    ) -> Result<(), String> {
        if view_id == parent_view_id || parent_view_id < FlutterRustViewId::IMPLICIT {
            return Err("invalid satellite parent".to_owned());
        }
        let child = self
            .view(view_id)
            .ok_or_else(|| "satellite does not belong to this engine".to_owned())?;
        if child.kind != NativeWindowKind::Satellite {
            return Err("only satellite windows can be reparented".to_owned());
        }
        let mut ancestor = Some(parent_view_id);
        while let Some(candidate) = ancestor {
            if candidate == view_id {
                return Err("satellite reparenting would create a cycle".to_owned());
            }
            ancestor = self.view(candidate).and_then(|view| view.parent_view_id);
        }
        let parent_window = {
            let parent = self
                .view(parent_view_id)
                .ok_or_else(|| "satellite parent does not belong to this engine".to_owned())?;
            if !matches!(
                parent.kind,
                NativeWindowKind::Regular | NativeWindowKind::Dialog
            ) {
                return Err("satellite parent must be a regular or dialog window".to_owned());
            }
            Arc::clone(&parent.window)
        };
        let window_id = *self
            .view_windows
            .get(&view_id)
            .ok_or_else(|| "satellite view index is missing".to_owned())?;
        let child = self
            .views
            .get_mut(&window_id)
            .ok_or_else(|| "satellite native window is missing".to_owned())?;
        CurrentPlatform::set_dialog_parent(child.window.as_ref(), parent_window.as_ref())?;
        child.parent_view_id = Some(parent_view_id);
        child._parent_window = Some(parent_window);
        self.update_satellite_visibility(parent_view_id);
        Ok(())
    }
    fn update_satellite_visibility(&self, parent_view_id: FlutterRustViewId) {
        let Some(parent) = self.view(parent_view_id) else {
            return;
        };
        let hidden = parent.window.is_maximized() || parent.window.fullscreen().is_some();
        let children = self
            .views
            .values()
            .filter(|view| {
                view.kind == NativeWindowKind::Satellite
                    && view.parent_view_id == Some(parent_view_id)
            })
            .map(|view| Arc::clone(&view.window))
            .collect::<Vec<_>>();
        for window in children {
            window.set_visible(!hidden);
        }
    }

    fn take_view_state(&mut self, view_id: FlutterRustViewId) -> Option<RemovedViewState> {
        let window_id = self.view_windows.remove(&view_id)?;
        if self.focused_window == Some(window_id) {
            self.focused_window = None;
        }
        let view = self
            .views
            .remove(&window_id)
            .expect("view/window index became inconsistent");
        self.removing_views.remove(&view_id);
        Some(RemovedViewState {
            _view: view,
            callback: self.window_event_callback,
        })
    }
    fn begin_remove_views(
        &mut self,
        view_id: FlutterRustViewId,
    ) -> Vec<(FlutterRustViewId, *mut c_void, HostEventSender)> {
        if view_id <= FlutterRustViewId::IMPLICIT || !self.view_windows.contains_key(&view_id) {
            return Vec::new();
        }
        let Some(shell) = self.shell else {
            return Vec::new();
        };
        let mut pending = vec![view_id];
        let mut ordered = Vec::new();
        while let Some(parent) = pending.pop() {
            for child in self
                .views
                .values()
                .filter(|view| view.parent_view_id == Some(parent))
                .map(|view| view.view_id)
                .collect::<Vec<_>>()
            {
                pending.push(child);
            }
            ordered.push(parent);
        }
        ordered
            .into_iter()
            .rev()
            .filter(|view_id| self.removing_views.insert(*view_id))
            .map(|view_id| (view_id, shell, self.event_proxy.clone()))
            .collect()
    }

    fn aggregate_window_state(&self) -> (bool, bool) {
        (
            self.views.values().any(|view| view.visible),
            self.views.values().any(|view| view.focused),
        )
    }
}

fn valid_window_size(width: f64, height: f64) -> bool {
    width.is_finite() && height.is_finite() && width > 0.0 && height > 0.0
}

fn valid_constraints(min_width: f64, min_height: f64, max_width: f64, max_height: f64) -> bool {
    min_width.is_finite()
        && min_height.is_finite()
        && min_width >= 0.0
        && min_height >= 0.0
        && !max_width.is_nan()
        && !max_height.is_nan()
        && min_width <= max_width
        && min_height <= max_height
}
fn finite_maximum(value: f64) -> f64 {
    if value.is_infinite() {
        f64::from(i32::MAX)
    } else {
        value
    }
}
fn anchor_point(x: f64, y: f64, width: f64, height: f64, anchor: PopupAnchor) -> (f64, f64) {
    match anchor {
        PopupAnchor::None => (x + width / 2.0, y + height / 2.0),
        PopupAnchor::Top => (x + width / 2.0, y),
        PopupAnchor::Bottom => (x + width / 2.0, y + height),
        PopupAnchor::Left => (x, y + height / 2.0),
        PopupAnchor::Right => (x + width, y + height / 2.0),
        PopupAnchor::TopLeft => (x, y),
        PopupAnchor::BottomLeft => (x, y + height),
        PopupAnchor::TopRight => (x + width, y),
        PopupAnchor::BottomRight => (x + width, y + height),
    }
}
fn child_origin_offset(size: winit::dpi::LogicalSize<f64>, gravity: PopupAnchor) -> (f64, f64) {
    match gravity {
        PopupAnchor::None => (-size.width / 2.0, -size.height / 2.0),
        PopupAnchor::Top => (-size.width / 2.0, -size.height),
        PopupAnchor::Bottom => (-size.width / 2.0, 0.0),
        PopupAnchor::Left => (-size.width, -size.height / 2.0),
        PopupAnchor::Right => (0.0, -size.height / 2.0),
        PopupAnchor::TopLeft => (-size.width, -size.height),
        PopupAnchor::BottomLeft => (-size.width, 0.0),
        PopupAnchor::TopRight => (0.0, -size.height),
        PopupAnchor::BottomRight => (0.0, 0.0),
    }
}

impl ShellApplication {
    fn send_pointer_events(&self, events: impl IntoIterator<Item = FlutterRustPointerEvent>) {
        if let Some(shell) = { self.windows.borrow().shell } {
            for event in events {
                send_cpp_pointer_event(shell, event);
            }
        }
    }

    fn send_lifecycle_event(&self, state: Option<FlutterRustLifecycleState>) {
        if let (Some(shell), Some(state)) = ({ self.windows.borrow().shell }, state) {
            send_cpp_lifecycle_event(shell, state);
        }
    }

    fn send_key_event(&self, event: FlutterRustKeyEvent) {
        if let Some(shell) = { self.windows.borrow().shell } {
            send_cpp_key_event(shell, event);
        }
    }

    fn send_raw_key_event(&self, message: &[u8]) {
        if let Some(shell) = { self.windows.borrow().shell } {
            send_cpp_platform_message(shell, KEY_EVENT_CHANNEL, message);
        }
    }

    fn apply_text_input_commands(&mut self) {
        for command in self.text_input_inbox.drain() {
            let effect = self.text_input_session.apply(command);
            let window = {
                let windows = self.windows.borrow();
                let window_id = windows.focused_window.or_else(|| {
                    windows
                        .view_windows
                        .get(&FlutterRustViewId::IMPLICIT)
                        .copied()
                });
                window_id
                    .and_then(|window_id| windows.views.get(&window_id))
                    .map(|view| Arc::clone(&view.window))
            };
            let Some(window) = window else {
                continue;
            };
            match effect {
                Some(TextInputEffect::SetImeAllowed(allowed)) => {
                    let request = if allowed {
                        let position = LogicalPosition::new(0, 0);
                        let size = LogicalSize::new(0, 0);
                        let ime_caps = ImeCapabilities::new()
                            .with_hint_and_purpose()
                            .with_cursor_area();
                        let request_data = ImeRequestData::default()
                            .with_hint_and_purpose(ImeHint::NONE, ImePurpose::Normal)
                            .with_cursor_area(position.into(), size.into());
                        ImeRequest::Enable(ImeEnableRequest::new(ime_caps, request_data).unwrap())
                    } else {
                        ImeRequest::Disable
                    };
                    let _ = window.request_ime_update(request);
                }
                Some(TextInputEffect::SetCursorRect(rect)) => {
                    if window
                        .ime_capabilities()
                        .is_some_and(|caps| caps.cursor_area())
                    {
                        let _ = window.request_ime_update(ImeRequest::Update(
                            ImeRequestData::default().with_cursor_area(
                                LogicalPosition::new(rect.x, rect.y).into(),
                                LogicalSize::new(rect.width, rect.height).into(),
                            ),
                        ));
                    }
                }
                None => {}
            }
        }
    }

    fn send_text_input_update(&self, message: &[u8]) {
        if let Some(shell) = { self.windows.borrow().shell } {
            send_cpp_platform_message(shell, TEXT_INPUT_CHANNEL, message);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug, PartialEq, Eq)]
    struct RecordedWindowCreation {
        kind: NativeWindowKind,
        parent: Option<FlutterRustViewId>,
        title: String,
    }

    #[derive(Debug, PartialEq, Eq)]
    struct RecordedPopupCreation {
        kind: NativeWindowKind,
        parent: FlutterRustViewId,
        constraint_adjustment: u32,
    }

    #[derive(Debug, PartialEq, Eq)]
    struct RecordedSatelliteCreation {
        parent: FlutterRustViewId,
        has_anchor_rect: bool,
        constraint_adjustment: u32,
    }

    #[derive(Default)]
    struct FakeWindowingHost {
        windows: RefCell<Vec<RecordedWindowCreation>>,
        popups: RefCell<Vec<RecordedPopupCreation>>,
        satellites: RefCell<Vec<RecordedSatelliteCreation>>,
        destroyed: RefCell<Vec<FlutterRustViewId>>,
    }

    impl WindowingCallbackHost for FakeWindowingHost {
        fn create_window(
            &self,
            request: NativeWindowRequest,
            kind: NativeWindowKind,
            parent: Option<FlutterRustViewId>,
        ) -> FlutterRustViewId {
            self.windows.borrow_mut().push(RecordedWindowCreation {
                kind,
                parent,
                title: request.title,
            });
            FlutterRustViewId(41)
        }

        fn create_popup(&self, request: NativePopupRequest) -> FlutterRustViewId {
            self.popups.borrow_mut().push(RecordedPopupCreation {
                kind: request.kind,
                parent: request.parent_view_id,
                constraint_adjustment: request.constraint_adjustment,
            });
            FlutterRustViewId(42)
        }

        fn create_satellite(&self, request: NativeSatelliteRequest) -> FlutterRustViewId {
            self.satellites
                .borrow_mut()
                .push(RecordedSatelliteCreation {
                    parent: request.parent_view_id,
                    has_anchor_rect: request.anchor_rect.is_some(),
                    constraint_adjustment: request._constraint_adjustment,
                });
            FlutterRustViewId(43)
        }

        fn destroy_window(&self, view_id: FlutterRustViewId) {
            self.destroyed.borrow_mut().push(view_id);
        }
    }

    fn regular_request(title: &[u8]) -> FlutterRustRegularWindowRequest {
        FlutterRustRegularWindowRequest {
            has_size: 1,
            width: 320.0,
            height: 240.0,
            title: title.as_ptr(),
            title_length: title.len() as u64,
            resizable: 1,
            has_constraints: 0,
            min_width: 0.0,
            min_height: 0.0,
            max_width: f64::INFINITY,
            max_height: f64::INFINITY,
        }
    }

    #[test]
    fn window_callbacks_decode_through_an_injected_host() {
        let host = FakeWindowingHost::default();
        let regular = regular_request(b"typed regular");
        assert_eq!(
            dispatch_create_regular(&host, &regular),
            FlutterRustViewId(41)
        );

        let dialog = FlutterRustDialogWindowRequest {
            window: regular_request(b"typed dialog"),
            has_parent: 1,
            parent_view_id: FlutterRustViewId(9),
        };
        assert_eq!(
            dispatch_create_dialog(&host, &dialog),
            FlutterRustViewId(41)
        );

        let windows = host.windows.borrow();
        assert_eq!(
            windows[0],
            RecordedWindowCreation {
                kind: NativeWindowKind::Regular,
                parent: None,
                title: "typed regular".to_owned(),
            }
        );
        assert_eq!(
            windows[1],
            RecordedWindowCreation {
                kind: NativeWindowKind::Dialog,
                parent: Some(FlutterRustViewId(9)),
                title: "typed dialog".to_owned(),
            }
        );
    }

    #[test]
    fn popup_and_destroy_callbacks_validate_before_dispatch() {
        let host = FakeWindowingHost::default();
        let mut popup = FlutterRustPopupWindowRequest {
            kind: 1,
            parent_view_id: FlutterRustViewId(9),
            min_width: 0.0,
            min_height: 0.0,
            max_width: f64::INFINITY,
            max_height: f64::INFINITY,
            anchor_x: 10.0,
            anchor_y: 20.0,
            anchor_width: 30.0,
            anchor_height: 40.0,
            parent_anchor: 6,
            child_anchor: 5,
            offset_x: 2.0,
            offset_y: 3.0,
            constraint_adjustment: 0x3f,
        };
        assert_eq!(dispatch_create_popup(&host, &popup), FlutterRustViewId(42));
        assert_eq!(
            host.popups.borrow()[0],
            RecordedPopupCreation {
                kind: NativeWindowKind::Popup,
                parent: FlutterRustViewId(9),
                constraint_adjustment: 0x3f,
            }
        );

        popup.kind = 99;
        assert_eq!(dispatch_create_popup(&host, &popup), FlutterRustViewId(-1));
        assert_eq!(host.popups.borrow().len(), 1);
        assert_eq!(
            dispatch_create_regular(&host, std::ptr::null()),
            FlutterRustViewId(-1)
        );

        dispatch_destroy(&host, FlutterRustViewId::IMPLICIT);
        dispatch_destroy(&host, FlutterRustViewId(42));
        assert_eq!(&*host.destroyed.borrow(), &[FlutterRustViewId(42)]);
    }

    #[test]
    fn satellite_callback_decodes_through_an_injected_host() {
        let host = FakeWindowingHost::default();
        let mut satellite = FlutterRustSatelliteWindowRequest {
            window: regular_request(b"typed satellite"),
            parent_view_id: FlutterRustViewId(9),
            has_anchor_rect: 1,
            anchor_x: 10.0,
            anchor_y: 20.0,
            anchor_width: 30.0,
            anchor_height: 40.0,
            parent_anchor: 6,
            child_anchor: 5,
            offset_x: 2.0,
            offset_y: 3.0,
            constraint_adjustment: 0x3f,
        };

        assert_eq!(
            dispatch_create_satellite(&host, &satellite),
            FlutterRustViewId(43)
        );
        assert_eq!(
            host.satellites.borrow()[0],
            RecordedSatelliteCreation {
                parent: FlutterRustViewId(9),
                has_anchor_rect: true,
                constraint_adjustment: 0x3f,
            }
        );

        satellite.parent_view_id = FlutterRustViewId::IMPLICIT;
        assert_eq!(
            dispatch_create_satellite(&host, &satellite),
            FlutterRustViewId(-1)
        );
        assert_eq!(host.satellites.borrow().len(), 1);
    }

    #[test]
    fn has_a_stable_default_window_title() {
        assert_eq!(ShellConfig::default().title, "Flutter Rust Shell");
        assert_eq!(TEXT_INPUT_CHANNEL, b"flutter/textinput");
        assert_eq!(KEY_EVENT_CHANNEL, b"flutter/keyevent");
    }

    #[test]
    fn application_registration_runs_once_and_propagates_failure() {
        let dispatcher =
            MainThreadDispatcher::for_shell_inactive(|_| true, std::thread::current().id());
        let mut registrar = PluginRegistrar::for_shell(dispatcher);
        let calls = Rc::new(std::cell::Cell::new(0));
        let registration_calls = Rc::clone(&calls);
        let mut registration: Option<ApplicationRegistration> = Some(Box::new(move |registrar| {
            registration_calls.set(registration_calls.get() + 1);
            assert!(registrar.main_thread_dispatcher().is_main_thread());
            Err(PluginError::Unsupported)
        }));

        assert_eq!(
            register_application_once(&mut registration, &mut registrar),
            Err(PluginError::Unsupported)
        );
        assert_eq!(calls.get(), 1);
        assert!(registration.is_none());
    }

    #[test]
    fn main_thread_callbacks_are_bounded_per_event_loop_turn() {
        let queue = Mutex::new(VecDeque::new());
        for _ in 0..(MAX_HOST_EVENTS_PER_TURN + 1) {
            queue
                .lock()
                .push_back(HostEvent::MainThreadTask(Box::new(|| {})));
        }

        let (first, has_more) = drain_host_event_batch(&queue);
        assert_eq!(first.len(), MAX_HOST_EVENTS_PER_TURN);
        assert!(has_more);
        for event in first {
            let HostEvent::MainThreadTask(task) = event else {
                panic!("unexpected host event");
            };
            task();
        }

        let (second, has_more) = drain_host_event_batch(&queue);
        assert_eq!(second.len(), 1);
        assert!(!has_more);
    }

    #[test]
    fn derives_frame_intervals_from_monitor_refresh_rates() {
        assert_eq!(frame_interval_from_millihertz(Some(60_000)), 16_666_666);
        assert_eq!(frame_interval_from_millihertz(Some(120_000)), 8_333_333);
        assert_eq!(
            frame_interval_from_millihertz(None),
            DEFAULT_FRAME_INTERVAL_NANOS
        );
        assert_eq!(
            frame_interval_from_millihertz(Some(0)),
            DEFAULT_FRAME_INTERVAL_NANOS
        );
    }

    #[test]
    fn returns_only_due_task_batons() {
        let now = Instant::now();
        let mut queue = TaskQueue::default();
        let first = ScheduledTask {
            task_runner: 1,
            task_baton: 1,
        };
        let second = ScheduledTask {
            task_runner: 1,
            task_baton: 2,
        };
        queue.schedule(first, now);
        queue.schedule(second, now + Duration::from_secs(1));

        assert_eq!(queue.take_due(now), vec![first]);
        assert_eq!(queue.next_deadline(), Some(now + Duration::from_secs(1)));
    }

    #[test]
    fn installs_callbacks_backed_by_the_rust_host() {
        let host = Box::new(TaskRunnerHost::new());
        let callbacks = host.callbacks();
        let schedule = callbacks.schedule_task.expect("schedule callback");
        let is_current = callbacks
            .runs_tasks_on_current_thread
            .expect("thread callback");
        let destroyed = callbacks
            .task_runner_destroyed
            .expect("destruction callback");

        assert_eq!(is_current(callbacks.user_data), 1);
        schedule(callbacks.user_data, 0x10usize as *mut c_void, 7, 0);
        assert_eq!(
            host.take_due(Instant::now()),
            vec![ScheduledTask {
                task_runner: 0x10,
                task_baton: 7,
            }]
        );
        destroyed(callbacks.user_data);
        assert!(host.is_destroyed());
    }

    #[test]
    fn decodes_typed_text_input_commands() {
        assert_eq!(
                TextInputCommand::decode(
                    br#"{"method":"TextInput.setClient","args":[42,{"inputAction":"TextInputAction.done"}]}"#,
                ),
                Some(TextInputCommand::SetClient(TextInputClientId(42)))
            );
        assert_eq!(
                TextInputCommand::decode(
                    r#"{"method":"TextInput.setEditingState","args":{"text":"A🙂B","selectionBase":3,"selectionExtent":3,"selectionAffinity":"TextAffinity.downstream","selectionIsDirectional":false,"composingBase":-1,"composingExtent":-1}}"#.as_bytes(),
                ),
                Some(TextInputCommand::SetEditingState(TextEditingState {
                    text: "A🙂B".to_owned(),
                    selection_base: 3,
                    selection_extent: 3,
                    selection_affinity: TextAffinity::Downstream,
                    selection_is_directional: false,
                    composing_base: -1,
                    composing_extent: -1,
                }))
            );
        assert_eq!(
                TextInputCommand::decode(
                    br#"{"method":"TextInput.setCaretRect","args":{"x":10.0,"y":20.0,"width":1.0,"height":18.0}}"#,
                ),
                Some(TextInputCommand::SetCursorRect(TextInputRect {
                    x: 10.0,
                    y: 20.0,
                    width: 1.0,
                    height: 18.0,
                }))
            );
    }

    #[test]
    fn decodes_application_exit_requests_and_responses() {
        assert_eq!(
            ApplicationExitRequest::decode(
                br#"{"method":"System.exitApplication","args":{"type":"required","exitCode":7}}"#,
            ),
            Some(ApplicationExitRequest::Required)
        );
        assert_eq!(
            ApplicationExitRequest::decode(
                br#"{"method":"System.exitApplication","args":{"type":"cancelable","exitCode":0}}"#,
            ),
            Some(ApplicationExitRequest::Cancelable)
        );
        assert_eq!(
            ApplicationExitRequest::decode(br#"{"method":"SystemNavigator.pop","args":null}"#,),
            Some(ApplicationExitRequest::Required)
        );
        assert!(
            ApplicationExitRequest::decode(
                br#"{"method":"System.exitApplication","args":{"type":"unknown"}}"#,
            )
            .is_none()
        );
        assert!(is_initialization_complete(
            br#"{"method":"System.initializationComplete","args":null}"#
        ));
        assert_eq!(
            ApplicationExitResponse::decode(br#"[{"response":"cancel"}]"#),
            Some(ApplicationExitResponse::Cancel)
        );
        assert_eq!(
            ApplicationExitResponse::decode(br#"[{"response":"exit"}]"#),
            Some(ApplicationExitResponse::Exit)
        );
        assert_eq!(
            ApplicationExitResponse::Cancel.envelope(),
            br#"[{"response":"cancel"}]"#
        );
        assert!(ApplicationExitResponse::decode(br#"[{"response":"invalid"}]"#).is_none());
    }

    #[test]
    fn rejects_malformed_text_input_commands_and_utf16_ranges() {
        assert!(TextInputCommand::decode(b"not json").is_none());
        assert!(
            TextInputCommand::decode(br#"{"method":"TextInput.unknown","args":null}"#,).is_none()
        );
        // UTF-16 offset 1 splits the emoji's surrogate pair.
        assert!(
                TextInputCommand::decode(
                    r#"{"method":"TextInput.setEditingState","args":{"text":"🙂","selectionBase":1,"selectionExtent":1,"composingBase":-1,"composingExtent":-1}}"#.as_bytes(),
                )
                .is_none()
            );
    }

    #[test]
    fn ime_replaces_utf16_selection_and_serializes_framework_update() {
        let mut session = TextInputSession::default();
        session.apply(TextInputCommand::SetClient(TextInputClientId(7)));
        session.apply(TextInputCommand::SetEditingState(TextEditingState {
            text: "A🙂B".to_owned(),
            selection_base: 1,
            selection_extent: 3,
            selection_affinity: TextAffinity::Downstream,
            selection_is_directional: false,
            composing_base: -1,
            composing_extent: -1,
        }));

        let preedit = session
            .ime(Ime::Preedit("é".to_owned(), Some((2, 2))))
            .expect("active client should receive preedit");
        assert_eq!(session.editing_state.text, "AéB");
        assert_eq!(session.editing_state.selection_base, 2);
        assert_eq!(session.editing_state.composing_base, 1);
        assert_eq!(session.editing_state.composing_extent, 2);
        let update: Value = serde_json::from_slice(&preedit).expect("valid update JSON");
        assert_eq!(update["method"], "TextInputClient.updateEditingState");
        assert_eq!(update["args"][0], 7);
        assert_eq!(update["args"][1]["text"], "AéB");

        session
            .ime(Ime::Commit("中".to_owned()))
            .expect("commit should update the framework");
        assert_eq!(session.editing_state.text, "A中B");
        assert_eq!(session.editing_state.selection_base, 2);
        assert_eq!(session.editing_state.composing_base, -1);
    }

    #[test]
    fn preedit_with_hidden_cursor_remains_composing() {
        let mut session = TextInputSession::default();
        session.apply(TextInputCommand::SetClient(TextInputClientId(9)));
        session.apply(TextInputCommand::SetEditingState(
            TextEditingState::default(),
        ));

        assert!(session.ime(Ime::Preedit("候補".to_owned(), None)).is_some());
        assert_eq!(session.editing_state.text, "候補");
        assert_eq!(session.editing_state.composing_base, 0);
        assert_eq!(session.editing_state.composing_extent, 2);
        assert_eq!(session.editing_state.selection_base, 2);

        // A cursor byte offset must land on a UTF-8 character boundary.
        assert!(
            session
                .ime(Ime::Preedit("🙂".to_owned(), Some((1, 1))))
                .is_none()
        );
        assert_eq!(session.editing_state.text, "候補");
    }

    #[test]
    fn keyboard_text_commits_without_turning_shortcuts_into_text() {
        assert_eq!(
            committed_key_text(ModifiersState::empty(), ElementState::Pressed, Some("é")),
            Some("é")
        );
        assert_eq!(
            committed_key_text(ModifiersState::CONTROL, ElementState::Pressed, Some("a")),
            None
        );
        assert_eq!(
            committed_key_text(ModifiersState::empty(), ElementState::Pressed, Some("\r")),
            None
        );

        let mut session = TextInputSession::default();
        session.apply(TextInputCommand::SetClient(TextInputClientId(10)));
        session.apply(TextInputCommand::SetEditingState(TextEditingState {
            text: "A🙂B".to_owned(),
            selection_base: 1,
            selection_extent: 3,
            selection_affinity: TextAffinity::Downstream,
            selection_is_directional: false,
            composing_base: -1,
            composing_extent: -1,
        }));

        let update = session
            .keyboard_text("é")
            .expect("ordinary keyboard text should update the client");
        assert_eq!(session.editing_state.text, "AéB");
        assert_eq!(session.editing_state.selection_base, 2);
        let update: Value = serde_json::from_slice(&update).expect("valid update JSON");
        assert_eq!(update["args"][1]["text"], "AéB");

        session.editing_state.composing_base = 1;
        session.editing_state.composing_extent = 2;
        assert!(session.keyboard_text("x").is_none());
    }

    #[test]
    fn raw_key_message_terminates_the_modern_key_packet() {
        let mut keyboard = KeyboardState::new();
        keyboard.modifiers_changed(ModifiersState::CONTROL);
        let event = make_key_event(
            1234,
            PhysicalKey::Code(KeyCode::KeyA),
            &Key::Character("a".into()),
            Some("a"),
            ElementState::Pressed,
            false,
            false,
        )
        .expect("key A should be supported");

        let message: Value = serde_json::from_slice(&keyboard.raw_event_message(&event))
            .expect("valid raw key JSON");
        assert_eq!(message["type"], "keydown");
        assert_eq!(message["keymap"], "linux");
        assert_eq!(message["toolkit"], "gtk");
        assert_eq!(message["scanCode"], 4);
        assert_eq!(message["specifiedLogicalKey"], u64::from('a'));
        assert_eq!(message["modifiers"], 1 << 2);
        assert_eq!(message["unicodeScalarValues"], u64::from('a'));
    }

    #[test]
    fn translates_mouse_motion_and_button_state() {
        let mut pointer = PointerState::new();
        let motion = pointer.moved(12.5, 24.0);
        assert_eq!(motion.len(), 2);
        assert_eq!(motion[0].phase, FlutterRustPointerPhase::Add as u32);
        assert_eq!(motion[1].phase, FlutterRustPointerPhase::Hover as u32);
        assert_eq!((motion[1].physical_x, motion[1].physical_y), (12.5, 24.0));

        let down = pointer.button(MouseButton::Left, ElementState::Pressed);
        assert_eq!(down.len(), 1);
        assert_eq!(down[0].phase, FlutterRustPointerPhase::Down as u32);
        assert_eq!(down[0].buttons, MOUSE_PRIMARY_BUTTON);

        let second_down = pointer.button(MouseButton::Right, ElementState::Pressed);
        assert_eq!(second_down[0].phase, FlutterRustPointerPhase::Move as u32);
        assert_eq!(
            second_down[0].buttons,
            MOUSE_PRIMARY_BUTTON | MOUSE_SECONDARY_BUTTON
        );

        let second_up = pointer.button(MouseButton::Right, ElementState::Released);
        assert_eq!(second_up[0].phase, FlutterRustPointerPhase::Move as u32);
        assert_eq!(second_up[0].buttons, MOUSE_PRIMARY_BUTTON);

        let drag = pointer.moved(20.0, 30.0);
        assert_eq!(drag[0].phase, FlutterRustPointerPhase::Move as u32);
        assert_eq!(drag[0].buttons, MOUSE_PRIMARY_BUTTON);

        let up = pointer.button(MouseButton::Left, ElementState::Released);
        assert_eq!(up[0].phase, FlutterRustPointerPhase::Up as u32);
        assert_eq!(up[0].buttons, 0);
    }

    #[test]
    fn pointer_events_preserve_their_target_view() {
        let mut pointer = PointerState::for_view(FlutterRustViewId(17));

        let events = pointer.moved(10.0, 20.0);

        assert!(!events.is_empty());
        assert!(
            events
                .iter()
                .all(|event| event.view_id == FlutterRustViewId(17))
        );
    }

    #[test]
    fn removes_a_dragged_pointer_after_its_last_button_is_released() {
        let mut pointer = PointerState::new();
        pointer.moved(12.5, 24.0);
        pointer.button(MouseButton::Left, ElementState::Pressed);

        assert!(pointer.left().is_none());
        let release = pointer.button(MouseButton::Left, ElementState::Released);

        assert_eq!(release.len(), 2);
        assert_eq!(release[0].phase, FlutterRustPointerPhase::Up as u32);
        assert_eq!(release[1].phase, FlutterRustPointerPhase::Remove as u32);
    }

    #[test]
    fn translates_scroll_direction_and_line_units() {
        let mut pointer = PointerState::new();
        pointer.moved(5.0, 6.0);
        let events = pointer.scroll(MouseScrollDelta::LineDelta(1.0, 2.0));
        assert_eq!(events.len(), 1);
        assert_eq!(
            events[0].signal_kind,
            FlutterRustPointerSignalKind::Scroll as u32
        );
        assert_eq!(events[0].scroll_delta_x, SCROLL_LINE_PIXELS);
        assert_eq!(events[0].scroll_delta_y, -2.0 * SCROLL_LINE_PIXELS);
    }

    #[test]
    fn touch_devices_do_not_collide_with_the_mouse() {
        assert_eq!(touch_device_id(0), 1);
        assert_eq!(touch_device_id(7), 8);
        assert_eq!(touch_device_id(u64::MAX), i64::MAX);
    }

    #[test]
    fn translates_key_down_repeat_and_up() {
        let down = make_key_event(
            1234,
            PhysicalKey::Code(KeyCode::KeyA),
            &Key::Character("A".into()),
            Some("A"),
            ElementState::Pressed,
            false,
            false,
        )
        .expect("key A should be supported");
        assert_eq!(down.timestamp_micros, 1234);
        assert_eq!(down.event_type, FlutterRustKeyEventType::Down as u32);
        assert_eq!(down.physical, 0x00070004);
        assert_eq!(down.logical, u64::from('a'));
        assert_eq!(down.character_length, 1);
        assert_eq!(&down.character[..1], b"A");

        let repeat = make_key_event(
            1235,
            PhysicalKey::Code(KeyCode::KeyA),
            &Key::Character("a".into()),
            Some("a"),
            ElementState::Pressed,
            true,
            false,
        )
        .expect("repeated key A should be supported");
        assert_eq!(repeat.event_type, FlutterRustKeyEventType::Repeat as u32);

        let up = make_key_event(
            1236,
            PhysicalKey::Code(KeyCode::KeyA),
            &Key::Character("a".into()),
            Some("a"),
            ElementState::Released,
            false,
            false,
        )
        .expect("released key A should be supported");
        assert_eq!(up.event_type, FlutterRustKeyEventType::Up as u32);
        assert_eq!(up.character_length, 0);
    }

    #[test]
    fn preserves_modifier_side_and_synthetic_state() {
        let event = make_key_event(
            42,
            PhysicalKey::Code(KeyCode::ShiftRight),
            &Key::Named(NamedKey::Shift),
            None,
            ElementState::Released,
            false,
            true,
        )
        .expect("right shift should be supported");

        assert_eq!(event.physical, 0x000700e5);
        assert_eq!(event.logical, 0x00200000103);
        assert_eq!(event.synthesized, 1);
    }

    #[test]
    fn uses_the_gtk_plane_for_unidentified_xkb_keys() {
        let event = make_key_event(
            7,
            PhysicalKey::Unidentified(NativeKeyCode::Xkb(0x1234)),
            &Key::Unidentified(NativeKey::Xkb(0x5678)),
            None,
            ElementState::Pressed,
            false,
            false,
        )
        .expect("XKB keys should have a stable fallback");

        assert_eq!(event.physical, CurrentPlatform::FALLBACK_KEY_PLANE | 0x1234);
        assert_eq!(event.logical, CurrentPlatform::FALLBACK_KEY_PLANE | 0x5678);
    }

    #[test]
    fn lifecycle_tracks_focus_visibility_suspend_and_detach() {
        let mut lifecycle = LifecycleState::new();
        assert_eq!(
            lifecycle.resumed(true, false),
            Some(FlutterRustLifecycleState::Inactive)
        );
        assert_eq!(
            lifecycle.focus_changed(true),
            Some(FlutterRustLifecycleState::Resumed)
        );
        assert_eq!(lifecycle.focus_changed(true), None);
        assert_eq!(
            lifecycle.visibility_changed(false),
            Some(FlutterRustLifecycleState::Hidden)
        );
        assert_eq!(
            lifecycle.suspended(),
            Some(FlutterRustLifecycleState::Paused)
        );
        assert_eq!(
            lifecycle.detached(),
            Some(FlutterRustLifecycleState::Detached)
        );
    }
}
