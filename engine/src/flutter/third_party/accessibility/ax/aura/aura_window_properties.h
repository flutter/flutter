// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AURA_AURA_WINDOW_PROPERTIES_H_
#define UI_ACCESSIBILITY_AURA_AURA_WINDOW_PROPERTIES_H_

#include <string>

#include "ui/accessibility/ax_enums.mojom-forward.h"
#include "ui/accessibility/ax_export.h"
#include "ui/aura/window.h"

namespace ui {

// Value is a serialized |ui::AXTreeID| because code in //ui/aura/mus needs
// to serialize the window property, but //ui/aura cannot depend on
// //ui/accessibility and hence cannot know about the type ui::AXTreeID.
// TODO(dmazzoni): Convert from string to base::UnguessableToken.
AX_EXPORT extern const aura::WindowProperty<std::string*>* const kChildAXTreeID;

AX_EXPORT extern const aura::WindowProperty<ax::mojom::Role>* const
    kAXRoleOverride;

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AURA_AURA_WINDOW_PROPERTIES_H_
