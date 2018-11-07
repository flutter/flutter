// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/string_view.h"

#include <functional>

#include "gtest/gtest.h"

namespace fml {
namespace {

#define TEST_STRING "Hello\0u"
#define TEST_STRING_LENGTH 5u

// Loops over all substrings of |needles|, and calls |callback| for each.
void LoopOverSubstrings(StringView haystack,
                        StringView needles,
                        std::function<void(std::string haystack_str,
                                           StringView haystack_sw,
                                           std::string to_find_str,
                                           StringView to_find_sw,
                                           int start_index)> callback) {
  std::string haystack_str = haystack.ToString();
  for (size_t substring_size = 0; substring_size < needles.size();
       ++substring_size) {
    for (size_t start_index = 0; start_index <= needles.size(); ++start_index) {
      auto to_find = needles.substr(start_index, substring_size);
      for (size_t start_pos = 0; start_pos <= haystack.size(); ++start_pos) {
        callback(haystack_str, haystack, to_find.ToString(), to_find,
                 start_pos);
      }
    }
  }
};

// Loops over all characters in |needles|, and calls |callback| for each.
void LoopOverChars(StringView haystack,
                   StringView needles,
                   std::function<void(std::string haystack_str,
                                      StringView haystack_sw,
                                      char c,
                                      int start_index)> callback) {
  std::string haystack_str = haystack.ToString();
  for (size_t index = 0; index < needles.size(); ++index) {
    for (size_t start_index = 0; start_index <= haystack.size();
         ++start_index) {
      callback(haystack_str, haystack, needles[index], start_index);
    }
  }
}

// Loops over all combinations of characters present in |needles|, and calls
// |callback| for each.
void LoopOverCharCombinations(StringView haystack,
                              StringView needles,
                              std::function<void(std::string haystack_str,
                                                 StringView haystack_sw,
                                                 std::string current_chars,
                                                 size_t pos)> callback) {
  // Look for all chars combinations, and compare with string.
  std::set<char> chars(needles.begin(), needles.end());
  std::string haystack_str = haystack.ToString();
  for (size_t selector = 0; selector < (1 << chars.size()); ++selector) {
    std::string current_chars;
    size_t current = selector;
    for (auto it = chars.begin(); it != chars.end(); ++it) {
      if (current & 1)
        current_chars += *it;
      current = current >> 1;
    }
    for (size_t pos = 0; pos <= haystack.size(); ++pos) {
      callback(haystack_str, haystack, current_chars, pos);
    }
  }
}

TEST(StringView, Constructors) {
  std::string str1("Hello");
  StringView sw1(str1);
  EXPECT_EQ(str1.data(), sw1.data());
  EXPECT_EQ(str1.size(), sw1.size());
  EXPECT_EQ(TEST_STRING_LENGTH, sw1.size());

  const char* str2 = str1.data();
  StringView sw2(str2);
  EXPECT_EQ(str1.data(), sw2.data());
  EXPECT_EQ(TEST_STRING_LENGTH, sw2.size());
}

TEST(StringView, ConstExprConstructors) {
  constexpr StringView sw1;
  EXPECT_EQ(0u, sw1.size());

  constexpr StringView sw2(sw1);
  EXPECT_EQ(0u, sw2.size());
  EXPECT_EQ(sw1.data(), sw2.data());

  constexpr StringView sw3(TEST_STRING, TEST_STRING_LENGTH);
  EXPECT_EQ(TEST_STRING_LENGTH, sw3.size());

  constexpr StringView sw4(TEST_STRING);
  EXPECT_EQ(TEST_STRING_LENGTH, sw4.size());

  constexpr const char* string_ptr = TEST_STRING;
  constexpr StringView sw5(string_ptr);
  EXPECT_EQ(TEST_STRING_LENGTH, sw5.size());
}

TEST(StringView, CopyOperator) {
  StringView sw1;

  StringView sw2(TEST_STRING);
  sw1 = sw2;
  EXPECT_EQ(sw2.data(), sw1.data());

  sw1 = TEST_STRING;
  EXPECT_EQ(TEST_STRING_LENGTH, sw1.size());

  sw1 = std::string(TEST_STRING);
  EXPECT_EQ(TEST_STRING_LENGTH, sw1.size());
}

TEST(StringView, CapacityMethods) {
  StringView sw1;
  EXPECT_EQ(0u, sw1.size());
  EXPECT_TRUE(sw1.empty());

  StringView sw2(TEST_STRING);
  EXPECT_EQ(TEST_STRING_LENGTH, sw2.size());
  EXPECT_FALSE(sw2.empty());
}

TEST(StringView, AccessMethods) {
  const char* str = TEST_STRING;
  StringView sw1(str);

  EXPECT_EQ('H', sw1.front());
  EXPECT_EQ('e', sw1[1]);
  EXPECT_EQ('l', sw1.at(2));
  EXPECT_EQ('o', sw1.back());
  EXPECT_EQ(str, sw1.data());
}

TEST(StringView, Iterators) {
  StringView sw1(TEST_STRING);

  std::string str1(sw1.begin(), sw1.end());
  EXPECT_EQ(TEST_STRING, str1);

  std::string str2(sw1.cbegin(), sw1.cend());
  EXPECT_EQ(TEST_STRING, str2);

  std::string str3(sw1.rbegin(), sw1.rend());
  EXPECT_EQ("olleH", str3);

  std::string str4(sw1.crbegin(), sw1.crend());
  EXPECT_EQ("olleH", str4);
}

TEST(StringView, Modifiers) {
  StringView sw1(TEST_STRING);

  sw1.remove_prefix(1);
  EXPECT_EQ("ello", sw1.ToString());

  sw1.remove_suffix(1);
  EXPECT_EQ("ell", sw1.ToString());

  sw1.clear();
  EXPECT_EQ(0u, sw1.size());

  StringView sw2(TEST_STRING);
  sw1.swap(sw2);
  EXPECT_EQ(0u, sw2.size());
  EXPECT_EQ(TEST_STRING, sw1.ToString());
}

TEST(StringView, SubString) {
  StringView sw1(TEST_STRING);

  StringView sw2 = sw1.substr(1, 2);
  EXPECT_EQ("el", sw2.ToString());
}

TEST(StringView, Compare) {
  StringView sw1(TEST_STRING);
  StringView sw2(TEST_STRING);

  EXPECT_EQ(0, sw1.compare(sw2));

  sw1 = "a";
  sw2 = "b";
  EXPECT_GT(0, sw1.compare(sw2));
  EXPECT_LT(0, sw2.compare(sw1));

  sw1 = "a";
  sw2 = "aa";
  EXPECT_GT(0, sw1.compare(sw2));
  EXPECT_LT(0, sw2.compare(sw1));

  std::string str1("a\0a", 3);
  std::string str2("a\0b", 3);
  sw1 = str1;
  sw2 = str2;

  EXPECT_GT(0, sw1.compare(sw2));
  EXPECT_LT(0, sw2.compare(sw1));
}

TEST(StringView, ComparaisonFunctions) {
  StringView sw1 = "a";
  StringView sw2 = "b";

  EXPECT_TRUE(sw1 == sw1);
  EXPECT_FALSE(sw1 == sw2);
  EXPECT_FALSE(sw1 != sw1);
  EXPECT_TRUE(sw1 != sw2);

  EXPECT_TRUE(sw1 < sw2);
  EXPECT_FALSE(sw2 < sw1);
  EXPECT_TRUE(sw1 <= sw1);
  EXPECT_TRUE(sw1 <= sw2);
  EXPECT_FALSE(sw2 <= sw1);

  EXPECT_TRUE(sw2 > sw1);
  EXPECT_FALSE(sw1 > sw2);
  EXPECT_TRUE(sw1 >= sw1);
  EXPECT_TRUE(sw2 >= sw1);
  EXPECT_FALSE(sw1 >= sw2);
}

TEST(StringView, Stream) {
  StringView sw1(TEST_STRING);

  std::stringstream ss;
  ss << sw1;
  EXPECT_EQ(TEST_STRING, ss.str());
}

TEST(StringView, find_String) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find("z"));
  EXPECT_EQ(StringView::npos, sw.find("  "));
  EXPECT_EQ(StringView::npos, sw.find("lll"));
  EXPECT_EQ(StringView::npos, sw.find("H", 1));
  EXPECT_EQ(StringView::npos, sw.find("H", 255));
  EXPECT_EQ(StringView::npos, sw.find("H", sw.size()));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string to_find_str, StringView to_find_sw,
                          int start_index) {
    EXPECT_EQ(haystack_str.find(to_find_str, start_index),
              haystack_sw.find(to_find_sw, start_index));
  };
  LoopOverSubstrings(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverSubstrings(sw, other_sw, test_callback);
}

TEST(StringView, find_Chars) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find('z'));
  EXPECT_EQ(StringView::npos, sw.find('H', 1));
  EXPECT_EQ(StringView::npos, sw.find('H', 255));
  EXPECT_EQ(StringView::npos, sw.find('H', sw.size()));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          char c, int start_index) {
    EXPECT_EQ(haystack_str.find(c, start_index),
              haystack_sw.find(c, start_index));
  };

  // Look for all chars at all position, and compare with string.
  LoopOverChars(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverChars(sw, other_sw, test_callback);
}

TEST(StringView, rfind_String) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.rfind("z"));
  EXPECT_EQ(StringView::npos, sw.rfind("  "));
  EXPECT_EQ(StringView::npos, sw.rfind("lll"));
  EXPECT_EQ(StringView::npos, sw.rfind("d", sw.size() - 2));
  EXPECT_EQ(StringView::npos, sw.rfind("d", 0));
  EXPECT_EQ(StringView::npos, sw.rfind("d", 1));

  // Look for all substring at all position, and compare with string.
  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string to_find_str, StringView to_find_sw,
                          int start_index) {
    EXPECT_EQ(haystack_str.rfind(to_find_str, start_index),
              haystack_sw.rfind(to_find_sw, start_index));
  };
  LoopOverSubstrings(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverSubstrings(sw, other_sw, test_callback);
}

TEST(StringView, rfind_Char) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.rfind('z'));
  EXPECT_EQ(StringView::npos, sw.rfind('d', sw.size() - 2));
  EXPECT_EQ(StringView::npos, sw.rfind('d', 0));
  EXPECT_EQ(StringView::npos, sw.rfind('d', 1));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          char c, int start_index) {
    EXPECT_EQ(haystack_str.rfind(c, start_index),
              haystack_sw.rfind(c, start_index));
  };

  // Look for all chars at all position, and compare with string.
  LoopOverChars(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverChars(sw, other_sw, test_callback);
}

TEST(StringView, find_first_of) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find_first_of(""));
  EXPECT_EQ(StringView::npos, sw.find_first_of(std::string("xyz")));
  EXPECT_EQ(StringView::npos, sw.find_first_of("xyHz", 1));
  EXPECT_EQ(StringView::npos, sw.find_first_of("Hello World", sw.size()));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string current_chars, size_t pos) {
    EXPECT_EQ(haystack_str.find_first_of(current_chars, pos),
              haystack_sw.find_first_of(current_chars, pos));
  };

  // Look for all chars combinations, and compare with string.
  LoopOverCharCombinations(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverCharCombinations(sw, other_sw, test_callback);
}

TEST(StringView, find_last_of) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find_last_of(""));
  EXPECT_EQ(StringView::npos, sw.find_last_of(std::string("xyz")));
  EXPECT_EQ(StringView::npos, sw.find_last_of("xydz", 1));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string current_chars, size_t pos) {
    EXPECT_EQ(haystack_str.find_last_of(current_chars, pos),
              haystack_sw.find_last_of(current_chars, pos));
  };

  // Look for all chars combinations, and compare with string.
  LoopOverCharCombinations(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverCharCombinations(sw, other_sw, test_callback);
}

TEST(StringView, find_first_not_of) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find_first_not_of("Helo Wrd"));
  EXPECT_EQ(StringView::npos, sw.find_first_not_of("elo Wrd", 1));
  EXPECT_EQ(StringView::npos, sw.find_first_not_of("", sw.size()));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string current_chars, size_t pos) {
    EXPECT_EQ(haystack_str.find_first_not_of(current_chars, pos),
              haystack_sw.find_first_not_of(current_chars, pos));
  };

  // Look for all chars combinations, and compare with string.
  LoopOverCharCombinations(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverCharCombinations(sw, other_sw, test_callback);
}

TEST(StringView, find_last_not_of) {
  StringView sw("Hello World");

  EXPECT_EQ(StringView::npos, sw.find_last_not_of("Helo Wrd"));
  EXPECT_EQ(StringView::npos, sw.find_last_not_of("H", 0));

  auto test_callback = [](std::string haystack_str, StringView haystack_sw,
                          std::string current_chars, size_t pos) {
    EXPECT_EQ(haystack_str.find_last_not_of(current_chars, pos),
              haystack_sw.find_last_not_of(current_chars, pos));
  };

  // Look for all chars combinations, and compare with string.
  LoopOverCharCombinations(sw, sw, test_callback);

  // Use another string for negative examples.
  StringView other_sw("Fuchsia World");
  LoopOverCharCombinations(sw, other_sw, test_callback);
}

}  // namespace
}  // namespace fml
