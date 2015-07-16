// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_CONTEXT_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_CONTEXT_H_

#include <string>
#include <vector>

#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
class ApplicationImpl;

class ViewManagerContext {
 public:
  explicit ViewManagerContext(ApplicationImpl* application_impl);
  ~ViewManagerContext();

  // Embed an application @ |url| at an appropriate View.
  // The first time this method is called in the life time of the View Manager
  // service the "appropriate View" is defined as being the service' root View.
  // Subsequent times, the implementation of this method is delegated to the
  // application embedded at the service root View. This application will have a
  // specific definition of where within its View hierarchy to embed an
  // un-parented URL.
  // |services| encapsulates services offered by the embedder to the embedded
  // app alongside this Embed() call. |exposed_services| provides a means for
  // the embedder to connect to services exposed by the embedded app.
  void Embed(const String& url);
  void Embed(const String& url,
             InterfaceRequest<ServiceProvider> services,
             ServiceProviderPtr exposed_Services);

 private:
  class InternalState;
  InternalState* state_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ViewManagerContext);
};

}  // namespace mojo

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_CONTEXT_H_
