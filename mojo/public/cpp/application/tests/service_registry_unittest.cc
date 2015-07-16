// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/lib/service_registry.h"

#include "mojo/public/cpp/application/service_connector.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace internal {
namespace {

class TestConnector : public ServiceConnector {
 public:
  explicit TestConnector(int* delete_count) : delete_count_(delete_count) {}
  ~TestConnector() override { (*delete_count_)++; }
  void ConnectToService(ApplicationConnection* application_connection,
                        const std::string& interface_name,
                        ScopedMessagePipeHandle client_handle) override {}

 private:
  int* delete_count_;
};

TEST(ServiceRegistryTest, Ownership) {
  int delete_count = 0;

  // Destruction.
  {
    ServiceRegistry registry;
    registry.SetServiceConnectorForName(new TestConnector(&delete_count),
                                        "TC1");
  }
  EXPECT_EQ(1, delete_count);

  // Removal.
  {
    ServiceRegistry registry;
    ServiceConnector* c = new TestConnector(&delete_count);
    registry.SetServiceConnectorForName(c, "TC1");
    registry.RemoveServiceConnectorForName("TC1");
    EXPECT_EQ(2, delete_count);
  }

  // Multiple.
  {
    ServiceRegistry registry;
    registry.SetServiceConnectorForName(new TestConnector(&delete_count),
                                        "TC1");
    registry.SetServiceConnectorForName(new TestConnector(&delete_count),
                                        "TC2");
  }
  EXPECT_EQ(4, delete_count);

  // Re-addition.
  {
    ServiceRegistry registry;
    registry.SetServiceConnectorForName(new TestConnector(&delete_count),
                                        "TC1");
    registry.SetServiceConnectorForName(new TestConnector(&delete_count),
                                        "TC1");
    EXPECT_EQ(5, delete_count);
  }
  EXPECT_EQ(6, delete_count);
}

}  // namespace
}  // namespace internal
}  // namespace mojo
