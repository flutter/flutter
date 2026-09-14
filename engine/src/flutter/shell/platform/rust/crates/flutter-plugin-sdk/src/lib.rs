//! Public, semantically versioned Rust API for Flutter Rust-shell plugins.
//!
//! The SDK deliberately exposes no Flutter C++ or Impeller types. Those remain
//! behind the private, lockstep engine bridge.

#![forbid(unsafe_code)]

use std::{
    sync::{
        Arc,
        atomic::{AtomicU8, Ordering},
    },
    thread::ThreadId,
};

/// The source compatibility version of this SDK.
pub const PLUGIN_SDK_API_VERSION: u32 = 1;

/// GPU API types pinned to the version used by the Rust shell.
///
/// Plugins must use this re-export for values passed through SDK callbacks.
pub mod gpu {
    pub use wgpu;
}

/// Errors returned while registering a Rust-shell plugin.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PluginError {
    /// The plugin requires an SDK capability not provided by this shell build.
    Unsupported,
    /// A texture descriptor has zero or unsupported dimensions or format.
    InvalidDescriptor,
    /// Every ring slot is currently reserved, ready, or used by Flutter.
    Busy,
    /// The reserved frame has not recorded any commands yet.
    NoFrame,
    /// The texture or shell is shutting down.
    Shutdown,
}

/// A convenient result type for plugin registration.
pub type Result<T> = core::result::Result<T, PluginError>;

/// Pixel formats accepted by engine-owned GPU textures.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TextureFormat {
    /// Eight-bit linear red, green, blue, and alpha channels.
    Rgba8Unorm,
}

/// Size and format of an engine-owned GPU texture.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TextureDescriptor {
    /// Width in physical pixels.
    pub width: u32,
    /// Height in physical pixels.
    pub height: u32,
    /// Storage and sampling format.
    pub format: TextureFormat,
}

impl TextureDescriptor {
    fn is_valid(self) -> bool {
        self.width > 0 && self.height > 0
    }
}

/// One producer callback that records wgpu commands for an engine-owned slot.
#[doc(hidden)]
pub type WgpuRenderTask =
    Box<dyn FnOnce(&wgpu::Device, &mut wgpu::CommandEncoder, &wgpu::TextureView) + Send + 'static>;

/// Private runtime implementation behind a public [`WgpuTexture`].
#[doc(hidden)]
#[async_trait::async_trait]
pub trait WgpuTextureBackendHandle: Send + Sync {
    /// Flutter texture-registry identifier.
    fn texture_id(&self) -> i64;
    /// Attempts to reserve one ring slot without blocking.
    fn try_next_frame(&self) -> Result<Arc<dyn WgpuTextureFrameBackend>>;
    /// Asynchronously waits until one ring slot can be reserved.
    async fn next_frame(&self) -> Result<Arc<dyn WgpuTextureFrameBackend>>;
}

/// Private runtime implementation behind one reserved [`WgpuTextureFrame`].
#[doc(hidden)]
pub trait WgpuTextureFrameBackend: Send + Sync {
    /// Records commands without submitting to the shared Vulkan queue.
    fn render(&self, task: WgpuRenderTask) -> Result<()>;
    /// Publishes the recorded slot and marks the Flutter texture dirty.
    fn present(&self) -> Result<()>;
}

/// One producer callback that writes directly into shell-owned pixel memory.
#[doc(hidden)]
pub type PixelWriteTask = Box<dyn FnOnce(&mut [u8], usize) + Send + 'static>;

/// Private runtime implementation behind a public [`PixelBufferTexture`].
#[doc(hidden)]
#[async_trait::async_trait]
pub trait PixelBufferTextureBackendHandle: Send + Sync {
    /// Flutter texture-registry identifier.
    fn texture_id(&self) -> i64;
    /// Attempts to reserve one shell-owned pixel buffer without blocking.
    fn try_next_frame(&self) -> Result<Arc<dyn PixelBufferTextureFrameBackend>>;
    /// Asynchronously waits until one shell-owned pixel buffer is available.
    async fn next_frame(&self) -> Result<Arc<dyn PixelBufferTextureFrameBackend>>;
}

/// Private runtime implementation behind one reserved pixel-buffer frame.
#[doc(hidden)]
pub trait PixelBufferTextureFrameBackend: Send + Sync {
    /// Lets the producer write directly into shell-owned memory.
    fn write_pixels(&self, task: PixelWriteTask) -> Result<()>;
    /// Publishes the written slot and marks the Flutter texture dirty.
    fn present(&self) -> Result<()>;
}

/// Private runtime factory installed into [`PluginRegistrar`].
#[doc(hidden)]
pub trait WgpuTextureBackend: Send + Sync {
    /// Creates one engine-owned texture.
    fn create_texture(
        &self,
        descriptor: TextureDescriptor,
    ) -> Result<Arc<dyn WgpuTextureBackendHandle>>;
    /// Creates one CPU-produced texture backed by shell-owned upload buffers.
    fn create_pixel_buffer_texture(
        &self,
        descriptor: TextureDescriptor,
    ) -> Result<Arc<dyn PixelBufferTextureBackendHandle>>;
}

/// GPU texture creation capability exposed by the plugin registrar.
#[derive(Clone)]
pub struct GpuTextures {
    backend: Arc<dyn WgpuTextureBackend>,
}

impl GpuTextures {
    /// Creates a texture whose storage and synchronization are owned by the
    /// shell. The returned ID can be passed directly to Dart's `Texture` widget.
    pub fn create_texture(&self, descriptor: TextureDescriptor) -> Result<WgpuTexture> {
        if !descriptor.is_valid() {
            return Err(PluginError::InvalidDescriptor);
        }
        Ok(WgpuTexture {
            backend: self.backend.create_texture(descriptor)?,
        })
    }

    /// Creates a CPU-produced texture. Producers write directly into reusable
    /// shell-owned buffers, avoiding a plugin-to-shell pixel copy.
    pub fn create_pixel_buffer_texture(
        &self,
        descriptor: TextureDescriptor,
    ) -> Result<PixelBufferTexture> {
        if !descriptor.is_valid() {
            return Err(PluginError::InvalidDescriptor);
        }
        Ok(PixelBufferTexture {
            backend: self.backend.create_pixel_buffer_texture(descriptor)?,
        })
    }

    /// Constructs the capability from the private shell runtime.
    #[doc(hidden)]
    pub fn for_shell(backend: Arc<dyn WgpuTextureBackend>) -> Self {
        Self { backend }
    }
}

/// Safe CPU producer handle backed by shell-owned pixel buffers.
pub struct PixelBufferTexture {
    backend: Arc<dyn PixelBufferTextureBackendHandle>,
}

impl PixelBufferTexture {
    /// Identifier consumed by Flutter's Dart `Texture` widget.
    pub fn texture_id(&self) -> i64 {
        self.backend.texture_id()
    }

    /// Attempts to reserve a writable pixel buffer without blocking.
    pub fn try_next_frame(&self) -> Result<PixelBufferTextureFrame> {
        Ok(PixelBufferTextureFrame::new(self.backend.try_next_frame()?))
    }

    /// Waits asynchronously for a writable pixel buffer.
    pub async fn next_frame(&self) -> Result<PixelBufferTextureFrame> {
        self.backend
            .next_frame()
            .await
            .map(PixelBufferTextureFrame::new)
    }
}

/// Exclusive reservation of one shell-owned CPU pixel buffer.
pub struct PixelBufferTextureFrame {
    backend: Arc<dyn PixelBufferTextureFrameBackend>,
    written: bool,
}

impl PixelBufferTextureFrame {
    fn new(backend: Arc<dyn PixelBufferTextureFrameBackend>) -> Self {
        Self {
            backend,
            written: false,
        }
    }

    /// Invokes `writer` with tightly packed RGBA8 storage and its row stride.
    /// The slice belongs to the shell and is reused after Flutter releases the
    /// frame; plugin code must not retain references into it.
    pub fn write_pixels(
        &mut self,
        writer: impl FnOnce(&mut [u8], usize) + Send + 'static,
    ) -> Result<()> {
        if self.written {
            return Err(PluginError::Busy);
        }
        self.backend.write_pixels(Box::new(writer))?;
        self.written = true;
        Ok(())
    }

    /// Publishes this buffer and schedules Flutter to repaint its texture.
    pub fn present(self) -> Result<()> {
        if !self.written {
            return Err(PluginError::NoFrame);
        }
        self.backend.present()
    }
}

/// Safe producer handle for an engine-owned wgpu texture ring.
pub struct WgpuTexture {
    backend: Arc<dyn WgpuTextureBackendHandle>,
}

impl WgpuTexture {
    /// Identifier consumed by Flutter's Dart `Texture` widget.
    pub fn texture_id(&self) -> i64 {
        self.backend.texture_id()
    }

    /// Attempts to reserve an available ring slot without blocking.
    pub fn try_next_frame(&self) -> Result<WgpuTextureFrame> {
        Ok(WgpuTextureFrame::new(self.backend.try_next_frame()?))
    }

    /// Asynchronously waits until a ring slot can be reserved.
    /// Dropping the future cancels the wait without reserving a slot.
    pub async fn next_frame(&self) -> Result<WgpuTextureFrame> {
        self.backend.next_frame().await.map(WgpuTextureFrame::new)
    }
}

/// Exclusive reservation of one engine-owned texture-ring slot.
pub struct WgpuTextureFrame {
    backend: Arc<dyn WgpuTextureFrameBackend>,
    rendered: bool,
}

impl WgpuTextureFrame {
    fn new(backend: Arc<dyn WgpuTextureFrameBackend>) -> Self {
        Self {
            backend,
            rendered: false,
        }
    }

    /// Records commands into this frame. A frame may be recorded once.
    pub fn render(
        &mut self,
        task: impl FnOnce(&wgpu::Device, &mut wgpu::CommandEncoder, &wgpu::TextureView) + Send + 'static,
    ) -> Result<()> {
        if self.rendered {
            return Err(PluginError::Busy);
        }
        self.backend.render(Box::new(task))?;
        self.rendered = true;
        Ok(())
    }

    /// Publishes this slot and schedules Flutter to repaint its existing
    /// texture layer. Consuming `self` prevents repeated publication.
    pub fn present(self) -> Result<()> {
        if !self.rendered {
            return Err(PluginError::NoFrame);
        }
        self.backend.present()
    }
}

/// A unit of work that is safe to transfer to the shell's main thread.
#[doc(hidden)]
pub type MainThreadTask = Box<dyn FnOnce() + Send + 'static>;

/// Error returned when work can no longer be posted to the main thread.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DispatchError {
    /// The shell has not completed initialization yet.
    NotReady,
    /// The application is shutting down and no longer accepts callbacks.
    Shutdown,
}

const DISPATCHER_STARTING: u8 = 0;
const DISPATCHER_RUNNING: u8 = 1;
const DISPATCHER_SHUTDOWN: u8 = 2;

/// Worker-safe handle for posting short operations to Flutter's main thread.
///
/// Dispatch is always asynchronous, including when called from the main
/// thread. This prevents a callback from unexpectedly re-entering Dart or
/// mutable platform state in the middle of an FFI call.
#[derive(Clone)]
pub struct MainThreadDispatcher {
    post: Arc<dyn Fn(MainThreadTask) -> bool + Send + Sync>,
    main_thread: ThreadId,
    state: Arc<AtomicU8>,
}

impl MainThreadDispatcher {
    /// Posts `task` for a later turn of the main event loop.
    pub fn dispatch(
        &self,
        task: impl FnOnce() + Send + 'static,
    ) -> core::result::Result<(), DispatchError> {
        match self.state.load(Ordering::Acquire) {
            DISPATCHER_STARTING => return Err(DispatchError::NotReady),
            DISPATCHER_SHUTDOWN => return Err(DispatchError::Shutdown),
            DISPATCHER_RUNNING => {}
            _ => unreachable!("invalid main-thread dispatcher state"),
        }
        let state = Arc::clone(&self.state);
        let guarded_task = Box::new(move || {
            if state.load(Ordering::Acquire) == DISPATCHER_RUNNING {
                task();
            }
        });
        if !(self.post)(guarded_task) {
            return Err(DispatchError::Shutdown);
        }
        Ok(())
    }

    /// Whether the caller is currently running on the owning main thread.
    pub fn is_main_thread(&self) -> bool {
        std::thread::current().id() == self.main_thread
    }

    /// Creates a dispatcher backed by the private shell runtime.
    #[doc(hidden)]
    pub fn for_shell(
        post: impl Fn(MainThreadTask) -> bool + Send + Sync + 'static,
        main_thread: ThreadId,
    ) -> Self {
        Self::for_shell_with_state(post, main_thread, DISPATCHER_RUNNING)
    }

    /// Creates a dispatcher that rejects work until shell startup completes.
    #[doc(hidden)]
    pub fn for_shell_inactive(
        post: impl Fn(MainThreadTask) -> bool + Send + Sync + 'static,
        main_thread: ThreadId,
    ) -> Self {
        Self::for_shell_with_state(post, main_thread, DISPATCHER_STARTING)
    }

    fn for_shell_with_state(
        post: impl Fn(MainThreadTask) -> bool + Send + Sync + 'static,
        main_thread: ThreadId,
        state: u8,
    ) -> Self {
        Self {
            post: Arc::new(post),
            main_thread,
            state: Arc::new(AtomicU8::new(state)),
        }
    }

    /// Enables dispatch after the shell and its implicit view are initialized.
    #[doc(hidden)]
    pub fn start_for_shell(&self) -> bool {
        self.state
            .compare_exchange(
                DISPATCHER_STARTING,
                DISPATCHER_RUNNING,
                Ordering::AcqRel,
                Ordering::Acquire,
            )
            .is_ok()
    }

    /// Stops this dispatcher and every clone from accepting new work.
    #[doc(hidden)]
    pub fn shutdown_for_shell(&self) {
        self.state.store(DISPATCHER_SHUTDOWN, Ordering::Release);
    }
}

/// The shell-owned registration context passed to every plugin.
///
/// Capabilities are added here as the shell implements them. Keeping this type
/// opaque prevents plugins from depending on private engine handles.
pub struct PluginRegistrar {
    main_thread_dispatcher: MainThreadDispatcher,
    gpu_textures: Option<GpuTextures>,
}

impl PluginRegistrar {
    /// Creates the registrar used by the shell during application startup.
    ///
    /// This is public only so the private shell runtime can construct the
    /// registrar across crate boundaries; plugin code should only receive it
    /// from [`FlutterRustPlugin::register`].
    #[doc(hidden)]
    pub fn for_shell(main_thread_dispatcher: MainThreadDispatcher) -> Self {
        Self {
            main_thread_dispatcher,
            gpu_textures: None,
        }
    }

    /// Returns the dispatcher for main-thread-only platform operations.
    pub fn main_thread_dispatcher(&self) -> &MainThreadDispatcher {
        &self.main_thread_dispatcher
    }

    /// Returns the engine-owned wgpu texture capability.
    pub fn gpu(&self) -> Result<&GpuTextures> {
        self.gpu_textures.as_ref().ok_or(PluginError::Unsupported)
    }

    /// Installs the shell's GPU backend after its engine and implicit view are
    /// ready. Plugin code must not call this method.
    #[doc(hidden)]
    pub fn install_gpu_for_shell(&mut self, gpu_textures: GpuTextures) -> bool {
        if self.gpu_textures.is_some() {
            return false;
        }
        self.gpu_textures = Some(gpu_textures);
        true
    }
}

/// A source-linked plugin compiled into the application's Rust aggregate.
pub trait FlutterRustPlugin: Send + Sync + 'static {
    /// Registers the plugin's platform services, FRB APIs, and textures.
    fn register(&self, registrar: &mut PluginRegistrar) -> Result<()>;
}

#[cfg(test)]
#[path = "../tests/unit/sdk.rs"]
mod tests;
