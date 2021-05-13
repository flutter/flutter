// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/uwptool_utils.h"

#include <Windows.h>
#include <Winreg.h>
#include <shobjidl_core.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Management.Deployment.h>
#include <winrt/base.h>

#include <string>
#include <unordered_set>
#include <vector>

namespace flutter {

Application::Application(const std::wstring_view package_id)
    : package_id_(package_id) {}

int Application::Launch(const std::wstring_view args) {
  // Create the ApplicationActivationManager.
  winrt::com_ptr<IApplicationActivationManager> activation_manager;
  HRESULT hresult = ::CoCreateInstance(
      CLSID_ApplicationActivationManager, nullptr, CLSCTX_INPROC_SERVER,
      IID_IApplicationActivationManager, activation_manager.put_void());
  if (FAILED(hresult)) {
    return -1;
  }

  // Launch the application.
  DWORD process_id;
  ACTIVATEOPTIONS options = AO_NONE;
  std::wstring app_user_model_id = package_id_ + L"!App";
  hresult = activation_manager->ActivateApplication(
      app_user_model_id.data(), args.data(), options, &process_id);
  if (FAILED(hresult)) {
    return -1;
  }
  return process_id;
}

std::vector<Application> ApplicationStore::GetInstalledApplications() {
  using winrt::Windows::ApplicationModel::Package;
  using winrt::Windows::Management::Deployment::PackageManager;

  // Find packages for the current user (default for empty string).
  PackageManager package_manager;
  std::unordered_set<std::wstring> package_ids;
  for (const Package& package : package_manager.FindPackagesForUser(L"")) {
    package_ids.emplace(package.Id().FamilyName().c_str());
  }
  std::vector<Application> apps(package_ids.begin(), package_ids.end());
  return apps;
}

}  // namespace flutter
