// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_WTF_ADDRESSSPACERANDOMIZATION_H_
#define SKY_ENGINE_WTF_ADDRESSSPACERANDOMIZATION_H_

#include "flutter/sky/engine/wtf/WTFExport.h"

namespace WTF {

// Calculates a random preferred mapping address. In calculating an
// address, we balance good ASLR against not fragmenting the address
// space too badly.
WTF_EXPORT void* getRandomPageBase();

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_ADDRESSSPACERANDOMIZATION_H_
