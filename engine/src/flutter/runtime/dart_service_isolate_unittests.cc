// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_service_isolate.h"

#include <string>
#include <vector>

#include "flutter/testing/testing.h"

namespace flutter {

TEST(DartServiceIsolateTest, CanAddAndRemoveHandles) {
  ASSERT_EQ(DartServiceIsolate::AddServerStatusCallback(nullptr), 0);
  auto handle = DartServiceIsolate::AddServerStatusCallback([](const auto&) {});
  ASSERT_NE(handle, 0);
  ASSERT_TRUE(DartServiceIsolate::RemoveServerStatusCallback(handle));
}

TEST(DartServiceIsolateTest, NotifiesCallbacksOnServerStateChanged) {
  DartServiceIsolate::OnServerStateChanged(nullptr);

  std::vector<std::string> first_uris;
  auto first_handle = DartServiceIsolate::AddServerStatusCallback(
      [&first_uris](const std::string& uri) { first_uris.push_back(uri); });
  ASSERT_NE(first_handle, 0);
  ASSERT_TRUE(first_uris.empty());

  const std::string expected_uri = "http://127.0.0.1:8181/";
  DartServiceIsolate::OnServerStateChanged(expected_uri.c_str());
  ASSERT_EQ(first_uris.size(), 1u);
  ASSERT_EQ(first_uris[0], expected_uri);

  // Callbacks registered after the server has started receive the cached URI
  // immediately.
  std::vector<std::string> second_uris;
  auto second_handle = DartServiceIsolate::AddServerStatusCallback(
      [&second_uris](const std::string& uri) { second_uris.push_back(uri); });
  ASSERT_NE(second_handle, 0);
  ASSERT_EQ(second_uris.size(), 1u);
  ASSERT_EQ(second_uris[0], expected_uri);

  // Removed callbacks are not notified on subsequent state changes.
  ASSERT_TRUE(DartServiceIsolate::RemoveServerStatusCallback(first_handle));

  // A null URI indicates shutdown and clears the cached URI.
  DartServiceIsolate::OnServerStateChanged(nullptr);
  ASSERT_EQ(first_uris.size(), 1u);
  ASSERT_EQ(second_uris.size(), 2u);
  ASSERT_EQ(second_uris[1], "");

  // Callbacks registered after shutdown do not receive a stale cached URI.
  std::vector<std::string> third_uris;
  auto third_handle = DartServiceIsolate::AddServerStatusCallback(
      [&third_uris](const std::string& uri) { third_uris.push_back(uri); });
  ASSERT_NE(third_handle, 0);
  ASSERT_TRUE(third_uris.empty());

  ASSERT_TRUE(DartServiceIsolate::RemoveServerStatusCallback(second_handle));
  ASSERT_TRUE(DartServiceIsolate::RemoveServerStatusCallback(third_handle));
}

}  // namespace flutter
