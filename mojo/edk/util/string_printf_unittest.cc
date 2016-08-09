// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/string_printf.h"

#include <errno.h>
#include <stdarg.h>

#include <string>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace util {
namespace {

// Note: |runnable| can't be a reference since that'd make the behavior of
// |va_start()| undefined.
template <typename Runnable>
std::string VAListHelper(Runnable runnable, ...) {
  va_list ap;
  va_start(ap, runnable);
  std::string rv = runnable(ap);
  va_end(ap);
  return rv;
}

TEST(StringPrintfTest, StringPrintf_Basic) {
  EXPECT_EQ("", StringPrintf(""));
  EXPECT_EQ("hello", StringPrintf("hello"));
  EXPECT_EQ("hello-123", StringPrintf("hello%d", -123));
  EXPECT_EQ("hello0123FACE", StringPrintf("%s%04d%X", "hello", 123, 0xfaceU));
}

TEST(StringPrintfTest, StringVPrintf_Basic) {
  EXPECT_EQ("", VAListHelper([](va_list ap) -> std::string {
              return StringVPrintf("", ap);
            }));
  EXPECT_EQ("hello", VAListHelper([](va_list ap) -> std::string {
              return StringVPrintf("hello", ap);
            }));
  EXPECT_EQ("hello-123", VAListHelper([](va_list ap) -> std::string {
              return StringVPrintf("hello%d", ap);
            }, -123));
  EXPECT_EQ("hello0123FACE", VAListHelper([](va_list ap) -> std::string {
              return StringVPrintf("%s%04d%X", ap);
            }, "hello", 123, 0xfaceU));
}

TEST(StringPrintfTest, StringAppendf_Basic) {
  {
    std::string s = "existing";
    StringAppendf(&s, "");
    EXPECT_EQ("existing", s);
  }
  {
    std::string s = "existing";
    StringAppendf(&s, "hello");
    EXPECT_EQ("existinghello", s);
  }
  {
    std::string s = "existing";
    StringAppendf(&s, "hello%d", -123);
    EXPECT_EQ("existinghello-123", s);
  }
  {
    std::string s = "existing";
    StringAppendf(&s, "%s%04d%X", "hello", 123, 0xfaceU);
    EXPECT_EQ("existinghello0123FACE", s);
  }
}

TEST(StringPrintfTest, StringVAppendf_Basic) {
  EXPECT_EQ("existing", VAListHelper([](va_list ap) -> std::string {
              std::string s = "existing";
              StringVAppendf(&s, "", ap);
              return s;
            }));
  EXPECT_EQ("existinghello", VAListHelper([](va_list ap) -> std::string {
              std::string s = "existing";
              StringVAppendf(&s, "hello", ap);
              return s;
            }));
  EXPECT_EQ("existinghello-123", VAListHelper([](va_list ap) -> std::string {
              std::string s = "existing";
              StringVAppendf(&s, "hello%d", ap);
              return s;
            }, -123));
  EXPECT_EQ("existinghello0123FACE",
            VAListHelper([](va_list ap) -> std::string {
              std::string s = "existing";
              StringVAppendf(&s, "%s%04d%X", ap);
              return s;
            }, "hello", 123, 0xfaceU));
}

// Generally, we assume that everything forwards to |StringVAppendf()|, so
// testing |StringPrintf()| more carefully suffices.

TEST(StringPrintfTest, StringPrintf_Boundary) {
  // Note: The size of strings generated should cover the boundary cases in the
  // constant |kStackBufferSize| in |StringVAppendf()|.
  for (size_t i = 800; i < 1200; i++) {
    std::string stuff(i, 'x');
    std::string format = stuff + "%d" + "%s" + " world";
    EXPECT_EQ(stuff + "123" + "hello world",
              StringPrintf(format.c_str(), 123, "hello"))
        << i;
  }
}

TEST(StringPrintfTest, StringPrintf_VeryBig) {
  // 4 megabytes of exes (we'll generate 5 times this).
  std::string stuff(4u << 20u, 'x');
  std::string format = "%s" + stuff + "%s" + stuff + "%s";
  EXPECT_EQ(stuff + stuff + stuff + stuff + stuff,
            StringPrintf(format.c_str(), stuff.c_str(), stuff.c_str(),
                         stuff.c_str()));
}

}  // namespace
}  // namespace util
}  // namespace mojo
