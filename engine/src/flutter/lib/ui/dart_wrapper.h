// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_DART_WRAPPER_H_
#define FLUTTER_LIB_UI_DART_WRAPPER_H_

#include "lib/fxl/memory/ref_counted.h"
#include "third_party/tonic/dart_wrappable.h"

namespace blink {

template <typename T>
class RefCountedDartWrappable : public fxl::RefCountedThreadSafe<T>,
                                public tonic::DartWrappable {
 public:
  virtual void RetainDartWrappableReference() const override {
    fxl::RefCountedThreadSafe<T>::AddRef();
  }

  virtual void ReleaseDartWrappableReference() const override {
    fxl::RefCountedThreadSafe<T>::Release();
  }
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_DART_WRAPPER_H_
