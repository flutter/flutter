// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/symmetric_key.h"

#include <vector>

// TODO(wtc): replace scoped_array by std::vector.
#include "base/memory/scoped_ptr.h"
#include "base/sys_byteorder.h"

namespace crypto {

namespace {

// The following is a non-public Microsoft header documented in MSDN under
// CryptImportKey / CryptExportKey. Following the header is the byte array of
// the actual plaintext key.
struct PlaintextBlobHeader {
  BLOBHEADER hdr;
  DWORD cbKeySize;
};

// CryptoAPI makes use of three distinct ALG_IDs for AES, rather than just
// CALG_AES (which exists, but depending on the functions you are calling, may
// result in function failure, whereas the subtype would succeed).
ALG_ID GetAESAlgIDForKeySize(size_t key_size_in_bits) {
  // Only AES-128/-192/-256 is supported in CryptoAPI.
  switch (key_size_in_bits) {
    case 128:
      return CALG_AES_128;
    case 192:
      return CALG_AES_192;
    case 256:
      return CALG_AES_256;
    default:
      NOTREACHED();
      return 0;
  }
};

// Imports a raw/plaintext key of |key_size| stored in |*key_data| into a new
// key created for the specified |provider|. |alg| contains the algorithm of
// the key being imported.
// If |key_data| is intended to be used as an HMAC key, then |alg| should be
// CALG_HMAC.
// If successful, returns true and stores the imported key in |*key|.
// TODO(wtc): use this function in hmac_win.cc.
bool ImportRawKey(HCRYPTPROV provider,
                  ALG_ID alg,
                  const void* key_data, size_t key_size,
                  ScopedHCRYPTKEY* key) {
  DCHECK_GT(key_size, 0);

  DWORD actual_size =
      static_cast<DWORD>(sizeof(PlaintextBlobHeader) + key_size);
  std::vector<BYTE> tmp_data(actual_size);
  BYTE* actual_key = &tmp_data[0];
  memcpy(actual_key + sizeof(PlaintextBlobHeader), key_data, key_size);
  PlaintextBlobHeader* key_header =
      reinterpret_cast<PlaintextBlobHeader*>(actual_key);
  memset(key_header, 0, sizeof(PlaintextBlobHeader));

  key_header->hdr.bType = PLAINTEXTKEYBLOB;
  key_header->hdr.bVersion = CUR_BLOB_VERSION;
  key_header->hdr.aiKeyAlg = alg;

  key_header->cbKeySize = static_cast<DWORD>(key_size);

  HCRYPTKEY unsafe_key = NULL;
  DWORD flags = CRYPT_EXPORTABLE;
  if (alg == CALG_HMAC) {
    // Though it may appear odd that IPSEC and RC2 are being used, this is
    // done in accordance with Microsoft's FIPS 140-2 Security Policy for the
    // RSA Enhanced Provider, as the approved means of using arbitrary HMAC
    // key material.
    key_header->hdr.aiKeyAlg = CALG_RC2;
    flags |= CRYPT_IPSEC_HMAC_KEY;
  }

  BOOL ok =
      CryptImportKey(provider, actual_key, actual_size, 0, flags, &unsafe_key);

  // Clean up the temporary copy of key, regardless of whether it was imported
  // sucessfully or not.
  SecureZeroMemory(actual_key, actual_size);

  if (!ok)
    return false;

  key->reset(unsafe_key);
  return true;
}

// Attempts to generate a random AES key of |key_size_in_bits|. Returns true
// if generation is successful, storing the generated key in |*key| and the
// key provider (CSP) in |*provider|.
bool GenerateAESKey(size_t key_size_in_bits,
                    ScopedHCRYPTPROV* provider,
                    ScopedHCRYPTKEY* key) {
  DCHECK(provider);
  DCHECK(key);

  ALG_ID alg = GetAESAlgIDForKeySize(key_size_in_bits);
  if (alg == 0)
    return false;

  ScopedHCRYPTPROV safe_provider;
  // Note: The only time NULL is safe to be passed as pszContainer is when
  // dwFlags contains CRYPT_VERIFYCONTEXT, as all keys generated and/or used
  // will be treated as ephemeral keys and not persisted.
  BOOL ok = CryptAcquireContext(safe_provider.receive(), NULL, NULL,
                                PROV_RSA_AES, CRYPT_VERIFYCONTEXT);
  if (!ok)
    return false;

  ScopedHCRYPTKEY safe_key;
  // In the FIPS 140-2 Security Policy for CAPI on XP/Vista+, Microsoft notes
  // that CryptGenKey makes use of the same functionality exposed via
  // CryptGenRandom. The reason this is being used, as opposed to
  // CryptGenRandom and CryptImportKey is for compliance with the security
  // policy
  ok = CryptGenKey(safe_provider.get(), alg, CRYPT_EXPORTABLE,
                   safe_key.receive());
  if (!ok)
    return false;

  key->swap(safe_key);
  provider->swap(safe_provider);

  return true;
}

// Returns true if the HMAC key size meets the requirement of FIPS 198
// Section 3.  |alg| is the hash function used in the HMAC.
bool CheckHMACKeySize(size_t key_size_in_bits, ALG_ID alg) {
  DWORD hash_size = 0;
  switch (alg) {
    case CALG_SHA1:
      hash_size = 20;
      break;
    case CALG_SHA_256:
      hash_size = 32;
      break;
    case CALG_SHA_384:
      hash_size = 48;
      break;
    case CALG_SHA_512:
      hash_size = 64;
      break;
  }
  if (hash_size == 0)
    return false;

  // An HMAC key must be >= L/2, where L is the output size of the hash
  // function being used.
  return (key_size_in_bits >= (hash_size / 2 * 8) &&
         (key_size_in_bits % 8) == 0);
}

// Attempts to generate a random, |key_size_in_bits|-long HMAC key, for use
// with the hash function |alg|.
// |key_size_in_bits| must be >= 1/2 the hash size of |alg| for security.
// Returns true if generation is successful, storing the generated key in
// |*key| and the key provider (CSP) in |*provider|.
bool GenerateHMACKey(size_t key_size_in_bits,
                     ALG_ID alg,
                     ScopedHCRYPTPROV* provider,
                     ScopedHCRYPTKEY* key,
                     scoped_ptr<BYTE[]>* raw_key) {
  DCHECK(provider);
  DCHECK(key);
  DCHECK(raw_key);

  if (!CheckHMACKeySize(key_size_in_bits, alg))
    return false;

  ScopedHCRYPTPROV safe_provider;
  // See comment in GenerateAESKey as to why NULL is acceptable for the
  // container name.
  BOOL ok = CryptAcquireContext(safe_provider.receive(), NULL, NULL,
                                PROV_RSA_FULL, CRYPT_VERIFYCONTEXT);
  if (!ok)
    return false;

  DWORD key_size_in_bytes = static_cast<DWORD>(key_size_in_bits / 8);
  scoped_ptr<BYTE[]> random(new BYTE[key_size_in_bytes]);
  ok = CryptGenRandom(safe_provider, key_size_in_bytes, random.get());
  if (!ok)
    return false;

  ScopedHCRYPTKEY safe_key;
  bool rv = ImportRawKey(safe_provider, CALG_HMAC, random.get(),
                         key_size_in_bytes, &safe_key);
  if (rv) {
    key->swap(safe_key);
    provider->swap(safe_provider);
    raw_key->swap(random);
  }

  SecureZeroMemory(random.get(), key_size_in_bytes);
  return rv;
}

// Attempts to create an HMAC hash instance using the specified |provider|
// and |key|. The inner hash function will be |hash_alg|. If successful,
// returns true and stores the hash in |*hash|.
// TODO(wtc): use this function in hmac_win.cc.
bool CreateHMACHash(HCRYPTPROV provider,
                    HCRYPTKEY key,
                    ALG_ID hash_alg,
                    ScopedHCRYPTHASH* hash) {
  ScopedHCRYPTHASH safe_hash;
  BOOL ok = CryptCreateHash(provider, CALG_HMAC, key, 0, safe_hash.receive());
  if (!ok)
    return false;

  HMAC_INFO hmac_info;
  memset(&hmac_info, 0, sizeof(hmac_info));
  hmac_info.HashAlgid = hash_alg;

  ok = CryptSetHashParam(safe_hash, HP_HMAC_INFO,
                         reinterpret_cast<const BYTE*>(&hmac_info), 0);
  if (!ok)
    return false;

  hash->swap(safe_hash);
  return true;
}

// Computes a block of the derived key using the PBKDF2 function F for the
// specified |block_index| using the PRF |hash|, writing the output to
// |output_buf|.
// |output_buf| must have enough space to accomodate the output of the PRF
// specified by |hash|.
// Returns true if the block was successfully computed.
bool ComputePBKDF2Block(HCRYPTHASH hash,
                        DWORD hash_size,
                        const std::string& salt,
                        size_t iterations,
                        uint32 block_index,
                        BYTE* output_buf) {
  // From RFC 2898:
  // 3. <snip> The function F is defined as the exclusive-or sum of the first
  //    c iterates of the underlying pseudorandom function PRF applied to the
  //    password P and the concatenation of the salt S and the block index i:
  //      F (P, S, c, i) = U_1 \xor U_2 \xor ... \xor U_c
  //    where
  //      U_1 = PRF(P, S || INT (i))
  //      U_2 = PRF(P, U_1)
  //      ...
  //      U_c = PRF(P, U_{c-1})
  ScopedHCRYPTHASH safe_hash;
  BOOL ok = CryptDuplicateHash(hash, NULL, 0, safe_hash.receive());
  if (!ok)
    return false;

  // Iteration U_1: Compute PRF for S.
  ok = CryptHashData(safe_hash, reinterpret_cast<const BYTE*>(salt.data()),
                     static_cast<DWORD>(salt.size()), 0);
  if (!ok)
    return false;

  // Iteration U_1: and append (big-endian) INT (i).
  uint32 big_endian_block_index = base::HostToNet32(block_index);
  ok = CryptHashData(safe_hash,
                     reinterpret_cast<BYTE*>(&big_endian_block_index),
                     sizeof(big_endian_block_index), 0);

  std::vector<BYTE> hash_value(hash_size);

  DWORD size = hash_size;
  ok = CryptGetHashParam(safe_hash, HP_HASHVAL, &hash_value[0], &size, 0);
  if (!ok  || size != hash_size)
    return false;

  memcpy(output_buf, &hash_value[0], hash_size);

  // Iteration 2 - c: Compute U_{iteration} by applying the PRF to
  // U_{iteration - 1}, then xor the resultant hash with |output|, which
  // contains U_1 ^ U_2 ^ ... ^ U_{iteration - 1}.
  for (size_t iteration = 2; iteration <= iterations; ++iteration) {
    safe_hash.reset();
    ok = CryptDuplicateHash(hash, NULL, 0, safe_hash.receive());
    if (!ok)
      return false;

    ok = CryptHashData(safe_hash, &hash_value[0], hash_size, 0);
    if (!ok)
      return false;

    size = hash_size;
    ok = CryptGetHashParam(safe_hash, HP_HASHVAL, &hash_value[0], &size, 0);
    if (!ok || size != hash_size)
      return false;

    for (int i = 0; i < hash_size; ++i)
      output_buf[i] ^= hash_value[i];
  }

  return true;
}

}  // namespace

SymmetricKey::~SymmetricKey() {
  // TODO(wtc): create a "secure" string type that zeroes itself in the
  // destructor.
  if (!raw_key_.empty())
    SecureZeroMemory(const_cast<char *>(raw_key_.data()), raw_key_.size());
}

// static
SymmetricKey* SymmetricKey::GenerateRandomKey(Algorithm algorithm,
                                              size_t key_size_in_bits) {
  DCHECK_GE(key_size_in_bits, 8);

  ScopedHCRYPTPROV provider;
  ScopedHCRYPTKEY key;

  bool ok = false;
  scoped_ptr<BYTE[]> raw_key;

  switch (algorithm) {
    case AES:
      ok = GenerateAESKey(key_size_in_bits, &provider, &key);
      break;
    case HMAC_SHA1:
      ok = GenerateHMACKey(key_size_in_bits, CALG_SHA1, &provider,
                           &key, &raw_key);
      break;
  }

  if (!ok) {
    NOTREACHED();
    return NULL;
  }

  size_t key_size_in_bytes = key_size_in_bits / 8;
  if (raw_key == NULL)
    key_size_in_bytes = 0;

  SymmetricKey* result = new SymmetricKey(provider.release(),
                                          key.release(),
                                          raw_key.get(),
                                          key_size_in_bytes);
  if (raw_key != NULL)
    SecureZeroMemory(raw_key.get(), key_size_in_bytes);

  return result;
}

// static
SymmetricKey* SymmetricKey::DeriveKeyFromPassword(Algorithm algorithm,
                                                  const std::string& password,
                                                  const std::string& salt,
                                                  size_t iterations,
                                                  size_t key_size_in_bits) {
  // CryptoAPI lacks routines to perform PBKDF2 derivation as specified
  // in RFC 2898, so it must be manually implemented. Only HMAC-SHA1 is
  // supported as the PRF.

  // While not used until the end, sanity-check the input before proceeding
  // with the expensive computation.
  DWORD provider_type = 0;
  ALG_ID alg = 0;
  switch (algorithm) {
    case AES:
      provider_type = PROV_RSA_AES;
      alg = GetAESAlgIDForKeySize(key_size_in_bits);
      break;
    case HMAC_SHA1:
      provider_type = PROV_RSA_FULL;
      alg = CALG_HMAC;
      break;
    default:
      NOTREACHED();
      break;
  }
  if (provider_type == 0 || alg == 0)
    return NULL;

  ScopedHCRYPTPROV provider;
  BOOL ok = CryptAcquireContext(provider.receive(), NULL, NULL, provider_type,
                                CRYPT_VERIFYCONTEXT);
  if (!ok)
    return NULL;

  // Convert the user password into a key suitable to be fed into the PRF
  // function.
  ScopedHCRYPTKEY password_as_key;
  BYTE* password_as_bytes =
      const_cast<BYTE*>(reinterpret_cast<const BYTE*>(password.data()));
  if (!ImportRawKey(provider, CALG_HMAC, password_as_bytes,
                    password.size(), &password_as_key))
    return NULL;

  // Configure the PRF function. Only HMAC variants are supported, with the
  // only hash function supported being SHA1.
  // TODO(rsleevi): Support SHA-256 on XP SP3+.
  ScopedHCRYPTHASH prf;
  if (!CreateHMACHash(provider, password_as_key, CALG_SHA1, &prf))
    return NULL;

  DWORD hLen = 0;
  DWORD param_size = sizeof(hLen);
  ok = CryptGetHashParam(prf, HP_HASHSIZE,
                         reinterpret_cast<BYTE*>(&hLen), &param_size, 0);
  if (!ok || hLen == 0)
    return NULL;

  // 1. If dkLen > (2^32 - 1) * hLen, output "derived key too long" and stop.
  size_t dkLen = key_size_in_bits / 8;
  DCHECK_GT(dkLen, 0);

  if ((dkLen / hLen) > 0xFFFFFFFF) {
    DLOG(ERROR) << "Derived key too long.";
    return NULL;
  }

  // 2. Let l be the number of hLen-octet blocks in the derived key,
  //    rounding up, and let r be the number of octets in the last
  //    block:
  size_t L = (dkLen + hLen - 1) / hLen;
  DCHECK_GT(L, 0);

  size_t total_generated_size = L * hLen;
  std::vector<BYTE> generated_key(total_generated_size);
  BYTE* block_offset = &generated_key[0];

  // 3. For each block of the derived key apply the function F defined below
  //    to the password P, the salt S, the iteration count c, and the block
  //    index to compute the block:
  //    T_1 = F (P, S, c, 1)
  //    T_2 = F (P, S, c, 2)
  //    ...
  //    T_l = F (P, S, c, l)
  // <snip>
  // 4. Concatenate the blocks and extract the first dkLen octets to produce
  //    a derived key DK:
  //    DK = T_1 || T_2 || ... || T_l<0..r-1>
  for (uint32 block_index = 1; block_index <= L; ++block_index) {
    if (!ComputePBKDF2Block(prf, hLen, salt, iterations, block_index,
                            block_offset))
        return NULL;
    block_offset += hLen;
  }

  // Convert the derived key bytes into a key handle for the desired algorithm.
  ScopedHCRYPTKEY key;
  if (!ImportRawKey(provider, alg, &generated_key[0], dkLen, &key))
    return NULL;

  SymmetricKey* result = new SymmetricKey(provider.release(), key.release(),
                                          &generated_key[0], dkLen);

  SecureZeroMemory(&generated_key[0], total_generated_size);

  return result;
}

// static
SymmetricKey* SymmetricKey::Import(Algorithm algorithm,
                                   const std::string& raw_key) {
  DWORD provider_type = 0;
  ALG_ID alg = 0;
  switch (algorithm) {
    case AES:
      provider_type = PROV_RSA_AES;
      alg = GetAESAlgIDForKeySize(raw_key.size() * 8);
      break;
    case HMAC_SHA1:
      provider_type = PROV_RSA_FULL;
      alg = CALG_HMAC;
      break;
    default:
      NOTREACHED();
      break;
  }
  if (provider_type == 0 || alg == 0)
    return NULL;

  ScopedHCRYPTPROV provider;
  BOOL ok = CryptAcquireContext(provider.receive(), NULL, NULL, provider_type,
                                CRYPT_VERIFYCONTEXT);
  if (!ok)
    return NULL;

  ScopedHCRYPTKEY key;
  if (!ImportRawKey(provider, alg, raw_key.data(), raw_key.size(), &key))
    return NULL;

  return new SymmetricKey(provider.release(), key.release(),
                          raw_key.data(), raw_key.size());
}

bool SymmetricKey::GetRawKey(std::string* raw_key) {
  // Short circuit for when the key was supplied to the constructor.
  if (!raw_key_.empty()) {
    *raw_key = raw_key_;
    return true;
  }

  DWORD size = 0;
  BOOL ok = CryptExportKey(key_, 0, PLAINTEXTKEYBLOB, 0, NULL, &size);
  if (!ok)
    return false;

  std::vector<BYTE> result(size);

  ok = CryptExportKey(key_, 0, PLAINTEXTKEYBLOB, 0, &result[0], &size);
  if (!ok)
    return false;

  PlaintextBlobHeader* header =
      reinterpret_cast<PlaintextBlobHeader*>(&result[0]);
  raw_key->assign(reinterpret_cast<char*>(&result[sizeof(*header)]),
                  header->cbKeySize);

  SecureZeroMemory(&result[0], size);

  return true;
}

SymmetricKey::SymmetricKey(HCRYPTPROV provider,
                           HCRYPTKEY key,
                           const void* key_data, size_t key_size_in_bytes)
    : provider_(provider), key_(key) {
  if (key_data) {
    raw_key_.assign(reinterpret_cast<const char*>(key_data),
                    key_size_in_bytes);
  }
}

}  // namespace crypto
