// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_H_

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "lib/tonic/dart_wrappable.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class SemanticsUpdate : public fxl::RefCountedThreadSafe<SemanticsUpdate>,
                        public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SemanticsUpdate);

 public:
  ~SemanticsUpdate() override;
  static fxl::RefPtr<SemanticsUpdate> create(SemanticsNodeUpdates nodes);

  SemanticsNodeUpdates takeNodes();

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit SemanticsUpdate(SemanticsNodeUpdates nodes);

  SemanticsNodeUpdates nodes_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_UPDATE_H_
