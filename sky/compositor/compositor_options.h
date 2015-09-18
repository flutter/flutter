// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_
#define SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_

#include "base/macros.h"
#include <vector>

namespace sky {
namespace compositor {

class CompositorOptions {
 public:
  using OptionType = unsigned int;
  enum class Option : OptionType {
    DisplayFrameStatistics,

    TerminationSentinel,
  };

  CompositorOptions();
  ~CompositorOptions();

  bool isEnabled(Option option) const;

  void setEnabled(Option option, bool enabled);

 private:
  std::vector<bool> options_;

  DISALLOW_COPY_AND_ASSIGN(CompositorOptions);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_COMPOSITOR_OPTIONS_H_
