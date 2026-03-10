// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

enum class SemanticsTristate : int32_t {
  kNone = 0,
  kTrue = 1,
  kFalse = 2,
};
enum class SemanticsCheckState : int32_t {
  kNone = 0,
  kTrue = 1,
  kFalse = 2,
  kMixed = 3,
};

struct SemanticsFlags {
  SemanticsCheckState isChecked = SemanticsCheckState::kNone;
  SemanticsTristate isSelected = SemanticsTristate::kNone;
  SemanticsTristate isEnabled = SemanticsTristate::kNone;
  SemanticsTristate isToggled = SemanticsTristate::kNone;
  SemanticsTristate isExpanded = SemanticsTristate::kNone;
  SemanticsTristate isRequired = SemanticsTristate::kNone;
  SemanticsTristate isFocused = SemanticsTristate::kNone;
  bool isButton = false;
  bool isTextField = false;
  bool isInMutuallyExclusiveGroup = false;
  bool isHeader = false;
  bool isObscured = false;
  bool scopesRoute = false;
  bool namesRoute = false;
  bool isHidden = false;
  bool isImage = false;
  bool isLiveRegion = false;
  bool hasImplicitScrolling = false;
  bool isMultiline = false;
  bool isReadOnly = false;
  bool isLink = false;
  bool isSlider = false;
  bool isKeyboardKey = false;
  bool isAccessibilityFocusBlocked = false;
};

//------------------------------------------------------------------------------
/// The peer class for all of the SemanticsFlags subclasses in semantics.dart.
class NativeSemanticsFlags
    : public RefCountedDartWrappable<NativeSemanticsFlags> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(NativeSemanticsFlags);

 public:
  ~NativeSemanticsFlags() override;

  //----------------------------------------------------------------------------
  /// The init method
  static void initSemanticsFlags(Dart_Handle semantics_flags_handle,
                                 int isChecked,
                                 int isSelected,
                                 int isEnabled,
                                 int isToggled,
                                 int isExpanded,
                                 int isRequired,
                                 int isFocused,
                                 bool isButton,
                                 bool isTextField,
                                 bool isInMutuallyExclusiveGroup,
                                 bool isHeader,
                                 bool isObscured,
                                 bool scopesRoute,
                                 bool namesRoute,
                                 bool isHidden,
                                 bool isImage,
                                 bool isLiveRegion,
                                 bool hasImplicitScrolling,
                                 bool isMultiline,
                                 bool isReadOnly,
                                 bool isLink,
                                 bool isSlider,
                                 bool isKeyboardKey,
                                 bool isAccessibilityFocusBlocked);

  //----------------------------------------------------------------------------
  /// Returns the c++ representataion of SemanticsFlags.

  const SemanticsFlags GetFlags() const;

 private:
  NativeSemanticsFlags();
  SemanticsFlags flags_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_
