// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_RESPONSE_HANDLE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_RESPONSE_HANDLE_H_

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockBinaryMessengerResponseHandle,
                     fl_mock_binary_messenger_response_handle,
                     FL,
                     MOCK_BINARY_MESSENGER_RESPONSE_HANDLE,
                     FlBinaryMessengerResponseHandle)

FlMockBinaryMessengerResponseHandle*
fl_mock_binary_messenger_response_handle_new();

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_RESPONSE_HANDLE_H_
