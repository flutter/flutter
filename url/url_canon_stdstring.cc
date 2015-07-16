// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url/url_canon_stdstring.h"

namespace url {

StdStringCanonOutput::StdStringCanonOutput(std::string* str)
    : CanonOutput(), str_(str) {
  cur_len_ = static_cast<int>(str_->size());  // Append to existing data.
  str_->resize(str_->capacity());
  buffer_ = str_->empty() ? NULL : &(*str_)[0];
  buffer_len_ = static_cast<int>(str_->size());
}

StdStringCanonOutput::~StdStringCanonOutput() {
  // Nothing to do, we don't own the string.
}

void StdStringCanonOutput::Complete() {
  str_->resize(cur_len_);
  buffer_len_ = cur_len_;
}

void StdStringCanonOutput::Resize(int sz) {
  str_->resize(sz);
  buffer_ = str_->empty() ? NULL : &(*str_)[0];
  buffer_len_ = sz;
}

}  // namespace url
