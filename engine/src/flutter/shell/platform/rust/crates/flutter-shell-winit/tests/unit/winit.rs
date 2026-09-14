use super::*;

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
    fn android_text_input_sync_suppresses_stale_native_echo_until_target_arrives() {
        let mut session = TextInputSession::default();
        session.begin_android_text_input_sync();
        let deadline = session
            .android_text_input_sync_deadline
            .expect("sync should install a deadline");

        assert!(session.suppress_android_text_input_while_syncing(false, Instant::now()));
        assert!(session.suppress_android_text_input_while_syncing(true, Instant::now()));
        assert!(session.android_text_input_sync_deadline.is_none());
        assert!(!session.suppress_android_text_input_while_syncing(false, Instant::now()));

        session.begin_android_text_input_sync();
        assert!(
            !session.suppress_android_text_input_while_syncing(
                false,
                deadline + Duration::from_secs(1),
            )
        );
        assert!(session.android_text_input_sync_deadline.is_none());
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
    fn touch_leave_cancels_an_active_touch_once() {
        let mut pointer = PointerState::new();
        let down = pointer.touch(0, 10.0, 20.0, TouchPhase::Started);
        assert_eq!(down.len(), 1);
        assert_eq!(down[0].phase, FlutterRustPointerPhase::Down as u32);

        let cancelled = pointer.touch_left(0, None);
        assert_eq!(cancelled.len(), 1);
        assert_eq!(cancelled[0].phase, FlutterRustPointerPhase::Cancel as u32);
        assert_eq!(
            (cancelled[0].physical_x, cancelled[0].physical_y),
            (10.0, 20.0)
        );
        assert!(pointer.touch_left(0, None).is_empty());
    }

    #[test]
    fn touch_release_makes_the_following_leave_a_noop() {
        let mut pointer = PointerState::new();
        pointer.touch(0, 10.0, 20.0, TouchPhase::Started);
        let up = pointer.touch(0, 10.0, 20.0, TouchPhase::Ended);
        assert_eq!(up.len(), 1);
        assert_eq!(up[0].phase, FlutterRustPointerPhase::Up as u32);
        assert!(pointer.touch_left(0, None).is_empty());
    }

    #[test]
    fn duplicate_touch_down_closes_the_stale_stream_first() {
        let mut pointer = PointerState::new();
        pointer.touch(0, 10.0, 20.0, TouchPhase::Started);
        let restarted = pointer.touch(0, 30.0, 40.0, TouchPhase::Started);

        assert_eq!(restarted.len(), 2);
        assert_eq!(restarted[0].phase, FlutterRustPointerPhase::Cancel as u32);
        assert_eq!(restarted[1].phase, FlutterRustPointerPhase::Down as u32);
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
