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
