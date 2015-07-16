// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/safe_sprintf.h"

#include <stdio.h>
#include <string.h>

#include <limits>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

// Death tests on Android are currently very flaky. No need to add more flaky
// tests, as they just make it hard to spot real problems.
// TODO(markus): See if the restrictions on Android can eventually be lifted.
#if defined(GTEST_HAS_DEATH_TEST) && !defined(OS_ANDROID)
#define ALLOW_DEATH_TEST
#endif

namespace base {
namespace strings {

TEST(SafeSPrintfTest, Empty) {
  char buf[2] = { 'X', 'X' };

  // Negative buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, static_cast<size_t>(-1), ""));
  EXPECT_EQ('X', buf[0]);
  EXPECT_EQ('X', buf[1]);

  // Zero buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, 0, ""));
  EXPECT_EQ('X', buf[0]);
  EXPECT_EQ('X', buf[1]);

  // A one-byte buffer should always print a single NUL byte.
  EXPECT_EQ(0, SafeSNPrintf(buf, 1, ""));
  EXPECT_EQ(0, buf[0]);
  EXPECT_EQ('X', buf[1]);
  buf[0] = 'X';

  // A larger buffer should leave the trailing bytes unchanged.
  EXPECT_EQ(0, SafeSNPrintf(buf, 2, ""));
  EXPECT_EQ(0, buf[0]);
  EXPECT_EQ('X', buf[1]);
  buf[0] = 'X';

  // The same test using SafeSPrintf() instead of SafeSNPrintf().
  EXPECT_EQ(0, SafeSPrintf(buf, ""));
  EXPECT_EQ(0, buf[0]);
  EXPECT_EQ('X', buf[1]);
  buf[0] = 'X';
}

TEST(SafeSPrintfTest, NoArguments) {
  // Output a text message that doesn't require any substitutions. This
  // is roughly equivalent to calling strncpy() (but unlike strncpy(), it does
  // always add a trailing NUL; it always deduplicates '%' characters).
  static const char text[] = "hello world";
  char ref[20], buf[20];
  memset(ref, 'X', sizeof(ref));
  memcpy(buf, ref, sizeof(buf));

  // A negative buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, static_cast<size_t>(-1), text));
  EXPECT_TRUE(!memcmp(buf, ref, sizeof(buf)));

  // Zero buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, 0, text));
  EXPECT_TRUE(!memcmp(buf, ref, sizeof(buf)));

  // A one-byte buffer should always print a single NUL byte.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1, SafeSNPrintf(buf, 1, text));
  EXPECT_EQ(0, buf[0]);
  EXPECT_TRUE(!memcmp(buf+1, ref+1, sizeof(buf)-1));
  memcpy(buf, ref, sizeof(buf));

  // A larger (but limited) buffer should always leave the trailing bytes
  // unchanged.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1, SafeSNPrintf(buf, 2, text));
  EXPECT_EQ(text[0], buf[0]);
  EXPECT_EQ(0, buf[1]);
  EXPECT_TRUE(!memcmp(buf+2, ref+2, sizeof(buf)-2));
  memcpy(buf, ref, sizeof(buf));

  // A unrestricted buffer length should always leave the trailing bytes
  // unchanged.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1,
            SafeSNPrintf(buf, sizeof(buf), text));
  EXPECT_EQ(std::string(text), std::string(buf));
  EXPECT_TRUE(!memcmp(buf + sizeof(text), ref + sizeof(text),
                      sizeof(buf) - sizeof(text)));
  memcpy(buf, ref, sizeof(buf));

  // The same test using SafeSPrintf() instead of SafeSNPrintf().
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1, SafeSPrintf(buf, text));
  EXPECT_EQ(std::string(text), std::string(buf));
  EXPECT_TRUE(!memcmp(buf + sizeof(text), ref + sizeof(text),
                      sizeof(buf) - sizeof(text)));
  memcpy(buf, ref, sizeof(buf));

  // Check for deduplication of '%' percent characters.
  EXPECT_EQ(1, SafeSPrintf(buf, "%%"));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%%"));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%X"));
  EXPECT_EQ(3, SafeSPrintf(buf, "%%%%X"));
#if defined(NDEBUG)
  EXPECT_EQ(1, SafeSPrintf(buf, "%"));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%"));
  EXPECT_EQ(2, SafeSPrintf(buf, "%X"));
  EXPECT_EQ(3, SafeSPrintf(buf, "%%%X"));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, "%"), "src.1. == '%'");
  EXPECT_DEATH(SafeSPrintf(buf, "%%%"), "src.1. == '%'");
  EXPECT_DEATH(SafeSPrintf(buf, "%X"), "src.1. == '%'");
  EXPECT_DEATH(SafeSPrintf(buf, "%%%X"), "src.1. == '%'");
#endif
}

TEST(SafeSPrintfTest, OneArgument) {
  // Test basic single-argument single-character substitution.
  const char text[] = "hello world";
  const char fmt[]  = "hello%cworld";
  char ref[20], buf[20];
  memset(ref, 'X', sizeof(buf));
  memcpy(buf, ref, sizeof(buf));

  // A negative buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, static_cast<size_t>(-1), fmt, ' '));
  EXPECT_TRUE(!memcmp(buf, ref, sizeof(buf)));

  // Zero buffer size should always result in an error.
  EXPECT_EQ(-1, SafeSNPrintf(buf, 0, fmt, ' '));
  EXPECT_TRUE(!memcmp(buf, ref, sizeof(buf)));

  // A one-byte buffer should always print a single NUL byte.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1,
            SafeSNPrintf(buf, 1, fmt, ' '));
  EXPECT_EQ(0, buf[0]);
  EXPECT_TRUE(!memcmp(buf+1, ref+1, sizeof(buf)-1));
  memcpy(buf, ref, sizeof(buf));

  // A larger (but limited) buffer should always leave the trailing bytes
  // unchanged.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1,
            SafeSNPrintf(buf, 2, fmt, ' '));
  EXPECT_EQ(text[0], buf[0]);
  EXPECT_EQ(0, buf[1]);
  EXPECT_TRUE(!memcmp(buf+2, ref+2, sizeof(buf)-2));
  memcpy(buf, ref, sizeof(buf));

  // A unrestricted buffer length should always leave the trailing bytes
  // unchanged.
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1,
            SafeSNPrintf(buf, sizeof(buf), fmt, ' '));
  EXPECT_EQ(std::string(text), std::string(buf));
  EXPECT_TRUE(!memcmp(buf + sizeof(text), ref + sizeof(text),
                      sizeof(buf) - sizeof(text)));
  memcpy(buf, ref, sizeof(buf));

  // The same test using SafeSPrintf() instead of SafeSNPrintf().
  EXPECT_EQ(static_cast<ssize_t>(sizeof(text))-1, SafeSPrintf(buf, fmt, ' '));
  EXPECT_EQ(std::string(text), std::string(buf));
  EXPECT_TRUE(!memcmp(buf + sizeof(text), ref + sizeof(text),
                      sizeof(buf) - sizeof(text)));
  memcpy(buf, ref, sizeof(buf));

  // Check for deduplication of '%' percent characters.
  EXPECT_EQ(1, SafeSPrintf(buf, "%%", 0));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%%", 0));
  EXPECT_EQ(2, SafeSPrintf(buf, "%Y", 0));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%Y", 0));
  EXPECT_EQ(3, SafeSPrintf(buf, "%%%Y", 0));
  EXPECT_EQ(3, SafeSPrintf(buf, "%%%%Y", 0));
#if defined(NDEBUG)
  EXPECT_EQ(1, SafeSPrintf(buf, "%", 0));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%", 0));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, "%", 0), "ch");
  EXPECT_DEATH(SafeSPrintf(buf, "%%%", 0), "ch");
#endif
}

TEST(SafeSPrintfTest, MissingArg) {
#if defined(NDEBUG)
  char buf[20];
  EXPECT_EQ(3, SafeSPrintf(buf, "%c%c", 'A'));
  EXPECT_EQ("A%c", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  char buf[20];
  EXPECT_DEATH(SafeSPrintf(buf, "%c%c", 'A'), "cur_arg < max_args");
#endif
}

TEST(SafeSPrintfTest, ASANFriendlyBufferTest) {
  // Print into a buffer that is sized exactly to size. ASAN can verify that
  // nobody attempts to write past the end of the buffer.
  // There is a more complicated test in PrintLongString() that covers a lot
  // more edge case, but it is also harder to debug in case of a failure.
  const char kTestString[] = "This is a test";
  scoped_ptr<char[]> buf(new char[sizeof(kTestString)]);
  EXPECT_EQ(static_cast<ssize_t>(sizeof(kTestString) - 1),
            SafeSNPrintf(buf.get(), sizeof(kTestString), kTestString));
  EXPECT_EQ(std::string(kTestString), std::string(buf.get()));
  EXPECT_EQ(static_cast<ssize_t>(sizeof(kTestString) - 1),
            SafeSNPrintf(buf.get(), sizeof(kTestString), "%s", kTestString));
  EXPECT_EQ(std::string(kTestString), std::string(buf.get()));
}

TEST(SafeSPrintfTest, NArgs) {
  // Pre-C++11 compilers have a different code path, that can only print
  // up to ten distinct arguments.
  // We test both SafeSPrintf() and SafeSNPrintf(). This makes sure we don't
  // have typos in the copy-n-pasted code that is needed to deal with various
  // numbers of arguments.
  char buf[12];
  EXPECT_EQ(1, SafeSPrintf(buf, "%c", 1));
  EXPECT_EQ("\1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%c%c", 1, 2));
  EXPECT_EQ("\1\2", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%c%c%c", 1, 2, 3));
  EXPECT_EQ("\1\2\3", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%c%c%c%c", 1, 2, 3, 4));
  EXPECT_EQ("\1\2\3\4", std::string(buf));
  EXPECT_EQ(5, SafeSPrintf(buf, "%c%c%c%c%c", 1, 2, 3, 4, 5));
  EXPECT_EQ("\1\2\3\4\5", std::string(buf));
  EXPECT_EQ(6, SafeSPrintf(buf, "%c%c%c%c%c%c", 1, 2, 3, 4, 5, 6));
  EXPECT_EQ("\1\2\3\4\5\6", std::string(buf));
  EXPECT_EQ(7, SafeSPrintf(buf, "%c%c%c%c%c%c%c", 1, 2, 3, 4, 5, 6, 7));
  EXPECT_EQ("\1\2\3\4\5\6\7", std::string(buf));
  EXPECT_EQ(8, SafeSPrintf(buf, "%c%c%c%c%c%c%c%c", 1, 2, 3, 4, 5, 6, 7, 8));
  EXPECT_EQ("\1\2\3\4\5\6\7\10", std::string(buf));
  EXPECT_EQ(9, SafeSPrintf(buf, "%c%c%c%c%c%c%c%c%c",
                           1, 2, 3, 4, 5, 6, 7, 8, 9));
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11", std::string(buf));
  EXPECT_EQ(10, SafeSPrintf(buf, "%c%c%c%c%c%c%c%c%c%c",
                            1, 2, 3, 4, 5, 6, 7, 8, 9, 10));

  // Repeat all the tests with SafeSNPrintf() instead of SafeSPrintf().
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11\12", std::string(buf));
  EXPECT_EQ(1, SafeSNPrintf(buf, 11, "%c", 1));
  EXPECT_EQ("\1", std::string(buf));
  EXPECT_EQ(2, SafeSNPrintf(buf, 11, "%c%c", 1, 2));
  EXPECT_EQ("\1\2", std::string(buf));
  EXPECT_EQ(3, SafeSNPrintf(buf, 11, "%c%c%c", 1, 2, 3));
  EXPECT_EQ("\1\2\3", std::string(buf));
  EXPECT_EQ(4, SafeSNPrintf(buf, 11, "%c%c%c%c", 1, 2, 3, 4));
  EXPECT_EQ("\1\2\3\4", std::string(buf));
  EXPECT_EQ(5, SafeSNPrintf(buf, 11, "%c%c%c%c%c", 1, 2, 3, 4, 5));
  EXPECT_EQ("\1\2\3\4\5", std::string(buf));
  EXPECT_EQ(6, SafeSNPrintf(buf, 11, "%c%c%c%c%c%c", 1, 2, 3, 4, 5, 6));
  EXPECT_EQ("\1\2\3\4\5\6", std::string(buf));
  EXPECT_EQ(7, SafeSNPrintf(buf, 11, "%c%c%c%c%c%c%c", 1, 2, 3, 4, 5, 6, 7));
  EXPECT_EQ("\1\2\3\4\5\6\7", std::string(buf));
  EXPECT_EQ(8, SafeSNPrintf(buf, 11, "%c%c%c%c%c%c%c%c",
                            1, 2, 3, 4, 5, 6, 7, 8));
  EXPECT_EQ("\1\2\3\4\5\6\7\10", std::string(buf));
  EXPECT_EQ(9, SafeSNPrintf(buf, 11, "%c%c%c%c%c%c%c%c%c",
                            1, 2, 3, 4, 5, 6, 7, 8, 9));
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11", std::string(buf));
  EXPECT_EQ(10, SafeSNPrintf(buf, 11, "%c%c%c%c%c%c%c%c%c%c",
                             1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11\12", std::string(buf));

  EXPECT_EQ(11, SafeSPrintf(buf, "%c%c%c%c%c%c%c%c%c%c%c",
                            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11\12\13", std::string(buf));
  EXPECT_EQ(11, SafeSNPrintf(buf, 12, "%c%c%c%c%c%c%c%c%c%c%c",
                             1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
  EXPECT_EQ("\1\2\3\4\5\6\7\10\11\12\13", std::string(buf));
}

TEST(SafeSPrintfTest, DataTypes) {
  char buf[40];

  // Bytes
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (uint8_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%d", (uint8_t)-1));
  EXPECT_EQ("255", std::string(buf));
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (int8_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%d", (int8_t)-1));
  EXPECT_EQ("-1", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%d", (int8_t)-128));
  EXPECT_EQ("-128", std::string(buf));

  // Half-words
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (uint16_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(5, SafeSPrintf(buf, "%d", (uint16_t)-1));
  EXPECT_EQ("65535", std::string(buf));
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (int16_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%d", (int16_t)-1));
  EXPECT_EQ("-1", std::string(buf));
  EXPECT_EQ(6, SafeSPrintf(buf, "%d", (int16_t)-32768));
  EXPECT_EQ("-32768", std::string(buf));

  // Words
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (uint32_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(10, SafeSPrintf(buf, "%d", (uint32_t)-1));
  EXPECT_EQ("4294967295", std::string(buf));
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (int32_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%d", (int32_t)-1));
  EXPECT_EQ("-1", std::string(buf));
  // Work-around for an limitation of C90
  EXPECT_EQ(11, SafeSPrintf(buf, "%d", (int32_t)-2147483647-1));
  EXPECT_EQ("-2147483648", std::string(buf));

  // Quads
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (uint64_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(20, SafeSPrintf(buf, "%d", (uint64_t)-1));
  EXPECT_EQ("18446744073709551615", std::string(buf));
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", (int64_t)1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%d", (int64_t)-1));
  EXPECT_EQ("-1", std::string(buf));
  // Work-around for an limitation of C90
  EXPECT_EQ(20, SafeSPrintf(buf, "%d", (int64_t)-9223372036854775807LL-1));
  EXPECT_EQ("-9223372036854775808", std::string(buf));

  // Strings (both const and mutable).
  EXPECT_EQ(4, SafeSPrintf(buf, "test"));
  EXPECT_EQ("test", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, buf));
  EXPECT_EQ("test", std::string(buf));

  // Pointer
  char addr[20];
  sprintf(addr, "0x%llX", (unsigned long long)(uintptr_t)buf);
  SafeSPrintf(buf, "%p", buf);
  EXPECT_EQ(std::string(addr), std::string(buf));
  SafeSPrintf(buf, "%p", (const char *)buf);
  EXPECT_EQ(std::string(addr), std::string(buf));
  sprintf(addr, "0x%llX", (unsigned long long)(uintptr_t)sprintf);
  SafeSPrintf(buf, "%p", sprintf);
  EXPECT_EQ(std::string(addr), std::string(buf));

  // Padding for pointers is a little more complicated because of the "0x"
  // prefix. Padding with '0' zeros is relatively straight-forward, but
  // padding with ' ' spaces requires more effort.
  sprintf(addr, "0x%017llX", (unsigned long long)(uintptr_t)buf);
  SafeSPrintf(buf, "%019p", buf);
  EXPECT_EQ(std::string(addr), std::string(buf));
  sprintf(addr, "0x%llX", (unsigned long long)(uintptr_t)buf);
  memset(addr, ' ',
         (char*)memmove(addr + sizeof(addr) - strlen(addr) - 1,
                        addr, strlen(addr)+1) - addr);
  SafeSPrintf(buf, "%19p", buf);
  EXPECT_EQ(std::string(addr), std::string(buf));
}

namespace {
void PrintLongString(char* buf, size_t sz) {
  // Output a reasonably complex expression into a limited-size buffer.
  // At least one byte is available for writing the NUL character.
  CHECK_GT(sz, static_cast<size_t>(0));

  // Allocate slightly more space, so that we can verify that SafeSPrintf()
  // never writes past the end of the buffer.
  scoped_ptr<char[]> tmp(new char[sz+2]);
  memset(tmp.get(), 'X', sz+2);

  // Use SafeSPrintf() to output a complex list of arguments:
  // - test padding and truncating %c single characters.
  // - test truncating %s simple strings.
  // - test mismatching arguments and truncating (for %d != %s).
  // - test zero-padding and truncating %x hexadecimal numbers.
  // - test outputting and truncating %d MININT.
  // - test outputting and truncating %p arbitrary pointer values.
  // - test outputting, padding and truncating NULL-pointer %s strings.
  char* out = tmp.get();
  size_t out_sz = sz;
  size_t len;
  for (scoped_ptr<char[]> perfect_buf;;) {
    size_t needed = SafeSNPrintf(out, out_sz,
#if defined(NDEBUG)
                            "A%2cong %s: %d %010X %d %p%7s", 'l', "string", "",
#else
                            "A%2cong %s: %%d %010X %d %p%7s", 'l', "string",
#endif
                            0xDEADBEEF, std::numeric_limits<intptr_t>::min(),
                            PrintLongString, static_cast<char*>(NULL)) + 1;

    // Various sanity checks:
    // The numbered of characters needed to print the full string should always
    // be bigger or equal to the bytes that have actually been output.
    len = strlen(tmp.get());
    CHECK_GE(needed, len+1);

    // The number of characters output should always fit into the buffer that
    // was passed into SafeSPrintf().
    CHECK_LT(len, out_sz);

    // The output is always terminated with a NUL byte (actually, this test is
    // always going to pass, as strlen() already verified this)
    EXPECT_FALSE(tmp[len]);

    // ASAN can check that we are not overwriting buffers, iff we make sure the
    // buffer is exactly the size that we are expecting to be written. After
    // running SafeSNPrintf() the first time, it is possible to compute the
    // correct buffer size for this test. So, allocate a second buffer and run
    // the exact same SafeSNPrintf() command again.
    if (!perfect_buf.get()) {
      out_sz = std::min(needed, sz);
      out = new char[out_sz];
      perfect_buf.reset(out);
    } else {
      break;
    }
  }

  // All trailing bytes are unchanged.
  for (size_t i = len+1; i < sz+2; ++i)
    EXPECT_EQ('X', tmp[i]);

  // The text that was generated by SafeSPrintf() should always match the
  // equivalent text generated by sprintf(). Please note that the format
  // string for sprintf() is not complicated, as it does not have the
  // benefit of getting type information from the C++ compiler.
  //
  // N.B.: It would be so much cleaner to use snprintf(). But unfortunately,
  //       Visual Studio doesn't support this function, and the work-arounds
  //       are all really awkward.
  char ref[256];
  CHECK_LE(sz, sizeof(ref));
  sprintf(ref, "A long string: %%d 00DEADBEEF %lld 0x%llX <NULL>",
          static_cast<long long>(std::numeric_limits<intptr_t>::min()),
          static_cast<unsigned long long>(
            reinterpret_cast<uintptr_t>(PrintLongString)));
  ref[sz-1] = '\000';

#if defined(NDEBUG)
  const size_t kSSizeMax = std::numeric_limits<ssize_t>::max();
#else
  const size_t kSSizeMax = internal::GetSafeSPrintfSSizeMaxForTest();
#endif

  // Compare the output from SafeSPrintf() to the one from sprintf().
  EXPECT_EQ(std::string(ref).substr(0, kSSizeMax-1), std::string(tmp.get()));

  // We allocated a slightly larger buffer, so that we could perform some
  // extra sanity checks. Now that the tests have all passed, we copy the
  // data to the output buffer that the caller provided.
  memcpy(buf, tmp.get(), len+1);
}

#if !defined(NDEBUG)
class ScopedSafeSPrintfSSizeMaxSetter {
 public:
  ScopedSafeSPrintfSSizeMaxSetter(size_t sz) {
    old_ssize_max_ = internal::GetSafeSPrintfSSizeMaxForTest();
    internal::SetSafeSPrintfSSizeMaxForTest(sz);
  }

  ~ScopedSafeSPrintfSSizeMaxSetter() {
    internal::SetSafeSPrintfSSizeMaxForTest(old_ssize_max_);
  }

 private:
  size_t old_ssize_max_;

  DISALLOW_COPY_AND_ASSIGN(ScopedSafeSPrintfSSizeMaxSetter);
};
#endif

}  // anonymous namespace

TEST(SafeSPrintfTest, Truncation) {
  // We use PrintLongString() to print a complex long string and then
  // truncate to all possible lengths. This ends up exercising a lot of
  // different code paths in SafeSPrintf() and IToASCII(), as truncation can
  // happen in a lot of different states.
  char ref[256];
  PrintLongString(ref, sizeof(ref));
  for (size_t i = strlen(ref)+1; i; --i) {
    char buf[sizeof(ref)];
    PrintLongString(buf, i);
    EXPECT_EQ(std::string(ref, i - 1), std::string(buf));
  }

  // When compiling in debug mode, we have the ability to fake a small
  // upper limit for the maximum value that can be stored in an ssize_t.
  // SafeSPrintf() uses this upper limit to determine how many bytes it will
  // write to the buffer, even if the caller claimed a bigger buffer size.
  // Repeat the truncation test and verify that this other code path in
  // SafeSPrintf() works correctly, too.
#if !defined(NDEBUG)
  for (size_t i = strlen(ref)+1; i > 1; --i) {
    ScopedSafeSPrintfSSizeMaxSetter ssize_max_setter(i);
    char buf[sizeof(ref)];
    PrintLongString(buf, sizeof(buf));
    EXPECT_EQ(std::string(ref, i - 1), std::string(buf));
  }

  // kSSizeMax is also used to constrain the maximum amount of padding, before
  // SafeSPrintf() detects an error in the format string.
  ScopedSafeSPrintfSSizeMaxSetter ssize_max_setter(100);
  char buf[256];
  EXPECT_EQ(99, SafeSPrintf(buf, "%99c", ' '));
  EXPECT_EQ(std::string(99, ' '), std::string(buf));
  *buf = '\000';
#if defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, "%100c", ' '), "padding <= max_padding");
#endif
  EXPECT_EQ(0, *buf);
#endif
}

TEST(SafeSPrintfTest, Padding) {
  char buf[40], fmt[40];

  // Chars %c
  EXPECT_EQ(1, SafeSPrintf(buf, "%c", 'A'));
  EXPECT_EQ("A", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%2c", 'A'));
  EXPECT_EQ(" A", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%02c", 'A'));
  EXPECT_EQ(" A", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2c", 'A'));
  EXPECT_EQ("%-2c", std::string(buf));
  SafeSPrintf(fmt, "%%%dc", std::numeric_limits<ssize_t>::max() - 1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1, SafeSPrintf(buf, fmt, 'A'));
  SafeSPrintf(fmt, "%%%dc",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, 'A'));
  EXPECT_EQ("%c", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, 'A'), "padding <= max_padding");
#endif

  // Octal %o
  EXPECT_EQ(1, SafeSPrintf(buf, "%o", 1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%2o", 1));
  EXPECT_EQ(" 1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%02o", 1));
  EXPECT_EQ("01", std::string(buf));
  EXPECT_EQ(12, SafeSPrintf(buf, "%12o", -1));
  EXPECT_EQ(" 37777777777", std::string(buf));
  EXPECT_EQ(12, SafeSPrintf(buf, "%012o", -1));
  EXPECT_EQ("037777777777", std::string(buf));
  EXPECT_EQ(23, SafeSPrintf(buf, "%23o", -1LL));
  EXPECT_EQ(" 1777777777777777777777", std::string(buf));
  EXPECT_EQ(23, SafeSPrintf(buf, "%023o", -1LL));
  EXPECT_EQ("01777777777777777777777", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%2o", 0111));
  EXPECT_EQ("111", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2o", 1));
  EXPECT_EQ("%-2o", std::string(buf));
  SafeSPrintf(fmt, "%%%do", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%0%do", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("000", std::string(buf));
  SafeSPrintf(fmt, "%%%do",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, 1));
  EXPECT_EQ("%o", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, 1), "padding <= max_padding");
#endif

  // Decimals %d
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", 1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%2d", 1));
  EXPECT_EQ(" 1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%02d", 1));
  EXPECT_EQ("01", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%3d", -1));
  EXPECT_EQ(" -1", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%03d", -1));
  EXPECT_EQ("-01", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%2d", 111));
  EXPECT_EQ("111", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%2d", -111));
  EXPECT_EQ("-111", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2d", 1));
  EXPECT_EQ("%-2d", std::string(buf));
  SafeSPrintf(fmt, "%%%dd", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%0%dd", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("000", std::string(buf));
  SafeSPrintf(fmt, "%%%dd",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, 1));
  EXPECT_EQ("%d", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, 1), "padding <= max_padding");
#endif

  // Hex %X
  EXPECT_EQ(1, SafeSPrintf(buf, "%X", 1));
  EXPECT_EQ("1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%2X", 1));
  EXPECT_EQ(" 1", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%02X", 1));
  EXPECT_EQ("01", std::string(buf));
  EXPECT_EQ(9, SafeSPrintf(buf, "%9X", -1));
  EXPECT_EQ(" FFFFFFFF", std::string(buf));
  EXPECT_EQ(9, SafeSPrintf(buf, "%09X", -1));
  EXPECT_EQ("0FFFFFFFF", std::string(buf));
  EXPECT_EQ(17, SafeSPrintf(buf, "%17X", -1LL));
  EXPECT_EQ(" FFFFFFFFFFFFFFFF", std::string(buf));
  EXPECT_EQ(17, SafeSPrintf(buf, "%017X", -1LL));
  EXPECT_EQ("0FFFFFFFFFFFFFFFF", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%2X", 0x111));
  EXPECT_EQ("111", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2X", 1));
  EXPECT_EQ("%-2X", std::string(buf));
  SafeSPrintf(fmt, "%%%dX", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%0%dX", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, 1));
  EXPECT_EQ("000", std::string(buf));
  SafeSPrintf(fmt, "%%%dX",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, 1));
  EXPECT_EQ("%X", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, 1), "padding <= max_padding");
#endif

  // Pointer %p
  EXPECT_EQ(3, SafeSPrintf(buf, "%p", (void*)1));
  EXPECT_EQ("0x1", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%4p", (void*)1));
  EXPECT_EQ(" 0x1", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%04p", (void*)1));
  EXPECT_EQ("0x01", std::string(buf));
  EXPECT_EQ(5, SafeSPrintf(buf, "%4p", (void*)0x111));
  EXPECT_EQ("0x111", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2p", (void*)1));
  EXPECT_EQ("%-2p", std::string(buf));
  SafeSPrintf(fmt, "%%%dp", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, (void*)1));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%0%dp", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, (void*)1));
  EXPECT_EQ("0x0", std::string(buf));
  SafeSPrintf(fmt, "%%%dp",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, 1));
  EXPECT_EQ("%p", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, 1), "padding <= max_padding");
#endif

  // String
  EXPECT_EQ(1, SafeSPrintf(buf, "%s", "A"));
  EXPECT_EQ("A", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%2s", "A"));
  EXPECT_EQ(" A", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%02s", "A"));
  EXPECT_EQ(" A", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%2s", "AAA"));
  EXPECT_EQ("AAA", std::string(buf));
  EXPECT_EQ(4, SafeSPrintf(buf, "%-2s", "A"));
  EXPECT_EQ("%-2s", std::string(buf));
  SafeSPrintf(fmt, "%%%ds", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, "A"));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%0%ds", std::numeric_limits<ssize_t>::max()-1);
  EXPECT_EQ(std::numeric_limits<ssize_t>::max()-1,
            SafeSNPrintf(buf, 4, fmt, "A"));
  EXPECT_EQ("   ", std::string(buf));
  SafeSPrintf(fmt, "%%%ds",
              static_cast<size_t>(std::numeric_limits<ssize_t>::max()));
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, fmt, "A"));
  EXPECT_EQ("%s", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, fmt, "A"), "padding <= max_padding");
#endif
}

TEST(SafeSPrintfTest, EmbeddedNul) {
  char buf[] = { 'X', 'X', 'X', 'X' };
  EXPECT_EQ(2, SafeSPrintf(buf, "%3c", 0));
  EXPECT_EQ(' ', buf[0]);
  EXPECT_EQ(' ', buf[1]);
  EXPECT_EQ(0,   buf[2]);
  EXPECT_EQ('X', buf[3]);

  // Check handling of a NUL format character. N.B. this takes two different
  // code paths depending on whether we are actually passing arguments. If
  // we don't have any arguments, we are running in the fast-path code, that
  // looks (almost) like a strncpy().
#if defined(NDEBUG)
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%"));
  EXPECT_EQ("%%", std::string(buf));
  EXPECT_EQ(2, SafeSPrintf(buf, "%%%", 0));
  EXPECT_EQ("%%", std::string(buf));
#elif defined(ALLOW_DEATH_TEST)
  EXPECT_DEATH(SafeSPrintf(buf, "%%%"), "src.1. == '%'");
  EXPECT_DEATH(SafeSPrintf(buf, "%%%", 0), "ch");
#endif
}

TEST(SafeSPrintfTest, EmitNULL) {
  char buf[40];
#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion-null"
#endif
  EXPECT_EQ(1, SafeSPrintf(buf, "%d", NULL));
  EXPECT_EQ("0", std::string(buf));
  EXPECT_EQ(3, SafeSPrintf(buf, "%p", NULL));
  EXPECT_EQ("0x0", std::string(buf));
  EXPECT_EQ(6, SafeSPrintf(buf, "%s", NULL));
  EXPECT_EQ("<NULL>", std::string(buf));
#if defined(__GCC__)
#pragma GCC diagnostic pop
#endif
}

TEST(SafeSPrintfTest, PointerSize) {
  // The internal data representation is a 64bit value, independent of the
  // native word size. We want to perform sign-extension for signed integers,
  // but we want to avoid doing so for pointer types. This could be a
  // problem on systems, where pointers are only 32bit. This tests verifies
  // that there is no such problem.
  char *str = reinterpret_cast<char *>(0x80000000u);
  void *ptr = str;
  char buf[40];
  EXPECT_EQ(10, SafeSPrintf(buf, "%p", str));
  EXPECT_EQ("0x80000000", std::string(buf));
  EXPECT_EQ(10, SafeSPrintf(buf, "%p", ptr));
  EXPECT_EQ("0x80000000", std::string(buf));
}

}  // namespace strings
}  // namespace base
