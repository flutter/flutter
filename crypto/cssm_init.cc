// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/cssm_init.h"

#include <Security/SecBase.h>

#include "base/logging.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/memory/singleton.h"
#include "base/strings/sys_string_conversions.h"

// When writing crypto code for Mac OS X, you may find the following
// documentation useful:
// - Common Security: CDSA and CSSM, Version 2 (with corrigenda)
//   http://www.opengroup.org/security/cdsa.htm
// - Apple Cryptographic Service Provider Functional Specification
// - CryptoSample: http://developer.apple.com/SampleCode/CryptoSample/

namespace {

void* CSSMMalloc(CSSM_SIZE size, void* alloc_ref) {
  return malloc(size);
}

void CSSMFree(void* mem_ptr, void* alloc_ref) {
  free(mem_ptr);
}

void* CSSMRealloc(void* ptr, CSSM_SIZE size, void* alloc_ref) {
  return realloc(ptr, size);
}

void* CSSMCalloc(uint32 num, CSSM_SIZE size, void* alloc_ref) {
  return calloc(num, size);
}

class CSSMInitSingleton {
 public:
  static CSSMInitSingleton* GetInstance() {
    return Singleton<CSSMInitSingleton,
                     LeakySingletonTraits<CSSMInitSingleton> >::get();
  }

  CSSM_CSP_HANDLE csp_handle() const { return csp_handle_; }
  CSSM_CL_HANDLE cl_handle() const { return cl_handle_; }
  CSSM_TP_HANDLE tp_handle() const { return tp_handle_; }

 private:
  CSSMInitSingleton()
      : inited_(false), csp_loaded_(false), cl_loaded_(false),
        tp_loaded_(false), csp_handle_(CSSM_INVALID_HANDLE),
        cl_handle_(CSSM_INVALID_HANDLE), tp_handle_(CSSM_INVALID_HANDLE) {
    static CSSM_VERSION version = {2, 0};
    // TODO(wtc): what should our caller GUID be?
    static const CSSM_GUID test_guid = {
      0xFADE, 0, 0, { 1, 2, 3, 4, 5, 6, 7, 0 }
    };
    CSSM_RETURN crtn;
    CSSM_PVC_MODE pvc_policy = CSSM_PVC_NONE;
    crtn = CSSM_Init(&version, CSSM_PRIVILEGE_SCOPE_NONE, &test_guid,
                     CSSM_KEY_HIERARCHY_NONE, &pvc_policy, NULL);
    if (crtn) {
      NOTREACHED();
      return;
    }
    inited_ = true;

    crtn = CSSM_ModuleLoad(&gGuidAppleCSP, CSSM_KEY_HIERARCHY_NONE, NULL, NULL);
    if (crtn) {
      NOTREACHED();
      return;
    }
    csp_loaded_ = true;
    crtn = CSSM_ModuleLoad(
        &gGuidAppleX509CL, CSSM_KEY_HIERARCHY_NONE, NULL, NULL);
    if (crtn) {
      NOTREACHED();
      return;
    }
    cl_loaded_ = true;
    crtn = CSSM_ModuleLoad(
        &gGuidAppleX509TP, CSSM_KEY_HIERARCHY_NONE, NULL, NULL);
    if (crtn) {
      NOTREACHED();
      return;
    }
    tp_loaded_ = true;

    const CSSM_API_MEMORY_FUNCS cssmMemoryFunctions = {
      CSSMMalloc,
      CSSMFree,
      CSSMRealloc,
      CSSMCalloc,
      NULL
    };

    crtn = CSSM_ModuleAttach(&gGuidAppleCSP, &version, &cssmMemoryFunctions, 0,
                             CSSM_SERVICE_CSP, 0, CSSM_KEY_HIERARCHY_NONE,
                             NULL, 0, NULL, &csp_handle_);
    DCHECK_EQ(CSSM_OK, crtn);
    crtn = CSSM_ModuleAttach(&gGuidAppleX509CL, &version, &cssmMemoryFunctions,
                             0, CSSM_SERVICE_CL, 0, CSSM_KEY_HIERARCHY_NONE,
                             NULL, 0, NULL, &cl_handle_);
    DCHECK_EQ(CSSM_OK, crtn);
    crtn = CSSM_ModuleAttach(&gGuidAppleX509TP, &version, &cssmMemoryFunctions,
                             0, CSSM_SERVICE_TP, 0, CSSM_KEY_HIERARCHY_NONE,
                             NULL, 0, NULL, &tp_handle_);
    DCHECK_EQ(CSSM_OK, crtn);
  }

  ~CSSMInitSingleton() {
    CSSM_RETURN crtn;
    if (csp_handle_) {
      CSSM_RETURN crtn = CSSM_ModuleDetach(csp_handle_);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (cl_handle_) {
      CSSM_RETURN crtn = CSSM_ModuleDetach(cl_handle_);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (tp_handle_) {
      CSSM_RETURN crtn = CSSM_ModuleDetach(tp_handle_);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (csp_loaded_) {
      crtn = CSSM_ModuleUnload(&gGuidAppleCSP, NULL, NULL);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (cl_loaded_) {
      crtn = CSSM_ModuleUnload(&gGuidAppleX509CL, NULL, NULL);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (tp_loaded_) {
      crtn = CSSM_ModuleUnload(&gGuidAppleX509TP, NULL, NULL);
      DCHECK_EQ(CSSM_OK, crtn);
    }
    if (inited_) {
      crtn = CSSM_Terminate();
      DCHECK_EQ(CSSM_OK, crtn);
    }
  }

  bool inited_;  // True if CSSM_Init has been called successfully.
  bool csp_loaded_;  // True if gGuidAppleCSP has been loaded
  bool cl_loaded_;  // True if gGuidAppleX509CL has been loaded.
  bool tp_loaded_;  // True if gGuidAppleX509TP has been loaded.
  CSSM_CSP_HANDLE csp_handle_;
  CSSM_CL_HANDLE cl_handle_;
  CSSM_TP_HANDLE tp_handle_;

  friend struct DefaultSingletonTraits<CSSMInitSingleton>;
};

}  // namespace

namespace crypto {

void EnsureCSSMInit() {
  CSSMInitSingleton::GetInstance();
}

CSSM_CSP_HANDLE GetSharedCSPHandle() {
  return CSSMInitSingleton::GetInstance()->csp_handle();
}

CSSM_CL_HANDLE GetSharedCLHandle() {
  return CSSMInitSingleton::GetInstance()->cl_handle();
}

CSSM_TP_HANDLE GetSharedTPHandle() {
  return CSSMInitSingleton::GetInstance()->tp_handle();
}

void* CSSMMalloc(CSSM_SIZE size) {
  return ::CSSMMalloc(size, NULL);
}

void CSSMFree(void* ptr) {
  ::CSSMFree(ptr, NULL);
}

void LogCSSMError(const char* fn_name, CSSM_RETURN err) {
  if (!err)
    return;
  base::ScopedCFTypeRef<CFStringRef> cfstr(
      SecCopyErrorMessageString(err, NULL));
  LOG(ERROR) << fn_name << " returned " << err
             << " (" << base::SysCFStringRefToUTF8(cfstr) << ")";
}

ScopedCSSMData::ScopedCSSMData() {
  memset(&data_, 0, sizeof(data_));
}

ScopedCSSMData::~ScopedCSSMData() {
  if (data_.Data) {
    CSSMFree(data_.Data);
    data_.Data = NULL;
  }
}

}  // namespace crypto
