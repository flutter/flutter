// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/openssl_bio_string.h"

#include <openssl/bio.h>
#include <string.h>

namespace crypto {

namespace {

int bio_string_write(BIO* bio, const char* data, int len) {
  reinterpret_cast<std::string*>(bio->ptr)->append(data, len);
  return len;
}

int bio_string_puts(BIO* bio, const char* data) {
  // Note: unlike puts(), BIO_puts does not add a newline.
  return bio_string_write(bio, data, strlen(data));
}

long bio_string_ctrl(BIO* bio, int cmd, long num, void* ptr) {
  std::string* str = reinterpret_cast<std::string*>(bio->ptr);
  switch (cmd) {
    case BIO_CTRL_RESET:
      str->clear();
      return 1;
    case BIO_C_FILE_SEEK:
      return -1;
    case BIO_C_FILE_TELL:
      return str->size();
    case BIO_CTRL_FLUSH:
      return 1;
    default:
      return 0;
  }
}

int bio_string_new(BIO* bio) {
  bio->ptr = NULL;
  bio->init = 0;
  return 1;
}

int bio_string_free(BIO* bio) {
  // The string is owned by the caller, so there's nothing to do here.
  return bio != NULL;
}

BIO_METHOD bio_string_methods = {
    // TODO(mattm): Should add some type number too? (bio.h uses 1-24)
    BIO_TYPE_SOURCE_SINK,
    "bio_string",
    bio_string_write,
    NULL, /* read */
    bio_string_puts,
    NULL, /* gets */
    bio_string_ctrl,
    bio_string_new,
    bio_string_free,
    NULL, /* callback_ctrl */
};

}  // namespace

BIO* BIO_new_string(std::string* out) {
  BIO* bio = BIO_new(&bio_string_methods);
  if (!bio)
    return bio;
  bio->ptr = out;
  bio->init = 1;
  return bio;
}

}  // namespace crypto
