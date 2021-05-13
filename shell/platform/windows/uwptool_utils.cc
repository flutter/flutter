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

#include <iostream>
#include <optional>
#include <string>
#include <unordered_set>
#include <vector>

namespace flutter {

Application::Application(const std::wstring_view package_name,
                         const std::wstring_view package_family,
                         const std::wstring_view package_full_name)
    : package_name_(package_name),
      package_family_(package_family),
      package_full_name_(package_full_name) {}

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
  std::wstring app_user_model_id = package_family_ + L"!App";
  hresult = activation_manager->ActivateApplication(
      app_user_model_id.data(), args.data(), options, &process_id);
  if (FAILED(hresult)) {
    return -1;
  }
  return process_id;
}

bool Application::Uninstall() {
  using winrt::Windows::Foundation::AsyncStatus;
  using winrt::Windows::Management::Deployment::PackageManager;
  using winrt::Windows::Management::Deployment::RemovalOptions;

  PackageManager package_manager;
  auto operation = package_manager.RemovePackageAsync(
      package_full_name_, RemovalOptions::RemoveForAllUsers);
  operation.get();

  if (operation.Status() == AsyncStatus::Completed) {
    return true;
  } else if (operation.Status() == AsyncStatus::Canceled) {
    return false;
  } else if (operation.Status() == AsyncStatus::Error) {
    auto result = operation.GetResults();
    std::wcerr << L"error: uninstall failed for package " << package_full_name_
               << L" with error: " << result.ErrorText().c_str() << std::endl;
    return false;
  }
  return false;
}

std::vector<Application> ApplicationStore::GetApps() const {
  using winrt::Windows::ApplicationModel::Package;
  using winrt::Windows::Management::Deployment::PackageManager;

  // Find packages for the current user (default for empty string).
  std::vector<Application> apps;
  try {
    PackageManager package_manager;
    for (const Package& package : package_manager.FindPackagesForUser(L"")) {
      apps.emplace_back(package.Id().Name().c_str(),
                        package.Id().FamilyName().c_str(),
                        package.Id().FullName().c_str());
    }
  } catch (winrt::hresult_error error) {
    return {};
  }
  return apps;
}

std::vector<Application> ApplicationStore::GetApps(
    const std::wstring_view package_family) const {
  using winrt::Windows::ApplicationModel::Package;
  using winrt::Windows::Management::Deployment::PackageManager;

  // Find packages for the current user (default for empty string).
  std::vector<Application> apps;
  try {
    PackageManager package_manager;
    for (const Package& package :
         package_manager.FindPackagesForUser(L"", package_family)) {
      apps.emplace_back(package.Id().Name().c_str(),
                        package.Id().FamilyName().c_str(),
                        package.Id().FullName().c_str());
    }
  } catch (winrt::hresult_error error) {
    return {};
  }
  return apps;
}

}  // namespace flutter
