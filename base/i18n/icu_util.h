// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_ICU_UTIL_H_
#define BASE_I18N_ICU_UTIL_H_

#include "base/files/memory_mapped_file.h"
#include "base/i18n/base_i18n_export.h"
#include "build/build_config.h"

namespace base {
namespace i18n {

#if !defined(OS_NACL)
// Call this function to load ICU's data tables for the current process.  This
// function should be called before ICU is used.
BASE_I18N_EXPORT bool InitializeICU();

#if ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_FILE
// Returns the PlatformFile and Region that was initialized by InitializeICU().
// Use with InitializeICUWithFileDescriptor().
BASE_I18N_EXPORT PlatformFile GetIcuDataFileHandle(
    MemoryMappedFile::Region* out_region);

// Android and html_viewer use a file descriptor passed by browser process to
// initialize ICU in render processes.
BASE_I18N_EXPORT bool InitializeICUWithFileDescriptor(
    PlatformFile data_fd,
    const MemoryMappedFile::Region& data_region);
#endif  // ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_FILE
#endif  // !defined(OS_NACL)

// In a test binary, the call above might occur twice.
BASE_I18N_EXPORT void AllowMultipleInitializeCallsForTesting();

}  // namespace i18n
}  // namespace base

#endif  // BASE_I18N_ICU_UTIL_H_
