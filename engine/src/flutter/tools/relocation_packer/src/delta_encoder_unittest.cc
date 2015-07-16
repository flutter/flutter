// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "delta_encoder.h"

#include <vector>
#include "elf.h"
#include "elf_traits.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

void AddRelocation(ELF::Addr addr,
                   ELF::Sxword addend,
                   std::vector<ELF::Rela>* relocations) {
  ELF::Rela relocation;
  relocation.r_offset = addr;
  relocation.r_info = ELF_R_INFO(0, ELF::kRelativeRelocationCode);
  relocation.r_addend = addend;
  relocations->push_back(relocation);
}

bool CheckRelocation(ELF::Addr addr,
                     ELF::Sxword addend,
                     const ELF::Rela& relocation) {
  return relocation.r_offset == addr &&
      ELF_R_SYM(relocation.r_info) == 0 &&
      ELF_R_TYPE(relocation.r_info) == ELF::kRelativeRelocationCode &&
      relocation.r_addend == addend;
}

}  // namespace

namespace relocation_packer {

TEST(Delta, Encode) {
  std::vector<ELF::Rela> relocations;
  std::vector<ELF::Sxword> packed;

  RelocationDeltaCodec codec;

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(0, packed.size());

  // Initial relocation.
  AddRelocation(0xf00d0000, 10000, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(3, packed.size());
  // One pair present.
  EXPECT_EQ(1, packed[0]);
  // Delta from the neutral element is the initial relocation.
  EXPECT_EQ(0xf00d0000, packed[1]);
  EXPECT_EQ(10000, packed[2]);

  // Add a second relocation, 4 byte offset delta, 12 byte addend delta.
  AddRelocation(0xf00d0004, 10012, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(5, packed.size());
  // Two pairs present.
  EXPECT_EQ(2, packed[0]);
  // Delta from the neutral element is the initial relocation.
  EXPECT_EQ(0xf00d0000, packed[1]);
  EXPECT_EQ(10000, packed[2]);
  // 4 byte offset delta, 12 byte addend delta.
  EXPECT_EQ(4, packed[3]);
  EXPECT_EQ(12, packed[4]);

  // Add a third relocation, 4 byte offset delta, 12 byte addend delta.
  AddRelocation(0xf00d0008, 10024, &relocations);

  // Add three more relocations, 8 byte offset deltas, -24 byte addend deltas.
  AddRelocation(0xf00d0010, 10000, &relocations);
  AddRelocation(0xf00d0018, 9976, &relocations);
  AddRelocation(0xf00d0020, 9952, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(13, packed.size());
  // Six pairs present.
  EXPECT_EQ(6, packed[0]);
  // Initial relocation.
  EXPECT_EQ(0xf00d0000, packed[1]);
  EXPECT_EQ(10000, packed[2]);
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  EXPECT_EQ(4, packed[3]);
  EXPECT_EQ(12, packed[4]);
  EXPECT_EQ(4, packed[5]);
  EXPECT_EQ(12, packed[6]);
  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  EXPECT_EQ(8, packed[7]);
  EXPECT_EQ(-24, packed[8]);
  EXPECT_EQ(8, packed[9]);
  EXPECT_EQ(-24, packed[10]);
  EXPECT_EQ(8, packed[11]);
  EXPECT_EQ(-24, packed[12]);
}

TEST(Delta, Decode) {
  std::vector<ELF::Sxword> packed;
  std::vector<ELF::Rela> relocations;

  RelocationDeltaCodec codec;
  codec.Decode(packed, &relocations);

  EXPECT_EQ(0, relocations.size());

  // Six pairs.
  packed.push_back(6);
  // Initial relocation.
  packed.push_back(0xc0de0000);
  packed.push_back(10000);
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  packed.push_back(4);
  packed.push_back(12);
  packed.push_back(4);
  packed.push_back(12);
  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  packed.push_back(8);
  packed.push_back(-24);
  packed.push_back(8);
  packed.push_back(-24);
  packed.push_back(8);
  packed.push_back(-24);

  relocations.clear();
  codec.Decode(packed, &relocations);

  EXPECT_EQ(6, relocations.size());
  // Initial relocation.
  EXPECT_TRUE(CheckRelocation(0xc0de0000, 10000, relocations[0]));
  // Two relocations, 4 byte offset deltas, 12 byte addend deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0004, 10012, relocations[1]));
  EXPECT_TRUE(CheckRelocation(0xc0de0008, 10024, relocations[2]));
  // Three relocations, 8 byte offset deltas, -24 byte addend deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0010, 10000, relocations[3]));
  EXPECT_TRUE(CheckRelocation(0xc0de0018, 9976, relocations[4]));
  EXPECT_TRUE(CheckRelocation(0xc0de0020, 9952, relocations[5]));
}

}  // namespace relocation_packer
