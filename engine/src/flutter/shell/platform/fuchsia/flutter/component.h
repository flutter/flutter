// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPONENT_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPONENT_H_

#include <array>
#include <memory>
#include <set>

#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/app/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async/default.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/fit/function.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/zx/eventpair.h>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"

#include "engine.h"
#include "flutter_runner_product_configuration.h"
#include "unique_fdio_ns.h"

namespace flutter_runner {

class Component;

struct ActiveComponent {
  std::unique_ptr<fml::Thread> platform_thread;
  std::unique_ptr<Component> component;

  ActiveComponent& operator=(ActiveComponent&& other) noexcept {
    if (this != &other) {
      this->platform_thread.reset(other.platform_thread.release());
      this->component.reset(other.component.release());
    }
    return *this;
  }

  ~ActiveComponent() = default;
};

// Represents an instance of a Flutter component that contains one of more
// Flutter engine instances.
class Component final : public Engine::Delegate,
                        public fuchsia::sys::ComponentController,
                        public fuchsia::ui::app::ViewProvider {
 public:
  using TerminationCallback = fit::function<void(const Component*)>;

  // Creates a dedicated thread to run the component and creates the
  // component on it. The component can be accessed only on this thread.
  // This is a synchronous operation.
  static ActiveComponent Create(
      TerminationCallback termination_callback,
      fuchsia::sys::Package package,
      fuchsia::sys::StartupInfo startup_info,
      std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
      fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller);

  // Must be called on the same thread returned from the create call. The thread
  // may be collected after.
  ~Component();

  static void ParseProgramMetadata(
      const fidl::VectorPtr<fuchsia::sys::ProgramMetadata>& program_metadata,
      std::string* data_path,
      std::string* assets_path);

  const std::string& GetDebugLabel() const;

#if !defined(DART_PRODUCT)
  void WriteProfileToTrace() const;
#endif  // !defined(DART_PRODUCT)

 private:
  flutter::Settings settings_;
  FlutterRunnerProductConfiguration product_config_;
  TerminationCallback termination_callback_;
  const std::string debug_label_;
  UniqueFDIONS fdio_ns_ = UniqueFDIONSCreate();
  fml::UniqueFD component_data_directory_;
  fml::UniqueFD component_assets_directory_;

  fidl::Binding<fuchsia::sys::ComponentController> component_controller_;
  fuchsia::io::DirectoryPtr directory_ptr_;
  fuchsia::io::NodePtr cloned_directory_ptr_;
  fidl::InterfaceRequest<fuchsia::io::Directory> directory_request_;
  std::unique_ptr<vfs::PseudoDir> outgoing_dir_;
  std::shared_ptr<sys::ServiceDirectory> svc_;
  std::shared_ptr<sys::ServiceDirectory> runner_incoming_services_;
  fidl::BindingSet<fuchsia::ui::app::ViewProvider> shells_bindings_;

  fml::RefPtr<flutter::DartSnapshot> isolate_snapshot_;
  std::set<std::unique_ptr<Engine>> shell_holders_;
  std::pair<bool, uint32_t> last_return_code_;
  fml::WeakPtrFactory<Component> weak_factory_;

  Component(
      TerminationCallback termination_callback,
      fuchsia::sys::Package package,
      fuchsia::sys::StartupInfo startup_info,
      std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
      fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller);

  // |fuchsia::sys::ComponentController|
  void Kill() override;

  // |fuchsia::sys::ComponentController|
  void Detach() override;

  // |fuchsia::ui::app::ViewProvider|
  void CreateView(
      zx::eventpair token,
      fidl::InterfaceRequest<fuchsia::sys::ServiceProvider> incoming_services,
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> outgoing_services)
      override;

  // |fuchsia::ui::app::ViewProvider|
  void CreateViewWithViewRef(zx::eventpair view_token,
                             fuchsia::ui::views::ViewRefControl control_ref,
                             fuchsia::ui::views::ViewRef view_ref) override;

  // |fuchsia::ui::app::ViewProvider|
  void CreateView2(fuchsia::ui::app::CreateView2Args view_args) override;

  // |flutter::Engine::Delegate|
  void OnEngineTerminate(const Engine* holder) override;

  FML_DISALLOW_COPY_AND_ASSIGN(Component);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPONENT_H_
