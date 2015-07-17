// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/p224_spake.h"

#include <string>

#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

namespace {

std::string HexEncodeString(const std::string& binary_data) {
  return base::HexEncode(binary_data.c_str(), binary_data.size());
}

bool RunExchange(P224EncryptedKeyExchange* client,
                 P224EncryptedKeyExchange* server,
                 bool is_password_same) {
  for (;;) {
    std::string client_message, server_message;
    client_message = client->GetNextMessage();
    server_message = server->GetNextMessage();

    P224EncryptedKeyExchange::Result client_result, server_result;
    client_result = client->ProcessMessage(server_message);
    server_result = server->ProcessMessage(client_message);

    // Check that we never hit the case where only one succeeds.
    EXPECT_EQ(client_result == P224EncryptedKeyExchange::kResultSuccess,
              server_result == P224EncryptedKeyExchange::kResultSuccess);

    if (client_result == P224EncryptedKeyExchange::kResultFailed ||
        server_result == P224EncryptedKeyExchange::kResultFailed) {
      return false;
    }

    EXPECT_EQ(is_password_same,
              client->GetUnverifiedKey() == server->GetUnverifiedKey());

    if (client_result == P224EncryptedKeyExchange::kResultSuccess &&
        server_result == P224EncryptedKeyExchange::kResultSuccess) {
      return true;
    }

    EXPECT_EQ(P224EncryptedKeyExchange::kResultPending, client_result);
    EXPECT_EQ(P224EncryptedKeyExchange::kResultPending, server_result);
  }
}

const char kPassword[] = "foo";

}  // namespace

TEST(MutualAuth, CorrectAuth) {
  P224EncryptedKeyExchange client(
      P224EncryptedKeyExchange::kPeerTypeClient, kPassword);
  P224EncryptedKeyExchange server(
      P224EncryptedKeyExchange::kPeerTypeServer, kPassword);

  EXPECT_TRUE(RunExchange(&client, &server, true));
  EXPECT_EQ(client.GetKey(), server.GetKey());
}

TEST(MutualAuth, IncorrectPassword) {
  P224EncryptedKeyExchange client(
      P224EncryptedKeyExchange::kPeerTypeClient,
      kPassword);
  P224EncryptedKeyExchange server(
      P224EncryptedKeyExchange::kPeerTypeServer,
      "wrongpassword");

  EXPECT_FALSE(RunExchange(&client, &server, false));
}

TEST(MutualAuth, ExpectedValues) {
  P224EncryptedKeyExchange client(P224EncryptedKeyExchange::kPeerTypeClient,
                                  kPassword);
  client.SetXForTesting("Client x");
  P224EncryptedKeyExchange server(P224EncryptedKeyExchange::kPeerTypeServer,
                                  kPassword);
  server.SetXForTesting("Server x");

  std::string client_message = client.GetNextMessage();
  EXPECT_EQ(
      "3508EF7DECC8AB9F9C439FBB0154288BBECC0A82E8448F4CF29554EB"
      "BE9D486686226255EAD1D077C635B1A41F46AC91D7F7F32CED9EC3E0",
      HexEncodeString(client_message));

  std::string server_message = server.GetNextMessage();
  EXPECT_EQ(
      "A3088C18B75D2C2B107105661AEC85424777475EB29F1DDFB8C14AFB"
      "F1603D0DF38413A00F420ACF2059E7997C935F5A957A193D09A2B584",
      HexEncodeString(server_message));

  EXPECT_EQ(P224EncryptedKeyExchange::kResultPending,
            client.ProcessMessage(server_message));
  EXPECT_EQ(P224EncryptedKeyExchange::kResultPending,
            server.ProcessMessage(client_message));

  EXPECT_EQ(client.GetUnverifiedKey(), server.GetUnverifiedKey());
  // Must stay the same. External implementations should be able to pair with.
  EXPECT_EQ(
      "CE7CCFC435CDA4F01EC8826788B1F8B82EF7D550A34696B371096E64"
      "C487D4FE193F7D1A6FF6820BC7F807796BA3889E8F999BBDEFC32FFA",
      HexEncodeString(server.GetUnverifiedKey()));

  EXPECT_TRUE(RunExchange(&client, &server, true));
  EXPECT_EQ(client.GetKey(), server.GetKey());
}

TEST(MutualAuth, Fuzz) {
  static const unsigned kIterations = 40;

  for (unsigned i = 0; i < kIterations; i++) {
    P224EncryptedKeyExchange client(
        P224EncryptedKeyExchange::kPeerTypeClient, kPassword);
    P224EncryptedKeyExchange server(
        P224EncryptedKeyExchange::kPeerTypeServer, kPassword);

    // We'll only be testing small values of i, but we don't want that to bias
    // the test coverage. So we disperse the value of i by multiplying by the
    // FNV, 32-bit prime, producing a poor-man's PRNG.
    const uint32 rand = i * 16777619;

    for (unsigned round = 0;; round++) {
      std::string client_message, server_message;
      client_message = client.GetNextMessage();
      server_message = server.GetNextMessage();

      if ((rand & 1) == round) {
        const bool server_or_client = rand & 2;
        std::string* m = server_or_client ? &server_message : &client_message;
        if (rand & 4) {
          // Truncate
          *m = m->substr(0, (i >> 3) % m->size());
        } else {
          // Corrupt
          const size_t bits = m->size() * 8;
          const size_t bit_to_corrupt = (rand >> 3) % bits;
          const_cast<char*>(m->data())[bit_to_corrupt / 8] ^=
              1 << (bit_to_corrupt % 8);
        }
      }

      P224EncryptedKeyExchange::Result client_result, server_result;
      client_result = client.ProcessMessage(server_message);
      server_result = server.ProcessMessage(client_message);

      // If we have corrupted anything, we expect the authentication to fail,
      // although one side can succeed if we happen to corrupt the second round
      // message to the other.
      ASSERT_FALSE(
          client_result == P224EncryptedKeyExchange::kResultSuccess &&
          server_result == P224EncryptedKeyExchange::kResultSuccess);

      if (client_result == P224EncryptedKeyExchange::kResultFailed ||
          server_result == P224EncryptedKeyExchange::kResultFailed) {
        break;
      }

      ASSERT_EQ(P224EncryptedKeyExchange::kResultPending,
                client_result);
      ASSERT_EQ(P224EncryptedKeyExchange::kResultPending,
                server_result);
    }
  }
}

}  // namespace crypto
