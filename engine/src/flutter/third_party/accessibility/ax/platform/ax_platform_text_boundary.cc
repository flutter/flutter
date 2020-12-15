// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_text_boundary.h"

#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

#if BUILDFLAG(USE_ATK)
ax::mojom::TextBoundary FromAtkTextBoundary(AtkTextBoundary boundary) {
  // These are listed in order of their definition in the ATK header.
  switch (boundary) {
    case ATK_TEXT_BOUNDARY_CHAR:
      return ax::mojom::TextBoundary::kCharacter;
    case ATK_TEXT_BOUNDARY_WORD_START:
      return ax::mojom::TextBoundary::kWordStart;
    case ATK_TEXT_BOUNDARY_WORD_END:
      return ax::mojom::TextBoundary::kWordEnd;
    case ATK_TEXT_BOUNDARY_SENTENCE_START:
      return ax::mojom::TextBoundary::kSentenceStart;
    case ATK_TEXT_BOUNDARY_SENTENCE_END:
      return ax::mojom::TextBoundary::kSentenceEnd;
    case ATK_TEXT_BOUNDARY_LINE_START:
      return ax::mojom::TextBoundary::kLineStart;
    case ATK_TEXT_BOUNDARY_LINE_END:
      return ax::mojom::TextBoundary::kLineEnd;
  }
}

#if ATK_CHECK_VERSION(2, 10, 0)
ax::mojom::TextBoundary FromAtkTextGranularity(AtkTextGranularity granularity) {
  // These are listed in order of their definition in the ATK header.
  switch (granularity) {
    case ATK_TEXT_GRANULARITY_CHAR:
      return ax::mojom::TextBoundary::kCharacter;
    case ATK_TEXT_GRANULARITY_WORD:
      return ax::mojom::TextBoundary::kWordStart;
    case ATK_TEXT_GRANULARITY_SENTENCE:
      return ax::mojom::TextBoundary::kSentenceStart;
    case ATK_TEXT_GRANULARITY_LINE:
      return ax::mojom::TextBoundary::kLineStart;
    case ATK_TEXT_GRANULARITY_PARAGRAPH:
      return ax::mojom::TextBoundary::kParagraphStart;
  }
}
#endif  // ATK_CHECK_VERSION(2, 10, 0)
#endif  // BUILDFLAG(USE_ATK)

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
