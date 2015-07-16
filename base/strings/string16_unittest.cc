// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>

#include "base/strings/string16.h"

#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

#if defined(WCHAR_T_IS_UTF32)

// We define a custom operator<< for string16 so we can use it with logging.
// This tests that conversion.
TEST(String16Test, OutputStream) {
  // Basic stream test.
  {
    std::ostringstream stream;
    stream << "Empty '" << string16() << "' standard '"
           << string16(ASCIIToUTF16("Hello, world")) << "'";
    EXPECT_STREQ("Empty '' standard 'Hello, world'",
                 stream.str().c_str());
  }

  // Interesting edge cases.
  {
    // These should each get converted to the invalid character: EF BF BD.
    string16 initial_surrogate;
    initial_surrogate.push_back(0xd800);
    string16 final_surrogate;
    final_surrogate.push_back(0xdc00);

    // Old italic A = U+10300, will get converted to: F0 90 8C 80 'z'.
    string16 surrogate_pair;
    surrogate_pair.push_back(0xd800);
    surrogate_pair.push_back(0xdf00);
    surrogate_pair.push_back('z');

    // Will get converted to the invalid char + 's': EF BF BD 's'.
    string16 unterminated_surrogate;
    unterminated_surrogate.push_back(0xd800);
    unterminated_surrogate.push_back('s');

    std::ostringstream stream;
    stream << initial_surrogate << "," << final_surrogate << ","
           << surrogate_pair << "," << unterminated_surrogate;

    EXPECT_STREQ("\xef\xbf\xbd,\xef\xbf\xbd,\xf0\x90\x8c\x80z,\xef\xbf\xbds",
                 stream.str().c_str());
  }
}

#endif

}  // namespace base
