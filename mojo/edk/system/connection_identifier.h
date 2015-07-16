// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CONNECTION_IDENTIFIER_H_
#define MOJO_EDK_SYSTEM_CONNECTION_IDENTIFIER_H_

#include "mojo/edk/system/unique_identifier.h"

namespace mojo {
namespace system {

// (Temporary, unique) identifiers for connections (for used with
// |ConnectionManager|s), used as they are being brought up:
using ConnectionIdentifier = UniqueIdentifier;

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CONNECTION_IDENTIFIER_H_
