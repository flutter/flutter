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

// Returns a range encompassing the grapheme clusters falling in |range|.
//
// This method will not alter the length of the input range, but will ensure
// that the range's location is not in the middle of a multi-byte unicode
// sequence.
//
// If the given |range| is first clamped to the closest valid string length 
// An invalid range will result in `NSRange(NSNotFound, 0)`.
NSRange RangeForCharactersInRange(NSString* text, NSRange range);

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_STRING_RANGE_SANITIZATION_H_
