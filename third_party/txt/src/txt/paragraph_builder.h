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

#include "font_collection.h"
#include "lib/fxl/macros.h"
#include "paragraph.h"
#include "paragraph_style.h"
#include "styled_runs.h"
#include "text_style.h"

namespace txt {

class ParagraphBuilder {
 public:
  ParagraphBuilder(ParagraphStyle style,
                   std::shared_ptr<FontCollection> font_collection);

  ~ParagraphBuilder();

  // Push a style to the stack. The corresponding text added with AddText will
  // use the top-most style.
  void PushStyle(const TextStyle& style);

  // Remove a style from the stack. Useful to apply different styles to chunks
  // of text such as bolding.
  // Example:
  //   builder.PushStyle(normal_style);
  //   builder.AddText("Hello this is normal. ");
  //
  //   builder.PushStyle(bold_style);
  //   builder.AddText("And this is BOLD. ");
  //
  //   builder.Pop();
  //   builder.AddText(" Back to normal again.");
  void Pop();

  // Returns the last TextStyle on the stack.
  const TextStyle& PeekStyle() const;

  // Adds text to the builder. Forms the proper runs to use the upper-most style
  // on the style_stack_;
  void AddText(const std::u16string& text);

  // Converts to u16string before adding.
  void AddText(const std::string& text);

  // Converts to u16string before adding.
  void AddText(const char* text);

  void SetParagraphStyle(const ParagraphStyle& style);

  // Constructs a Paragraph object that can be used to layout and paint the text
  // to a SkCanvas.
  std::unique_ptr<Paragraph> Build();

 private:
  std::vector<uint16_t> text_;
  std::vector<size_t> style_stack_;
  std::shared_ptr<FontCollection> font_collection_;
  StyledRuns runs_;
  ParagraphStyle paragraph_style_;

  // Break any newline '\n' characters into their own runs. This allows
  // Paragraph::Layout to cleanly discover and handle newlines.
  void SplitNewlineRuns();

  FXL_DISALLOW_COPY_AND_ASSIGN(ParagraphBuilder);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_BUILDER_H_
