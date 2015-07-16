// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/display/util/edid_parser.h"

#include <algorithm>

#include "base/hash.h"
#include "base/strings/string_util.h"
#include "base/sys_byteorder.h"

namespace ui {

namespace {

// Returns 64-bit persistent ID for the specified manufacturer's ID and
// product_code_hash, and the index of the output it is connected to.
// |output_index| is used to distinguish the displays of the same type. For
// example, swapping two identical display between two outputs will not be
// treated as swap. The 'serial number' field in EDID isn't used here because
// it is not guaranteed to have unique number and it may have the same fixed
// value (like 0).
int64_t GetID(uint16_t manufacturer_id,
              uint32_t product_code_hash,
              uint8_t output_index) {
  return ((static_cast<int64_t>(manufacturer_id) << 40) |
          (static_cast<int64_t>(product_code_hash) << 8) | output_index);
}

}  // namespace

bool GetDisplayIdFromEDID(const std::vector<uint8_t>& edid,
                          uint8_t output_index,
                          int64_t* display_id_out) {
  uint16_t manufacturer_id = 0;
  std::string product_name;

  // ParseOutputDeviceData fails if it doesn't have product_name.
  ParseOutputDeviceData(edid, &manufacturer_id, &product_name);

  // Generates product specific value from product_name instead of product code.
  // See crbug.com/240341
  uint32_t product_code_hash = product_name.empty() ?
      0 : base::Hash(product_name);
  if (manufacturer_id != 0) {
    // An ID based on display's index will be assigned later if this call
    // fails.
    *display_id_out = GetID(
        manufacturer_id, product_code_hash, output_index);
    return true;
  }
  return false;
}

bool ParseOutputDeviceData(const std::vector<uint8_t>& edid,
                           uint16_t* manufacturer_id,
                           std::string* human_readable_name) {
  // See http://en.wikipedia.org/wiki/Extended_display_identification_data
  // for the details of EDID data format.  We use the following data:
  //   bytes 8-9: manufacturer EISA ID, in big-endian
  //   bytes 54-125: four descriptors (18-bytes each) which may contain
  //     the display name.
  const unsigned int kManufacturerOffset = 8;
  const unsigned int kManufacturerLength = 2;
  const unsigned int kDescriptorOffset = 54;
  const unsigned int kNumDescriptors = 4;
  const unsigned int kDescriptorLength = 18;
  // The specifier types.
  const unsigned char kMonitorNameDescriptor = 0xfc;

  if (manufacturer_id) {
    if (edid.size() < kManufacturerOffset + kManufacturerLength) {
      LOG(ERROR) << "too short EDID data: manifacturer id";
      return false;
    }

    *manufacturer_id =
        *reinterpret_cast<const uint16_t*>(&edid[kManufacturerOffset]);
#if defined(ARCH_CPU_LITTLE_ENDIAN)
    *manufacturer_id = base::ByteSwap(*manufacturer_id);
#endif
  }

  if (!human_readable_name)
    return true;

  human_readable_name->clear();
  for (unsigned int i = 0; i < kNumDescriptors; ++i) {
    if (edid.size() < kDescriptorOffset + (i + 1) * kDescriptorLength)
      break;

    size_t offset = kDescriptorOffset + i * kDescriptorLength;
    // If the descriptor contains the display name, it has the following
    // structure:
    //   bytes 0-2, 4: \0
    //   byte 3: descriptor type, defined above.
    //   bytes 5-17: text data, ending with \r, padding with spaces
    // we should check bytes 0-2 and 4, since it may have other values in
    // case that the descriptor contains other type of data.
    if (edid[offset] == 0 && edid[offset + 1] == 0 && edid[offset + 2] == 0 &&
        edid[offset + 3] == kMonitorNameDescriptor && edid[offset + 4] == 0) {
      std::string found_name(reinterpret_cast<const char*>(&edid[offset + 5]),
                             kDescriptorLength - 5);
      base::TrimWhitespaceASCII(
          found_name, base::TRIM_TRAILING, human_readable_name);
      break;
    }
  }

  // Verify if the |human_readable_name| consists of printable characters only.
  for (size_t i = 0; i < human_readable_name->size(); ++i) {
    char c = (*human_readable_name)[i];
    if (!isascii(c) || !isprint(c)) {
      human_readable_name->clear();
      LOG(ERROR) << "invalid EDID: human unreadable char in name";
      return false;
    }
  }

  return true;
}

bool ParseOutputOverscanFlag(const std::vector<uint8_t>& edid,
                             bool* flag) {
  // See http://en.wikipedia.org/wiki/Extended_display_identification_data
  // for the extension format of EDID.  Also see EIA/CEA-861 spec for
  // the format of the extensions and how video capability is encoded.
  //  - byte 0: tag.  should be 02h.
  //  - byte 1: revision.  only cares revision 3 (03h).
  //  - byte 4-: data block.
  const unsigned int kExtensionBase = 128;
  const unsigned int kExtensionSize = 128;
  const unsigned int kNumExtensionsOffset = 126;
  const unsigned int kDataBlockOffset = 4;
  const unsigned char kCEAExtensionTag = '\x02';
  const unsigned char kExpectedExtensionRevision = '\x03';
  const unsigned char kExtendedTag = 7;
  const unsigned char kExtendedVideoCapabilityTag = 0;
  const unsigned int kPTOverscan = 4;
  const unsigned int kITOverscan = 2;
  const unsigned int kCEOverscan = 0;

  if (edid.size() <= kNumExtensionsOffset)
    return false;

  unsigned char num_extensions = edid[kNumExtensionsOffset];

  for (size_t i = 0; i < num_extensions; ++i) {
    // Skip parsing the whole extension if size is not enough.
    if (edid.size() < kExtensionBase + (i + 1) * kExtensionSize)
      break;

    size_t extension_offset = kExtensionBase + i * kExtensionSize;
    unsigned char tag = edid[extension_offset];
    unsigned char revision = edid[extension_offset + 1];
    if (tag != kCEAExtensionTag || revision != kExpectedExtensionRevision)
      continue;

    unsigned char timing_descriptors_start = std::min(
        edid[extension_offset + 2], static_cast<unsigned char>(kExtensionSize));

    for (size_t data_offset = extension_offset + kDataBlockOffset;
         data_offset < extension_offset + timing_descriptors_start;) {
      // A data block is encoded as:
      // - byte 1 high 3 bits: tag. '07' for extended tags.
      // - byte 1 remaining bits: the length of data block.
      // - byte 2: the extended tag.  '0' for video capability.
      // - byte 3: the capability.
      unsigned char tag = edid[data_offset] >> 5;
      unsigned char payload_length = edid[data_offset] & 0x1f;
      if (data_offset + payload_length > edid.size())
        break;

      if (tag != kExtendedTag || payload_length < 2 ||
          edid[data_offset + 1] != kExtendedVideoCapabilityTag) {
        data_offset += payload_length + 1;
        continue;
      }

      // The difference between preferred, IT, and CE video formats
      // doesn't matter. Sets |flag| to true if any of these flags are true.
      if ((edid[data_offset + 2] & (1 << kPTOverscan)) ||
          (edid[data_offset + 2] & (1 << kITOverscan)) ||
          (edid[data_offset + 2] & (1 << kCEOverscan))) {
        *flag = true;
      } else {
        *flag = false;
      }
      return true;
    }
  }

  return false;
}

}  // namespace ui
