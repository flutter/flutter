// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/openssl_util.h"

#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/cpu.h>

#include "base/logging.h"
#include "base/memory/scoped_vector.h"
#include "base/memory/singleton.h"
#include "base/strings/string_piece.h"
#include "base/synchronization/lock.h"
#include "build/build_config.h"

#if defined(OS_ANDROID) && defined(ARCH_CPU_ARMEL)
#include <cpu-features.h>
#include "base/cpu.h"
#endif

namespace crypto {

namespace {

void CurrentThreadId(CRYPTO_THREADID* id) {
  CRYPTO_THREADID_set_numeric(
      id, static_cast<unsigned long>(base::PlatformThread::CurrentId()));
}

// Singleton for initializing and cleaning up the OpenSSL library.
class OpenSSLInitSingleton {
 public:
  static OpenSSLInitSingleton* GetInstance() {
    // We allow the SSL environment to leak for multiple reasons:
    //   -  it is used from a non-joinable worker thread that is not stopped on
    //      shutdown, hence may still be using OpenSSL library after the AtExit
    //      runner has completed.
    //   -  There are other OpenSSL related singletons (e.g. the client socket
    //      context) who's cleanup depends on the global environment here, but
    //      we can't control the order the AtExit handlers will run in so
    //      allowing the global environment to leak at least ensures it is
    //      available for those other singletons to reliably cleanup.
    return Singleton<OpenSSLInitSingleton,
               LeakySingletonTraits<OpenSSLInitSingleton> >::get();
  }
 private:
  friend struct DefaultSingletonTraits<OpenSSLInitSingleton>;
  OpenSSLInitSingleton() {
#if defined(OS_ANDROID) && defined(ARCH_CPU_ARMEL)
    const bool has_neon =
        (android_getCpuFeatures() & ANDROID_CPU_ARM_FEATURE_NEON) != 0;
    // CRYPTO_set_NEON_capable is called before |SSL_library_init| because this
    // stops BoringSSL from probing for NEON support via SIGILL in the case
    // that getauxval isn't present.
    CRYPTO_set_NEON_capable(has_neon);
    // See https://code.google.com/p/chromium/issues/detail?id=341598
    base::CPU cpu;
    CRYPTO_set_NEON_functional(!cpu.has_broken_neon());
#endif

    SSL_load_error_strings();
    SSL_library_init();
    int num_locks = CRYPTO_num_locks();
    locks_.reserve(num_locks);
    for (int i = 0; i < num_locks; ++i)
      locks_.push_back(new base::Lock());
    CRYPTO_set_locking_callback(LockingCallback);
    CRYPTO_THREADID_set_callback(CurrentThreadId);
  }

  ~OpenSSLInitSingleton() {
    CRYPTO_set_locking_callback(NULL);
    EVP_cleanup();
    ERR_free_strings();
  }

  static void LockingCallback(int mode, int n, const char* file, int line) {
    OpenSSLInitSingleton::GetInstance()->OnLockingCallback(mode, n, file, line);
  }

  void OnLockingCallback(int mode, int n, const char* file, int line) {
    CHECK_LT(static_cast<size_t>(n), locks_.size());
    if (mode & CRYPTO_LOCK)
      locks_[n]->Acquire();
    else
      locks_[n]->Release();
  }

  // These locks are used and managed by OpenSSL via LockingCallback().
  ScopedVector<base::Lock> locks_;

  DISALLOW_COPY_AND_ASSIGN(OpenSSLInitSingleton);
};

// Callback routine for OpenSSL to print error messages. |str| is a
// NULL-terminated string of length |len| containing diagnostic information
// such as the library, function and reason for the error, the file and line
// where the error originated, plus potentially any context-specific
// information about the error. |context| contains a pointer to user-supplied
// data, which is currently unused.
// If this callback returns a value <= 0, OpenSSL will stop processing the
// error queue and return, otherwise it will continue calling this function
// until all errors have been removed from the queue.
int OpenSSLErrorCallback(const char* str, size_t len, void* context) {
  DVLOG(1) << "\t" << base::StringPiece(str, len);
  return 1;
}

}  // namespace

void EnsureOpenSSLInit() {
  (void)OpenSSLInitSingleton::GetInstance();
}

void ClearOpenSSLERRStack(const tracked_objects::Location& location) {
  if (logging::DEBUG_MODE && VLOG_IS_ON(1)) {
    int error_num = ERR_peek_error();
    if (error_num == 0)
      return;

    std::string message;
    location.Write(true, true, &message);
    DVLOG(1) << "OpenSSL ERR_get_error stack from " << message;
    ERR_print_errors_cb(&OpenSSLErrorCallback, NULL);
  } else {
    ERR_clear_error();
  }
}

}  // namespace crypto
