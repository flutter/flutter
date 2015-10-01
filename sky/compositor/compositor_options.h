// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_
#define SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_

#include <stdint.h>
#include <vector>
#include "base/macros.h"

namespace sky {
namespace compositor {

class CompositorOptions {
 public:
  using OptionType = unsigned int;
  enum class Option : OptionType {
    DisplayRasterizerStatistics,
    VisualizeRasterizerStatistics,
    DisplayEngineStatistics,
    VisualizeEngineStatistics,

    TerminationSentinel,
  };

  CompositorOptions();
  explicit CompositorOptions(uint64_t mask);

  ~CompositorOptions();

  bool isEnabled(Option option) const;

  bool anyEnabled() const;

  void setEnabled(Option option, bool enabled);

 private:
  std::vector<bool> options_;

  DISALLOW_COPY_AND_ASSIGN(CompositorOptions);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_
