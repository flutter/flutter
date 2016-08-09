// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CONFIG_H_

#include "build/build_config.h"

#if defined(OS_WIN)
#include "third_party/tcmalloc/chromium/src/config_win.h"
#elif defined(OS_ANDROID)
#include "third_party/tcmalloc/chromium/src/config_android.h"
#elif defined(OS_LINUX)
#include "third_party/tcmalloc/chromium/src/config_linux.h"
#elif defined(OS_FREEBSD)
#include "third_party/tcmalloc/chromium/src/config_freebsd.h"
#endif

#endif // CONFIG_H_
