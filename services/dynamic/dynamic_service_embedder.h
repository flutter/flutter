// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_EMBEDDER_H_
#define FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_EMBEDDER_H_

#include "flutter/services/dynamic/dynamic_service.h"

typedef const struct FlutterServiceVersion* (*FlutterServiceGetVersionProc)(
    void);
typedef void (*FlutterServiceOnLoadProc)(const struct MojoAsyncWaiter*,
                                         const struct MojoLogger*);
typedef void (*FlutterServiceInvokeProc)(MojoHandle, const char*);
typedef void (*FlutterServiceOnUnloadProc)();

FLUTTER_C_API_START

extern const char* const kFlutterServiceGetVersionProcName;
extern const char* const kFlutterServiceOnLoadProcName;
extern const char* const kFlutterServiceInvokeProcName;
extern const char* const kFlutterServiceOnUnloadProcName;

FLUTTER_C_API_END

#endif  // FLUTTER_SERVICES_DYNAMIC_DYNAMIC_SERVICE_EMBEDDER_H_
