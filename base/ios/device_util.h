// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_IOS_DEVICE_UTIL_H_
#define BASE_IOS_DEVICE_UTIL_H_

#include <string>

namespace ios {
namespace device_util {

// Returns the hardware version of the device the app is running on.
//
// The returned string is the string returned by sysctlbyname() with name
// "hw.machine". Possible (known) values include:
//
// iPhone1,1 -> iPhone 1G
// iPhone1,2 -> iPhone 3G
// iPhone2,1 -> iPhone 3GS
// iPhone3,1 -> iPhone 4/AT&T
// iPhone3,2 -> iPhone 4/Other Carrier?
// iPhone3,3 -> iPhone 4/Other Carrier?
// iPhone4,1 -> iPhone 4S
//
// iPod1,1   -> iPod touch 1G
// iPod2,1   -> iPod touch 2G
// iPod2,2   -> ?
// iPod3,1   -> iPod touch 3G
// iPod4,1   -> iPod touch 4G
// iPod5,1   -> ?
//
// iPad1,1   -> iPad 1G, WiFi
// iPad1,?   -> iPad 1G, 3G <- needs 3G owner to test
// iPad2,1   -> iPad 2G, WiFi
//
// AppleTV2,1 -> AppleTV 2
//
// i386       -> Simulator
// x86_64     -> Simulator
std::string GetPlatform();

// Returns true if the application is running on a device with 512MB or more
// RAM.
bool RamIsAtLeast512Mb();

// Returns true if the application is running on a device with 1024MB or more
// RAM.
bool RamIsAtLeast1024Mb();

// Returns true if the application is running on a device with |ram_in_mb| MB or
// more RAM.
// Use with caution! Actual RAM reported by devices is less than the commonly
// used powers-of-two values. For example, a 512MB device may report only 502MB
// RAM. The convenience methods above should be used in most cases because they
// correctly handle this issue.
bool RamIsAtLeast(uint64_t ram_in_mb);

// Returns true if the device has only one core.
bool IsSingleCoreDevice();

// Returns the MAC address of the interface with name |interface_name|.
std::string GetMacAddress(const std::string& interface_name);

// Returns a random UUID.
std::string GetRandomId();

// Returns an identifier for the device, using the given |salt|. A global
// identifier is generated the first time this method is called, and the salt
// is used to be able to generate distinct identifiers for the same device. If
// |salt| is NULL, a default value is used. Unless you are using this value for
// something that should be anonymous, you should probably pass NULL.
std::string GetDeviceIdentifier(const char* salt);

// Returns a hashed version of |in_string| using |salt| (which must not be
// zero-length). Different salt values should result in differently hashed
// strings.
std::string GetSaltedString(const std::string& in_string,
                            const std::string& salt);

}  // namespace device_util
}  // namespace ios

#endif  // BASE_IOS_DEVICE_UTIL_H_
