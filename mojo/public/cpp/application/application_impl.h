// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_APPLICATION_APPLICATION_IMPL_H_
#define MOJO_PUBLIC_APPLICATION_APPLICATION_IMPL_H_

#include <string>
#include <vector>

#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/lib/service_registry.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"

namespace mojo {

class ApplicationConnection;

// Implements the Application interface, which the shell uses for basic
// communication with an application (e.g., to connect clients to services
// provided by an application). Also provides the application access to the
// Shell, which, e.g., may be used by an application to connect to other
// services.
//
// Typically, you create one or more classes implementing your APIs (e.g.,
// FooImpl implementing Foo). See bindings/binding.h for more information. Then
// you implement an mojo::ApplicationDelegate that either is or owns a
// mojo::InterfaceFactory<Foo> and whose ConfigureIncomingConnection() adds that
// factory to each connection. Finally, you instantiate your delegate and pass
// it to an ApplicationRunner, which will create the ApplicationImpl and then
// run a message (or run) loop.
class ApplicationImpl : public Application {
 public:
  // Does not take ownership of |delegate|, which must remain valid for the
  // lifetime of ApplicationImpl.
  ApplicationImpl(ApplicationDelegate* delegate,
                  InterfaceRequest<Application> request);
  ~ApplicationImpl() override;

  // The Mojo shell. This will return a valid pointer after Initialize() has
  // been invoked. It will remain valid until UnbindConnections() is invoked or
  // the ApplicationImpl is destroyed.
  Shell* shell() const { return shell_.get(); }

  const std::string& url() const { return url_; }

  // Returns any initial configuration arguments, passed by the Shell.
  const std::vector<std::string>& args() const { return args_; }
  bool HasArg(const std::string& arg) const;

  // Requests a new connection to an application. Returns a pointer to the
  // connection if the connection is permitted by this application's delegate,
  // or nullptr otherwise. Caller does not take ownership. The pointer remains
  // valid until an error occurs on the connection with the Shell, or until the
  // ApplicationImpl is destroyed, whichever occurs first.
  ApplicationConnection* ConnectToApplication(const String& application_url);

  // Connect to application identified by |application_url| and connect to the
  // service implementation of the interface identified by |Interface|.
  template <typename Interface>
  void ConnectToService(const std::string& application_url,
                        InterfacePtr<Interface>* ptr) {
    ConnectToApplication(application_url)->ConnectToService(ptr);
  }

  // Application implementation.
  void Initialize(ShellPtr shell,
                  Array<String> args,
                  const mojo::String& url) override;

  // Block until the Application is initialized, if it is not already.
  void WaitForInitialize();

  // Unbinds the Shell and Application connections. Can be used to re-bind the
  // handles to another implementation of ApplicationImpl, for instance when
  // running apptests.
  void UnbindConnections(InterfaceRequest<Application>* application_request,
                         ShellPtr* shell);

  // Quits the main run loop for this application.
  static void Terminate();

 protected:
  // Application implementation.
  void AcceptConnection(const String& requestor_url,
                        InterfaceRequest<ServiceProvider> services,
                        ServiceProviderPtr exposed_services,
                        const String& url) override;

 private:
  void ClearConnections();

  void OnShellError() {
    delegate_->Quit();
    ClearConnections();
    Terminate();
  }

  // Application implementation.
  void RequestQuit() override;

  typedef std::vector<internal::ServiceRegistry*> ServiceRegistryList;

  ServiceRegistryList incoming_service_registries_;
  ServiceRegistryList outgoing_service_registries_;
  ApplicationDelegate* delegate_;
  Binding<Application> binding_;
  ShellPtr shell_;
  std::string url_;
  std::vector<std::string> args_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ApplicationImpl);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_APPLICATION_APPLICATION_IMPL_H_
