// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_NSS_CRYPTO_MODULE_DELEGATE_H_
#define CRYPTO_NSS_CRYPTO_MODULE_DELEGATE_H_

#include <string>

#include "base/callback_forward.h"
#include "crypto/scoped_nss_types.h"

namespace crypto {

// PK11_SetPasswordFunc is a global setting.  An implementation of
// CryptoModuleBlockingPasswordDelegate should be passed using wincx() as the
// user data argument (|wincx|) to relevant NSS functions, which the global
// password handler will call to do the actual work. This delegate should only
// be used in NSS calls on worker threads due to the blocking nature.
class CryptoModuleBlockingPasswordDelegate {
 public:
  virtual ~CryptoModuleBlockingPasswordDelegate() {}

  // Return a value suitable for passing to the |wincx| argument of relevant NSS
  // functions. This should be used instead of passing the object pointer
  // directly to avoid accidentally casting a pointer to a subclass to void* and
  // then casting back to a pointer of the base class
  void* wincx() { return this; }

  // Requests a password to unlock |slot_name|. The interface is synchronous
  // because NSS cannot issue an asynchronous request. |retry| is true if this
  // is a request for the retry and we previously returned the wrong password.
  // The implementation should set |*cancelled| to true if the user cancelled
  // instead of entering a password, otherwise it should return the password the
  // user entered.
  virtual std::string RequestPassword(const std::string& slot_name, bool retry,
                                      bool* cancelled) = 0;

};

// Extends CryptoModuleBlockingPasswordDelegate with the ability to return a
// slot in which to act. (Eg, which slot to store a generated key in.)
class NSSCryptoModuleDelegate : public CryptoModuleBlockingPasswordDelegate {
 public:
  ~NSSCryptoModuleDelegate() override {}

  // Get the slot to store the generated key.
  virtual ScopedPK11Slot RequestSlot() = 0;
};

}  // namespace crypto

#endif  // CRYPTO_NSS_CRYPTO_MODULE_DELEGATE_H_
