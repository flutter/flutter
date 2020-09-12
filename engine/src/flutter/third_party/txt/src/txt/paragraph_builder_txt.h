/*
 * Copyright 2019 Google Inc.
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

#ifndef LIB_TXT_SRC_PARAGRAPH_BUILDER_TXT_H_
#define LIB_TXT_SRC_PARAGRAPH_BUILDER_TXT_H_

#include "paragraph_builder.h"

#include "styled_runs.h"

namespace txt {

// Implementation of ParagraphBuilder that produces paragraphs backed by the
// Minikin text layout library.
class ParagraphBuilderTxt : public ParagraphBuilder {
 public:
  ParagraphBuilderTxt(const ParagraphStyle& style,
                      std::shared_ptr<FontCollection> font_collection);

  virtual ~ParagraphBuilderTxt();

  virtual void PushStyle(const TextStyle& style) override;
  virtual void Pop() override;
  virtual const TextStyle& PeekStyle() override;
  virtual void AddText(const std::u16string& text) override;
  virtual void AddPlaceholder(PlaceholderRun& span) override;
  virtual std::unique_ptr<Paragraph> Build() override;

 private:
  std::vector<uint16_t> text_;
  // A vector of PlaceholderRuns, which detail the sizes, positioning and break
  // behavior of the empty spaces to leave. Each placeholder span corresponds to
  // a 0xFFFC (object replacement character) in text_, which indicates the
  // position in the text where the placeholder will occur. There should be an
  // equal number of 0xFFFC characters and elements in this vector.
  std::vector<PlaceholderRun> inline_placeholders_;
  // The indexes of the obj replacement characters added through
  // ParagraphBuilder::addPlaceholder().
  std::unordered_set<size_t> obj_replacement_char_indexes_;
  std::vector<size_t> style_stack_;
  std::shared_ptr<FontCollection> font_collection_;
  StyledRuns runs_;
  ParagraphStyle paragraph_style_;
  size_t paragraph_style_index_;

  void SetParagraphStyle(const ParagraphStyle& style);

  size_t PeekStyleIndex() const;
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_BUILDER_TXT_H_
