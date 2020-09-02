// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_HINT_FREED_DELEGATE_H_
#define FLUTTER_LIB_UI_HINT_FREED_DELEGATE_H_

namespace flutter {

class HintFreedDelegate {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Notifies the engine that native bytes might be freed if a
  ///             garbage collection ran at the next NotifyIdle period.
  ///
  /// @param[in]  size  The number of bytes freed. This size adds to any
  ///                   previously supplied value, rather than replacing.
  ///
  virtual void HintFreed(size_t size) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_HINT_FREED_DELEGATE_H_
