// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_DELEGATE_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_DELEGATE_H_

#include <string>

#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace mojo {

class View;
class ViewManager;

// Interface implemented by an application using the view manager.
class ViewManagerDelegate {
 public:
  // Called when the application implementing this interface is embedded at
  // |root|. Every embed results in a new ViewManager and root View being
  // created. |root| and it's corresponding ViewManager are valid until
  // OnViewManagerDisconnected() is called with the same object.
  //
  // |services| exposes the services offered by the embedder to the delegate.
  //
  // |exposed_services| is an object that the delegate can add services to
  // expose to the embedder.
  //
  // Note that if a different application is subsequently embedded at |root|,
  // the pipes connecting |services| and |exposed_services| to the embedder and
  // any services obtained from them are not broken and will continue to be
  // valid.
  virtual void OnEmbed(View* root,
                       InterfaceRequest<ServiceProvider> services,
                       ServiceProviderPtr exposed_services) = 0;

  // Called when a connection to the view manager service is closed.
  // |view_manager| is not valid after this function returns.
  virtual void OnViewManagerDisconnected(ViewManager* view_manager) = 0;

  // Asks the delegate to perform the specified action.
  // TODO(sky): nuke! See comments in view_manager.mojom for details.
  virtual bool OnPerformAction(View* view, const std::string& action);

 protected:
  virtual ~ViewManagerDelegate() {}
};

}  // namespace mojo

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_DELEGATE_H_
