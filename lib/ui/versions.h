// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_VERSIONS_H_
#define FLUTTER_LIB_UI_VERSIONS_H_

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Versions final {
 public:
  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_VERSIONS_H_
