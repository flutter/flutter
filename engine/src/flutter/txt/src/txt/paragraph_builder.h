// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_PARAGRAPH_BUILDER_H_
#define FLUTTER_TXT_SRC_TXT_PARAGRAPH_BUILDER_H_

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "font_collection.h"
#include "paragraph.h"
#include "paragraph_style.h"
#include "placeholder_run.h"
#include "text_style.h"

namespace txt {

class ParagraphBuilder {
 public:
  static std::unique_ptr<ParagraphBuilder> CreateSkiaBuilder(
      const ParagraphStyle& style,
      const std::shared_ptr<FontCollection>& font_collection,
      const bool impeller_enabled);

  virtual ~ParagraphBuilder() = default;

  // Push a style to the stack. The corresponding text added with AddText will
  // use the top-most style.
  virtual void PushStyle(const TextStyle& style) = 0;

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
  virtual void Pop() = 0;

  // Returns the last TextStyle on the stack.
  virtual const TextStyle& PeekStyle() = 0;

  // Adds text to the builder. Forms the proper runs to use the upper-most style
  // on the style stack.
  virtual void AddText(const std::u16string& text) = 0;

  // Adds text to the builder. Forms the proper runs to use the upper-most style
  // on the style stack.
  //
  // Data must be in UTF-8 encoding.
  virtual void AddText(const uint8_t* utf8_data, size_t byte_length) = 0;

  // Pushes the information required to leave an open space, where Flutter may
  // draw a custom placeholder into.
  //
  // Internally, this method adds a single object replacement character (0xFFFC)
  // and emplaces a new PlaceholderRun instance to the vector of inline
  // placeholders.
  virtual void AddPlaceholder(PlaceholderRun& span) = 0;

  // Constructs a Paragraph object that can be used to layout and paint the text
  // to a SkCanvas.
  virtual std::unique_ptr<Paragraph> Build() = 0;

 protected:
  ParagraphBuilder() = default;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ParagraphBuilder);
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_PARAGRAPH_BUILDER_H_
