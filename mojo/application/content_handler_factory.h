// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_APPLICATION_CONTENT_HANDLER_FACTORY_H_
#define MOJO_APPLICATION_CONTENT_HANDLER_FACTORY_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"
#include "mojo/services/network/interfaces/url_loader.mojom.h"

namespace mojo {

struct ConnectionContext;

// TODO(vtl): Nuke this class. Now it's only a "namespace" for stuff, most of
// which is overcomplicated.
class ContentHandlerFactory {
 public:
  class HandledApplicationHolder {
   public:
    virtual ~HandledApplicationHolder() {}
  };

  class Delegate {
   public:
    virtual ~Delegate() {}
    // Implement this method to create the Application. This method will be
    // called on a new thread. Leaving this method will quit the application.
    virtual void RunApplication(
        InterfaceRequest<Application> application_request,
        URLResponsePtr response) = 0;
  };

  class ManagedDelegate : public Delegate {
   public:
    ~ManagedDelegate() override {}
    // Implement this method to create the Application for the given content.
    // This method will be called on a new thread. The application will be run
    // on this new thread, and the returned value will be kept alive until the
    // application ends.
    virtual scoped_ptr<HandledApplicationHolder> CreateApplication(
        InterfaceRequest<Application> application_request,
        URLResponsePtr response) = 0;

   private:
    void RunApplication(InterfaceRequest<Application> application_request,
                        URLResponsePtr response) override;
  };

  // For use with |ServiceProviderImpl::AddService<ContentHandler>()|.
  static ServiceProviderImpl::InterfaceRequestHandler<ContentHandler>
  GetInterfaceRequestHandler(Delegate* delegate);
};

template <class A>
class HandledApplicationHolderImpl
    : public ContentHandlerFactory::HandledApplicationHolder {
 public:
  explicit HandledApplicationHolderImpl(A* value) : value_(value) {}

 private:
  scoped_ptr<A> value_;
};

template <class A>
scoped_ptr<ContentHandlerFactory::HandledApplicationHolder>
make_handled_factory_holder(A* value) {
  return make_scoped_ptr(new HandledApplicationHolderImpl<A>(value));
}

}  // namespace mojo

#endif  // MOJO_APPLICATION_CONTENT_HANDLER_FACTORY_H_
