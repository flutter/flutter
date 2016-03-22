// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_UI_VIEWS_CPP_FORMATTING_H_
#define MOJO_SERVICES_UI_VIEWS_CPP_FORMATTING_H_

#include <iosfwd>

#include "mojo/public/cpp/bindings/formatting.h"
#include "mojo/services/geometry/cpp/formatting.h"
#include "mojo/services/gfx/composition/cpp/formatting.h"
#include "mojo/services/ui/views/interfaces/view_associates.mojom.h"
#include "mojo/services/ui/views/interfaces/view_manager.mojom.h"

namespace mojo {
namespace ui {

std::ostream& operator<<(std::ostream& os, const mojo::ui::ViewToken& value);

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewTreeToken& value);

std::ostream& operator<<(std::ostream& os, const mojo::ui::ViewInfo& value);

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::BoxConstraints& value);
std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutParams& value);
std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutInfo& value);
std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutResult& value);

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewAssociateInfo& value);

}  // namespace ui
}  // namespace mojo

#endif  // MOJO_SERVICES_UI_VIEWS_CPP_FORMATTING_H_
