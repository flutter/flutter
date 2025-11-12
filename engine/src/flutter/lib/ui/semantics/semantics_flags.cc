// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/semantics/semantics_flags.h"
#include "flutter/fml/logging.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, NativeSemanticsFlags);

NativeSemanticsFlags::NativeSemanticsFlags() {}

NativeSemanticsFlags::~NativeSemanticsFlags() {}

void NativeSemanticsFlags::initSemanticsFlags(
    Dart_Handle semantics_flags_handle,
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
    bool isAccessibilityFocusBlocked) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto native_semantics_flags = fml::MakeRefCounted<NativeSemanticsFlags>();
  native_semantics_flags->AssociateWithDartWrapper(semantics_flags_handle);

  native_semantics_flags->flags_ = SemanticsFlags{
      .isChecked = static_cast<SemanticsCheckState>(isChecked),
      .isSelected = static_cast<SemanticsTristate>(isSelected),
      .isEnabled = static_cast<SemanticsTristate>(isEnabled),
      .isToggled = static_cast<SemanticsTristate>(isToggled),
      .isExpanded = static_cast<SemanticsTristate>(isExpanded),
      .isRequired = static_cast<SemanticsTristate>(isRequired),
      .isFocused = static_cast<SemanticsTristate>(isFocused),
      .isButton = isButton,
      .isTextField = isTextField,
      .isInMutuallyExclusiveGroup = isInMutuallyExclusiveGroup,
      .isHeader = isHeader,
      .isObscured = isObscured,
      .scopesRoute = scopesRoute,
      .namesRoute = namesRoute,
      .isHidden = isHidden,
      .isImage = isImage,
      .isLiveRegion = isLiveRegion,
      .hasImplicitScrolling = hasImplicitScrolling,
      .isMultiline = isMultiline,
      .isReadOnly = isReadOnly,
      .isLink = isLink,
      .isSlider = isSlider,
      .isKeyboardKey = isKeyboardKey,
      .isAccessibilityFocusBlocked = isAccessibilityFocusBlocked,
  };
}

const SemanticsFlags NativeSemanticsFlags::GetFlags() const {
  return flags_;
}

}  // namespace flutter
