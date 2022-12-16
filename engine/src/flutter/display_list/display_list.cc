// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <type_traits>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/display_list/display_list_ops.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

const SaveLayerOptions SaveLayerOptions::kNoAttributes = SaveLayerOptions();
const SaveLayerOptions SaveLayerOptions::kWithAttributes =
    kNoAttributes.with_renders_with_attributes();

DisplayList::DisplayList()
    : byte_count_(0),
      op_count_(0),
      nested_byte_count_(0),
      nested_op_count_(0),
      unique_id_(0),
      bounds_({0, 0, 0, 0}),
      can_apply_group_opacity_(true) {}

DisplayList::DisplayList(DisplayListStorage&& storage,
                         size_t byte_count,
                         unsigned int op_count,
                         size_t nested_byte_count,
                         unsigned int nested_op_count,
                         const SkRect& bounds,
                         bool can_apply_group_opacity,
                         sk_sp<const DlRTree> rtree)
    : storage_(std::move(storage)),
      byte_count_(byte_count),
      op_count_(op_count),
      nested_byte_count_(nested_byte_count),
      nested_op_count_(nested_op_count),
      bounds_(bounds),
      can_apply_group_opacity_(can_apply_group_opacity),
      rtree_(std::move(rtree)) {
  static std::atomic<uint32_t> next_id{1};
  do {
    unique_id_ = next_id.fetch_add(+1, std::memory_order_relaxed);
  } while (unique_id_ == 0);
}

DisplayList::~DisplayList() {
  uint8_t* ptr = storage_.get();
  DisposeOps(ptr, ptr + byte_count_);
}

void DisplayList::Dispatch(Dispatcher& dispatcher,
                           uint8_t* ptr,
                           uint8_t* end) const {
  while (ptr < end) {
    auto op = reinterpret_cast<const DLOp*>(ptr);
    ptr += op->size;
    FML_DCHECK(ptr <= end);
    switch (op->type) {
#define DL_OP_DISPATCH(name)                                \
  case DisplayListOpType::k##name:                          \
    static_cast<const name##Op*>(op)->dispatch(dispatcher); \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_DISPATCH)

#undef DL_OP_DISPATCH

      default:
        FML_DCHECK(false);
        return;
    }
  }
}

void DisplayList::DisposeOps(uint8_t* ptr, uint8_t* end) {
  while (ptr < end) {
    auto op = reinterpret_cast<const DLOp*>(ptr);
    ptr += op->size;
    FML_DCHECK(ptr <= end);
    switch (op->type) {
#define DL_OP_DISPOSE(name)                            \
  case DisplayListOpType::k##name:                     \
    if (!std::is_trivially_destructible_v<name##Op>) { \
      static_cast<const name##Op*>(op)->~name##Op();   \
    }                                                  \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_DISPOSE)

#undef DL_OP_DISPOSE

      default:
        FML_DCHECK(false);
        return;
    }
  }
}

static bool CompareOps(uint8_t* ptrA,
                       uint8_t* endA,
                       uint8_t* ptrB,
                       uint8_t* endB) {
  // These conditions are checked by the caller...
  FML_DCHECK((endA - ptrA) == (endB - ptrB));
  FML_DCHECK(ptrA != ptrB);
  uint8_t* bulk_start_a = ptrA;
  uint8_t* bulk_start_b = ptrB;
  while (ptrA < endA && ptrB < endB) {
    auto opA = reinterpret_cast<const DLOp*>(ptrA);
    auto opB = reinterpret_cast<const DLOp*>(ptrB);
    if (opA->type != opB->type || opA->size != opB->size) {
      return false;
    }
    ptrA += opA->size;
    ptrB += opB->size;
    FML_DCHECK(ptrA <= endA);
    FML_DCHECK(ptrB <= endB);
    DisplayListCompare result;
    switch (opA->type) {
#define DL_OP_EQUALS(name)                              \
  case DisplayListOpType::k##name:                      \
    result = static_cast<const name##Op*>(opA)->equals( \
        static_cast<const name##Op*>(opB));             \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_EQUALS)

#undef DL_OP_EQUALS

      default:
        FML_DCHECK(false);
        return false;
    }
    switch (result) {
      case DisplayListCompare::kNotEqual:
        return false;
      case DisplayListCompare::kUseBulkCompare:
        break;
      case DisplayListCompare::kEqual:
        // Check if we have a backlog of bytes to bulk compare and then
        // reset the bulk compare pointers to the address following this op
        auto bulk_bytes = reinterpret_cast<const uint8_t*>(opA) - bulk_start_a;
        if (bulk_bytes > 0) {
          if (memcmp(bulk_start_a, bulk_start_b, bulk_bytes) != 0) {
            return false;
          }
        }
        bulk_start_a = ptrA;
        bulk_start_b = ptrB;
        break;
    }
  }
  if (ptrA != endA || ptrB != endB) {
    return false;
  }
  if (bulk_start_a < ptrA) {
    // Perform a final bulk compare if we have remaining bytes waiting
    if (memcmp(bulk_start_a, bulk_start_b, ptrA - bulk_start_a) != 0) {
      return false;
    }
  }
  return true;
}

void DisplayList::RenderTo(DisplayListBuilder* builder,
                           SkScalar opacity) const {
  // TODO(100983): Opacity is not respected and attributes are not reset.
  if (!builder) {
    return;
  }
  Dispatch(*builder);
}

void DisplayList::RenderTo(SkCanvas* canvas, SkScalar opacity) const {
  DisplayListCanvasDispatcher dispatcher(canvas, opacity);
  Dispatch(dispatcher);
}

bool DisplayList::Equals(const DisplayList* other) const {
  if (this == other) {
    return true;
  }
  if (byte_count_ != other->byte_count_ || op_count_ != other->op_count_) {
    return false;
  }
  uint8_t* ptr = storage_.get();
  uint8_t* o_ptr = other->storage_.get();
  if (ptr == o_ptr) {
    return true;
  }
  return CompareOps(ptr, ptr + byte_count_, o_ptr, o_ptr + other->byte_count_);
}

}  // namespace flutter
