// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_ENCLOSING_ENVIRONMENT_H_
#define LIB_SYS_CPP_TESTING_ENCLOSING_ENVIRONMENT_H_

#include <memory>
#include <string>
#include <unordered_map>

#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async/default.h>
#include <lib/fidl/cpp/interface_handle.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/fit/function.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/sys/cpp/testing/launcher_impl.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/vfs/cpp/service.h>

namespace sys {
namespace testing {

class EnclosingEnvironment;

// EnvironmentServices acts as a container of services to EnclosingEnvironment.
//
// By default, EnvironmentServices supplies only the parent environment's loader
// service. Additional services can be provided through |AddService| and
// friends. Typically, this is used to inject fake services for tests, or to
// pass through services from the parent environment.
//
// Every EnclosingEnvironment takes EnvironmentServices as an argument to
// instantiation. Services should not be added after the EnclosingEnvironment is
// created.
class EnvironmentServices {
 public:
  EnvironmentServices(const EnvironmentServices&) = delete;
  EnvironmentServices& operator=(const EnvironmentServices&) = delete;
  EnvironmentServices(EnvironmentServices&&) = delete;

  // Creates services with parent's loader service.
  static std::unique_ptr<EnvironmentServices> Create(
      const fuchsia::sys::EnvironmentPtr& parent_env,
      async_dispatcher_t* dispatcher = nullptr);
  // Creates services with custom loader service.
  static std::unique_ptr<EnvironmentServices> CreateWithCustomLoader(
      const fuchsia::sys::EnvironmentPtr& parent_env,
      const std::shared_ptr<vfs::Service>& loader_service,
      async_dispatcher_t* dispatcher = nullptr);

  // Adds the specified interface to the set of services.
  //
  // Adds a supported service with the given |service_name|, using the given
  // |interface_request_handler|, which should remain valid for the lifetime
  // of this object.
  //
  // A typical usage may be:
  //
  //   AddService(foobar_bindings_.GetHandler(this));
  //
  template <typename Interface>
  zx_status_t AddService(fidl::InterfaceRequestHandler<Interface> handler,
                         const std::string& service_name = Interface::Name_) {
    svc_names_.push_back(service_name);
    return svc_.AddEntry(
        service_name,
        std::make_unique<vfs::Service>(
            [handler = std::move(handler)](zx::channel channel,
                                           async_dispatcher_t* dispatcher) {
              handler(fidl::InterfaceRequest<Interface>(std::move(channel)));
            }));
  }

  // Adds the specified service to the set of services.
  zx_status_t AddSharedService(const std::shared_ptr<vfs::Service>& service,
                               const std::string& service_name);

  // Adds the specified service to the set of services.
  zx_status_t AddService(std::unique_ptr<vfs::Service> service,
                         const std::string& service_name);

  // Adds the specified service to the set of services.
  //
  // Adds a supported service with the given |service_name|, using the given
  // |launch_info|, it only starts the component when the service is
  // requested.
  // Note: Only url and arguments fields of provided launch_info are used, if
  // you need to use other fields, use the Handler signature.
  zx_status_t AddServiceWithLaunchInfo(fuchsia::sys::LaunchInfo launch_info,
                                       const std::string& service_name);

  // Adds the specified service to the set of services.
  //
  // Adds a supported service with the given |service_name|, using the given
  // handler to generate launch info, it only starts the component when the
  // service is requested.
  // The provided singleton_id argument is used to keep track of singleton
  // instances, generally you want to use the URL that'll be used for launch
  // info.
  zx_status_t AddServiceWithLaunchInfo(
      std::string singleton_id,
      fit::function<fuchsia::sys::LaunchInfo()> handler,
      const std::string& service_name);

  // Allows child components to access parent service with name
  // |service_name|.
  //
  // This will only work if parent environment actually provides said service
  // and the service is in the test component's service whitelist.
  zx_status_t AllowParentService(const std::string& service_name);

  // Serve service directory using |flags| and returns a new |InterfaceHandle|;
  // Will cause exception if serving fails.
  fidl::InterfaceHandle<fuchsia::io::Directory> ServeServiceDir(
      uint32_t flags = fuchsia::io::OPEN_RIGHT_READABLE);

  // Serves service directory using passed |request| and returns status.
  zx_status_t ServeServiceDir(
      fidl::InterfaceRequest<fuchsia::io::Directory> request,
      uint32_t flags = fuchsia::io::OPEN_RIGHT_READABLE);

  // Serves service directory using passed |request| and returns status.
  zx_status_t ServeServiceDir(
      zx::channel request, uint32_t flags = fuchsia::io::OPEN_RIGHT_READABLE);

 private:
  friend class EnclosingEnvironment;
  EnvironmentServices(const fuchsia::sys::EnvironmentPtr& parent_env,
                      const std::shared_ptr<vfs::Service>& loader_service,
                      async_dispatcher_t* dispatcher = nullptr);

  void set_enclosing_env(EnclosingEnvironment* e) { enclosing_env_ = e; }

  vfs::PseudoDir svc_;
  fidl::VectorPtr<std::string> svc_names_;
  std::shared_ptr<sys::ServiceDirectory> parent_svc_;
  // Pointer to containing environment. Not owned.
  EnclosingEnvironment* enclosing_env_ = nullptr;
  async_dispatcher_t* dispatcher_;

  // Keep track of all singleton services, indexed by url.
  std::unordered_map<std::string, std::shared_ptr<sys::ServiceDirectory>>
      singleton_services_;
};

// EnclosingEnvironment wraps a new isolated environment for test |parent_env|
// and provides a way to use that environment for integration testing.
//
// It provides a way to add custom fake services using handlers and singleton
// components. By default components under this environment have no access to
// any of system services. You need to add your own services by using
// |AddService| or |AddServiceWithLaunchInfo| methods.
//
// It also provides a way to access parent services if needed.
class EnclosingEnvironment {
 public:
  // Creates environment with the given services.
  //
  // |label| is human readable environment name, it can be seen in /hub, for eg
  // /hub/r/sys/<koid>/r/<label>/<koid>
  //
  // |services| are the services the environment will provide. See
  // |EnvironmentServices| for details.
  static std::unique_ptr<EnclosingEnvironment> Create(
      const std::string& label, const fuchsia::sys::EnvironmentPtr& parent_env,
      std::unique_ptr<EnvironmentServices> services,
      const fuchsia::sys::EnvironmentOptions& options = {});

  ~EnclosingEnvironment();

  fuchsia::sys::LauncherPtr launcher_ptr() {
    fuchsia::sys::LauncherPtr launcher;
    launcher_.AddBinding(launcher.NewRequest());
    return launcher;
  }

  // Returns true if underlying environment is running.
  bool is_running() const { return running_; }

  // Kills the underlying environment.
  void Kill(fit::function<void()> callback = nullptr);

  // Creates a real component from |launch_info| in underlying environment.
  //
  // That component will only have access to the services added and
  // any allowed parent service.
  void CreateComponent(
      fuchsia::sys::LaunchInfo launch_info,
      fidl::InterfaceRequest<fuchsia::sys::ComponentController> request);

  // Creates a real component from |launch_info| in underlying environment and
  // returns controller ptr.
  //
  // That component will only have access to the services added and
  // any allowed parent service.
  fuchsia::sys::ComponentControllerPtr CreateComponent(
      fuchsia::sys::LaunchInfo launch_info);

  // Creates a real component in underlying environment for a url and returns
  // controller ptr.
  //
  // That component will only have access to the services added and
  // any allowed parent service.
  fuchsia::sys::ComponentControllerPtr CreateComponentFromUrl(
      std::string component_url);

  // Creates a nested enclosing environment on top of underlying environment.
  std::unique_ptr<EnclosingEnvironment> CreateNestedEnclosingEnvironment(
      const std::string& label);

  // Creates a nested enclosing environment on top of underlying environment
  // with custom loader service.
  std::unique_ptr<EnclosingEnvironment>
  CreateNestedEnclosingEnvironmentWithLoader(
      const std::string& label, std::shared_ptr<vfs::Service> loader_service);

  // Connects to service provided by this environment.
  void ConnectToService(fidl::StringPtr service_name, zx::channel channel) {
    service_provider_->Connect(service_name, std::move(channel));
  }

  // Connects to service provided by this environment.
  template <typename Interface>
  void ConnectToService(fidl::InterfaceRequest<Interface> request,
                        const std::string& service_name = Interface::Name_) {
    ConnectToService(service_name, request.TakeChannel());
  }

  // Connects to service provided by this environment.
  template <typename Interface>
  fidl::InterfacePtr<Interface> ConnectToService(
      const std::string& service_name = Interface::Name_) {
    fidl::InterfacePtr<Interface> ptr;
    ConnectToService(service_name, ptr.NewRequest().TakeChannel());
    return ptr;
  }

  // Sets a listener for changes in the running status
  void SetRunningChangedCallback(fit::function<void(bool)> cb) {
    running_changed_callback_ = std::move(cb);
  }

 private:
  EnclosingEnvironment(const std::string& label,
                       const fuchsia::sys::EnvironmentPtr& parent_env,
                       std::unique_ptr<EnvironmentServices> services,
                       const fuchsia::sys::EnvironmentOptions& options);

  void SetRunning(bool running);

  bool running_ = false;
  const std::string label_;
  fuchsia::sys::EnvironmentControllerPtr env_controller_;
  std::shared_ptr<sys::ServiceDirectory> service_provider_;
  LauncherImpl launcher_;
  std::unique_ptr<EnvironmentServices> services_;
  fit::function<void(bool)> running_changed_callback_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_ENCLOSING_ENVIRONMENT_H_
