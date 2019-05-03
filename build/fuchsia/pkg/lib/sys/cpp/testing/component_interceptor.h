// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_COMPONENT_INTERCEPTOR_H_
#define LIB_SYS_CPP_TESTING_COMPONENT_INTERCEPTOR_H_

#include <mutex>
#include <string>

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/testing/enclosing_environment.h>

namespace sys {
namespace testing {

using fuchsia::sys::TerminationReason;

// A Wrapper class which implements a basic version of
// |fuchsia::sys::ComponentController| and gives owner control over lifetime of
// this component.
class InterceptedComponent : public fuchsia::sys::ComponentController {
 public:
  // Called when this component is killed.
  using OnKill = fit::function<void()>;

  InterceptedComponent(
      fidl::InterfaceRequest<fuchsia::sys::ComponentController> request,
      async_dispatcher_t* dispatcher = nullptr);

  // resets |on_kill_| to nullptr and calls |Kill()|.
  ~InterceptedComponent() override;

  void Exit(int64_t exit_code,
            TerminationReason reason = TerminationReason::EXITED);

  void set_on_kill(OnKill on_kill) { on_kill_ = std::move(on_kill); }

 private:
  // |ComponentController|.
  void Detach() override;

  // |ComponentController|.
  //
  // Calls |on_kill_| and call Terminated event on component before clearing the
  // bindings
  void Kill() override;

  fidl::Binding<fuchsia::sys::ComponentController> binding_;
  TerminationReason termination_reason_;
  int64_t exit_code_;
  OnKill on_kill_;
};

// ComponentInterceptor is a utility that helps users construct an
// EnvironmentService (to be used alongside EnclosingEnvironment) that is able
// to intercept and mock components launched under the EnclosingEnvironment.
//
// This class is thread-safe. Underlying FIDL communication is processed on the
// async dispatcher supplied to this class.
class ComponentInterceptor : fuchsia::sys::Loader, fuchsia::sys::Runner {
 public:
  using ComponentLaunchHandler = fit::function<void(
      fuchsia::sys::StartupInfo, std::unique_ptr<InterceptedComponent>)>;

  ComponentInterceptor(fuchsia::sys::LoaderPtr fallback_loader,
                       async_dispatcher_t* dispatcher = nullptr);

  virtual ~ComponentInterceptor() override;

  // Constructs a fallback loader from the given |env|.
  static ComponentInterceptor CreateWithEnvironmentLoader(
      const fuchsia::sys::EnvironmentPtr& env,
      async_dispatcher_t* dispatcher = nullptr);

  // Creates an |EnvironmentServices| which contains custom Loader and
  // Runner services which intercept component launch URLs configured using
  // |InterceptURL|. Calls to |InterceptURL| are effective regardless of if
  // they're called before or after calls to this method.
  //
  // Restrictions:
  //  * Users must not override the fuchsia::sys::Loader and
  //    fuchsia::sys::Runner services.
  //  * An instance of |ComponentInterceptor| must outlive instances of
  //    vended |EnvironmentServices|
  std::unique_ptr<EnvironmentServices> MakeEnvironmentServices(
      const fuchsia::sys::EnvironmentPtr& env);

  // Intercepts |component_url| from being launched under this environment, and
  // calls the supplied |handler| to handle the runtime of this component.
  //
  // |extra_cmx_contents| contains additional component manifest contents
  // supplied for this component.
  //   * If |extra_cmx_contents| is empty a default one is used:
  //      * {"program": {"binary": ""}}
  //   * The "runner" is always overwritten.
  //
  // Returns |false| if |extra_cmx_contents| contains invalid JSON.
  [[nodiscard]] bool InterceptURL(std::string component_url,
                                  std::string extra_cmx_contents,
                                  ComponentLaunchHandler handler);

 private:
  // Returns a faked fuchsia.sys.Package with a custom runner which forwards
  // the StartComponent request to environment's fuchsia::sys::Runner
  // service hosted by this object instance.
  //
  // |fuchsia::sys::Loader|
  void LoadUrl(std::string url, LoadUrlCallback response) override;

  // We arrive here if our fuchsia::sys::Loader sends a component launch to
  // the test harness runner component, which forwards it to here.
  //
  // |fuchsia::sys::Runner|
  void StartComponent(fuchsia::sys::Package package,
                      fuchsia::sys::StartupInfo startup_info,
                      fidl::InterfaceRequest<fuchsia::sys::ComponentController>
                          controller) override;

  // Ensures that calls to intercepting URLs remains thread-safe.
  std::mutex intercept_urls_mu_;

  struct ComponentLoadInfo {
    ComponentLaunchHandler handler;
    // Fake component package directory where we host our fake manifest.
    std::unique_ptr<vfs::PseudoDir> pkg_dir;
  };
  std::map<std::string, ComponentLoadInfo> intercepted_component_load_info_
      __TA_GUARDED(intercept_urls_mu_);

  fuchsia::sys::LoaderPtr fallback_loader_;

  std::shared_ptr<vfs::Service> loader_svc_;
  fidl::BindingSet<fuchsia::sys::Loader> loader_bindings_;
  fidl::BindingSet<fuchsia::sys::Runner> runner_bindings_;

  async_dispatcher_t* dispatcher_;

  std::unique_ptr<EnclosingEnvironment> env_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_COMPONENT_INTERCEPTOR_H_
