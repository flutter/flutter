/*
 * Copyright (C) 2010 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/wtf/text/StringStatics.h"

#include "flutter/sky/engine/wtf/DynamicAnnotations.h"
#include "flutter/sky/engine/wtf/MainThread.h"
#include "flutter/sky/engine/wtf/StaticConstructors.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/StringImpl.h"

namespace WTF {

StringImpl* StringImpl::empty() {
  DEFINE_STATIC_LOCAL(StringImpl, emptyString, (ConstructEmptyString));
  WTF_ANNOTATE_BENIGN_RACE(
      &emptyString, "Benign race on StringImpl::emptyString reference counter");
  return &emptyString;
}

WTF_EXPORT DEFINE_GLOBAL(AtomicString, nullAtom) WTF_EXPORT
    DEFINE_GLOBAL(AtomicString, emptyAtom) WTF_EXPORT
    DEFINE_GLOBAL(AtomicString, starAtom)

        NEVER_INLINE unsigned StringImpl::hashSlowCase() const {
  if (is8Bit())
    setHash(StringHasher::computeHashAndMaskTop8Bits(characters8(), m_length));
  else
    setHash(StringHasher::computeHashAndMaskTop8Bits(characters16(), m_length));
  return existingHash();
}

void AtomicString::init() {
  ASSERT(isMainThread());

  new (NotNull, (void*)&nullAtom) AtomicString;
  new (NotNull, (void*)&emptyAtom) AtomicString("");
}

void StringStatics::init() {
  ASSERT(isMainThread());

  // FIXME: These should be allocated at compile time.
  new (NotNull, (void*)&starAtom)
      AtomicString("*", AtomicString::ConstructFromLiteral);
}

}  // namespace WTF
