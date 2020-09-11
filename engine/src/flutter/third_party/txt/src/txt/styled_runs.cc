/*
 * Copyright 2017 Google Inc.
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

#include "flutter/fml/logging.h"
#include "utils/WindowsUtils.h"

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

const TextStyle& StyledRuns::GetStyle(size_t style_index) const {
  return styles_[style_index];
}

void StyledRuns::StartRun(size_t style_index, size_t start) {
  EndRunIfNeeded(start);
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

}  // namespace txt
