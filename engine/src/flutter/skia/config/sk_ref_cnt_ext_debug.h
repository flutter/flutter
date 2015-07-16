// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SK_REF_CNT_EXT_DEBUG_H_
#define SK_REF_CNT_EXT_DEBUG_H_

#ifdef SK_REF_CNT_EXT_RELEASE_H_
#error Only one SkRefCnt should be used.
#endif

// Alternate implementation of SkRefCnt for Chromium debug builds
class SK_API SkRefCnt : public SkRefCntBase {
public:
  SkRefCnt() : flags_(0) {}
  void ref() const { SkASSERT(flags_ != AdoptionRequired_Flag); SkRefCntBase::ref(); }
  void adopted() const { flags_ |= Adopted_Flag; }
  void requireAdoption() const { flags_ |= AdoptionRequired_Flag; }
  void deref() const { SkRefCntBase::unref(); }
private:
  enum {
    Adopted_Flag = 0x1,
    AdoptionRequired_Flag = 0x2,
  };

  mutable int flags_;
};

// Bootstrap for Blink's WTF::RefPtr

namespace WTF {
  inline void adopted(const SkRefCnt* object) {
    if (!object)
      return;
    object->adopted();
  }
  inline void requireAdoption(const SkRefCnt* object) {
    if (!object)
      return;
    object->requireAdoption();
  }
};

using WTF::adopted;
using WTF::requireAdoption;

#endif

