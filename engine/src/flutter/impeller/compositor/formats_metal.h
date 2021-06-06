// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/geometry/color.h"

namespace impeller {

constexpr MTLPixelFormat ToMTLPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::kUnknown:
      return MTLPixelFormatInvalid;
  }
  return MTLPixelFormatInvalid;
};

constexpr MTLBlendFactor ToMTLBlendFactor(BlendFactor type) {
  switch (type) {
    case BlendFactor::kZero:
      return MTLBlendFactorZero;
    case BlendFactor::kOne:
      return MTLBlendFactorOne;
    case BlendFactor::kSourceColor:
      return MTLBlendFactorSourceColor;
    case BlendFactor::kOneMinusSourceColor:
      return MTLBlendFactorOneMinusSourceColor;
    case BlendFactor::kSourceAlpha:
      return MTLBlendFactorSourceAlpha;
    case BlendFactor::kOneMinusSourceAlpha:
      return MTLBlendFactorOneMinusSourceAlpha;
    case BlendFactor::kDestinationColor:
      return MTLBlendFactorDestinationColor;
    case BlendFactor::kOneMinusDestinationColor:
      return MTLBlendFactorOneMinusDestinationColor;
    case BlendFactor::kDestinationAlpha:
      return MTLBlendFactorDestinationAlpha;
    case BlendFactor::kOneMinusDestinationAlpha:
      return MTLBlendFactorOneMinusDestinationAlpha;
    case BlendFactor::kSourceAlphaSaturated:
      return MTLBlendFactorSourceAlphaSaturated;
    case BlendFactor::kBlendColor:
      return MTLBlendFactorBlendColor;
    case BlendFactor::kOneMinusBlendColor:
      return MTLBlendFactorOneMinusBlendColor;
    case BlendFactor::kBlendAlpha:
      return MTLBlendFactorBlendAlpha;
    case BlendFactor::kOneMinusBlendAlpha:
      return MTLBlendFactorOneMinusBlendAlpha;
  }
  return MTLBlendFactorZero;
};

constexpr MTLBlendOperation ToMTLBlendOperation(BlendOperation type) {
  switch (type) {
    case BlendOperation::kAdd:
      return MTLBlendOperationAdd;
    case BlendOperation::kSubtract:
      return MTLBlendOperationSubtract;
    case BlendOperation::kReverseSubtract:
      return MTLBlendOperationReverseSubtract;
    case BlendOperation::kMin:
      return MTLBlendOperationMin;
    case BlendOperation::kMax:
      return MTLBlendOperationMax;
  }
  return MTLBlendOperationAdd;
};

constexpr MTLColorWriteMask ToMTLColorWriteMask(
    std::underlying_type_t<ColorWriteMask> type) {
  using UnderlyingType = decltype(type);

  MTLColorWriteMask mask = MTLColorWriteMaskNone;

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kRed)) {
    mask |= MTLColorWriteMaskRed;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kGreen)) {
    mask |= MTLColorWriteMaskGreen;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kBlue)) {
    mask |= MTLColorWriteMaskBlue;
  }

  if (type & static_cast<UnderlyingType>(ColorWriteMask::kAlpha)) {
    mask |= MTLColorWriteMaskAlpha;
  }

  return mask;
};

constexpr MTLCompareFunction ToMTLCompareFunction(CompareFunction func) {
  switch (func) {
    case CompareFunction::kNever:
      return MTLCompareFunctionNever;
    case CompareFunction::kLess:
      return MTLCompareFunctionLess;
    case CompareFunction::kEqual:
      return MTLCompareFunctionEqual;
    case CompareFunction::kLessEqual:
      return MTLCompareFunctionLessEqual;
    case CompareFunction::kGreater:
      return MTLCompareFunctionGreater;
    case CompareFunction::kNotEqual:
      return MTLCompareFunctionNotEqual;
    case CompareFunction::kGreaterEqual:
      return MTLCompareFunctionGreaterEqual;
    case CompareFunction::kAlways:
      return MTLCompareFunctionAlways;
  }
  return MTLCompareFunctionAlways;
};

constexpr MTLStencilOperation ToMTLStencilOperation(StencilOperation op) {
  switch (op) {
    case StencilOperation::kKeep:
      return MTLStencilOperationKeep;
    case StencilOperation::kZero:
      return MTLStencilOperationZero;
    case StencilOperation::kReplace:
      return MTLStencilOperationReplace;
    case StencilOperation::kIncrementClamp:
      return MTLStencilOperationIncrementClamp;
    case StencilOperation::kDecrementClamp:
      return MTLStencilOperationDecrementClamp;
    case StencilOperation::kInvert:
      return MTLStencilOperationInvert;
    case StencilOperation::kIncrementWrap:
      return MTLStencilOperationIncrementWrap;
    case StencilOperation::kDecrementWrap:
      return MTLStencilOperationDecrementWrap;
  }
  return MTLStencilOperationKeep;
};

constexpr MTLLoadAction ToMTLLoadAction(LoadAction action) {
  switch (action) {
    case LoadAction::kDontCare:
      return MTLLoadActionDontCare;
    case LoadAction::kLoad:
      return MTLLoadActionLoad;
    case LoadAction::kClear:
      return MTLLoadActionClear;
  }

  return MTLLoadActionDontCare;
}

constexpr MTLStoreAction ToMTLStoreAction(StoreAction action) {
  switch (action) {
    case StoreAction::kDontCare:
      return MTLStoreActionDontCare;
    case StoreAction::kStore:
      return MTLStoreActionStore;
  }
  return MTLStoreActionDontCare;
}

constexpr MTLClearColor ToMTLClearColor(const Color& color) {
  return MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
}

MTLRenderPipelineColorAttachmentDescriptor*
ToMTLRenderPipelineColorAttachmentDescriptor(
    ColorAttachmentDescriptor descriptor);

MTLDepthStencilDescriptor* ToMTLDepthStencilDescriptor(
    std::optional<DepthAttachmentDescriptor> depth,
    std::optional<StencilAttachmentDescriptor> front,
    std::optional<StencilAttachmentDescriptor> back);

}  // namespace impeller
