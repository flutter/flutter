// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_TESTS_POINTER_EVENT_UTILITY_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_TESTS_POINTER_EVENT_UTILITY_H_

#include <fuchsia/ui/pointer/cpp/fidl.h>
#include <zircon/types.h>

#include <array>
#include <optional>
#include <vector>

namespace flutter_runner::testing {

// A helper class for crafting a fuchsia.ui.pointer.TouchEvent table.
class TouchEventBuilder {
 public:
  static TouchEventBuilder New();

  TouchEventBuilder& AddTime(zx_time_t time);
  TouchEventBuilder& AddSample(fuchsia::ui::pointer::TouchInteractionId id,
                               fuchsia::ui::pointer::EventPhase phase,
                               std::array<float, 2> position);
  TouchEventBuilder& AddViewParameters(
      std::array<std::array<float, 2>, 2> view,
      std::array<std::array<float, 2>, 2> viewport,
      std::array<float, 9> transform);
  TouchEventBuilder& AddResult(
      fuchsia::ui::pointer::TouchInteractionResult result);

  fuchsia::ui::pointer::TouchEvent Build();
  std::vector<fuchsia::ui::pointer::TouchEvent> BuildAsVector();

 private:
  std::optional<zx_time_t> time_;
  std::optional<fuchsia::ui::pointer::ViewParameters> params_;
  std::optional<fuchsia::ui::pointer::TouchPointerSample> sample_;
  std::optional<fuchsia::ui::pointer::TouchInteractionResult> result_;
};

}  // namespace flutter_runner::testing

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_TESTS_POINTER_EVENT_UTILITY_H_
