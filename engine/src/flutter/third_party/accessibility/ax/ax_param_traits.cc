// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_param_traits.h"

namespace IPC {

void ParamTraits<ui::AXTreeID>::Write(base::Pickle* m, const param_type& p) {
  WriteParam(m, p.ToString());
}

bool ParamTraits<ui::AXTreeID>::Read(const base::Pickle* m,
                                     base::PickleIterator* iter,
                                     param_type* r) {
  std::string value;
  if (!ReadParam(m, iter, &value))
    return false;
  *r = ui::AXTreeID::FromString(value);
  return true;
}

void ParamTraits<ui::AXTreeID>::Log(const param_type& p, std::string* l) {
  l->append("<ui::AXTreeID>");
}

}  // namespace IPC

// Generate param traits write methods.
#include "ipc/param_traits_write_macros.h"
namespace IPC {
#undef UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_
#include "ui/accessibility/ax_param_traits_macros.h"
}  // namespace IPC

// Generate param traits read methods.
#include "ipc/param_traits_read_macros.h"
namespace IPC {
#undef UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_
#include "ui/accessibility/ax_param_traits_macros.h"
}  // namespace IPC

// Generate param traits log methods.
#include "ipc/param_traits_log_macros.h"
namespace IPC {
#undef UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_
#include "ui/accessibility/ax_param_traits_macros.h"
}  // namespace IPC
