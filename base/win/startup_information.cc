// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/startup_information.h"

#include "base/logging.h"
#include "base/win/windows_version.h"

namespace {

typedef BOOL (WINAPI *InitializeProcThreadAttributeListFunction)(
    LPPROC_THREAD_ATTRIBUTE_LIST attribute_list,
    DWORD attribute_count,
    DWORD flags,
    PSIZE_T size);
static InitializeProcThreadAttributeListFunction
    initialize_proc_thread_attribute_list;

typedef BOOL (WINAPI *UpdateProcThreadAttributeFunction)(
    LPPROC_THREAD_ATTRIBUTE_LIST attribute_list,
    DWORD flags,
    DWORD_PTR attribute,
    PVOID value,
    SIZE_T size,
    PVOID previous_value,
    PSIZE_T return_size);
static UpdateProcThreadAttributeFunction update_proc_thread_attribute_list;

typedef VOID (WINAPI *DeleteProcThreadAttributeListFunction)(
    LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList);
static DeleteProcThreadAttributeListFunction delete_proc_thread_attribute_list;

}  // namespace

namespace base {
namespace win {

StartupInformation::StartupInformation() {
  memset(&startup_info_, 0, sizeof(startup_info_));

  // Pre Windows Vista doesn't support STARTUPINFOEX.
  if (base::win::GetVersion() < base::win::VERSION_VISTA) {
    startup_info_.StartupInfo.cb = sizeof(STARTUPINFO);
    return;
  }

  startup_info_.StartupInfo.cb = sizeof(startup_info_);

  // Load the attribute API functions.
  if (!initialize_proc_thread_attribute_list ||
      !update_proc_thread_attribute_list ||
      !delete_proc_thread_attribute_list) {
    HMODULE module = ::GetModuleHandleW(L"kernel32.dll");
    initialize_proc_thread_attribute_list =
        reinterpret_cast<InitializeProcThreadAttributeListFunction>(
            ::GetProcAddress(module, "InitializeProcThreadAttributeList"));
    update_proc_thread_attribute_list =
        reinterpret_cast<UpdateProcThreadAttributeFunction>(
            ::GetProcAddress(module, "UpdateProcThreadAttribute"));
    delete_proc_thread_attribute_list =
        reinterpret_cast<DeleteProcThreadAttributeListFunction>(
            ::GetProcAddress(module, "DeleteProcThreadAttributeList"));
  }
}

StartupInformation::~StartupInformation() {
  if (startup_info_.lpAttributeList) {
    delete_proc_thread_attribute_list(startup_info_.lpAttributeList);
    delete [] reinterpret_cast<BYTE*>(startup_info_.lpAttributeList);
  }
}

bool StartupInformation::InitializeProcThreadAttributeList(
    DWORD attribute_count) {
  if (startup_info_.StartupInfo.cb != sizeof(startup_info_) ||
      startup_info_.lpAttributeList)
    return false;

  SIZE_T size = 0;
  initialize_proc_thread_attribute_list(NULL, attribute_count, 0, &size);
  if (size == 0)
    return false;

  startup_info_.lpAttributeList =
      reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(new BYTE[size]);
  if (!initialize_proc_thread_attribute_list(startup_info_.lpAttributeList,
                                           attribute_count, 0, &size)) {
    delete [] reinterpret_cast<BYTE*>(startup_info_.lpAttributeList);
    startup_info_.lpAttributeList = NULL;
    return false;
  }

  return true;
}

bool StartupInformation::UpdateProcThreadAttribute(
    DWORD_PTR attribute,
    void* value,
    size_t size) {
  if (!startup_info_.lpAttributeList)
    return false;
  return !!update_proc_thread_attribute_list(startup_info_.lpAttributeList, 0,
                                       attribute, value, size, NULL, NULL);
}

}  // namespace win
}  // namespace base

