// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pipeline.h"

#include <array>
#include <cstdint>
#include <cstring>
#include <span>
#include <string_view>

#include "flutter/lib/gpu/shader.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/vertex_descriptor.h"
#include "third_party/abseil-cpp/absl/status/status.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/abseil-cpp/absl/strings/str_cat.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, RenderPipeline);

RenderPipeline::RenderPipeline(
    fml::RefPtr<flutter::gpu::Shader> vertex_shader,
    fml::RefPtr<flutter::gpu::Shader> fragment_shader,
    std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor)
    : vertex_shader_(std::move(vertex_shader)),
      fragment_shader_(std::move(fragment_shader)),
      vertex_descriptor_(std::move(vertex_descriptor)) {
  // Register the descriptor set layouts contributed by each shader exactly
  // once, here at construction. Doing this in BindToPipelineDescriptor (as
  // earlier revisions did) would append the same layouts on every bind
  // since `RegisterDescriptorSetLayouts` accumulates rather than replaces.
  vertex_descriptor_->RegisterDescriptorSetLayouts(
      vertex_shader_->GetDescriptorSetLayouts().data(),
      vertex_shader_->GetDescriptorSetLayouts().size());
  vertex_descriptor_->RegisterDescriptorSetLayouts(
      fragment_shader_->GetDescriptorSetLayouts().data(),
      fragment_shader_->GetDescriptorSetLayouts().size());
}

void RenderPipeline::BindToPipelineDescriptor(
    impeller::ShaderLibrary& library,
    impeller::PipelineDescriptor& desc) {
  desc.SetVertexDescriptor(vertex_descriptor_);

  desc.AddStageEntrypoint(vertex_shader_->GetFunctionFromLibrary(library));
  desc.AddStageEntrypoint(fragment_shader_->GetFunctionFromLibrary(library));
}

RenderPipeline::~RenderPipeline() = default;

namespace {

// Translation table from the Dart-side `VertexFormat` enum (encoded as the
// enum index) to the `(ShaderType, bit_width, vec_size, bytes_per_element)`
// tuple Impeller's HAL stores in `ShaderStageIOSlot`. The order MUST stay
// in sync with `lib/src/vertex_layout.dart`.
struct VertexFormatInfo {
  impeller::ShaderType type;
  size_t bit_width;
  size_t vec_size;
  size_t bytes_per_element;
};

constexpr std::array<VertexFormatInfo, 12> kVertexFormatTable = {{
    {impeller::ShaderType::kFloat, 32, 1, 4},         // float32
    {impeller::ShaderType::kFloat, 32, 2, 8},         // float32x2
    {impeller::ShaderType::kFloat, 32, 3, 12},        // float32x3
    {impeller::ShaderType::kFloat, 32, 4, 16},        // float32x4
    {impeller::ShaderType::kUnsignedInt, 32, 1, 4},   // uint32
    {impeller::ShaderType::kUnsignedInt, 32, 2, 8},   // uint32x2
    {impeller::ShaderType::kUnsignedInt, 32, 3, 12},  // uint32x3
    {impeller::ShaderType::kUnsignedInt, 32, 4, 16},  // uint32x4
    {impeller::ShaderType::kSignedInt, 32, 1, 4},     // sint32
    {impeller::ShaderType::kSignedInt, 32, 2, 8},     // sint32x2
    {impeller::ShaderType::kSignedInt, 32, 3, 12},    // sint32x3
    {impeller::ShaderType::kSignedInt, 32, 4, 16},    // sint32x4
}};

// Width of each "row" in the packed `bufferLayouts` ByteData passed from
// Dart: `[strideInBytes, attributeCount]`. Each buffer's binding slot is
// implicit in its position in the array (the first buffer is slot 0, etc.).
constexpr size_t kBufferLayoutInts = 2;

// Width of each "row" in the packed `attributes` ByteData passed from Dart:
// `[offsetInBytes, formatIndex, nameByteLength]`. Attribute rows are
// flattened across buffers in buffer-list order; each buffer's
// `attributeCount` indicates how many attribute rows belong to it. The
// attribute name itself lives in a parallel `attribute_names` byte blob
// walked sequentially using the per-row `nameByteLength`.
constexpr size_t kAttributeInts = 3;

// Builds an `impeller::VertexDescriptor` from the user-supplied buffer
// layout and attribute arrays, validating each entry against the vertex
// shader's reflection metadata. On validation failure, returns a non-OK
// status whose message describes the first problem found.
//
// Binding slots are implicit in buffer-list position. Buffer N (0-indexed)
// is bound at binding slot N. This makes sparse bindings impossible to
// express by construction; Impeller's RenderPass::SetVertexBuffer also
// rejects sparse bindings, and lifting that restriction would need a
// `firstBinding`-style entry point added to the HAL.
// TODO(https://github.com/flutter/flutter/issues/186308): Allow sparse
// vertex buffer binding slots.
absl::StatusOr<std::shared_ptr<impeller::VertexDescriptor>>
BuildCustomVertexDescriptor(const flutter::gpu::Shader& vertex_shader,
                            std::span<const int32_t> buffer_layouts,
                            std::span<const int32_t> attributes,
                            std::span<const char> attribute_names) {
  const size_t buffer_layout_count = buffer_layouts.size() / kBufferLayoutInts;
  const size_t attribute_count = attributes.size() / kAttributeInts;
  const auto& shader_inputs = vertex_shader.GetStageInputs();

  std::vector<impeller::ShaderStageBufferLayout> stage_layouts;
  stage_layouts.reserve(buffer_layout_count);
  std::vector<impeller::ShaderStageIOSlot> stage_inputs;
  stage_inputs.reserve(attribute_count);

  size_t attr_cursor = 0;
  size_t name_cursor = 0;
  for (size_t buffer_index = 0; buffer_index < buffer_layout_count;
       ++buffer_index) {
    const int32_t stride = buffer_layouts[buffer_index * kBufferLayoutInts + 0];
    const int32_t attr_count_in_buffer =
        buffer_layouts[buffer_index * kBufferLayoutInts + 1];
    if (stride <= 0) {
      return absl::InvalidArgumentError(
          absl::StrCat("VertexBuffer.strideInBytes must be positive (got ",
                       stride, ") on buffer at index ", buffer_index, "."));
    }
    if (attr_count_in_buffer < 0 ||
        attr_cursor + static_cast<size_t>(attr_count_in_buffer) >
            attribute_count) {
      return absl::InvalidArgumentError(
          "Internal error: attribute count overruns the packed attributes "
          "blob.");
    }
    stage_layouts.push_back({static_cast<size_t>(stride), buffer_index});

    // Track each attribute's byte range within this buffer so we can
    // detect overlaps after building them all.
    struct AttrRange {
      std::string name;
      size_t begin;
      size_t end;
    };
    std::vector<AttrRange> ranges_in_buffer;
    ranges_in_buffer.reserve(attr_count_in_buffer);

    for (size_t a = 0; a < static_cast<size_t>(attr_count_in_buffer); ++a) {
      const int32_t offset = attributes[attr_cursor * kAttributeInts + 0];
      const int32_t format_index = attributes[attr_cursor * kAttributeInts + 1];
      const int32_t name_byte_length =
          attributes[attr_cursor * kAttributeInts + 2];
      ++attr_cursor;

      if (name_byte_length <= 0 ||
          name_cursor + static_cast<size_t>(name_byte_length) >
              attribute_names.size()) {
        return absl::InvalidArgumentError(
            "Internal error: attribute name overruns the packed names blob.");
      }
      const std::string_view name(attribute_names.data() + name_cursor,
                                  static_cast<size_t>(name_byte_length));
      name_cursor += static_cast<size_t>(name_byte_length);

      if (offset < 0) {
        return absl::InvalidArgumentError(absl::StrCat(
            "VertexAttribute '", name,
            "' offsetInBytes must be non-negative (got ", offset, ")."));
      }
      if (format_index < 0 ||
          static_cast<size_t>(format_index) >= kVertexFormatTable.size()) {
        return absl::InvalidArgumentError(
            absl::StrCat("VertexAttribute '", name, "' format index ",
                         format_index, " is out of range."));
      }
      const VertexFormatInfo& format = kVertexFormatTable[format_index];

      if (static_cast<size_t>(offset) + format.bytes_per_element >
          static_cast<size_t>(stride)) {
        return absl::InvalidArgumentError(absl::StrCat(
            "VertexAttribute '", name, "' (offset ", offset, " + ",
            format.bytes_per_element, " bytes) overruns stride of ", stride,
            " on buffer at index ", buffer_index, "."));
      }

      // Detect overlap against earlier attributes in this buffer before
      // doing any shader-side lookups, so the overlap diagnostic isn't
      // shadowed by a less informative name-mismatch error.
      const size_t begin = static_cast<size_t>(offset);
      const size_t end = begin + format.bytes_per_element;
      const std::string name_owned(name);
      for (const auto& other : ranges_in_buffer) {
        if (begin < other.end && other.begin < end) {
          return absl::InvalidArgumentError(
              absl::StrCat("VertexAttribute '", name, "' (bytes [", begin, ", ",
                           end, ")) overlaps VertexAttribute '", other.name,
                           "' (bytes [", other.begin, ", ", other.end,
                           ")) on buffer at index ", buffer_index, "."));
        }
      }
      ranges_in_buffer.push_back({name_owned, begin, end});

      // Find the matching shader input by name to validate format and to
      // copy the (location, set, columns, relaxed_precision) metadata we
      // don't carry on the Dart side. The Shader's IOSlot names point into
      // the shader bundle flatbuffer, which the Shader keeps alive via its
      // code mapping; the impellerc-generated builds use static string
      // literals. Either way, strcmp against a NUL-terminated needle is
      // safe.
      const impeller::ShaderStageIOSlot* shader_slot = nullptr;
      for (const auto& slot : shader_inputs) {
        if (slot.name != nullptr &&
            std::strcmp(slot.name, name_owned.c_str()) == 0) {
          shader_slot = &slot;
          break;
        }
      }
      if (shader_slot == nullptr) {
        return absl::InvalidArgumentError(absl::StrCat(
            "VertexAttribute name '", name,
            "' does not match any input declared by the bound vertex "
            "shader."));
      }
      // Match the shader's scalar type class (float vs signed int vs
      // unsigned int). Mirroring WebGPU, Vulkan, and Metal, component-count
      // mismatches are NOT errors: the shader receives default substitution
      // (missing components default to (0, 0, 0, 1)) when the buffer
      // supplies fewer components than declared, and reads only the leading
      // components when the buffer supplies more. The shipped enum only
      // contains 32-bit formats, so checking `type` alone is sufficient
      // until 8/16-bit formats are added.
      // TODO(https://github.com/flutter/flutter/issues/186309): Add
      // normalized, packed, half-float, BGRA-swizzled, and 64-bit vertex
      // attribute formats; the format check will need to also verify
      // `bit_width` once those land.
      if (shader_slot->type != format.type ||
          shader_slot->bit_width != format.bit_width) {
        return absl::InvalidArgumentError(absl::StrCat(
            "VertexAttribute '", name,
            "' format does not match the vertex shader's declared input "
            "type."));
      }

      impeller::ShaderStageIOSlot built = *shader_slot;
      built.binding = buffer_index;
      built.offset = static_cast<size_t>(offset);
      stage_inputs.push_back(built);
    }
  }

  if (attr_cursor != attribute_count) {
    return absl::InvalidArgumentError(
        "Internal error: attributes blob has trailing rows not consumed "
        "by any buffer.");
  }
  if (name_cursor != attribute_names.size()) {
    return absl::InvalidArgumentError(
        "Internal error: attribute names blob has trailing bytes.");
  }

  auto descriptor = std::make_shared<impeller::VertexDescriptor>();
  descriptor->SetStageInputs(stage_inputs, stage_layouts);
  return descriptor;
}

}  // namespace

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_RenderPipeline_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    flutter::gpu::Shader* vertex_shader,
    flutter::gpu::Shader* fragment_shader,
    Dart_Handle buffer_layouts_handle,
    Dart_Handle attributes_handle,
    Dart_Handle attribute_names_handle) {
  // Lazily register the shaders synchronously if they haven't been already.
  vertex_shader->RegisterSync(*gpu_context);
  fragment_shader->RegisterSync(*gpu_context);

  std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor;

  const bool buffer_layouts_provided = !Dart_IsNull(buffer_layouts_handle);
  const bool attributes_provided = !Dart_IsNull(attributes_handle);
  const bool attribute_names_provided = !Dart_IsNull(attribute_names_handle);
  if (buffer_layouts_provided != attributes_provided ||
      attributes_provided != attribute_names_provided) {
    return tonic::ToDart(
        "VertexLayout requires buffer layouts, attributes, and attribute "
        "names to be provided together.");
  }

  if (buffer_layouts_provided) {
    // Copy the packed Dart-side ByteData buffers into local vectors so the
    // tonic::DartByteData typed-data handles are released before we make any
    // call back into the Dart VM (e.g. tonic::ToDart for an error string).
    // Holding a typed-data handle while calling into the VM raises
    // "Callbacks into the Dart VM are currently prohibited." Errors raised
    // inside the inner scope must therefore be deferred to a local string
    // and returned only after the typed-data handles go out of scope.
    std::vector<int32_t> buffer_layouts_ints;
    std::vector<int32_t> attribute_ints;
    std::vector<char> attribute_names_bytes;
    std::string copy_error;
    {
      tonic::DartByteData buffer_layouts_data(buffer_layouts_handle);
      tonic::DartByteData attributes_data(attributes_handle);
      tonic::DartByteData attribute_names_data(attribute_names_handle);
      if (buffer_layouts_data.length_in_bytes() %
              (flutter::gpu::kBufferLayoutInts * sizeof(int32_t)) !=
          0) {
        copy_error =
            "Internal error: buffer layouts ByteData has invalid length.";
      } else if (attributes_data.length_in_bytes() %
                     (flutter::gpu::kAttributeInts * sizeof(int32_t)) !=
                 0) {
        copy_error = "Internal error: attributes ByteData has invalid length.";
      } else {
        const auto* buffer_layouts_src =
            static_cast<const int32_t*>(buffer_layouts_data.data());
        const auto* attributes_src =
            static_cast<const int32_t*>(attributes_data.data());
        const auto* names_src =
            static_cast<const char*>(attribute_names_data.data());
        buffer_layouts_ints.assign(
            buffer_layouts_src,
            buffer_layouts_src +
                buffer_layouts_data.length_in_bytes() / sizeof(int32_t));
        attribute_ints.assign(
            attributes_src, attributes_src + attributes_data.length_in_bytes() /
                                                 sizeof(int32_t));
        attribute_names_bytes.assign(
            names_src, names_src + attribute_names_data.length_in_bytes());
      }
    }
    if (!copy_error.empty()) {
      return tonic::ToDart(copy_error);
    }

    absl::StatusOr<std::shared_ptr<impeller::VertexDescriptor>> built =
        flutter::gpu::BuildCustomVertexDescriptor(
            *vertex_shader,
            std::span<const int32_t>(buffer_layouts_ints.data(),
                                     buffer_layouts_ints.size()),
            std::span<const int32_t>(attribute_ints.data(),
                                     attribute_ints.size()),
            std::span<const char>(attribute_names_bytes.data(),
                                  attribute_names_bytes.size()));
    if (!built.ok()) {
      return tonic::ToDart(std::string(built.status().message()));
    }
    vertex_descriptor = *std::move(built);
  } else {
    vertex_descriptor = vertex_shader->CreateVertexDescriptor();
  }

  auto res = fml::MakeRefCounted<flutter::gpu::RenderPipeline>(
      fml::RefPtr<flutter::gpu::Shader>(vertex_shader),    //
      fml::RefPtr<flutter::gpu::Shader>(fragment_shader),  //
      std::move(vertex_descriptor));
  res->AssociateWithDartWrapper(wrapper);

  return Dart_Null();
}
