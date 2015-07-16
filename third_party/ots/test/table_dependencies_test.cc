// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtest/gtest.h>

#include "gsub.h"
#include "ots.h"
#include "ots-memory-stream.h"
#include "vhea.h"
#include "vmtx.h"

#define SET_TABLE(name, capname) \
  do { file.name = new ots::OpenType##capname; } while (0)
#define SET_LAYOUT_TABLE(name, capname)                    \
  do {                                                     \
    if (!file.name) {                                      \
      SET_TABLE(name, capname);                            \
    }                                                      \
    file.name->data = reinterpret_cast<const uint8_t*>(1); \
    file.name->length = 1;                                 \
  } while (0)
#define DROP_TABLE(name) \
  do { delete file.name; file.name = NULL; } while (0)
#define DROP_LAYOUT_TABLE(name) \
  do { file.name->data = NULL; file.name->length = 0; } while (0)

namespace {

class TableDependenciesTest : public ::testing::Test {
 protected:
  virtual void SetUp() {
    SET_LAYOUT_TABLE(gsub, GSUB);
    SET_TABLE(vhea, VHEA);
    SET_TABLE(vmtx, VMTX);
  }

  virtual void TearDown() {
    DROP_TABLE(gsub);
    DROP_TABLE(vhea);
    DROP_TABLE(vmtx);
  }
  ots::OpenTypeFile file;
};
}  // namespace

TEST_F(TableDependenciesTest, TestVhea) {
  EXPECT_TRUE(ots::ots_vhea_should_serialise(&file));
}

TEST_F(TableDependenciesTest, TestVmtx) {
  EXPECT_TRUE(ots::ots_vmtx_should_serialise(&file));
}

TEST_F(TableDependenciesTest, TestVheaVmtx) {
  DROP_TABLE(vmtx);
  EXPECT_FALSE(ots::ots_vhea_should_serialise(&file));
}

TEST_F(TableDependenciesTest, TestVmtxVhea) {
  DROP_TABLE(vhea);
  EXPECT_FALSE(ots::ots_vmtx_should_serialise(&file));
}

TEST_F(TableDependenciesTest, TestVheaGsub) {
  DROP_LAYOUT_TABLE(gsub);
  EXPECT_FALSE(ots::ots_vhea_should_serialise(&file));
  DROP_TABLE(gsub);
  EXPECT_FALSE(ots::ots_vhea_should_serialise(&file));
}

TEST_F(TableDependenciesTest, TestVmtxGsub) {
  DROP_LAYOUT_TABLE(gsub);
  EXPECT_FALSE(ots::ots_vmtx_should_serialise(&file));
  DROP_TABLE(gsub);
  EXPECT_FALSE(ots::ots_vmtx_should_serialise(&file));
}

