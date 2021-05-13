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
  explicit Application(const std::wstring_view package_family,
                       const std::wstring_view package_full_name);
  Application(const Application& other) = default;
  Application& operator=(const Application& other) = default;

  // Returns the package family.
  std::wstring GetPackageFamily() const { return package_family_; }

  // Returns the package full name.
  std::wstring GetPackageFullName() const { return package_full_name_; }

  // Launches the application with the specified list of launch arguments.
  //
  // Returns the process ID on success, or -1 on failure.
  int Launch(const std::wstring_view args);

 private:
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

  // Returns a list of all installed application user model IDs.
  std::vector<Application> GetInstalledApplications() const;

  // Returns a list of all installed application user model IDs.
  std::optional<Application> GetInstalledApplication(
      const std::wstring_view package_family) const;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_UTILS_H_
