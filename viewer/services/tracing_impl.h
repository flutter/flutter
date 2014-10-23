// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_SERVICES_TRACING_IMPL_H_
#define SKY_VIEWER_SERVICES_TRACING_IMPL_H_

#include "base/basictypes.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "sky/viewer/services/tracing.mojom.h"

namespace sky {

class TracingImpl : public mojo::InterfaceImpl<Tracing> {
 public:
  TracingImpl();
  virtual ~TracingImpl();

 private:
  // Overridden from Tracing:
  void Start() override;
  void Stop() override;

  DISALLOW_COPY_AND_ASSIGN(TracingImpl);
};

typedef mojo::InterfaceFactoryImpl<TracingImpl> TracingFactory;

}  // namespace sky

#endif  // SKY_VIEWER_SERVICES_TRACING_IMPL_H_
