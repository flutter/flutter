//! Android GameActivity entry point.
//!
//! This crate proves the native entry-point seam described in
//! `flutter-rs.md` Phase 4, milestone 1: a winit-owned window backed by a
//! wgpu Vulkan surface, launched through `android_main` and packaged as a
//! standard Gradle app. It deliberately does not link the C++ `RustShell`
//! ABI (`flutter-shell-winit::run_application`) yet, since that ABI expects
//! the Dart VM/Impeller/Skia archives that a later milestone will bring to
//! Android; wiring it in now would require stubbing over a dozen
//! `FlutterRustShell*` extern "C" symbols with no engine behind them. Once
//! Android reaches the point of linking those archives, this crate's
//! `android_main` should hand off to `flutter-shell-winit::run_application`
//! the same way Linux's `cpp/main.cc` does today.

use std::sync::Arc;

use winit::application::ApplicationHandler;
use winit::event::WindowEvent;
use winit::event_loop::{ActiveEventLoop, EventLoop};
use winit::platform::android::EventLoopBuilderExtAndroid;
use winit::platform::android::activity::AndroidApp;
use winit::window::{Window, WindowAttributes, WindowId};

struct GpuSurface {
    window: Arc<dyn Window>,
    surface: wgpu::Surface<'static>,
    device: wgpu::Device,
    queue: wgpu::Queue,
    config: wgpu::SurfaceConfiguration,
}

#[derive(Default)]
struct AndroidShellApp {
    gpu: Option<GpuSurface>,
}

impl ApplicationHandler for AndroidShellApp {
    fn can_create_surfaces(&mut self, event_loop: &dyn ActiveEventLoop) {
        // GameActivity can call this more than once across a
        // pause/resume/surface-recreation cycle; tear down any stale GPU
        // state before creating the new one.
        self.gpu = None;

        let window: Arc<dyn Window> = Arc::from(
            event_loop
                .create_window(WindowAttributes::default())
                .expect("winit failed to create the Android surface window"),
        );

        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::VULKAN,
            ..wgpu::InstanceDescriptor::new_without_display_handle()
        });
        let surface = instance
            .create_surface(Arc::clone(&window))
            .expect("failed to create a wgpu Vulkan surface for the Android window");
        let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::default(),
            compatible_surface: Some(&surface),
            force_fallback_adapter: false,
            apply_limit_buckets: false,
        }))
        .expect("no Vulkan adapter available on this Android device");
        let (device, queue) = pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor {
            label: Some("flutter-shell-android-runner"),
            required_features: wgpu::Features::empty(),
            // `downlevel_defaults()` caps max_texture_dimension_2d at 2048,
            // which is smaller than common phone display heights; request
            // whatever the adapter actually supports for the full-screen
            // surface instead.
            required_limits: adapter.limits(),
            ..Default::default()
        }))
        .expect("failed to open a wgpu device");

        let size = window.surface_size();
        let mut config = surface
            .get_default_config(&adapter, size.width.max(1), size.height.max(1))
            .expect("Android Vulkan surface is incompatible with the chosen adapter");
        config.present_mode = wgpu::PresentMode::Fifo;
        surface.configure(&device, &config);

        log::info!("flutter-shell-android-runner: Vulkan surface configured ({size:?})");
        self.gpu = Some(GpuSurface {
            window,
            surface,
            device,
            queue,
            config,
        });
        self.gpu.as_ref().unwrap().window.request_redraw();
    }

    fn destroy_surfaces(&mut self, _event_loop: &dyn ActiveEventLoop) {
        // GameActivity destroys the native window when the Activity is
        // paused; drop the surface before the OS reclaims it.
        log::info!("flutter-shell-android-runner: surface destroyed");
        self.gpu = None;
    }

    fn window_event(&mut self, event_loop: &dyn ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        let Some(gpu) = self.gpu.as_mut() else {
            return;
        };
        match event {
            WindowEvent::SurfaceResized(size) => {
                gpu.config.width = size.width.max(1);
                gpu.config.height = size.height.max(1);
                gpu.surface.configure(&gpu.device, &gpu.config);
            }
            WindowEvent::RedrawRequested => {
                let frame = match gpu.surface.get_current_texture() {
                    wgpu::CurrentSurfaceTexture::Success(frame) => frame,
                    wgpu::CurrentSurfaceTexture::Suboptimal(frame) => frame,
                    wgpu::CurrentSurfaceTexture::Outdated => {
                        gpu.surface.configure(&gpu.device, &gpu.config);
                        gpu.window.request_redraw();
                        return;
                    }
                    _ => {
                        log::warn!("flutter-shell-android-runner: failed to acquire a frame");
                        return;
                    }
                };
                let view = frame
                    .texture
                    .create_view(&wgpu::TextureViewDescriptor::default());
                let mut encoder = gpu
                    .device
                    .create_command_encoder(&wgpu::CommandEncoderDescriptor::default());
                {
                    let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                        label: Some("android-runner-clear"),
                        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                            view: &view,
                            resolve_target: None,
                            ops: wgpu::Operations {
                                load: wgpu::LoadOp::Clear(wgpu::Color {
                                    r: 0.0,
                                    g: 0.4,
                                    b: 0.8,
                                    a: 1.0,
                                }),
                                store: wgpu::StoreOp::Store,
                            },
                            depth_slice: None,
                        })],
                        depth_stencil_attachment: None,
                        timestamp_writes: None,
                        occlusion_query_set: None,
                        ..Default::default()
                    });
                }
                gpu.queue.submit(Some(encoder.finish()));
                gpu.queue.present(frame);
                gpu.window.request_redraw();
                let _ = event_loop;
            }
            _ => {}
        }
    }
}

#[unsafe(no_mangle)]
fn android_main(app: AndroidApp) {
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Info)
            .with_tag("flutter_shell_android_runner"),
    );
    std::panic::set_hook(Box::new(|info| {
        log::error!("flutter-shell-android-runner panicked: {info}");
    }));

    let event_loop: EventLoop = EventLoop::builder()
        .with_android_app(app)
        .build()
        .expect("failed to create the Android winit event loop");

    event_loop
        .run_app(AndroidShellApp::default())
        .expect("Android winit event loop exited with an error");
}
