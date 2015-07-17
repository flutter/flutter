// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This code implements SPAKE2, a variant of EKE:
//  http://www.di.ens.fr/~pointche/pub.php?reference=AbPo04

#include <crypto/p224_spake.h>

#include <algorithm>

#include <base/logging.h>
#include <crypto/p224.h>
#include <crypto/random.h>
#include <crypto/secure_util.h>

namespace {

// The following two points (M and N in the protocol) are verifiable random
// points on the curve and can be generated with the following code:

// #include <stdint.h>
// #include <stdio.h>
// #include <string.h>
//
// #include <openssl/ec.h>
// #include <openssl/obj_mac.h>
// #include <openssl/sha.h>
//
// static const char kSeed1[] = "P224 point generation seed (M)";
// static const char kSeed2[] = "P224 point generation seed (N)";
//
// void find_seed(const char* seed) {
//   SHA256_CTX sha256;
//   uint8_t digest[SHA256_DIGEST_LENGTH];
//
//   SHA256_Init(&sha256);
//   SHA256_Update(&sha256, seed, strlen(seed));
//   SHA256_Final(digest, &sha256);
//
//   BIGNUM x, y;
//   EC_GROUP* p224 = EC_GROUP_new_by_curve_name(NID_secp224r1);
//   EC_POINT* p = EC_POINT_new(p224);
//
//   for (unsigned i = 0;; i++) {
//     BN_init(&x);
//     BN_bin2bn(digest, 28, &x);
//
//     if (EC_POINT_set_compressed_coordinates_GFp(
//             p224, p, &x, digest[28] & 1, NULL)) {
//       BN_init(&y);
//       EC_POINT_get_affine_coordinates_GFp(p224, p, &x, &y, NULL);
//       char* x_str = BN_bn2hex(&x);
//       char* y_str = BN_bn2hex(&y);
//       printf("Found after %u iterations:\n%s\n%s\n", i, x_str, y_str);
//       OPENSSL_free(x_str);
//       OPENSSL_free(y_str);
//       BN_free(&x);
//       BN_free(&y);
//       break;
//     }
//
//     SHA256_Init(&sha256);
//     SHA256_Update(&sha256, digest, sizeof(digest));
//     SHA256_Final(digest, &sha256);
//
//     BN_free(&x);
//   }
//
//   EC_POINT_free(p);
//   EC_GROUP_free(p224);
// }
//
// int main() {
//   find_seed(kSeed1);
//   find_seed(kSeed2);
//   return 0;
// }

const crypto::p224::Point kM = {
  {174237515, 77186811, 235213682, 33849492,
   33188520, 48266885, 177021753, 81038478},
  {104523827, 245682244, 266509668, 236196369,
   28372046, 145351378, 198520366, 113345994},
  {1, 0, 0, 0, 0, 0, 0, 0},
};

const crypto::p224::Point kN = {
  {136176322, 263523628, 251628795, 229292285,
   5034302, 185981975, 171998428, 11653062},
  {197567436, 51226044, 60372156, 175772188,
   42075930, 8083165, 160827401, 65097570},
  {1, 0, 0, 0, 0, 0, 0, 0},
};

}  // anonymous namespace

namespace crypto {

P224EncryptedKeyExchange::P224EncryptedKeyExchange(
    PeerType peer_type, const base::StringPiece& password)
    : state_(kStateInitial),
      is_server_(peer_type == kPeerTypeServer) {
  memset(&x_, 0, sizeof(x_));
  memset(&expected_authenticator_, 0, sizeof(expected_authenticator_));

  // x_ is a random scalar.
  RandBytes(x_, sizeof(x_));

  // Calculate |password| hash to get SPAKE password value.
  SHA256HashString(std::string(password.data(), password.length()),
                   pw_, sizeof(pw_));

  Init();
}

void P224EncryptedKeyExchange::Init() {
  // X = g**x_
  p224::Point X;
  p224::ScalarBaseMult(x_, &X);

  // The client masks the Diffie-Hellman value, X, by adding M**pw and the
  // server uses N**pw.
  p224::Point MNpw;
  p224::ScalarMult(is_server_ ? kN : kM, pw_, &MNpw);

  // X* = X + (N|M)**pw
  p224::Point Xstar;
  p224::Add(X, MNpw, &Xstar);

  next_message_ = Xstar.ToString();
}

const std::string& P224EncryptedKeyExchange::GetNextMessage() {
  if (state_ == kStateInitial) {
    state_ = kStateRecvDH;
    return next_message_;
  } else if (state_ == kStateSendHash) {
    state_ = kStateRecvHash;
    return next_message_;
  }

  LOG(FATAL) << "P224EncryptedKeyExchange::GetNextMessage called in"
                " bad state " << state_;
  next_message_ = "";
  return next_message_;
}

P224EncryptedKeyExchange::Result P224EncryptedKeyExchange::ProcessMessage(
    const base::StringPiece& message) {
  if (state_ == kStateRecvHash) {
    // This is the final state of the protocol: we are reading the peer's
    // authentication hash and checking that it matches the one that we expect.
    if (message.size() != sizeof(expected_authenticator_)) {
      error_ = "peer's hash had an incorrect size";
      return kResultFailed;
    }
    if (!SecureMemEqual(message.data(), expected_authenticator_,
                        message.size())) {
      error_ = "peer's hash had incorrect value";
      return kResultFailed;
    }
    state_ = kStateDone;
    return kResultSuccess;
  }

  if (state_ != kStateRecvDH) {
    LOG(FATAL) << "P224EncryptedKeyExchange::ProcessMessage called in"
                  " bad state " << state_;
    error_ = "internal error";
    return kResultFailed;
  }

  // Y* is the other party's masked, Diffie-Hellman value.
  p224::Point Ystar;
  if (!Ystar.SetFromString(message)) {
    error_ = "failed to parse peer's masked Diffie-Hellman value";
    return kResultFailed;
  }

  // We calculate the mask value: (N|M)**pw
  p224::Point MNpw, minus_MNpw, Y, k;
  p224::ScalarMult(is_server_ ? kM : kN, pw_, &MNpw);
  p224::Negate(MNpw, &minus_MNpw);

  // Y = Y* - (N|M)**pw
  p224::Add(Ystar, minus_MNpw, &Y);

  // K = Y**x_
  p224::ScalarMult(Y, x_, &k);

  // If everything worked out, then K is the same for both parties.
  key_ = k.ToString();

  std::string client_masked_dh, server_masked_dh;
  if (is_server_) {
    client_masked_dh = message.as_string();
    server_masked_dh = next_message_;
  } else {
    client_masked_dh = next_message_;
    server_masked_dh = message.as_string();
  }

  // Now we calculate the hashes that each side will use to prove to the other
  // that they derived the correct value for K.
  uint8 client_hash[kSHA256Length], server_hash[kSHA256Length];
  CalculateHash(kPeerTypeClient, client_masked_dh, server_masked_dh, key_,
                client_hash);
  CalculateHash(kPeerTypeServer, client_masked_dh, server_masked_dh, key_,
                server_hash);

  const uint8* my_hash = is_server_ ? server_hash : client_hash;
  const uint8* their_hash = is_server_ ? client_hash : server_hash;

  next_message_ =
      std::string(reinterpret_cast<const char*>(my_hash), kSHA256Length);
  memcpy(expected_authenticator_, their_hash, kSHA256Length);
  state_ = kStateSendHash;
  return kResultPending;
}

void P224EncryptedKeyExchange::CalculateHash(
    PeerType peer_type,
    const std::string& client_masked_dh,
    const std::string& server_masked_dh,
    const std::string& k,
    uint8* out_digest) {
  std::string hash_contents;

  if (peer_type == kPeerTypeServer) {
    hash_contents = "server";
  } else {
    hash_contents = "client";
  }

  hash_contents += client_masked_dh;
  hash_contents += server_masked_dh;
  hash_contents +=
      std::string(reinterpret_cast<const char *>(pw_), sizeof(pw_));
  hash_contents += k;

  SHA256HashString(hash_contents, out_digest, kSHA256Length);
}

const std::string& P224EncryptedKeyExchange::error() const {
  return error_;
}

const std::string& P224EncryptedKeyExchange::GetKey() const {
  DCHECK_EQ(state_, kStateDone);
  return GetUnverifiedKey();
}

const std::string& P224EncryptedKeyExchange::GetUnverifiedKey() const {
  // Key is already final when state is kStateSendHash. Subsequent states are
  // used only for verification of the key. Some users may combine verification
  // with sending verifiable data instead of |expected_authenticator_|.
  DCHECK_GE(state_, kStateSendHash);
  return key_;
}

void P224EncryptedKeyExchange::SetXForTesting(const std::string& x) {
  memset(&x_, 0, sizeof(x_));
  memcpy(&x_, x.data(), std::min(x.size(), sizeof(x_)));
  Init();
}

}  // namespace crypto
