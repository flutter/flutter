// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/base/accelerators/accelerator_manager.h"

#include "base/compiler_specific.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event_constants.h"
#include "ui/events/keycodes/keyboard_codes.h"

namespace ui {
namespace test {

namespace {

class TestTarget : public AcceleratorTarget {
 public:
  TestTarget() : accelerator_pressed_count_(0) {}
  ~TestTarget() override {}

  int accelerator_pressed_count() const {
    return accelerator_pressed_count_;
  }

  void set_accelerator_pressed_count(int accelerator_pressed_count) {
    accelerator_pressed_count_ = accelerator_pressed_count;
  }

  // Overridden from AcceleratorTarget:
  bool AcceleratorPressed(const Accelerator& accelerator) override;
  bool CanHandleAccelerators() const override;

 private:
  int accelerator_pressed_count_;

  DISALLOW_COPY_AND_ASSIGN(TestTarget);
};

bool TestTarget::AcceleratorPressed(const Accelerator& accelerator) {
  ++accelerator_pressed_count_;
  return true;
}

bool TestTarget::CanHandleAccelerators() const {
  return true;
}

Accelerator GetAccelerator(KeyboardCode code, int mask) {
  return Accelerator(code, mask);
}

}  // namespace

class AcceleratorManagerTest : public testing::Test {
 public:
  AcceleratorManagerTest() {}
  ~AcceleratorManagerTest() override {}

  AcceleratorManager manager_;
};

TEST_F(AcceleratorManagerTest, Register) {
  const Accelerator accelerator_a(VKEY_A, EF_NONE);
  TestTarget target;
  manager_.Register(accelerator_a, AcceleratorManager::kNormalPriority,
                    &target);

  // The registered accelerator is processed.
  EXPECT_TRUE(manager_.Process(accelerator_a));
  EXPECT_EQ(1, target.accelerator_pressed_count());
}

TEST_F(AcceleratorManagerTest, RegisterMultipleTarget) {
  const Accelerator accelerator_a(VKEY_A, EF_NONE);
  TestTarget target1;
  manager_.Register(accelerator_a, AcceleratorManager::kNormalPriority,
                    &target1);
  TestTarget target2;
  manager_.Register(accelerator_a, AcceleratorManager::kNormalPriority,
                    &target2);

  // If multiple targets are registered with the same accelerator, the target
  // registered later processes the accelerator.
  EXPECT_TRUE(manager_.Process(accelerator_a));
  EXPECT_EQ(0, target1.accelerator_pressed_count());
  EXPECT_EQ(1, target2.accelerator_pressed_count());
}

TEST_F(AcceleratorManagerTest, Unregister) {
  const Accelerator accelerator_a(VKEY_A, EF_NONE);
  TestTarget target;
  manager_.Register(accelerator_a, AcceleratorManager::kNormalPriority,
                    &target);
  const Accelerator accelerator_b(VKEY_B, EF_NONE);
  manager_.Register(accelerator_b, AcceleratorManager::kNormalPriority,
                    &target);

  // Unregistering a different accelerator does not affect the other
  // accelerator.
  manager_.Unregister(accelerator_b, &target);
  EXPECT_TRUE(manager_.Process(accelerator_a));
  EXPECT_EQ(1, target.accelerator_pressed_count());

  // The unregistered accelerator is no longer processed.
  target.set_accelerator_pressed_count(0);
  manager_.Unregister(accelerator_a, &target);
  EXPECT_FALSE(manager_.Process(accelerator_a));
  EXPECT_EQ(0, target.accelerator_pressed_count());
}

TEST_F(AcceleratorManagerTest, UnregisterAll) {
  const Accelerator accelerator_a(VKEY_A, EF_NONE);
  TestTarget target1;
  manager_.Register(accelerator_a, AcceleratorManager::kNormalPriority,
                    &target1);
  const Accelerator accelerator_b(VKEY_B, EF_NONE);
  manager_.Register(accelerator_b, AcceleratorManager::kNormalPriority,
                    &target1);
  const Accelerator accelerator_c(VKEY_C, EF_NONE);
  TestTarget target2;
  manager_.Register(accelerator_c, AcceleratorManager::kNormalPriority,
                    &target2);
  manager_.UnregisterAll(&target1);

  // All the accelerators registered for |target1| are no longer processed.
  EXPECT_FALSE(manager_.Process(accelerator_a));
  EXPECT_FALSE(manager_.Process(accelerator_b));
  EXPECT_EQ(0, target1.accelerator_pressed_count());

  // UnregisterAll with a different target does not affect the other target.
  EXPECT_TRUE(manager_.Process(accelerator_c));
  EXPECT_EQ(1, target2.accelerator_pressed_count());
}

TEST_F(AcceleratorManagerTest, Process) {
  TestTarget target;

  // Test all 2*2*2 cases (shift/control/alt = on/off).
  for (int mask = 0; mask < 2 * 2 * 2; ++mask) {
    Accelerator accelerator(GetAccelerator(VKEY_A, mask));
    const base::string16 text = accelerator.GetShortcutText();
    manager_.Register(accelerator, AcceleratorManager::kNormalPriority,
                      &target);

    // The registered accelerator is processed.
    const int last_count = target.accelerator_pressed_count();
    EXPECT_TRUE(manager_.Process(accelerator)) << text;
    EXPECT_EQ(last_count + 1, target.accelerator_pressed_count()) << text;

    // The non-registered accelerators are not processed.
    accelerator.set_type(ET_UNKNOWN);
    EXPECT_FALSE(manager_.Process(accelerator)) << text;  // different type
    accelerator.set_type(ET_TRANSLATED_KEY_PRESS);
    EXPECT_FALSE(manager_.Process(accelerator)) << text;  // different type
    accelerator.set_type(ET_KEY_RELEASED);
    EXPECT_FALSE(manager_.Process(accelerator)) << text;  // different type
    accelerator.set_type(ET_TRANSLATED_KEY_RELEASE);
    EXPECT_FALSE(manager_.Process(accelerator)) << text;  // different type

    EXPECT_FALSE(manager_.Process(GetAccelerator(VKEY_UNKNOWN, mask)))
        << text;  // different vkey
    EXPECT_FALSE(manager_.Process(GetAccelerator(VKEY_B, mask)))
        << text;  // different vkey
    EXPECT_FALSE(manager_.Process(GetAccelerator(VKEY_SHIFT, mask)))
        << text;  // different vkey

    for (int test_mask = 0; test_mask < 2 * 2 * 2; ++test_mask) {
      if (test_mask == mask)
        continue;
      const Accelerator test_accelerator(GetAccelerator(VKEY_A, test_mask));
      const base::string16 test_text = test_accelerator.GetShortcutText();
      EXPECT_FALSE(manager_.Process(test_accelerator))
          << text << ", " << test_text;  // different modifiers
    }

    EXPECT_EQ(last_count + 1, target.accelerator_pressed_count()) << text;
    manager_.UnregisterAll(&target);
  }
}

}  // namespace test
}  // namespace ui
