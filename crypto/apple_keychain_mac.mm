// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/apple_keychain.h"

#import <Foundation/Foundation.h>

#include "base/synchronization/lock.h"
#include "crypto/mac_security_services_lock.h"

namespace crypto {

AppleKeychain::AppleKeychain() {}

AppleKeychain::~AppleKeychain() {}

OSStatus AppleKeychain::ItemCopyAttributesAndData(
    SecKeychainItemRef itemRef,
    SecKeychainAttributeInfo* info,
    SecItemClass* itemClass,
    SecKeychainAttributeList** attrList,
    UInt32* length,
    void** outData) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainItemCopyAttributesAndData(itemRef, info, itemClass,
                                              attrList, length, outData);
}

OSStatus AppleKeychain::ItemModifyAttributesAndData(
    SecKeychainItemRef itemRef,
    const SecKeychainAttributeList* attrList,
    UInt32 length,
    const void* data) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainItemModifyAttributesAndData(itemRef, attrList, length,
                                                data);
}

OSStatus AppleKeychain::ItemFreeAttributesAndData(
    SecKeychainAttributeList* attrList,
    void* data) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainItemFreeAttributesAndData(attrList, data);
}

OSStatus AppleKeychain::ItemDelete(SecKeychainItemRef itemRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainItemDelete(itemRef);
}

OSStatus AppleKeychain::SearchCreateFromAttributes(
    CFTypeRef keychainOrArray,
    SecItemClass itemClass,
    const SecKeychainAttributeList* attrList,
    SecKeychainSearchRef* searchRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainSearchCreateFromAttributes(keychainOrArray, itemClass,
                                               attrList, searchRef);
}

OSStatus AppleKeychain::SearchCopyNext(SecKeychainSearchRef searchRef,
                                       SecKeychainItemRef* itemRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainSearchCopyNext(searchRef, itemRef);
}

OSStatus AppleKeychain::AddInternetPassword(
    SecKeychainRef keychain,
    UInt32 serverNameLength,
    const char* serverName,
    UInt32 securityDomainLength,
    const char* securityDomain,
    UInt32 accountNameLength,
    const char* accountName,
    UInt32 pathLength,
    const char* path,
    UInt16 port,
    SecProtocolType protocol,
    SecAuthenticationType authenticationType,
    UInt32 passwordLength,
    const void* passwordData,
    SecKeychainItemRef* itemRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainAddInternetPassword(keychain,
                                        serverNameLength, serverName,
                                        securityDomainLength, securityDomain,
                                        accountNameLength, accountName,
                                        pathLength, path,
                                        port, protocol, authenticationType,
                                        passwordLength, passwordData,
                                        itemRef);
}

OSStatus AppleKeychain::FindGenericPassword(CFTypeRef keychainOrArray,
                                            UInt32 serviceNameLength,
                                            const char* serviceName,
                                            UInt32 accountNameLength,
                                            const char* accountName,
                                            UInt32* passwordLength,
                                            void** passwordData,
                                            SecKeychainItemRef* itemRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainFindGenericPassword(keychainOrArray,
                                        serviceNameLength,
                                        serviceName,
                                        accountNameLength,
                                        accountName,
                                        passwordLength,
                                        passwordData,
                                        itemRef);
}

OSStatus AppleKeychain::ItemFreeContent(SecKeychainAttributeList* attrList,
                                        void* data) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainItemFreeContent(attrList, data);
}

OSStatus AppleKeychain::AddGenericPassword(SecKeychainRef keychain,
                                           UInt32 serviceNameLength,
                                           const char* serviceName,
                                           UInt32 accountNameLength,
                                           const char* accountName,
                                           UInt32 passwordLength,
                                           const void* passwordData,
                                           SecKeychainItemRef* itemRef) const {
  base::AutoLock lock(GetMacSecurityServicesLock());
  return SecKeychainAddGenericPassword(keychain,
                                       serviceNameLength,
                                       serviceName,
                                       accountNameLength,
                                       accountName,
                                       passwordLength,
                                       passwordData,
                                       itemRef);
}

void AppleKeychain::Free(CFTypeRef ref) const {
  if (ref)
    CFRelease(ref);
}

}  // namespace crypto
