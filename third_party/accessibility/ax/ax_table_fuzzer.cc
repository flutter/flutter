// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/macros.h"
#include "build/build_config.h"
#include "ui/accessibility/ax_node.h"
#include "ui/accessibility/ax_tree.h"

// The purpose of this script is to fuzz code that parses
// table-like structures. As a result, we want to generate
// accessibility trees that contain lots of table-related
// roles.
//
// We also bias towards cells and rows so that we end up
// with more of those overall.
ax::mojom::Role GetInterestingTableRole(unsigned char byte) {
  switch (byte % 16) {
    default:
    case 0:
    case 1:
    case 2:
    case 3:
      return ax::mojom::Role::kCell;
    case 4:
    case 5:
      return ax::mojom::Role::kRow;
    case 6:
      return ax::mojom::Role::kTable;
    case 7:
      return ax::mojom::Role::kGrid;
    case 8:
      return ax::mojom::Role::kColumnHeader;
    case 9:
      return ax::mojom::Role::kRowHeader;
    case 10:
      return ax::mojom::Role::kGenericContainer;
    case 11:
      return ax::mojom::Role::kIgnored;
    case 12:
      return ax::mojom::Role::kLayoutTable;
    case 13:
      return ax::mojom::Role::kLayoutTableCell;
    case 14:
      return ax::mojom::Role::kLayoutTableRow;
    case 15:
      return ax::mojom::Role::kMain;
  }
}

// We want some of the nodes in the accessibility tree to have
// table-related attributes.
ax::mojom::IntAttribute GetInterestingTableAttribute(unsigned char byte) {
  switch (byte % 10) {
    case 0:
    default:
      return ax::mojom::IntAttribute::kTableCellRowIndex;
    case 1:
      return ax::mojom::IntAttribute::kTableCellColumnIndex;
    case 2:
      return ax::mojom::IntAttribute::kTableRowCount;
    case 3:
      return ax::mojom::IntAttribute::kTableColumnCount;
    case 4:
      return ax::mojom::IntAttribute::kAriaRowCount;
    case 5:
      return ax::mojom::IntAttribute::kAriaColumnCount;
    case 6:
      return ax::mojom::IntAttribute::kTableCellRowSpan;
    case 7:
      return ax::mojom::IntAttribute::kTableCellColumnSpan;
    case 8:
      return ax::mojom::IntAttribute::kAriaCellRowIndex;
    case 9:
      return ax::mojom::IntAttribute::kAriaCellColumnIndex;
  }
}

// Call all of the table-related APIs on an accessibility node.
// These will be no-ops if the node is not part of a complete
// table. We don't care about any of the results, we just want
// to make sure none of these crash or hang.
void TestTableAPIs(const ui::AXNode* node) {
  ignore_result(node->IsTable());
  ignore_result(node->GetTableColCount());
  ignore_result(node->GetTableRowCount());
  ignore_result(node->GetTableAriaColCount());
  ignore_result(node->GetTableAriaRowCount());
  ignore_result(node->GetTableCellCount());
  ignore_result(node->GetTableCaption());
  for (int i = 0; i < 8; i++)
    ignore_result(node->GetTableCellFromIndex(i));
  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      ignore_result(node->GetTableCellFromCoords(i, j));
  // Note: some of the APIs return IDs - we don't care what's
  // returned, we just want to make sure these APIs don't
  // crash. Normally |ids| is an out argument only, but
  // there's no reason we shouldn't be able to pass a vector
  // that was previously used by another call.
  std::vector<ui::AXNode::AXID> ids;
  for (int i = 0; i < 3; i++) {
    std::vector<ui::AXNode::AXID> col_header_node_ids =
        node->GetTableColHeaderNodeIds(i);
    ids.insert(ids.end(), col_header_node_ids.begin(),
               col_header_node_ids.end());

    std::vector<ui::AXNode::AXID> row_header_node_ids =
        node->GetTableRowHeaderNodeIds(i);
    ids.insert(ids.end(), row_header_node_ids.begin(),
               row_header_node_ids.end());
  }
  std::vector<ui::AXNode::AXID> unique_cell_ids = node->GetTableUniqueCellIds();
  ids.insert(ids.end(), unique_cell_ids.begin(), unique_cell_ids.end());

  ignore_result(node->IsTableRow());
  ignore_result(node->GetTableRowRowIndex());
#if defined(OS_APPLE)
  ignore_result(node->IsTableColumn());
  ignore_result(node->GetTableColColIndex());
#endif
  ignore_result(node->IsTableCellOrHeader());
  ignore_result(node->GetTableCellIndex());
  ignore_result(node->GetTableCellColIndex());
  ignore_result(node->GetTableCellRowIndex());
  ignore_result(node->GetTableCellColSpan());
  ignore_result(node->GetTableCellRowSpan());
  ignore_result(node->GetTableCellAriaColIndex());
  ignore_result(node->GetTableCellAriaRowIndex());
  std::vector<ui::AXNode::AXID> cell_col_header_node_ids =
      node->GetTableCellColHeaderNodeIds();
  ids.insert(ids.end(), cell_col_header_node_ids.begin(),
             cell_col_header_node_ids.end());
  std::vector<ui::AXNode::AXID> cell_row_header_node_ids =
      node->GetTableCellRowHeaderNodeIds();
  ids.insert(ids.end(), cell_row_header_node_ids.begin(),
             cell_row_header_node_ids.end());
  std::vector<ui::AXNode*> headers;
  node->GetTableCellColHeaders(&headers);
  node->GetTableCellRowHeaders(&headers);

  for (const auto* child : node->children())
    TestTableAPIs(child);
}

// Entry point for LibFuzzer.
extern "C" int LLVMFuzzerTestOneInput(const unsigned char* data, size_t size) {
  ui::AXTreeUpdate initial_state;
  initial_state.root_id = 1;
  size_t i = 0;

  // The root of the accessibility tree.
  ui::AXNodeData root;
  root.id = 1;
  if (i < size)
    root.role = GetInterestingTableRole(data[i++]);
  root.child_ids.push_back(2);
  initial_state.nodes.push_back(root);

  // Force the next node of the accessibility tree to be a table,
  // and give it no attributes but a few children.
  ui::AXNodeData table;
  table.id = 2;
  table.role = ax::mojom::Role::kTable;
  if (i < size) {
    size_t child_count = data[i++] % 8;
    for (size_t j = 0; j < child_count && i < size; j++)
      table.child_ids.push_back(3 + data[i++] % 32);
  }
  initial_state.nodes.push_back(table);

  // Create more accessibility nodes that might result in a table.
  int next_id = 3;
  while (i < size) {
    ui::AXNodeData node;
    node.id = next_id++;
    if (i < size)
      node.role = GetInterestingTableRole(data[i++]);
    if (i < size) {
      int attr_count = data[i++] % 6;
      for (int j = 0; j < attr_count && i + 1 < size; j++) {
        unsigned char attr = data[i++];
        int32_t value = static_cast<int32_t>(data[i++]) - 2;
        node.AddIntAttribute(GetInterestingTableAttribute(attr), value);
      }
    }
    if (i < size) {
      size_t child_count = data[i++] % 8;
      for (size_t j = 0; j < child_count && i < size; j++)
        node.child_ids.push_back(4 + data[i++] % 32);
    }
    initial_state.nodes.push_back(node);
  }

  // Run with --v=1 to aid in debugging a specific crash.
  VLOG(1) << "Input accessibility tree:\n" << initial_state.ToString();

  ui::AXTree tree;
  if (tree.Unserialize(initial_state))
    TestTableAPIs(tree.root());

  return 0;
}
