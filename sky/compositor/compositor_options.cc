// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/compositor_options.h"

#include <mutex>

namespace sky {
namespace compositor {

CompositorOptions::CompositorOptions() {
  static_assert(std::is_unsigned<OptionType>::value,
                "OptionType must be unsigned");
  options_.resize(static_cast<OptionType>(Option::TerminationSentinel), false);
}

bool CompositorOptions::isEnabled(Option option) const {
  if (option >= Option::TerminationSentinel) {
    return false;
  }

  return options_[static_cast<OptionType>(option)];
}

void CompositorOptions::setEnabled(Option option, bool enabled) {
  if (option < Option::TerminationSentinel) {
    options_[static_cast<OptionType>(option)] = enabled;
  }
}

CompositorOptions::~CompositorOptions() {
}

}  // namespace compositor
}  // namespace sky
