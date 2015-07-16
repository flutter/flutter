// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/strings/string16.h"
#include "base/strings/string_piece.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

template <typename T>
class CommonStringPieceTest : public ::testing::Test {
 public:
  static const T as_string(const char* input) {
    return T(input);
  }
  static const T& as_string(const T& input) {
    return input;
  }
};

template <>
class CommonStringPieceTest<string16> : public ::testing::Test {
 public:
  static const string16 as_string(const char* input) {
    return ASCIIToUTF16(input);
  }
  static const string16 as_string(const std::string& input) {
    return ASCIIToUTF16(input);
  }
};

typedef ::testing::Types<std::string, string16> SupportedStringTypes;

TYPED_TEST_CASE(CommonStringPieceTest, SupportedStringTypes);

TYPED_TEST(CommonStringPieceTest, CheckComparisonOperators) {
#define CMP_Y(op, x, y)                                                    \
  {                                                                        \
    TypeParam lhs(TestFixture::as_string(x));                              \
    TypeParam rhs(TestFixture::as_string(y));                              \
    ASSERT_TRUE( (BasicStringPiece<TypeParam>((lhs.c_str())) op            \
                  BasicStringPiece<TypeParam>((rhs.c_str()))));            \
    ASSERT_TRUE( (BasicStringPiece<TypeParam>((lhs.c_str())).compare(      \
                      BasicStringPiece<TypeParam>((rhs.c_str()))) op 0));  \
  }

#define CMP_N(op, x, y)                                                    \
  {                                                                        \
    TypeParam lhs(TestFixture::as_string(x));                              \
    TypeParam rhs(TestFixture::as_string(y));                              \
    ASSERT_FALSE( (BasicStringPiece<TypeParam>((lhs.c_str())) op           \
                  BasicStringPiece<TypeParam>((rhs.c_str()))));            \
    ASSERT_FALSE( (BasicStringPiece<TypeParam>((lhs.c_str())).compare(     \
                      BasicStringPiece<TypeParam>((rhs.c_str()))) op 0));  \
  }

  CMP_Y(==, "",   "");
  CMP_Y(==, "a",  "a");
  CMP_Y(==, "aa", "aa");
  CMP_N(==, "a",  "");
  CMP_N(==, "",   "a");
  CMP_N(==, "a",  "b");
  CMP_N(==, "a",  "aa");
  CMP_N(==, "aa", "a");

  CMP_N(!=, "",   "");
  CMP_N(!=, "a",  "a");
  CMP_N(!=, "aa", "aa");
  CMP_Y(!=, "a",  "");
  CMP_Y(!=, "",   "a");
  CMP_Y(!=, "a",  "b");
  CMP_Y(!=, "a",  "aa");
  CMP_Y(!=, "aa", "a");

  CMP_Y(<, "a",  "b");
  CMP_Y(<, "a",  "aa");
  CMP_Y(<, "aa", "b");
  CMP_Y(<, "aa", "bb");
  CMP_N(<, "a",  "a");
  CMP_N(<, "b",  "a");
  CMP_N(<, "aa", "a");
  CMP_N(<, "b",  "aa");
  CMP_N(<, "bb", "aa");

  CMP_Y(<=, "a",  "a");
  CMP_Y(<=, "a",  "b");
  CMP_Y(<=, "a",  "aa");
  CMP_Y(<=, "aa", "b");
  CMP_Y(<=, "aa", "bb");
  CMP_N(<=, "b",  "a");
  CMP_N(<=, "aa", "a");
  CMP_N(<=, "b",  "aa");
  CMP_N(<=, "bb", "aa");

  CMP_N(>=, "a",  "b");
  CMP_N(>=, "a",  "aa");
  CMP_N(>=, "aa", "b");
  CMP_N(>=, "aa", "bb");
  CMP_Y(>=, "a",  "a");
  CMP_Y(>=, "b",  "a");
  CMP_Y(>=, "aa", "a");
  CMP_Y(>=, "b",  "aa");
  CMP_Y(>=, "bb", "aa");

  CMP_N(>, "a",  "a");
  CMP_N(>, "a",  "b");
  CMP_N(>, "a",  "aa");
  CMP_N(>, "aa", "b");
  CMP_N(>, "aa", "bb");
  CMP_Y(>, "b",  "a");
  CMP_Y(>, "aa", "a");
  CMP_Y(>, "b",  "aa");
  CMP_Y(>, "bb", "aa");

  std::string x;
  for (int i = 0; i < 256; i++) {
    x += 'a';
    std::string y = x;
    CMP_Y(==, x, y);
    for (int j = 0; j < i; j++) {
      std::string z = x;
      z[j] = 'b';       // Differs in position 'j'
      CMP_N(==, x, z);
    }
  }

#undef CMP_Y
#undef CMP_N
}

TYPED_TEST(CommonStringPieceTest, CheckSTL) {
  TypeParam alphabet(TestFixture::as_string("abcdefghijklmnopqrstuvwxyz"));
  TypeParam abc(TestFixture::as_string("abc"));
  TypeParam xyz(TestFixture::as_string("xyz"));
  TypeParam foobar(TestFixture::as_string("foobar"));

  BasicStringPiece<TypeParam> a(alphabet);
  BasicStringPiece<TypeParam> b(abc);
  BasicStringPiece<TypeParam> c(xyz);
  BasicStringPiece<TypeParam> d(foobar);
  BasicStringPiece<TypeParam> e;
  TypeParam temp(TestFixture::as_string("123"));
  temp += static_cast<typename TypeParam::value_type>(0);
  temp += TestFixture::as_string("456");
  BasicStringPiece<TypeParam> f(temp);

  ASSERT_EQ(a[6], static_cast<typename TypeParam::value_type>('g'));
  ASSERT_EQ(b[0], static_cast<typename TypeParam::value_type>('a'));
  ASSERT_EQ(c[2], static_cast<typename TypeParam::value_type>('z'));
  ASSERT_EQ(f[3], static_cast<typename TypeParam::value_type>('\0'));
  ASSERT_EQ(f[5], static_cast<typename TypeParam::value_type>('5'));

  ASSERT_EQ(*d.data(), static_cast<typename TypeParam::value_type>('f'));
  ASSERT_EQ(d.data()[5], static_cast<typename TypeParam::value_type>('r'));
  ASSERT_TRUE(e.data() == NULL);

  ASSERT_EQ(*a.begin(), static_cast<typename TypeParam::value_type>('a'));
  ASSERT_EQ(*(b.begin() + 2), static_cast<typename TypeParam::value_type>('c'));
  ASSERT_EQ(*(c.end() - 1), static_cast<typename TypeParam::value_type>('z'));

  ASSERT_EQ(*a.rbegin(), static_cast<typename TypeParam::value_type>('z'));
  ASSERT_EQ(*(b.rbegin() + 2),
            static_cast<typename TypeParam::value_type>('a'));
  ASSERT_EQ(*(c.rend() - 1), static_cast<typename TypeParam::value_type>('x'));
  ASSERT_TRUE(a.rbegin() + 26 == a.rend());

  ASSERT_EQ(a.size(), 26U);
  ASSERT_EQ(b.size(), 3U);
  ASSERT_EQ(c.size(), 3U);
  ASSERT_EQ(d.size(), 6U);
  ASSERT_EQ(e.size(), 0U);
  ASSERT_EQ(f.size(), 7U);

  ASSERT_TRUE(!d.empty());
  ASSERT_TRUE(d.begin() != d.end());
  ASSERT_TRUE(d.begin() + 6 == d.end());

  ASSERT_TRUE(e.empty());
  ASSERT_TRUE(e.begin() == e.end());

  d.clear();
  ASSERT_EQ(d.size(), 0U);
  ASSERT_TRUE(d.empty());
  ASSERT_TRUE(d.data() == NULL);
  ASSERT_TRUE(d.begin() == d.end());

  ASSERT_GE(a.max_size(), a.capacity());
  ASSERT_GE(a.capacity(), a.size());
}

TYPED_TEST(CommonStringPieceTest, CheckFind) {
  typedef BasicStringPiece<TypeParam> Piece;

  TypeParam alphabet(TestFixture::as_string("abcdefghijklmnopqrstuvwxyz"));
  TypeParam abc(TestFixture::as_string("abc"));
  TypeParam xyz(TestFixture::as_string("xyz"));
  TypeParam foobar(TestFixture::as_string("foobar"));

  BasicStringPiece<TypeParam> a(alphabet);
  BasicStringPiece<TypeParam> b(abc);
  BasicStringPiece<TypeParam> c(xyz);
  BasicStringPiece<TypeParam> d(foobar);

  d.clear();
  Piece e;
  TypeParam temp(TestFixture::as_string("123"));
  temp.push_back('\0');
  temp += TestFixture::as_string("456");
  Piece f(temp);

  typename TypeParam::value_type buf[4] = { '%', '%', '%', '%' };
  ASSERT_EQ(a.copy(buf, 4), 4U);
  ASSERT_EQ(buf[0], a[0]);
  ASSERT_EQ(buf[1], a[1]);
  ASSERT_EQ(buf[2], a[2]);
  ASSERT_EQ(buf[3], a[3]);
  ASSERT_EQ(a.copy(buf, 3, 7), 3U);
  ASSERT_EQ(buf[0], a[7]);
  ASSERT_EQ(buf[1], a[8]);
  ASSERT_EQ(buf[2], a[9]);
  ASSERT_EQ(buf[3], a[3]);
  ASSERT_EQ(c.copy(buf, 99), 3U);
  ASSERT_EQ(buf[0], c[0]);
  ASSERT_EQ(buf[1], c[1]);
  ASSERT_EQ(buf[2], c[2]);
  ASSERT_EQ(buf[3], a[3]);

  ASSERT_EQ(Piece::npos, TypeParam::npos);

  ASSERT_EQ(a.find(b), 0U);
  ASSERT_EQ(a.find(b, 1), Piece::npos);
  ASSERT_EQ(a.find(c), 23U);
  ASSERT_EQ(a.find(c, 9), 23U);
  ASSERT_EQ(a.find(c, Piece::npos), Piece::npos);
  ASSERT_EQ(b.find(c), Piece::npos);
  ASSERT_EQ(b.find(c, Piece::npos), Piece::npos);
  ASSERT_EQ(a.find(d), 0U);
  ASSERT_EQ(a.find(e), 0U);
  ASSERT_EQ(a.find(d, 12), 12U);
  ASSERT_EQ(a.find(e, 17), 17U);
  TypeParam not_found(TestFixture::as_string("xx not found bb"));
  Piece g(not_found);
  ASSERT_EQ(a.find(g), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(d.find(b), Piece::npos);
  ASSERT_EQ(e.find(b), Piece::npos);
  ASSERT_EQ(d.find(b, 4), Piece::npos);
  ASSERT_EQ(e.find(b, 7), Piece::npos);

  size_t empty_search_pos = TypeParam().find(TypeParam());
  ASSERT_EQ(d.find(d), empty_search_pos);
  ASSERT_EQ(d.find(e), empty_search_pos);
  ASSERT_EQ(e.find(d), empty_search_pos);
  ASSERT_EQ(e.find(e), empty_search_pos);
  ASSERT_EQ(d.find(d, 4), std::string().find(std::string(), 4));
  ASSERT_EQ(d.find(e, 4), std::string().find(std::string(), 4));
  ASSERT_EQ(e.find(d, 4), std::string().find(std::string(), 4));
  ASSERT_EQ(e.find(e, 4), std::string().find(std::string(), 4));

  ASSERT_EQ(a.find('a'), 0U);
  ASSERT_EQ(a.find('c'), 2U);
  ASSERT_EQ(a.find('z'), 25U);
  ASSERT_EQ(a.find('$'), Piece::npos);
  ASSERT_EQ(a.find('\0'), Piece::npos);
  ASSERT_EQ(f.find('\0'), 3U);
  ASSERT_EQ(f.find('3'), 2U);
  ASSERT_EQ(f.find('5'), 5U);
  ASSERT_EQ(g.find('o'), 4U);
  ASSERT_EQ(g.find('o', 4), 4U);
  ASSERT_EQ(g.find('o', 5), 8U);
  ASSERT_EQ(a.find('b', 5), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(d.find('\0'), Piece::npos);
  ASSERT_EQ(e.find('\0'), Piece::npos);
  ASSERT_EQ(d.find('\0', 4), Piece::npos);
  ASSERT_EQ(e.find('\0', 7), Piece::npos);
  ASSERT_EQ(d.find('x'), Piece::npos);
  ASSERT_EQ(e.find('x'), Piece::npos);
  ASSERT_EQ(d.find('x', 4), Piece::npos);
  ASSERT_EQ(e.find('x', 7), Piece::npos);

  ASSERT_EQ(a.rfind(b), 0U);
  ASSERT_EQ(a.rfind(b, 1), 0U);
  ASSERT_EQ(a.rfind(c), 23U);
  ASSERT_EQ(a.rfind(c, 22U), Piece::npos);
  ASSERT_EQ(a.rfind(c, 1U), Piece::npos);
  ASSERT_EQ(a.rfind(c, 0U), Piece::npos);
  ASSERT_EQ(b.rfind(c), Piece::npos);
  ASSERT_EQ(b.rfind(c, 0U), Piece::npos);
  ASSERT_EQ(a.rfind(d), static_cast<size_t>(a.as_string().rfind(TypeParam())));
  ASSERT_EQ(a.rfind(e), a.as_string().rfind(TypeParam()));
  ASSERT_EQ(a.rfind(d, 12), 12U);
  ASSERT_EQ(a.rfind(e, 17), 17U);
  ASSERT_EQ(a.rfind(g), Piece::npos);
  ASSERT_EQ(d.rfind(b), Piece::npos);
  ASSERT_EQ(e.rfind(b), Piece::npos);
  ASSERT_EQ(d.rfind(b, 4), Piece::npos);
  ASSERT_EQ(e.rfind(b, 7), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(d.rfind(d, 4), std::string().rfind(std::string()));
  ASSERT_EQ(e.rfind(d, 7), std::string().rfind(std::string()));
  ASSERT_EQ(d.rfind(e, 4), std::string().rfind(std::string()));
  ASSERT_EQ(e.rfind(e, 7), std::string().rfind(std::string()));
  ASSERT_EQ(d.rfind(d), std::string().rfind(std::string()));
  ASSERT_EQ(e.rfind(d), std::string().rfind(std::string()));
  ASSERT_EQ(d.rfind(e), std::string().rfind(std::string()));
  ASSERT_EQ(e.rfind(e), std::string().rfind(std::string()));

  ASSERT_EQ(g.rfind('o'), 8U);
  ASSERT_EQ(g.rfind('q'), Piece::npos);
  ASSERT_EQ(g.rfind('o', 8), 8U);
  ASSERT_EQ(g.rfind('o', 7), 4U);
  ASSERT_EQ(g.rfind('o', 3), Piece::npos);
  ASSERT_EQ(f.rfind('\0'), 3U);
  ASSERT_EQ(f.rfind('\0', 12), 3U);
  ASSERT_EQ(f.rfind('3'), 2U);
  ASSERT_EQ(f.rfind('5'), 5U);
  // empty string nonsense
  ASSERT_EQ(d.rfind('o'), Piece::npos);
  ASSERT_EQ(e.rfind('o'), Piece::npos);
  ASSERT_EQ(d.rfind('o', 4), Piece::npos);
  ASSERT_EQ(e.rfind('o', 7), Piece::npos);

  TypeParam one_two_three_four(TestFixture::as_string("one,two:three;four"));
  TypeParam comma_colon(TestFixture::as_string(",:"));
  ASSERT_EQ(3U, Piece(one_two_three_four).find_first_of(comma_colon));
  ASSERT_EQ(a.find_first_of(b), 0U);
  ASSERT_EQ(a.find_first_of(b, 0), 0U);
  ASSERT_EQ(a.find_first_of(b, 1), 1U);
  ASSERT_EQ(a.find_first_of(b, 2), 2U);
  ASSERT_EQ(a.find_first_of(b, 3), Piece::npos);
  ASSERT_EQ(a.find_first_of(c), 23U);
  ASSERT_EQ(a.find_first_of(c, 23), 23U);
  ASSERT_EQ(a.find_first_of(c, 24), 24U);
  ASSERT_EQ(a.find_first_of(c, 25), 25U);
  ASSERT_EQ(a.find_first_of(c, 26), Piece::npos);
  ASSERT_EQ(g.find_first_of(b), 13U);
  ASSERT_EQ(g.find_first_of(c), 0U);
  ASSERT_EQ(a.find_first_of(f), Piece::npos);
  ASSERT_EQ(f.find_first_of(a), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(a.find_first_of(d), Piece::npos);
  ASSERT_EQ(a.find_first_of(e), Piece::npos);
  ASSERT_EQ(d.find_first_of(b), Piece::npos);
  ASSERT_EQ(e.find_first_of(b), Piece::npos);
  ASSERT_EQ(d.find_first_of(d), Piece::npos);
  ASSERT_EQ(e.find_first_of(d), Piece::npos);
  ASSERT_EQ(d.find_first_of(e), Piece::npos);
  ASSERT_EQ(e.find_first_of(e), Piece::npos);

  ASSERT_EQ(a.find_first_not_of(b), 3U);
  ASSERT_EQ(a.find_first_not_of(c), 0U);
  ASSERT_EQ(b.find_first_not_of(a), Piece::npos);
  ASSERT_EQ(c.find_first_not_of(a), Piece::npos);
  ASSERT_EQ(f.find_first_not_of(a), 0U);
  ASSERT_EQ(a.find_first_not_of(f), 0U);
  ASSERT_EQ(a.find_first_not_of(d), 0U);
  ASSERT_EQ(a.find_first_not_of(e), 0U);
  // empty string nonsense
  ASSERT_EQ(d.find_first_not_of(a), Piece::npos);
  ASSERT_EQ(e.find_first_not_of(a), Piece::npos);
  ASSERT_EQ(d.find_first_not_of(d), Piece::npos);
  ASSERT_EQ(e.find_first_not_of(d), Piece::npos);
  ASSERT_EQ(d.find_first_not_of(e), Piece::npos);
  ASSERT_EQ(e.find_first_not_of(e), Piece::npos);

  TypeParam equals(TestFixture::as_string("===="));
  Piece h(equals);
  ASSERT_EQ(h.find_first_not_of('='), Piece::npos);
  ASSERT_EQ(h.find_first_not_of('=', 3), Piece::npos);
  ASSERT_EQ(h.find_first_not_of('\0'), 0U);
  ASSERT_EQ(g.find_first_not_of('x'), 2U);
  ASSERT_EQ(f.find_first_not_of('\0'), 0U);
  ASSERT_EQ(f.find_first_not_of('\0', 3), 4U);
  ASSERT_EQ(f.find_first_not_of('\0', 2), 2U);
  // empty string nonsense
  ASSERT_EQ(d.find_first_not_of('x'), Piece::npos);
  ASSERT_EQ(e.find_first_not_of('x'), Piece::npos);
  ASSERT_EQ(d.find_first_not_of('\0'), Piece::npos);
  ASSERT_EQ(e.find_first_not_of('\0'), Piece::npos);

  //  Piece g("xx not found bb");
  TypeParam fifty_six(TestFixture::as_string("56"));
  Piece i(fifty_six);
  ASSERT_EQ(h.find_last_of(a), Piece::npos);
  ASSERT_EQ(g.find_last_of(a), g.size()-1);
  ASSERT_EQ(a.find_last_of(b), 2U);
  ASSERT_EQ(a.find_last_of(c), a.size()-1);
  ASSERT_EQ(f.find_last_of(i), 6U);
  ASSERT_EQ(a.find_last_of('a'), 0U);
  ASSERT_EQ(a.find_last_of('b'), 1U);
  ASSERT_EQ(a.find_last_of('z'), 25U);
  ASSERT_EQ(a.find_last_of('a', 5), 0U);
  ASSERT_EQ(a.find_last_of('b', 5), 1U);
  ASSERT_EQ(a.find_last_of('b', 0), Piece::npos);
  ASSERT_EQ(a.find_last_of('z', 25), 25U);
  ASSERT_EQ(a.find_last_of('z', 24), Piece::npos);
  ASSERT_EQ(f.find_last_of(i, 5), 5U);
  ASSERT_EQ(f.find_last_of(i, 6), 6U);
  ASSERT_EQ(f.find_last_of(a, 4), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(f.find_last_of(d), Piece::npos);
  ASSERT_EQ(f.find_last_of(e), Piece::npos);
  ASSERT_EQ(f.find_last_of(d, 4), Piece::npos);
  ASSERT_EQ(f.find_last_of(e, 4), Piece::npos);
  ASSERT_EQ(d.find_last_of(d), Piece::npos);
  ASSERT_EQ(d.find_last_of(e), Piece::npos);
  ASSERT_EQ(e.find_last_of(d), Piece::npos);
  ASSERT_EQ(e.find_last_of(e), Piece::npos);
  ASSERT_EQ(d.find_last_of(f), Piece::npos);
  ASSERT_EQ(e.find_last_of(f), Piece::npos);
  ASSERT_EQ(d.find_last_of(d, 4), Piece::npos);
  ASSERT_EQ(d.find_last_of(e, 4), Piece::npos);
  ASSERT_EQ(e.find_last_of(d, 4), Piece::npos);
  ASSERT_EQ(e.find_last_of(e, 4), Piece::npos);
  ASSERT_EQ(d.find_last_of(f, 4), Piece::npos);
  ASSERT_EQ(e.find_last_of(f, 4), Piece::npos);

  ASSERT_EQ(a.find_last_not_of(b), a.size()-1);
  ASSERT_EQ(a.find_last_not_of(c), 22U);
  ASSERT_EQ(b.find_last_not_of(a), Piece::npos);
  ASSERT_EQ(b.find_last_not_of(b), Piece::npos);
  ASSERT_EQ(f.find_last_not_of(i), 4U);
  ASSERT_EQ(a.find_last_not_of(c, 24), 22U);
  ASSERT_EQ(a.find_last_not_of(b, 3), 3U);
  ASSERT_EQ(a.find_last_not_of(b, 2), Piece::npos);
  // empty string nonsense
  ASSERT_EQ(f.find_last_not_of(d), f.size()-1);
  ASSERT_EQ(f.find_last_not_of(e), f.size()-1);
  ASSERT_EQ(f.find_last_not_of(d, 4), 4U);
  ASSERT_EQ(f.find_last_not_of(e, 4), 4U);
  ASSERT_EQ(d.find_last_not_of(d), Piece::npos);
  ASSERT_EQ(d.find_last_not_of(e), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(d), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(e), Piece::npos);
  ASSERT_EQ(d.find_last_not_of(f), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(f), Piece::npos);
  ASSERT_EQ(d.find_last_not_of(d, 4), Piece::npos);
  ASSERT_EQ(d.find_last_not_of(e, 4), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(d, 4), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(e, 4), Piece::npos);
  ASSERT_EQ(d.find_last_not_of(f, 4), Piece::npos);
  ASSERT_EQ(e.find_last_not_of(f, 4), Piece::npos);

  ASSERT_EQ(h.find_last_not_of('x'), h.size() - 1);
  ASSERT_EQ(h.find_last_not_of('='), Piece::npos);
  ASSERT_EQ(b.find_last_not_of('c'), 1U);
  ASSERT_EQ(h.find_last_not_of('x', 2), 2U);
  ASSERT_EQ(h.find_last_not_of('=', 2), Piece::npos);
  ASSERT_EQ(b.find_last_not_of('b', 1), 0U);
  // empty string nonsense
  ASSERT_EQ(d.find_last_not_of('x'), Piece::npos);
  ASSERT_EQ(e.find_last_not_of('x'), Piece::npos);
  ASSERT_EQ(d.find_last_not_of('\0'), Piece::npos);
  ASSERT_EQ(e.find_last_not_of('\0'), Piece::npos);

  ASSERT_EQ(a.substr(0, 3), b);
  ASSERT_EQ(a.substr(23), c);
  ASSERT_EQ(a.substr(23, 3), c);
  ASSERT_EQ(a.substr(23, 99), c);
  ASSERT_EQ(a.substr(0), a);
  ASSERT_EQ(a.substr(3, 2), TestFixture::as_string("de"));
  // empty string nonsense
  ASSERT_EQ(a.substr(99, 2), e);
  ASSERT_EQ(d.substr(99), e);
  ASSERT_EQ(d.substr(0, 99), e);
  ASSERT_EQ(d.substr(99, 99), e);
}

TYPED_TEST(CommonStringPieceTest, CheckCustom) {
  TypeParam foobar(TestFixture::as_string("foobar"));
  BasicStringPiece<TypeParam> a(foobar);
  TypeParam s1(TestFixture::as_string("123"));
  s1 += static_cast<typename TypeParam::value_type>('\0');
  s1 += TestFixture::as_string("456");
  BasicStringPiece<TypeParam> b(s1);
  BasicStringPiece<TypeParam> e;
  TypeParam s2;

  // remove_prefix
  BasicStringPiece<TypeParam> c(a);
  c.remove_prefix(3);
  ASSERT_EQ(c, TestFixture::as_string("bar"));
  c = a;
  c.remove_prefix(0);
  ASSERT_EQ(c, a);
  c.remove_prefix(c.size());
  ASSERT_EQ(c, e);

  // remove_suffix
  c = a;
  c.remove_suffix(3);
  ASSERT_EQ(c, TestFixture::as_string("foo"));
  c = a;
  c.remove_suffix(0);
  ASSERT_EQ(c, a);
  c.remove_suffix(c.size());
  ASSERT_EQ(c, e);

  // set
  c.set(foobar.c_str());
  ASSERT_EQ(c, a);
  c.set(foobar.c_str(), 6);
  ASSERT_EQ(c, a);
  c.set(foobar.c_str(), 0);
  ASSERT_EQ(c, e);
  c.set(foobar.c_str(), 7);  // Note, has an embedded NULL
  ASSERT_NE(c, a);

  // as_string
  TypeParam s3(a.as_string().c_str(), 7);  // Note, has an embedded NULL
  ASSERT_TRUE(c == s3);
  TypeParam s4(e.as_string());
  ASSERT_TRUE(s4.empty());
}

TEST(StringPieceTest, CheckCustom) {
  StringPiece a("foobar");
  std::string s1("123");
  s1 += '\0';
  s1 += "456";
  StringPiece b(s1);
  StringPiece e;
  std::string s2;

  // CopyToString
  a.CopyToString(&s2);
  ASSERT_EQ(s2.size(), 6U);
  ASSERT_EQ(s2, "foobar");
  b.CopyToString(&s2);
  ASSERT_EQ(s2.size(), 7U);
  ASSERT_EQ(s1, s2);
  e.CopyToString(&s2);
  ASSERT_TRUE(s2.empty());

  // AppendToString
  s2.erase();
  a.AppendToString(&s2);
  ASSERT_EQ(s2.size(), 6U);
  ASSERT_EQ(s2, "foobar");
  a.AppendToString(&s2);
  ASSERT_EQ(s2.size(), 12U);
  ASSERT_EQ(s2, "foobarfoobar");

  // starts_with
  ASSERT_TRUE(a.starts_with(a));
  ASSERT_TRUE(a.starts_with("foo"));
  ASSERT_TRUE(a.starts_with(e));
  ASSERT_TRUE(b.starts_with(s1));
  ASSERT_TRUE(b.starts_with(b));
  ASSERT_TRUE(b.starts_with(e));
  ASSERT_TRUE(e.starts_with(""));
  ASSERT_TRUE(!a.starts_with(b));
  ASSERT_TRUE(!b.starts_with(a));
  ASSERT_TRUE(!e.starts_with(a));

  // ends with
  ASSERT_TRUE(a.ends_with(a));
  ASSERT_TRUE(a.ends_with("bar"));
  ASSERT_TRUE(a.ends_with(e));
  ASSERT_TRUE(b.ends_with(s1));
  ASSERT_TRUE(b.ends_with(b));
  ASSERT_TRUE(b.ends_with(e));
  ASSERT_TRUE(e.ends_with(""));
  ASSERT_TRUE(!a.ends_with(b));
  ASSERT_TRUE(!b.ends_with(a));
  ASSERT_TRUE(!e.ends_with(a));

  StringPiece c;
  c.set("foobar", 6);
  ASSERT_EQ(c, a);
  c.set("foobar", 0);
  ASSERT_EQ(c, e);
  c.set("foobar", 7);
  ASSERT_NE(c, a);
}

TYPED_TEST(CommonStringPieceTest, CheckNULL) {
  // we used to crash here, but now we don't.
  BasicStringPiece<TypeParam> s(NULL);
  ASSERT_EQ(s.data(), (const typename TypeParam::value_type*)NULL);
  ASSERT_EQ(s.size(), 0U);

  s.set(NULL);
  ASSERT_EQ(s.data(), (const typename TypeParam::value_type*)NULL);
  ASSERT_EQ(s.size(), 0U);

  TypeParam str = s.as_string();
  ASSERT_EQ(str.length(), 0U);
  ASSERT_EQ(str, TypeParam());
}

TYPED_TEST(CommonStringPieceTest, CheckComparisons2) {
  TypeParam alphabet(TestFixture::as_string("abcdefghijklmnopqrstuvwxyz"));
  TypeParam alphabet_z(TestFixture::as_string("abcdefghijklmnopqrstuvwxyzz"));
  TypeParam alphabet_y(TestFixture::as_string("abcdefghijklmnopqrstuvwxyy"));
  BasicStringPiece<TypeParam> abc(alphabet);

  // check comparison operations on strings longer than 4 bytes.
  ASSERT_TRUE(abc == BasicStringPiece<TypeParam>(alphabet));
  ASSERT_EQ(abc.compare(BasicStringPiece<TypeParam>(alphabet)), 0);

  ASSERT_TRUE(abc < BasicStringPiece<TypeParam>(alphabet_z));
  ASSERT_LT(abc.compare(BasicStringPiece<TypeParam>(alphabet_z)), 0);

  ASSERT_TRUE(abc > BasicStringPiece<TypeParam>(alphabet_y));
  ASSERT_GT(abc.compare(BasicStringPiece<TypeParam>(alphabet_y)), 0);
}

// Test operations only supported by std::string version.
TEST(StringPieceTest, CheckComparisons2) {
  StringPiece abc("abcdefghijklmnopqrstuvwxyz");

  // starts_with
  ASSERT_TRUE(abc.starts_with(abc));
  ASSERT_TRUE(abc.starts_with("abcdefghijklm"));
  ASSERT_TRUE(!abc.starts_with("abcdefguvwxyz"));

  // ends_with
  ASSERT_TRUE(abc.ends_with(abc));
  ASSERT_TRUE(!abc.ends_with("abcdefguvwxyz"));
  ASSERT_TRUE(abc.ends_with("nopqrstuvwxyz"));
}

TYPED_TEST(CommonStringPieceTest, StringCompareNotAmbiguous) {
  ASSERT_TRUE(TestFixture::as_string("hello").c_str() ==
              TestFixture::as_string("hello"));
  ASSERT_TRUE(TestFixture::as_string("hello").c_str() <
              TestFixture::as_string("world"));
}

TYPED_TEST(CommonStringPieceTest, HeterogenousStringPieceEquals) {
  TypeParam hello(TestFixture::as_string("hello"));

  ASSERT_TRUE(BasicStringPiece<TypeParam>(hello) == hello);
  ASSERT_TRUE(hello.c_str() == BasicStringPiece<TypeParam>(hello));
}

// string16-specific stuff
TEST(StringPiece16Test, CheckSTL) {
  // Check some non-ascii characters.
  string16 fifth(ASCIIToUTF16("123"));
  fifth.push_back(0x0000);
  fifth.push_back(0xd8c5);
  fifth.push_back(0xdffe);
  StringPiece16 f(fifth);

  ASSERT_EQ(f[3], '\0');
  ASSERT_EQ(f[5], static_cast<char16>(0xdffe));

  ASSERT_EQ(f.size(), 6U);
}



TEST(StringPiece16Test, CheckConversion) {
  // Make sure that we can convert from UTF8 to UTF16 and back. We use a two
  // byte character (G clef) to test this.
  ASSERT_EQ(
      UTF16ToUTF8(
          StringPiece16(UTF8ToUTF16("\xf0\x9d\x84\x9e")).as_string()),
      "\xf0\x9d\x84\x9e");
}

TYPED_TEST(CommonStringPieceTest, CheckConstructors) {
  TypeParam str(TestFixture::as_string("hello world"));
  TypeParam empty;

  ASSERT_TRUE(str == BasicStringPiece<TypeParam>(str));
  ASSERT_TRUE(str == BasicStringPiece<TypeParam>(str.c_str()));
  ASSERT_TRUE(TestFixture::as_string("hello") ==
              BasicStringPiece<TypeParam>(str.c_str(), 5));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(str.c_str(),
      static_cast<typename BasicStringPiece<TypeParam>::size_type>(0)));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(NULL));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(NULL,
      static_cast<typename BasicStringPiece<TypeParam>::size_type>(0)));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>());
  ASSERT_TRUE(str == BasicStringPiece<TypeParam>(str.begin(), str.end()));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(str.begin(), str.begin()));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(empty));
  ASSERT_TRUE(empty == BasicStringPiece<TypeParam>(empty.begin(), empty.end()));
}

}  // namespace base
