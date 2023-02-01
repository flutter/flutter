// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "software_surface.h"

#include <lib/async/default.h>
#include <lib/ui/scenic/cpp/commands.h>
#include <zircon/rights.h>
#include <zircon/status.h>
#include <zircon/types.h>

#include <cmath>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fuchsia/sysmem/cpp/fidl.h"
#include "include/core/SkImageInfo.h"

#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSurface.h"

#include "../runtime/dart/utils/inlines.h"

namespace flutter_runner {

namespace {

constexpr SkColorType kSkiaColorType = kRGBA_8888_SkColorType;

uint32_t BytesPerRow(const fuchsia::sysmem::SingleBufferSettings& settings,
                     uint32_t bytes_per_pixel,
                     uint32_t image_width) {
  const uint32_t bytes_per_row_divisor =
      settings.image_format_constraints.bytes_per_row_divisor;
  const uint32_t min_bytes_per_row =
      settings.image_format_constraints.min_bytes_per_row;
  const uint32_t unrounded_bytes_per_row =
      std::max(image_width * bytes_per_pixel, min_bytes_per_row);
  const uint32_t roundup_bytes =
      unrounded_bytes_per_row % bytes_per_row_divisor;

  return unrounded_bytes_per_row + roundup_bytes;
}

}  // namespace

uint32_t SoftwareSurface::sNextBufferId = 1;  // 0 is invalid; start at 1.

SoftwareSurface::SoftwareSurface(
    fuchsia::sysmem::AllocatorSyncPtr& sysmem_allocator,
    fuchsia::ui::composition::AllocatorPtr& flatland_allocator,
    scenic::Session* session,
    const SkISize& size)
    : session_(session), wait_for_surface_read_finished_(this) {
  FML_CHECK((session_ || flatland_allocator.is_bound()) &&
            !(session_ && flatland_allocator.is_bound()));

  if (!SetupSkiaSurface(sysmem_allocator, flatland_allocator, size)) {
    FML_LOG(ERROR) << "Could not create render surface.";
    return;
  }

  if (!CreateFences()) {
    FML_LOG(ERROR) << "Could not create signal fences.";
    return;
  }

  if (session) {
    if (image_id_ == 0) {
      image_id_ = session->AllocResourceId();
    }
    session->Enqueue(scenic::NewCreateImage2Cmd(
        image_id_, sk_surface_->width(), sk_surface_->height(), buffer_id_, 0));
  }

  wait_for_surface_read_finished_.set_object(release_event_.get());
  wait_for_surface_read_finished_.set_trigger(ZX_EVENT_SIGNALED);
  Reset();

  valid_ = true;
}

SoftwareSurface::~SoftwareSurface() {
  if (session_) {
    if (image_id_) {
      session_->Enqueue(scenic::NewReleaseResourceCmd(image_id_));
    }
    if (buffer_id_) {
      session_->DeregisterBufferCollection(buffer_id_);
    }
  } else {
    release_image_callback_();
  }
  wait_for_surface_read_finished_.Cancel();
  wait_for_surface_read_finished_.set_object(ZX_HANDLE_INVALID);
}

bool SoftwareSurface::IsValid() const {
  return valid_;
}

SkISize SoftwareSurface::GetSize() const {
  if (!valid_) {
    return SkISize::Make(0, 0);
  }

  return SkISize::Make(sk_surface_->width(), sk_surface_->height());
}

bool SoftwareSurface::CreateFences() {
  if (zx::event::create(0, &acquire_event_) != ZX_OK) {
    FML_LOG(ERROR) << "Failed to create acquire event.";
    return false;
  }

  if (zx::event::create(0, &release_event_) != ZX_OK) {
    FML_LOG(ERROR) << "Failed to create release event.";
    return false;
  }

  return true;
}

bool SoftwareSurface::SetupSkiaSurface(
    fuchsia::sysmem::AllocatorSyncPtr& sysmem_allocator,
    fuchsia::ui::composition::AllocatorPtr& flatland_allocator,
    const SkISize& size) {
  if (size.isEmpty()) {
    FML_LOG(ERROR) << "Failed to allocate surface, size is empty.";
    return false;
  }

  // Allocate a "local" sysmem token to represent flutter's handle to the
  // sysmem buffer.
  fuchsia::sysmem::BufferCollectionTokenSyncPtr local_token;
  zx_status_t allocate_status =
      sysmem_allocator->AllocateSharedCollection(local_token.NewRequest());
  if (allocate_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to allocate collection: "
                   << zx_status_get_string(allocate_status);
    return false;
  }

  // Create a single Duplicate of the token and Sync it; the single duplicate
  // token represents scenic's handle to the sysmem buffer.
  std::vector<fuchsia::sysmem::BufferCollectionTokenHandle> duplicate_tokens;
  zx_status_t duplicate_status = local_token->DuplicateSync(
      std::vector<zx_rights_t>{ZX_RIGHT_SAME_RIGHTS}, &duplicate_tokens);
  if (duplicate_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to duplicate collection token: "
                   << zx_status_get_string(duplicate_status);
    return false;
  }
  if (duplicate_tokens.size() != 1u) {
    FML_LOG(ERROR) << "Failed to duplicate collection token: Incorrect number "
                      "of tokens returned.";
    return false;
  }
  auto scenic_token = std::move(duplicate_tokens[0]);

  // Register the sysmem token with flatland (or scenic's legacy gfx interface).
  //
  // This binds the sysmem token to a composition token, which is used later
  // to associate the rendering surface with a specific flatland Image.
  //
  // Under gfx, scenic uses an integral `buffer_id` instead of the composition
  // token.
  if (session_) {
    buffer_id_ = sNextBufferId++;
    session_->RegisterBufferCollection(buffer_id_, std::move(scenic_token));
  } else {
    fuchsia::ui::composition::BufferCollectionExportToken export_token;
    zx_status_t token_create_status =
        zx::eventpair::create(0, &export_token.value, &import_token_.value);
    if (token_create_status != ZX_OK) {
      FML_LOG(ERROR) << "Failed to create flatland export token: "
                     << zx_status_get_string(token_create_status);
      return false;
    }

    fuchsia::ui::composition::RegisterBufferCollectionArgs args;
    args.set_export_token(std::move(export_token));
    args.set_buffer_collection_token(std::move(scenic_token));
    args.set_usage(
        fuchsia::ui::composition::RegisterBufferCollectionUsage::DEFAULT);
    flatland_allocator->RegisterBufferCollection(
        std::move(args),
        [](fuchsia::ui::composition::Allocator_RegisterBufferCollection_Result
               result) {
          if (result.is_err()) {
            FML_LOG(ERROR)
                << "RegisterBufferCollection call to Scenic Allocator failed.";
          }
        });
  }

  // Acquire flutter's local handle to the sysmem buffer.
  fuchsia::sysmem::BufferCollectionSyncPtr buffer_collection;
  zx_status_t bind_status = sysmem_allocator->BindSharedCollection(
      std::move(local_token), buffer_collection.NewRequest());
  if (bind_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to bind collection token: "
                   << zx_status_get_string(bind_status);
    return false;
  }

  // Set flutter's constraints on the sysmem buffer.  Software rendering only
  // requires CPU access to the surface and a basic R8G8B8A8 pixel format.
  fuchsia::sysmem::BufferCollectionConstraints constraints;
  constraints.min_buffer_count = 1;
  constraints.usage.cpu =
      fuchsia::sysmem::cpuUsageWrite | fuchsia::sysmem::cpuUsageWriteOften;
  constraints.has_buffer_memory_constraints = true;
  constraints.buffer_memory_constraints.physically_contiguous_required = false;
  constraints.buffer_memory_constraints.secure_required = false;
  constraints.buffer_memory_constraints.ram_domain_supported = true;
  constraints.buffer_memory_constraints.cpu_domain_supported = true;
  constraints.buffer_memory_constraints.inaccessible_domain_supported = false;
  constraints.image_format_constraints_count = 1;
  fuchsia::sysmem::ImageFormatConstraints& image_constraints =
      constraints.image_format_constraints[0];
  image_constraints = fuchsia::sysmem::ImageFormatConstraints();
  image_constraints.min_coded_width = static_cast<uint32_t>(size.fWidth);
  image_constraints.min_coded_height = static_cast<uint32_t>(size.fHeight);
  image_constraints.min_bytes_per_row = static_cast<uint32_t>(size.fWidth) * 4;
  image_constraints.pixel_format.type =
      fuchsia::sysmem::PixelFormatType::R8G8B8A8;
  image_constraints.color_spaces_count = 1;
  image_constraints.color_space[0].type = fuchsia::sysmem::ColorSpaceType::SRGB;
  image_constraints.pixel_format.has_format_modifier = true;
  image_constraints.pixel_format.format_modifier.value =
      fuchsia::sysmem::FORMAT_MODIFIER_LINEAR;
  zx_status_t set_constraints_status =
      buffer_collection->SetConstraints(true, constraints);
  if (set_constraints_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to set constraints: "
                   << zx_status_get_string(set_constraints_status);
    return false;
  }

  // Wait for sysmem to allocate, now that constraints are set.
  fuchsia::sysmem::BufferCollectionInfo_2 buffer_collection_info;
  zx_status_t allocation_status = ZX_OK;
  zx_status_t wait_for_allocated_status =
      buffer_collection->WaitForBuffersAllocated(&allocation_status,
                                                 &buffer_collection_info);
  if (allocation_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to allocate: "
                   << zx_status_get_string(allocation_status);
    return false;
  }
  if (wait_for_allocated_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to wait for allocate: "
                   << zx_status_get_string(wait_for_allocated_status);
    return false;
  }

  // Cache the allocated surface VMO and metadata.
  FML_CHECK(buffer_collection_info.settings.buffer_settings.size_bytes != 0);
  FML_CHECK(buffer_collection_info.buffers[0].vmo != ZX_HANDLE_INVALID);
  surface_vmo_ = std::move(buffer_collection_info.buffers[0].vmo);
  surface_size_bytes_ =
      buffer_collection_info.settings.buffer_settings.size_bytes;
  if (buffer_collection_info.settings.buffer_settings.coherency_domain ==
      fuchsia::sysmem::CoherencyDomain::RAM) {
    // RAM coherency domain requires a cache clean when writes are finished.
    needs_cache_clean_ = true;
  }

  // Map the allocated buffer to the CPU.
  uint8_t* vmo_base = nullptr;
  zx_status_t buffer_map_status = zx::vmar::root_self()->map(
      ZX_VM_PERM_WRITE | ZX_VM_PERM_READ, 0, surface_vmo_, 0,
      surface_size_bytes_, reinterpret_cast<uintptr_t*>(&vmo_base));
  if (buffer_map_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to map buffer memory: "
                   << zx_status_get_string(buffer_map_status);
    return false;
  }

  // Now that the buffer is CPU-readable, it's safe to discard flutter's
  // connection to sysmem.
  zx_status_t close_status = buffer_collection->Close();
  if (close_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to close buffer: "
                   << zx_status_get_string(close_status);
    return false;
  }

  // Wrap the buffer in a software-rendered Skia surface.
  const uint64_t vmo_offset =
      buffer_collection_info.buffers[0].vmo_usable_start;
  const size_t vmo_stride =
      BytesPerRow(buffer_collection_info.settings, 4u, size.width());
  SkSurfaceProps sk_surface_props(0, kUnknown_SkPixelGeometry);
  sk_surface_ = SkSurface::MakeRasterDirect(
      SkImageInfo::Make(size, kSkiaColorType, kPremul_SkAlphaType,
                        SkColorSpace::MakeSRGB()),
      vmo_base + vmo_offset, vmo_stride, &sk_surface_props);
  if (!sk_surface_ || sk_surface_->getCanvas() == nullptr) {
    FML_LOG(ERROR) << "SkSurface::MakeRasterDirect failed.";
    return false;
  }

  return true;
}

void SoftwareSurface::SetImageId(uint32_t image_id) {
  FML_CHECK(image_id_ == 0);
  FML_CHECK(!session_);
  image_id_ = image_id;
}

uint32_t SoftwareSurface::GetImageId() {
  return image_id_;
}

sk_sp<SkSurface> SoftwareSurface::GetSkiaSurface() const {
  return valid_ ? sk_surface_ : nullptr;
}

fuchsia::ui::composition::BufferCollectionImportToken
SoftwareSurface::GetBufferCollectionImportToken() {
  FML_CHECK(!session_);
  fuchsia::ui::composition::BufferCollectionImportToken import_dup;
  import_token_.value.duplicate(ZX_RIGHT_SAME_RIGHTS, &import_dup.value);
  return import_dup;
}

zx::event SoftwareSurface::GetAcquireFence() {
  FML_CHECK(!session_);
  zx::event fence;
  acquire_event_.duplicate(ZX_RIGHT_SAME_RIGHTS, &fence);
  return fence;
}

zx::event SoftwareSurface::GetReleaseFence() {
  FML_CHECK(!session_);
  zx::event fence;
  release_event_.duplicate(ZX_RIGHT_SAME_RIGHTS, &fence);
  return fence;
}
void SoftwareSurface::SetReleaseImageCallback(
    ReleaseImageCallback release_image_callback) {
  FML_CHECK(!session_);
  release_image_callback_ = release_image_callback;
}

size_t SoftwareSurface::AdvanceAndGetAge() {
  return ++age_;
}

bool SoftwareSurface::FlushSessionAcquireAndReleaseEvents() {
  if (session_) {
    zx::event acquire, release;
    if (acquire_event_.duplicate(ZX_RIGHT_SAME_RIGHTS, &acquire) != ZX_OK ||
        release_event_.duplicate(ZX_RIGHT_SAME_RIGHTS, &release) != ZX_OK) {
      return false;
    }
    session_->EnqueueAcquireFence(std::move(acquire));
    session_->EnqueueReleaseFence(std::move(release));
  }

  age_ = 0;
  return true;
}

void SoftwareSurface::SignalWritesFinished(
    const std::function<void(void)>& on_surface_read_finished) {
  FML_CHECK(on_surface_read_finished);

  if (!valid_) {
    on_surface_read_finished();
    return;
  }

  dart_utils::Check(surface_read_finished_callback_ == nullptr,
                    "Attempted to signal a write on the surface when the "
                    "previous write has not yet been acknowledged by the "
                    "compositor.");
  surface_read_finished_callback_ = on_surface_read_finished;

  // Sysmem *may* require the cache to be cleared after writes to the surface
  // are complete.
  if (needs_cache_clean_) {
    surface_vmo_.op_range(ZX_VMO_OP_CACHE_CLEAN, 0, surface_size_bytes_,
                          /*buffer*/ nullptr,
                          /*buffer_size*/ 0);
  }

  // Inform scenic that flutter is finished writing to the surface.
  zx_status_t signal_status = acquire_event_.signal(0u, ZX_EVENT_SIGNALED);
  if (signal_status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to signal acquire event; "
                   << zx_status_get_string(signal_status);
  }
}

void SoftwareSurface::Reset() {
  if (acquire_event_.signal(ZX_EVENT_SIGNALED, 0u) != ZX_OK ||
      release_event_.signal(ZX_EVENT_SIGNALED, 0u) != ZX_OK) {
    valid_ = false;
    FML_LOG(ERROR) << "Could not reset fences. The surface is no longer valid.";
  }

  wait_for_surface_read_finished_.Begin(async_get_default_dispatcher());

  // It is safe for the caller to collect the surface in the callback.
  auto callback = surface_read_finished_callback_;
  surface_read_finished_callback_ = nullptr;
  if (callback) {
    callback();
  }
}

void SoftwareSurface::OnSurfaceReadFinished(async_dispatcher_t* dispatcher,
                                            async::WaitBase* wait,
                                            zx_status_t status,
                                            const zx_packet_signal_t* signal) {
  if (status != ZX_OK) {
    return;
  }
  FML_DCHECK(signal->observed & ZX_EVENT_SIGNALED);

  Reset();
}

}  // namespace flutter_runner
