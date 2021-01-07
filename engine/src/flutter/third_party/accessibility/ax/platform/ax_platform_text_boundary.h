// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_TEXT_BOUNDARY_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_TEXT_BOUNDARY_H_

#include "ax/ax_enums.h"
#include "ax/ax_export.h"
#include "ax_build/build_config.h"

#ifdef OS_WIN
#include <oleacc.h>
#include <uiautomation.h>

#include "third_party/iaccessible2/ia2_api_all.h"
#endif  // OS_WIN

namespace ui {

#ifdef OS_WIN
// Converts from an IAccessible2 text boundary to an ax::mojom::TextBoundary.
AX_EXPORT ax::mojom::TextBoundary FromIA2TextBoundary(
    IA2TextBoundaryType boundary);

// Converts from a UI Automation text unit to an ax::mojom::TextBoundary.
AX_EXPORT ax::mojom::TextBoundary FromUIATextUnit(TextUnit unit);
#endif  // OS_WIN

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_TEXT_BOUNDARY_H_
