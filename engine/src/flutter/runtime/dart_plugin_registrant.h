// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DART_PLUGIN_REGISTRANT_H_
#define FLUTTER_DART_PLUGIN_REGISTRANT_H_

#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

/// Looks for the Dart Plugin Registrant in `library_handle` and invokes it if
/// it is found.
/// @return `true` when the registrant has been invoked.
bool InvokeDartPluginRegistrantIfAvailable(Dart_Handle library_handle);

/// @return `true` when the registrant has been invoked.
bool FindAndInvokeDartPluginRegistrant();

}  // namespace flutter

#endif  // FLUTTER_DART_PLUGIN_REGISTRANT_H_
