//! The one unsafe Rust component that exposes wgpu's Vulkan objects to the
//! private Flutter engine bridge. Rust retains ownership of every object.

#![deny(unsafe_op_in_unsafe_fn)]

// This module is Vulkan/wgpu code with no Linux-specific dependencies; it
// currently builds for every platform that has a working `ash`/`wgpu`
// Vulkan target dependency block in Cargo.toml (Linux and Android so far).
#[cfg(any(target_os = "linux", target_os = "android"))]
mod vulkan {
    use ash::vk::Handle as _;
    use flutter_plugin_sdk::{
        PixelBufferTextureBackendHandle, PixelBufferTextureFrameBackend, PixelWriteTask,
        PluginError, Result as PluginResult, WgpuRenderTask, WgpuTextureBackendHandle,
        WgpuTextureFrameBackend,
    };
    use flutter_shell_core::{
        FlutterRustExternalTextureCallbacks, FlutterRustExternalTextureFrame,
        FlutterRustVulkanImage, FlutterRustVulkanPresentationCallbacks,
    };
    use parking_lot::Mutex;
    use std::collections::VecDeque;
    use std::ffi::c_void;
    use std::fs::File;
    use std::io::Write;
    use std::path::PathBuf;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicBool, AtomicI64, AtomicU8, Ordering};
    use tokio::sync::mpsc;

    /// Application-scoped wgpu/Vulkan ownership shared by every native view.
    pub struct GpuContext {
        instance: wgpu::Instance,
        adapter: wgpu::Adapter,
        device: wgpu::Device,
        queue: wgpu::Queue,
    }

    /// Borrowed Vulkan object values suitable only for an immediate C++ call.
    /// Their lifetime is tied to the [`GpuBroker`] that supplied them.
    #[derive(Debug, Clone, PartialEq, Eq)]
    pub struct VulkanContextData {
        pub get_instance_proc_addr: usize,
        pub instance: usize,
        pub physical_device: usize,
        pub device: usize,
        pub queue: usize,
        pub queue_family_index: u32,
        pub instance_extensions: Vec<String>,
        pub device_extensions: Vec<String>,
    }

    /// Wgpu owns the instance, device, queue, and surface. The broker exposes
    /// Vulkan values only through [`Self::with_vulkan_context`], preventing a
    /// Rust reference from escaping the handoff into C++.
    pub struct GpuBroker {
        context: std::sync::Arc<GpuContext>,
        // Swappable as a pair so `recreate_surface` can replace both without
        // moving (and thereby invalidating the address of) the `GpuBroker`
        // itself: C++ holds a raw pointer to it for the shell's lifetime via
        // `presentation_callbacks`'s `user_data`.
        presentable: parking_lot::RwLock<Presentable>,
        surface_state: Mutex<SurfaceState>,
        presentation_stats: Option<Mutex<PresentationStats>>,
    }

    struct Presentable {
        surface: wgpu::Surface<'static>,
        // Retained both for the unsafe surface lifetime and so presentation
        // can notify winit immediately before the Vulkan WSI commit.
        window: std::sync::Arc<dyn winit::window::Window>,
    }

    /// Engine-owned triple-buffered texture storage shared by wgpu producers
    /// and Flutter's Impeller raster thread.
    #[derive(Clone)]
    pub struct WgpuTextureRing {
        inner: Arc<WgpuTextureRingInner>,
    }

    type FrameAvailableCallback = Arc<dyn Fn(i64) -> PluginResult<()> + Send + Sync>;

    struct WgpuTextureRingInner {
        context: Arc<GpuContext>,
        width: u32,
        height: u32,
        state: Mutex<TextureRingState>,
        available: AvailableSlots,
        pending_clear: Mutex<Option<[f64; 4]>>,
        texture_id: AtomicI64,
        mark_frame_available: Mutex<Option<FrameAvailableCallback>>,
    }

    struct AvailableSlots {
        sender: Mutex<Option<mpsc::Sender<usize>>>,
        receiver: tokio::sync::Mutex<mpsc::Receiver<usize>>,
        shutdown: AtomicBool,
    }

    impl AvailableSlots {
        fn new(count: usize) -> Self {
            let (sender, receiver) = mpsc::channel(count);
            for index in 0..count {
                sender
                    .try_send(index)
                    .expect("new slot channel has capacity");
            }
            Self {
                sender: Mutex::new(Some(sender)),
                receiver: tokio::sync::Mutex::new(receiver),
                shutdown: AtomicBool::new(false),
            }
        }

        fn is_shutdown(&self) -> bool {
            self.shutdown.load(Ordering::Acquire)
        }

        fn try_take(&self) -> PluginResult<usize> {
            if self.is_shutdown() {
                return Err(PluginError::Shutdown);
            }
            let mut receiver = self.receiver.try_lock().map_err(|_| PluginError::Busy)?;
            match receiver.try_recv() {
                Ok(index) if !self.is_shutdown() => Ok(index),
                Ok(_) | Err(mpsc::error::TryRecvError::Disconnected) => Err(PluginError::Shutdown),
                Err(mpsc::error::TryRecvError::Empty) => Err(PluginError::Busy),
            }
        }

        async fn take(&self) -> PluginResult<usize> {
            let index = self
                .receiver
                .lock()
                .await
                .recv()
                .await
                .ok_or(PluginError::Shutdown)?;
            if self.is_shutdown() {
                Err(PluginError::Shutdown)
            } else {
                Ok(index)
            }
        }

        fn give_back(&self, index: usize) {
            if let Some(sender) = self.sender.lock().as_ref() {
                let _ = sender.try_send(index);
            }
        }

        fn shutdown(&self) {
            self.shutdown.store(true, Ordering::Release);
            self.sender.lock().take();
        }
    }

    struct TextureRingState {
        slots: Vec<TextureSlot>,
        ready: VecDeque<usize>,
    }

    struct TextureSlot {
        texture: wgpu::Texture,
        view: wgpu::TextureView,
        image: ash::vk::Image,
        image_view: ash::vk::ImageView,
        sync: FrameSync,
        state: TextureSlotState,
        wait_for_flutter: bool,
        render_task: Option<WgpuRenderTask>,
        pixels: Vec<u8>,
        pixels_written: bool,
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    enum TextureSlotState {
        Available,
        Reserved,
        Ready,
        InFlutter,
    }

    const FRAME_RESERVED: u8 = 0;
    const FRAME_PRESENTED: u8 = 1;
    const FRAME_RETURNED: u8 = 2;

    struct ReservedWgpuTextureFrame {
        ring: Arc<WgpuTextureRingInner>,
        slot: usize,
        state: AtomicU8,
    }

    struct ReservedPixelBufferTextureFrame {
        ring: Arc<WgpuTextureRingInner>,
        slot: usize,
        state: AtomicU8,
    }

    struct PresentationStats {
        file: File,
        count: u64,
    }

    impl PresentationStats {
        fn create(path: PathBuf) -> Result<Self, String> {
            let file = File::create(&path).map_err(|error| {
                format!(
                    "failed to create presentation stats file {}: {error}",
                    path.display()
                )
            })?;
            Ok(Self { file, count: 0 })
        }

        fn record(&mut self, width: u32, height: u32) {
            self.count += 1;
            let _ = writeln!(self.file, "{} {width} {height}", self.count);
            let _ = self.file.flush();
        }
    }

    struct SurfaceState {
        configuration: Option<wgpu::SurfaceConfiguration>,
        // Holds the acquired frame between `acquire_image` and `present_image`.
        // wgpu must not destroy the swapchain image while Impeller is drawing
        // into it through the raw handle handed to C++.
        pending_frame: Option<PendingFrame>,
        // Wgpu forbids reconfiguration while a SurfaceTexture is outstanding.
        // Resize events therefore replace this with the latest requested
        // configuration, which is applied at the next safe acquire boundary.
        deferred_configuration: Option<wgpu::SurfaceConfiguration>,
        // Synchronization objects are kept alive until the final wgpu
        // submission that consumed them has completed. A small bounded queue
        // preserves normal frame overlap without leaking one pair per frame.
        retired_frames: VecDeque<RetiredFrame>,
        // Set while the native surface behind `presentable` is known invalid
        // (e.g. Android destroyed the window on minimize) and cleared once
        // `GpuBroker::recreate_surface` has replaced it. Acquiring or
        // presenting during this window would touch a dead swapchain.
        suspended: bool,
    }

    struct PendingFrame {
        texture: wgpu::SurfaceTexture,
        sync: FrameSync,
    }

    struct RetiredFrame {
        submission: wgpu::SubmissionIndex,
        sync: FrameSync,
    }

    #[derive(Debug, Clone, Copy)]
    struct FrameSync {
        acquire: ash::vk::Semaphore,
        render: ash::vk::Semaphore,
    }

    /// A Vulkan swapchain image borrowed from the broker's current frame.
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct AcquiredImage {
        pub image: u64,
        pub format: u32,
        pub acquire_semaphore: u64,
        pub render_semaphore: u64,
    }

    fn vulkan_format(format: wgpu::TextureFormat) -> Option<ash::vk::Format> {
        use wgpu::TextureFormat::*;
        Some(match format {
            Bgra8Unorm => ash::vk::Format::B8G8R8A8_UNORM,
            Bgra8UnormSrgb => ash::vk::Format::B8G8R8A8_SRGB,
            Rgba8Unorm => ash::vk::Format::R8G8B8A8_UNORM,
            Rgba8UnormSrgb => ash::vk::Format::R8G8B8A8_SRGB,
            Rgba16Float => ash::vk::Format::R16G16B16A16_SFLOAT,
            _ => return None,
        })
    }

    impl GpuContext {
        fn new_for_window(
            window: &std::sync::Arc<dyn winit::window::Window>,
        ) -> Result<std::sync::Arc<Self>, String> {
            let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
                backends: wgpu::Backends::VULKAN,
                ..wgpu::InstanceDescriptor::new_without_display_handle()
            });
            // This temporary surface selects a device that can present to the
            // application's initial native window.
            let surface = unsafe {
                instance.create_surface_unsafe(
                    wgpu::SurfaceTargetUnsafe::from_display_and_window(window, window)
                        .map_err(|error| error.to_string())?,
                )
            }
            .map_err(|error| error.to_string())?;
            let adapter =
                pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
                    power_preference: wgpu::PowerPreference::HighPerformance,
                    force_fallback_adapter: false,
                    compatible_surface: Some(&surface),
                    apply_limit_buckets: false,
                }))
                .map_err(|error| error.to_string())?;
            let device_descriptor = wgpu::DeviceDescriptor {
                label: Some("Flutter Rust Shell Vulkan device"),
                required_features: wgpu::Features::empty(),
                // `downlevel_defaults()` caps max_texture_dimension_2d at
                // 2048, smaller than common phone display heights (e.g.
                // 2408px); request whatever the adapter actually
                // supports for the full-screen surface instead. This was
                // latent on Linux, where monitor heights rarely exceed
                // 2048px, until Android surfaced it (see
                // flutter-rs-proggress.md milestone 2).
                required_limits: adapter.limits(),
                ..Default::default()
            };
            #[cfg(target_os = "android")]
            let (device, queue) = {
                // Impeller's Android capability check (capabilities_vk.cc)
                // hard-requires these device extensions for
                // AHardwareBuffer-backed texture interop; wgpu has no
                // concept of them since it never needs them itself, so the
                // safe `request_device` path never enables them and C++
                // rejects the device as unsuitable. `open_with_callback` is
                // this wgpu-hal fork's supported escape hatch for injecting
                // extra Vulkan device extensions before creation.
                let open_device = {
                    let hal_adapter = unsafe { adapter.as_hal::<wgpu::hal::vulkan::Api>() }
                        .ok_or_else(|| "adapter is not a Vulkan adapter".to_owned())?;
                    unsafe {
                        hal_adapter.open_with_callback(
                            device_descriptor.required_features,
                            &device_descriptor.required_limits,
                            &wgpu::MemoryHints::default(),
                            Some(Box::new(|args| {
                                args.extensions
                                    .push(c"VK_ANDROID_external_memory_android_hardware_buffer");
                                args.extensions.push(c"VK_KHR_sampler_ycbcr_conversion");
                                args.extensions.push(c"VK_KHR_external_memory");
                                args.extensions.push(c"VK_EXT_queue_family_foreign");
                                args.extensions.push(c"VK_KHR_dedicated_allocation");
                            })),
                        )
                    }
                    .map_err(|error| error.to_string())?
                };
                unsafe { adapter.create_device_from_hal(open_device, &device_descriptor) }
                    .map_err(|error| error.to_string())?
            };
            #[cfg(not(target_os = "android"))]
            let (device, queue) = pollster::block_on(adapter.request_device(&device_descriptor))
                .map_err(|error| error.to_string())?;
            Ok(std::sync::Arc::new(Self {
                instance,
                adapter,
                device,
                queue,
            }))
        }

        /// Creates external-texture storage on this shared device.
        pub fn create_texture_ring(
            self: &Arc<Self>,
            width: u32,
            height: u32,
        ) -> Result<Box<WgpuTextureRing>, String> {
            WgpuTextureRing::new(Arc::clone(self), width, height, false)
        }

        /// Creates a texture ring with reusable shell-owned CPU pixel buffers.
        pub fn create_pixel_buffer_texture_ring(
            self: &Arc<Self>,
            width: u32,
            height: u32,
        ) -> Result<Box<WgpuTextureRing>, String> {
            WgpuTextureRing::new(Arc::clone(self), width, height, true)
        }
    }

    impl WgpuTextureRing {
        fn new(
            context: std::sync::Arc<GpuContext>,
            width: u32,
            height: u32,
            allocate_pixels: bool,
        ) -> Result<Box<Self>, String> {
            if width == 0 || height == 0 {
                return Err("external texture dimensions must be nonzero".to_owned());
            }
            let mut slots = Vec::with_capacity(3);
            let pixel_bytes = (width as usize)
                .checked_mul(height as usize)
                .and_then(|size| size.checked_mul(4))
                .ok_or_else(|| "pixel-buffer dimensions overflow address space".to_owned())?;
            for index in 0..3 {
                let texture = context.device.create_texture(&wgpu::TextureDescriptor {
                    label: Some("Flutter Rust external texture slot"),
                    size: wgpu::Extent3d {
                        width,
                        height,
                        depth_or_array_layers: 1,
                    },
                    mip_level_count: 1,
                    sample_count: 1,
                    dimension: wgpu::TextureDimension::D2,
                    format: wgpu::TextureFormat::Rgba8Unorm,
                    usage: wgpu::TextureUsages::RENDER_ATTACHMENT
                        | wgpu::TextureUsages::TEXTURE_BINDING
                        | wgpu::TextureUsages::COPY_DST,
                    view_formats: &[],
                });
                let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
                // SAFETY: only the numeric borrowed handles escape these
                // guards. The slot retains both wgpu objects through every
                // callback and until the device is idle during drop.
                let image = unsafe {
                    texture
                        .as_hal::<wgpu::hal::vulkan::Api>()
                        .ok_or("wgpu texture is not Vulkan")?
                        .raw_handle()
                };
                let image_view = unsafe {
                    view.as_hal::<wgpu::hal::vulkan::Api>()
                        .ok_or("wgpu texture view is not Vulkan")?
                        .raw_handle()
                };
                let device = unsafe { context.device.as_hal::<wgpu::hal::vulkan::Api>() }
                    .ok_or("wgpu device is not Vulkan")?;
                let raw = device.raw_device();
                let acquire =
                    unsafe { raw.create_semaphore(&ash::vk::SemaphoreCreateInfo::default(), None) }
                        .map_err(|error| format!("failed to create acquire semaphore: {error}"))?;
                let render = match unsafe {
                    raw.create_semaphore(&ash::vk::SemaphoreCreateInfo::default(), None)
                } {
                    Ok(semaphore) => semaphore,
                    Err(error) => {
                        unsafe { raw.destroy_semaphore(acquire, None) };
                        return Err(format!("failed to create render semaphore: {error}"));
                    }
                };
                let mut pixels = Vec::new();
                if allocate_pixels {
                    pixels.try_reserve_exact(pixel_bytes).map_err(|error| {
                        format!("failed to allocate pixel-buffer slot: {error}")
                    })?;
                    pixels.resize(pixel_bytes, 0);
                }
                slots.push(TextureSlot {
                    texture,
                    view,
                    image,
                    image_view,
                    sync: FrameSync { acquire, render },
                    state: TextureSlotState::Available,
                    wait_for_flutter: false,
                    render_task: None,
                    pixels,
                    pixels_written: false,
                });
                debug_assert_eq!(slots.len(), index + 1);
            }
            Ok(Box::new(Self {
                inner: Arc::new(WgpuTextureRingInner {
                    context,
                    width,
                    height,
                    state: Mutex::new(TextureRingState {
                        slots,
                        ready: VecDeque::new(),
                    }),
                    available: AvailableSlots::new(3),
                    pending_clear: Mutex::new(None),
                    texture_id: AtomicI64::new(-1),
                    mark_frame_available: Mutex::new(None),
                }),
            }))
        }

        /// Connects this ring to the shell texture registry. This is private
        /// runtime plumbing; plugins receive only the SDK handle.
        pub fn set_registration(
            &self,
            texture_id: i64,
            mark_frame_available: impl Fn(i64) -> PluginResult<()> + Send + Sync + 'static,
        ) {
            self.inner.texture_id.store(texture_id, Ordering::Release);
            *self.inner.mark_frame_available.lock() = Some(Arc::new(mark_frame_available));
        }

        /// Stops frame production and wakes tasks waiting for a free slot.
        /// Existing Flutter frames remain alive until their release callback.
        pub fn shutdown(&self) {
            self.inner.mark_frame_available.lock().take();
            self.inner.available.shutdown();
        }

        /// Requests a solid-color frame. Rendering is deliberately deferred to
        /// Flutter's acquire callback so wgpu and Impeller never submit to the
        /// shared Vulkan queue concurrently.
        pub fn request_clear(&self, color: [f64; 4]) {
            *self.inner.pending_clear.lock() = Some(color);
        }

        fn render_pending_clear(&self) -> bool {
            let Some(color) = self.inner.pending_clear.lock().take() else {
                return false;
            };
            let Ok(index) = self.inner.try_reserve_slot() else {
                *self.inner.pending_clear.lock() = Some(color);
                return false;
            };
            let task: WgpuRenderTask = Box::new(move |_, encoder, view| {
                let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("Flutter Rust external texture clear"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
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
                    })],
                    ..Default::default()
                });
            });
            self.inner.record(index, task).is_ok() && self.inner.publish(index, false).is_ok()
        }

        /// Returns callbacks whose user data is valid while this boxed ring
        /// remains alive.
        pub fn callbacks(&self) -> FlutterRustExternalTextureCallbacks {
            FlutterRustExternalTextureCallbacks {
                user_data: (self as *const Self).cast_mut().cast::<c_void>(),
                acquire_frame: Some(acquire_external_texture_frame),
                release_frame: Some(release_external_texture_frame),
            }
        }
    }

    impl WgpuTextureRingInner {
        fn is_shutdown(&self) -> bool {
            self.available.is_shutdown()
        }

        fn return_available(&self, index: usize) {
            self.available.give_back(index);
        }

        fn claim_slot(&self, index: usize) -> PluginResult<usize> {
            if self.is_shutdown() {
                return Err(PluginError::Shutdown);
            }
            let mut state = self.state.lock();
            let Some(slot) = state.slots.get_mut(index) else {
                return Err(PluginError::Shutdown);
            };
            if slot.state != TextureSlotState::Available {
                return Err(PluginError::Busy);
            }
            slot.state = TextureSlotState::Reserved;
            Ok(index)
        }

        fn try_reserve_slot(&self) -> PluginResult<usize> {
            if self.is_shutdown() {
                return Err(PluginError::Shutdown);
            }
            self.claim_slot(self.available.try_take()?)
        }

        async fn reserve_slot(&self) -> PluginResult<usize> {
            self.claim_slot(self.available.take().await?)
        }

        fn record(&self, index: usize, task: WgpuRenderTask) -> PluginResult<()> {
            let mut state = self.state.lock();
            let Some(slot) = state.slots.get_mut(index) else {
                return Err(PluginError::Shutdown);
            };
            if slot.state != TextureSlotState::Reserved
                || slot.render_task.is_some()
                || slot.pixels_written
            {
                return Err(PluginError::Busy);
            }
            slot.render_task = Some(task);
            Ok(())
        }

        fn write_pixels(&self, index: usize, task: PixelWriteTask) -> PluginResult<()> {
            let mut state = self.state.lock();
            let Some(slot) = state.slots.get_mut(index) else {
                return Err(PluginError::Shutdown);
            };
            if slot.state != TextureSlotState::Reserved
                || slot.render_task.is_some()
                || slot.pixels_written
                || slot.pixels.is_empty()
            {
                return Err(PluginError::Busy);
            }
            task(&mut slot.pixels, self.width as usize * 4);
            slot.pixels_written = true;
            Ok(())
        }

        fn publish(&self, index: usize, notify_flutter: bool) -> PluginResult<()> {
            if self.is_shutdown() {
                return Err(PluginError::Shutdown);
            }
            {
                let mut state = self.state.lock();
                let Some(slot) = state.slots.get_mut(index) else {
                    return Err(PluginError::Shutdown);
                };
                if slot.state != TextureSlotState::Reserved {
                    return Err(PluginError::Busy);
                }
                if slot.render_task.is_none() && !slot.pixels_written {
                    return Err(PluginError::NoFrame);
                }
                slot.state = TextureSlotState::Ready;
                state.ready.push_back(index);
            }
            if notify_flutter {
                let texture_id = self.texture_id.load(Ordering::Acquire);
                let mark = self.mark_frame_available.lock().clone();
                let Some(mark) = mark else {
                    self.return_ready_slot(index);
                    return Err(PluginError::Shutdown);
                };
                if let Err(error) = mark(texture_id) {
                    self.return_ready_slot(index);
                    return Err(error);
                }
            }
            Ok(())
        }

        fn return_ready_slot(&self, index: usize) {
            let should_send = {
                let mut state = self.state.lock();
                state.ready.retain(|ready| *ready != index);
                let Some(slot) = state.slots.get_mut(index) else {
                    return;
                };
                if slot.state != TextureSlotState::Ready {
                    return;
                }
                slot.render_task = None;
                slot.pixels_written = false;
                slot.state = TextureSlotState::Available;
                true
            };
            if should_send {
                self.return_available(index);
            }
        }

        fn return_reserved_slot(&self, index: usize) {
            let should_send = {
                let mut state = self.state.lock();
                let Some(slot) = state.slots.get_mut(index) else {
                    return;
                };
                if slot.state != TextureSlotState::Reserved {
                    return;
                }
                slot.render_task = None;
                slot.pixels_written = false;
                slot.state = TextureSlotState::Available;
                true
            };
            if should_send {
                self.return_available(index);
            }
        }
    }

    #[async_trait::async_trait]
    impl WgpuTextureBackendHandle for WgpuTextureRing {
        fn texture_id(&self) -> i64 {
            self.inner.texture_id.load(Ordering::Acquire)
        }

        fn try_next_frame(&self) -> PluginResult<Arc<dyn WgpuTextureFrameBackend>> {
            let slot = self.inner.try_reserve_slot()?;
            Ok(Arc::new(ReservedWgpuTextureFrame {
                ring: Arc::clone(&self.inner),
                slot,
                state: AtomicU8::new(FRAME_RESERVED),
            }))
        }

        async fn next_frame(&self) -> PluginResult<Arc<dyn WgpuTextureFrameBackend>> {
            let slot = self.inner.reserve_slot().await?;
            Ok(Arc::new(ReservedWgpuTextureFrame {
                ring: Arc::clone(&self.inner),
                slot,
                state: AtomicU8::new(FRAME_RESERVED),
            }))
        }
    }

    impl WgpuTextureFrameBackend for ReservedWgpuTextureFrame {
        fn render(&self, task: WgpuRenderTask) -> PluginResult<()> {
            if self.state.load(Ordering::Acquire) != FRAME_RESERVED {
                return Err(PluginError::Busy);
            }
            self.ring.record(self.slot, task)
        }

        fn present(&self) -> PluginResult<()> {
            self.state
                .compare_exchange(
                    FRAME_RESERVED,
                    FRAME_PRESENTED,
                    Ordering::AcqRel,
                    Ordering::Acquire,
                )
                .map_err(|_| PluginError::Busy)?;
            match self.ring.publish(self.slot, true) {
                Ok(()) => Ok(()),
                Err(error) => {
                    self.ring.return_reserved_slot(self.slot);
                    self.state.store(FRAME_RETURNED, Ordering::Release);
                    Err(error)
                }
            }
        }
    }

    impl Drop for ReservedWgpuTextureFrame {
        fn drop(&mut self) {
            if self
                .state
                .compare_exchange(
                    FRAME_RESERVED,
                    FRAME_RETURNED,
                    Ordering::AcqRel,
                    Ordering::Acquire,
                )
                .is_ok()
            {
                self.ring.return_reserved_slot(self.slot);
            }
        }
    }

    #[async_trait::async_trait]
    impl PixelBufferTextureBackendHandle for WgpuTextureRing {
        fn texture_id(&self) -> i64 {
            self.inner.texture_id.load(Ordering::Acquire)
        }

        fn try_next_frame(&self) -> PluginResult<Arc<dyn PixelBufferTextureFrameBackend>> {
            let slot = self.inner.try_reserve_slot()?;
            Ok(Arc::new(ReservedPixelBufferTextureFrame {
                ring: Arc::clone(&self.inner),
                slot,
                state: AtomicU8::new(FRAME_RESERVED),
            }))
        }

        async fn next_frame(&self) -> PluginResult<Arc<dyn PixelBufferTextureFrameBackend>> {
            let slot = self.inner.reserve_slot().await?;
            Ok(Arc::new(ReservedPixelBufferTextureFrame {
                ring: Arc::clone(&self.inner),
                slot,
                state: AtomicU8::new(FRAME_RESERVED),
            }))
        }
    }

    impl PixelBufferTextureFrameBackend for ReservedPixelBufferTextureFrame {
        fn write_pixels(&self, task: PixelWriteTask) -> PluginResult<()> {
            if self.state.load(Ordering::Acquire) != FRAME_RESERVED {
                return Err(PluginError::Busy);
            }
            self.ring.write_pixels(self.slot, task)
        }

        fn present(&self) -> PluginResult<()> {
            self.state
                .compare_exchange(
                    FRAME_RESERVED,
                    FRAME_PRESENTED,
                    Ordering::AcqRel,
                    Ordering::Acquire,
                )
                .map_err(|_| PluginError::Busy)?;
            match self.ring.publish(self.slot, true) {
                Ok(()) => Ok(()),
                Err(error) => {
                    self.ring.return_reserved_slot(self.slot);
                    self.state.store(FRAME_RETURNED, Ordering::Release);
                    Err(error)
                }
            }
        }
    }

    impl Drop for ReservedPixelBufferTextureFrame {
        fn drop(&mut self) {
            if self
                .state
                .compare_exchange(
                    FRAME_RESERVED,
                    FRAME_RETURNED,
                    Ordering::AcqRel,
                    Ordering::Acquire,
                )
                .is_ok()
            {
                self.ring.return_reserved_slot(self.slot);
            }
        }
    }

    impl Drop for WgpuTextureRingInner {
        fn drop(&mut self) {
            let Some(device) = (unsafe { self.context.device.as_hal::<wgpu::hal::vulkan::Api>() })
            else {
                return;
            };
            let _ = unsafe { device.raw_device().device_wait_idle() };
            let state = self.state.get_mut();
            for slot in &state.slots {
                unsafe {
                    device
                        .raw_device()
                        .destroy_semaphore(slot.sync.acquire, None);
                    device
                        .raw_device()
                        .destroy_semaphore(slot.sync.render, None);
                }
            }
        }
    }

    impl GpuBroker {
        /// Creates an engine-owned external texture ring on this application's
        /// shared wgpu device.
        pub fn create_texture_ring(
            &self,
            width: u32,
            height: u32,
        ) -> Result<Box<WgpuTextureRing>, String> {
            self.context.create_texture_ring(width, height)
        }

        /// Creates an external texture ring with reusable CPU pixel buffers.
        pub fn create_pixel_buffer_texture_ring(
            &self,
            width: u32,
            height: u32,
        ) -> Result<Box<WgpuTextureRing>, String> {
            self.context.create_pixel_buffer_texture_ring(width, height)
        }

        pub fn new(
            window: std::sync::Arc<dyn winit::window::Window>,
            presentation_stats_path: Option<PathBuf>,
        ) -> Result<Self, String> {
            let context = GpuContext::new_for_window(&window)?;
            Self::from_context(context, window, presentation_stats_path)
        }

        pub fn from_context(
            context: std::sync::Arc<GpuContext>,
            window: std::sync::Arc<dyn winit::window::Window>,
            presentation_stats_path: Option<PathBuf>,
        ) -> Result<Self, String> {
            // SAFETY: the broker retains the window until after this surface
            // has been destroyed.
            let surface = unsafe {
                context.instance.create_surface_unsafe(
                    wgpu::SurfaceTargetUnsafe::from_display_and_window(&window, &window)
                        .map_err(|error| error.to_string())?,
                )
            }
            .map_err(|error| error.to_string())?;
            if surface
                .get_capabilities(&context.adapter)
                .formats
                .is_empty()
            {
                return Err("shared Vulkan adapter cannot present to this window".to_owned());
            }
            let presentation_stats = presentation_stats_path
                .map(PresentationStats::create)
                .transpose()?
                .map(Mutex::new);
            Ok(Self {
                context,
                presentable: parking_lot::RwLock::new(Presentable { surface, window }),
                surface_state: Mutex::new(SurfaceState {
                    configuration: None,
                    pending_frame: None,
                    deferred_configuration: None,
                    retired_frames: VecDeque::new(),
                    suspended: false,
                }),
                presentation_stats,
            })
        }

        pub fn shared_context(&self) -> std::sync::Arc<GpuContext> {
            std::sync::Arc::clone(&self.context)
        }

        /// Marks the current surface as unusable without destroying the
        /// broker. Android destroys the native window (and therefore the
        /// wgpu surface backed by it) when the activity is paused; further
        /// acquire/present calls in that window would touch a dead
        /// swapchain. Call [`Self::recreate_surface`] once a replacement
        /// window exists to resume presentation.
        pub fn suspend(&self) {
            self.surface_state.lock().suspended = true;
        }

        /// Replaces the broker's surface and window in place, keeping this
        /// `GpuBroker`'s address (and therefore every raw pointer C++ holds
        /// to it via `presentation_callbacks`) stable. Used to recover from
        /// Android's destroy/recreate window cycle without rebuilding the
        /// C++ shell or Vulkan device.
        pub fn recreate_surface(
            &self,
            window: std::sync::Arc<dyn winit::window::Window>,
        ) -> Result<(), String> {
            // SAFETY: the broker retains the window until after this surface
            // has been destroyed.
            let surface = unsafe {
                self.context.instance.create_surface_unsafe(
                    wgpu::SurfaceTargetUnsafe::from_display_and_window(&window, &window)
                        .map_err(|error| error.to_string())?,
                )
            }
            .map_err(|error| error.to_string())?;
            if surface
                .get_capabilities(&self.context.adapter)
                .formats
                .is_empty()
            {
                return Err("shared Vulkan adapter cannot present to this window".to_owned());
            }
            let mut state = self.surface_state.lock();
            self.destroy_all_frames(&mut state);
            state.configuration = None;
            state.deferred_configuration = None;
            *self.presentable.write() = Presentable { surface, window };
            state.suspended = false;
            Ok(())
        }

        /// Waits for the device to go idle, then destroys every outstanding
        /// frame-sync semaphore. Shared by `Drop` (full teardown) and
        /// `recreate_surface` (the old surface's in-flight frames can never
        /// be presented once the native window is gone).
        fn destroy_all_frames(&self, state: &mut SurfaceState) {
            let Some(device) = (unsafe { self.context.device.as_hal::<wgpu::hal::vulkan::Api>() })
            else {
                return;
            };
            let _ = unsafe { device.raw_device().device_wait_idle() };
            if let Some(pending) = state.pending_frame.take() {
                unsafe {
                    device
                        .raw_device()
                        .destroy_semaphore(pending.sync.acquire, None);
                    device
                        .raw_device()
                        .destroy_semaphore(pending.sync.render, None);
                }
            }
            for retired in state.retired_frames.drain(..) {
                unsafe {
                    device
                        .raw_device()
                        .destroy_semaphore(retired.sync.acquire, None);
                    device
                        .raw_device()
                        .destroy_semaphore(retired.sync.render, None);
                }
            }
        }

        fn create_frame_sync(&self) -> Option<FrameSync> {
            // SAFETY: the HAL guard keeps wgpu's device alive while the raw
            // Vulkan calls create objects owned by this broker.
            let device = unsafe { self.context.device.as_hal::<wgpu::hal::vulkan::Api>() }?;
            let raw = device.raw_device();
            let acquire = unsafe {
                raw.create_semaphore(&ash::vk::SemaphoreCreateInfo::default(), None)
                    .ok()?
            };
            let render = match unsafe {
                raw.create_semaphore(&ash::vk::SemaphoreCreateInfo::default(), None)
            } {
                Ok(semaphore) => semaphore,
                Err(_) => {
                    unsafe { raw.destroy_semaphore(acquire, None) };
                    return None;
                }
            };
            Some(FrameSync { acquire, render })
        }

        fn destroy_frame_sync(&self, sync: FrameSync) {
            // SAFETY: callers wait for the submission that consumed both
            // semaphores before destroying them.
            let Some(device) = (unsafe { self.context.device.as_hal::<wgpu::hal::vulkan::Api>() })
            else {
                return;
            };
            unsafe {
                device.raw_device().destroy_semaphore(sync.acquire, None);
                device.raw_device().destroy_semaphore(sync.render, None);
            }
        }

        fn wait_and_destroy(&self, retired: RetiredFrame) -> bool {
            if self
                .context
                .device
                .poll(wgpu::PollType::Wait {
                    submission_index: Some(retired.submission),
                    timeout: None,
                })
                .is_err()
            {
                return false;
            }
            self.destroy_frame_sync(retired.sync);
            true
        }

        /// Calls `callback` while wgpu-hal guards keep the borrowed Vulkan
        /// device alive. The callback must copy values immediately and must
        /// not destroy or submit through the handles.
        pub fn with_vulkan_context<T>(
            &self,
            callback: impl FnOnce(VulkanContextData) -> T,
        ) -> Option<T> {
            // SAFETY: the broker retains wgpu ownership, and no HAL resource
            // is destroyed or submitted through this borrowed handle.
            let device = unsafe { self.context.device.as_hal::<wgpu::hal::vulkan::Api>() }?;
            let instance = device.shared_instance();
            Some(callback(VulkanContextData {
                get_instance_proc_addr: instance.entry().static_fn().get_instance_proc_addr
                    as usize,
                instance: instance.raw_instance().handle().as_raw() as usize,
                physical_device: device.raw_physical_device().as_raw() as usize,
                device: device.raw_device().handle().as_raw() as usize,
                queue: device.raw_queue().as_raw() as usize,
                queue_family_index: device.queue_family_index(),
                instance_extensions: instance
                    .extensions()
                    .iter()
                    .map(|extension| extension.to_string_lossy().into_owned())
                    .collect(),
                device_extensions: device
                    .enabled_device_extensions()
                    .iter()
                    .map(|extension| extension.to_string_lossy().into_owned())
                    .collect(),
            }))
        }

        /// Configure the Rust-owned surface after winit reports a non-zero
        /// physical size. Acquisition/presentation stays in this broker.
        pub fn configure(&self, width: u32, height: u32) -> Result<(), String> {
            if width == 0 || height == 0 {
                return Ok(());
            }
            let mut state = self.surface_state.lock();
            let presentable = self.presentable.read();
            let capabilities = presentable.surface.get_capabilities(&self.context.adapter);
            // Impeller's Vulkan backend only recognizes these two swapchain
            // formats (see VkFormatToImpellerFormat); sRGB and other variants
            // the surface may prefer are rejected at frame-acquire time.
            let format = [
                wgpu::TextureFormat::Bgra8Unorm,
                wgpu::TextureFormat::Rgba8Unorm,
            ]
            .into_iter()
            .find(|format| capabilities.formats.contains(format))
            .ok_or_else(|| "Vulkan surface has no format Impeller supports".to_owned())?;
            let configuration = wgpu::SurfaceConfiguration {
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                format,
                color_space: wgpu::SurfaceColorSpace::Auto,
                width,
                height,
                present_mode: wgpu::PresentMode::Fifo,
                alpha_mode: capabilities.alpha_modes[0],
                view_formats: vec![],
                desired_maximum_frame_latency: 2,
            };
            // Once the surface is initialized, resize is applied at the next
            // acquire boundary. This coalesces compositor resize bursts and
            // prevents repeated configure calls between presentation and
            // wgpu's retirement of its internal WSI acquire fence.
            if state.configuration.is_some() {
                state.deferred_configuration = Some(configuration);
                return Ok(());
            }
            presentable
                .surface
                .configure(&self.context.device, &configuration);
            state.configuration = Some(configuration);
            state.deferred_configuration = None;
            Ok(())
        }

        /// Acquires the next swapchain image for Impeller to draw into.
        ///
        /// The returned handle stays valid until [`Self::present_image`] is
        /// called; the broker keeps the underlying `SurfaceTexture` alive in
        /// the meantime. Only one frame may be in flight at a time.
        pub fn acquire_image(
            &self,
            requested_width: u32,
            requested_height: u32,
        ) -> Option<AcquiredImage> {
            let mut state = self.surface_state.lock();
            if state.suspended || state.pending_frame.is_some() {
                return None;
            }
            let presentable = self.presentable.read();
            // The dimensions Flutter passes here belong to the layer tree that
            // Impeller is about to render. A newer winit resize may already be
            // queued, but applying that newer size would combine a swapchain
            // color image with depth/stencil attachments from this older
            // layer-tree generation. Configure this acquire to the requested
            // generation and retain a newer deferred size for the next frame.
            let deferred_matches_request =
                state
                    .deferred_configuration
                    .as_ref()
                    .is_some_and(|configuration| {
                        configuration.width == requested_width
                            && configuration.height == requested_height
                    });
            let configuration_changed = state.configuration.as_ref().is_none_or(|configuration| {
                configuration.width != requested_width || configuration.height != requested_height
            });
            if configuration_changed {
                let mut configuration = if deferred_matches_request {
                    state.deferred_configuration.take()?
                } else {
                    state.configuration.clone()?
                };
                configuration.width = requested_width;
                configuration.height = requested_height;
                while let Some(retired) = state.retired_frames.pop_front() {
                    if !self.wait_and_destroy(retired) {
                        return None;
                    }
                }
                presentable
                    .surface
                    .configure(&self.context.device, &configuration);
                state.configuration = Some(configuration);
            } else if deferred_matches_request {
                // A matching deferred request has now reached its layer-tree
                // generation; the existing swapchain already has that size.
                state.deferred_configuration = None;
            }
            // Three pairs cover the configured two-frame surface latency plus
            // the frame being acquired. Recycle the oldest pair only after its
            // consuming submission has completed.
            if state.retired_frames.len() >= 3 {
                let retired = state.retired_frames.pop_front()?;
                if !self.wait_and_destroy(retired) {
                    return None;
                }
            }
            let configuration = state.configuration.clone()?;
            let format = configuration.format;
            let vk_format = vulkan_format(format)?;
            let (surface_texture, suboptimal) = match presentable.surface.get_current_texture() {
                wgpu::CurrentSurfaceTexture::Success(texture) => (texture, false),
                wgpu::CurrentSurfaceTexture::Suboptimal(texture) => (texture, true),
                wgpu::CurrentSurfaceTexture::Outdated => {
                    presentable
                        .surface
                        .configure(&self.context.device, &configuration);
                    match presentable.surface.get_current_texture() {
                        wgpu::CurrentSurfaceTexture::Success(texture) => (texture, false),
                        wgpu::CurrentSurfaceTexture::Suboptimal(texture) => (texture, true),
                        _ => return None,
                    }
                }
                _ => return None,
            };
            if surface_texture.texture.width() != requested_width
                || surface_texture.texture.height() != requested_height
            {
                return None;
            }
            if suboptimal && state.deferred_configuration.is_none() {
                state.deferred_configuration = Some(configuration);
            }
            // SAFETY: the returned guard is dropped immediately after copying
            // the raw handle; the image itself outlives it in `pending_frame`.
            let image = unsafe {
                let guard = surface_texture.texture.as_hal::<wgpu::hal::vulkan::Api>()?;
                guard.raw_handle()
            };
            let sync = self.create_frame_sync()?;
            // Register a real wgpu write to the acquired image before handing
            // its raw handle to Impeller. This makes wgpu's submission wait on
            // the swapchain acquire semaphore and marks the texture initialized;
            // otherwise Queue::present clears the image because Impeller's raw
            // Vulkan commands are invisible to wgpu's resource tracker.
            let view = surface_texture
                .texture
                .create_view(&wgpu::TextureViewDescriptor::default());
            let mut encoder =
                self.context
                    .device
                    .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                        label: Some("Flutter Rust Shell acquire barrier"),
                    });
            {
                let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("Flutter Rust Shell acquire barrier"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &view,
                        depth_slice: None,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT),
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    ..Default::default()
                });
            }
            // Make the acquire-complete semaphore part of the same wgpu
            // submission that consumes the swapchain's private acquire
            // semaphore. Impeller waits on this before its first image use.
            let Some(queue) = (unsafe { self.context.queue.as_hal::<wgpu::hal::vulkan::Api>() })
            else {
                self.destroy_frame_sync(sync);
                return None;
            };
            queue.add_signal_semaphore(sync.acquire, None);
            self.context.queue.submit([encoder.finish()]);
            state.pending_frame = Some(PendingFrame {
                texture: surface_texture,
                sync,
            });
            Some(AcquiredImage {
                image: image.as_raw(),
                format: vk_format.as_raw() as u32,
                acquire_semaphore: sync.acquire.as_raw(),
                render_semaphore: sync.render.as_raw(),
            })
        }

        /// Presents the frame most recently returned by [`Self::acquire_image`].
        ///
        pub fn present_image(&self) -> bool {
            let mut state = self.surface_state.lock();
            let Some(pending) = state.pending_frame.take() else {
                return false;
            };
            if state.suspended {
                // The native surface this frame was acquired against is
                // already gone (e.g. Android destroyed the window before
                // Impeller finished this frame); presenting would touch a
                // dead swapchain. Drop the frame instead of submitting it.
                self.destroy_frame_sync(pending.sync);
                return false;
            }
            let Some(queue) = (unsafe { self.context.queue.as_hal::<wgpu::hal::vulkan::Api>() })
            else {
                return false;
            };
            // Impeller signals `render` after its final layout transition. Make
            // a real wgpu submission wait on it and touch the surface texture,
            // so wgpu's own presentation semaphore is signalled only after all
            // Impeller work is complete.
            let view = pending
                .texture
                .texture
                .create_view(&wgpu::TextureViewDescriptor::default());
            let mut encoder =
                self.context
                    .device
                    .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                        label: Some("Flutter Rust Shell present handoff"),
                    });
            {
                let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("Flutter Rust Shell present handoff"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &view,
                        depth_slice: None,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Load,
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    ..Default::default()
                });
            }
            queue.add_wait_semaphore(
                pending.sync.render,
                None,
                ash::vk::PipelineStageFlags::COLOR_ATTACHMENT_OUTPUT,
            );
            let submission = self.context.queue.submit([encoder.finish()]);
            // Wayland frame callbacks must only be armed when a surface commit
            // is guaranteed. Doing this at the earlier vsync pulse can freeze
            // redraw delivery when Flutter requested a secondary vsync that
            // intentionally produced no frame.
            self.presentable.read().window.pre_present_notify();
            self.context.queue.present(pending.texture);
            if let (Some(stats), Some(configuration)) =
                (&self.presentation_stats, &state.configuration)
            {
                stats
                    .lock()
                    .record(configuration.width, configuration.height);
            }
            state.retired_frames.push_back(RetiredFrame {
                submission,
                sync: pending.sync,
            });
            true
        }

        /// A presentation callback table whose `user_data` is this broker's
        /// address. The broker must outlive every use of the returned table.
        pub fn presentation_callbacks(&self) -> FlutterRustVulkanPresentationCallbacks {
            FlutterRustVulkanPresentationCallbacks {
                user_data: (self as *const Self).cast_mut().cast::<c_void>(),
                acquire_image: Some(acquire_image_callback),
                present_image: Some(present_image_callback),
            }
        }
    }

    impl Drop for GpuBroker {
        fn drop(&mut self) {
            // SAFETY: no callback can enter the broker during `drop`.
            let mut state = self.surface_state.lock();
            self.destroy_all_frames(&mut state);
        }
    }

    extern "C" fn acquire_external_texture_frame(
        user_data: *mut c_void,
        _requested_width: u32,
        _requested_height: u32,
        out_frame: *mut FlutterRustExternalTextureFrame,
    ) -> i32 {
        if user_data.is_null() || out_frame.is_null() {
            return 0;
        }
        // SAFETY: callbacks() points at a boxed ring retained by the host, and
        // the C++ bridge supplies a writable output for this call.
        let ring = unsafe { &*user_data.cast::<WgpuTextureRing>() };
        let has_ready = !ring.inner.state.lock().ready.is_empty();
        if !has_ready {
            ring.render_pending_clear();
        }
        let mut state = ring.inner.state.lock();
        let Some(index) = state.ready.pop_front() else {
            return 0;
        };
        let slot = &mut state.slots[index];
        if slot.state != TextureSlotState::Ready {
            return 0;
        }
        let task = slot.render_task.take();
        if task.is_none() && !slot.pixels_written {
            slot.state = TextureSlotState::Available;
            drop(state);
            ring.inner.return_available(index);
            return 0;
        }
        let mut encoder =
            ring.inner
                .context
                .device
                .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                    label: Some("Flutter Rust external texture producer"),
                });
        if let Some(task) = task {
            task(&ring.inner.context.device, &mut encoder, &slot.view);
        } else {
            ring.inner.context.queue.write_texture(
                wgpu::TexelCopyTextureInfo {
                    texture: &slot.texture,
                    mip_level: 0,
                    origin: wgpu::Origin3d::ZERO,
                    aspect: wgpu::TextureAspect::All,
                },
                &slot.pixels,
                wgpu::TexelCopyBufferLayout {
                    offset: 0,
                    bytes_per_row: Some(ring.inner.width * 4),
                    rows_per_image: Some(ring.inner.height),
                },
                wgpu::Extent3d {
                    width: ring.inner.width,
                    height: ring.inner.height,
                    depth_or_array_layers: 1,
                },
            );
            slot.pixels_written = false;
        }
        encoder.transition_resources(
            std::iter::empty(),
            std::iter::once(wgpu::TextureTransition {
                texture: &slot.texture,
                selector: None,
                state: wgpu::TextureUses::RESOURCE,
            }),
        );
        let Some(queue) = (unsafe { ring.inner.context.queue.as_hal::<wgpu::hal::vulkan::Api>() })
        else {
            slot.state = TextureSlotState::Available;
            drop(state);
            ring.inner.return_available(index);
            return 0;
        };
        if slot.wait_for_flutter {
            queue.add_wait_semaphore(
                slot.sync.render,
                None,
                ash::vk::PipelineStageFlags::ALL_COMMANDS,
            );
            slot.wait_for_flutter = false;
        }
        queue.add_signal_semaphore(slot.sync.acquire, None);
        ring.inner.context.queue.submit([encoder.finish()]);
        slot.state = TextureSlotState::InFlutter;
        let frame = FlutterRustExternalTextureFrame {
            image: slot.image.as_raw(),
            image_view: slot.image_view.as_raw(),
            format: ash::vk::Format::R8G8B8A8_UNORM.as_raw() as u32,
            width: ring.inner.width,
            height: ring.inner.height,
            acquire_semaphore: slot.sync.acquire.as_raw(),
            render_semaphore: slot.sync.render.as_raw(),
        };
        unsafe { *out_frame = frame };
        1
    }

    extern "C" fn release_external_texture_frame(
        user_data: *mut c_void,
        frame: FlutterRustExternalTextureFrame,
    ) {
        if user_data.is_null() {
            return;
        }
        // SAFETY: see acquire_external_texture_frame.
        let ring = unsafe { &*user_data.cast::<WgpuTextureRing>() };
        let mut state = ring.inner.state.lock();
        let Some((index, slot)) = state
            .slots
            .iter_mut()
            .enumerate()
            .find(|(_, slot)| slot.image.as_raw() == frame.image)
        else {
            return;
        };
        if slot.state == TextureSlotState::InFlutter {
            slot.state = TextureSlotState::Available;
            slot.wait_for_flutter = true;
            drop(state);
            ring.inner.return_available(index);
        }
    }

    extern "C" fn acquire_image_callback(
        user_data: *mut c_void,
        width: u32,
        height: u32,
        out_image: *mut FlutterRustVulkanImage,
    ) -> i32 {
        // SAFETY: presentation_callbacks() sets user_data to a GpuBroker
        // address that outlives every call through this callback table.
        let broker = unsafe { &*user_data.cast::<GpuBroker>() };
        match broker.acquire_image(width, height) {
            Some(image) => {
                // SAFETY: the C++ caller supplies a valid output pointer for
                // the duration of this call.
                unsafe {
                    *out_image = FlutterRustVulkanImage {
                        image: image.image,
                        format: image.format,
                        acquire_semaphore: image.acquire_semaphore,
                        render_semaphore: image.render_semaphore,
                    };
                }
                1
            }
            None => 0,
        }
    }

    extern "C" fn present_image_callback(
        user_data: *mut c_void,
        _image: FlutterRustVulkanImage,
    ) -> i32 {
        // SAFETY: see acquire_image_callback.
        let broker = unsafe { &*user_data.cast::<GpuBroker>() };
        i32::from(broker.present_image())
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn context_values_are_plain_owned_data() {
            let context = VulkanContextData {
                get_instance_proc_addr: 1,
                instance: 2,
                physical_device: 3,
                device: 4,
                queue: 5,
                queue_family_index: 6,
                instance_extensions: vec!["VK_KHR_surface".to_owned()],
                device_extensions: vec!["VK_KHR_swapchain".to_owned()],
            };
            assert_eq!(context.queue_family_index, 6);
            assert_eq!(context.instance_extensions.len(), 1);
        }

        #[test]
        fn available_slots_apply_backpressure_and_reuse_returns() {
            let slots = AvailableSlots::new(3);
            assert_eq!(slots.try_take(), Ok(0));
            assert_eq!(slots.try_take(), Ok(1));
            assert_eq!(slots.try_take(), Ok(2));
            assert_eq!(slots.try_take(), Err(PluginError::Busy));
            slots.give_back(1);
            assert_eq!(slots.try_take(), Ok(1));
        }

        #[test]
        fn shutdown_wakes_an_async_slot_waiter() {
            let slots = Arc::new(AvailableSlots::new(1));
            assert_eq!(slots.try_take(), Ok(0));
            let waiter_slots = Arc::clone(&slots);
            let waiter = std::thread::spawn(move || pollster::block_on(waiter_slots.take()));

            slots.shutdown();

            assert_eq!(
                waiter.join().expect("slot waiter panicked"),
                Err(PluginError::Shutdown)
            );
            slots.give_back(0);
            assert_eq!(slots.try_take(), Err(PluginError::Shutdown));
        }
    }
}

#[cfg(any(target_os = "linux", target_os = "android"))]
pub use vulkan::{GpuBroker, GpuContext, VulkanContextData, WgpuTextureRing};
