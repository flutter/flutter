// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/secure_hash.h"

#include "base/logging.h"
#include "base/pickle.h"
#include "crypto/third_party/nss/chromium-blapi.h"
#include "crypto/third_party/nss/chromium-sha256.h"

namespace crypto {

namespace {

const char kSHA256Descriptor[] = "NSS";

class SecureHashSHA256NSS : public SecureHash {
 public:
  static const int kSecureHashVersion = 1;

  SecureHashSHA256NSS() {
    SHA256_Begin(&ctx_);
  }

  ~SecureHashSHA256NSS() override { memset(&ctx_, 0, sizeof(ctx_)); }

  // SecureHash implementation:
  void Update(const void* input, size_t len) override {
    SHA256_Update(&ctx_, static_cast<const unsigned char*>(input), len);
  }

  void Finish(void* output, size_t len) override {
    SHA256_End(&ctx_, static_cast<unsigned char*>(output), NULL,
               static_cast<unsigned int>(len));
  }

  bool Serialize(base::Pickle* pickle) override;
  bool Deserialize(base::PickleIterator* data_iterator) override;

 private:
  SHA256Context ctx_;
};

bool SecureHashSHA256NSS::Serialize(base::Pickle* pickle) {
  if (!pickle)
    return false;

  if (!pickle->WriteInt(kSecureHashVersion) ||
      !pickle->WriteString(kSHA256Descriptor) ||
      !pickle->WriteBytes(&ctx_, sizeof(ctx_))) {
    return false;
  }

  return true;
}

bool SecureHashSHA256NSS::Deserialize(base::PickleIterator* data_iterator) {
  int version;
  if (!data_iterator->ReadInt(&version))
    return false;

  if (version > kSecureHashVersion)
    return false;  // We don't know how to deal with this.

  std::string type;
  if (!data_iterator->ReadString(&type))
    return false;

  if (type != kSHA256Descriptor)
    return false;  // It's the wrong kind.

  const char* data = NULL;
  if (!data_iterator->ReadBytes(&data, sizeof(ctx_)))
    return false;

  memcpy(&ctx_, data, sizeof(ctx_));

  return true;
}

}  // namespace

SecureHash* SecureHash::Create(Algorithm algorithm) {
  switch (algorithm) {
    case SHA256:
      return new SecureHashSHA256NSS();
    default:
      NOTIMPLEMENTED();
      return NULL;
  }
}

}  // namespace crypto
