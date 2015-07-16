// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_SCOPED_GDI_OBJECT_H_
#define BASE_WIN_SCOPED_GDI_OBJECT_H_

#include <windows.h>

#include "base/basictypes.h"
#include "base/logging.h"

namespace base {
namespace win {

// Like ScopedHandle but for GDI objects.
template<class T>
class ScopedGDIObject {
 public:
  ScopedGDIObject() : object_(NULL) {}
  explicit ScopedGDIObject(T object) : object_(object) {}

  ~ScopedGDIObject() {
    Close();
  }

  T Get() {
    return object_;
  }

  void Set(T object) {
    if (object_ && object != object_)
      Close();
    object_ = object;
  }

  ScopedGDIObject& operator=(T object) {
    Set(object);
    return *this;
  }

  T release() {
    T object = object_;
    object_ = NULL;
    return object;
  }

  operator T() { return object_; }

 private:
  void Close() {
    if (object_)
      DeleteObject(object_);
  }

  T object_;
  DISALLOW_COPY_AND_ASSIGN(ScopedGDIObject);
};

// An explicit specialization for HICON because we have to call DestroyIcon()
// instead of DeleteObject() for HICON.
template<>
void inline ScopedGDIObject<HICON>::Close() {
  if (object_)
    DestroyIcon(object_);
}

// Typedefs for some common use cases.
typedef ScopedGDIObject<HBITMAP> ScopedBitmap;
typedef ScopedGDIObject<HRGN> ScopedRegion;
typedef ScopedGDIObject<HFONT> ScopedHFONT;
typedef ScopedGDIObject<HICON> ScopedHICON;

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_SCOPED_GDI_OBJECT_H_
