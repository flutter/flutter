// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_bstr.h"

#include "base/logging.h"

namespace base {
namespace win {

ScopedBstr::ScopedBstr(const char16* non_bstr)
    : bstr_(SysAllocString(non_bstr)) {
}

ScopedBstr::~ScopedBstr() {
  COMPILE_ASSERT(sizeof(ScopedBstr) == sizeof(BSTR), ScopedBstrSize);
  SysFreeString(bstr_);
}

void ScopedBstr::Reset(BSTR bstr) {
  if (bstr != bstr_) {
    // if |bstr_| is NULL, SysFreeString does nothing.
    SysFreeString(bstr_);
    bstr_ = bstr;
  }
}

BSTR ScopedBstr::Release() {
  BSTR bstr = bstr_;
  bstr_ = NULL;
  return bstr;
}

void ScopedBstr::Swap(ScopedBstr& bstr2) {
  BSTR tmp = bstr_;
  bstr_ = bstr2.bstr_;
  bstr2.bstr_ = tmp;
}

BSTR* ScopedBstr::Receive() {
  DCHECK(!bstr_) << "BSTR leak.";
  return &bstr_;
}

BSTR ScopedBstr::Allocate(const char16* str) {
  Reset(SysAllocString(str));
  return bstr_;
}

BSTR ScopedBstr::AllocateBytes(size_t bytes) {
  Reset(SysAllocStringByteLen(NULL, static_cast<UINT>(bytes)));
  return bstr_;
}

void ScopedBstr::SetByteLen(size_t bytes) {
  DCHECK(bstr_ != NULL) << "attempting to modify a NULL bstr";
  uint32* data = reinterpret_cast<uint32*>(bstr_);
  data[-1] = static_cast<uint32>(bytes);
}

size_t ScopedBstr::Length() const {
  return SysStringLen(bstr_);
}

size_t ScopedBstr::ByteLength() const {
  return SysStringByteLen(bstr_);
}

}  // namespace win
}  // namespace base
