/*
 * Copyright 2021 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/async-testing/test_loop.h>

#include "fake_provider.h"
#include "gtest/gtest.h"
#include "txt/platform.h"

namespace txt {

class PlatformFuchsiaTest : public ::testing::Test {
 protected:
  PlatformFuchsiaTest() : loop_(&kAsyncLoopConfigNoAttachToCurrentThread) {
    loop_.StartThread();
  }

  async::Loop& loop() { return loop_; }

  FakeProvider& fake_provider() { return fake_provider_; }

  fidl::InterfaceHandle<fuchsia::fonts::Provider> GetProvider() {
    return fake_provider_.Bind(loop_.dispatcher());
  }

  void TearDown() override {
    loop_.Quit();
    loop_.JoinThreads();
  }

 private:
  async::Loop loop_;  // Must come before FIDL bindings.
  FakeProvider fake_provider_;
};

TEST_F(PlatformFuchsiaTest, GetDefaultFontManager) {
  zx_handle_t handle = GetProvider().TakeChannel().release();
  auto font_manager = GetDefaultFontManager(handle);

  // Nonnull font initialization data should not create SkFontMgr::RefDefault().
  EXPECT_NE(font_manager, SkFontMgr::RefDefault());

  // Check to see that our font provider was called.
  EXPECT_FALSE(fake_provider().WasInvoked());
  font_manager->matchFamily("Invalid font.");
  EXPECT_TRUE(fake_provider().WasInvoked());
}

TEST_F(PlatformFuchsiaTest, GetDefaultFontManagerFail) {
  // Null font initialization data should create SkFontMgr::RefDefault().
  EXPECT_EQ(GetDefaultFontManager(0), SkFontMgr::RefDefault());
}

}  // namespace txt
