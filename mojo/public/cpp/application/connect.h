// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_APPLICATION_CONNECT_H_
#define MOJO_PUBLIC_CPP_APPLICATION_CONNECT_H_

#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace mojo {

// Binds |ptr| to a remote implementation of Interface from |service_provider|.
template <typename Interface>
inline void ConnectToService(ServiceProvider* service_provider,
                             InterfacePtr<Interface>* ptr) {
  MessagePipe pipe;
  ptr->Bind(InterfacePtrInfo<Interface>(pipe.handle0.Pass(), 0u));
  service_provider->ConnectToService(Interface::Name_, pipe.handle1.Pass());
}

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_APPLICATION_CONNECT_H_
