// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/iunknown_impl.h"

namespace base {
namespace win {

IUnknownImpl::IUnknownImpl()
    : ref_count_(0) {
}

IUnknownImpl::~IUnknownImpl() {
}

ULONG STDMETHODCALLTYPE IUnknownImpl::AddRef() {
  base::AtomicRefCountInc(&ref_count_);
  return 1;
}

ULONG STDMETHODCALLTYPE IUnknownImpl::Release() {
  if (!base::AtomicRefCountDec(&ref_count_)) {
    delete this;
    return 0;
  }
  return 1;
}

STDMETHODIMP IUnknownImpl::QueryInterface(REFIID riid, void** ppv) {
  if (riid == IID_IUnknown) {
    *ppv = static_cast<IUnknown*>(this);
    AddRef();
    return S_OK;
  }

  *ppv = NULL;
  return E_NOINTERFACE;
}

}  // namespace win
}  // namespace base
