// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/mac_security_services_lock.h"

#include "base/memory/singleton.h"
#include "base/synchronization/lock.h"

namespace {

// This singleton pertains to Apple's wrappers over their own CSSM handles,
// as opposed to our own CSSM_CSP_HANDLE in cssm_init.cc.
class SecurityServicesSingleton {
 public:
  static SecurityServicesSingleton* GetInstance() {
    return Singleton<SecurityServicesSingleton,
                     LeakySingletonTraits<SecurityServicesSingleton> >::get();
  }

  base::Lock& lock() { return lock_; }

 private:
  friend struct DefaultSingletonTraits<SecurityServicesSingleton>;

  SecurityServicesSingleton() {}
  ~SecurityServicesSingleton() {}

  base::Lock lock_;

  DISALLOW_COPY_AND_ASSIGN(SecurityServicesSingleton);
};

}  // namespace

namespace crypto {

base::Lock& GetMacSecurityServicesLock() {
  return SecurityServicesSingleton::GetInstance()->lock();
}

}  // namespace crypto
