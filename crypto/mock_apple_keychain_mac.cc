// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/time/time.h"
#include "crypto/mock_apple_keychain.h"

namespace crypto {

// static
const SecKeychainSearchRef MockAppleKeychain::kDummySearchRef =
    reinterpret_cast<SecKeychainSearchRef>(1000);

MockAppleKeychain::MockAppleKeychain()
    : locked_(false),
      next_item_key_(0),
      search_copy_count_(0),
      keychain_item_copy_count_(0),
      attribute_data_copy_count_(0),
      find_generic_result_(noErr),
      called_add_generic_(false),
      password_data_count_(0) {}

void MockAppleKeychain::InitializeKeychainData(MockKeychainItemType key) const {
  UInt32 tags[] = { kSecAccountItemAttr,
                    kSecServerItemAttr,
                    kSecPortItemAttr,
                    kSecPathItemAttr,
                    kSecProtocolItemAttr,
                    kSecAuthenticationTypeItemAttr,
                    kSecSecurityDomainItemAttr,
                    kSecCreationDateItemAttr,
                    kSecNegativeItemAttr,
                    kSecCreatorItemAttr };
  keychain_attr_list_[key] = SecKeychainAttributeList();
  keychain_data_[key] = KeychainPasswordData();
  keychain_attr_list_[key].count = arraysize(tags);
  keychain_attr_list_[key].attr = static_cast<SecKeychainAttribute*>(
      calloc(keychain_attr_list_[key].count, sizeof(SecKeychainAttribute)));
  for (unsigned int i = 0; i < keychain_attr_list_[key].count; ++i) {
    keychain_attr_list_[key].attr[i].tag = tags[i];
    size_t data_size = 0;
    switch (tags[i]) {
      case kSecPortItemAttr:
        data_size = sizeof(UInt32);
        break;
      case kSecProtocolItemAttr:
        data_size = sizeof(SecProtocolType);
        break;
      case kSecAuthenticationTypeItemAttr:
        data_size = sizeof(SecAuthenticationType);
        break;
      case kSecNegativeItemAttr:
        data_size = sizeof(Boolean);
        break;
      case kSecCreatorItemAttr:
        data_size = sizeof(OSType);
        break;
    }
    if (data_size > 0) {
      keychain_attr_list_[key].attr[i].length = data_size;
      keychain_attr_list_[key].attr[i].data = calloc(1, data_size);
    }
  }
}

MockAppleKeychain::~MockAppleKeychain() {
  for (MockKeychainAttributesMap::iterator it = keychain_attr_list_.begin();
       it != keychain_attr_list_.end();
       ++it) {
    for (unsigned int i = 0; i < it->second.count; ++i) {
      if (it->second.attr[i].data)
        free(it->second.attr[i].data);
    }
    free(it->second.attr);
    if (keychain_data_[it->first].data)
      free(keychain_data_[it->first].data);
  }
  keychain_attr_list_.clear();
  keychain_data_.clear();
}

SecKeychainAttribute* MockAppleKeychain::AttributeWithTag(
    const SecKeychainAttributeList& attribute_list,
    UInt32 tag) {
  int attribute_index = -1;
  for (unsigned int i = 0; i < attribute_list.count; ++i) {
    if (attribute_list.attr[i].tag == tag) {
      attribute_index = i;
      break;
    }
  }
  if (attribute_index == -1) {
    NOTREACHED() << "Unsupported attribute: " << tag;
    return NULL;
  }
  return &(attribute_list.attr[attribute_index]);
}

void MockAppleKeychain::SetTestDataBytes(MockKeychainItemType item,
                                         UInt32 tag,
                                         const void* data,
                                         size_t length) {
  SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[item],
                                                     tag);
  attribute->length = length;
  if (length > 0) {
    if (attribute->data)
      free(attribute->data);
    attribute->data = malloc(length);
    CHECK(attribute->data);
    memcpy(attribute->data, data, length);
  } else {
    attribute->data = NULL;
  }
}

void MockAppleKeychain::SetTestDataString(MockKeychainItemType item,
                                          UInt32 tag,
                                          const char* value) {
  SetTestDataBytes(item, tag, value, value ? strlen(value) : 0);
}

void MockAppleKeychain::SetTestDataPort(MockKeychainItemType item,
                                        UInt32 value) {
  SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[item],
                                                     kSecPortItemAttr);
  UInt32* data = static_cast<UInt32*>(attribute->data);
  *data = value;
}

void MockAppleKeychain::SetTestDataProtocol(MockKeychainItemType item,
                                            SecProtocolType value) {
  SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[item],
                                                     kSecProtocolItemAttr);
  SecProtocolType* data = static_cast<SecProtocolType*>(attribute->data);
  *data = value;
}

void MockAppleKeychain::SetTestDataAuthType(MockKeychainItemType item,
                                            SecAuthenticationType value) {
  SecKeychainAttribute* attribute = AttributeWithTag(
      keychain_attr_list_[item], kSecAuthenticationTypeItemAttr);
  SecAuthenticationType* data = static_cast<SecAuthenticationType*>(
      attribute->data);
  *data = value;
}

void MockAppleKeychain::SetTestDataNegativeItem(MockKeychainItemType item,
                                                Boolean value) {
  SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[item],
                                                     kSecNegativeItemAttr);
  Boolean* data = static_cast<Boolean*>(attribute->data);
  *data = value;
}

void MockAppleKeychain::SetTestDataCreator(MockKeychainItemType item,
                                           OSType value) {
  SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[item],
                                                     kSecCreatorItemAttr);
  OSType* data = static_cast<OSType*>(attribute->data);
  *data = value;
}

void MockAppleKeychain::SetTestDataPasswordBytes(MockKeychainItemType item,
                                                 const void* data,
                                                 size_t length) {
  keychain_data_[item].length = length;
  if (length > 0) {
    if (keychain_data_[item].data)
      free(keychain_data_[item].data);
    keychain_data_[item].data = malloc(length);
    memcpy(keychain_data_[item].data, data, length);
  } else {
    keychain_data_[item].data = NULL;
  }
}

void MockAppleKeychain::SetTestDataPasswordString(MockKeychainItemType item,
                                                  const char* value) {
  SetTestDataPasswordBytes(item, value, value ? strlen(value) : 0);
}

OSStatus MockAppleKeychain::ItemCopyAttributesAndData(
    SecKeychainItemRef itemRef,
    SecKeychainAttributeInfo* info,
    SecItemClass* itemClass,
    SecKeychainAttributeList** attrList,
    UInt32* length,
    void** outData) const {
  DCHECK(itemRef);
  MockKeychainItemType key =
      reinterpret_cast<MockKeychainItemType>(itemRef) - 1;
  if (keychain_attr_list_.find(key) == keychain_attr_list_.end())
    return errSecInvalidItemRef;

  DCHECK(!itemClass);  // itemClass not implemented in the Mock.
  if (locked_ && outData)
    return errSecAuthFailed;

  if (attrList)
    *attrList  = &(keychain_attr_list_[key]);
  if (outData) {
    *outData = keychain_data_[key].data;
    DCHECK(length);
    *length = keychain_data_[key].length;
  }

  ++attribute_data_copy_count_;
  return noErr;
}

OSStatus MockAppleKeychain::ItemModifyAttributesAndData(
    SecKeychainItemRef itemRef,
    const SecKeychainAttributeList* attrList,
    UInt32 length,
    const void* data) const {
  DCHECK(itemRef);
  if (locked_)
    return errSecAuthFailed;
  const char* fail_trigger = "fail_me";
  if (length == strlen(fail_trigger) &&
      memcmp(data, fail_trigger, length) == 0) {
    return errSecAuthFailed;
  }

  MockKeychainItemType key =
      reinterpret_cast<MockKeychainItemType>(itemRef) - 1;
  if (keychain_attr_list_.find(key) == keychain_attr_list_.end())
    return errSecInvalidItemRef;

  MockAppleKeychain* mutable_this = const_cast<MockAppleKeychain*>(this);
  if (attrList) {
    for (UInt32 change_attr = 0; change_attr < attrList->count; ++change_attr) {
      if (attrList->attr[change_attr].tag == kSecCreatorItemAttr) {
        void* data = attrList->attr[change_attr].data;
        mutable_this->SetTestDataCreator(key, *(static_cast<OSType*>(data)));
      } else {
        NOTIMPLEMENTED();
      }
    }
  }
  if (data)
    mutable_this->SetTestDataPasswordBytes(key, data, length);
  return noErr;
}

OSStatus MockAppleKeychain::ItemFreeAttributesAndData(
    SecKeychainAttributeList* attrList,
    void* data) const {
  --attribute_data_copy_count_;
  return noErr;
}

OSStatus MockAppleKeychain::ItemDelete(SecKeychainItemRef itemRef) const {
  if (locked_)
    return errSecAuthFailed;
  MockKeychainItemType key =
      reinterpret_cast<MockKeychainItemType>(itemRef) - 1;

  for (unsigned int i = 0; i < keychain_attr_list_[key].count; ++i) {
    if (keychain_attr_list_[key].attr[i].data)
      free(keychain_attr_list_[key].attr[i].data);
  }
  free(keychain_attr_list_[key].attr);
  if (keychain_data_[key].data)
    free(keychain_data_[key].data);

  keychain_attr_list_.erase(key);
  keychain_data_.erase(key);
  added_via_api_.erase(key);
  return noErr;
}

OSStatus MockAppleKeychain::SearchCreateFromAttributes(
    CFTypeRef keychainOrArray,
    SecItemClass itemClass,
    const SecKeychainAttributeList* attrList,
    SecKeychainSearchRef* searchRef) const {
  // Figure out which of our mock items matches, and set up the array we'll use
  // to generate results out of SearchCopyNext.
  remaining_search_results_.clear();
  for (MockKeychainAttributesMap::const_iterator it =
           keychain_attr_list_.begin();
       it != keychain_attr_list_.end();
       ++it) {
    bool mock_item_matches = true;
    for (UInt32 search_attr = 0; search_attr < attrList->count; ++search_attr) {
      SecKeychainAttribute* mock_attribute =
          AttributeWithTag(it->second, attrList->attr[search_attr].tag);
      if (mock_attribute->length != attrList->attr[search_attr].length ||
          memcmp(mock_attribute->data, attrList->attr[search_attr].data,
                 attrList->attr[search_attr].length) != 0) {
        mock_item_matches = false;
        break;
      }
    }
    if (mock_item_matches)
      remaining_search_results_.push_back(it->first);
  }

  DCHECK(searchRef);
  *searchRef = kDummySearchRef;
  ++search_copy_count_;
  return noErr;
}

bool MockAppleKeychain::AlreadyContainsInternetPassword(
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
    SecAuthenticationType authenticationType) const {
  for (MockKeychainAttributesMap::const_iterator it =
           keychain_attr_list_.begin();
       it != keychain_attr_list_.end();
       ++it) {
    SecKeychainAttribute* attribute;
    attribute = AttributeWithTag(it->second, kSecServerItemAttr);
    if ((attribute->length != serverNameLength) ||
        (attribute->data == NULL && *serverName != '\0') ||
        (attribute->data != NULL && *serverName == '\0') ||
        strncmp(serverName,
                (const char*) attribute->data,
                serverNameLength) != 0) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecSecurityDomainItemAttr);
    if ((attribute->length != securityDomainLength) ||
        (attribute->data == NULL && *securityDomain != '\0') ||
        (attribute->data != NULL && *securityDomain == '\0') ||
        strncmp(securityDomain,
                (const char*) attribute->data,
                securityDomainLength) != 0) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecAccountItemAttr);
    if ((attribute->length != accountNameLength) ||
        (attribute->data == NULL && *accountName != '\0') ||
        (attribute->data != NULL && *accountName == '\0') ||
        strncmp(accountName,
                (const char*) attribute->data,
                accountNameLength) != 0) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecPathItemAttr);
    if ((attribute->length != pathLength) ||
        (attribute->data == NULL && *path != '\0') ||
        (attribute->data != NULL && *path == '\0') ||
        strncmp(path,
                (const char*) attribute->data,
                pathLength) != 0) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecPortItemAttr);
    if ((attribute->data == NULL) ||
        (port != *(static_cast<UInt32*>(attribute->data)))) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecProtocolItemAttr);
    if ((attribute->data == NULL) ||
        (protocol != *(static_cast<SecProtocolType*>(attribute->data)))) {
      continue;
    }
    attribute = AttributeWithTag(it->second, kSecAuthenticationTypeItemAttr);
    if ((attribute->data == NULL) ||
        (authenticationType !=
            *(static_cast<SecAuthenticationType*>(attribute->data)))) {
      continue;
    }
    // The keychain already has this item, since all fields other than the
    // password match.
    return true;
  }
  return false;
}

OSStatus MockAppleKeychain::AddInternetPassword(
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
  if (locked_)
    return errSecAuthFailed;

  // Check for the magic duplicate item trigger.
  if (strcmp(serverName, "some.domain.com") == 0)
    return errSecDuplicateItem;

  // If the account already exists in the keychain, we don't add it.
  if (AlreadyContainsInternetPassword(serverNameLength, serverName,
                                      securityDomainLength, securityDomain,
                                      accountNameLength, accountName,
                                      pathLength, path,
                                      port, protocol,
                                      authenticationType)) {
    return errSecDuplicateItem;
  }

  // Pick the next unused slot.
  MockKeychainItemType key = next_item_key_++;

  // Initialize keychain data storage at the target location.
  InitializeKeychainData(key);

  MockAppleKeychain* mutable_this = const_cast<MockAppleKeychain*>(this);
  mutable_this->SetTestDataBytes(key, kSecServerItemAttr, serverName,
                                 serverNameLength);
  mutable_this->SetTestDataBytes(key, kSecSecurityDomainItemAttr,
                                 securityDomain, securityDomainLength);
  mutable_this->SetTestDataBytes(key, kSecAccountItemAttr, accountName,
                                 accountNameLength);
  mutable_this->SetTestDataBytes(key, kSecPathItemAttr, path, pathLength);
  mutable_this->SetTestDataPort(key, port);
  mutable_this->SetTestDataProtocol(key, protocol);
  mutable_this->SetTestDataAuthType(key, authenticationType);
  mutable_this->SetTestDataPasswordBytes(key, passwordData,
                                         passwordLength);
  base::Time::Exploded exploded_time;
  base::Time::Now().UTCExplode(&exploded_time);
  char time_string[128];
  snprintf(time_string, sizeof(time_string), "%04d%02d%02d%02d%02d%02dZ",
           exploded_time.year, exploded_time.month, exploded_time.day_of_month,
           exploded_time.hour, exploded_time.minute, exploded_time.second);
  mutable_this->SetTestDataString(key, kSecCreationDateItemAttr, time_string);

  added_via_api_.insert(key);

  if (itemRef) {
    *itemRef = reinterpret_cast<SecKeychainItemRef>(key + 1);
    ++keychain_item_copy_count_;
  }
  return noErr;
}

OSStatus MockAppleKeychain::SearchCopyNext(SecKeychainSearchRef searchRef,
                                           SecKeychainItemRef* itemRef) const {
  if (remaining_search_results_.empty())
    return errSecItemNotFound;
  MockKeychainItemType key = remaining_search_results_.front();
  remaining_search_results_.erase(remaining_search_results_.begin());
  *itemRef = reinterpret_cast<SecKeychainItemRef>(key + 1);
  ++keychain_item_copy_count_;
  return noErr;
}

void MockAppleKeychain::Free(CFTypeRef ref) const {
  if (!ref)
    return;

  if (ref == kDummySearchRef) {
    --search_copy_count_;
  } else {
    --keychain_item_copy_count_;
  }
}

int MockAppleKeychain::UnfreedSearchCount() const {
  return search_copy_count_;
}

int MockAppleKeychain::UnfreedKeychainItemCount() const {
  return keychain_item_copy_count_;
}

int MockAppleKeychain::UnfreedAttributeDataCount() const {
  return attribute_data_copy_count_;
}

bool MockAppleKeychain::CreatorCodesSetForAddedItems() const {
  for (std::set<MockKeychainItemType>::const_iterator
           i = added_via_api_.begin();
       i != added_via_api_.end();
       ++i) {
    SecKeychainAttribute* attribute = AttributeWithTag(keychain_attr_list_[*i],
                                                       kSecCreatorItemAttr);
    OSType* data = static_cast<OSType*>(attribute->data);
    if (*data == 0)
      return false;
  }
  return true;
}

void MockAppleKeychain::AddTestItem(const KeychainTestData& item_data) {
  MockKeychainItemType key = next_item_key_++;

  InitializeKeychainData(key);
  SetTestDataAuthType(key, item_data.auth_type);
  SetTestDataString(key, kSecServerItemAttr, item_data.server);
  SetTestDataProtocol(key, item_data.protocol);
  SetTestDataString(key, kSecPathItemAttr, item_data.path);
  SetTestDataPort(key, item_data.port);
  SetTestDataString(key, kSecSecurityDomainItemAttr,
                    item_data.security_domain);
  SetTestDataString(key, kSecCreationDateItemAttr, item_data.creation_date);
  SetTestDataString(key, kSecAccountItemAttr, item_data.username);
  SetTestDataPasswordString(key, item_data.password);
  SetTestDataNegativeItem(key, item_data.negative_item);
}

}  // namespace crypto
