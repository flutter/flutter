// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "packer.h"

#include <vector>
#include "elf.h"
#include "elf_traits.h"
#include "gtest/gtest.h"


template <typename ELF>
static void AddRelocation(typename ELF::Addr addr,
                   typename ELF::Xword info,
                   typename ELF::Sxword addend,
                   std::vector<typename ELF::Rela>* relocations) {
  typename ELF::Rela relocation;
  relocation.r_offset = addr;
  relocation.r_info = info;
  relocation.r_addend = addend;

  relocations->push_back(relocation);
}

template <typename ELF>
static bool CheckRelocation(typename ELF::Addr addr,
                     typename ELF::Xword info,
                     typename ELF::Sxword addend,
                     const typename ELF::Rela& relocation) {
  return relocation.r_offset == addr &&
      relocation.r_info == info &&
      relocation.r_addend == addend;
}

namespace relocation_packer {

template <typename ELF>
static void DoPackNoAddend() {
  std::vector<typename ELF::Rela> relocations;
  std::vector<uint8_t> packed;
  bool is_32 = sizeof(typename ELF::Addr) == 4;
  // Initial relocation.
  AddRelocation<ELF>(0xd1ce0000, 0x11, 0, &relocations);
  // Two more relocations, 4 byte deltas.
  AddRelocation<ELF>(0xd1ce0004, 0x11, 0, &relocations);
  AddRelocation<ELF>(0xd1ce0008, 0x11, 0, &relocations);
  // Three more relocations, 8 byte deltas.
  AddRelocation<ELF>(0xd1ce0010, 0x11, 0, &relocations);
  AddRelocation<ELF>(0xd1ce0018, 0x11, 0, &relocations);
  AddRelocation<ELF>(0xd1ce0020, 0x11, 0, &relocations);

  RelocationPacker<ELF> packer;

  packed.clear();
  packer.PackRelocations(relocations, &packed);

  ASSERT_EQ(18U, packed.size());
  // Identifier.
  size_t ndx = 0;
  EXPECT_EQ('A', packed[ndx++]);
  EXPECT_EQ('P', packed[ndx++]);
  EXPECT_EQ('S', packed[ndx++]);
  EXPECT_EQ('2', packed[ndx++]);
  // relocation count
  EXPECT_EQ(6, packed[ndx++]);
  // base relocation = 0xd1cdfffc -> fc, ff, b7, 8e, 7d/0d (32/64bit)
  EXPECT_EQ(0xfc, packed[ndx++]);
  EXPECT_EQ(0xff, packed[ndx++]);
  EXPECT_EQ(0xb7, packed[ndx++]);
  EXPECT_EQ(0x8e, packed[ndx++]);
  EXPECT_EQ(is_32 ? 0x7d : 0x0d, packed[ndx++]);
  // first group
  EXPECT_EQ(3, packed[ndx++]);  // size
  EXPECT_EQ(3, packed[ndx++]); // flags
  EXPECT_EQ(4, packed[ndx++]); // r_offset_delta
  EXPECT_EQ(0x11, packed[ndx++]); // r_info
  // second group
  EXPECT_EQ(3, packed[ndx++]);  // size
  EXPECT_EQ(3, packed[ndx++]); // flags
  EXPECT_EQ(8, packed[ndx++]); // r_offset_delta
  EXPECT_EQ(0x11, packed[ndx++]); // r_info

  EXPECT_EQ(ndx, packed.size());
}

TEST(Packer, PackNoAddend32) {
  DoPackNoAddend<ELF32_traits>();
}

TEST(Packer, PackNoAddend64) {
  DoPackNoAddend<ELF64_traits>();
}

template <typename ELF>
static void DoUnpackNoAddend() {
  std::vector<typename ELF::Rela> relocations;
  std::vector<uint8_t> packed;
  bool is_32 = sizeof(typename ELF::Addr) == 4;
  packed.push_back('A');
  packed.push_back('P');
  packed.push_back('S');
  packed.push_back('2');
  // relocation count
  packed.push_back(6);
  // base relocation = 0xd1cdfffc -> fc, ff, b7, 8e, 7d/0d (32/64bit)
  packed.push_back(0xfc);
  packed.push_back(0xff);
  packed.push_back(0xb7);
  packed.push_back(0x8e);
  packed.push_back(is_32 ? 0x7d : 0x0d);
  // first group
  packed.push_back(3);  // size
  packed.push_back(3); // flags
  packed.push_back(4); // r_offset_delta
  packed.push_back(0x11); // r_info
  // second group
  packed.push_back(3);  // size
  packed.push_back(3); // flags
  packed.push_back(8); // r_offset_delta
  packed.push_back(0x11); // r_info

  RelocationPacker<ELF> packer;
  packer.UnpackRelocations(packed, &relocations);

  size_t ndx = 0;
  EXPECT_EQ(6U, relocations.size());
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0000, 0x11, 0, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0004, 0x11, 0, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0008, 0x11, 0, relocations[ndx++]));

  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0010, 0x11, 0, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0018, 0x11, 0, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0020, 0x11, 0, relocations[ndx++]));

  EXPECT_EQ(ndx, relocations.size());
}

TEST(Packer, UnpackNoAddend32) {
  DoUnpackNoAddend<ELF32_traits>();
}

TEST(Packer, UnpackNoAddend64) {
  DoUnpackNoAddend<ELF64_traits>();
}

template <typename ELF>
static void DoPackWithAddend() {
  std::vector<typename ELF::Rela> relocations;

  // Initial relocation.
  AddRelocation<ELF>(0xd1ce0000, 0x01, 10024, &relocations);
  // Two more relocations, 4 byte offset deltas, 12 byte addend deltas.
  AddRelocation<ELF>(0xd1ce0004, 0x01, 10012, &relocations);
  AddRelocation<ELF>(0xd1ce0008, 0x01, 10024, &relocations);
  // Three more relocations, 8 byte deltas, -24 byte addend deltas.
  AddRelocation<ELF>(0xd1ce0010, 0x01, 10000, &relocations);
  AddRelocation<ELF>(0xd1ce0018, 0x01, 9976, &relocations);
  AddRelocation<ELF>(0xd1ce0020, 0x01, 9952, &relocations);

  std::vector<uint8_t> packed;

  RelocationPacker<ELF> packer;

  packed.clear();
  packer.PackRelocations(relocations, &packed);

  EXPECT_EQ(26U, packed.size());
  size_t ndx = 0;
  // Identifier.
  EXPECT_EQ('A', packed[ndx++]);
  EXPECT_EQ('P', packed[ndx++]);
  EXPECT_EQ('S', packed[ndx++]);
  EXPECT_EQ('2', packed[ndx++]);
  // Relocation count
  EXPECT_EQ(6U, packed[ndx++]);
  // base relocation = 0xd1cdfffc -> fc, ff, b7, 8e, 0d/7d (depending on ELF::Addr)
  EXPECT_EQ(0xfc, packed[ndx++]);
  EXPECT_EQ(0xff, packed[ndx++]);
  EXPECT_EQ(0xb7, packed[ndx++]);
  EXPECT_EQ(0x8e, packed[ndx++]);
  if (sizeof(typename ELF::Addr) == 8) {
    // positive for uint64_t
    EXPECT_EQ(0x0d, packed[ndx++]);
  } else {
    // negative for uint32_t
    EXPECT_EQ(0x7d, packed[ndx++]);
  }
  // group 1
  EXPECT_EQ(0x03, packed[ndx++]); // size
  EXPECT_EQ(0x0b, packed[ndx++]); // flags
  EXPECT_EQ(0x04, packed[ndx++]); // r_offset_delta
  EXPECT_EQ(0x01, packed[ndx++]); // r_info
  // group 1 - addend 1: 10024 = 0xa8, 0xce, 0x80
  EXPECT_EQ(0xa8, packed[ndx++]);
  EXPECT_EQ(0xce, packed[ndx++]);
  EXPECT_EQ(0x00, packed[ndx++]);
  // group 1 - addend 2: -12 = 0x74
  EXPECT_EQ(0x74, packed[ndx++]);
  // group 1 - addend 3: +12 = 0x0c
  EXPECT_EQ(0x0c, packed[ndx++]);

  // group 2
  EXPECT_EQ(0x03, packed[ndx++]); // size
  EXPECT_EQ(0x0b, packed[ndx++]); // flags
  EXPECT_EQ(0x08, packed[ndx++]); // r_offset_delta
  EXPECT_EQ(0x01, packed[ndx++]); // r_info

  // group 2 - addend 1: -24 = 0x68
  EXPECT_EQ(0x68, packed[ndx++]);
  // group 2 - addend 2: -24 = 0x68
  EXPECT_EQ(0x68, packed[ndx++]);
  // group 2 - addend 3: -24 = 0x68
  EXPECT_EQ(0x68, packed[ndx++]);

  EXPECT_EQ(ndx, packed.size());
}

TEST(Packer, PackWithAddend) {
  DoPackWithAddend<ELF32_traits>();
  DoPackWithAddend<ELF64_traits>();
}

template <typename ELF>
static void DoUnpackWithAddend() {
  std::vector<uint8_t> packed;
  // Identifier.
  packed.push_back('A');
  packed.push_back('P');
  packed.push_back('S');
  packed.push_back('2');
  // Relocation count
  packed.push_back(6U);
  // base relocation = 0xd1cdfffc -> fc, ff, b7, 8e, 0d
  packed.push_back(0xfc);
  packed.push_back(0xff);
  packed.push_back(0xb7);
  packed.push_back(0x8e);
  if (sizeof(typename ELF::Addr) == 8) {
    // positive for uint64_t
    packed.push_back(0x0d);
  } else {
    // negative for uint32_t
    packed.push_back(0x7d);
  }
  // group 1
  packed.push_back(0x03); // size
  packed.push_back(0x0b); // flags
  packed.push_back(0x04); // r_offset_delta
  packed.push_back(0x01); // r_info
  // group 1 - addend 1: 10024 = 0xa8, 0xce, 0x80
  packed.push_back(0xa8);
  packed.push_back(0xce);
  packed.push_back(0x00);
  // group 1 - addend 2: -12 = 0x74
  packed.push_back(0x74);
  // group 1 - addend 3: +12 = 0x0c
  packed.push_back(0x0c);

  // group 2
  packed.push_back(0x03); // size
  packed.push_back(0x0b); // flags
  packed.push_back(0x08); // r_offset_delta
  packed.push_back(0x01); // r_info

  // group 2 - addend 1: -24 = 0x68
  packed.push_back(0x68);
  // group 2 - addend 2: -24 = 0x68
  packed.push_back(0x68);
  // group 2 - addend 3: -24 = 0x68
  packed.push_back(0x68);

  std::vector<typename ELF::Rela> relocations;

  RelocationPacker<ELF> packer;

  relocations.clear();
  packer.UnpackRelocations(packed, &relocations);

  EXPECT_EQ(6U, relocations.size());
  size_t ndx = 0;
  // Initial relocation.
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0000, 0x01, 10024, relocations[ndx++]));
  // Two more relocations, 4 byte offset deltas, 12 byte addend deltas.
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0004, 0x01, 10012, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0008, 0x01, 10024, relocations[ndx++]));
  // Three more relocations, 8 byte offset deltas, -24 byte addend deltas.
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0010, 0x01, 10000, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0018, 0x01, 9976, relocations[ndx++]));
  EXPECT_TRUE(CheckRelocation<ELF>(0xd1ce0020, 0x01, 9952, relocations[ndx++]));

  EXPECT_EQ(ndx, relocations.size());
}

TEST(Packer, UnpackWithAddend) {
  DoUnpackWithAddend<ELF32_traits>();
  DoUnpackWithAddend<ELF64_traits>();
}

}  // namespace relocation_packer
