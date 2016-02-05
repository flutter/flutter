// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DYLIB_H_
#define SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DYLIB_H_

#include "sky/services/dynamic/dynamic_service_macros.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "mojo/public/cpp/bindings/string.h"

void FlutterServicePerform(mojo::ScopedMessagePipeHandle client_handle,
                           const mojo::String& service_name);

#endif  // SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DYLIB_H_
