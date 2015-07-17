// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_NSS_UTIL_H_
#define CRYPTO_NSS_UTIL_H_

#include <string>
#include "base/basictypes.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "crypto/crypto_export.h"

namespace base {
class FilePath;
class Lock;
class Time;
}  // namespace base

// This file specifically doesn't depend on any NSS or NSPR headers because it
// is included by various (non-crypto) parts of chrome to call the
// initialization functions.
namespace crypto {

#if defined(USE_NSS_CERTS)
// EarlySetupForNSSInit performs lightweight setup which must occur before the
// process goes multithreaded. This does not initialise NSS. For test, see
// EnsureNSSInit.
CRYPTO_EXPORT void EarlySetupForNSSInit();
#endif

// Initialize NRPR if it isn't already initialized.  This function is
// thread-safe, and NSPR will only ever be initialized once.
CRYPTO_EXPORT void EnsureNSPRInit();

// Initialize NSS safely for strict sandboxing.  This function tells NSS to not
// load user security modules, and makes sure NSS will have proper entropy in a
// restricted, sandboxed environment.
//
// As a defense in depth measure, this function should be called in a sandboxed
// environment.  That way, in the event of a bug, NSS will still not be able to
// load security modules that could expose private data and keys.
//
// Make sure to get an LGTM from the Chrome Security Team if you use this.
CRYPTO_EXPORT void InitNSSSafely();

// Initialize NSS if it isn't already initialized.  This must be called before
// any other NSS functions.  This function is thread-safe, and NSS will only
// ever be initialized once.
CRYPTO_EXPORT void EnsureNSSInit();

// Call this before calling EnsureNSSInit() will force NSS to initialize
// without a persistent DB.  This is used for the special case where access of
// persistent DB is prohibited.
//
// TODO(hclam): Isolate loading default root certs.
//
// NSS will be initialized without loading any user security modules, including
// the built-in root certificates module. User security modules need to be
// loaded manually after NSS initialization.
//
// If EnsureNSSInit() is called before then this function has no effect.
//
// Calling this method only has effect on Linux.
//
// WARNING: Use this with caution.
CRYPTO_EXPORT void ForceNSSNoDBInit();

// This method is used to disable checks in NSS when used in a forked process.
// NSS checks whether it is running a forked process to avoid problems when
// using user security modules in a forked process.  However if we are sure
// there are no modules loaded before the process is forked then there is no
// harm disabling the check.
//
// This method must be called before EnsureNSSInit() to take effect.
//
// WARNING: Use this with caution.
CRYPTO_EXPORT void DisableNSSForkCheck();

// Load NSS library files. This function has no effect on Mac and Windows.
// This loads the necessary NSS library files so that NSS can be initialized
// after loading additional library files is disallowed, for example when the
// sandbox is active.
//
// Note that this does not load libnssckbi.so which contains the root
// certificates.
CRYPTO_EXPORT void LoadNSSLibraries();

// Check if the current NSS version is greater than or equals to |version|.
// A sample version string is "3.12.3".
bool CheckNSSVersion(const char* version);

#if defined(OS_CHROMEOS)
// Indicates that NSS should use the Chaps library so that we
// can access the TPM through NSS.  InitializeTPMTokenAndSystemSlot and
// InitializeTPMForChromeOSUser must still be called to load the slots.
CRYPTO_EXPORT void EnableTPMTokenForNSS();

// Returns true if EnableTPMTokenForNSS has been called.
CRYPTO_EXPORT bool IsTPMTokenEnabledForNSS();

// Returns true if the TPM is owned and PKCS#11 initialized with the
// user and security officer PINs, and has been enabled in NSS by
// calling EnableTPMForNSS, and Chaps has been successfully
// loaded into NSS.
// If |callback| is non-null and the function returns false, the |callback| will
// be run once the TPM is ready. |callback| will never be run if the function
// returns true.
CRYPTO_EXPORT bool IsTPMTokenReady(const base::Closure& callback)
    WARN_UNUSED_RESULT;

// Initialize the TPM token and system slot. The |callback| will run on the same
// thread with true if the token and slot were successfully loaded or were
// already initialized. |callback| will be passed false if loading failed.  Once
// called, InitializeTPMTokenAndSystemSlot must not be called again until the
// |callback| has been run.
CRYPTO_EXPORT void InitializeTPMTokenAndSystemSlot(
    int system_slot_id,
    const base::Callback<void(bool)>& callback);
#endif

// Convert a NSS PRTime value into a base::Time object.
// We use a int64 instead of PRTime here to avoid depending on NSPR headers.
CRYPTO_EXPORT base::Time PRTimeToBaseTime(int64 prtime);

// Convert a base::Time object into a PRTime value.
// We use a int64 instead of PRTime here to avoid depending on NSPR headers.
CRYPTO_EXPORT int64 BaseTimeToPRTime(base::Time time);

#if defined(USE_NSS_CERTS)
// NSS has a bug which can cause a deadlock or stall in some cases when writing
// to the certDB and keyDB. It also has a bug which causes concurrent key pair
// generations to scribble over each other. To work around this, we synchronize
// writes to the NSS databases with a global lock. The lock is hidden beneath a
// function for easy disabling when the bug is fixed. Callers should allow for
// it to return NULL in the future.
//
// See https://bugzilla.mozilla.org/show_bug.cgi?id=564011
base::Lock* GetNSSWriteLock();

// A helper class that acquires the NSS write Lock while the AutoNSSWriteLock
// is in scope.
class CRYPTO_EXPORT AutoNSSWriteLock {
 public:
  AutoNSSWriteLock();
  ~AutoNSSWriteLock();
 private:
  base::Lock *lock_;
  DISALLOW_COPY_AND_ASSIGN(AutoNSSWriteLock);
};
#endif  // defined(USE_NSS_CERTS)

}  // namespace crypto

#endif  // CRYPTO_NSS_UTIL_H_
