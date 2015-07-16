// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_USER_METRICS_ACTION_H_
#define BASE_METRICS_USER_METRICS_ACTION_H_

namespace base {

// UserMetricsAction exists purely to standardize on the parameters passed to
// UserMetrics. That way, our toolset can scan the source code reliable for
// constructors and extract the associated string constants.
// WARNING: When using UserMetricsAction, UserMetricsAction and a string literal
// parameter must be on the same line, e.g.
//   RecordAction(UserMetricsAction("my extremely long action name"));
// or
//   RenderThread::Get()->RecordAction(
//       UserMetricsAction("my extremely long action name"));
// because otherwise our processing scripts won't pick up on new actions.
// Please see tools/metrics/actions/extract_actions.py for details.
struct UserMetricsAction {
  const char* str_;
  explicit UserMetricsAction(const char* str) : str_(str) {}
};

}  // namespace base

#endif  // BASE_METRICS_USER_METRICS_ACTION_H_
