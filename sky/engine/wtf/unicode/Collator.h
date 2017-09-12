/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_UNICODE_COLLATOR_H_
#define SKY_ENGINE_WTF_UNICODE_COLLATOR_H_

#include "flutter/sky/engine/wtf/FastAllocBase.h"
#include "flutter/sky/engine/wtf/Noncopyable.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/sky/engine/wtf/WTFExport.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

struct UCollator;

namespace WTF {

class WTF_EXPORT Collator {
  WTF_MAKE_NONCOPYABLE(Collator);
  WTF_MAKE_FAST_ALLOCATED;

 public:
  enum Result { Equal = 0, Greater = 1, Less = -1 };

  Collator(const char* locale);  // Parsing is lenient; e.g. language
                                 // identifiers (such as "en-US") are accepted,
                                 // too.
  ~Collator();
  void setOrderLowerFirst(bool);

  static PassOwnPtr<Collator> userDefault();

  Result collate(const ::UChar*, size_t, const ::UChar*, size_t) const;

 private:
  void createCollator() const;
  void releaseCollator();
  mutable UCollator* m_collator;
  char* m_locale;
  bool m_lowerFirst;
};
}  // namespace WTF

using WTF::Collator;

#endif  // SKY_ENGINE_WTF_UNICODE_COLLATOR_H_
