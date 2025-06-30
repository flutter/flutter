// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_STRING_RANGE_SANITIZATION_H_
#define FLUTTER_FML_PLATFORM_DARWIN_STRING_RANGE_SANITIZATION_H_

#include <Foundation/Foundation.h>

namespace fml {

// Returns a range encompassing the grapheme cluster in which |index| is located.
//
// If the |index| is larger than the length of the |text|, the range of the last
// character is returned.
NSRange RangeForCharacterAtIndex(NSString* text, NSUInteger index);

// Returns the smallest range encompassing the grapheme clusters which are with
// in |range| or clipped by |range|.
//
// The given |range| is first clamped to a valid range within the length of the
// string before it is used to determine the grapheme clusters.
NSRange RangeForCharactersInRange(NSString* text, NSRange range);

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_STRING_RANGE_SANITIZATION_H_
