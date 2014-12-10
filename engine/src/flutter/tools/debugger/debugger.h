// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/public/interfaces/input_events/input_events.mojom.h"
#include "mojo/services/public/interfaces/navigation/navigation.mojom.h"
#include "mojo/services/view_manager/public/cpp/view_manager.h"
#include "mojo/services/view_manager/public/cpp/view_manager_delegate.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "services/window_manager/window_manager_app.h"
#include "services/window_manager/window_manager_delegate.h"
#include "sky/tools/debugger/debugger.mojom.h"
#include "sky/tools/debugger/navigator_host_impl.h"
#include "sky/viewer/services/inspector.mojom.h"

namespace sky {
namespace debugger {

class SkyDebugger : public mojo::ApplicationDelegate,
                    public mojo::ViewManagerDelegate,
                    public mojo::ViewObserver,
                    public mojo::InterfaceFactory<Debugger>,
                    public mojo::InterfaceImpl<Debugger> {
 public:
  SkyDebugger();
  virtual ~SkyDebugger();

  base::WeakPtr<SkyDebugger> GetWeakPtr();

  // Overridden from Debugger
  void NavigateToURL(const mojo::String& url) override;
  void InjectInspector() override;
  void Shutdown() override;

 private:
  // Overridden from mojo::ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override;
  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override;
  bool ConfigureOutgoingConnection(
      mojo::ApplicationConnection* connection) override;

  // Overridden from mojo::ViewManagerDelegate:
  void OnEmbed(mojo::ViewManager* view_manager,
               mojo::View* root,
               mojo::ServiceProviderImpl* exported_services,
               scoped_ptr<mojo::ServiceProvider> imported_services) override;
  void OnViewManagerDisconnected(mojo::ViewManager* view_manager) override;

  // Overriden from mojo::ViewObserver:
  void OnViewDestroyed(mojo::View* view) override;
  void OnViewBoundsChanged(mojo::View* view,
                           const mojo::Rect& old_bounds,
                           const mojo::Rect& new_bounds) override;

  // Overridden from InterfaceFactory<Debugger>:
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<Debugger> request) override;

  scoped_ptr<window_manager::WindowManagerApp> window_manager_app_;

  mojo::ViewManager* view_manager_;
  mojo::View* root_;
  mojo::View* content_;
  std::string pending_url_;

  scoped_ptr<mojo::ServiceProvider> viewer_services_;

  NavigatorHostFactory navigator_host_factory_;

  base::WeakPtrFactory<SkyDebugger> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SkyDebugger);
};

}  // namespace debugger
}  // namespace sky
