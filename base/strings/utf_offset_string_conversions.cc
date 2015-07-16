// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/utf_offset_string_conversions.h"

#include <algorithm>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_piece.h"
#include "base/strings/utf_string_conversion_utils.h"

namespace base {

OffsetAdjuster::Adjustment::Adjustment(size_t original_offset,
                                       size_t original_length,
                                       size_t output_length)
    : original_offset(original_offset),
      original_length(original_length),
      output_length(output_length) {
}

// static
void OffsetAdjuster::AdjustOffsets(
    const Adjustments& adjustments,
    std::vector<size_t>* offsets_for_adjustment) {
  if (!offsets_for_adjustment || adjustments.empty())
    return;
  for (std::vector<size_t>::iterator i(offsets_for_adjustment->begin());
       i != offsets_for_adjustment->end(); ++i)
    AdjustOffset(adjustments, &(*i));
}

// static
void OffsetAdjuster::AdjustOffset(const Adjustments& adjustments,
                                  size_t* offset) {
  if (*offset == string16::npos)
    return;
  int adjustment = 0;
  for (Adjustments::const_iterator i = adjustments.begin();
       i != adjustments.end(); ++i) {
    if (*offset <= i->original_offset)
      break;
    if (*offset < (i->original_offset + i->original_length)) {
      *offset = string16::npos;
      return;
    }
    adjustment += static_cast<int>(i->original_length - i->output_length);
  }
  *offset -= adjustment;
}

// static
void OffsetAdjuster::UnadjustOffsets(
    const Adjustments& adjustments,
    std::vector<size_t>* offsets_for_unadjustment) {
  if (!offsets_for_unadjustment || adjustments.empty())
    return;
  for (std::vector<size_t>::iterator i(offsets_for_unadjustment->begin());
       i != offsets_for_unadjustment->end(); ++i)
    UnadjustOffset(adjustments, &(*i));
}

// static
void OffsetAdjuster::UnadjustOffset(const Adjustments& adjustments,
                                    size_t* offset) {
  if (*offset == string16::npos)
    return;
  int adjustment = 0;
  for (Adjustments::const_iterator i = adjustments.begin();
       i != adjustments.end(); ++i) {
    if (*offset + adjustment <= i->original_offset)
      break;
    adjustment += static_cast<int>(i->original_length - i->output_length);
    if ((*offset + adjustment) <
        (i->original_offset + i->original_length)) {
      *offset = string16::npos;
      return;
    }
  }
  *offset += adjustment;
}

// static
void OffsetAdjuster::MergeSequentialAdjustments(
    const Adjustments& first_adjustments,
    Adjustments* adjustments_on_adjusted_string) {
  Adjustments::iterator adjusted_iter = adjustments_on_adjusted_string->begin();
  Adjustments::const_iterator first_iter = first_adjustments.begin();
  // Simultaneously iterate over all |adjustments_on_adjusted_string| and
  // |first_adjustments|, adding adjustments to or correcting the adjustments
  // in |adjustments_on_adjusted_string| as we go.  |shift| keeps track of the
  // current number of characters collapsed by |first_adjustments| up to this
  // point.  |currently_collapsing| keeps track of the number of characters
  // collapsed by |first_adjustments| into the current |adjusted_iter|'s
  // length.  These are characters that will change |shift| as soon as we're
  // done processing the current |adjusted_iter|; they are not yet reflected in
  // |shift|.
  size_t shift = 0;
  size_t currently_collapsing = 0;
  while (adjusted_iter != adjustments_on_adjusted_string->end()) {
    if ((first_iter == first_adjustments.end()) ||
        ((adjusted_iter->original_offset + shift +
          adjusted_iter->original_length) <= first_iter->original_offset)) {
      // Entire |adjusted_iter| (accounting for its shift and including its
      // whole original length) comes before |first_iter|.
      //
      // Correct the offset at |adjusted_iter| and move onto the next
      // adjustment that needs revising.
      adjusted_iter->original_offset += shift;
      shift += currently_collapsing;
      currently_collapsing = 0;
      ++adjusted_iter;
    } else if ((adjusted_iter->original_offset + shift) >
               first_iter->original_offset) {
      // |first_iter| comes before the |adjusted_iter| (as adjusted by |shift|).

      // It's not possible for the adjustments to overlap.  (It shouldn't
      // be possible that we have an |adjusted_iter->original_offset| that,
      // when adjusted by the computed |shift|, is in the middle of
      // |first_iter|'s output's length.  After all, that would mean the
      // current adjustment_on_adjusted_string somehow points to an offset
      // that was supposed to have been eliminated by the first set of
      // adjustments.)
      DCHECK_LE(first_iter->original_offset + first_iter->output_length,
                adjusted_iter->original_offset + shift);

      // Add the |first_adjustment_iter| to the full set of adjustments while
      // making sure |adjusted_iter| continues pointing to the same element.
      // We do this by inserting the |first_adjustment_iter| right before
      // |adjusted_iter|, then incrementing |adjusted_iter| so it points to
      // the following element.
      shift += first_iter->original_length - first_iter->output_length;
      adjusted_iter = adjustments_on_adjusted_string->insert(
          adjusted_iter, *first_iter);
      ++adjusted_iter;
      ++first_iter;
    } else {
      // The first adjustment adjusted something that then got further adjusted
      // by the second set of adjustments.  In other words, |first_iter| points
      // to something in the range covered by |adjusted_iter|'s length (after
      // accounting for |shift|).  Precisely,
      //   adjusted_iter->original_offset + shift
      //   <=
      //   first_iter->original_offset
      //   <=
      //   adjusted_iter->original_offset + shift +
      //       adjusted_iter->original_length

      // Modify the current |adjusted_iter| to include whatever collapsing
      // happened in |first_iter|, then advance to the next |first_adjustments|
      // because we dealt with the current one.
      const int collapse = static_cast<int>(first_iter->original_length) -
          static_cast<int>(first_iter->output_length);
      // This function does not know how to deal with a string that expands and
      // then gets modified, only strings that collapse and then get modified.
      DCHECK_GT(collapse, 0);
      adjusted_iter->original_length += collapse;
      currently_collapsing += collapse;
      ++first_iter;
    }
  }
  DCHECK_EQ(0u, currently_collapsing);
  if (first_iter != first_adjustments.end()) {
    // Only first adjustments are left.  These do not need to be modified.
    // (Their offsets are already correct with respect to the original string.)
    // Append them all.
    DCHECK(adjusted_iter == adjustments_on_adjusted_string->end());
    adjustments_on_adjusted_string->insert(
        adjustments_on_adjusted_string->end(), first_iter,
        first_adjustments.end());
  }
}

// Converts the given source Unicode character type to the given destination
// Unicode character type as a STL string. The given input buffer and size
// determine the source, and the given output STL string will be replaced by
// the result.  If non-NULL, |adjustments| is set to reflect the all the
// alterations to the string that are not one-character-to-one-character.
// It will always be sorted by increasing offset.
template<typename SrcChar, typename DestStdString>
bool ConvertUnicode(const SrcChar* src,
                    size_t src_len,
                    DestStdString* output,
                    OffsetAdjuster::Adjustments* adjustments) {
  if (adjustments)
    adjustments->clear();
  // ICU requires 32-bit numbers.
  bool success = true;
  int32 src_len32 = static_cast<int32>(src_len);
  for (int32 i = 0; i < src_len32; i++) {
    uint32 code_point;
    size_t original_i = i;
    size_t chars_written = 0;
    if (ReadUnicodeCharacter(src, src_len32, &i, &code_point)) {
      chars_written = WriteUnicodeCharacter(code_point, output);
    } else {
      chars_written = WriteUnicodeCharacter(0xFFFD, output);
      success = false;
    }

    // Only bother writing an adjustment if this modification changed the
    // length of this character.
    // NOTE: ReadUnicodeCharacter() adjusts |i| to point _at_ the last
    // character read, not after it (so that incrementing it in the loop
    // increment will place it at the right location), so we need to account
    // for that in determining the amount that was read.
    if (adjustments && ((i - original_i + 1) != chars_written)) {
      adjustments->push_back(OffsetAdjuster::Adjustment(
          original_i, i - original_i + 1, chars_written));
    }
  }
  return success;
}

bool UTF8ToUTF16WithAdjustments(
    const char* src,
    size_t src_len,
    string16* output,
    base::OffsetAdjuster::Adjustments* adjustments) {
  PrepareForUTF16Or32Output(src, src_len, output);
  return ConvertUnicode(src, src_len, output, adjustments);
}

string16 UTF8ToUTF16WithAdjustments(
    const base::StringPiece& utf8,
    base::OffsetAdjuster::Adjustments* adjustments) {
  string16 result;
  UTF8ToUTF16WithAdjustments(utf8.data(), utf8.length(), &result, adjustments);
  return result;
}

string16 UTF8ToUTF16AndAdjustOffsets(
    const base::StringPiece& utf8,
    std::vector<size_t>* offsets_for_adjustment) {
  std::for_each(offsets_for_adjustment->begin(),
                offsets_for_adjustment->end(),
                LimitOffset<base::StringPiece>(utf8.length()));
  OffsetAdjuster::Adjustments adjustments;
  string16 result = UTF8ToUTF16WithAdjustments(utf8, &adjustments);
  OffsetAdjuster::AdjustOffsets(adjustments, offsets_for_adjustment);
  return result;
}

std::string UTF16ToUTF8AndAdjustOffsets(
    const base::StringPiece16& utf16,
    std::vector<size_t>* offsets_for_adjustment) {
  std::for_each(offsets_for_adjustment->begin(),
                offsets_for_adjustment->end(),
                LimitOffset<base::StringPiece16>(utf16.length()));
  std::string result;
  PrepareForUTF8Output(utf16.data(), utf16.length(), &result);
  OffsetAdjuster::Adjustments adjustments;
  ConvertUnicode(utf16.data(), utf16.length(), &result, &adjustments);
  OffsetAdjuster::AdjustOffsets(adjustments, offsets_for_adjustment);
  return result;
}

}  // namespace base
