// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_CSSM_INIT_H_
#define CRYPTO_CSSM_INIT_H_

#include <Security/cssm.h>

#include "base/basictypes.h"
#include "crypto/crypto_export.h"

namespace crypto {

// Initialize CSSM if it isn't already initialized.  This must be called before
// any other CSSM functions.  This function is thread-safe, and CSSM will only
// ever be initialized once.  CSSM will be properly shut down on program exit.
CRYPTO_EXPORT void EnsureCSSMInit();

// Returns the shared CSP handle used by CSSM functions.
CRYPTO_EXPORT CSSM_CSP_HANDLE GetSharedCSPHandle();

// Returns the shared CL handle used by CSSM functions.
CRYPTO_EXPORT CSSM_CL_HANDLE GetSharedCLHandle();

// Returns the shared TP handle used by CSSM functions.
CRYPTO_EXPORT CSSM_TP_HANDLE GetSharedTPHandle();

// Set of pointers to memory function wrappers that are required for CSSM
extern const CSSM_API_MEMORY_FUNCS kCssmMemoryFunctions;

// Utility function to log an error message including the error name.
CRYPTO_EXPORT void LogCSSMError(const char *function_name, CSSM_RETURN err);

// Utility functions to allocate and release CSSM memory.
void* CSSMMalloc(CSSM_SIZE size);
CRYPTO_EXPORT void CSSMFree(void* ptr);

// Wrapper class for CSSM_DATA type. This should only be used when using the
// CL/TP/CSP handles from above, since that's the only time we're guaranteed (or
// supposed to be guaranteed) that our memory management functions will be used.
// Apple's Sec* APIs manage their own memory so it shouldn't be used for those.
// The constructor initializes data_ to zero and the destructor releases the
// data properly.
class ScopedCSSMData {
 public:
  ScopedCSSMData();
  ~ScopedCSSMData();
  operator CSSM_DATA*() { return &data_; }
  CSSM_DATA* operator ->() { return &data_; }

 private:
  CSSM_DATA data_;

  DISALLOW_COPY_AND_ASSIGN(ScopedCSSMData);
};

}  // namespace crypto

#endif  // CRYPTO_CSSM_INIT_H_
