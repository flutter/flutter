// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_LINE_METRICS_H_
#define FLUTTER_TXT_SRC_TXT_LINE_METRICS_H_

#include <map>
#include <vector>

#include "run_metrics.h"

namespace txt {

class LineMetrics {
 public:
  // The following fields are used in the layout process itself.

  // The indexes in the text buffer the line begins and ends.
  size_t start_index = 0;
  size_t end_index = 0;
  size_t end_excluding_whitespace = 0;
  size_t end_including_newline = 0;
  bool hard_break = false;

  // The following fields are tracked after or during layout to provide to
  // the user as well as for computing bounding boxes.

  // The final computed ascent and descent for the line. This can be impacted by
  // the strut, height, scaling, as well as outlying runs that are very tall.
  //
  // The top edge is `baseline - ascent` and the bottom edge is `baseline +
  // descent`. Ascent and descent are provided as positive numbers. Raw numbers
  // for specific runs of text can be obtained in run_metrics_map. These values
  // are the cumulative metrics for the entire line.
  double ascent = 0.0;
  double descent = 0.0;
  double unscaled_ascent = 0.0;
  // Total height of the paragraph including the current line.
  //
  // The height of the current line is `round(ascent + descent)`.
  double height = 0.0;
  // Width of the line.
  double width = 0.0;
  // The left edge of the line. The right edge can be obtained with `left +
  // width`
  double left = 0.0;
  // The y position of the baseline for this line from the top of the paragraph.
  double baseline = 0.0;
  // Zero indexed line number.
  size_t line_number = 0;

  // Mapping between text index ranges and the FontMetrics associated with
  // them. The first run will be keyed under start_index. The metrics here
  // are before layout and are the base values we calculate from.
  std::map<size_t, RunMetrics> run_metrics;

  LineMetrics() = default;

  LineMetrics(size_t start,
              size_t end,
              size_t end_excluding_whitespace,
              size_t end_including_newline,
              bool hard_break)
      : start_index(start),
        end_index(end),
        end_excluding_whitespace(end_excluding_whitespace),
        end_including_newline(end_including_newline),
        hard_break(hard_break) {}
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_LINE_METRICS_H_
