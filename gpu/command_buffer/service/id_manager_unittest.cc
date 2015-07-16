// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/id_manager.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {
namespace gles2 {

class IdManagerTest : public testing::Test {
 public:
  IdManagerTest() {
  }

 protected:
  void SetUp() override {}

  void TearDown() override {}

  IdManager manager_;
};

TEST_F(IdManagerTest, Basic) {
  const GLuint kClientId1 = 1;
  const GLuint kClientId2 = 2;
  const GLuint kServiceId1 = 201;
  const GLuint kServiceId2 = 202;
  // Check we can add an id
  EXPECT_TRUE(manager_.AddMapping(kClientId1, kServiceId1));
  // Check we can get that mapping
  GLuint service_id = 0;
  EXPECT_TRUE(manager_.GetServiceId(kClientId1, &service_id));
  EXPECT_EQ(kServiceId1, service_id);
  GLuint client_id = 0;
  EXPECT_TRUE(manager_.GetClientId(kServiceId1, &client_id));
  EXPECT_EQ(kClientId1, client_id);
  // Check that it fails if we get a non-existent id.
  service_id = 0;
  client_id = 0;
  EXPECT_FALSE(manager_.GetServiceId(kClientId2, &service_id));
  EXPECT_FALSE(manager_.GetClientId(kServiceId2, &client_id));
  EXPECT_EQ(0u, service_id);
  EXPECT_EQ(0u, client_id);
  // Check we can add a second id.
  EXPECT_TRUE(manager_.AddMapping(kClientId2, kServiceId2));
  // Check we can get that mapping
  service_id = 0;
  EXPECT_TRUE(manager_.GetServiceId(kClientId1, &service_id));
  EXPECT_EQ(kServiceId1, service_id);
  EXPECT_TRUE(manager_.GetServiceId(kClientId2, &service_id));
  EXPECT_EQ(kServiceId2, service_id);
  client_id = 0;
  EXPECT_TRUE(manager_.GetClientId(kServiceId1, &client_id));
  EXPECT_EQ(kClientId1, client_id);
  EXPECT_TRUE(manager_.GetClientId(kServiceId2, &client_id));
  EXPECT_EQ(kClientId2, client_id);
  // Check if we remove an id we can no longer get it.
  EXPECT_TRUE(manager_.RemoveMapping(kClientId1, kServiceId1));
  EXPECT_FALSE(manager_.GetServiceId(kClientId1, &service_id));
  EXPECT_FALSE(manager_.GetClientId(kServiceId1, &client_id));
  // Check we get an error if we try to remove a non-existent id.
  EXPECT_FALSE(manager_.RemoveMapping(kClientId1, kServiceId1));
  EXPECT_FALSE(manager_.RemoveMapping(kClientId2, kServiceId1));
  EXPECT_FALSE(manager_.RemoveMapping(kClientId1, kServiceId2));
  // Check we get an error if we try to map an existing id.
  EXPECT_FALSE(manager_.AddMapping(kClientId2, kServiceId2));
  EXPECT_FALSE(manager_.AddMapping(kClientId2, kServiceId1));
}

}  // namespace gles2
}  // namespace gpu


