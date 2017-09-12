/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_TRANSFORMS_PERSPECTIVETRANSFORMOPERATION_H_
#define SKY_ENGINE_PLATFORM_TRANSFORMS_PERSPECTIVETRANSFORMOPERATION_H_

#include "flutter/sky/engine/platform/transforms/TransformOperation.h"

namespace blink {

class PLATFORM_EXPORT PerspectiveTransformOperation
    : public TransformOperation {
 public:
  static PassRefPtr<PerspectiveTransformOperation> create(double p) {
    return adoptRef(new PerspectiveTransformOperation(p));
  }

  double perspective() const { return m_p; }

  virtual bool canBlendWith(const TransformOperation& other) const {
    return isSameType(other);
  }

 private:
  virtual bool isIdentity() const override { return !m_p; }
  virtual OperationType type() const override { return Perspective; }

  virtual bool operator==(const TransformOperation& o) const override {
    if (!isSameType(o))
      return false;
    const PerspectiveTransformOperation* p =
        static_cast<const PerspectiveTransformOperation*>(&o);
    return m_p == p->m_p;
  }

  virtual void apply(TransformationMatrix& transform,
                     const FloatSize&) const override {
    transform.applyPerspective(m_p);
  }

  virtual PassRefPtr<TransformOperation> blend(
      const TransformOperation* from,
      double progress,
      bool blendToIdentity = false) override;

  PerspectiveTransformOperation(double p) : m_p(p) {}

  double m_p;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_TRANSFORMS_PERSPECTIVETRANSFORMOPERATION_H_
