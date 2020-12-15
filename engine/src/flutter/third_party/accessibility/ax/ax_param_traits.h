// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_PARAM_TRAITS_H_
#define UI_ACCESSIBILITY_AX_PARAM_TRAITS_H_

#include "ui/accessibility/ax_param_traits_macros.h"

namespace IPC {

template <>
struct AX_EXPORT ParamTraits<ui::AXTreeID> {
  typedef ui::AXTreeID param_type;
  static void Write(base::Pickle* m, const param_type& p);
  static bool Read(const base::Pickle* m,
                   base::PickleIterator* iter,
                   param_type* r);
  static void Log(const param_type& p, std::string* l);
};

}  // namespace IPC

#endif  // UI_ACCESSIBILITY_AX_PARAM_TRAITS_H_
