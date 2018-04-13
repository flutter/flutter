// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/file.h"

#include <Shlwapi.h>

#include <sstream>

#include "flutter/fml/platform/win/wstring_conversion.h"

namespace fml {

fml::UniqueFD OpenFile(const std::wstring& path,
                       OpenPermission permission,
                       bool is_directory) {
  if (path.size() == 0) {
    return fml::UniqueFD{};
  }

  DWORD desired_access = 0;

  switch (permission) {
    case OpenPermission::kRead:
      desired_access = GENERIC_READ;
      break;
    case OpenPermission::kWrite:
      desired_access = GENERIC_WRITE;
      break;
    case OpenPermission::kReadWrite:
      desired_access = GENERIC_WRITE | GENERIC_READ;
      break;
    case OpenPermission::kExecute:
      desired_access = GENERIC_READ | GENERIC_EXECUTE;
      break;
  }

  return fml::UniqueFD{::CreateFile(
      path.c_str(),           // lpFileName
      desired_access,         // dwDesiredAccess
      FILE_SHARE_READ,        // dwShareMode
      0,                      // lpSecurityAttributes
      OPEN_EXISTING,          // dwCreationDisposition
      FILE_ATTRIBUTE_NORMAL,  // dwFlagsAndAttributes
      0                       // hTemplateFile
      )};
}

fml::UniqueFD OpenFile(const char* path,
                       OpenPermission permission,
                       bool is_directory) {
  return OpenFile(ConvertToWString(path), permission, is_directory);
}

static std::wstring GetFullHandlePath(const fml::UniqueFD& handle) {
  wchar_t buffer[MAX_PATH];

  DWORD returned = ::GetFinalPathNameByHandle(handle.get(), buffer, MAX_PATH,
                                              FILE_NAME_NORMALIZED);
  if (returned == 0 || returned > MAX_PATH) {
    return {};
  }

  return {buffer};
}

fml::UniqueFD OpenFile(const fml::UniqueFD& base_directory,
                       const char* path,
                       OpenPermission permission,
                       bool is_directory) {
  // If the base directory is invalid or the path is absolute, use the generic
  // open file variant.
  if (!base_directory.is_valid()) {
    return OpenFile(path, permission, is_directory);
  }

  const auto wpath = ConvertToWString(path);

  if (!::PathIsRelative(wpath.c_str())) {
    return OpenFile(path, permission, is_directory);
  }

  std::wstringstream stream;
  stream << GetFullHandlePath(base_directory) << "\\" << path;
  return OpenFile(stream.str(), permission, is_directory);
}

fml::UniqueFD Duplicate(fml::UniqueFD::element_type descriptor) {
  if (descriptor == INVALID_HANDLE_VALUE) {
    return fml::UniqueFD{};
  }

  HANDLE duplicated = INVALID_HANDLE_VALUE;

  if (!::DuplicateHandle(
          GetCurrentProcess(),  // source process
          descriptor,           // source handle
          GetCurrentProcess(),  // target process
          &duplicated,          // target handle
          0,      // desired access (ignored because DUPLICATE_SAME_ACCESS)
          FALSE,  // inheritable
          DUPLICATE_SAME_ACCESS)  // options
  ) {
    return fml::UniqueFD{};
  }

  return fml::UniqueFD{duplicated};
}

bool IsDirectory(const fml::UniqueFD& directory) {
  BY_HANDLE_FILE_INFORMATION info;
  if (!::GetFileInformationByHandle(directory.get(), &info)) {
    return false;
  }
  return info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY;
}

}  // namespace fml
