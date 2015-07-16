// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_SCOPED_PROPVARIANT_H_
#define BASE_WIN_SCOPED_PROPVARIANT_H_

#include <propidl.h>

#include "base/basictypes.h"
#include "base/logging.h"

namespace base {
namespace win {

// A PROPVARIANT that is automatically initialized and cleared upon respective
// construction and destruction of this class.
class ScopedPropVariant {
 public:
  ScopedPropVariant() {
    PropVariantInit(&pv_);
  }

  ~ScopedPropVariant() {
    Reset();
  }

  // Returns a pointer to the underlying PROPVARIANT for use as an out param in
  // a function call.
  PROPVARIANT* Receive() {
    DCHECK_EQ(pv_.vt, VT_EMPTY);
    return &pv_;
  }

  // Clears the instance to prepare it for re-use (e.g., via Receive).
  void Reset() {
    if (pv_.vt != VT_EMPTY) {
      HRESULT result = PropVariantClear(&pv_);
      DCHECK_EQ(result, S_OK);
    }
  }

  const PROPVARIANT& get() const { return pv_; }
  const PROPVARIANT* ptr() const { return &pv_; }

 private:
  PROPVARIANT pv_;

  // Comparison operators for ScopedPropVariant are not supported at this point.
  bool operator==(const ScopedPropVariant&) const;
  bool operator!=(const ScopedPropVariant&) const;
  DISALLOW_COPY_AND_ASSIGN(ScopedPropVariant);
};

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_SCOPED_PROPVARIANT_H_
