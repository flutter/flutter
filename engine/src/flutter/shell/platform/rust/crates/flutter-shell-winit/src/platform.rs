//! Native window-system operations that are not expressed by winit's shared API.

use winit::{
    event_loop::ActiveEventLoop,
    window::{Window, WindowAttributes},
};

use crate::{NativeWindowKind, PopupPlacement};

#[cfg(target_os = "linux")]
mod linux;

#[cfg(target_os = "linux")]
pub(crate) use linux::LinuxPlatform as CurrentPlatform;

#[cfg(target_os = "android")]
mod android;

#[cfg(target_os = "android")]
pub(crate) use android::AndroidPlatform as CurrentPlatform;

#[cfg(not(any(target_os = "linux", target_os = "android")))]
compile_error!(
    "flutter-shell-winit needs a platform adapter for this target; the shared host is platform-neutral"
);

/// Statically selected native operations not covered by winit's shared API.
pub(crate) trait PlatformBackend {
    const LEGACY_KEYMAP: &'static str;
    const LEGACY_TOOLKIT: &'static str;
    const FALLBACK_KEY_PLANE: u64;

    fn prepare_window_attributes(
        attributes: WindowAttributes,
        kind: NativeWindowKind,
    ) -> WindowAttributes;

    fn is_wayland(event_loop: &dyn ActiveEventLoop) -> bool;

    fn create_popup(
        event_loop: &dyn ActiveEventLoop,
        parent: &dyn Window,
        placement: PopupPlacement,
        grab: bool,
    ) -> Result<Box<dyn Window>, String>;

    fn set_dialog_parent(child: &dyn Window, parent: &dyn Window) -> Result<(), String>;
}
