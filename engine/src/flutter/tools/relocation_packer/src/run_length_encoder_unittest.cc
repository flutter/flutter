// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "run_length_encoder.h"

#include <vector>
#include "elf.h"
#include "elf_traits.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

void AddRelocation(ELF::Addr addr, std::vector<ELF::Rel>* relocations) {
  ELF::Rel relocation;
  relocation.r_offset = addr;
  relocation.r_info = ELF_R_INFO(0, ELF::kRelativeRelocationCode);
  relocations->push_back(relocation);
}

bool CheckRelocation(ELF::Addr addr, const ELF::Rel& relocation) {
  return relocation.r_offset == addr &&
      ELF_R_SYM(relocation.r_info) == 0 &&
      ELF_R_TYPE(relocation.r_info) == ELF::kRelativeRelocationCode;
}

}  // namespace

namespace relocation_packer {

TEST(RunLength, Encode) {
  std::vector<ELF::Rel> relocations;
  std::vector<ELF::Xword> packed;

  RelocationRunLengthCodec codec;

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(0, packed.size());

  // Add one relocation (insufficient data to encode).
  AddRelocation(0xf00d0000, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(0, packed.size());

  // Add a second relocation, 4 byte delta (minimum data to encode).
  AddRelocation(0xf00d0004, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(4, packed.size());
  // One count-delta pair present.
  EXPECT_EQ(1, packed[0]);
  // Initial relocation.
  EXPECT_EQ(0xf00d0000, packed[1]);
  // Run of a single relocation, 4 byte delta.
  EXPECT_EQ(1, packed[2]);
  EXPECT_EQ(4, packed[3]);

  // Add a third relocation, 4 byte delta.
  AddRelocation(0xf00d0008, &relocations);

  // Add three more relocations, 8 byte deltas.
  AddRelocation(0xf00d0010, &relocations);
  AddRelocation(0xf00d0018, &relocations);
  AddRelocation(0xf00d0020, &relocations);

  packed.clear();
  codec.Encode(relocations, &packed);

  EXPECT_EQ(6, packed.size());
  // Two count-delta pairs present.
  EXPECT_EQ(2, packed[0]);
  // Initial relocation.
  EXPECT_EQ(0xf00d0000, packed[1]);
  // Run of two relocations, 4 byte deltas.
  EXPECT_EQ(2, packed[2]);
  EXPECT_EQ(4, packed[3]);
  // Run of three relocations, 8 byte deltas.
  EXPECT_EQ(3, packed[4]);
  EXPECT_EQ(8, packed[5]);
}

TEST(RunLength, Decode) {
  std::vector<ELF::Xword> packed;
  std::vector<ELF::Rel> relocations;

  RelocationRunLengthCodec codec;
  codec.Decode(packed, &relocations);

  EXPECT_EQ(0, relocations.size());

  // Two count-delta pairs.
  packed.push_back(2);
  // Initial relocation.
  packed.push_back(0xc0de0000);
  // Run of two relocations, 4 byte deltas.
  packed.push_back(2);
  packed.push_back(4);
  // Run of three relocations, 8 byte deltas.
  packed.push_back(3);
  packed.push_back(8);

  relocations.clear();
  codec.Decode(packed, &relocations);

  EXPECT_EQ(6, relocations.size());
  // Initial relocation.
  EXPECT_TRUE(CheckRelocation(0xc0de0000, relocations[0]));
  // Two relocations, 4 byte deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0004, relocations[1]));
  EXPECT_TRUE(CheckRelocation(0xc0de0008, relocations[2]));
  // Three relocations, 8 byte deltas.
  EXPECT_TRUE(CheckRelocation(0xc0de0010, relocations[3]));
  EXPECT_TRUE(CheckRelocation(0xc0de0018, relocations[4]));
  EXPECT_TRUE(CheckRelocation(0xc0de0020, relocations[5]));
}

}  // namespace relocation_packer
