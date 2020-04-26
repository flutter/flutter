#include "flutter_window.h"

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(RunLoop* run_loop,
                             const flutter::DartProject& project)
    : run_loop_(run_loop), project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::OnCreate() {
  Win32Window::OnCreate();

  // The size here is arbitrary since SetChildContent will resize it.
  flutter_controller_ =
      std::make_unique<flutter::FlutterViewController>(100, 100, project_);
  RegisterPlugins(flutter_controller_.get());
  run_loop_->RegisterFlutterInstance(flutter_controller_.get());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    run_loop_->UnregisterFlutterInstance(flutter_controller_.get());
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}
