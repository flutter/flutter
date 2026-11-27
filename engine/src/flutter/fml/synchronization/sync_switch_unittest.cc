// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/sync_switch.h"

#include <atomic>
#include <memory>
#include <thread>

#include "flutter/fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"

using fml::SyncSwitch;

TEST(SyncSwitchTest, Basic) {
  SyncSwitch sync_switch;
  bool switch_value = false;
  sync_switch.Execute(SyncSwitch::Handlers()
                          .SetIfTrue([&] { switch_value = true; })
                          .SetIfFalse([&] { switch_value = false; }));
  EXPECT_FALSE(switch_value);
  sync_switch.SetSwitch(true);
  sync_switch.Execute(SyncSwitch::Handlers()
                          .SetIfTrue([&] { switch_value = true; })
                          .SetIfFalse([&] { switch_value = false; }));
  EXPECT_TRUE(switch_value);
}

TEST(SyncSwitchTest, NoopIfUndefined) {
  SyncSwitch sync_switch;
  bool switch_value = false;
  sync_switch.Execute(SyncSwitch::Handlers());
  EXPECT_FALSE(switch_value);
}

TEST(SyncSwitchTest, SharedLock) {
  SyncSwitch sync_switch;
  sync_switch.SetSwitch(true);
  bool switch_value1 = false;
  bool switch_value2 = false;

  std::thread thread1([&] {
    sync_switch.Execute(
        SyncSwitch::Handlers()
            .SetIfTrue([&] {
              switch_value1 = true;

              std::thread thread2([&]() {
                sync_switch.Execute(
                    SyncSwitch::Handlers()
                        .SetIfTrue([&] { switch_value2 = true; })
                        .SetIfFalse([&] { switch_value2 = false; }));
              });
              thread2.join();
            })
            .SetIfFalse([&] { switch_value1 = false; }));
  });
  thread1.join();
  EXPECT_TRUE(switch_value1);
  EXPECT_TRUE(switch_value2);
}

TEST(SyncSwitchTest, ObserverCanCallExecuteFromCallback) {
  SyncSwitch sync_switch;
  bool observed_true = false;
  int notifications = 0;

  class ReentrantObserver : public SyncSwitch::Observer {
   public:
    ReentrantObserver(SyncSwitch& sw, bool& observed_true, int& notifications)
        : switch_(sw),
          observed_true_(observed_true),
          notifications_(notifications) {}

    void OnSyncSwitchUpdate(bool /*new_is_disabled*/) override {
      ++notifications_;
      switch_.Execute(SyncSwitch::Handlers()
                          .SetIfTrue([&] { observed_true_ = true; })
                          .SetIfFalse([&] { observed_true_ = false; }));
    }

   private:
    SyncSwitch& switch_;
    bool& observed_true_;
    int& notifications_;
  };

  ReentrantObserver observer(sync_switch, observed_true, notifications);
  sync_switch.AddObserver(&observer);
  sync_switch.SetSwitch(true);
  EXPECT_EQ(notifications, 1);
  EXPECT_TRUE(observed_true);

  sync_switch.SetSwitch(false);
  EXPECT_EQ(notifications, 2);
  EXPECT_FALSE(observed_true);
  sync_switch.RemoveObserver(&observer);
}

TEST(SyncSwitchTest, RemoveObserverBlocksUntilInFlightNotificationCompletes) {
  SyncSwitch sync_switch;
  fml::AutoResetWaitableEvent entered_callback;
  fml::AutoResetWaitableEvent allow_callback_exit;
  fml::AutoResetWaitableEvent remove_started;
  fml::AutoResetWaitableEvent remove_finished;
  std::atomic<bool> callback_completed{false};

  class BlockingObserver : public SyncSwitch::Observer {
   public:
    BlockingObserver(fml::AutoResetWaitableEvent& entered,
                     fml::AutoResetWaitableEvent& allow_exit,
                     std::atomic<bool>& completed)
        : entered_(entered), allow_exit_(allow_exit), completed_(completed) {}

    void OnSyncSwitchUpdate(bool /*new_is_disabled*/) override {
      entered_.Signal();
      allow_exit_.Wait();
      completed_.store(true, std::memory_order_release);
    }

   private:
    fml::AutoResetWaitableEvent& entered_;
    fml::AutoResetWaitableEvent& allow_exit_;
    std::atomic<bool>& completed_;
  };

  BlockingObserver observer(entered_callback, allow_callback_exit,
                            callback_completed);
  sync_switch.AddObserver(&observer);

  std::thread set_thread([&] { sync_switch.SetSwitch(true); });
  entered_callback.Wait();

  std::thread remove_thread([&] {
    remove_started.Signal();
    sync_switch.RemoveObserver(&observer);
    EXPECT_TRUE(callback_completed.load(std::memory_order_acquire));
    remove_finished.Signal();
  });

  remove_started.Wait();
  // RemoveObserver must remain blocked while OnSyncSwitchUpdate is in flight.
  EXPECT_TRUE(
      remove_finished.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(10)));
  EXPECT_FALSE(callback_completed.load(std::memory_order_acquire));

  allow_callback_exit.Signal();
  remove_finished.Wait();

  remove_thread.join();
  set_thread.join();
}

TEST(SyncSwitchTest, ConcurrentSetSwitchAndAddRemoveObserver) {
  SyncSwitch sync_switch;
  fml::ManualResetWaitableEvent toggle_started;
  std::atomic<bool> done{false};
  std::atomic<int> notifications{0};

  class LifetimeCheckedObserver : public SyncSwitch::Observer {
   public:
    LifetimeCheckedObserver(SyncSwitch& sw, std::atomic<int>& notifications)
        : switch_(sw), notifications_(notifications) {}

    ~LifetimeCheckedObserver() override { alive_.store(false); }

    void OnSyncSwitchUpdate(bool /*new_is_disabled*/) override {
      EXPECT_TRUE(alive_.load());
      notifications_.fetch_add(1, std::memory_order_relaxed);
      switch_.Execute(SyncSwitch::Handlers());
    }

   private:
    SyncSwitch& switch_;
    std::atomic<int>& notifications_;
    std::atomic<bool> alive_{true};
  };

  std::thread toggle_thread([&] {
    toggle_started.Signal();
    bool value = false;
    while (!done.load(std::memory_order_relaxed)) {
      value = !value;
      sync_switch.SetSwitch(value);
    }
  });

  std::thread observer_thread([&] {
    toggle_started.Wait();
    for (int i = 0;
         i < 500 ||
         (notifications.load(std::memory_order_relaxed) == 0 && i < 10000);
         ++i) {
      auto observer =
          std::make_unique<LifetimeCheckedObserver>(sync_switch, notifications);
      sync_switch.AddObserver(observer.get());
      sync_switch.Execute(SyncSwitch::Handlers());
      std::this_thread::yield();
      sync_switch.RemoveObserver(observer.get());
      // Destroying immediately after RemoveObserver verifies no in-flight
      // notification can use-after-free the observer.
      observer.reset();
    }
    done.store(true, std::memory_order_relaxed);
  });

  observer_thread.join();
  toggle_thread.join();
  EXPECT_GT(notifications.load(std::memory_order_relaxed), 0);
}
