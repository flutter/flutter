// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atk/atk.h>

#include <string>

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/platform/atk_util_auralinux.h"
#include "ui/accessibility/platform/ax_platform_node_auralinux.h"
#include "ui/accessibility/platform/ax_platform_node_unittest.h"
#include "ui/accessibility/platform/test_ax_node_wrapper.h"

namespace ui {

class AtkUtilAuraLinuxTest : public AXPlatformNodeTest {
 public:
  AtkUtilAuraLinuxTest() {
    AXPlatformNode::NotifyAddAXModeFlags(kAXModeComplete);
    // We need to create a platform node in order to install it as the root
    // ATK node. The ATK bridge will complain if we try to use it without a
    // root node installed.
    AXNodeData root;
    root.id = 1;
    Init(root);

    TestAXNodeWrapper* wrapper =
        TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
    if (!wrapper)
      NOTREACHED();
    AXPlatformNodeAuraLinux::SetApplication(wrapper->ax_platform_node());

    AtkUtilAuraLinux::GetInstance()->InitializeForTesting();
  }

  ~AtkUtilAuraLinuxTest() override {
    TestAXNodeWrapper* wrapper =
        TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
    if (!wrapper)
      NOTREACHED();
    g_object_unref(wrapper->ax_platform_node()->GetNativeViewAccessible());
  }

  AtkUtilAuraLinuxTest(const AtkUtilAuraLinuxTest&) = delete;
  AtkUtilAuraLinuxTest& operator=(const AtkUtilAuraLinuxTest&) = delete;
};

TEST_F(AtkUtilAuraLinuxTest, KeySnooping) {
  AtkKeySnoopFunc key_snoop_func = reinterpret_cast<AtkKeySnoopFunc>(
      +[](AtkKeyEventStruct* key_event, int* keyval_seen) {
        *keyval_seen = key_event->keyval;
      });

  int keyval_seen = 0;
  guint listener_id = atk_add_key_event_listener(key_snoop_func, &keyval_seen);

  AtkKeyEventStruct atk_key_event;
  atk_key_event.type = ATK_KEY_EVENT_PRESS;
  atk_key_event.state = 0;
  atk_key_event.keyval = 55;
  atk_key_event.keycode = 10;
  atk_key_event.timestamp = 10;
  atk_key_event.string = nullptr;
  atk_key_event.length = 0;

  AtkUtilAuraLinux* atk_util = AtkUtilAuraLinux::GetInstance();
  atk_util->HandleAtkKeyEvent(&atk_key_event);
  // AX mode is enabled and Key snooping works.
  EXPECT_EQ(keyval_seen, 55);

  TestAXNodeWrapper* wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
  DCHECK(wrapper);
  AXMode prev_mode = wrapper->ax_platform_node()->ax_mode_;
  // Disables AX mode.
  wrapper->ax_platform_node()->ax_mode_ = 0;
  keyval_seen = 0;
  atk_util->HandleAtkKeyEvent(&atk_key_event);
  // When AX mode is not enabled, Key snooping doesn't work.
  EXPECT_EQ(keyval_seen, 0);

  // Restores the previous AX mode.
  wrapper->ax_platform_node()->ax_mode_ = prev_mode;
  keyval_seen = 0;
  atk_util->HandleAtkKeyEvent(&atk_key_event);
  // AX mode is set again, Key snooping works.
  EXPECT_EQ(keyval_seen, 55);

  atk_remove_key_event_listener(listener_id);

  keyval_seen = 0;
  atk_util->HandleAtkKeyEvent(&atk_key_event);

  EXPECT_EQ(keyval_seen, 0);
}

TEST_F(AtkUtilAuraLinuxTest, AtSpiReady) {
  AtkUtilAuraLinux* atk_util = AtkUtilAuraLinux::GetInstance();

  EXPECT_FALSE(atk_util->IsAtSpiReady());

  // In a normal browser execution, when a key event listener is added it means
  // the AT-SPI bridge has done it as part of its initialization, so it is set
  // as enabled.
  AtkKeySnoopFunc key_snoop_func =
      reinterpret_cast<AtkKeySnoopFunc>(+[](AtkKeyEventStruct* key_event) {});
  atk_add_key_event_listener(key_snoop_func, nullptr);

  EXPECT_TRUE(atk_util->IsAtSpiReady());
}

}  // namespace ui
