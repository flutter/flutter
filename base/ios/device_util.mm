// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/ios/device_util.h"

#include <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

#include <ifaddrs.h>
#include <net/if_dl.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#include "base/logging.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/sys_string_conversions.h"

namespace {

// Client ID key in the user preferences.
NSString* const kLegacyClientIdPreferenceKey = @"ChromiumClientID";
NSString* const kClientIdPreferenceKey = @"ChromeClientID";
// Current hardware type. This is used to detect that a device has been backed
// up and restored to another device, and allows regenerating a new device id.
NSString* const kHardwareTypePreferenceKey = @"ClientIDGenerationHardwareType";
// Default salt for device ids.
const char kDefaultSalt[] = "Salt";
// Zero UUID returned on buggy iOS devices.
NSString* const kZeroUUID = @"00000000-0000-0000-0000-000000000000";

NSString* GenerateClientId() {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  // Try to migrate from legacy client id.
  NSString* client_id = [defaults stringForKey:kLegacyClientIdPreferenceKey];

  // Some iOS6 devices return a buggy identifierForVendor:
  // http://openradar.appspot.com/12377282. If this is the case, revert to
  // generating a new one.
  if (!client_id || [client_id isEqualToString:kZeroUUID]) {
    client_id = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if ([client_id isEqualToString:kZeroUUID])
      client_id = base::SysUTF8ToNSString(ios::device_util::GetRandomId());
  }
  return client_id;
}

}  // namespace

namespace ios {
namespace device_util {

std::string GetPlatform() {
  std::string platform;
  size_t size = 0;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
  sysctlbyname("hw.machine", WriteInto(&platform, size), &size, NULL, 0);
  return platform;
}

bool RamIsAtLeast512Mb() {
  // 512MB devices report anywhere from 502-504 MB, use 450 MB just to be safe.
  return RamIsAtLeast(450);
}

bool RamIsAtLeast1024Mb() {
  // 1GB devices report anywhere from 975-999 MB, use 900 MB just to be safe.
  return RamIsAtLeast(900);
}

bool RamIsAtLeast(uint64_t ram_in_mb) {
  uint64_t memory_size = 0;
  size_t size = sizeof(memory_size);
  if (sysctlbyname("hw.memsize", &memory_size, &size, NULL, 0) == 0) {
    // Anything >= 500M, call high ram.
    return memory_size >= ram_in_mb * 1024 * 1024;
  }
  return false;
}

bool IsSingleCoreDevice() {
  uint64_t cpu_number = 0;
  size_t sizes = sizeof(cpu_number);
  sysctlbyname("hw.physicalcpu", &cpu_number, &sizes, NULL, 0);
  return cpu_number == 1;
}

std::string GetMacAddress(const std::string& interface_name) {
  std::string mac_string;
  struct ifaddrs* addresses;
  if (getifaddrs(&addresses) == 0) {
    for (struct ifaddrs* address = addresses; address;
         address = address->ifa_next) {
      if ((address->ifa_addr->sa_family == AF_LINK) &&
          strcmp(interface_name.c_str(), address->ifa_name) == 0) {
        const struct sockaddr_dl* found_address_struct =
            reinterpret_cast<const struct sockaddr_dl*>(address->ifa_addr);

        // |found_address_struct->sdl_data| contains the interface name followed
        // by the interface address. The address part can be accessed based on
        // the length of the name, that is, |found_address_struct->sdl_nlen|.
        const unsigned char* found_address =
            reinterpret_cast<const unsigned char*>(
                &found_address_struct->sdl_data[
                    found_address_struct->sdl_nlen]);

        int found_address_length = found_address_struct->sdl_alen;
        for (int i = 0; i < found_address_length; ++i) {
          if (i != 0)
            mac_string.push_back(':');
          base::StringAppendF(&mac_string, "%02X", found_address[i]);
        }
        break;
      }
    }
    freeifaddrs(addresses);
  }
  return mac_string;
}

std::string GetRandomId() {
  base::ScopedCFTypeRef<CFUUIDRef> uuid_object(
      CFUUIDCreate(kCFAllocatorDefault));
  base::ScopedCFTypeRef<CFStringRef> uuid_string(
      CFUUIDCreateString(kCFAllocatorDefault, uuid_object));
  return base::SysCFStringRefToUTF8(uuid_string);
}

std::string GetDeviceIdentifier(const char* salt) {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  NSString* last_seen_hardware =
      [defaults stringForKey:kHardwareTypePreferenceKey];
  NSString* current_hardware = base::SysUTF8ToNSString(GetPlatform());
  if (!last_seen_hardware) {
    last_seen_hardware = current_hardware;
    [defaults setObject:current_hardware forKey:kHardwareTypePreferenceKey];
    [defaults synchronize];
  }

  NSString* client_id = [defaults stringForKey:kClientIdPreferenceKey];

  if (!client_id || ![last_seen_hardware isEqualToString:current_hardware]) {
    client_id = GenerateClientId();
    [defaults setObject:client_id forKey:kClientIdPreferenceKey];
    [defaults setObject:current_hardware forKey:kHardwareTypePreferenceKey];
    [defaults synchronize];
  }

  return GetSaltedString(base::SysNSStringToUTF8(client_id),
                         salt ? salt : kDefaultSalt);
}

std::string GetSaltedString(const std::string& in_string,
                            const std::string& salt) {
  DCHECK(salt.length());
  NSData* hash_data = [base::SysUTF8ToNSString(in_string + salt)
      dataUsingEncoding:NSUTF8StringEncoding];

  unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256([hash_data bytes], [hash_data length], hash);
  CFUUIDBytes* uuid_bytes = reinterpret_cast<CFUUIDBytes*>(hash);

  base::ScopedCFTypeRef<CFUUIDRef> uuid_object(
      CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, *uuid_bytes));
  base::ScopedCFTypeRef<CFStringRef> device_id(
      CFUUIDCreateString(kCFAllocatorDefault, uuid_object));
  return base::SysCFStringRefToUTF8(device_id);
}

}  // namespace device_util
}  // namespace ios
