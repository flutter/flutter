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

#ifndef LIB_TXT_SRC_PARAGRAPH_BUILDER_H_
#define LIB_TXT_SRC_PARAGRAPH_BUILDER_H_

#include <memory>
#include <string>

#include "lib/ftl/macros.h"
#include "lib/txt/src/paragraph_style.h"
#include "lib/txt/src/styled_runs.h"
#include "lib/txt/src/text_style.h"

namespace txt {

class ParagraphBuilder {
 public:
  explicit ParagraphBuilder(ParagraphStyle style);

  ~ParagraphBuilder();

  void PushStyle(const TextStyle& style);

  void Pop();

  void AddText(const uint16_t* text, size_t length);

 private:
  std::vector<uint16_t> text_;
  std::vector<size_t> style_stack_;
  StyledRuns runs_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ParagraphBuilder);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_BUILDER_H_
