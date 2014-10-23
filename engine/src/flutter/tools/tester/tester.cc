// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/public/cpp/view_manager/view_manager.h"
#include "mojo/services/public/cpp/view_manager/view_manager_delegate.h"
#include "mojo/services/public/cpp/view_manager/view_observer.h"
#include "mojo/services/public/interfaces/input_events/input_events.mojom.h"
#include "mojo/services/window_manager/window_manager_app.h"
#include "mojo/services/window_manager/window_manager_delegate.h"
#include "sky/tools/tester/test_harness.h"

namespace sky {
namespace tester {

class SkyTester : public mojo::ApplicationDelegate,
                  public mojo::ViewManagerDelegate,
                  public mojo::WindowManagerDelegate,
                  public mojo::ViewObserver {
 public:
  SkyTester()
      : window_manager_app_(new mojo::WindowManagerApp(this, this)),
        view_manager_(NULL),
        root_(NULL),
        content_(NULL) {}
  virtual ~SkyTester() {}

 private:
  // Overridden from mojo::ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* impl) override {
    window_manager_app_->Initialize(impl);
  }
  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    window_manager_app_->ConfigureIncomingConnection(connection);
    return true;
  }

  // Overridden from mojo::ViewManagerDelegate:
  virtual void OnEmbed(
      mojo::ViewManager* view_manager,
      mojo::View* root,
      mojo::ServiceProviderImpl* exported_services,
      scoped_ptr<mojo::ServiceProvider> remote_service_provider) override {
    view_manager_ = view_manager;
    root_ = root;
    root_->AddObserver(this);

    content_ = mojo::View::Create(view_manager_);
    content_->SetBounds(root_->bounds());
    root_->AddChild(content_);

    test_harness_.reset(new TestHarness(content_));
    test_harness_->ScheduleRun();
  }

  // Overridden from WindowManagerDelegate:
  virtual void Embed(
      const mojo::String& url,
      mojo::InterfaceRequest<mojo::ServiceProvider> service_provider) override {
  }

  virtual void OnViewManagerDisconnected(
      mojo::ViewManager* view_manager) override {
    view_manager_ = NULL;
    root_ = NULL;
  }

  virtual void OnViewDestroyed(mojo::View* view) override {
    view->RemoveObserver(this);
  }

  virtual void OnViewBoundsChanged(mojo::View* view,
                                   const gfx::Rect& old_bounds,
                                   const gfx::Rect& new_bounds) override {
    content_->SetBounds(new_bounds);
  }

  scoped_ptr<mojo::WindowManagerApp> window_manager_app_;

  mojo::ViewManager* view_manager_;
  mojo::View* root_;
  mojo::View* content_;
  scoped_ptr<TestHarness> test_harness_;

  DISALLOW_COPY_AND_ASSIGN(SkyTester);
};

}  // namespace tester
}  // namespace examples

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::tester::SkyTester);
  return runner.Run(shell_handle);
}
