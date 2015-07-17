// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/apple_keychain.h"

#import <Foundation/Foundation.h>

#include "base/mac/foundation_util.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/mac/scoped_nsobject.h"

namespace {

enum KeychainAction {
  kKeychainActionCreate,
  kKeychainActionUpdate
};

// Creates a dictionary that can be used to query the keystore.
// Ownership follows the Create rule.
CFDictionaryRef CreateGenericPasswordQuery(UInt32 serviceNameLength,
                                           const char* serviceName,
                                           UInt32 accountNameLength,
                                           const char* accountName) {
  CFMutableDictionaryRef query =
      CFDictionaryCreateMutable(NULL,
                                5,
                                &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);
  // Type of element is generic password.
  CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);

  // Set the service name.
  base::scoped_nsobject<NSString> service_name_ns(
      [[NSString alloc] initWithBytes:serviceName
                               length:serviceNameLength
                             encoding:NSUTF8StringEncoding]);
  CFDictionarySetValue(query, kSecAttrService,
                       base::mac::NSToCFCast(service_name_ns));

  // Set the account name.
  base::scoped_nsobject<NSString> account_name_ns(
      [[NSString alloc] initWithBytes:accountName
                               length:accountNameLength
                             encoding:NSUTF8StringEncoding]);
  CFDictionarySetValue(query, kSecAttrAccount,
                       base::mac::NSToCFCast(account_name_ns));

  // Use the proper search constants, return only the data of the first match.
  CFDictionarySetValue(query, kSecMatchLimit, kSecMatchLimitOne);
  CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
  return query;
}

// Creates a dictionary conatining the data to save into the keychain.
// Ownership follows the Create rule.
CFDictionaryRef CreateKeychainData(UInt32 serviceNameLength,
                                   const char* serviceName,
                                   UInt32 accountNameLength,
                                   const char* accountName,
                                   UInt32 passwordLength,
                                   const void* passwordData,
                                   KeychainAction action) {
  CFMutableDictionaryRef keychain_data =
      CFDictionaryCreateMutable(NULL,
                                0,
                                &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);

  // Set the password.
  NSData* password = [NSData dataWithBytes:passwordData length:passwordLength];
  CFDictionarySetValue(keychain_data, kSecValueData,
                       base::mac::NSToCFCast(password));

  // If this is not a creation, no structural information is needed.
  if (action != kKeychainActionCreate)
    return keychain_data;

  // Set the type of the data.
  CFDictionarySetValue(keychain_data, kSecClass, kSecClassGenericPassword);

  // Only allow access when the device has been unlocked.
  CFDictionarySetValue(keychain_data,
                       kSecAttrAccessible,
                       kSecAttrAccessibleWhenUnlocked);

  // Set the service name.
  base::scoped_nsobject<NSString> service_name_ns(
      [[NSString alloc] initWithBytes:serviceName
                               length:serviceNameLength
                             encoding:NSUTF8StringEncoding]);
  CFDictionarySetValue(keychain_data, kSecAttrService,
                       base::mac::NSToCFCast(service_name_ns));

  // Set the account name.
  base::scoped_nsobject<NSString> account_name_ns(
      [[NSString alloc] initWithBytes:accountName
                               length:accountNameLength
                             encoding:NSUTF8StringEncoding]);
  CFDictionarySetValue(keychain_data, kSecAttrAccount,
                       base::mac::NSToCFCast(account_name_ns));

  return keychain_data;
}

}  // namespace

namespace crypto {

AppleKeychain::AppleKeychain() {}

AppleKeychain::~AppleKeychain() {}

OSStatus AppleKeychain::ItemFreeContent(SecKeychainAttributeList* attrList,
                                        void* data) const {
  free(data);
  return noErr;
}

OSStatus AppleKeychain::AddGenericPassword(SecKeychainRef keychain,
                                           UInt32 serviceNameLength,
                                           const char* serviceName,
                                           UInt32 accountNameLength,
                                           const char* accountName,
                                           UInt32 passwordLength,
                                           const void* passwordData,
                                           SecKeychainItemRef* itemRef) const {
  base::ScopedCFTypeRef<CFDictionaryRef> query(CreateGenericPasswordQuery(
      serviceNameLength, serviceName, accountNameLength, accountName));
  // Check that there is not already a password.
  OSStatus status = SecItemCopyMatching(query, NULL);
  if (status == errSecItemNotFound) {
    // A new entry must be created.
    base::ScopedCFTypeRef<CFDictionaryRef> keychain_data(
        CreateKeychainData(serviceNameLength,
                           serviceName,
                           accountNameLength,
                           accountName,
                           passwordLength,
                           passwordData,
                           kKeychainActionCreate));
    status = SecItemAdd(keychain_data, NULL);
  } else if (status == noErr) {
    // The entry must be updated.
    base::ScopedCFTypeRef<CFDictionaryRef> keychain_data(
        CreateKeychainData(serviceNameLength,
                           serviceName,
                           accountNameLength,
                           accountName,
                           passwordLength,
                           passwordData,
                           kKeychainActionUpdate));
    status = SecItemUpdate(query, keychain_data);
  }

  return status;
}

OSStatus AppleKeychain::FindGenericPassword(CFTypeRef keychainOrArray,
                                            UInt32 serviceNameLength,
                                            const char* serviceName,
                                            UInt32 accountNameLength,
                                            const char* accountName,
                                            UInt32* passwordLength,
                                            void** passwordData,
                                            SecKeychainItemRef* itemRef) const {
  DCHECK((passwordData && passwordLength) ||
         (!passwordData && !passwordLength));
  base::ScopedCFTypeRef<CFDictionaryRef> query(CreateGenericPasswordQuery(
      serviceNameLength, serviceName, accountNameLength, accountName));

  // Get the keychain item containing the password.
  CFTypeRef resultRef = NULL;
  OSStatus status = SecItemCopyMatching(query, &resultRef);
  base::ScopedCFTypeRef<CFTypeRef> result(resultRef);

  if (status != noErr) {
    if (passwordData) {
      *passwordData = NULL;
      *passwordLength = 0;
    }
    return status;
  }

  if (passwordData) {
    CFDataRef data = base::mac::CFCast<CFDataRef>(result);
    NSUInteger length = CFDataGetLength(data);
    *passwordData = malloc(length * sizeof(UInt8));
    CFDataGetBytes(data, CFRangeMake(0, length), (UInt8*)*passwordData);
    *passwordLength = length;
  }
  return status;
}

}  // namespace crypto
