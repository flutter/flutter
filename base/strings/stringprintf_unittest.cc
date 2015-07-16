// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/stringprintf.h"

#include <errno.h>

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

// A helper for the StringAppendV test that follows.
//
// Just forwards its args to StringAppendV.
static void StringAppendVTestHelper(std::string* out, const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  StringAppendV(out, format, ap);
  va_end(ap);
}

}  // namespace

TEST(StringPrintfTest, StringPrintfEmpty) {
  EXPECT_EQ("", StringPrintf("%s", ""));
}

TEST(StringPrintfTest, StringPrintfMisc) {
  EXPECT_EQ("123hello w", StringPrintf("%3d%2s %1c", 123, "hello", 'w'));
#if defined(OS_WIN)
  EXPECT_EQ(L"123hello w", StringPrintf(L"%3d%2ls %1lc", 123, L"hello", 'w'));
#endif
}

TEST(StringPrintfTest, StringAppendfEmptyString) {
  std::string value("Hello");
  StringAppendF(&value, "%s", "");
  EXPECT_EQ("Hello", value);

#if defined(OS_WIN)
  std::wstring valuew(L"Hello");
  StringAppendF(&valuew, L"%ls", L"");
  EXPECT_EQ(L"Hello", valuew);
#endif
}

TEST(StringPrintfTest, StringAppendfString) {
  std::string value("Hello");
  StringAppendF(&value, " %s", "World");
  EXPECT_EQ("Hello World", value);

#if defined(OS_WIN)
  std::wstring valuew(L"Hello");
  StringAppendF(&valuew, L" %ls", L"World");
  EXPECT_EQ(L"Hello World", valuew);
#endif
}

TEST(StringPrintfTest, StringAppendfInt) {
  std::string value("Hello");
  StringAppendF(&value, " %d", 123);
  EXPECT_EQ("Hello 123", value);

#if defined(OS_WIN)
  std::wstring valuew(L"Hello");
  StringAppendF(&valuew, L" %d", 123);
  EXPECT_EQ(L"Hello 123", valuew);
#endif
}

// Make sure that lengths exactly around the initial buffer size are handled
// correctly.
TEST(StringPrintfTest, StringPrintfBounds) {
  const int kSrcLen = 1026;
  char src[kSrcLen];
  for (size_t i = 0; i < arraysize(src); i++)
    src[i] = 'A';

  wchar_t srcw[kSrcLen];
  for (size_t i = 0; i < arraysize(srcw); i++)
    srcw[i] = 'A';

  for (int i = 1; i < 3; i++) {
    src[kSrcLen - i] = 0;
    std::string out;
    SStringPrintf(&out, "%s", src);
    EXPECT_STREQ(src, out.c_str());

#if defined(OS_WIN)
    srcw[kSrcLen - i] = 0;
    std::wstring outw;
    SStringPrintf(&outw, L"%ls", srcw);
    EXPECT_STREQ(srcw, outw.c_str());
#endif
  }
}

// Test very large sprintfs that will cause the buffer to grow.
TEST(StringPrintfTest, Grow) {
  char src[1026];
  for (size_t i = 0; i < arraysize(src); i++)
    src[i] = 'A';
  src[1025] = 0;

  const char fmt[] = "%sB%sB%sB%sB%sB%sB%s";

  std::string out;
  SStringPrintf(&out, fmt, src, src, src, src, src, src, src);

  const int kRefSize = 320000;
  char* ref = new char[kRefSize];
#if defined(OS_WIN)
  sprintf_s(ref, kRefSize, fmt, src, src, src, src, src, src, src);
#elif defined(OS_POSIX)
  snprintf(ref, kRefSize, fmt, src, src, src, src, src, src, src);
#endif

  EXPECT_STREQ(ref, out.c_str());
  delete[] ref;
}

TEST(StringPrintfTest, StringAppendV) {
  std::string out;
  StringAppendVTestHelper(&out, "%d foo %s", 1, "bar");
  EXPECT_EQ("1 foo bar", out);
}

// Test the boundary condition for the size of the string_util's
// internal buffer.
TEST(StringPrintfTest, GrowBoundary) {
  const int kStringUtilBufLen = 1024;
  // Our buffer should be one larger than the size of StringAppendVT's stack
  // buffer.
  // And need extra one for NULL-terminator.
  const int kBufLen = kStringUtilBufLen + 1 + 1;
  char src[kBufLen];
  for (int i = 0; i < kBufLen - 1; ++i)
    src[i] = 'a';
  src[kBufLen - 1] = 0;

  std::string out;
  SStringPrintf(&out, "%s", src);

  EXPECT_STREQ(src, out.c_str());
}

// TODO(evanm): what's the proper cross-platform test here?
#if defined(OS_WIN)
// sprintf in Visual Studio fails when given U+FFFF. This tests that the
// failure case is gracefuly handled.
TEST(StringPrintfTest, Invalid) {
  wchar_t invalid[2];
  invalid[0] = 0xffff;
  invalid[1] = 0;

  std::wstring out;
  SStringPrintf(&out, L"%ls", invalid);
  EXPECT_STREQ(L"", out.c_str());
}
#endif

// Test that StringPrintf and StringAppendV do not change errno.
TEST(StringPrintfTest, StringPrintfErrno) {
  errno = 1;
  EXPECT_EQ("", StringPrintf("%s", ""));
  EXPECT_EQ(1, errno);
  std::string out;
  StringAppendVTestHelper(&out, "%d foo %s", 1, "bar");
  EXPECT_EQ(1, errno);
}

}  // namespace base
