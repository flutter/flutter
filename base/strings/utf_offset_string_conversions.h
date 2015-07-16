// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_STRINGS_UTF_OFFSET_STRING_CONVERSIONS_H_
#define BASE_STRINGS_UTF_OFFSET_STRING_CONVERSIONS_H_

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"

namespace base {

// A helper class and associated data structures to adjust offsets into a
// string in response to various adjustments one might do to that string
// (e.g., eliminating a range).  For details on offsets, see the comments by
// the AdjustOffsets() function below.
class BASE_EXPORT OffsetAdjuster {
 public:
  struct BASE_EXPORT Adjustment {
    Adjustment(size_t original_offset,
               size_t original_length,
               size_t output_length);

    size_t original_offset;
    size_t original_length;
    size_t output_length;
  };
  typedef std::vector<Adjustment> Adjustments;

  // Adjusts all offsets in |offsets_for_adjustment| to reflect the adjustments
  // recorded in |adjustments|.
  //
  // Offsets represents insertion/selection points between characters: if |src|
  // is "abcd", then 0 is before 'a', 2 is between 'b' and 'c', and 4 is at the
  // end of the string.  Valid input offsets range from 0 to |src_len|.  On
  // exit, each offset will have been modified to point at the same logical
  // position in the output string.  If an offset cannot be successfully
  // adjusted (e.g., because it points into the middle of a multibyte sequence),
  // it will be set to string16::npos.
  static void AdjustOffsets(const Adjustments& adjustments,
                            std::vector<size_t>* offsets_for_adjustment);

  // Adjusts the single |offset| to reflect the adjustments recorded in
  // |adjustments|.
  static void AdjustOffset(const Adjustments& adjustments,
                           size_t* offset);

  // Adjusts all offsets in |offsets_for_unadjustment| to reflect the reverse
  // of the adjustments recorded in |adjustments|.  In other words, the offsets
  // provided represent offsets into an adjusted string and the caller wants
  // to know the offsets they correspond to in the original string.  If an
  // offset cannot be successfully unadjusted (e.g., because it points into
  // the middle of a multibyte sequence), it will be set to string16::npos.
  static void UnadjustOffsets(const Adjustments& adjustments,
                              std::vector<size_t>* offsets_for_unadjustment);

  // Adjusts the single |offset| to reflect the reverse of the adjustments
  // recorded in |adjustments|.
  static void UnadjustOffset(const Adjustments& adjustments,
                             size_t* offset);

  // Combines two sequential sets of adjustments, storing the combined revised
  // adjustments in |adjustments_on_adjusted_string|.  That is, suppose a
  // string was altered in some way, with the alterations recorded as
  // adjustments in |first_adjustments|.  Then suppose the resulting string is
  // further altered, with the alterations recorded as adjustments scored in
  // |adjustments_on_adjusted_string|, with the offsets recorded in these
  // adjustments being with respect to the intermediate string.  This function
  // combines the two sets of adjustments into one, storing the result in
  // |adjustments_on_adjusted_string|, whose offsets are correct with respect
  // to the original string.
  //
  // Assumes both parameters are sorted by increasing offset.
  //
  // WARNING: Only supports |first_adjustments| that involve collapsing ranges
  // of text, not expanding ranges.
  static void MergeSequentialAdjustments(
      const Adjustments& first_adjustments,
      Adjustments* adjustments_on_adjusted_string);
};

// Like the conversions in utf_string_conversions.h, but also fills in an
// |adjustments| parameter that reflects the alterations done to the string.
// It may be NULL.
BASE_EXPORT bool UTF8ToUTF16WithAdjustments(
    const char* src,
    size_t src_len,
    string16* output,
    base::OffsetAdjuster::Adjustments* adjustments);
BASE_EXPORT string16 UTF8ToUTF16WithAdjustments(
    const base::StringPiece& utf8,
    base::OffsetAdjuster::Adjustments* adjustments);
// As above, but instead internally examines the adjustments and applies them
// to |offsets_for_adjustment|.  See comments by AdjustOffsets().
BASE_EXPORT string16 UTF8ToUTF16AndAdjustOffsets(
    const base::StringPiece& utf8,
    std::vector<size_t>* offsets_for_adjustment);

BASE_EXPORT std::string UTF16ToUTF8AndAdjustOffsets(
    const base::StringPiece16& utf16,
    std::vector<size_t>* offsets_for_adjustment);

// Limiting function callable by std::for_each which will replace any value
// which is greater than |limit| with npos.  Typically this is called with a
// string length to clamp offsets into the string to [0, length] (as opposed to
// [0, length); see comments above).
template <typename T>
struct LimitOffset {
  explicit LimitOffset(size_t limit)
    : limit_(limit) {}

  void operator()(size_t& offset) {
    if (offset > limit_)
      offset = T::npos;
  }

  size_t limit_;
};

}  // namespace base

#endif  // BASE_STRINGS_UTF_OFFSET_STRING_CONVERSIONS_H_
