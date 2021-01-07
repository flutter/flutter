// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ax_platform_text_boundary.h"

#include "ax/ax_enums.h"

namespace ui {

#ifdef OS_WIN
ax::mojom::TextBoundary FromIA2TextBoundary(IA2TextBoundaryType boundary) {
  switch (boundary) {
    case IA2_TEXT_BOUNDARY_CHAR:
      return ax::mojom::TextBoundary::kCharacter;
    case IA2_TEXT_BOUNDARY_WORD:
      return ax::mojom::TextBoundary::kWordStart;
    case IA2_TEXT_BOUNDARY_LINE:
      return ax::mojom::TextBoundary::kLineStart;
    case IA2_TEXT_BOUNDARY_SENTENCE:
      return ax::mojom::TextBoundary::kSentenceStart;
    case IA2_TEXT_BOUNDARY_PARAGRAPH:
      return ax::mojom::TextBoundary::kParagraphStart;
    case IA2_TEXT_BOUNDARY_ALL:
      return ax::mojom::TextBoundary::kObject;
  }
}

ax::mojom::TextBoundary FromUIATextUnit(TextUnit unit) {
  // These are listed in order of their definition in the Microsoft
  // documentation.
  switch (unit) {
    case TextUnit_Character:
      return ax::mojom::TextBoundary::kCharacter;
    case TextUnit_Format:
      return ax::mojom::TextBoundary::kFormat;
    case TextUnit_Word:
      return ax::mojom::TextBoundary::kWordStart;
    case TextUnit_Line:
      return ax::mojom::TextBoundary::kLineStart;
    case TextUnit_Paragraph:
      return ax::mojom::TextBoundary::kParagraphStart;
    case TextUnit_Page:
      // UI Automation's TextUnit_Page cannot be reliably supported in a Web
      // document. We return kWebPage which is the next best thing.
    case TextUnit_Document:
      return ax::mojom::TextBoundary::kWebPage;
  }
}
#endif  // OS_WIN

}  // namespace ui
