use super::*;

pub(crate) enum HostEvent {
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
pub(crate) struct PendingPlatformResponse(pub(crate) usize);

#[derive(Clone)]
pub(crate) struct HostEventSender {
    queue: Arc<Mutex<VecDeque<HostEvent>>>,
    proxy: EventLoopProxy,
}

pub(crate) const MAX_HOST_EVENTS_PER_TURN: usize = 64;

impl HostEventSender {
    pub(crate) fn new(proxy: EventLoopProxy) -> Self {
        Self {
            queue: Arc::new(Mutex::new(VecDeque::new())),
            proxy,
        }
    }

    pub(crate) fn send_event(&self, event: HostEvent) -> Result<(), ()> {
        self.queue.lock().push_back(event);
        self.proxy.wake_up();
        Ok(())
    }

    pub(crate) fn drain(&self) -> Vec<HostEvent> {
        let (events, has_more) = drain_host_event_batch(&self.queue);
        if has_more {
            self.proxy.wake_up();
        }
        events
    }
}

pub(crate) fn drain_host_event_batch(queue: &Mutex<VecDeque<HostEvent>>) -> (Vec<HostEvent>, bool) {
    let mut queue = queue.lock();
    let count = queue.len().min(MAX_HOST_EVENTS_PER_TURN);
    let events = queue.drain(..count).collect();
    (events, !queue.is_empty())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ViewOperation {
    Add,
    Remove,
}

pub(crate) struct ViewOperationContext {
    pub(crate) wake_proxy: HostEventSender,
    pub(crate) operation: ViewOperation,
}

pub(crate) struct ActiveWindowingContext {
    pub(crate) event_loop: *const dyn ActiveEventLoop,
    pub(crate) windows: Weak<RefCell<WindowRegistry>>,
}

thread_local! {
    pub(crate) static ACTIVE_WINDOWING_CONTEXT: RefCell<Option<ActiveWindowingContext>> = const {
        RefCell::new(None)
    };
}

pub(crate) fn with_active_windowing_context<T>(
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
