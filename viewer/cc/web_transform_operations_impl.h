// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_TRANSFORM_OPERATIONS_IMPL_H_
#define SKY_VIEWER_CC_WEB_TRANSFORM_OPERATIONS_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "cc/animation/transform_operations.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebTransformOperations.h"

namespace sky_viewer_cc {

class WebTransformOperationsImpl : public blink::WebTransformOperations {
 public:
  SKY_VIEWER_CC_EXPORT WebTransformOperationsImpl();
  virtual ~WebTransformOperationsImpl();

  const cc::TransformOperations& AsTransformOperations() const;

  // Implementation of blink::WebTransformOperations methods
  virtual bool canBlendWith(const blink::WebTransformOperations& other) const;
  virtual void appendTranslate(double x, double y, double z);
  virtual void appendRotate(double x, double y, double z, double degrees);
  virtual void appendScale(double x, double y, double z);
  virtual void appendSkew(double x, double y);
  virtual void appendPerspective(double depth);
  virtual void appendMatrix(const SkMatrix44&);
  virtual void appendIdentity();
  virtual bool isIdentity() const;

 private:
  cc::TransformOperations transform_operations_;

  DISALLOW_COPY_AND_ASSIGN(WebTransformOperationsImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_TRANSFORM_OPERATIONS_IMPL_H_
