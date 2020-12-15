// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_text_utils.h"

#include <algorithm>

#include "base/check_op.h"
#include "base/i18n/break_iterator.h"
#include "base/notreached.h"
#include "base/numerics/safe_conversions.h"
#include "base/optional.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

namespace {

base::i18n::BreakIterator::BreakType ICUBreakTypeForBoundaryType(
    ax::mojom::TextBoundary boundary) {
  switch (boundary) {
    case ax::mojom::TextBoundary::kCharacter:
      return base::i18n::BreakIterator::BREAK_CHARACTER;
    case ax::mojom::TextBoundary::kSentenceStart:
      return base::i18n::BreakIterator::BREAK_SENTENCE;
    case ax::mojom::TextBoundary::kWordStart:
    case ax::mojom::TextBoundary::kWordStartOrEnd:
      return base::i18n::BreakIterator::BREAK_WORD;
    // These are currently unused since line breaking is done via an array of
    // line break offsets, and object boundary by finding no boundary within the
    // current node.
    case ax::mojom::TextBoundary::kObject:
    case ax::mojom::TextBoundary::kLineStart:
    case ax::mojom::TextBoundary::kParagraphStart:
      return base::i18n::BreakIterator::BREAK_NEWLINE;
    default:
      NOTREACHED() << boundary;
      return base::i18n::BreakIterator::BREAK_NEWLINE;
  }
}

}  // namespace

// line_breaks is a Misnomer. Blink provides the start offsets of each line
// not the line breaks.
// TODO(nektar): Rename line_breaks a11y attribute and variable references.
size_t FindAccessibleTextBoundary(const base::string16& text,
                                  const std::vector<int>& line_breaks,
                                  ax::mojom::TextBoundary boundary,
                                  size_t start_offset,
                                  ax::mojom::MoveDirection direction,
                                  ax::mojom::TextAffinity affinity) {
  size_t text_size = text.size();
  DCHECK_LE(start_offset, text_size);

  base::i18n::BreakIterator::BreakType break_type =
      ICUBreakTypeForBoundaryType(boundary);
  base::i18n::BreakIterator break_iter(text, break_type);
  if (boundary == ax::mojom::TextBoundary::kCharacter ||
      boundary == ax::mojom::TextBoundary::kSentenceStart ||
      boundary == ax::mojom::TextBoundary::kWordStart ||
      boundary == ax::mojom::TextBoundary::kWordStartOrEnd) {
    if (!break_iter.Init())
      return start_offset;
  }

  if (boundary == ax::mojom::TextBoundary::kLineStart) {
    if (direction == ax::mojom::MoveDirection::kForward) {
      for (int line_break : line_breaks) {
        size_t clamped_line_break = size_t{std::max(0, line_break)};
        if ((affinity == ax::mojom::TextAffinity::kDownstream &&
             clamped_line_break > start_offset) ||
            (affinity == ax::mojom::TextAffinity::kUpstream &&
             clamped_line_break >= start_offset)) {
          return clamped_line_break;
        }
      }
      return text_size;
    } else {
      for (size_t j = line_breaks.size(); j != 0; --j) {
        size_t line_break = line_breaks[j - 1] >= 0 ? line_breaks[j - 1] : 0;
        if ((affinity == ax::mojom::TextAffinity::kDownstream &&
             line_break <= start_offset) ||
            (affinity == ax::mojom::TextAffinity::kUpstream &&
             line_break < start_offset)) {
          return line_break;
        }
      }
      return 0;
    }
  }

  size_t result = start_offset;
  for (;;) {
    size_t pos;
    if (direction == ax::mojom::MoveDirection::kForward) {
      if (result >= text_size)
        return text_size;
      pos = result;
    } else {
      if (result == 0)
        return 0;
      pos = result - 1;
    }

    switch (boundary) {
      case ax::mojom::TextBoundary::kLineStart:
        NOTREACHED() << boundary;  // This is handled above.
        return result;
      case ax::mojom::TextBoundary::kCharacter:
        if (break_iter.IsGraphemeBoundary(result)) {
          // If we are searching forward and we are still at the start offset,
          // we need to find the next character.
          if (direction == ax::mojom::MoveDirection::kBackward ||
              result != start_offset)
            return result;
        }
        break;
      case ax::mojom::TextBoundary::kWordStart:
        if (break_iter.IsStartOfWord(result)) {
          // If we are searching forward and we are still at the start offset,
          // we need to find the next word.
          if (direction == ax::mojom::MoveDirection::kBackward ||
              result != start_offset)
            return result;
        }
        break;
      case ax::mojom::TextBoundary::kWordStartOrEnd:
        if (break_iter.IsStartOfWord(result)) {
          // If we are searching forward and we are still at the start offset,
          // we need to find the next word.
          if (direction == ax::mojom::MoveDirection::kBackward ||
              result != start_offset)
            return result;
        } else if (break_iter.IsEndOfWord(result)) {
          // If we are searching backward and we are still at the end offset, we
          // need to find the previous word.
          if (direction == ax::mojom::MoveDirection::kForward ||
              result != start_offset)
            return result;
        }
        break;
      case ax::mojom::TextBoundary::kSentenceStart:
        if (break_iter.IsSentenceBoundary(result)) {
          // If we are searching forward and we are still at the start offset,
          // we need to find the next sentence.
          if (direction == ax::mojom::MoveDirection::kBackward ||
              result != start_offset) {
            // ICU sometimes returns sentence boundaries in the whitespace
            // between sentences. For the purposes of accessibility, we want to
            // include all whitespace at the end of a sentence. We move the
            // boundary past the last whitespace offset. This works the same for
            // backwards and forwards searches.
            while (result < text_size &&
                   base::IsUnicodeWhitespace(text[result]))
              result++;
            return result;
          }
        }
        break;
      case ax::mojom::TextBoundary::kParagraphStart:
        if (text[pos] == '\n')
          return result;
        break;
      default:
        break;
    }

    if (direction == ax::mojom::MoveDirection::kForward) {
      result++;
    } else {
      result--;
    }
  }
}

std::vector<int> GetWordStartOffsets(const base::string16& text) {
  std::vector<int> word_starts;
  base::i18n::BreakIterator iter(text, base::i18n::BreakIterator::BREAK_WORD);
  if (!iter.Init())
    return word_starts;
  // iter.Advance() returns false if we've run past end of the text.
  while (iter.Advance()) {
    if (!iter.IsWord())
      continue;
    word_starts.push_back(
        base::checked_cast<int>(iter.prev()) /* start index */);
  }
  return word_starts;
}

std::vector<int> GetWordEndOffsets(const base::string16& text) {
  std::vector<int> word_ends;
  base::i18n::BreakIterator iter(text, base::i18n::BreakIterator::BREAK_WORD);
  if (!iter.Init())
    return word_ends;
  // iter.Advance() returns false if we've run past end of the text.
  while (iter.Advance()) {
    if (!iter.IsWord())
      continue;
    word_ends.push_back(base::checked_cast<int>(iter.pos()) /* end index */);
  }
  return word_ends;
}

}  // namespace ui
