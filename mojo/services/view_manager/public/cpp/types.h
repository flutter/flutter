// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_TYPES_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_TYPES_H_

#include <stdint.h>

// Typedefs for the transport types. These typedefs match that of the mojom
// file, see it for specifics.

namespace mojo {

// Used to identify views and change ids.
typedef uint32_t Id;

// Used to identify a connection as well as a connection specific view id. For
// example, the Id for a view consists of the ConnectionSpecificId of the
// connection and the ConnectionSpecificId of the view.
typedef uint16_t ConnectionSpecificId;

}  // namespace mojo

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_TYPES_H_
