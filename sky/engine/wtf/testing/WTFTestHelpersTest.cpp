/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "wtf/testing/WTFTestHelpers.h"

#include <gtest/gtest.h>
#include <sstream>
#include <string>
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

using namespace WTF;

namespace {

CString toCStringThroughPrinter(const String& string) {
  std::ostringstream output;
  output << string;
  const std::string& result = output.str();
  return CString(result.data(), result.length());
}

TEST(WTFTestHelpersTest, StringPrinter) {
  EXPECT_EQ(CString("\"Hello!\""), toCStringThroughPrinter("Hello!"));
  EXPECT_EQ(CString("\"\\\"\""), toCStringThroughPrinter("\""));
  EXPECT_EQ(CString("\"\\\\\""), toCStringThroughPrinter("\\"));
  EXPECT_EQ(
      CString("\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\""),
      toCStringThroughPrinter(String("\x00\x01\x02\x03\x04\x05\x06\x07", 8)));
  EXPECT_EQ(
      CString("\"\\u0008\\t\\n\\u000B\\u000C\\r\\u000E\\u000F\""),
      toCStringThroughPrinter(String("\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F", 8)));
  EXPECT_EQ(
      CString("\"\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\""),
      toCStringThroughPrinter(String("\x10\x11\x12\x13\x14\x15\x16\x17", 8)));
  EXPECT_EQ(
      CString("\"\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F\""),
      toCStringThroughPrinter(String("\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F", 8)));
  EXPECT_EQ(CString("\"\\u007F\\u0080\\u0081\""),
            toCStringThroughPrinter("\x7F\x80\x81"));
  EXPECT_EQ(CString("\"\""), toCStringThroughPrinter(emptyString()));
  EXPECT_EQ(CString("<null>"), toCStringThroughPrinter(String()));

  static const UChar unicodeSample[] = {0x30C6, 0x30B9,
                                        0x30C8};  // "Test" in Japanese.
  EXPECT_EQ(CString("\"\\u30C6\\u30B9\\u30C8\""),
            toCStringThroughPrinter(
                String(unicodeSample, WTF_ARRAY_LENGTH(unicodeSample))));
}

}  // namespace
