// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/posix/unix_domain_socket_posix.h"

#include <array>
#include <cstdint>
#include <string>

#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "gtest/gtest.h"

namespace fml::testing {

TEST(UnixDomainSocketTest, SendsDataAndFileDescriptorsAcrossPair) {
  auto pair = UnixDomainSocket::CreatePair();
  ASSERT_TRUE(pair.has_value());
  auto& [client, server] = *pair;
  ASSERT_TRUE(client.is_valid());
  ASSERT_TRUE(server.is_valid());

  ScopedTemporaryDirectory temp_dir;
  ASSERT_TRUE(temp_dir.fd().is_valid());
  UniqueFD shared_file =
      OpenFile(temp_dir.fd(), "payload.txt", true, FilePermission::kReadWrite);
  ASSERT_TRUE(shared_file.is_valid());
  ASSERT_TRUE(TruncateFile(shared_file, 5));
  {
    FileMapping write_map(shared_file, {FileMapping::Protection::kRead,
                                        FileMapping::Protection::kWrite});
    ASSERT_TRUE(write_map.IsValid());
    const std::array<uint8_t, 5> kContent = {'h', 'e', 'l', 'l', 'o'};
    std::copy(kContent.begin(), kContent.end(), write_map.GetMutableMapping());
  }

  const std::array<uint8_t, 4> kMessage = {1, 2, 3, 4};
  ASSERT_TRUE(client.Send(kMessage, shared_file.get()));

  std::array<uint8_t, 16> rx_buf = {};
  UniqueFD received_fd;
  const ssize_t n = server.Receive(rx_buf, &received_fd);
  ASSERT_EQ(n, 4);
  EXPECT_EQ(rx_buf[0], 1u);
  EXPECT_EQ(rx_buf[3], 4u);
  ASSERT_TRUE(received_fd.is_valid());

  std::string read_back;
  ASSERT_TRUE(ReadFileToString(received_fd, &read_back));
  EXPECT_EQ(read_back, "hello");
}

}  // namespace fml::testing
