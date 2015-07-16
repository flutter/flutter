// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/iat_patch_function.h"

#include "base/logging.h"
#include "base/win/pe_image.h"

namespace base {
namespace win {

namespace {

struct InterceptFunctionInformation {
  bool finished_operation;
  const char* imported_from_module;
  const char* function_name;
  void* new_function;
  void** old_function;
  IMAGE_THUNK_DATA** iat_thunk;
  DWORD return_code;
};

void* GetIATFunction(IMAGE_THUNK_DATA* iat_thunk) {
  if (NULL == iat_thunk) {
    NOTREACHED();
    return NULL;
  }

  // Works around the 64 bit portability warning:
  // The Function member inside IMAGE_THUNK_DATA is really a pointer
  // to the IAT function. IMAGE_THUNK_DATA correctly maps to IMAGE_THUNK_DATA32
  // or IMAGE_THUNK_DATA64 for correct pointer size.
  union FunctionThunk {
    IMAGE_THUNK_DATA thunk;
    void* pointer;
  } iat_function;

  iat_function.thunk = *iat_thunk;
  return iat_function.pointer;
}

bool InterceptEnumCallback(const base::win::PEImage& image, const char* module,
                           DWORD ordinal, const char* name, DWORD hint,
                           IMAGE_THUNK_DATA* iat, void* cookie) {
  InterceptFunctionInformation* intercept_information =
    reinterpret_cast<InterceptFunctionInformation*>(cookie);

  if (NULL == intercept_information) {
    NOTREACHED();
    return false;
  }

  DCHECK(module);

  if ((0 == lstrcmpiA(module, intercept_information->imported_from_module)) &&
     (NULL != name) &&
     (0 == lstrcmpiA(name, intercept_information->function_name))) {
    // Save the old pointer.
    if (NULL != intercept_information->old_function) {
      *(intercept_information->old_function) = GetIATFunction(iat);
    }

    if (NULL != intercept_information->iat_thunk) {
      *(intercept_information->iat_thunk) = iat;
    }

    // portability check
    COMPILE_ASSERT(sizeof(iat->u1.Function) ==
      sizeof(intercept_information->new_function), unknown_IAT_thunk_format);

    // Patch the function.
    intercept_information->return_code =
      ModifyCode(&(iat->u1.Function),
                 &(intercept_information->new_function),
                 sizeof(intercept_information->new_function));

    // Terminate further enumeration.
    intercept_information->finished_operation = true;
    return false;
  }

  return true;
}

// Helper to intercept a function in an import table of a specific
// module.
//
// Arguments:
// module_handle          Module to be intercepted
// imported_from_module   Module that exports the symbol
// function_name          Name of the API to be intercepted
// new_function           Interceptor function
// old_function           Receives the original function pointer
// iat_thunk              Receives pointer to IAT_THUNK_DATA
//                        for the API from the import table.
//
// Returns: Returns NO_ERROR on success or Windows error code
//          as defined in winerror.h
DWORD InterceptImportedFunction(HMODULE module_handle,
                                const char* imported_from_module,
                                const char* function_name, void* new_function,
                                void** old_function,
                                IMAGE_THUNK_DATA** iat_thunk) {
  if ((NULL == module_handle) || (NULL == imported_from_module) ||
     (NULL == function_name) || (NULL == new_function)) {
    NOTREACHED();
    return ERROR_INVALID_PARAMETER;
  }

  base::win::PEImage target_image(module_handle);
  if (!target_image.VerifyMagic()) {
    NOTREACHED();
    return ERROR_INVALID_PARAMETER;
  }

  InterceptFunctionInformation intercept_information = {
    false,
    imported_from_module,
    function_name,
    new_function,
    old_function,
    iat_thunk,
    ERROR_GEN_FAILURE};

  // First go through the IAT. If we don't find the import we are looking
  // for in IAT, search delay import table.
  target_image.EnumAllImports(InterceptEnumCallback, &intercept_information);
  if (!intercept_information.finished_operation) {
    target_image.EnumAllDelayImports(InterceptEnumCallback,
                                     &intercept_information);
  }

  return intercept_information.return_code;
}

// Restore intercepted IAT entry with the original function.
//
// Arguments:
// intercept_function     Interceptor function
// original_function      Receives the original function pointer
//
// Returns: Returns NO_ERROR on success or Windows error code
//          as defined in winerror.h
DWORD RestoreImportedFunction(void* intercept_function,
                              void* original_function,
                              IMAGE_THUNK_DATA* iat_thunk) {
  if ((NULL == intercept_function) || (NULL == original_function) ||
      (NULL == iat_thunk)) {
    NOTREACHED();
    return ERROR_INVALID_PARAMETER;
  }

  if (GetIATFunction(iat_thunk) != intercept_function) {
    // Check if someone else has intercepted on top of us.
    // We cannot unpatch in this case, just raise a red flag.
    NOTREACHED();
    return ERROR_INVALID_FUNCTION;
  }

  return ModifyCode(&(iat_thunk->u1.Function),
                    &original_function,
                    sizeof(original_function));
}

}  // namespace

// Change the page protection (of code pages) to writable and copy
// the data at the specified location
//
// Arguments:
// old_code               Target location to copy
// new_code               Source
// length                 Number of bytes to copy
//
// Returns: Windows error code (winerror.h). NO_ERROR if successful
DWORD ModifyCode(void* old_code, void* new_code, int length) {
  if ((NULL == old_code) || (NULL == new_code) || (0 == length)) {
    NOTREACHED();
    return ERROR_INVALID_PARAMETER;
  }

  // Change the page protection so that we can write.
  MEMORY_BASIC_INFORMATION memory_info;
  DWORD error = NO_ERROR;
  DWORD old_page_protection = 0;

  if (!VirtualQuery(old_code, &memory_info, sizeof(memory_info))) {
    error = GetLastError();
    return error;
  }

  DWORD is_executable = (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                        PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY) &
                        memory_info.Protect;

  if (VirtualProtect(old_code,
                     length,
                     is_executable ? PAGE_EXECUTE_READWRITE :
                                     PAGE_READWRITE,
                     &old_page_protection)) {

    // Write the data.
    CopyMemory(old_code, new_code, length);

    // Restore the old page protection.
    error = ERROR_SUCCESS;
    VirtualProtect(old_code,
                  length,
                  old_page_protection,
                  &old_page_protection);
  } else {
    error = GetLastError();
  }

  return error;
}

IATPatchFunction::IATPatchFunction()
    : module_handle_(NULL),
      original_function_(NULL),
      iat_thunk_(NULL),
      intercept_function_(NULL) {
}

IATPatchFunction::~IATPatchFunction() {
  if (NULL != intercept_function_) {
    DWORD error = Unpatch();
    DCHECK_EQ(static_cast<DWORD>(NO_ERROR), error);
  }
}

DWORD IATPatchFunction::Patch(const wchar_t* module,
                              const char* imported_from_module,
                              const char* function_name,
                              void* new_function) {
  HMODULE module_handle = LoadLibraryW(module);
  if (module_handle == NULL) {
    NOTREACHED();
    return GetLastError();
  }

  DWORD error = PatchFromModule(module_handle, imported_from_module,
                                function_name, new_function);
  if (NO_ERROR == error) {
    module_handle_ = module_handle;
  } else {
    FreeLibrary(module_handle);
  }

  return error;
}

DWORD IATPatchFunction::PatchFromModule(HMODULE module,
                                        const char* imported_from_module,
                                        const char* function_name,
                                        void* new_function) {
  DCHECK_EQ(static_cast<void*>(NULL), original_function_);
  DCHECK_EQ(static_cast<IMAGE_THUNK_DATA*>(NULL), iat_thunk_);
  DCHECK_EQ(static_cast<void*>(NULL), intercept_function_);
  DCHECK(module);

  DWORD error = InterceptImportedFunction(module,
                                          imported_from_module,
                                          function_name,
                                          new_function,
                                          &original_function_,
                                          &iat_thunk_);

  if (NO_ERROR == error) {
    DCHECK_NE(original_function_, intercept_function_);
    intercept_function_ = new_function;
  }

  return error;
}

DWORD IATPatchFunction::Unpatch() {
  DWORD error = RestoreImportedFunction(intercept_function_,
                                        original_function_,
                                        iat_thunk_);
  DCHECK_EQ(static_cast<DWORD>(NO_ERROR), error);

  // Hands off the intercept if we fail to unpatch.
  // If IATPatchFunction::Unpatch fails during RestoreImportedFunction
  // it means that we cannot safely unpatch the import address table
  // patch. In this case its better to be hands off the intercept as
  // trying to unpatch again in the destructor of IATPatchFunction is
  // not going to be any safer
  if (module_handle_)
    FreeLibrary(module_handle_);
  module_handle_ = NULL;
  intercept_function_ = NULL;
  original_function_ = NULL;
  iat_thunk_ = NULL;

  return error;
}

void* IATPatchFunction::original_function() const {
  DCHECK(is_patched());
  return original_function_;
}

}  // namespace win
}  // namespace base
