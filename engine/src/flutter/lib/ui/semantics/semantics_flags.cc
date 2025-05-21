#include "flutter/lib/ui/semantics/semantics_flags.h"
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/logging.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"

#include <memory>
#include <utility>

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, NativeSemanticsFlags);

NativeSemanticsFlags::NativeSemanticsFlags() {}

NativeSemanticsFlags::~NativeSemanticsFlags() {}

void NativeSemanticsFlags::initSemanticsFlags(
    Dart_Handle semantics_flags_handle,
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
    bool isRequired) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto native_semantics_flags = fml::MakeRefCounted<NativeSemanticsFlags>();
  native_semantics_flags->AssociateWithDartWrapper(semantics_flags_handle);

  native_semantics_flags->flags_ =
      SemanticsFlags{.hasCheckedState = hasCheckedState};
}

const SemanticsFlags NativeSemanticsFlags::GetFlags() const {
  return flags_;
}

}  // namespace flutter
