// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_tree_id_mojom_traits.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_tree_id.h"
#include "ui/accessibility/mojom/ax_tree_id.mojom.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXTreeIDMojomTraitsTest, TestSerializeAndDeserializeAXTreeID) {
  ui::AXTreeID empty_input = ui::AXTreeID();
  ui::AXTreeID empty_output;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXTreeID>(&empty_input,
                                                           &empty_output));
  EXPECT_EQ(empty_input, empty_output);
  EXPECT_EQ("", empty_output.ToString());

  ui::AXTreeID unknown_input = ui::AXTreeIDUnknown();
  ui::AXTreeID unknown_output;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXTreeID>(&unknown_input,
                                                           &unknown_output));
  EXPECT_EQ(unknown_input, unknown_output);
  EXPECT_EQ("", unknown_output.ToString());

  ui::AXTreeID token_input = ui::AXTreeID::CreateNewAXTreeID();
  ui::AXTreeID token_output;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXTreeID>(&token_input,
                                                           &token_output));
  EXPECT_EQ(token_input, token_output);
  // It should be a 32-char hex string.
  EXPECT_EQ(32U, token_output.ToString().size());
}
