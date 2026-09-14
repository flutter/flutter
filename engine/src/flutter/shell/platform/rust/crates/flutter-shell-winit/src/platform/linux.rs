//! Wayland/X11 implementation of the narrow native-window adapter.

use raw_window_handle::{HasDisplayHandle, HasWindowHandle, RawDisplayHandle, RawWindowHandle};
use wayland_sys::{
    client::{wayland_client_handle, wl_proxy},
    ffi_dispatch,
};
use winit::{
    dpi::LogicalSize,
    event_loop::ActiveEventLoop,
    platform::{
        wayland::{
            ActiveEventLoopExtWayland, PopupAnchor, PopupAttributesWayland, WindowExtWayland,
        },
        x11::{WindowAttributesX11, WindowType},
    },
    window::{Window, WindowAttributes},
};

use super::super::{NativeWindowKind, PopupAnchor as HostPopupAnchor, PopupPlacement};
use super::PlatformBackend;

pub(crate) struct LinuxPlatform;

impl PlatformBackend for LinuxPlatform {
    const LEGACY_KEYMAP: &'static str = "linux";
    const LEGACY_TOOLKIT: &'static str = "gtk";
    const FALLBACK_KEY_PLANE: u64 = 0x01500000000;

    fn prepare_window_attributes(
        mut attributes: WindowAttributes,
        kind: NativeWindowKind,
    ) -> WindowAttributes {
        if matches!(kind, NativeWindowKind::Dialog) {
            attributes = attributes.with_platform_attributes(Box::new(
                WindowAttributesX11::default().with_x11_window_type(vec![WindowType::Dialog]),
            ));
        } else if matches!(kind, NativeWindowKind::Satellite) {
            attributes = attributes.with_platform_attributes(Box::new(
                WindowAttributesX11::default().with_x11_window_type(vec![WindowType::Utility]),
            ));
        }
        attributes
    }

    fn is_wayland(event_loop: &dyn ActiveEventLoop) -> bool {
        event_loop.is_wayland()
    }

    fn create_popup(
        event_loop: &dyn ActiveEventLoop,
        parent: &dyn Window,
        placement: PopupPlacement,
        grab: bool,
    ) -> Result<Box<dyn Window>, String> {
        event_loop
            .create_popup_wayland(
                parent,
                PopupAttributesWayland {
                    size: LogicalSize::new(placement.width.max(1), placement.height.max(1)),
                    anchor_rect: placement.anchor_rect,
                    anchor: placement.anchor.into(),
                    gravity: placement.gravity.into(),
                    offset: placement.offset,
                    constraint_adjustment: placement.constraint_adjustment,
                    reactive: true,
                    grab,
                },
            )
            .map_err(|error| error.to_string())
    }

    fn set_dialog_parent(child: &dyn Window, parent: &dyn Window) -> Result<(), String> {
        if let (Some(child_toplevel), Some(parent_toplevel)) =
            (child.xdg_toplevel(), parent.xdg_toplevel())
        {
            unsafe {
                ffi_dispatch!(
                    wayland_client_handle(),
                    wl_proxy_marshal,
                    child_toplevel.as_ptr().cast::<wl_proxy>(),
                    1_u32,
                    parent_toplevel.as_ptr().cast::<wl_proxy>()
                );
            }
            return Ok(());
        }

        let display = child.display_handle().map_err(|error| error.to_string())?;
        let child_handle = child.window_handle().map_err(|error| error.to_string())?;
        let parent_handle = parent.window_handle().map_err(|error| error.to_string())?;
        match (
            display.as_raw(),
            child_handle.as_raw(),
            parent_handle.as_raw(),
        ) {
            (
                RawDisplayHandle::Xlib(display),
                RawWindowHandle::Xlib(child),
                RawWindowHandle::Xlib(parent),
            ) => {
                let display = display
                    .display
                    .ok_or_else(|| "X11 display handle is null".to_owned())?;
                let xlib = x11_dl::xlib::Xlib::open().map_err(|error| error.to_string())?;
                unsafe {
                    (xlib.XSetTransientForHint)(
                        display.as_ptr().cast(),
                        child.window,
                        parent.window,
                    );
                    (xlib.XFlush)(display.as_ptr().cast());
                }
                Ok(())
            }
            _ => Err("native dialog parenting is unsupported by this display backend".to_owned()),
        }
    }
}

impl From<HostPopupAnchor> for PopupAnchor {
    fn from(anchor: HostPopupAnchor) -> Self {
        match anchor {
            HostPopupAnchor::None => Self::None,
            HostPopupAnchor::Top => Self::Top,
            HostPopupAnchor::Bottom => Self::Bottom,
            HostPopupAnchor::Left => Self::Left,
            HostPopupAnchor::Right => Self::Right,
            HostPopupAnchor::TopLeft => Self::TopLeft,
            HostPopupAnchor::BottomLeft => Self::BottomLeft,
            HostPopupAnchor::TopRight => Self::TopRight,
            HostPopupAnchor::BottomRight => Self::BottomRight,
        }
    }
}
