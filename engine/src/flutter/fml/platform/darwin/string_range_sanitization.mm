// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/string_range_sanitization.h"

namespace fml {

NSRange RangeForCharacterAtIndex(NSString* text, NSUInteger index) {
    return [text rangeOfComposedCharacterSequenceAtIndex:MIN(text.length, index)];
}

NSRange RangeForCharactersInRange(NSString* text, NSRange range) {
  NSUInteger location = MIN(text.length, range.location);
  NSUInteger length = MIN(text.length - location, range.length);
  return [text rangeOfComposedCharacterSequencesForRange:NSMakeRange(location, length)];
}

}  // namespace fml
