// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/build_config.h"
#include "flutter/fml/log_settings.h"
#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

#if defined(OS_FUCHSIA)
#include <lib/syslog/global.h>
#include <lib/syslog/logger.h>
#include <lib/syslog/wire_format.h>
#include <lib/zx/socket.h>

#include "gmock/gmock.h"
#endif

namespace fml {
namespace testing {

int UnreachableScopeWithoutReturnDoesNotMakeCompilerMad() {
  KillProcess();
  // return 0; <--- Missing but compiler is fine.
}

int UnreachableScopeWithMacroWithoutReturnDoesNotMakeCompilerMad() {
  FML_UNREACHABLE();
  // return 0; <--- Missing but compiler is fine.
}

TEST(LoggingTest, UnreachableKillProcess) {
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH(KillProcess(), "");
}

TEST(LoggingTest, UnreachableKillProcessWithMacro) {
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({ FML_UNREACHABLE(); }, "");
}

#if defined(OS_FUCHSIA)

struct LogPacket {
  fx_log_metadata_t metadata;
  std::vector<std::string> tags;
  std::string message;
};

class LoggingSocketTest : public ::testing::Test {
 protected:
  void SetUp() override {
    zx::socket local;
    ASSERT_EQ(ZX_OK, zx::socket::create(ZX_SOCKET_DATAGRAM, &local, &socket_));

    fx_logger_config_t config = {
        .min_severity = FX_LOG_INFO,
        .console_fd = -1,
        .log_sink_socket = local.release(),
        .tags = nullptr,
        .num_tags = 0,
    };

    fx_log_reconfigure(&config);
  }

  LogPacket ReadPacket() {
    LogPacket result;
    fx_log_packet_t packet;
    zx_status_t res = socket_.read(0, &packet, sizeof(packet), nullptr);
    EXPECT_EQ(ZX_OK, res);
    result.metadata = packet.metadata;
    int pos = 0;
    while (packet.data[pos]) {
      int tag_len = packet.data[pos++];
      result.tags.emplace_back(packet.data + pos, tag_len);
      pos += tag_len;
    }
    result.message.append(packet.data + pos + 1);
    return result;
  }

  void ReadPacketAndCompare(fx_log_severity_t severity,
                            const std::string& message,
                            const std::vector<std::string>& tags = {}) {
    LogPacket packet = ReadPacket();
    EXPECT_EQ(severity, packet.metadata.severity);
    EXPECT_THAT(packet.message, ::testing::EndsWith(message));
    EXPECT_EQ(tags, packet.tags);
  }

  void CheckSocketEmpty() {
    zx_info_socket_t info = {};
    zx_status_t status =
        socket_.get_info(ZX_INFO_SOCKET, &info, sizeof(info), nullptr, nullptr);
    ASSERT_EQ(ZX_OK, status);
    EXPECT_EQ(0u, info.rx_buf_available);
  }

  zx::socket socket_;
};

TEST_F(LoggingSocketTest, UseSyslogOnFuchsia) {
  const char* msg1 = "test message";
  const char* msg2 = "hello";
  const char* msg3 = "logging";
  const char* msg4 = "Another message";
  const char* msg5 = "Foo";

  fml::SetLogSettings({.min_log_level = -1});

  FML_LOG(INFO) << msg1;
  ReadPacketAndCompare(FX_LOG_INFO, msg1);
  CheckSocketEmpty();

  FML_LOG(WARNING) << msg2;
  ReadPacketAndCompare(FX_LOG_WARNING, msg2);
  CheckSocketEmpty();

  FML_LOG(ERROR) << msg3;
  ReadPacketAndCompare(FX_LOG_ERROR, msg3);
  CheckSocketEmpty();

  FML_VLOG(1) << msg4;
  ReadPacketAndCompare(fx_log_severity_from_verbosity(1), msg4);
  CheckSocketEmpty();

  // VLOG(2) is not enabled so the log gets dropped.
  FML_VLOG(2) << msg5;
  CheckSocketEmpty();
}

#endif

}  // namespace testing
}  // namespace fml
