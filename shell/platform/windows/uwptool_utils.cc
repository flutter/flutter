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

bool ApplicationStore::Install(
    const std::wstring_view package_uri,
    const std::vector<std::wstring>& dependency_uris) {
  using winrt::Windows::Foundation::AsyncStatus;
  using winrt::Windows::Foundation::Uri;
  using winrt::Windows::Foundation::Collections::IVector;
  using winrt::Windows::Management::Deployment::DeploymentOptions;
  using winrt::Windows::Management::Deployment::PackageManager;

  Uri package(package_uri);
  IVector<Uri> dependencies = winrt::single_threaded_vector<Uri>();
  for (const auto& dependency_uri : dependency_uris) {
    dependencies.Append(Uri(dependency_uri));
  }
  PackageManager package_manager;
  auto operation = package_manager.AddPackageAsync(package, dependencies,
                                                   DeploymentOptions::None);
  operation.get();

  if (operation.Status() == AsyncStatus::Completed) {
    return true;
  } else if (operation.Status() == AsyncStatus::Canceled) {
    return false;
  } else if (operation.Status() == AsyncStatus::Error) {
    auto result = operation.GetResults();
    std::wcerr << L"error: install failed for package " << package_uri
               << L" with error: " << result.ErrorText().c_str() << std::endl;
    return false;
  }

  return false;
}

bool ApplicationStore::Uninstall(const std::wstring_view package_family) {
  bool success = true;
  for (const Application& app : GetApps(package_family)) {
    if (Uninstall(app.GetPackageFullName())) {
      std::wcerr << L"Uninstalled application " << app.GetPackageFullName()
                 << std::endl;
    } else {
      std::wcerr << L"error: Failed to uninstall application "
                 << app.GetPackageFullName() << std::endl;
      success = false;
    }
  }
  return success;
}

bool ApplicationStore::UninstallPackage(
    const std::wstring_view package_full_name) {
  using winrt::Windows::Foundation::AsyncStatus;
  using winrt::Windows::Management::Deployment::PackageManager;
  using winrt::Windows::Management::Deployment::RemovalOptions;

  PackageManager package_manager;
  auto operation = package_manager.RemovePackageAsync(
      package_full_name, RemovalOptions::RemoveForAllUsers);
  operation.get();

  if (operation.Status() == AsyncStatus::Completed) {
    return true;
  } else if (operation.Status() == AsyncStatus::Canceled) {
    return false;
  } else if (operation.Status() == AsyncStatus::Error) {
    auto result = operation.GetResults();
    std::wcerr << L"error: uninstall failed for package " << package_full_name
               << L" with error: " << result.ErrorText().c_str() << std::endl;
    return false;
  }
  return false;
}

int ApplicationStore::Launch(const std::wstring_view package_family,
                             const std::wstring_view args) {
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
  std::wstring app_user_model_id = std::wstring(package_family) + L"!App";
  hresult = activation_manager->ActivateApplication(
      app_user_model_id.data(), args.data(), options, &process_id);
  if (FAILED(hresult)) {
    return -1;
  }
  return process_id;
}

}  // namespace flutter
