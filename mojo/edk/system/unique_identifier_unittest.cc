// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/unique_identifier.h"

#include <memory>
#include <set>
#include <string>
#include <unordered_set>

#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

class UniqueIdentifierTest : public testing::Test {
 public:
  UniqueIdentifierTest()
      : platform_support_(embedder::CreateSimplePlatformSupport()) {}
  ~UniqueIdentifierTest() override {}

  embedder::PlatformSupport* platform_support() {
    return platform_support_.get();
  }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(UniqueIdentifierTest);
};

TEST_F(UniqueIdentifierTest, Basic) {
  // (This also checks copy constructibility.)
  UniqueIdentifier id1 = UniqueIdentifier::Generate(platform_support());

  EXPECT_EQ(id1, id1);
  EXPECT_FALSE(id1 != id1);
  EXPECT_FALSE(id1 < id1);

  UniqueIdentifier id2 = UniqueIdentifier::Generate(platform_support());

  EXPECT_FALSE(id2 == id1);
  EXPECT_NE(id2, id1);
  EXPECT_TRUE((id1 < id2) ^ (id2 < id1));

  // Test copyability.
  id2 = id1;
}

TEST_F(UniqueIdentifierTest, ToString) {
  UniqueIdentifier id1 = UniqueIdentifier::Generate(platform_support());
  std::string id1_string = id1.ToString();
  EXPECT_FALSE(id1_string.empty());

  // The string should be printable, and not contain certain characters.
  for (size_t i = 0; i < id1_string.size(); i++) {
    char c = id1_string[i];
    // Printable characters, not including space.
    EXPECT_GT(c, ' ');
    EXPECT_LE(c, '\x7e');
    // Single and double quotes, and backslashes are disallowed.
    EXPECT_NE(c, '\'');
    EXPECT_NE(c, '"');
    EXPECT_NE(c, '\\');
  }

  UniqueIdentifier id2 = UniqueIdentifier::Generate(platform_support());
  std::string id2_string = id2.ToString();
  EXPECT_FALSE(id2_string.empty());

  EXPECT_NE(id1, id2);
  EXPECT_NE(id1_string, id2_string);
}

TEST_F(UniqueIdentifierTest, FromString) {
  UniqueIdentifier id = UniqueIdentifier::Generate(platform_support());
  std::string id_string = id.ToString();
  EXPECT_FALSE(id_string.empty());

  bool success = false;
  UniqueIdentifier id_restored =
      UniqueIdentifier::FromString(id_string, &success);
  EXPECT_TRUE(success);
  EXPECT_EQ(id, id_restored);
}

TEST_F(UniqueIdentifierTest, FromStringFailures) {
  bool success = true;
  UniqueIdentifier::FromString("", &success);
  EXPECT_FALSE(success);

  // That the cases below will fail requires *some* knowledge of the (private)
  // encoding. So first check something that we know should succeed, to roughly
  // confirm our knowledge.
  success = false;
  UniqueIdentifier::FromString("0123456789ABCDEF0123456789ABCDEF", &success);
  EXPECT_TRUE(success);

  success = true;
  UniqueIdentifier::FromString("0123456789abcdef0123456789abcdef", &success);
  EXPECT_FALSE(success);

  success = true;
  UniqueIdentifier::FromString("!@#$%^&*()_+-=/\\,.<>[]{};':\"|", &success);
  EXPECT_FALSE(success);

  success = true;
  UniqueIdentifier::FromString("0123456789ABCDEF0123456789ABCDE", &success);
  EXPECT_FALSE(success);

  success = true;
  UniqueIdentifier::FromString("0123456789ABCDEF0123456789ABCD", &success);
  EXPECT_FALSE(success);
}

TEST_F(UniqueIdentifierTest, StdSet) {
  std::set<UniqueIdentifier> s;
  EXPECT_TRUE(s.empty());

  UniqueIdentifier id1 = UniqueIdentifier::Generate(platform_support());
  EXPECT_TRUE(s.find(id1) == s.end());
  s.insert(id1);
  EXPECT_TRUE(s.find(id1) != s.end());
  EXPECT_FALSE(s.empty());

  UniqueIdentifier id2 = UniqueIdentifier::Generate(platform_support());
  EXPECT_TRUE(s.find(id2) == s.end());
  s.insert(id2);
  EXPECT_TRUE(s.find(id2) != s.end());
  // Make sure |id1| is still in |s|.
  EXPECT_TRUE(s.find(id1) != s.end());

  s.erase(id1);
  EXPECT_TRUE(s.find(id1) == s.end());
  // Make sure |id2| is still in |s|.
  EXPECT_TRUE(s.find(id2) != s.end());

  s.erase(id2);
  EXPECT_TRUE(s.find(id2) == s.end());
  EXPECT_TRUE(s.empty());
}

TEST_F(UniqueIdentifierTest, UnorderedSet) {
  std::unordered_set<UniqueIdentifier> s;
  EXPECT_TRUE(s.empty());

  UniqueIdentifier id1 = UniqueIdentifier::Generate(platform_support());
  EXPECT_TRUE(s.find(id1) == s.end());
  s.insert(id1);
  EXPECT_TRUE(s.find(id1) != s.end());
  EXPECT_FALSE(s.empty());

  UniqueIdentifier id2 = UniqueIdentifier::Generate(platform_support());
  EXPECT_TRUE(s.find(id2) == s.end());
  s.insert(id2);
  EXPECT_TRUE(s.find(id2) != s.end());
  // Make sure |id1| is still in |s|.
  EXPECT_TRUE(s.find(id1) != s.end());

  s.erase(id1);
  EXPECT_TRUE(s.find(id1) == s.end());
  // Make sure |id2| is still in |s|.
  EXPECT_TRUE(s.find(id2) != s.end());

  s.erase(id2);
  EXPECT_TRUE(s.find(id2) == s.end());
  EXPECT_TRUE(s.empty());
}

}  // namespace
}  // namespace system
}  // namespace mojo
