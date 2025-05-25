// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_
#define FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

struct SemanticsFlags {
  bool hasCheckedState = false;
  bool isChecked = false;
  bool isSelected = false;
  bool isButton = false;
  bool isTextField = false;
  bool isFocused = false;
  bool hasEnabledState = false;
  bool isEnabled = false;
  bool isInMutuallyExclusiveGroup = false;
  bool isHeader = false;
  bool isObscured = false;
  bool scopesRoute = false;
  bool namesRoute = false;
  bool isHidden = false;
  bool isImage = false;
  bool isLiveRegion = false;
  bool hasToggledState = false;
  bool isToggled = false;
  bool hasImplicitScrolling = false;
  bool isMultiline = false;
  bool isReadOnly = false;
  bool isFocusable = false;
  bool isLink = false;
  bool isSlider = false;
  bool isKeyboardKey = false;
  bool isCheckStateMixed = false;
  bool hasExpandedState = false;
  bool isExpanded = false;
  bool hasSelectedState = false;
  bool hasRequiredState = false;
  bool isRequired = false;
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
                                 bool hasCheckedState,
                                 bool isChecked,
                                 bool isSelected,
                                 bool isButton,
                                 bool isTextField,
                                 bool isFocused,
                                 bool hasEnabledState,
                                 bool isEnabled,
                                 bool isInMutuallyExclusiveGroup,
                                 bool isHeader,
                                 bool isObscured,
                                 bool scopesRoute,
                                 bool namesRoute,
                                 bool isHidden,
                                 bool isImage,
                                 bool isLiveRegion,
                                 bool hasToggledState,
                                 bool isToggled,
                                 bool hasImplicitScrolling,
                                 bool isMultiline,
                                 bool isReadOnly,
                                 bool isFocusable,
                                 bool isLink,
                                 bool isSlider,
                                 bool isKeyboardKey,
                                 bool isCheckStateMixed,
                                 bool hasExpandedState,
                                 bool isExpanded,
                                 bool hasSelectedState,
                                 bool hasRequiredState,
                                 bool isRequired);

  //----------------------------------------------------------------------------
  /// Returns the c++ representataion of SemanticsFlags.

  const SemanticsFlags GetFlags() const;

 private:
  NativeSemanticsFlags();
  SemanticsFlags flags_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SEMANTICS_SEMANTICS_FLAGS_H_
