// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_IAT_PATCH_FUNCTION_H_
#define BASE_WIN_IAT_PATCH_FUNCTION_H_

#include <windows.h>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace win {

// A class that encapsulates Import Address Table patching helpers and restores
// the original function in the destructor.
//
// It will intercept functions for a specific DLL imported from another DLL.
// This is the case when, for example, we want to intercept
// CertDuplicateCertificateContext function (exported from crypt32.dll) called
// by wininet.dll.
class BASE_EXPORT IATPatchFunction {
 public:
  IATPatchFunction();
  ~IATPatchFunction();

  // Intercept a function in an import table of a specific
  // module. Save the original function and the import
  // table address. These values will be used later
  // during Unpatch
  //
  // Arguments:
  // module                 Module to be intercepted
  // imported_from_module   Module that exports the 'function_name'
  // function_name          Name of the API to be intercepted
  //
  // Returns: Windows error code (winerror.h). NO_ERROR if successful
  //
  // Note: Patching a function will make the IAT patch take some "ownership" on
  // |module|.  It will LoadLibrary(module) to keep the DLL alive until a call
  // to Unpatch(), which will call FreeLibrary() and allow the module to be
  // unloaded.  The idea is to help prevent the DLL from going away while a
  // patch is still active.
  DWORD Patch(const wchar_t* module,
              const char* imported_from_module,
              const char* function_name,
              void* new_function);

  // Same as Patch(), but uses a handle to a |module| instead of the DLL name.
  DWORD PatchFromModule(HMODULE module,
                        const char* imported_from_module,
                        const char* function_name,
                        void* new_function);

  // Unpatch the IAT entry using internally saved original
  // function.
  //
  // Returns: Windows error code (winerror.h). NO_ERROR if successful
  DWORD Unpatch();

  bool is_patched() const {
    return (NULL != intercept_function_);
  }

  void* original_function() const;


 private:
  HMODULE module_handle_;
  void* intercept_function_;
  void* original_function_;
  IMAGE_THUNK_DATA* iat_thunk_;

  DISALLOW_COPY_AND_ASSIGN(IATPatchFunction);
};

BASE_EXPORT DWORD ModifyCode(void* old_code, void* new_code, int length);

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_IAT_PATCH_FUNCTION_H_
