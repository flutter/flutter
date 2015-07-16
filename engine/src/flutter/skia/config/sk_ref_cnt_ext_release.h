// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SK_REF_CNT_EXT_RELEASE_H_
#define SK_REF_CNT_EXT_RELEASE_H_

#ifdef SK_REF_CNT_EXT_DEBUG_H_
#error Only one SkRefCnt should be used.
#endif

// Alternate implementation of SkRefCnt for Chromium release builds
class SK_API SkRefCnt : public SkRefCntBase {
public:
  void deref() const { SkRefCntBase::unref(); }
};

#endif

