// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_UTILS_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_UTILS_H_

#include <optional>
#include <string>
#include <vector>

namespace flutter {

// A UWP application.
class Application {
 public:
  Application(const std::wstring_view package_name,
              const std::wstring_view package_family,
              const std::wstring_view package_full_name)
      : package_name_(package_name),
        package_family_(package_family),
        package_full_name_(package_full_name) {}

  Application(const Application& other) = default;
  Application& operator=(const Application& other) = default;

  // Returns the package name.
  //
  // The package name is a globally unique name that represents the 'friendly'
  // name of a package.
  std::wstring GetPackageName() const { return package_name_; }

  // Returns the package family.
  //
  // The package family is a serialized form of the package identifiers that
  // includes the package name and publisher.
  std::wstring GetPackageFamily() const { return package_family_; }

  // Returns the package full name.
  //
  // The package full name is a serialized form of the package identifiers that
  // includes a particular version of the package on the computer. It encodes
  // package name, publisher, architecture and version information.
  std::wstring GetPackageFullName() const { return package_full_name_; }

 private:
  std::wstring package_name_;
  std::wstring package_family_;
  std::wstring package_full_name_;
};

// The machine-local store of installed applications.
class ApplicationStore {
 public:
  ApplicationStore() = default;

  // Prevent copying.
  ApplicationStore(const ApplicationStore& other) = delete;
  ApplicationStore& operator=(const ApplicationStore& other) = delete;

  // Returns all installed applications.
  std::vector<Application> GetApps() const;

  // Returns all installed applications with the specified family name.
  std::vector<Application> GetApps(
      const std::wstring_view package_family) const;

  // Installs the specified application.
  //
  // Installs the application located at package_uri with the specified
  // dependencies.
  bool Install(const std::wstring_view package_uri,
               const std::vector<std::wstring>& dependency_uris);

  // Uninstalls all application packages in the specified package family.
  //
  // Returns true on success.
  bool Uninstall(const std::wstring_view package_family);

  // Launches the application with the specified list of launch arguments.
  //
  // Returns the process ID on success, or -1 on failure.
  int Launch(const std::wstring_view package_family,
             const std::wstring_view args);

 private:
  // Uninstalls the specified application package.
  //
  // Returns true on success.
  bool UninstallPackage(const std::wstring_view package_full_name);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_UTILS_H_
