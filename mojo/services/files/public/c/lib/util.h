// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_UTIL_H_
#define SERVICES_FILES_C_LIB_UTIL_H_

#include "files/public/interfaces/types.mojom.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {

// Converts a |mojo::files::Error| to an errno value. (Note that this converts
// |mojo::files::ERROR_OK| to 0, which is not a valid errno value.
int ErrorToErrno(mojo::files::Error error);

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_UTIL_H_
