/*
 * Copyright 2017 Google, Inc.
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

#ifndef LIB_TXT_SRC_PARAGRAPH_CONSTRAINTS_H_
#define LIB_TXT_SRC_PARAGRAPH_CONSTRAINTS_H_

#include "lib/ftl/macros.h"

namespace txt {

class ParagraphConstraints {
 public:
  explicit ParagraphConstraints(double width);

  double width() const { return width_; }

 private:
  double width_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ParagraphConstraints);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_CONSTRAINTS_H_
