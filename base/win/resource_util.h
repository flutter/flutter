// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains utility functions for accessing resources in external
// files (DLLs) or embedded in the executable itself.

#ifndef BASE_WIN_RESOURCE_UTIL_H_
#define BASE_WIN_RESOURCE_UTIL_H_

#include <windows.h>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace win {

// Function for getting a data resource of the specified |resource_type| from
// a dll.  Some resources are optional, especially in unit tests, so this
// returns false but doesn't raise an error if the resource can't be loaded.
bool BASE_EXPORT GetResourceFromModule(HMODULE module,
                                       int resource_id,
                                       LPCTSTR resource_type,
                                       void** data,
                                       size_t* length);

// Function for getting a data resource (BINDATA) from a dll.  Some
// resources are optional, especially in unit tests, so this returns false
// but doesn't raise an error if the resource can't be loaded.
bool BASE_EXPORT GetDataResourceFromModule(HMODULE module,
                                           int resource_id,
                                           void** data,
                                           size_t* length);

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_RESOURCE_UTIL_H_
