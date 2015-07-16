// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

// This macro helps avoid wrapped lines in the test structs.
#define FPL(x) FILE_PATH_LITERAL(x)

// This macro constructs strings which can contain NULs.
#define FPS(x) FilePath::StringType(FPL(x), arraysize(FPL(x)) - 1)

namespace base {

struct UnaryTestData {
  const FilePath::CharType* input;
  const FilePath::CharType* expected;
};

struct UnaryBooleanTestData {
  const FilePath::CharType* input;
  bool expected;
};

struct BinaryTestData {
  const FilePath::CharType* inputs[2];
  const FilePath::CharType* expected;
};

struct BinaryBooleanTestData {
  const FilePath::CharType* inputs[2];
  bool expected;
};

struct BinaryIntTestData {
  const FilePath::CharType* inputs[2];
  int expected;
};

struct UTF8TestData {
  const FilePath::CharType* native;
  const char* utf8;
};

// file_util winds up using autoreleased objects on the Mac, so this needs
// to be a PlatformTest
typedef PlatformTest FilePathTest;

TEST_F(FilePathTest, DirName) {
  const struct UnaryTestData cases[] = {
    { FPL(""),              FPL(".") },
    { FPL("aa"),            FPL(".") },
    { FPL("/aa/bb"),        FPL("/aa") },
    { FPL("/aa/bb/"),       FPL("/aa") },
    { FPL("/aa/bb//"),      FPL("/aa") },
    { FPL("/aa/bb/ccc"),    FPL("/aa/bb") },
    { FPL("/aa"),           FPL("/") },
    { FPL("/aa/"),          FPL("/") },
    { FPL("/"),             FPL("/") },
    { FPL("//"),            FPL("//") },
    { FPL("///"),           FPL("/") },
    { FPL("aa/"),           FPL(".") },
    { FPL("aa/bb"),         FPL("aa") },
    { FPL("aa/bb/"),        FPL("aa") },
    { FPL("aa/bb//"),       FPL("aa") },
    { FPL("aa//bb//"),      FPL("aa") },
    { FPL("aa//bb/"),       FPL("aa") },
    { FPL("aa//bb"),        FPL("aa") },
    { FPL("//aa/bb"),       FPL("//aa") },
    { FPL("//aa/"),         FPL("//") },
    { FPL("//aa"),          FPL("//") },
    { FPL("0:"),            FPL(".") },
    { FPL("@:"),            FPL(".") },
    { FPL("[:"),            FPL(".") },
    { FPL("`:"),            FPL(".") },
    { FPL("{:"),            FPL(".") },
    { FPL("\xB3:"),         FPL(".") },
    { FPL("\xC5:"),         FPL(".") },
#if defined(OS_WIN)
    { FPL("\x0143:"),       FPL(".") },
#endif  // OS_WIN
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:"),            FPL("c:") },
    { FPL("C:"),            FPL("C:") },
    { FPL("A:"),            FPL("A:") },
    { FPL("Z:"),            FPL("Z:") },
    { FPL("a:"),            FPL("a:") },
    { FPL("z:"),            FPL("z:") },
    { FPL("c:aa"),          FPL("c:") },
    { FPL("c:/"),           FPL("c:/") },
    { FPL("c://"),          FPL("c://") },
    { FPL("c:///"),         FPL("c:/") },
    { FPL("c:/aa"),         FPL("c:/") },
    { FPL("c:/aa/"),        FPL("c:/") },
    { FPL("c:/aa/bb"),      FPL("c:/aa") },
    { FPL("c:aa/bb"),       FPL("c:aa") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("\\aa\\bb"),      FPL("\\aa") },
    { FPL("\\aa\\bb\\"),    FPL("\\aa") },
    { FPL("\\aa\\bb\\\\"),  FPL("\\aa") },
    { FPL("\\aa\\bb\\ccc"), FPL("\\aa\\bb") },
    { FPL("\\aa"),          FPL("\\") },
    { FPL("\\aa\\"),        FPL("\\") },
    { FPL("\\"),            FPL("\\") },
    { FPL("\\\\"),          FPL("\\\\") },
    { FPL("\\\\\\"),        FPL("\\") },
    { FPL("aa\\"),          FPL(".") },
    { FPL("aa\\bb"),        FPL("aa") },
    { FPL("aa\\bb\\"),      FPL("aa") },
    { FPL("aa\\bb\\\\"),    FPL("aa") },
    { FPL("aa\\\\bb\\\\"),  FPL("aa") },
    { FPL("aa\\\\bb\\"),    FPL("aa") },
    { FPL("aa\\\\bb"),      FPL("aa") },
    { FPL("\\\\aa\\bb"),    FPL("\\\\aa") },
    { FPL("\\\\aa\\"),      FPL("\\\\") },
    { FPL("\\\\aa"),        FPL("\\\\") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:\\"),          FPL("c:\\") },
    { FPL("c:\\\\"),        FPL("c:\\\\") },
    { FPL("c:\\\\\\"),      FPL("c:\\") },
    { FPL("c:\\aa"),        FPL("c:\\") },
    { FPL("c:\\aa\\"),      FPL("c:\\") },
    { FPL("c:\\aa\\bb"),    FPL("c:\\aa") },
    { FPL("c:aa\\bb"),      FPL("c:aa") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    FilePath observed = input.DirName();
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed.value()) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, BaseName) {
  const struct UnaryTestData cases[] = {
    { FPL(""),              FPL("") },
    { FPL("aa"),            FPL("aa") },
    { FPL("/aa/bb"),        FPL("bb") },
    { FPL("/aa/bb/"),       FPL("bb") },
    { FPL("/aa/bb//"),      FPL("bb") },
    { FPL("/aa/bb/ccc"),    FPL("ccc") },
    { FPL("/aa"),           FPL("aa") },
    { FPL("/"),             FPL("/") },
    { FPL("//"),            FPL("//") },
    { FPL("///"),           FPL("/") },
    { FPL("aa/"),           FPL("aa") },
    { FPL("aa/bb"),         FPL("bb") },
    { FPL("aa/bb/"),        FPL("bb") },
    { FPL("aa/bb//"),       FPL("bb") },
    { FPL("aa//bb//"),      FPL("bb") },
    { FPL("aa//bb/"),       FPL("bb") },
    { FPL("aa//bb"),        FPL("bb") },
    { FPL("//aa/bb"),       FPL("bb") },
    { FPL("//aa/"),         FPL("aa") },
    { FPL("//aa"),          FPL("aa") },
    { FPL("0:"),            FPL("0:") },
    { FPL("@:"),            FPL("@:") },
    { FPL("[:"),            FPL("[:") },
    { FPL("`:"),            FPL("`:") },
    { FPL("{:"),            FPL("{:") },
    { FPL("\xB3:"),         FPL("\xB3:") },
    { FPL("\xC5:"),         FPL("\xC5:") },
#if defined(OS_WIN)
    { FPL("\x0143:"),       FPL("\x0143:") },
#endif  // OS_WIN
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:"),            FPL("") },
    { FPL("C:"),            FPL("") },
    { FPL("A:"),            FPL("") },
    { FPL("Z:"),            FPL("") },
    { FPL("a:"),            FPL("") },
    { FPL("z:"),            FPL("") },
    { FPL("c:aa"),          FPL("aa") },
    { FPL("c:/"),           FPL("/") },
    { FPL("c://"),          FPL("//") },
    { FPL("c:///"),         FPL("/") },
    { FPL("c:/aa"),         FPL("aa") },
    { FPL("c:/aa/"),        FPL("aa") },
    { FPL("c:/aa/bb"),      FPL("bb") },
    { FPL("c:aa/bb"),       FPL("bb") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("\\aa\\bb"),      FPL("bb") },
    { FPL("\\aa\\bb\\"),    FPL("bb") },
    { FPL("\\aa\\bb\\\\"),  FPL("bb") },
    { FPL("\\aa\\bb\\ccc"), FPL("ccc") },
    { FPL("\\aa"),          FPL("aa") },
    { FPL("\\"),            FPL("\\") },
    { FPL("\\\\"),          FPL("\\\\") },
    { FPL("\\\\\\"),        FPL("\\") },
    { FPL("aa\\"),          FPL("aa") },
    { FPL("aa\\bb"),        FPL("bb") },
    { FPL("aa\\bb\\"),      FPL("bb") },
    { FPL("aa\\bb\\\\"),    FPL("bb") },
    { FPL("aa\\\\bb\\\\"),  FPL("bb") },
    { FPL("aa\\\\bb\\"),    FPL("bb") },
    { FPL("aa\\\\bb"),      FPL("bb") },
    { FPL("\\\\aa\\bb"),    FPL("bb") },
    { FPL("\\\\aa\\"),      FPL("aa") },
    { FPL("\\\\aa"),        FPL("aa") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:\\"),          FPL("\\") },
    { FPL("c:\\\\"),        FPL("\\\\") },
    { FPL("c:\\\\\\"),      FPL("\\") },
    { FPL("c:\\aa"),        FPL("aa") },
    { FPL("c:\\aa\\"),      FPL("aa") },
    { FPL("c:\\aa\\bb"),    FPL("bb") },
    { FPL("c:aa\\bb"),      FPL("bb") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    FilePath observed = input.BaseName();
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed.value()) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, Append) {
  const struct BinaryTestData cases[] = {
    { { FPL(""),           FPL("cc") }, FPL("cc") },
    { { FPL("."),          FPL("ff") }, FPL("ff") },
    { { FPL("/"),          FPL("cc") }, FPL("/cc") },
    { { FPL("/aa"),        FPL("") },   FPL("/aa") },
    { { FPL("/aa/"),       FPL("") },   FPL("/aa") },
    { { FPL("//aa"),       FPL("") },   FPL("//aa") },
    { { FPL("//aa/"),      FPL("") },   FPL("//aa") },
    { { FPL("//"),         FPL("aa") }, FPL("//aa") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:"),         FPL("a") },  FPL("c:a") },
    { { FPL("c:"),         FPL("") },   FPL("c:") },
    { { FPL("c:/"),        FPL("a") },  FPL("c:/a") },
    { { FPL("c://"),       FPL("a") },  FPL("c://a") },
    { { FPL("c:///"),      FPL("a") },  FPL("c:/a") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    // Append introduces the default separator character, so these test cases
    // need to be defined with different expected results on platforms that use
    // different default separator characters.
    { { FPL("\\"),         FPL("cc") }, FPL("\\cc") },
    { { FPL("\\aa"),       FPL("") },   FPL("\\aa") },
    { { FPL("\\aa\\"),     FPL("") },   FPL("\\aa") },
    { { FPL("\\\\aa"),     FPL("") },   FPL("\\\\aa") },
    { { FPL("\\\\aa\\"),   FPL("") },   FPL("\\\\aa") },
    { { FPL("\\\\"),       FPL("aa") }, FPL("\\\\aa") },
    { { FPL("/aa/bb"),     FPL("cc") }, FPL("/aa/bb\\cc") },
    { { FPL("/aa/bb/"),    FPL("cc") }, FPL("/aa/bb\\cc") },
    { { FPL("aa/bb/"),     FPL("cc") }, FPL("aa/bb\\cc") },
    { { FPL("aa/bb"),      FPL("cc") }, FPL("aa/bb\\cc") },
    { { FPL("a/b"),        FPL("c") },  FPL("a/b\\c") },
    { { FPL("a/b/"),       FPL("c") },  FPL("a/b\\c") },
    { { FPL("//aa"),       FPL("bb") }, FPL("//aa\\bb") },
    { { FPL("//aa/"),      FPL("bb") }, FPL("//aa\\bb") },
    { { FPL("\\aa\\bb"),   FPL("cc") }, FPL("\\aa\\bb\\cc") },
    { { FPL("\\aa\\bb\\"), FPL("cc") }, FPL("\\aa\\bb\\cc") },
    { { FPL("aa\\bb\\"),   FPL("cc") }, FPL("aa\\bb\\cc") },
    { { FPL("aa\\bb"),     FPL("cc") }, FPL("aa\\bb\\cc") },
    { { FPL("a\\b"),       FPL("c") },  FPL("a\\b\\c") },
    { { FPL("a\\b\\"),     FPL("c") },  FPL("a\\b\\c") },
    { { FPL("\\\\aa"),     FPL("bb") }, FPL("\\\\aa\\bb") },
    { { FPL("\\\\aa\\"),   FPL("bb") }, FPL("\\\\aa\\bb") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:\\"),       FPL("a") },  FPL("c:\\a") },
    { { FPL("c:\\\\"),     FPL("a") },  FPL("c:\\\\a") },
    { { FPL("c:\\\\\\"),   FPL("a") },  FPL("c:\\a") },
    { { FPL("c:\\"),       FPL("") },   FPL("c:\\") },
    { { FPL("c:\\a"),      FPL("b") },  FPL("c:\\a\\b") },
    { { FPL("c:\\a\\"),    FPL("b") },  FPL("c:\\a\\b") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#else  // FILE_PATH_USES_WIN_SEPARATORS
    { { FPL("/aa/bb"),     FPL("cc") }, FPL("/aa/bb/cc") },
    { { FPL("/aa/bb/"),    FPL("cc") }, FPL("/aa/bb/cc") },
    { { FPL("aa/bb/"),     FPL("cc") }, FPL("aa/bb/cc") },
    { { FPL("aa/bb"),      FPL("cc") }, FPL("aa/bb/cc") },
    { { FPL("a/b"),        FPL("c") },  FPL("a/b/c") },
    { { FPL("a/b/"),       FPL("c") },  FPL("a/b/c") },
    { { FPL("//aa"),       FPL("bb") }, FPL("//aa/bb") },
    { { FPL("//aa/"),      FPL("bb") }, FPL("//aa/bb") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:/"),        FPL("a") },  FPL("c:/a") },
    { { FPL("c:/"),        FPL("") },   FPL("c:/") },
    { { FPL("c:/a"),       FPL("b") },  FPL("c:/a/b") },
    { { FPL("c:/a/"),      FPL("b") },  FPL("c:/a/b") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath root(cases[i].inputs[0]);
    FilePath::StringType leaf(cases[i].inputs[1]);
    FilePath observed_str = root.Append(leaf);
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed_str.value()) <<
              "i: " << i << ", root: " << root.value() << ", leaf: " << leaf;
    FilePath observed_path = root.Append(FilePath(leaf));
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed_path.value()) <<
              "i: " << i << ", root: " << root.value() << ", leaf: " << leaf;

    // TODO(erikkay): It would be nice to have a unicode test append value to
    // handle the case when AppendASCII is passed UTF8
#if defined(OS_WIN)
    std::string ascii = WideToUTF8(leaf);
#elif defined(OS_POSIX)
    std::string ascii = leaf;
#endif
    observed_str = root.AppendASCII(ascii);
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed_str.value()) <<
              "i: " << i << ", root: " << root.value() << ", leaf: " << leaf;
  }
}

TEST_F(FilePathTest, StripTrailingSeparators) {
  const struct UnaryTestData cases[] = {
    { FPL(""),              FPL("") },
    { FPL("/"),             FPL("/") },
    { FPL("//"),            FPL("//") },
    { FPL("///"),           FPL("/") },
    { FPL("////"),          FPL("/") },
    { FPL("a/"),            FPL("a") },
    { FPL("a//"),           FPL("a") },
    { FPL("a///"),          FPL("a") },
    { FPL("a////"),         FPL("a") },
    { FPL("/a"),            FPL("/a") },
    { FPL("/a/"),           FPL("/a") },
    { FPL("/a//"),          FPL("/a") },
    { FPL("/a///"),         FPL("/a") },
    { FPL("/a////"),        FPL("/a") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:"),            FPL("c:") },
    { FPL("c:/"),           FPL("c:/") },
    { FPL("c://"),          FPL("c://") },
    { FPL("c:///"),         FPL("c:/") },
    { FPL("c:////"),        FPL("c:/") },
    { FPL("c:/a"),          FPL("c:/a") },
    { FPL("c:/a/"),         FPL("c:/a") },
    { FPL("c:/a//"),        FPL("c:/a") },
    { FPL("c:/a///"),       FPL("c:/a") },
    { FPL("c:/a////"),      FPL("c:/a") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("\\"),            FPL("\\") },
    { FPL("\\\\"),          FPL("\\\\") },
    { FPL("\\\\\\"),        FPL("\\") },
    { FPL("\\\\\\\\"),      FPL("\\") },
    { FPL("a\\"),           FPL("a") },
    { FPL("a\\\\"),         FPL("a") },
    { FPL("a\\\\\\"),       FPL("a") },
    { FPL("a\\\\\\\\"),     FPL("a") },
    { FPL("\\a"),           FPL("\\a") },
    { FPL("\\a\\"),         FPL("\\a") },
    { FPL("\\a\\\\"),       FPL("\\a") },
    { FPL("\\a\\\\\\"),     FPL("\\a") },
    { FPL("\\a\\\\\\\\"),   FPL("\\a") },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("c:\\"),          FPL("c:\\") },
    { FPL("c:\\\\"),        FPL("c:\\\\") },
    { FPL("c:\\\\\\"),      FPL("c:\\") },
    { FPL("c:\\\\\\\\"),    FPL("c:\\") },
    { FPL("c:\\a"),         FPL("c:\\a") },
    { FPL("c:\\a\\"),       FPL("c:\\a") },
    { FPL("c:\\a\\\\"),     FPL("c:\\a") },
    { FPL("c:\\a\\\\\\"),   FPL("c:\\a") },
    { FPL("c:\\a\\\\\\\\"), FPL("c:\\a") },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    FilePath observed = input.StripTrailingSeparators();
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed.value()) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, IsAbsolute) {
  const struct UnaryBooleanTestData cases[] = {
    { FPL(""),       false },
    { FPL("a"),      false },
    { FPL("c:"),     false },
    { FPL("c:a"),    false },
    { FPL("a/b"),    false },
    { FPL("//"),     true },
    { FPL("//a"),    true },
    { FPL("c:a/b"),  false },
    { FPL("?:/a"),   false },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("/"),      false },
    { FPL("/a"),     false },
    { FPL("/."),     false },
    { FPL("/.."),    false },
    { FPL("c:/"),    true },
    { FPL("c:/a"),   true },
    { FPL("c:/."),   true },
    { FPL("c:/.."),  true },
    { FPL("C:/a"),   true },
    { FPL("d:/a"),   true },
#else  // FILE_PATH_USES_DRIVE_LETTERS
    { FPL("/"),      true },
    { FPL("/a"),     true },
    { FPL("/."),     true },
    { FPL("/.."),    true },
    { FPL("c:/"),    false },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("a\\b"),   false },
    { FPL("\\\\"),   true },
    { FPL("\\\\a"),  true },
    { FPL("a\\b"),   false },
    { FPL("\\\\"),   true },
    { FPL("//a"),    true },
    { FPL("c:a\\b"), false },
    { FPL("?:\\a"),  false },
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("\\"),     false },
    { FPL("\\a"),    false },
    { FPL("\\."),    false },
    { FPL("\\.."),   false },
    { FPL("c:\\"),   true },
    { FPL("c:\\"),   true },
    { FPL("c:\\a"),  true },
    { FPL("c:\\."),  true },
    { FPL("c:\\.."), true },
    { FPL("C:\\a"),  true },
    { FPL("d:\\a"),  true },
#else  // FILE_PATH_USES_DRIVE_LETTERS
    { FPL("\\"),     true },
    { FPL("\\a"),    true },
    { FPL("\\."),    true },
    { FPL("\\.."),   true },
    { FPL("c:\\"),   false },
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    bool observed = input.IsAbsolute();
    EXPECT_EQ(cases[i].expected, observed) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, PathComponentsTest) {
  const struct UnaryTestData cases[] = {
    { FPL("//foo/bar/baz/"),          FPL("|//|foo|bar|baz")},
    { FPL("///"),                     FPL("|/")},
    { FPL("/foo//bar//baz/"),         FPL("|/|foo|bar|baz")},
    { FPL("/foo/bar/baz/"),           FPL("|/|foo|bar|baz")},
    { FPL("/foo/bar/baz//"),          FPL("|/|foo|bar|baz")},
    { FPL("/foo/bar/baz///"),         FPL("|/|foo|bar|baz")},
    { FPL("/foo/bar/baz"),            FPL("|/|foo|bar|baz")},
    { FPL("/foo/bar.bot/baz.txt"),    FPL("|/|foo|bar.bot|baz.txt")},
    { FPL("//foo//bar/baz"),          FPL("|//|foo|bar|baz")},
    { FPL("/"),                       FPL("|/")},
    { FPL("foo"),                     FPL("|foo")},
    { FPL(""),                        FPL("")},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { FPL("e:/foo"),                  FPL("|e:|/|foo")},
    { FPL("e:/"),                     FPL("|e:|/")},
    { FPL("e:"),                      FPL("|e:")},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("../foo"),                  FPL("|..|foo")},
    { FPL("./foo"),                   FPL("|foo")},
    { FPL("../foo/bar/"),             FPL("|..|foo|bar") },
    { FPL("\\\\foo\\bar\\baz\\"),     FPL("|\\\\|foo|bar|baz")},
    { FPL("\\\\\\"),                  FPL("|\\")},
    { FPL("\\foo\\\\bar\\\\baz\\"),   FPL("|\\|foo|bar|baz")},
    { FPL("\\foo\\bar\\baz\\"),       FPL("|\\|foo|bar|baz")},
    { FPL("\\foo\\bar\\baz\\\\"),     FPL("|\\|foo|bar|baz")},
    { FPL("\\foo\\bar\\baz\\\\\\"),   FPL("|\\|foo|bar|baz")},
    { FPL("\\foo\\bar\\baz"),         FPL("|\\|foo|bar|baz")},
    { FPL("\\foo\\bar/baz\\\\\\"),    FPL("|\\|foo|bar|baz")},
    { FPL("/foo\\bar\\baz"),          FPL("|/|foo|bar|baz")},
    { FPL("\\foo\\bar.bot\\baz.txt"), FPL("|\\|foo|bar.bot|baz.txt")},
    { FPL("\\\\foo\\\\bar\\baz"),     FPL("|\\\\|foo|bar|baz")},
    { FPL("\\"),                      FPL("|\\")},
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    std::vector<FilePath::StringType> comps;
    input.GetComponents(&comps);

    FilePath::StringType observed;
    for (size_t j = 0; j < comps.size(); ++j) {
      observed.append(FILE_PATH_LITERAL("|"), 1);
      observed.append(comps[j]);
    }
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, IsParentTest) {
  const struct BinaryBooleanTestData cases[] = {
    { { FPL("/"),             FPL("/foo/bar/baz") },      true},
    { { FPL("/foo/bar"),      FPL("/foo/bar/baz") },      true},
    { { FPL("/foo/bar/"),     FPL("/foo/bar/baz") },      true},
    { { FPL("//foo/bar/"),    FPL("//foo/bar/baz") },     true},
    { { FPL("/foo/bar"),      FPL("/foo2/bar/baz") },     false},
    { { FPL("/foo/bar.txt"),  FPL("/foo/bar/baz") },      false},
    { { FPL("/foo/bar"),      FPL("/foo/bar2/baz") },     false},
    { { FPL("/foo/bar"),      FPL("/foo/bar") },          false},
    { { FPL("/foo/bar/baz"),  FPL("/foo/bar") },          false},
    { { FPL("foo/bar"),       FPL("foo/bar/baz") },       true},
    { { FPL("foo/bar"),       FPL("foo2/bar/baz") },      false},
    { { FPL("foo/bar"),       FPL("foo/bar2/baz") },      false},
    { { FPL(""),              FPL("foo") },               false},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:/foo/bar"),    FPL("c:/foo/bar/baz") },    true},
    { { FPL("E:/foo/bar"),    FPL("e:/foo/bar/baz") },    true},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/bar/baz") },    true},
    { { FPL("E:/Foo/bar"),    FPL("e:/foo/bar/baz") },    false},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/Bar/baz") },    false},
    { { FPL("c:/"),           FPL("c:/foo/bar/baz") },    true},
    { { FPL("c:"),            FPL("c:/foo/bar/baz") },    true},
    { { FPL("c:/foo/bar"),    FPL("d:/foo/bar/baz") },    false},
    { { FPL("c:/foo/bar"),    FPL("D:/foo/bar/baz") },    false},
    { { FPL("C:/foo/bar"),    FPL("d:/foo/bar/baz") },    false},
    { { FPL("c:/foo/bar"),    FPL("c:/foo2/bar/baz") },   false},
    { { FPL("e:/foo/bar"),    FPL("E:/foo2/bar/baz") },   false},
    { { FPL("F:/foo/bar"),    FPL("f:/foo2/bar/baz") },   false},
    { { FPL("c:/foo/bar"),    FPL("c:/foo/bar2/baz") },   false},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar\\baz") },   true},
    { { FPL("\\foo/bar"),     FPL("\\foo\\bar\\baz") },   true},
    { { FPL("\\foo/bar"),     FPL("\\foo/bar/baz") },     true},
    { { FPL("\\"),            FPL("\\foo\\bar\\baz") },   true},
    { { FPL(""),              FPL("\\foo\\bar\\baz") },   false},
    { { FPL("\\foo\\bar"),    FPL("\\foo2\\bar\\baz") },  false},
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar2\\baz") },  false},
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath parent(cases[i].inputs[0]);
    FilePath child(cases[i].inputs[1]);

    EXPECT_EQ(parent.IsParent(child), cases[i].expected) <<
        "i: " << i << ", parent: " << parent.value() << ", child: " <<
        child.value();
  }
}

TEST_F(FilePathTest, AppendRelativePathTest) {
  const struct BinaryTestData cases[] = {
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("/"),             FPL("/foo/bar/baz") },      FPL("foo\\bar\\baz")},
#else  // FILE_PATH_USES_WIN_SEPARATORS
    { { FPL("/"),             FPL("/foo/bar/baz") },      FPL("foo/bar/baz")},
#endif  // FILE_PATH_USES_WIN_SEPARATORS
    { { FPL("/foo/bar"),      FPL("/foo/bar/baz") },      FPL("baz")},
    { { FPL("/foo/bar/"),     FPL("/foo/bar/baz") },      FPL("baz")},
    { { FPL("//foo/bar/"),    FPL("//foo/bar/baz") },     FPL("baz")},
    { { FPL("/foo/bar"),      FPL("/foo2/bar/baz") },     FPL("")},
    { { FPL("/foo/bar.txt"),  FPL("/foo/bar/baz") },      FPL("")},
    { { FPL("/foo/bar"),      FPL("/foo/bar2/baz") },     FPL("")},
    { { FPL("/foo/bar"),      FPL("/foo/bar") },          FPL("")},
    { { FPL("/foo/bar/baz"),  FPL("/foo/bar") },          FPL("")},
    { { FPL("foo/bar"),       FPL("foo/bar/baz") },       FPL("baz")},
    { { FPL("foo/bar"),       FPL("foo2/bar/baz") },      FPL("")},
    { { FPL("foo/bar"),       FPL("foo/bar2/baz") },      FPL("")},
    { { FPL(""),              FPL("foo") },               FPL("")},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:/foo/bar"),    FPL("c:/foo/bar/baz") },    FPL("baz")},
    { { FPL("E:/foo/bar"),    FPL("e:/foo/bar/baz") },    FPL("baz")},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/bar/baz") },    FPL("baz")},
    { { FPL("E:/Foo/bar"),    FPL("e:/foo/bar/baz") },    FPL("")},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/Bar/baz") },    FPL("")},
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("c:/"),           FPL("c:/foo/bar/baz") },    FPL("foo\\bar\\baz")},
    // TODO(akalin): Figure out how to handle the corner case in the
    // commented-out test case below.  Appending to an empty path gives
    // /foo\bar\baz but appending to a nonempty path "blah" gives
    // blah\foo\bar\baz.
    // { { FPL("c:"),            FPL("c:/foo/bar/baz") }, FPL("foo\\bar\\baz")},
#endif  // FILE_PATH_USES_WIN_SEPARATORS
    { { FPL("c:/foo/bar"),    FPL("d:/foo/bar/baz") },    FPL("")},
    { { FPL("c:/foo/bar"),    FPL("D:/foo/bar/baz") },    FPL("")},
    { { FPL("C:/foo/bar"),    FPL("d:/foo/bar/baz") },    FPL("")},
    { { FPL("c:/foo/bar"),    FPL("c:/foo2/bar/baz") },   FPL("")},
    { { FPL("e:/foo/bar"),    FPL("E:/foo2/bar/baz") },   FPL("")},
    { { FPL("F:/foo/bar"),    FPL("f:/foo2/bar/baz") },   FPL("")},
    { { FPL("c:/foo/bar"),    FPL("c:/foo/bar2/baz") },   FPL("")},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar\\baz") },   FPL("baz")},
    { { FPL("\\foo/bar"),     FPL("\\foo\\bar\\baz") },   FPL("baz")},
    { { FPL("\\foo/bar"),     FPL("\\foo/bar/baz") },     FPL("baz")},
    { { FPL("\\"),            FPL("\\foo\\bar\\baz") },   FPL("foo\\bar\\baz")},
    { { FPL(""),              FPL("\\foo\\bar\\baz") },   FPL("")},
    { { FPL("\\foo\\bar"),    FPL("\\foo2\\bar\\baz") },  FPL("")},
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar2\\baz") },  FPL("")},
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  const FilePath base(FPL("blah"));

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath parent(cases[i].inputs[0]);
    FilePath child(cases[i].inputs[1]);
    {
      FilePath result;
      bool success = parent.AppendRelativePath(child, &result);
      EXPECT_EQ(cases[i].expected[0] != '\0', success) <<
        "i: " << i << ", parent: " << parent.value() << ", child: " <<
        child.value();
      EXPECT_STREQ(cases[i].expected, result.value().c_str()) <<
        "i: " << i << ", parent: " << parent.value() << ", child: " <<
        child.value();
    }
    {
      FilePath result(base);
      bool success = parent.AppendRelativePath(child, &result);
      EXPECT_EQ(cases[i].expected[0] != '\0', success) <<
        "i: " << i << ", parent: " << parent.value() << ", child: " <<
        child.value();
      EXPECT_EQ(base.Append(cases[i].expected).value(), result.value()) <<
        "i: " << i << ", parent: " << parent.value() << ", child: " <<
        child.value();
    }
  }
}

TEST_F(FilePathTest, EqualityTest) {
  const struct BinaryBooleanTestData cases[] = {
    { { FPL("/foo/bar/baz"),  FPL("/foo/bar/baz") },      true},
    { { FPL("/foo/bar"),      FPL("/foo/bar/baz") },      false},
    { { FPL("/foo/bar/baz"),  FPL("/foo/bar") },          false},
    { { FPL("//foo/bar/"),    FPL("//foo/bar/") },        true},
    { { FPL("/foo/bar"),      FPL("/foo2/bar") },         false},
    { { FPL("/foo/bar.txt"),  FPL("/foo/bar") },          false},
    { { FPL("foo/bar"),       FPL("foo/bar") },           true},
    { { FPL("foo/bar"),       FPL("foo/bar/baz") },       false},
    { { FPL(""),              FPL("foo") },               false},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:/foo/bar"),    FPL("c:/foo/bar") },        true},
    { { FPL("E:/foo/bar"),    FPL("e:/foo/bar") },        true},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/bar") },        true},
    { { FPL("E:/Foo/bar"),    FPL("e:/foo/bar") },        false},
    { { FPL("f:/foo/bar"),    FPL("F:/foo/Bar") },        false},
    { { FPL("c:/"),           FPL("c:/") },               true},
    { { FPL("c:"),            FPL("c:") },                true},
    { { FPL("c:/foo/bar"),    FPL("d:/foo/bar") },        false},
    { { FPL("c:/foo/bar"),    FPL("D:/foo/bar") },        false},
    { { FPL("C:/foo/bar"),    FPL("d:/foo/bar") },        false},
    { { FPL("c:/foo/bar"),    FPL("c:/foo2/bar") },       false},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar") },        true},
    { { FPL("\\foo/bar"),     FPL("\\foo/bar") },         true},
    { { FPL("\\foo/bar"),     FPL("\\foo\\bar") },        false},
    { { FPL("\\"),            FPL("\\") },                true},
    { { FPL("\\"),            FPL("/") },                 false},
    { { FPL(""),              FPL("\\") },                false},
    { { FPL("\\foo\\bar"),    FPL("\\foo2\\bar") },       false},
    { { FPL("\\foo\\bar"),    FPL("\\foo\\bar2") },       false},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:\\foo\\bar"),    FPL("c:\\foo\\bar") },    true},
    { { FPL("E:\\foo\\bar"),    FPL("e:\\foo\\bar") },    true},
    { { FPL("f:\\foo\\bar"),    FPL("F:\\foo/bar") },     false},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#endif  // FILE_PATH_USES_WIN_SEPARATORS
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath a(cases[i].inputs[0]);
    FilePath b(cases[i].inputs[1]);

    EXPECT_EQ(a == b, cases[i].expected) <<
      "equality i: " << i << ", a: " << a.value() << ", b: " <<
      b.value();
  }

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath a(cases[i].inputs[0]);
    FilePath b(cases[i].inputs[1]);

    EXPECT_EQ(a != b, !cases[i].expected) <<
      "inequality i: " << i << ", a: " << a.value() << ", b: " <<
      b.value();
  }
}

TEST_F(FilePathTest, Extension) {
  FilePath base_dir(FILE_PATH_LITERAL("base_dir"));

  FilePath jpg = base_dir.Append(FILE_PATH_LITERAL("foo.jpg"));
  EXPECT_EQ(FILE_PATH_LITERAL(".jpg"), jpg.Extension());
  EXPECT_EQ(FILE_PATH_LITERAL(".jpg"), jpg.FinalExtension());

  FilePath base = jpg.BaseName().RemoveExtension();
  EXPECT_EQ(FILE_PATH_LITERAL("foo"), base.value());

  FilePath path_no_ext = base_dir.Append(base);
  EXPECT_EQ(path_no_ext.value(), jpg.RemoveExtension().value());

  EXPECT_EQ(path_no_ext.value(), path_no_ext.RemoveExtension().value());
  EXPECT_EQ(FILE_PATH_LITERAL(""), path_no_ext.Extension());
  EXPECT_EQ(FILE_PATH_LITERAL(""), path_no_ext.FinalExtension());
}

TEST_F(FilePathTest, Extension2) {
  const struct UnaryTestData cases[] = {
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("C:\\a\\b\\c.ext"),        FPL(".ext") },
    { FPL("C:\\a\\b\\c."),           FPL(".") },
    { FPL("C:\\a\\b\\c"),            FPL("") },
    { FPL("C:\\a\\b\\"),             FPL("") },
    { FPL("C:\\a\\b.\\"),            FPL(".") },
    { FPL("C:\\a\\b\\c.ext1.ext2"),  FPL(".ext2") },
    { FPL("C:\\foo.bar\\\\\\"),      FPL(".bar") },
    { FPL("C:\\foo.bar\\.."),        FPL("") },
    { FPL("C:\\foo.bar\\..\\\\"),    FPL("") },
#endif
    { FPL("/foo/bar/baz.ext"),       FPL(".ext") },
    { FPL("/foo/bar/baz."),          FPL(".") },
    { FPL("/foo/bar/baz.."),         FPL(".") },
    { FPL("/foo/bar/baz"),           FPL("") },
    { FPL("/foo/bar/"),              FPL("") },
    { FPL("/foo/bar./"),             FPL(".") },
    { FPL("/foo/bar/baz.ext1.ext2"), FPL(".ext2") },
    { FPL("/subversion-1.6.12.zip"), FPL(".zip") },
    { FPL("/foo.12345.gz"),          FPL(".gz") },
    { FPL("/foo..gz"),               FPL(".gz") },
    { FPL("."),                      FPL("") },
    { FPL(".."),                     FPL("") },
    { FPL("./foo"),                  FPL("") },
    { FPL("./foo.ext"),              FPL(".ext") },
    { FPL("/foo.ext1/bar.ext2"),     FPL(".ext2") },
    { FPL("/foo.bar////"),           FPL(".bar") },
    { FPL("/foo.bar/.."),            FPL("") },
    { FPL("/foo.bar/..////"),        FPL("") },
    { FPL("/foo.1234.luser.js"),     FPL(".js") },
    { FPL("/user.js"),               FPL(".js") },
  };
  const struct UnaryTestData double_extension_cases[] = {
    { FPL("/foo.tar.gz"),            FPL(".tar.gz") },
    { FPL("/foo.tar.Z"),             FPL(".tar.Z") },
    { FPL("/foo.tar.bz2"),           FPL(".tar.bz2") },
    { FPL("/foo.1234.gz"),           FPL(".1234.gz") },
    { FPL("/foo.1234.tar.gz"),       FPL(".tar.gz") },
    { FPL("/foo.tar.tar.gz"),        FPL(".tar.gz") },
    { FPL("/foo.tar.gz.gz"),         FPL(".gz.gz") },
    { FPL("/foo.1234.user.js"),      FPL(".user.js") },
    { FPL("foo.user.js"),            FPL(".user.js") },
    { FPL("/foo.tar.bz"),            FPL(".tar.bz") },
  };
  for (unsigned int i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].input);
    FilePath::StringType extension = path.Extension();
    FilePath::StringType final_extension = path.FinalExtension();
    EXPECT_STREQ(cases[i].expected, extension.c_str())
        << "i: " << i << ", path: " << path.value();
    EXPECT_STREQ(cases[i].expected, final_extension.c_str())
        << "i: " << i << ", path: " << path.value();
  }
  for (unsigned int i = 0; i < arraysize(double_extension_cases); ++i) {
    FilePath path(double_extension_cases[i].input);
    FilePath::StringType extension = path.Extension();
    EXPECT_STREQ(double_extension_cases[i].expected, extension.c_str())
        << "i: " << i << ", path: " << path.value();
  }
}

TEST_F(FilePathTest, InsertBeforeExtension) {
  const struct BinaryTestData cases[] = {
    { { FPL(""),                FPL("") },        FPL("") },
    { { FPL(""),                FPL("txt") },     FPL("") },
    { { FPL("."),               FPL("txt") },     FPL("") },
    { { FPL(".."),              FPL("txt") },     FPL("") },
    { { FPL("foo.dll"),         FPL("txt") },     FPL("footxt.dll") },
    { { FPL("."),               FPL("") },        FPL(".") },
    { { FPL("foo.dll"),         FPL(".txt") },    FPL("foo.txt.dll") },
    { { FPL("foo"),             FPL("txt") },     FPL("footxt") },
    { { FPL("foo"),             FPL(".txt") },    FPL("foo.txt") },
    { { FPL("foo.baz.dll"),     FPL("txt") },     FPL("foo.baztxt.dll") },
    { { FPL("foo.baz.dll"),     FPL(".txt") },    FPL("foo.baz.txt.dll") },
    { { FPL("foo.dll"),         FPL("") },        FPL("foo.dll") },
    { { FPL("foo.dll"),         FPL(".") },       FPL("foo..dll") },
    { { FPL("foo"),             FPL("") },        FPL("foo") },
    { { FPL("foo"),             FPL(".") },       FPL("foo.") },
    { { FPL("foo.baz.dll"),     FPL("") },        FPL("foo.baz.dll") },
    { { FPL("foo.baz.dll"),     FPL(".") },       FPL("foo.baz..dll") },
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("\\"),              FPL("") },        FPL("\\") },
    { { FPL("\\"),              FPL("txt") },     FPL("\\txt") },
    { { FPL("\\."),             FPL("txt") },     FPL("") },
    { { FPL("\\.."),            FPL("txt") },     FPL("") },
    { { FPL("\\."),             FPL("") },        FPL("\\.") },
    { { FPL("C:\\bar\\foo.dll"), FPL("txt") },
        FPL("C:\\bar\\footxt.dll") },
    { { FPL("C:\\bar.baz\\foodll"), FPL("txt") },
        FPL("C:\\bar.baz\\foodlltxt") },
    { { FPL("C:\\bar.baz\\foo.dll"), FPL("txt") },
        FPL("C:\\bar.baz\\footxt.dll") },
    { { FPL("C:\\bar.baz\\foo.dll.exe"), FPL("txt") },
        FPL("C:\\bar.baz\\foo.dlltxt.exe") },
    { { FPL("C:\\bar.baz\\foo"), FPL("") },
        FPL("C:\\bar.baz\\foo") },
    { { FPL("C:\\bar.baz\\foo.exe"), FPL("") },
        FPL("C:\\bar.baz\\foo.exe") },
    { { FPL("C:\\bar.baz\\foo.dll.exe"), FPL("") },
        FPL("C:\\bar.baz\\foo.dll.exe") },
    { { FPL("C:\\bar\\baz\\foo.exe"), FPL(" (1)") },
        FPL("C:\\bar\\baz\\foo (1).exe") },
    { { FPL("C:\\foo.baz\\\\"), FPL(" (1)") },    FPL("C:\\foo (1).baz") },
    { { FPL("C:\\foo.baz\\..\\"), FPL(" (1)") },  FPL("") },
#endif
    { { FPL("/"),               FPL("") },        FPL("/") },
    { { FPL("/"),               FPL("txt") },     FPL("/txt") },
    { { FPL("/."),              FPL("txt") },     FPL("") },
    { { FPL("/.."),             FPL("txt") },     FPL("") },
    { { FPL("/."),              FPL("") },        FPL("/.") },
    { { FPL("/bar/foo.dll"),    FPL("txt") },     FPL("/bar/footxt.dll") },
    { { FPL("/bar.baz/foodll"), FPL("txt") },     FPL("/bar.baz/foodlltxt") },
    { { FPL("/bar.baz/foo.dll"), FPL("txt") },    FPL("/bar.baz/footxt.dll") },
    { { FPL("/bar.baz/foo.dll.exe"), FPL("txt") },
        FPL("/bar.baz/foo.dlltxt.exe") },
    { { FPL("/bar.baz/foo"),    FPL("") },        FPL("/bar.baz/foo") },
    { { FPL("/bar.baz/foo.exe"), FPL("") },       FPL("/bar.baz/foo.exe") },
    { { FPL("/bar.baz/foo.dll.exe"), FPL("") },   FPL("/bar.baz/foo.dll.exe") },
    { { FPL("/bar/baz/foo.exe"), FPL(" (1)") },   FPL("/bar/baz/foo (1).exe") },
    { { FPL("/bar/baz/..////"), FPL(" (1)") },    FPL("") },
  };
  for (unsigned int i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].inputs[0]);
    FilePath result = path.InsertBeforeExtension(cases[i].inputs[1]);
    EXPECT_EQ(cases[i].expected, result.value()) << "i: " << i <<
        ", path: " << path.value() << ", insert: " << cases[i].inputs[1];
  }
}

TEST_F(FilePathTest, RemoveExtension) {
  const struct UnaryTestData cases[] = {
    { FPL(""),                    FPL("") },
    { FPL("."),                   FPL(".") },
    { FPL(".."),                  FPL("..") },
    { FPL("foo.dll"),             FPL("foo") },
    { FPL("./foo.dll"),           FPL("./foo") },
    { FPL("foo..dll"),            FPL("foo.") },
    { FPL("foo"),                 FPL("foo") },
    { FPL("foo."),                FPL("foo") },
    { FPL("foo.."),               FPL("foo.") },
    { FPL("foo.baz.dll"),         FPL("foo.baz") },
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { FPL("C:\\foo.bar\\foo"),    FPL("C:\\foo.bar\\foo") },
    { FPL("C:\\foo.bar\\..\\\\"), FPL("C:\\foo.bar\\..\\\\") },
#endif
    { FPL("/foo.bar/foo"),        FPL("/foo.bar/foo") },
    { FPL("/foo.bar/..////"),     FPL("/foo.bar/..////") },
  };
  for (unsigned int i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].input);
    FilePath removed = path.RemoveExtension();
    FilePath removed_final = path.RemoveFinalExtension();
    EXPECT_EQ(cases[i].expected, removed.value()) << "i: " << i <<
        ", path: " << path.value();
    EXPECT_EQ(cases[i].expected, removed_final.value()) << "i: " << i <<
        ", path: " << path.value();
  }
  {
    FilePath path(FPL("foo.tar.gz"));
    FilePath removed = path.RemoveExtension();
    FilePath removed_final = path.RemoveFinalExtension();
    EXPECT_EQ(FPL("foo"), removed.value()) << ", path: " << path.value();
    EXPECT_EQ(FPL("foo.tar"), removed_final.value()) << ", path: "
                                                     << path.value();
  }
}

TEST_F(FilePathTest, ReplaceExtension) {
  const struct BinaryTestData cases[] = {
    { { FPL(""),              FPL("") },      FPL("") },
    { { FPL(""),              FPL("txt") },   FPL("") },
    { { FPL("."),             FPL("txt") },   FPL("") },
    { { FPL(".."),            FPL("txt") },   FPL("") },
    { { FPL("."),             FPL("") },      FPL("") },
    { { FPL("foo.dll"),       FPL("txt") },   FPL("foo.txt") },
    { { FPL("./foo.dll"),     FPL("txt") },   FPL("./foo.txt") },
    { { FPL("foo..dll"),      FPL("txt") },   FPL("foo..txt") },
    { { FPL("foo.dll"),       FPL(".txt") },  FPL("foo.txt") },
    { { FPL("foo"),           FPL("txt") },   FPL("foo.txt") },
    { { FPL("foo."),          FPL("txt") },   FPL("foo.txt") },
    { { FPL("foo.."),         FPL("txt") },   FPL("foo..txt") },
    { { FPL("foo"),           FPL(".txt") },  FPL("foo.txt") },
    { { FPL("foo.baz.dll"),   FPL("txt") },   FPL("foo.baz.txt") },
    { { FPL("foo.baz.dll"),   FPL(".txt") },  FPL("foo.baz.txt") },
    { { FPL("foo.dll"),       FPL("") },      FPL("foo") },
    { { FPL("foo.dll"),       FPL(".") },     FPL("foo") },
    { { FPL("foo"),           FPL("") },      FPL("foo") },
    { { FPL("foo"),           FPL(".") },     FPL("foo") },
    { { FPL("foo.baz.dll"),   FPL("") },      FPL("foo.baz") },
    { { FPL("foo.baz.dll"),   FPL(".") },     FPL("foo.baz") },
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("C:\\foo.bar\\foo"),    FPL("baz") }, FPL("C:\\foo.bar\\foo.baz") },
    { { FPL("C:\\foo.bar\\..\\\\"), FPL("baz") }, FPL("") },
#endif
    { { FPL("/foo.bar/foo"),        FPL("baz") }, FPL("/foo.bar/foo.baz") },
    { { FPL("/foo.bar/..////"),     FPL("baz") }, FPL("") },
  };
  for (unsigned int i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].inputs[0]);
    FilePath replaced = path.ReplaceExtension(cases[i].inputs[1]);
    EXPECT_EQ(cases[i].expected, replaced.value()) << "i: " << i <<
        ", path: " << path.value() << ", replace: " << cases[i].inputs[1];
  }
}

TEST_F(FilePathTest, AddExtension) {
  const struct BinaryTestData cases[] = {
    { { FPL(""),              FPL("") },      FPL("") },
    { { FPL(""),              FPL("txt") },   FPL("") },
    { { FPL("."),             FPL("txt") },   FPL("") },
    { { FPL(".."),            FPL("txt") },   FPL("") },
    { { FPL("."),             FPL("") },      FPL("") },
    { { FPL("foo.dll"),       FPL("txt") },   FPL("foo.dll.txt") },
    { { FPL("./foo.dll"),     FPL("txt") },   FPL("./foo.dll.txt") },
    { { FPL("foo..dll"),      FPL("txt") },   FPL("foo..dll.txt") },
    { { FPL("foo.dll"),       FPL(".txt") },  FPL("foo.dll.txt") },
    { { FPL("foo"),           FPL("txt") },   FPL("foo.txt") },
    { { FPL("foo."),          FPL("txt") },   FPL("foo.txt") },
    { { FPL("foo.."),         FPL("txt") },   FPL("foo..txt") },
    { { FPL("foo"),           FPL(".txt") },  FPL("foo.txt") },
    { { FPL("foo.baz.dll"),   FPL("txt") },   FPL("foo.baz.dll.txt") },
    { { FPL("foo.baz.dll"),   FPL(".txt") },  FPL("foo.baz.dll.txt") },
    { { FPL("foo.dll"),       FPL("") },      FPL("foo.dll") },
    { { FPL("foo.dll"),       FPL(".") },     FPL("foo.dll") },
    { { FPL("foo"),           FPL("") },      FPL("foo") },
    { { FPL("foo"),           FPL(".") },     FPL("foo") },
    { { FPL("foo.baz.dll"),   FPL("") },      FPL("foo.baz.dll") },
    { { FPL("foo.baz.dll"),   FPL(".") },     FPL("foo.baz.dll") },
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("C:\\foo.bar\\foo"),    FPL("baz") }, FPL("C:\\foo.bar\\foo.baz") },
    { { FPL("C:\\foo.bar\\..\\\\"), FPL("baz") }, FPL("") },
#endif
    { { FPL("/foo.bar/foo"),        FPL("baz") }, FPL("/foo.bar/foo.baz") },
    { { FPL("/foo.bar/..////"),     FPL("baz") }, FPL("") },
  };
  for (unsigned int i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].inputs[0]);
    FilePath added = path.AddExtension(cases[i].inputs[1]);
    EXPECT_EQ(cases[i].expected, added.value()) << "i: " << i <<
        ", path: " << path.value() << ", add: " << cases[i].inputs[1];
  }
}

TEST_F(FilePathTest, MatchesExtension) {
  const struct BinaryBooleanTestData cases[] = {
    { { FPL("foo"),                     FPL("") },                    true},
    { { FPL("foo"),                     FPL(".") },                   false},
    { { FPL("foo."),                    FPL("") },                    false},
    { { FPL("foo."),                    FPL(".") },                   true},
    { { FPL("foo.txt"),                 FPL(".dll") },                false},
    { { FPL("foo.txt"),                 FPL(".txt") },                true},
    { { FPL("foo.txt.dll"),             FPL(".txt") },                false},
    { { FPL("foo.txt.dll"),             FPL(".dll") },                true},
    { { FPL("foo.TXT"),                 FPL(".txt") },                true},
    { { FPL("foo.txt"),                 FPL(".TXT") },                true},
    { { FPL("foo.tXt"),                 FPL(".txt") },                true},
    { { FPL("foo.txt"),                 FPL(".tXt") },                true},
    { { FPL("foo.tXt"),                 FPL(".TXT") },                true},
    { { FPL("foo.tXt"),                 FPL(".tXt") },                true},
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
    { { FPL("c:/foo.txt.dll"),          FPL(".txt") },                false},
    { { FPL("c:/foo.txt"),              FPL(".txt") },                true},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
    { { FPL("c:\\bar\\foo.txt.dll"),    FPL(".txt") },                false},
    { { FPL("c:\\bar\\foo.txt"),        FPL(".txt") },                true},
#endif  // FILE_PATH_USES_DRIVE_LETTERS
    { { FPL("/bar/foo.txt.dll"),        FPL(".txt") },                false},
    { { FPL("/bar/foo.txt"),            FPL(".txt") },                true},
#if defined(OS_WIN) || defined(OS_MACOSX)
    // Umlauts A, O, U: direct comparison, and upper case vs. lower case
    { { FPL("foo.\u00E4\u00F6\u00FC"),  FPL(".\u00E4\u00F6\u00FC") }, true},
    { { FPL("foo.\u00C4\u00D6\u00DC"),  FPL(".\u00E4\u00F6\u00FC") }, true},
    // C with circumflex: direct comparison, and upper case vs. lower case
    { { FPL("foo.\u0109"),              FPL(".\u0109") },             true},
    { { FPL("foo.\u0108"),              FPL(".\u0109") },             true},
#endif
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath path(cases[i].inputs[0]);
    FilePath::StringType ext(cases[i].inputs[1]);

    EXPECT_EQ(cases[i].expected, path.MatchesExtension(ext)) <<
        "i: " << i << ", path: " << path.value() << ", ext: " << ext;
  }
}

TEST_F(FilePathTest, CompareIgnoreCase) {
  const struct BinaryIntTestData cases[] = {
    { { FPL("foo"),                          FPL("foo") },                  0},
    { { FPL("FOO"),                          FPL("foo") },                  0},
    { { FPL("foo.ext"),                      FPL("foo.ext") },              0},
    { { FPL("FOO.EXT"),                      FPL("foo.ext") },              0},
    { { FPL("Foo.Ext"),                      FPL("foo.ext") },              0},
    { { FPL("foO"),                          FPL("foo") },                  0},
    { { FPL("foo"),                          FPL("foO") },                  0},
    { { FPL("fOo"),                          FPL("foo") },                  0},
    { { FPL("foo"),                          FPL("fOo") },                  0},
    { { FPL("bar"),                          FPL("foo") },                 -1},
    { { FPL("foo"),                          FPL("bar") },                  1},
    { { FPL("BAR"),                          FPL("foo") },                 -1},
    { { FPL("FOO"),                          FPL("bar") },                  1},
    { { FPL("bar"),                          FPL("FOO") },                 -1},
    { { FPL("foo"),                          FPL("BAR") },                  1},
    { { FPL("BAR"),                          FPL("FOO") },                 -1},
    { { FPL("FOO"),                          FPL("BAR") },                  1},
    // German "Eszett" (lower case and the new-fangled upper case)
    // Note that uc(<lowercase eszett>) => "SS", NOT <uppercase eszett>!
    // However, neither Windows nor Mac OSX converts these.
    // (or even have glyphs for <uppercase eszett>)
    { { FPL("\u00DF"),                       FPL("\u00DF") },               0},
    { { FPL("\u1E9E"),                       FPL("\u1E9E") },               0},
    { { FPL("\u00DF"),                       FPL("\u1E9E") },              -1},
    { { FPL("SS"),                           FPL("\u00DF") },              -1},
    { { FPL("SS"),                           FPL("\u1E9E") },              -1},
#if defined(OS_WIN) || defined(OS_MACOSX)
    // Umlauts A, O, U: direct comparison, and upper case vs. lower case
    { { FPL("\u00E4\u00F6\u00FC"),           FPL("\u00E4\u00F6\u00FC") },   0},
    { { FPL("\u00C4\u00D6\u00DC"),           FPL("\u00E4\u00F6\u00FC") },   0},
    // C with circumflex: direct comparison, and upper case vs. lower case
    { { FPL("\u0109"),                       FPL("\u0109") },               0},
    { { FPL("\u0108"),                       FPL("\u0109") },               0},
    // Cyrillic letter SHA: direct comparison, and upper case vs. lower case
    { { FPL("\u0428"),                       FPL("\u0428") },               0},
    { { FPL("\u0428"),                       FPL("\u0448") },               0},
    // Greek letter DELTA: direct comparison, and upper case vs. lower case
    { { FPL("\u0394"),                       FPL("\u0394") },               0},
    { { FPL("\u0394"),                       FPL("\u03B4") },               0},
    // Japanese full-width A: direct comparison, and upper case vs. lower case
    // Note that full-width and standard characters are considered different.
    { { FPL("\uFF21"),                       FPL("\uFF21") },               0},
    { { FPL("\uFF21"),                       FPL("\uFF41") },               0},
    { { FPL("A"),                            FPL("\uFF21") },              -1},
    { { FPL("A"),                            FPL("\uFF41") },              -1},
    { { FPL("a"),                            FPL("\uFF21") },              -1},
    { { FPL("a"),                            FPL("\uFF41") },              -1},
#endif
#if defined(OS_MACOSX)
    // Codepoints > 0x1000
    // Georgian letter DON: direct comparison, and upper case vs. lower case
    { { FPL("\u10A3"),                       FPL("\u10A3") },               0},
    { { FPL("\u10A3"),                       FPL("\u10D3") },               0},
    // Combining characters vs. pre-composed characters, upper and lower case
    { { FPL("k\u0301u\u032Do\u0304\u0301n"), FPL("\u1E31\u1E77\u1E53n") },  0},
    { { FPL("k\u0301u\u032Do\u0304\u0301n"), FPL("kuon") },                 1},
    { { FPL("kuon"), FPL("k\u0301u\u032Do\u0304\u0301n") },                -1},
    { { FPL("K\u0301U\u032DO\u0304\u0301N"), FPL("KUON") },                 1},
    { { FPL("KUON"), FPL("K\u0301U\u032DO\u0304\u0301N") },                -1},
    { { FPL("k\u0301u\u032Do\u0304\u0301n"), FPL("KUON") },                 1},
    { { FPL("K\u0301U\u032DO\u0304\u0301N"), FPL("\u1E31\u1E77\u1E53n") },  0},
    { { FPL("k\u0301u\u032Do\u0304\u0301n"), FPL("\u1E30\u1E76\u1E52n") },  0},
    { { FPL("k\u0301u\u032Do\u0304\u0302n"), FPL("\u1E30\u1E76\u1E52n") },  1},
#endif
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath::StringType s1(cases[i].inputs[0]);
    FilePath::StringType s2(cases[i].inputs[1]);
    int result = FilePath::CompareIgnoreCase(s1, s2);
    EXPECT_EQ(cases[i].expected, result) <<
        "i: " << i << ", s1: " << s1 << ", s2: " << s2;
  }
}

TEST_F(FilePathTest, ReferencesParent) {
  const struct UnaryBooleanTestData cases[] = {
    { FPL("."),        false },
    { FPL(".."),       true },
    { FPL(".. "),      true },
    { FPL(" .."),      true },
    { FPL("..."),      true },
    { FPL("a.."),      false },
    { FPL("..a"),      false },
    { FPL("../"),      true },
    { FPL("/.."),      true },
    { FPL("/../"),     true },
    { FPL("/a../"),    false },
    { FPL("/..a/"),    false },
    { FPL("//.."),     true },
    { FPL("..//"),     true },
    { FPL("//..//"),   true },
    { FPL("a//..//c"), true },
    { FPL("../b/c"),   true },
    { FPL("/../b/c"),  true },
    { FPL("a/b/.."),   true },
    { FPL("a/b/../"),  true },
    { FPL("a/../c"),   true },
    { FPL("a/b/c"),    false },
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    bool observed = input.ReferencesParent();
    EXPECT_EQ(cases[i].expected, observed) <<
              "i: " << i << ", input: " << input.value();
  }
}

TEST_F(FilePathTest, FromUTF8Unsafe_And_AsUTF8Unsafe) {
  const struct UTF8TestData cases[] = {
    { FPL("foo.txt"), "foo.txt" },
    // "aeo" with accents. Use http://0xcc.net/jsescape/ to decode them.
    { FPL("\u00E0\u00E8\u00F2.txt"), "\xC3\xA0\xC3\xA8\xC3\xB2.txt" },
    // Full-width "ABC".
    { FPL("\uFF21\uFF22\uFF23.txt"),
      "\xEF\xBC\xA1\xEF\xBC\xA2\xEF\xBC\xA3.txt" },
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    // Test FromUTF8Unsafe() works.
    FilePath from_utf8 = FilePath::FromUTF8Unsafe(cases[i].utf8);
    EXPECT_EQ(cases[i].native, from_utf8.value())
        << "i: " << i << ", input: " << cases[i].native;
    // Test AsUTF8Unsafe() works.
    FilePath from_native = FilePath(cases[i].native);
    EXPECT_EQ(cases[i].utf8, from_native.AsUTF8Unsafe())
        << "i: " << i << ", input: " << cases[i].native;
    // Test the two file paths are identical.
    EXPECT_EQ(from_utf8.value(), from_native.value());
  }
}

TEST_F(FilePathTest, ConstructWithNUL) {
  // Assert FPS() works.
  ASSERT_EQ(3U, FPS("a\0b").length());

  // Test constructor strips '\0'
  FilePath path(FPS("a\0b"));
  EXPECT_EQ(1U, path.value().length());
  EXPECT_EQ(FPL("a"), path.value());
}

TEST_F(FilePathTest, AppendWithNUL) {
  // Assert FPS() works.
  ASSERT_EQ(3U, FPS("b\0b").length());

  // Test Append() strips '\0'
  FilePath path(FPL("a"));
  path = path.Append(FPS("b\0b"));
  EXPECT_EQ(3U, path.value().length());
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
  EXPECT_EQ(FPL("a\\b"), path.value());
#else
  EXPECT_EQ(FPL("a/b"), path.value());
#endif
}

TEST_F(FilePathTest, ReferencesParentWithNUL) {
  // Assert FPS() works.
  ASSERT_EQ(3U, FPS("..\0").length());

  // Test ReferencesParent() doesn't break with "..\0"
  FilePath path(FPS("..\0"));
  EXPECT_TRUE(path.ReferencesParent());
}

#if defined(FILE_PATH_USES_WIN_SEPARATORS)
TEST_F(FilePathTest, NormalizePathSeparators) {
  const struct UnaryTestData cases[] = {
    { FPL("foo/bar"), FPL("foo\\bar") },
    { FPL("foo/bar\\betz"), FPL("foo\\bar\\betz") },
    { FPL("foo\\bar"), FPL("foo\\bar") },
    { FPL("foo\\bar/betz"), FPL("foo\\bar\\betz") },
    { FPL("foo"), FPL("foo") },
    // Trailing slashes don't automatically get stripped.  That's what
    // StripTrailingSeparators() is for.
    { FPL("foo\\"), FPL("foo\\") },
    { FPL("foo/"), FPL("foo\\") },
    { FPL("foo/bar\\"), FPL("foo\\bar\\") },
    { FPL("foo\\bar/"), FPL("foo\\bar\\") },
    { FPL("foo/bar/"), FPL("foo\\bar\\") },
    { FPL("foo\\bar\\"), FPL("foo\\bar\\") },
    { FPL("\\foo/bar"), FPL("\\foo\\bar") },
    { FPL("/foo\\bar"), FPL("\\foo\\bar") },
    { FPL("c:/foo/bar/"), FPL("c:\\foo\\bar\\") },
    { FPL("/foo/bar/"), FPL("\\foo\\bar\\") },
    { FPL("\\foo\\bar\\"), FPL("\\foo\\bar\\") },
    { FPL("c:\\foo/bar"), FPL("c:\\foo\\bar") },
    { FPL("//foo\\bar\\"), FPL("\\\\foo\\bar\\") },
    { FPL("\\\\foo\\bar\\"), FPL("\\\\foo\\bar\\") },
    { FPL("//foo\\bar\\"), FPL("\\\\foo\\bar\\") },
    // This method does not normalize the number of path separators.
    { FPL("foo\\\\bar"), FPL("foo\\\\bar") },
    { FPL("foo//bar"), FPL("foo\\\\bar") },
    { FPL("foo/\\bar"), FPL("foo\\\\bar") },
    { FPL("foo\\/bar"), FPL("foo\\\\bar") },
    { FPL("///foo\\\\bar"), FPL("\\\\\\foo\\\\bar") },
    { FPL("foo//bar///"), FPL("foo\\\\bar\\\\\\") },
    { FPL("foo/\\bar/\\"), FPL("foo\\\\bar\\\\") },
    { FPL("/\\foo\\/bar"), FPL("\\\\foo\\\\bar") },
  };
  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    FilePath observed = input.NormalizePathSeparators();
    EXPECT_EQ(FilePath::StringType(cases[i].expected), observed.value()) <<
              "i: " << i << ", input: " << input.value();
  }
}
#endif

TEST_F(FilePathTest, EndsWithSeparator) {
  const UnaryBooleanTestData cases[] = {
    { FPL(""), false },
    { FPL("/"), true },
    { FPL("foo/"), true },
    { FPL("bar"), false },
    { FPL("/foo/bar"), false },
  };
  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input = FilePath(cases[i].input).NormalizePathSeparators();
    EXPECT_EQ(cases[i].expected, input.EndsWithSeparator());
  }
}

TEST_F(FilePathTest, AsEndingWithSeparator) {
  const UnaryTestData cases[] = {
    { FPL(""), FPL("") },
    { FPL("/"), FPL("/") },
    { FPL("foo"), FPL("foo/") },
    { FPL("foo/"), FPL("foo/") }
  };
  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input = FilePath(cases[i].input).NormalizePathSeparators();
    FilePath expected = FilePath(cases[i].expected).NormalizePathSeparators();
    EXPECT_EQ(expected.value(), input.AsEndingWithSeparator().value());
  }
}

#if defined(OS_ANDROID)
TEST_F(FilePathTest, ContentUriTest) {
  const struct UnaryBooleanTestData cases[] = {
    { FPL("content://foo.bar"),    true },
    { FPL("content://foo.bar/"),   true },
    { FPL("content://foo/bar"),    true },
    { FPL("CoNTenT://foo.bar"),    true },
    { FPL("content://"),           true },
    { FPL("content:///foo.bar"),   true },
    { FPL("content://3foo/bar"),   true },
    { FPL("content://_foo/bar"),   true },
    { FPL(".. "),                  false },
    { FPL("foo.bar"),              false },
    { FPL("content:foo.bar"),      false },
    { FPL("content:/foo.ba"),      false },
    { FPL("content:/dir/foo.bar"), false },
    { FPL("content: //foo.bar"),   false },
    { FPL("content%2a%2f%2f"),     false },
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    FilePath input(cases[i].input);
    bool observed = input.IsContentUri();
    EXPECT_EQ(cases[i].expected, observed) <<
              "i: " << i << ", input: " << input.value();
  }
}
#endif

// Test the PrintTo overload for FilePath (used when a test fails to compare two
// FilePaths).
TEST_F(FilePathTest, PrintTo) {
  std::stringstream ss;
  FilePath fp(FPL("foo"));
  base::PrintTo(fp, &ss);
  EXPECT_EQ("foo", ss.str());
}

}  // namespace base
