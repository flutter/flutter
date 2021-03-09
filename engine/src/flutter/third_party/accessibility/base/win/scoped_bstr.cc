// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_bstr.h"

#include <stdint.h>

#include "base/check.h"
#include "base/numerics/safe_conversions.h"
#include "base/process/memory.h"
#include "base/strings/string_util.h"

namespace base {
namespace win {

namespace {

BSTR AllocBstrOrDie(WStringPiece non_bstr) {
  BSTR result = ::SysAllocStringLen(non_bstr.data(),
                                    checked_cast<UINT>(non_bstr.length()));
  if (!result) {
    base::TerminateBecauseOutOfMemory((non_bstr.length() + 1) *
                                      sizeof(wchar_t));
  }
  return result;
}

BSTR AllocBstrBytesOrDie(size_t bytes) {
  BSTR result = ::SysAllocStringByteLen(nullptr, checked_cast<UINT>(bytes));
  if (!result)
    base::TerminateBecauseOutOfMemory(bytes + sizeof(wchar_t));
  return result;
}

}  // namespace

ScopedBstr::ScopedBstr(WStringPiece non_bstr)
    : bstr_(AllocBstrOrDie(non_bstr)) {}

ScopedBstr::~ScopedBstr() {
  static_assert(sizeof(ScopedBstr) == sizeof(BSTR), "ScopedBstrSize");
  ::SysFreeString(bstr_);
}

void ScopedBstr::Reset(BSTR bstr) {
  if (bstr != bstr_) {
    // SysFreeString handles null properly.
    ::SysFreeString(bstr_);
    bstr_ = bstr;
  }
}

BSTR ScopedBstr::Release() {
  BSTR bstr = bstr_;
  bstr_ = nullptr;
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

BSTR ScopedBstr::Allocate(WStringPiece str) {
  Reset(AllocBstrOrDie(str));
  return bstr_;
}

BSTR ScopedBstr::AllocateBytes(size_t bytes) {
  Reset(AllocBstrBytesOrDie(bytes));
  return bstr_;
}

void ScopedBstr::SetByteLen(size_t bytes) {
  DCHECK(bstr_);
  uint32_t* data = reinterpret_cast<uint32_t*>(bstr_);
  data[-1] = checked_cast<uint32_t>(bytes);
}

size_t ScopedBstr::Length() const {
  return ::SysStringLen(bstr_);
}

size_t ScopedBstr::ByteLength() const {
  return ::SysStringByteLen(bstr_);
}

}  // namespace win
}  // namespace base
