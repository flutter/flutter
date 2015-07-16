// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/context_state.h"

#include <cmath>

#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/buffer_manager.h"
#include "gpu/command_buffer/service/error_state.h"
#include "gpu/command_buffer/service/framebuffer_manager.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/renderbuffer_manager.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"

namespace gpu {
namespace gles2 {

namespace {

GLuint Get2dServiceId(const TextureUnit& unit) {
  return unit.bound_texture_2d.get()
      ? unit.bound_texture_2d->service_id() : 0;
}

GLuint GetCubeServiceId(const TextureUnit& unit) {
  return unit.bound_texture_cube_map.get()
      ? unit.bound_texture_cube_map->service_id() : 0;
}

GLuint GetOesServiceId(const TextureUnit& unit) {
  return unit.bound_texture_external_oes.get()
      ? unit.bound_texture_external_oes->service_id() : 0;
}

GLuint GetArbServiceId(const TextureUnit& unit) {
  return unit.bound_texture_rectangle_arb.get()
      ? unit.bound_texture_rectangle_arb->service_id() : 0;
}

GLuint GetServiceId(const TextureUnit& unit, GLuint target) {
  switch (target) {
    case GL_TEXTURE_2D:
      return Get2dServiceId(unit);
    case GL_TEXTURE_CUBE_MAP:
      return GetCubeServiceId(unit);
    case GL_TEXTURE_RECTANGLE_ARB:
      return GetArbServiceId(unit);
    case GL_TEXTURE_EXTERNAL_OES:
      return GetOesServiceId(unit);
    default:
      NOTREACHED();
      return 0;
  }
}

bool TargetIsSupported(const FeatureInfo* feature_info, GLuint target) {
  switch (target) {
    case GL_TEXTURE_2D:
      return true;
    case GL_TEXTURE_CUBE_MAP:
      return true;
    case GL_TEXTURE_RECTANGLE_ARB:
      return feature_info->feature_flags().arb_texture_rectangle;
    case GL_TEXTURE_EXTERNAL_OES:
      return feature_info->feature_flags().oes_egl_image_external;
    default:
      NOTREACHED();
      return false;
  }
}

}  // anonymous namespace.

TextureUnit::TextureUnit()
    : bind_target(GL_TEXTURE_2D) {
}

TextureUnit::~TextureUnit() {
}

ContextState::ContextState(FeatureInfo* feature_info,
                           ErrorStateClient* error_state_client,
                           Logger* logger)
    : active_texture_unit(0),
      bound_renderbuffer_valid(false),
      pack_reverse_row_order(false),
      ignore_cached_state(false),
      fbo_binding_for_scissor_workaround_dirty(false),
      feature_info_(feature_info),
      error_state_(ErrorState::Create(error_state_client, logger)) {
  Initialize();
}

ContextState::~ContextState() {
}

void ContextState::RestoreTextureUnitBindings(
    GLuint unit, const ContextState* prev_state) const {
  DCHECK_LT(unit, texture_units.size());
  const TextureUnit& texture_unit = texture_units[unit];
  GLuint service_id_2d = Get2dServiceId(texture_unit);
  GLuint service_id_cube = GetCubeServiceId(texture_unit);
  GLuint service_id_oes = GetOesServiceId(texture_unit);
  GLuint service_id_arb = GetArbServiceId(texture_unit);

  bool bind_texture_2d = true;
  bool bind_texture_cube = true;
  bool bind_texture_oes = feature_info_->feature_flags().oes_egl_image_external;
  bool bind_texture_arb = feature_info_->feature_flags().arb_texture_rectangle;

  if (prev_state) {
    const TextureUnit& prev_unit = prev_state->texture_units[unit];
    bind_texture_2d = service_id_2d != Get2dServiceId(prev_unit);
    bind_texture_cube = service_id_cube != GetCubeServiceId(prev_unit);
    bind_texture_oes =
        bind_texture_oes && service_id_oes != GetOesServiceId(prev_unit);
    bind_texture_arb =
        bind_texture_arb && service_id_arb != GetArbServiceId(prev_unit);
  }

  // Early-out if nothing has changed from the previous state.
  if (!bind_texture_2d && !bind_texture_cube
      && !bind_texture_oes && !bind_texture_arb) {
    return;
  }

  glActiveTexture(GL_TEXTURE0 + unit);
  if (bind_texture_2d) {
    glBindTexture(GL_TEXTURE_2D, service_id_2d);
  }
  if (bind_texture_cube) {
    glBindTexture(GL_TEXTURE_CUBE_MAP, service_id_cube);
  }
  if (bind_texture_oes) {
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, service_id_oes);
  }
  if (bind_texture_arb) {
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, service_id_arb);
  }
}

void ContextState::RestoreBufferBindings() const {
  if (vertex_attrib_manager.get()) {
    Buffer* element_array_buffer =
        vertex_attrib_manager->element_array_buffer();
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,
        element_array_buffer ? element_array_buffer->service_id() : 0);
  }
  glBindBuffer(GL_ARRAY_BUFFER,
               bound_array_buffer.get() ? bound_array_buffer->service_id() : 0);
}

void ContextState::RestoreRenderbufferBindings() {
  // Require Renderbuffer rebind.
  bound_renderbuffer_valid = false;
}

void ContextState::RestoreProgramBindings() const {
  glUseProgram(current_program.get() ? current_program->service_id() : 0);
}

void ContextState::RestoreActiveTexture() const {
  glActiveTexture(GL_TEXTURE0 + active_texture_unit);
}

void ContextState::RestoreAllTextureUnitBindings(
    const ContextState* prev_state) const {
  // Restore Texture state.
  for (size_t ii = 0; ii < texture_units.size(); ++ii) {
    RestoreTextureUnitBindings(ii, prev_state);
  }
  RestoreActiveTexture();
}

void ContextState::RestoreActiveTextureUnitBinding(unsigned int target) const {
  DCHECK_LT(active_texture_unit, texture_units.size());
  const TextureUnit& texture_unit = texture_units[active_texture_unit];
  if (TargetIsSupported(feature_info_, target))
    glBindTexture(target, GetServiceId(texture_unit, target));
}

void ContextState::RestoreVertexAttribValues() const {
  for (size_t attrib = 0; attrib < vertex_attrib_manager->num_attribs();
       ++attrib) {
    glVertexAttrib4fv(attrib, attrib_values[attrib].v);
  }
}

void ContextState::RestoreVertexAttribArrays(
    const scoped_refptr<VertexAttribManager> attrib_manager) const {
  // This is expected to be called only for VAO with service_id 0,
  // either to restore the default VAO or a virtual VAO with service_id 0.
  GLuint vao_service_id = attrib_manager->service_id();
  DCHECK(vao_service_id == 0);

  // Bind VAO if supported.
  if (feature_info_->feature_flags().native_vertex_array_object)
    glBindVertexArrayOES(vao_service_id);

  // Restore vertex attrib arrays.
  for (size_t attrib_index = 0; attrib_index < attrib_manager->num_attribs();
       ++attrib_index) {
    const VertexAttrib* attrib = attrib_manager->GetVertexAttrib(attrib_index);

    // Restore vertex array.
    Buffer* buffer = attrib->buffer();
    GLuint buffer_service_id = buffer ? buffer->service_id() : 0;
    glBindBuffer(GL_ARRAY_BUFFER, buffer_service_id);
    const void* ptr = reinterpret_cast<const void*>(attrib->offset());
    glVertexAttribPointer(attrib_index,
                          attrib->size(),
                          attrib->type(),
                          attrib->normalized(),
                          attrib->gl_stride(),
                          ptr);

    // Restore attrib divisor if supported.
    if (feature_info_->feature_flags().angle_instanced_arrays)
      glVertexAttribDivisorANGLE(attrib_index, attrib->divisor());

    // Never touch vertex attribute 0's state (in particular, never
    // disable it) when running on desktop GL because it will never be
    // re-enabled.
    if (attrib_index != 0 ||
        gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2) {
      if (attrib->enabled()) {
        glEnableVertexAttribArray(attrib_index);
      } else {
        glDisableVertexAttribArray(attrib_index);
      }
    }
  }
}

void ContextState::RestoreVertexAttribs() const {
  // Restore Vertex Attrib Arrays
  // TODO: This if should not be needed. RestoreState is getting called
  // before GLES2Decoder::Initialize which is a bug.
  if (vertex_attrib_manager.get()) {
    // Restore VAOs.
    if (feature_info_->feature_flags().native_vertex_array_object) {
      // If default VAO is still using shared id 0 instead of unique ids
      // per-context, default VAO state must be restored.
      GLuint default_vao_service_id =
          default_vertex_attrib_manager->service_id();
      if (default_vao_service_id == 0)
        RestoreVertexAttribArrays(default_vertex_attrib_manager);

      // Restore the current VAO binding, unless it's the same as the
      // default above.
      GLuint curr_vao_service_id = vertex_attrib_manager->service_id();
      if (curr_vao_service_id != 0)
        glBindVertexArrayOES(curr_vao_service_id);
    } else {
      // If native VAO isn't supported, emulated VAOs are used.
      // Restore to the currently bound VAO.
      RestoreVertexAttribArrays(vertex_attrib_manager);
    }
  }

  // glVertexAttrib4fv aren't part of VAO state and must be restored.
  RestoreVertexAttribValues();
}

void ContextState::RestoreGlobalState(const ContextState* prev_state) const {
  InitCapabilities(prev_state);
  InitState(prev_state);
}

void ContextState::RestoreState(const ContextState* prev_state) {
  RestoreAllTextureUnitBindings(prev_state);
  RestoreVertexAttribs();
  RestoreBufferBindings();
  RestoreRenderbufferBindings();
  RestoreProgramBindings();
  RestoreGlobalState(prev_state);
}

ErrorState* ContextState::GetErrorState() {
  return error_state_.get();
}

void ContextState::EnableDisable(GLenum pname, bool enable) const {
  if (pname == GL_PRIMITIVE_RESTART_FIXED_INDEX) {
    if (feature_info_->feature_flags().emulate_primitive_restart_fixed_index)
      pname = GL_PRIMITIVE_RESTART;
  }
  if (enable) {
    glEnable(pname);
  } else {
    glDisable(pname);
  }
}

// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/service/context_state_impl_autogen.h"

}  // namespace gles2
}  // namespace gpu


