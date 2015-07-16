// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_CONVERTERS_SURFACES_SURFACES_TYPE_CONVERTERS_H_
#define MOJO_CONVERTERS_SURFACES_SURFACES_TYPE_CONVERTERS_H_

#include "base/memory/scoped_ptr.h"
#include "cc/resources/returned_resource.h"
#include "cc/resources/transferable_resource.h"
#include "cc/surfaces/surface_id.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/common/mailbox_holder.h"
#include "mojo/services/surfaces/public/interfaces/quads.mojom.h"
#include "mojo/services/surfaces/public/interfaces/surface_id.mojom.h"
#include "mojo/services/surfaces/public/interfaces/surfaces.mojom.h"
#include "third_party/skia/include/core/SkColor.h"

namespace cc {
class CompositorFrame;
class DrawQuad;
class RenderPass;
class RenderPassId;
class SharedQuadState;
}  // namespace cc

namespace mojo {

// Types from surface_id.mojom
template <>
struct TypeConverter<SurfaceIdPtr, cc::SurfaceId> {
  static SurfaceIdPtr Convert(const cc::SurfaceId& input);
};
template <>
struct TypeConverter<cc::SurfaceId, SurfaceIdPtr> {
  static cc::SurfaceId Convert(const SurfaceIdPtr& input);
};

// Types from quads.mojom
template <>
struct TypeConverter<ColorPtr, SkColor> {
  static ColorPtr Convert(const SkColor& input);
};
template <>
struct TypeConverter<SkColor, ColorPtr> {
  static SkColor Convert(const ColorPtr& input);
};

template <>
struct TypeConverter<RenderPassIdPtr, cc::RenderPassId> {
  static RenderPassIdPtr Convert(const cc::RenderPassId& input);
};

template <>
struct TypeConverter<cc::RenderPassId, RenderPassIdPtr> {
  static cc::RenderPassId Convert(const RenderPassIdPtr& input);
};

template <>
struct TypeConverter<QuadPtr, cc::DrawQuad> {
  static QuadPtr Convert(const cc::DrawQuad& input);
};

template <>
struct TypeConverter<SharedQuadStatePtr, cc::SharedQuadState> {
  static SharedQuadStatePtr Convert(const cc::SharedQuadState& input);
};

template <>
struct TypeConverter<PassPtr, cc::RenderPass> {
  static PassPtr Convert(const cc::RenderPass& input);
};

template <>
struct TypeConverter<scoped_ptr<cc::RenderPass>, PassPtr> {
  static scoped_ptr<cc::RenderPass> Convert(const PassPtr& input);
};

// Types from surfaces.mojom
template <>
struct TypeConverter<MailboxPtr, gpu::Mailbox> {
  static MailboxPtr Convert(const gpu::Mailbox& input);
};
template <>
struct TypeConverter<gpu::Mailbox, MailboxPtr> {
  static gpu::Mailbox Convert(const MailboxPtr& input);
};

template <>
struct TypeConverter<MailboxHolderPtr, gpu::MailboxHolder> {
  static MailboxHolderPtr Convert(const gpu::MailboxHolder& input);
};
template <>
struct TypeConverter<gpu::MailboxHolder, MailboxHolderPtr> {
  static gpu::MailboxHolder Convert(const MailboxHolderPtr& input);
};

template <>
struct TypeConverter<TransferableResourcePtr, cc::TransferableResource> {
  static TransferableResourcePtr Convert(const cc::TransferableResource& input);
};
template <>
struct TypeConverter<cc::TransferableResource, TransferableResourcePtr> {
  static cc::TransferableResource Convert(const TransferableResourcePtr& input);
};

template <>
struct TypeConverter<Array<TransferableResourcePtr>,
                     cc::TransferableResourceArray> {
  static Array<TransferableResourcePtr> Convert(
      const cc::TransferableResourceArray& input);
};
template <>
struct TypeConverter<cc::TransferableResourceArray,
                     Array<TransferableResourcePtr>> {
  static cc::TransferableResourceArray Convert(
      const Array<TransferableResourcePtr>& input);
};

template <>
struct TypeConverter<ReturnedResourcePtr, cc::ReturnedResource> {
  static ReturnedResourcePtr Convert(const cc::ReturnedResource& input);
};
template <>
struct TypeConverter<cc::ReturnedResource, ReturnedResourcePtr> {
  static cc::ReturnedResource Convert(const ReturnedResourcePtr& input);
};

template <>
struct TypeConverter<Array<ReturnedResourcePtr>, cc::ReturnedResourceArray> {
  static Array<ReturnedResourcePtr> Convert(
      const cc::ReturnedResourceArray& input);
};

template <>
struct TypeConverter<FramePtr, cc::CompositorFrame> {
  static FramePtr Convert(const cc::CompositorFrame& input);
};

template <>
struct TypeConverter<scoped_ptr<cc::CompositorFrame>, FramePtr> {
  static scoped_ptr<cc::CompositorFrame> Convert(const FramePtr& input);
};

}  // namespace mojo

#endif  // MOJO_CONVERTERS_SURFACES_SURFACES_TYPE_CONVERTERS_H_
