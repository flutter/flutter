// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "delta_encoder.h"

#include <vector>
#include "elf.h"
#include "gtest/gtest.h"

namespace {

template <typename T>
void AddRelocation(uint32_t addr,
                   uint32_t info,
                   int32_t addend,
                   std::vector<T>* relocations) {
  T relocation;
  relocation.r_offset = addr;
  relocation.r_info = info;
  relocation.r_addend = addend;
  relocations->push_back(relocation);
}

template <typename T>
bool CheckRelocation(uint32_t addr,
                     uint32_t info,
                     int32_t addend,
                     const T& relocation) {
  return relocation.r_offset == addr &&
      relocation.r_info == info &&
      relocation.r_addend == addend;
}

}  // namespace

namespace relocation_packer {

template <typename ELF>
static void encode() {
  std::vector<typename ELF::Rela> relocations;
  std::vector<typename ELF::Addr> packed;

  RelocationDeltaCodec<ELF> codec;

  codec.Encode(relocations, &packed);

  ASSERT_EQ(0U, packed.size());

  // Initial relocation.
  AddRelocation(0xf00d0000, 11U, 10000, &relocations);

  codec.Encode(relocations, &packed);

  // size of reloc table, size of group, flags, 3 fields, zero
  EXPECT_EQ(7U, packed.size());
  // One pair present.
  size_t ndx = 0;
  EXPECT_EQ(1U, packed[ndx++]);
  EXPECT_EQ(0xf00d0000, packed[ndx++]);
  EXPECT_EQ(1U, packed[ndx++]); // group_size
  EXPECT_EQ(8U, packed[ndx++]); // flags
  // Delta from the neutral element is zero
  EXPECT_EQ(0U, packed[ndx++]); // offset_delta
  EXPECT_EQ(11U, packed[ndx++]); // info
  EXPECT_EQ(10000U, packed[ndx++]); // addend_delta

  // Add a second relocation, 4 byte offset delta, 12 byte addend delta.
  // same info
  AddRelocation(0xf00d0004, 11U, 10012, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  ndx = 0;
  EXPECT_EQ(8U, packed.size());

  EXPECT_EQ(2U, packed[ndx++]); // relocs count
  EXPECT_EQ(0xf00cfffc, packed[ndx++]); // initial offset
  EXPECT_EQ(2U, packed[ndx++]); // group count
  EXPECT_EQ(11U, packed[ndx++]); // flags
  EXPECT_EQ(4U, packed[ndx++]); // group offset delta
  EXPECT_EQ(11U, packed[ndx++]); // info

  EXPECT_EQ(10000U, packed[ndx++]); // addend delta
  EXPECT_EQ(12U, packed[ndx++]); // addend delta

  // Add a third relocation, 4 byte offset delta, 12 byte addend delta.
  // different info
  AddRelocation(0xf00d0008, 41U, 10024, &relocations);

  // Add three more relocations, 8 byte offset deltas, -24 byte addend deltas.
  AddRelocation(0xf00d0010, 42U, 10000, &relocations);
  AddRelocation(0xf00d0018, 42U, 9976, &relocations);
  AddRelocation(0xf00d0020, 42U, 9952, &relocations);

  AddRelocation(0xf00d2028, 1042U, 0, &relocations);
  AddRelocation(0xf00d2030, 3442U, 0, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  ndx = 0;
  EXPECT_EQ(26U, packed.size());
  // Total number of relocs
  EXPECT_EQ(8U, packed[ndx++]);
  EXPECT_EQ(0xf00cfffc, packed[ndx++]);
  // 2 in first group
  EXPECT_EQ(2U, packed[ndx++]);
  EXPECT_EQ(11U, packed[ndx++]); //flags
  EXPECT_EQ(4U, packed[ndx++]); // group offset delta
  EXPECT_EQ(11U, packed[ndx++]); // info

  // Initial relocation.
  EXPECT_EQ(10000U, packed[ndx++]); // addend delta
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  EXPECT_EQ(12U, packed[ndx++]); // addend delta

  // second group has only one reloc
  EXPECT_EQ(1U, packed[ndx++]); // count
  EXPECT_EQ(8U, packed[ndx++]); // flags

  EXPECT_EQ(4U, packed[ndx++]); // offset delta
  EXPECT_EQ(41U, packed[ndx++]); // info
  EXPECT_EQ(12U, packed[ndx++]); // addend delta

  // next - 3 relocs grouped by info
  EXPECT_EQ(3U, packed[ndx++]); // count
  EXPECT_EQ(11U, packed[ndx++]); // flags
  EXPECT_EQ(8U, packed[ndx++]); // group offset delta
  EXPECT_EQ(42U, packed[ndx++]); // info
  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  EXPECT_EQ(static_cast<typename ELF::Addr>(-24), packed[ndx++]);
  EXPECT_EQ(static_cast<typename ELF::Addr>(-24), packed[ndx++]);
  EXPECT_EQ(static_cast<typename ELF::Addr>(-24), packed[ndx++]);

  // and last - 2 relocations without addend
  EXPECT_EQ(2U, packed[ndx++]);
  EXPECT_EQ(0U, packed[ndx++]); // flags
  // offset_deltas and r_infos for next 2 relocations
  EXPECT_EQ(0x2008U, packed[ndx++]); // offset delta
  EXPECT_EQ(1042U, packed[ndx++]); // r_info
  EXPECT_EQ(0x8U, packed[ndx++]); // offset delta
  EXPECT_EQ(3442U, packed[ndx++]); // r_info

  EXPECT_EQ(packed.size(), ndx);
}

TEST(Delta, Encode32) {
  encode<ELF32_traits>();
}

TEST(Delta, Encode64) {
  encode<ELF64_traits>();
}

template <typename ELF>
static void decode() {
  std::vector<typename ELF::Addr> packed;
  std::vector<typename ELF::Rela> relocations;

  RelocationDeltaCodec<ELF> codec;
  codec.Decode(packed, &relocations);

  EXPECT_EQ(0U, relocations.size());

  // Six pairs.
  packed.push_back(6U); // count
  packed.push_back(0xc0ddfffc); // base offset
  packed.push_back(3U); // group count
  packed.push_back(11U); // flags
  packed.push_back(4U); // offset delta
  packed.push_back(11U); // info
  // Initial relocation.
  packed.push_back(10000U);
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  packed.push_back(12U); // addend
  packed.push_back(12U); // addend

  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  packed.push_back(1U); // group count
  packed.push_back(9U); // flags
  packed.push_back(11U); // info

  packed.push_back(8U);
  packed.push_back(static_cast<typename ELF::Addr>(-24));
  // next group with 2 relocs
  packed.push_back(2U); // group count
  packed.push_back(11U); // flags
  packed.push_back(8U); // offset
  packed.push_back(42U); // info

  packed.push_back(static_cast<typename ELF::Addr>(-24)); // addend
  packed.push_back(static_cast<typename ELF::Addr>(-24)); // addend

  relocations.clear();
  codec.Decode(packed, &relocations);

  EXPECT_EQ(6U, relocations.size());
  // Initial relocation.
  EXPECT_TRUE(CheckRelocation(0xc0de0000, 11U, 10000, relocations[0]));
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0004, 11U, 10012, relocations[1]));
  EXPECT_TRUE(CheckRelocation(0xc0de0008, 11U, 10024, relocations[2]));
  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0010, 11U, 10000, relocations[3]));
  EXPECT_TRUE(CheckRelocation(0xc0de0018, 42U, 9976, relocations[4]));
  EXPECT_TRUE(CheckRelocation(0xc0de0020, 42U, 9952, relocations[5]));
}

TEST(Delta, Decode32) {
  decode<ELF32_traits>();
}

TEST(Delta, Decode64) {
  decode<ELF64_traits>();
}

// TODO (dimitry): add more tests (fix by 19 January 2038 03:14:07 UTC)
// TODO (dimtiry): 1. Incorrect packed array for decode
// TODO (dimtiry): 2. Try to catch situation where it is likely to get series of groups with size 1

}  // namespace relocation_packer
