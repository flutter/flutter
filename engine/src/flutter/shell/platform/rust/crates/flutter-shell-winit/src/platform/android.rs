//! Android implementation of the narrow native-window adapter.
//!
//! Android has no native multi-window model comparable to X11/Wayland
//! transient windows, and GameActivity owns a single fullscreen surface, so
//! popup/dialog creation is unsupported here rather than emulated.

use winit::event_loop::ActiveEventLoop;
use winit::window::{Window, WindowAttributes};

use super::super::{NativeWindowKind, PopupPlacement};
use super::PlatformBackend;

pub(crate) struct AndroidPlatform;

impl PlatformBackend for AndroidPlatform {
    // Matches the "android" keymap identifier Flutter's Java embedding sends
    // over `flutter/keyevent` (see KeyEventChannel.java). Real Android
    // keyboard support needs its own message encoding (Android's legacy
    // schema uses keyCode/scanCode/metaState/flags, not this Linux-shaped
    // struct), so LEGACY_TOOLKIT has no real counterpart yet; nothing sends
    // that message on Android today.
    const LEGACY_KEYMAP: &'static str = "android";
    const LEGACY_TOOLKIT: &'static str = "android";
    // Flutter's `LogicalKeyboardKey.androidPlane`
    // (packages/flutter/lib/src/services/keyboard_key.g.dart).
    const FALLBACK_KEY_PLANE: u64 = 0x01100000000;

    fn prepare_window_attributes(
        attributes: WindowAttributes,
        _kind: NativeWindowKind,
    ) -> WindowAttributes {
        attributes
    }

    fn is_wayland(_event_loop: &dyn ActiveEventLoop) -> bool {
        false
    }

    fn create_popup(
        _event_loop: &dyn ActiveEventLoop,
        _parent: &dyn Window,
        _placement: PopupPlacement,
        _grab: bool,
    ) -> Result<Box<dyn Window>, String> {
        Err("native popups are not supported on Android".to_owned())
    }

    fn set_dialog_parent(_child: &dyn Window, _parent: &dyn Window) -> Result<(), String> {
        Err("native dialog parenting is not supported on Android".to_owned())
    }
}
