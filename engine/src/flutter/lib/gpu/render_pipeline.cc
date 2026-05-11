// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pipeline.h"

#include <array>
#include <cstdint>
#include <cstring>
#include <sstream>
#include <string_view>

#include "flutter/lib/gpu/shader.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/vertex_descriptor.h"
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
      vertex_descriptor_(std::move(vertex_descriptor)) {}

void RenderPipeline::BindToPipelineDescriptor(
    impeller::ShaderLibrary& library,
    impeller::PipelineDescriptor& desc) {
  vertex_descriptor_->RegisterDescriptorSetLayouts(
      vertex_shader_->GetDescriptorSetLayouts().data(),
      vertex_shader_->GetDescriptorSetLayouts().size());
  vertex_descriptor_->RegisterDescriptorSetLayouts(
      fragment_shader_->GetDescriptorSetLayouts().data(),
      fragment_shader_->GetDescriptorSetLayouts().size());
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
// Dart: `[binding, stride]`.
constexpr size_t kBufferLayoutInts = 2;

// Width of each "row" in the packed `attributes` ByteData passed from Dart:
// `[bufferBinding, offset, formatIndex, nameByteLength]`. The attribute name
// itself lives in a parallel `attribute_names` byte blob walked sequentially
// using the per-row `nameByteLength`.
constexpr size_t kAttributeInts = 4;

// Builds an `impeller::VertexDescriptor` from the user-supplied buffer
// layout and attribute arrays, validating each entry against the vertex
// shader's reflection metadata. On validation failure, returns a non-empty
// string describing the first problem found.
std::string BuildCustomVertexDescriptor(
    const flutter::gpu::Shader& vertex_shader,
    const int32_t* buffer_layouts,
    size_t buffer_layout_count,
    const int32_t* attributes,
    size_t attribute_count,
    const char* attribute_names,
    size_t attribute_names_byte_length,
    impeller::VertexDescriptor& out) {
  // Build the per-binding stride table. Bindings must be densely packed
  // `{0, 1, ..., buffer_layout_count - 1}` because Impeller's
  // RenderPass::SetVertexBuffer rejects sparse bindings; the HAL would need
  // a `firstBinding`-style entry point before this restriction can be lifted.
  // TODO(https://github.com/flutter/flutter/issues/186308): Allow sparse
  // vertex buffer binding indices.
  std::vector<impeller::ShaderStageBufferLayout> stage_layouts;
  stage_layouts.reserve(buffer_layout_count);
  std::vector<bool> binding_seen(buffer_layout_count, false);
  for (size_t i = 0; i < buffer_layout_count; ++i) {
    const int32_t binding = buffer_layouts[i * kBufferLayoutInts + 0];
    const int32_t stride = buffer_layouts[i * kBufferLayoutInts + 1];
    if (binding < 0 || static_cast<size_t>(binding) >= buffer_layout_count) {
      std::ostringstream s;
      s << "VertexBufferLayout.binding must be in [0, " << buffer_layout_count
        << ") (got " << binding
        << "); binding indices must be densely packed starting from 0.";
      return s.str();
    }
    if (binding_seen[binding]) {
      std::ostringstream s;
      s << "VertexBufferLayout.binding " << binding << " was declared twice.";
      return s.str();
    }
    binding_seen[binding] = true;
    if (stride <= 0) {
      std::ostringstream s;
      s << "VertexBufferLayout.strideInBytes must be positive (got " << stride
        << ").";
      return s.str();
    }
    stage_layouts.push_back(
        {static_cast<size_t>(stride), static_cast<size_t>(binding)});
  }

  // Build per-attribute IOSlots, looking up shader reflection by name for
  // the metadata we don't carry on the Dart side. Name-keyed lookup mirrors
  // the existing uniform binding API and keeps Dart layouts robust to
  // shader source edits (e.g. reordering `in` declarations).
  const auto& shader_inputs = vertex_shader.GetStageInputs();
  std::vector<impeller::ShaderStageIOSlot> stage_inputs;
  stage_inputs.reserve(attribute_count);
  size_t name_cursor = 0;
  for (size_t i = 0; i < attribute_count; ++i) {
    const int32_t buffer_binding = attributes[i * kAttributeInts + 0];
    const int32_t offset = attributes[i * kAttributeInts + 1];
    const int32_t format_index = attributes[i * kAttributeInts + 2];
    const int32_t name_byte_length = attributes[i * kAttributeInts + 3];

    if (name_byte_length <= 0 ||
        name_cursor + static_cast<size_t>(name_byte_length) >
            attribute_names_byte_length) {
      return "Internal error: attribute name overruns the packed names blob.";
    }
    const std::string_view name(attribute_names + name_cursor,
                                static_cast<size_t>(name_byte_length));
    name_cursor += static_cast<size_t>(name_byte_length);

    if (buffer_binding < 0) {
      std::ostringstream s;
      s << "VertexAttribute '" << name
        << "' bufferBinding must be non-negative (got " << buffer_binding
        << ").";
      return s.str();
    }
    if (offset < 0) {
      std::ostringstream s;
      s << "VertexAttribute '" << name
        << "' offsetInBytes must be non-negative (got " << offset << ").";
      return s.str();
    }
    if (format_index < 0 ||
        static_cast<size_t>(format_index) >= kVertexFormatTable.size()) {
      std::ostringstream s;
      s << "VertexAttribute '" << name << "' format index " << format_index
        << " is out of range.";
      return s.str();
    }
    const VertexFormatInfo& format = kVertexFormatTable[format_index];

    // Find the matching layout (for stride bounds checking).
    const impeller::ShaderStageBufferLayout* matching_layout = nullptr;
    for (const auto& layout : stage_layouts) {
      if (layout.binding == static_cast<size_t>(buffer_binding)) {
        matching_layout = &layout;
        break;
      }
    }
    if (matching_layout == nullptr) {
      std::ostringstream s;
      s << "VertexAttribute '" << name << "' references bufferBinding "
        << buffer_binding << " which is not declared in VertexLayout.buffers.";
      return s.str();
    }
    if (static_cast<size_t>(offset) + format.bytes_per_element >
        matching_layout->stride) {
      std::ostringstream s;
      s << "VertexAttribute '" << name << "' (offset " << offset << " + "
        << format.bytes_per_element << " bytes) overruns stride of "
        << matching_layout->stride << " on bufferBinding " << buffer_binding
        << ".";
      return s.str();
    }

    // Find the matching shader input by name to validate format and to copy
    // the (location, set, columns, relaxed_precision) metadata we don't
    // carry on the Dart side. The Shader's IOSlot names point into the
    // shader bundle flatbuffer, which the Shader keeps alive via its code
    // mapping; the impellerc-generated builds use static string literals.
    // Either way, strcmp against a NUL-terminated needle is safe.
    const impeller::ShaderStageIOSlot* shader_slot = nullptr;
    const std::string name_owned(name);
    for (const auto& slot : shader_inputs) {
      if (slot.name != nullptr &&
          std::strcmp(slot.name, name_owned.c_str()) == 0) {
        shader_slot = &slot;
        break;
      }
    }
    if (shader_slot == nullptr) {
      std::ostringstream s;
      s << "VertexAttribute name '" << name
        << "' does not match any input declared by the bound vertex shader.";
      return s.str();
    }
    // Match the shader's scalar type class (float vs signed int vs unsigned
    // int). Mirroring WebGPU, Vulkan, and Metal, component-count mismatches
    // are NOT errors: the shader receives default substitution (missing
    // components default to (0, 0, 0, 1)) when the buffer supplies fewer
    // components than declared, and reads only the leading components when
    // the buffer supplies more. The shipped enum only contains 32-bit
    // formats, so checking `type` alone is sufficient until 8/16-bit
    // formats are added.
    // TODO(https://github.com/flutter/flutter/issues/186309): Add
    // normalized, packed, half-float, BGRA-swizzled, and 64-bit vertex
    // attribute formats; the format check will need to also verify
    // `bit_width` once those land.
    if (shader_slot->type != format.type ||
        shader_slot->bit_width != format.bit_width) {
      std::ostringstream s;
      s << "VertexAttribute '" << name
        << "' format does not match the vertex shader's declared input type.";
      return s.str();
    }

    impeller::ShaderStageIOSlot built = *shader_slot;
    built.binding = static_cast<size_t>(buffer_binding);
    built.offset = static_cast<size_t>(offset);
    stage_inputs.push_back(built);
  }

  if (name_cursor != attribute_names_byte_length) {
    return "Internal error: attribute names blob has trailing bytes.";
  }

  out.SetStageInputs(stage_inputs, stage_layouts);
  return {};
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

    const size_t buffer_layout_count =
        buffer_layouts_ints.size() / flutter::gpu::kBufferLayoutInts;
    const size_t attribute_count =
        attribute_ints.size() / flutter::gpu::kAttributeInts;

    auto descriptor = std::make_shared<impeller::VertexDescriptor>();
    std::string error = flutter::gpu::BuildCustomVertexDescriptor(
        *vertex_shader, buffer_layouts_ints.data(), buffer_layout_count,
        attribute_ints.data(), attribute_count, attribute_names_bytes.data(),
        attribute_names_bytes.size(), *descriptor);
    if (!error.empty()) {
      return tonic::ToDart(error);
    }
    vertex_descriptor = std::move(descriptor);
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
