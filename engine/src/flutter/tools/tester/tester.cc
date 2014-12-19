// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>
#include "base/bind.h"
#include "base/memory/weak_ptr.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/input_events/public/interfaces/input_events.mojom.h"
#include "mojo/services/view_manager/public/cpp/view_manager.h"
#include "mojo/services/view_manager/public/cpp/view_manager_delegate.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "services/window_manager/window_manager_app.h"
#include "services/window_manager/window_manager_delegate.h"
#include "sky/tools/tester/test_runner.h"

namespace sky {
namespace tester {
namespace {

struct UrlData {
  std::string url;
  std::string expected_pixel_hash;
  bool enable_pixel_dumping = false;
};

void WaitForURL(UrlData& data) {
  // A test name is formated like file:///path/to/test'--pixel-test'pixelhash
  std::cin >> data.url;

  std::string pixel_switch;
  std::string::size_type separator_position = data.url.find('\'');
  if (separator_position != std::string::npos) {
    pixel_switch = data.url.substr(separator_position + 1);
    data.url.erase(separator_position);
  }

  std::string pixel_hash;
  separator_position = pixel_switch.find('\'');
  if (separator_position != std::string::npos) {
    pixel_hash = pixel_switch.substr(separator_position + 1);
    pixel_switch.erase(separator_position);
  }

  data.enable_pixel_dumping = pixel_switch == "--pixel-test";
  data.expected_pixel_hash = pixel_hash;
}

}  // namespace

class SkyTester : public mojo::ApplicationDelegate,
                  public mojo::ViewManagerDelegate,
                  public window_manager::WindowManagerDelegate,
                  public mojo::ViewObserver,
                  public TestRunnerClient {
 public:
  SkyTester()
      : window_manager_app_(new window_manager::WindowManagerApp(this, this)),
        root_(NULL),
        content_(NULL),
        weak_ptr_factory_(this) {}
  virtual ~SkyTester() {}

 private:
  // Overridden from mojo::ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* impl) override {
    window_manager_app_->Initialize(impl);

    if (impl->args().size() >= 2)
      url_from_args_ = impl->args()[1];
  }
  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    window_manager_app_->ConfigureIncomingConnection(connection);
    if (test_runner_)
      connection->AddService(test_runner_->test_harness_factory());
    return true;
  }

  // Overridden from mojo::ViewManagerDelegate:
  virtual void OnEmbed(
      mojo::View* root,
      mojo::ServiceProviderImpl* exported_services,
      scoped_ptr<mojo::ServiceProvider> remote_service_provider) override {
    root_ = root;
    root_->AddObserver(this);

    content_ = root->view_manager()->CreateView();
    content_->SetBounds(root_->bounds());
    root_->AddChild(content_);
    content_->SetVisible(true);

    std::cout << "#READY\n";
    std::cout.flush();
    ScheduleRun();
  }

  // Overridden from window_manager::WindowManagerDelegate:
  virtual void Embed(
      const mojo::String& url,
      mojo::InterfaceRequest<mojo::ServiceProvider> service_provider) override {
  }

  virtual void OnViewManagerDisconnected(
      mojo::ViewManager* view_manager) override {
    root_ = NULL;
  }

  virtual void OnViewDestroyed(mojo::View* view) override {
    view->RemoveObserver(this);
  }

  virtual void OnViewBoundsChanged(mojo::View* view,
                                   const mojo::Rect& old_bounds,
                                   const mojo::Rect& new_bounds) override {
    content_->SetBounds(new_bounds);
  }

  void ScheduleRun() {
    base::MessageLoop::current()->PostTask(FROM_HERE,
        base::Bind(&SkyTester::Run, weak_ptr_factory_.GetWeakPtr()));
  }

  void Run() {
    DCHECK(!test_runner_);

    UrlData data;
    if (url_from_args_.length()) {
      data.url = url_from_args_;
    } else {
      WaitForURL(data);
    }

    test_runner_.reset(new TestRunner(this, content_, data.url,
        data.enable_pixel_dumping));
  }

  void OnTestComplete() override {
    test_runner_.reset();
    if (url_from_args_.length())
      exit(0);
    ScheduleRun();
  }

  void DispatchInputEvent(mojo::EventPtr event) override {
    window_manager_app_->DispatchInputEventToView(content_, event.Pass());
  }

  scoped_ptr<window_manager::WindowManagerApp> window_manager_app_;

  std::string url_from_args_;

  mojo::View* root_;
  mojo::View* content_;

  scoped_ptr<TestRunner> test_runner_;

  base::WeakPtrFactory<SkyTester> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(SkyTester);
};

}  // namespace tester
}  // namespace examples

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::tester::SkyTester);
  return runner.Run(shell_handle);
}
