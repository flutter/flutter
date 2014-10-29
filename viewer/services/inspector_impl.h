// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_SERVICES_INSPECTOR_IMPL_H_
#define SKY_VIEWER_SERVICES_INSPECTOR_IMPL_H_

#include "base/basictypes.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "sky/viewer/services/inspector.mojom.h"

namespace sky {
class DocumentView;

class InspectorServiceImpl : public mojo::InterfaceImpl<InspectorService> {
 public:
  explicit InspectorServiceImpl(DocumentView*);
  virtual ~InspectorServiceImpl();

 private:
  // Overridden from InspectorService:
  void Inject() override;

  base::WeakPtr<DocumentView> view_;

  DISALLOW_COPY_AND_ASSIGN(InspectorServiceImpl);
};

typedef mojo::InterfaceFactoryImplWithContext<
    InspectorServiceImpl, DocumentView> InspectorServiceFactory;

}  // namespace sky

#endif  // SKY_VIEWER_SERVICES_INSPECTOR_IMPL_H_
