// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/aes_128_gcm_helpers_nss.h"

#include <pkcs11t.h>
#include <seccomon.h>

#include "base/lazy_instance.h"
#include "base/macros.h"
#include "crypto/ghash.h"
#include "crypto/scoped_nss_types.h"

#if defined(USE_NSS_CERTS)
#include <dlfcn.h>
#endif

namespace crypto {
namespace {

// Declaration of the prototype both PK11_Decrypt and PK11_Encrypt follow.
using PK11_TransformFunction = SECStatus(PK11SymKey* symKey,
                                         CK_MECHANISM_TYPE mechanism,
                                         SECItem* param,
                                         unsigned char* out,
                                         unsigned int* outLen,
                                         unsigned int maxLen,
                                         const unsigned char* data,
                                         unsigned int dataLen);

// On Linux, dynamically link against the system version of libnss3.so. In
// order to continue working on systems without up-to-date versions of NSS,
// lookup PK11_Decrypt and PK11_Encrypt with dlsym.
//
// GcmSupportChecker is a singleton which caches the results of runtime symbol
// resolution of these symbols.
class GcmSupportChecker {
 public:
  PK11_TransformFunction* pk11_decrypt_func() { return pk11_decrypt_func_; }

  PK11_TransformFunction* pk11_encrypt_func() { return pk11_encrypt_func_; }

 private:
  friend struct base::DefaultLazyInstanceTraits<GcmSupportChecker>;

  GcmSupportChecker() {
#if !defined(USE_NSS_CERTS)
    // Using a bundled version of NSS that is guaranteed to have these symbols.
    pk11_decrypt_func_ = PK11_Decrypt;
    pk11_encrypt_func_ = PK11_Encrypt;
#else
    // Using system NSS libraries and PCKS #11 modules, which may not have the
    // necessary functions (PK11_Decrypt and PK11_Encrypt) or mechanism support
    // (CKM_AES_GCM).

    // If PK11_Decrypt() and PK11_Encrypt() were successfully resolved, then NSS
    // will support AES-GCM directly. This was introduced in NSS 3.15.
    pk11_decrypt_func_ = reinterpret_cast<PK11_TransformFunction*>(
        dlsym(RTLD_DEFAULT, "PK11_Decrypt"));
    pk11_encrypt_func_ = reinterpret_cast<PK11_TransformFunction*>(
        dlsym(RTLD_DEFAULT, "PK11_Encrypt"));
#endif
  }

  ~GcmSupportChecker() {}

  // |pk11_decrypt_func_| stores the runtime symbol resolution of PK11_Decrypt.
  PK11_TransformFunction* pk11_decrypt_func_;

  // |pk11_encrypt_func_| stores the runtime symbol resolution of PK11_Encrypt.
  PK11_TransformFunction* pk11_encrypt_func_;

  DISALLOW_COPY_AND_ASSIGN(GcmSupportChecker);
};

base::LazyInstance<GcmSupportChecker>::Leaky g_gcm_support_checker =
    LAZY_INSTANCE_INITIALIZER;

}  // namespace

// Calls PK11_Decrypt if it's available. Otherwise, emulates CKM_AES_GCM using
// CKM_AES_CTR and the GaloisHash class.
SECStatus PK11DecryptHelper(PK11SymKey* key,
                            CK_MECHANISM_TYPE mechanism,
                            SECItem* param,
                            unsigned char* out,
                            unsigned int* out_len,
                            unsigned int max_len,
                            const unsigned char* data,
                            unsigned int data_len) {
  // If PK11_Decrypt() was successfully resolved or if bundled version of NSS is
  // being used, then NSS will support AES-GCM directly.
  PK11_TransformFunction* pk11_decrypt_func =
      g_gcm_support_checker.Get().pk11_decrypt_func();

  if (pk11_decrypt_func != nullptr) {
    return pk11_decrypt_func(key, mechanism, param, out, out_len, max_len, data,
                             data_len);
  }

  // Otherwise, the user has an older version of NSS. Regrettably, NSS 3.14.x
  // has a bug in the AES GCM code
  // (https://bugzilla.mozilla.org/show_bug.cgi?id=853285), as well as missing
  // the PK11_Decrypt function
  // (https://bugzilla.mozilla.org/show_bug.cgi?id=854063), both of which are
  // resolved in NSS 3.15.

  CHECK_EQ(mechanism, static_cast<CK_MECHANISM_TYPE>(CKM_AES_GCM));
  CHECK_EQ(param->len, sizeof(CK_GCM_PARAMS));

  const CK_GCM_PARAMS* gcm_params =
      reinterpret_cast<CK_GCM_PARAMS*>(param->data);

  const CK_ULONG auth_tag_size = gcm_params->ulTagBits / 8;

  if (gcm_params->ulIvLen != 12u) {
    DVLOG(1) << "ulIvLen is not equal to 12";
    PORT_SetError(SEC_ERROR_INPUT_LEN);
    return SECFailure;
  }

  SECItem my_param = {siBuffer, nullptr, 0};

  // Step 2. Let H = CIPH_K(128 '0' bits).
  unsigned char ghash_key[16] = {0};
  crypto::ScopedPK11Context ctx(
      PK11_CreateContextBySymKey(CKM_AES_ECB, CKA_ENCRYPT, key, &my_param));
  if (!ctx) {
    DVLOG(1) << "PK11_CreateContextBySymKey failed";
    return SECFailure;
  }
  int output_len;
  if (PK11_CipherOp(ctx.get(), ghash_key, &output_len, sizeof(ghash_key),
                    ghash_key, sizeof(ghash_key)) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }

  if (PK11_Finalize(ctx.get()) != SECSuccess) {
    DVLOG(1) << "PK11_Finalize failed";
    return SECFailure;
  }

  if (output_len != sizeof(ghash_key)) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  // Step 3. If len(IV)=96, then let J0 = IV || 31 '0' bits || 1.
  CK_AES_CTR_PARAMS ctr_params = {0};
  ctr_params.ulCounterBits = 32;
  memcpy(ctr_params.cb, gcm_params->pIv, gcm_params->ulIvLen);
  ctr_params.cb[12] = 0;
  ctr_params.cb[13] = 0;
  ctr_params.cb[14] = 0;
  ctr_params.cb[15] = 1;

  my_param.type = siBuffer;
  my_param.data = reinterpret_cast<unsigned char*>(&ctr_params);
  my_param.len = sizeof(ctr_params);

  ctx.reset(
      PK11_CreateContextBySymKey(CKM_AES_CTR, CKA_ENCRYPT, key, &my_param));
  if (!ctx) {
    DVLOG(1) << "PK11_CreateContextBySymKey failed";
    return SECFailure;
  }

  // Step 6. Calculate the encryption mask of GCTR_K(J0, ...).
  unsigned char tag_mask[16] = {0};
  if (PK11_CipherOp(ctx.get(), tag_mask, &output_len, sizeof(tag_mask),
                    tag_mask, sizeof(tag_mask)) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }
  if (output_len != sizeof(tag_mask)) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  if (data_len < auth_tag_size) {
    PORT_SetError(SEC_ERROR_INPUT_LEN);
    return SECFailure;
  }

  // The const_cast for |data| can be removed if system NSS libraries are
  // NSS 3.14.1 or later (NSS bug
  // https://bugzilla.mozilla.org/show_bug.cgi?id=808218).
  if (PK11_CipherOp(ctx.get(), out, &output_len, max_len,
                    const_cast<unsigned char*>(data),
                    data_len - auth_tag_size) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }

  if (PK11_Finalize(ctx.get()) != SECSuccess) {
    DVLOG(1) << "PK11_Finalize failed";
    return SECFailure;
  }

  if (static_cast<unsigned int>(output_len) != data_len - auth_tag_size) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  crypto::GaloisHash ghash(ghash_key);
  ghash.UpdateAdditional(gcm_params->pAAD, gcm_params->ulAADLen);
  ghash.UpdateCiphertext(data, output_len);
  unsigned char auth_tag[auth_tag_size];
  ghash.Finish(auth_tag, auth_tag_size);
  for (unsigned int i = 0; i < auth_tag_size; i++) {
    auth_tag[i] ^= tag_mask[i];
  }

  if (NSS_SecureMemcmp(auth_tag, data + output_len, auth_tag_size) != 0) {
    PORT_SetError(SEC_ERROR_BAD_DATA);
    return SECFailure;
  }

  *out_len = output_len;
  return SECSuccess;
}

// Calls PK11_Encrypt if it's available. Otherwise, emulates CKM_AES_GCM using
// CKM_AES_CTR and the GaloisHash class.
SECStatus PK11EncryptHelper(PK11SymKey* key,
                            CK_MECHANISM_TYPE mechanism,
                            SECItem* param,
                            unsigned char* out,
                            unsigned int* out_len,
                            unsigned int max_len,
                            const unsigned char* data,
                            unsigned int data_len) {
  // If PK11_Encrypt() was successfully resolved or if bundled version of NSS is
  // being used, then NSS will support AES-GCM directly.
  PK11_TransformFunction* pk11_encrypt_func =
      g_gcm_support_checker.Get().pk11_encrypt_func();

  if (pk11_encrypt_func != nullptr) {
    return pk11_encrypt_func(key, mechanism, param, out, out_len, max_len, data,
                             data_len);
  }

  // Otherwise, the user has an older version of NSS. Regrettably, NSS 3.14.x
  // has a bug in the AES GCM code
  // (https://bugzilla.mozilla.org/show_bug.cgi?id=853285), as well as missing
  // the PK11_Encrypt function
  // (https://bugzilla.mozilla.org/show_bug.cgi?id=854063), both of which are
  // resolved in NSS 3.15.

  CHECK_EQ(mechanism, static_cast<CK_MECHANISM_TYPE>(CKM_AES_GCM));
  CHECK_EQ(param->len, sizeof(CK_GCM_PARAMS));

  const CK_GCM_PARAMS* gcm_params =
      reinterpret_cast<CK_GCM_PARAMS*>(param->data);

  const CK_ULONG auth_tag_size = gcm_params->ulTagBits / 8;

  if (max_len < auth_tag_size) {
    DVLOG(1) << "max_len is less than kAuthTagSize";
    PORT_SetError(SEC_ERROR_OUTPUT_LEN);
    return SECFailure;
  }

  if (gcm_params->ulIvLen != 12u) {
    DVLOG(1) << "ulIvLen is not equal to 12";
    PORT_SetError(SEC_ERROR_INPUT_LEN);
    return SECFailure;
  }

  SECItem my_param = {siBuffer, nullptr, 0};

  // Step 1. Let H = CIPH_K(128 '0' bits).
  unsigned char ghash_key[16] = {0};
  crypto::ScopedPK11Context ctx(
      PK11_CreateContextBySymKey(CKM_AES_ECB, CKA_ENCRYPT, key, &my_param));
  if (!ctx) {
    DVLOG(1) << "PK11_CreateContextBySymKey failed";
    return SECFailure;
  }
  int output_len;
  if (PK11_CipherOp(ctx.get(), ghash_key, &output_len, sizeof(ghash_key),
                    ghash_key, sizeof(ghash_key)) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }

  if (PK11_Finalize(ctx.get()) != SECSuccess) {
    DVLOG(1) << "PK11_Finalize failed";
    return SECFailure;
  }

  if (output_len != sizeof(ghash_key)) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  // Step 2. If len(IV)=96, then let J0 = IV || 31 '0' bits || 1.
  CK_AES_CTR_PARAMS ctr_params = {0};
  ctr_params.ulCounterBits = 32;
  memcpy(ctr_params.cb, gcm_params->pIv, gcm_params->ulIvLen);
  ctr_params.cb[12] = 0;
  ctr_params.cb[13] = 0;
  ctr_params.cb[14] = 0;
  ctr_params.cb[15] = 1;

  my_param.type = siBuffer;
  my_param.data = reinterpret_cast<unsigned char*>(&ctr_params);
  my_param.len = sizeof(ctr_params);

  ctx.reset(
      PK11_CreateContextBySymKey(CKM_AES_CTR, CKA_ENCRYPT, key, &my_param));
  if (!ctx) {
    DVLOG(1) << "PK11_CreateContextBySymKey failed";
    return SECFailure;
  }

  // Step 6. Calculate the encryption mask of GCTR_K(J0, ...).
  unsigned char tag_mask[16] = {0};
  if (PK11_CipherOp(ctx.get(), tag_mask, &output_len, sizeof(tag_mask),
                    tag_mask, sizeof(tag_mask)) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }
  if (output_len != sizeof(tag_mask)) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  // The const_cast for |data| can be removed if system NSS libraries are
  // NSS 3.14.1 or later (NSS bug
  // https://bugzilla.mozilla.org/show_bug.cgi?id=808218).
  if (PK11_CipherOp(ctx.get(), out, &output_len, max_len,
                    const_cast<unsigned char*>(data), data_len) != SECSuccess) {
    DVLOG(1) << "PK11_CipherOp failed";
    return SECFailure;
  }

  if (PK11_Finalize(ctx.get()) != SECSuccess) {
    DVLOG(1) << "PK11_Finalize failed";
    return SECFailure;
  }

  if (static_cast<unsigned int>(output_len) != data_len) {
    DVLOG(1) << "Wrong output length";
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
  }

  if ((max_len - auth_tag_size) < static_cast<unsigned int>(output_len)) {
    DVLOG(1) << "(max_len - kAuthTagSize) is less than output_len";
    PORT_SetError(SEC_ERROR_OUTPUT_LEN);
    return SECFailure;
  }

  crypto::GaloisHash ghash(ghash_key);
  ghash.UpdateAdditional(gcm_params->pAAD, gcm_params->ulAADLen);
  ghash.UpdateCiphertext(out, output_len);
  ghash.Finish(out + output_len, auth_tag_size);
  for (unsigned int i = 0; i < auth_tag_size; i++) {
    out[output_len + i] ^= tag_mask[i];
  }

  *out_len = output_len + auth_tag_size;
  return SECSuccess;
}

}  // namespace crypto
