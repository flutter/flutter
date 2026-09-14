use super::*;
use parking_lot::Mutex;
use std::collections::VecDeque;

struct FakeGpuBackend {
    operations: Arc<Mutex<Vec<&'static str>>>,
}

struct FakeTextureBackend {
    operations: Arc<Mutex<Vec<&'static str>>>,
}

struct FakeFrameBackend {
    operations: Arc<Mutex<Vec<&'static str>>>,
}

struct FakePixelTextureBackend {
    operations: Arc<Mutex<Vec<&'static str>>>,
}

struct FakePixelFrameBackend {
    operations: Arc<Mutex<Vec<&'static str>>>,
    pixels: Mutex<Vec<u8>>,
}

impl WgpuTextureBackend for FakeGpuBackend {
    fn create_texture(
        &self,
        _descriptor: TextureDescriptor,
    ) -> Result<Arc<dyn WgpuTextureBackendHandle>> {
        self.operations.lock().push("create");
        Ok(Arc::new(FakeTextureBackend {
            operations: Arc::clone(&self.operations),
        }))
    }

    fn create_pixel_buffer_texture(
        &self,
        _descriptor: TextureDescriptor,
    ) -> Result<Arc<dyn PixelBufferTextureBackendHandle>> {
        self.operations.lock().push("create_pixels");
        Ok(Arc::new(FakePixelTextureBackend {
            operations: Arc::clone(&self.operations),
        }))
    }
}

#[async_trait::async_trait]
impl PixelBufferTextureBackendHandle for FakePixelTextureBackend {
    fn texture_id(&self) -> i64 {
        23
    }

    fn try_next_frame(&self) -> Result<Arc<dyn PixelBufferTextureFrameBackend>> {
        self.operations.lock().push("reserve_pixels");
        Ok(Arc::new(FakePixelFrameBackend {
            operations: Arc::clone(&self.operations),
            pixels: Mutex::new(vec![0; 32]),
        }))
    }

    async fn next_frame(&self) -> Result<Arc<dyn PixelBufferTextureFrameBackend>> {
        self.try_next_frame()
    }
}

impl PixelBufferTextureFrameBackend for FakePixelFrameBackend {
    fn write_pixels(&self, task: PixelWriteTask) -> Result<()> {
        self.operations.lock().push("write_pixels");
        task(&mut self.pixels.lock(), 16);
        Ok(())
    }

    fn present(&self) -> Result<()> {
        self.operations.lock().push("present_pixels");
        Ok(())
    }
}

#[async_trait::async_trait]
impl WgpuTextureBackendHandle for FakeTextureBackend {
    fn texture_id(&self) -> i64 {
        17
    }

    fn try_next_frame(&self) -> Result<Arc<dyn WgpuTextureFrameBackend>> {
        self.operations.lock().push("reserve");
        Ok(Arc::new(FakeFrameBackend {
            operations: Arc::clone(&self.operations),
        }))
    }

    async fn next_frame(&self) -> Result<Arc<dyn WgpuTextureFrameBackend>> {
        self.try_next_frame()
    }
}

impl WgpuTextureFrameBackend for FakeFrameBackend {
    fn render(&self, _task: WgpuRenderTask) -> Result<()> {
        self.operations.lock().push("render");
        Ok(())
    }

    fn present(&self) -> Result<()> {
        self.operations.lock().push("present");
        Ok(())
    }
}

struct TestPlugin;

impl FlutterRustPlugin for TestPlugin {
    fn register(&self, _registrar: &mut PluginRegistrar) -> Result<()> {
        Ok(())
    }
}

#[test]
fn plugins_register_with_the_shell_registrar() {
    let queue = Arc::new(Mutex::new(VecDeque::<MainThreadTask>::new()));
    let queue_for_post = Arc::clone(&queue);
    let dispatcher = MainThreadDispatcher::for_shell(
        move |task| {
            queue_for_post.lock().push_back(task);
            true
        },
        std::thread::current().id(),
    );
    let mut registrar = PluginRegistrar::for_shell(dispatcher);
    TestPlugin.register(&mut registrar).unwrap();
}

#[test]
fn gpu_capability_validates_and_hides_the_runtime_backend() {
    let dispatcher = MainThreadDispatcher::for_shell(|_| true, std::thread::current().id());
    let mut registrar = PluginRegistrar::for_shell(dispatcher);
    assert!(matches!(registrar.gpu(), Err(PluginError::Unsupported)));

    let operations = Arc::new(Mutex::new(Vec::new()));
    let capability = GpuTextures::for_shell(Arc::new(FakeGpuBackend {
        operations: Arc::clone(&operations),
    }));
    assert!(registrar.install_gpu_for_shell(capability.clone()));
    assert!(!registrar.install_gpu_for_shell(capability));
    assert!(matches!(
        registrar.gpu().unwrap().create_texture(TextureDescriptor {
            width: 0,
            height: 32,
            format: TextureFormat::Rgba8Unorm,
        }),
        Err(PluginError::InvalidDescriptor)
    ));

    let texture = registrar
        .gpu()
        .unwrap()
        .create_texture(TextureDescriptor {
            width: 64,
            height: 32,
            format: TextureFormat::Rgba8Unorm,
        })
        .unwrap();
    assert_eq!(texture.texture_id(), 17);
    assert!(matches!(
        texture.try_next_frame().unwrap().present(),
        Err(PluginError::NoFrame)
    ));
    let mut frame = texture.try_next_frame().unwrap();
    frame.render(|_, _, _| {}).unwrap();
    assert_eq!(frame.render(|_, _, _| {}), Err(PluginError::Busy));
    frame.present().unwrap();

    assert_eq!(
        *operations.lock(),
        vec!["create", "reserve", "reserve", "render", "present"]
    );
}

#[test]
fn pixel_buffer_frames_write_directly_into_shell_storage() {
    let operations = Arc::new(Mutex::new(Vec::new()));
    let gpu = GpuTextures::for_shell(Arc::new(FakeGpuBackend {
        operations: Arc::clone(&operations),
    }));
    let texture = gpu
        .create_pixel_buffer_texture(TextureDescriptor {
            width: 4,
            height: 2,
            format: TextureFormat::Rgba8Unorm,
        })
        .unwrap();
    assert_eq!(texture.texture_id(), 23);
    assert_eq!(
        texture.try_next_frame().unwrap().present(),
        Err(PluginError::NoFrame)
    );
    let mut frame = texture.try_next_frame().unwrap();
    frame
        .write_pixels(|pixels, row_bytes| {
            assert_eq!(row_bytes, 16);
            assert_eq!(pixels.len(), 32);
            pixels.fill(0x7f);
        })
        .unwrap();
    assert_eq!(frame.write_pixels(|_, _| {}), Err(PluginError::Busy));
    frame.present().unwrap();
    assert_eq!(
        *operations.lock(),
        vec![
            "create_pixels",
            "reserve_pixels",
            "reserve_pixels",
            "write_pixels",
            "present_pixels"
        ]
    );
}

#[test]
fn worker_dispatch_is_deferred_non_reentrant_and_rejects_shutdown() {
    let queue = Arc::new(Mutex::new(VecDeque::<MainThreadTask>::new()));
    let queue_for_post = Arc::clone(&queue);
    let dispatcher = MainThreadDispatcher::for_shell(
        move |task| {
            queue_for_post.lock().push_back(task);
            true
        },
        std::thread::current().id(),
    );
    let order = Arc::new(Mutex::new(Vec::new()));
    let worker_dispatcher = dispatcher.clone();
    let nested_dispatcher = dispatcher.clone();
    let order_in_task = Arc::clone(&order);
    std::thread::spawn(move || {
        assert!(!worker_dispatcher.is_main_thread());
        worker_dispatcher
            .dispatch(move || {
                assert!(nested_dispatcher.is_main_thread());
                order_in_task.lock().push(1);
                let nested_order = Arc::clone(&order_in_task);
                nested_dispatcher
                    .dispatch(move || nested_order.lock().push(2))
                    .unwrap();
            })
            .unwrap();
    })
    .join()
    .unwrap();

    assert!(order.lock().is_empty());
    let first = queue.lock().pop_front().unwrap();
    first();
    assert_eq!(*order.lock(), vec![1]);
    let second = queue.lock().pop_front().unwrap();
    second();
    assert_eq!(*order.lock(), vec![1, 2]);
    assert!(dispatcher.is_main_thread());

    dispatcher.shutdown_for_shell();
    assert_eq!(dispatcher.dispatch(|| {}), Err(DispatchError::Shutdown));
}

#[test]
fn startup_and_shutdown_gate_queued_callbacks_deterministically() {
    for _ in 0..100 {
        let queue = Arc::new(Mutex::new(VecDeque::<MainThreadTask>::new()));
        let queue_for_post = Arc::clone(&queue);
        let dispatcher = MainThreadDispatcher::for_shell_inactive(
            move |task| {
                queue_for_post.lock().push_back(task);
                true
            },
            std::thread::current().id(),
        );
        assert_eq!(dispatcher.dispatch(|| {}), Err(DispatchError::NotReady));
        assert!(queue.lock().is_empty());
        assert!(dispatcher.start_for_shell());
        assert!(!dispatcher.start_for_shell());

        let ran = Arc::new(AtomicU8::new(0));
        let ran_in_task = Arc::clone(&ran);
        dispatcher
            .dispatch(move || ran_in_task.store(1, Ordering::Release))
            .unwrap();
        dispatcher.shutdown_for_shell();
        queue.lock().pop_front().unwrap()();
        assert_eq!(ran.load(Ordering::Acquire), 0);
        assert_eq!(dispatcher.dispatch(|| {}), Err(DispatchError::Shutdown));
    }
}
