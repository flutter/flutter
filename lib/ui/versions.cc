// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/versions.h"
#include "flutter/common/version/version.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_library_natives.h"

#include <string>
#include <vector>

using tonic::DartConverter;

namespace blink {

// returns a vector with 3 versions.
// Dart, Skia and Flutter engine versions in this order.
void GetVersions(Dart_NativeArguments args) {
  const std::vector<std::string> versions_list = {
      GetDartVersion(), GetSkiaVersion(), GetFlutterEngineVersion()};
  Dart_Handle dart_val =
      DartConverter<std::vector<std::string>>::ToDart(versions_list);
  Dart_SetReturnValue(args, dart_val);
}

void Versions::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Versions_getVersions", GetVersions, 0, true}});
}

}  // namespace blink
