// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/metro.h"

#include "base/strings/string_util.h"

namespace base {
namespace win {

HMODULE GetMetroModule() {
  const HMODULE kUninitialized = reinterpret_cast<HMODULE>(1);
  static HMODULE metro_module = kUninitialized;

  if (metro_module == kUninitialized) {
    // Initialize the cache, note that the initialization is idempotent
    // under the assumption that metro_driver is never unloaded, so the
    // race to this assignment is safe.
    metro_module = GetModuleHandleA("metro_driver.dll");
    if (metro_module != NULL) {
      // This must be a metro process if the metro_driver is loaded.
      DCHECK(IsMetroProcess());
    }
  }

  DCHECK(metro_module != kUninitialized);
  return metro_module;
}

bool IsMetroProcess() {
  enum ImmersiveState {
    kImmersiveUnknown,
    kImmersiveTrue,
    kImmersiveFalse
  };
  // The immersive state of a process can never change.
  // Look it up once and cache it here.
  static ImmersiveState state = kImmersiveUnknown;

  if (state == kImmersiveUnknown) {
    if (IsProcessImmersive(::GetCurrentProcess())) {
      state = kImmersiveTrue;
    } else {
      state = kImmersiveFalse;
    }
  }
  DCHECK_NE(kImmersiveUnknown, state);
  return state == kImmersiveTrue;
}

bool IsProcessImmersive(HANDLE process) {
  typedef BOOL (WINAPI* IsImmersiveProcessFunc)(HANDLE process);
  HMODULE user32 = ::GetModuleHandleA("user32.dll");
  DCHECK(user32 != NULL);

  IsImmersiveProcessFunc is_immersive_process =
      reinterpret_cast<IsImmersiveProcessFunc>(
          ::GetProcAddress(user32, "IsImmersiveProcess"));

  if (is_immersive_process)
    return is_immersive_process(process) ? true: false;
  return false;
}

wchar_t* LocalAllocAndCopyString(const string16& src) {
  size_t dest_size = (src.length() + 1) * sizeof(wchar_t);
  wchar_t* dest = reinterpret_cast<wchar_t*>(LocalAlloc(LPTR, dest_size));
  base::wcslcpy(dest, src.c_str(), dest_size);
  return dest;
}

// Metro driver exports for getting the launch type, initial url, initial
// search term, etc.
extern "C" {
typedef const wchar_t* (*GetInitialUrl)();
typedef const wchar_t* (*GetInitialSearchString)();
typedef base::win::MetroLaunchType (*GetLaunchType)(
    base::win::MetroPreviousExecutionState* previous_state);
}

MetroLaunchType GetMetroLaunchParams(string16* params) {
  HMODULE metro = base::win::GetMetroModule();
  if (!metro)
    return base::win::METRO_LAUNCH_ERROR;

  GetLaunchType get_launch_type = reinterpret_cast<GetLaunchType>(
      ::GetProcAddress(metro, "GetLaunchType"));
  DCHECK(get_launch_type);

  base::win::MetroLaunchType launch_type = get_launch_type(NULL);

  if ((launch_type == base::win::METRO_PROTOCOL) ||
      (launch_type == base::win::METRO_LAUNCH)) {
    GetInitialUrl initial_metro_url = reinterpret_cast<GetInitialUrl>(
        ::GetProcAddress(metro, "GetInitialUrl"));
    DCHECK(initial_metro_url);
    *params = initial_metro_url();
  } else if (launch_type == base::win::METRO_SEARCH) {
    GetInitialSearchString initial_search_string =
        reinterpret_cast<GetInitialSearchString>(
            ::GetProcAddress(metro, "GetInitialSearchString"));
    DCHECK(initial_search_string);
    *params = initial_search_string();
  }
  return launch_type;
}

}  // namespace win
}  // namespace base
