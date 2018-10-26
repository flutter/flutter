// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_ISOLATE_NAME_SERVER_NATIVES_H_
#define FLUTTER_LIB_UI_ISOLATE_NAME_SERVER_NATIVES_H_

#include <string>
#include "third_party/dart/runtime/include/dart_api.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class IsolateNameServerNatives {
 public:
  static Dart_Handle LookupPortByName(const std::string& name);
  static Dart_Handle RegisterPortWithName(Dart_Handle port_handle,
                                          const std::string& name);
  static Dart_Handle RemovePortNameMapping(const std::string& name);
  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_ISOLATE_NAME_SERVER_NATIVES_H_
