/*
 * Copyright (C) 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "styled_runs.h"

#include "lib/ftl/logging.h"

namespace txt {

StyledRuns::StyledRuns() = default;

StyledRuns::~StyledRuns() = default;

StyledRuns::StyledRuns(StyledRuns&& other) {
  styles_.swap(other.styles_);
  runs_.swap(other.runs_);
}

const StyledRuns& StyledRuns::operator=(StyledRuns&& other) {
  styles_.swap(other.styles_);
  runs_.swap(other.runs_);
  return *this;
}

void StyledRuns::swap(StyledRuns& other) {
  styles_.swap(other.styles_);
  runs_.swap(other.runs_);
}

size_t StyledRuns::AddStyle(const TextStyle& style) {
  const size_t style_index = styles_.size();
  styles_.push_back(style);
  return style_index;
}

const TextStyle& StyledRuns::PeekStyle() const {
  return styles_.back();
}

void StyledRuns::StartRun(size_t style_index, size_t start) {
  runs_.push_back(IndexedRun{style_index, start, start});
}

void StyledRuns::EndRunIfNeeded(size_t end) {
  if (runs_.empty())
    return;
  IndexedRun& run = runs_.back();
  if (run.start == end) {
    // The run is empty. We can skip it.
    runs_.pop_back();
  } else {
    run.end = end;
  }
}

StyledRuns::Run StyledRuns::GetRun(size_t index) const {
  const IndexedRun& run = runs_[index];
  return Run{styles_[run.style_index], run.start, run.end};
}

void StyledRuns::SplitNewlineRuns(std::list<size_t> newline_positions) {
  std::vector<IndexedRun> result;
  for (size_t i = 0; i < runs_.size(); ++i) {
    if (runs_[i].end <= newline_positions.front() ||
        newline_positions.empty()) {
      result.push_back(runs_[i]);
    } else {
      size_t start = runs_[i].start;
      size_t end = runs_[i].end;
      while (end > newline_positions.front() && !newline_positions.empty() &&
             start < end) {
        IndexedRun temp_run;
        temp_run.style_index = runs_[i].style_index;
        temp_run.start = start;
        temp_run.end = newline_positions.front();
        newline_positions.pop_front();
        result.push_back(temp_run);

        temp_run.start = temp_run.end;
        temp_run.end = temp_run.end + 1;
        result.push_back(temp_run);

        start = temp_run.end;
      }
      if (start < end) {
        IndexedRun temp_run;
        temp_run.style_index = runs_[i].style_index;
        temp_run.start = start;
        temp_run.end = end;
        result.push_back(temp_run);
      }
    }
  }
  runs_ = result;
}

}  // namespace txt
