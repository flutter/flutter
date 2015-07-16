// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Unit tests for event trace provider.
#include "base/win/event_trace_provider.h"
#include <new>
#include "testing/gtest/include/gtest/gtest.h"
#include <initguid.h>  // NOLINT - has to be last

namespace {

using base::win::EtwTraceProvider;
using base::win::EtwMofEvent;

// {7F0FD37F-FA3C-4cd6-9242-DF60967A2CB2}
DEFINE_GUID(kTestProvider,
  0x7f0fd37f, 0xfa3c, 0x4cd6, 0x92, 0x42, 0xdf, 0x60, 0x96, 0x7a, 0x2c, 0xb2);

// {7F0FD37F-FA3C-4cd6-9242-DF60967A2CB2}
DEFINE_GUID(kTestEventClass,
  0x7f0fd37f, 0xfa3c, 0x4cd6, 0x92, 0x42, 0xdf, 0x60, 0x96, 0x7a, 0x2c, 0xb2);

}  // namespace

TEST(EtwTraceProviderTest, ToleratesPreCreateInvocations) {
  // Because the trace provider is used in logging, it's important that
  // it be possible to use static provider instances without regard to
  // whether they've been constructed or destructed.
  // The interface of the class is designed to tolerate this usage.
  char buf[sizeof(EtwTraceProvider)] = {0};
  EtwTraceProvider& provider = reinterpret_cast<EtwTraceProvider&>(buf);

  EXPECT_EQ(NULL, provider.registration_handle());
  EXPECT_EQ(NULL, provider.session_handle());
  EXPECT_EQ(0, provider.enable_flags());
  EXPECT_EQ(0, provider.enable_level());

  EXPECT_FALSE(provider.ShouldLog(TRACE_LEVEL_FATAL, 0xfffffff));

  // We expect these not to crash.
  provider.Log(kTestEventClass, 0, TRACE_LEVEL_FATAL, "foo");
  provider.Log(kTestEventClass, 0, TRACE_LEVEL_FATAL, L"foo");

  EtwMofEvent<1> dummy(kTestEventClass, 0, TRACE_LEVEL_FATAL);
  DWORD data = 0;
  dummy.SetField(0, sizeof(data), &data);
  provider.Log(dummy.get());

  // Placement-new the provider into our buffer.
  new (buf) EtwTraceProvider(kTestProvider);

  // Registration is now safe.
  EXPECT_EQ(ERROR_SUCCESS, provider.Register());

  // Destruct the instance, this should unregister it.
  provider.EtwTraceProvider::~EtwTraceProvider();

  // And post-destruction, all of the above should still be safe.
  EXPECT_EQ(NULL, provider.registration_handle());
  EXPECT_EQ(NULL, provider.session_handle());
  EXPECT_EQ(0, provider.enable_flags());
  EXPECT_EQ(0, provider.enable_level());

  EXPECT_FALSE(provider.ShouldLog(TRACE_LEVEL_FATAL, 0xfffffff));

  // We expect these not to crash.
  provider.Log(kTestEventClass, 0, TRACE_LEVEL_FATAL, "foo");
  provider.Log(kTestEventClass, 0, TRACE_LEVEL_FATAL, L"foo");
  provider.Log(dummy.get());
}

TEST(EtwTraceProviderTest, Initialize) {
  EtwTraceProvider provider(kTestProvider);

  EXPECT_EQ(NULL, provider.registration_handle());
  EXPECT_EQ(NULL, provider.session_handle());
  EXPECT_EQ(0, provider.enable_flags());
  EXPECT_EQ(0, provider.enable_level());
}

TEST(EtwTraceProviderTest, Register) {
  EtwTraceProvider provider(kTestProvider);

  ASSERT_EQ(ERROR_SUCCESS, provider.Register());
  EXPECT_NE(NULL, provider.registration_handle());
  ASSERT_EQ(ERROR_SUCCESS, provider.Unregister());
  EXPECT_EQ(NULL, provider.registration_handle());
}

TEST(EtwTraceProviderTest, RegisterWithNoNameFails) {
  EtwTraceProvider provider;

  EXPECT_TRUE(provider.Register() != ERROR_SUCCESS);
}

TEST(EtwTraceProviderTest, Enable) {
  EtwTraceProvider provider(kTestProvider);

  ASSERT_EQ(ERROR_SUCCESS, provider.Register());
  EXPECT_NE(NULL, provider.registration_handle());

  // No session so far.
  EXPECT_EQ(NULL, provider.session_handle());
  EXPECT_EQ(0, provider.enable_flags());
  EXPECT_EQ(0, provider.enable_level());

  ASSERT_EQ(ERROR_SUCCESS, provider.Unregister());
  EXPECT_EQ(NULL, provider.registration_handle());
}
