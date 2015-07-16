// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/tools/compositor_model_bench/shaders.h"

#include <algorithm>

#include "gpu/tools/compositor_model_bench/render_model_utils.h"
#include "gpu/tools/compositor_model_bench/render_tree.h"

using std::min;

static const int kPositionLocation = 0;
static const int kTexCoordLocation = 1;

static unsigned g_quad_vertices_vbo;
static unsigned g_quad_elements_vbo;

// Store a pointer to the transform matrix of the active layer (the complete
// transform isn't build until we draw the quad; then we can apply
// translation/scaling/projection)
static float* g_current_layer_transform;

// In addition to the transform, store other useful information about tiled
// layers that we'll need to render each tile's quad
static float g_current_tile_layer_width;
static float g_current_tile_layer_height;
static float g_current_tile_width;
static float g_current_tile_height;

static const float yuv2RGB[9] = {
  1.164f, 1.164f, 1.164f,
  0.f, -.391f, 2.018f,
  1.596f, -.813f, 0.f
};

// Store shader programs in a sparse array so that they can be addressed easily.
static int g_program_objects[SHADER_ID_MAX*SHADER_ID_MAX];
static int g_active_index = -1;

///////////////////////////////////////////////////////////////////////////////
//              L        R           B          T   N  F
//      glOrtho(0, WINDOW_WIDTH, WINDOW_HEIGHT, 0, -1, 1);   // column major

static float g_projection_matrix[] = {
  2.0 / WINDOW_WIDTH, 0.0, 0.0, 0.0,
  0.0, 2.0 / -WINDOW_HEIGHT, 0.0, 0.0,
  0.0, 0.0, -1.0, 0.0,
  -1.0, 1.0, 0.0, 1.0
};

#define ADDR(i, j) (i*4 + j) /* column major */
static void Project(const float* v, float* p) {
  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      p[ADDR(i, j)] = 0;
      for (int k = 0; k < 4; ++k) {
        p[ADDR(i, j)] += g_projection_matrix[ADDR(k, i)] * v[ADDR(j, k)];
      }
    }
  }
}

static void Scale(const float* in, float* out, float sx, float sy, float sz) {
  for (int i = 0; i < 4; ++i)
    out[i] = in[i] * sx;
  for (int j = 4; j < 8; ++j)
    out[j] = in[j] * sy;
  for (int k = 8; k < 12; ++k)
    out[k] = in[k] * sz;
  for (int l = 12; l < 16; ++l)
    out[l] = in[l];
}

static void TranslateInPlace(float* m, float tx, float ty, float tz) {
  m[12] += tx;
  m[13] += ty;
  m[14] += tz;
}

///////////////////////////////////////////////////////////////////////////////

ShaderID ShaderIDFromString(std::string name) {
  if (name == "VertexShaderPosTexYUVStretch")
    return VERTEX_SHADER_POS_TEX_YUV_STRETCH;
  if (name == "VertexShaderPosTex")
    return VERTEX_SHADER_POS_TEX;
  if (name == "VertexShaderPosTexTransform")
    return VERTEX_SHADER_POS_TEX_TRANSFORM;
  if (name == "FragmentShaderYUVVideo")
    return FRAGMENT_SHADER_YUV_VIDEO;
  if (name == "FragmentShaderRGBATexFlipAlpha")
    return FRAGMENT_SHADER_RGBA_TEX_FLIP_ALPHA;
  if (name == "FragmentShaderRGBATexAlpha")
    return FRAGMENT_SHADER_RGBA_TEX_ALPHA;
  return SHADER_UNRECOGNIZED;
}

std::string ShaderNameFromID(ShaderID id) {
  switch (id) {
    case VERTEX_SHADER_POS_TEX_YUV_STRETCH:
      return "VertexShaderPosTexYUVStretch";
    case VERTEX_SHADER_POS_TEX:
      return "VertexShaderPosTex";
    case VERTEX_SHADER_POS_TEX_TRANSFORM:
      return "VertexShaderPosTexTransform";
    case FRAGMENT_SHADER_YUV_VIDEO:
      return "FragmentShaderYUVVideo";
    case FRAGMENT_SHADER_RGBA_TEX_FLIP_ALPHA:
      return "FragmentShaderRGBATexFlipAlpha";
    case FRAGMENT_SHADER_RGBA_TEX_ALPHA:
      return "FragmentShaderRGBATexAlpha";
    default:
      return "(unknown shader)";
  }
}

#define SHADER0(Src) #Src
#define SHADER(Src) SHADER0(Src)

const char* GetShaderSource(ShaderID shader) {
  switch (shader) {
    case VERTEX_SHADER_POS_TEX_YUV_STRETCH:
      return SHADER(
        #ifdef GL_ES
        precision mediump float;
        #endif
        attribute vec4 a_position;
        attribute vec2 a_texCoord;
        uniform mat4 matrix;
        varying vec2 y_texCoord;
        varying vec2 uv_texCoord;
        uniform float y_widthScaleFactor;
        uniform float uv_widthScaleFactor;
        void main() {
          gl_Position = matrix * a_position;
          y_texCoord = vec2(y_widthScaleFactor * a_texCoord.x,
            a_texCoord.y);
          uv_texCoord = vec2(uv_widthScaleFactor * a_texCoord.x,
            a_texCoord.y);
        });
      break;
    case VERTEX_SHADER_POS_TEX:
      return SHADER(
        attribute vec4 a_position;
        attribute vec2 a_texCoord;
        uniform mat4 matrix;
        varying vec2 v_texCoord;
        void main() {
          gl_Position = matrix * a_position;
          v_texCoord = a_texCoord;
        });
      break;
    case VERTEX_SHADER_POS_TEX_TRANSFORM:
      return SHADER(
        attribute vec4 a_position;
        attribute vec2 a_texCoord;
        uniform mat4 matrix;
        uniform vec4 texTransform;
        varying vec2 v_texCoord;
        void main() {
          gl_Position = matrix * a_position;
          v_texCoord = a_texCoord*texTransform.zw + texTransform.xy;
        });
      break;
    case FRAGMENT_SHADER_YUV_VIDEO:
      return SHADER(
        #ifdef GL_ES
        precision mediump float;
        precision mediump int;
        #endif
        varying vec2 y_texCoord;
        varying vec2 uv_texCoord;
        uniform sampler2D y_texture;
        uniform sampler2D u_texture;
        uniform sampler2D v_texture;
        uniform float alpha;
        uniform vec3 yuv_adj;
        uniform mat3 cc_matrix;
        void main() {
          float y_raw = texture2D(y_texture, y_texCoord).x;
          float u_unsigned = texture2D(u_texture, uv_texCoord).x;
          float v_unsigned = texture2D(v_texture, uv_texCoord).x;
          vec3 yuv = vec3(y_raw, u_unsigned, v_unsigned) + yuv_adj;
          vec3 rgb = cc_matrix * yuv;
          gl_FragColor = vec4(rgb, 1.0) * alpha;
        });
      break;
    case FRAGMENT_SHADER_RGBA_TEX_FLIP_ALPHA:
      return SHADER(
        #ifdef GL_ES
        precision mediump float;
        #endif
        varying vec2 v_texCoord;
        uniform sampler2D s_texture;
        uniform float alpha;
        void main() {
          vec4 texColor = texture2D(s_texture,
            vec2(v_texCoord.x, 1.0 - v_texCoord.y));
          gl_FragColor = vec4(texColor.x,
            texColor.y,
            texColor.z,
            texColor.w) * alpha;
        });
      break;
    case FRAGMENT_SHADER_RGBA_TEX_ALPHA:
      return SHADER(
        #ifdef GL_ES
        precision mediump float;
        #endif
        varying vec2 v_texCoord;
        uniform sampler2D s_texture;
        uniform float alpha;
        void main() {
          vec4 texColor = texture2D(s_texture, v_texCoord);
          gl_FragColor = texColor * alpha;
        });
      break;
    default:
      printf("Shader source requested for unknown shader\n");
      return "";
  }
}

int GetProgramIdx(ShaderID v, ShaderID f) {
  return v * SHADER_ID_MAX + f;
}

static void ReportAnyShaderCompilationErrors(GLuint shader, ShaderID id) {
  GLint status;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
  if (status)
    return;
  // Get the length of the log string
  GLsizei length;
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
  scoped_ptr<GLchar[]> log(new GLchar[length+1]);
  glGetShaderInfoLog(shader, length, NULL, log.get());
  LOG(ERROR) << log.get() << " in shader " << ShaderNameFromID(id);
}

static int ActivateShader(ShaderID v, ShaderID f, float* layer_transform) {
  int program_index = GetProgramIdx(v, f);
  if (!g_program_objects[program_index]) {
    g_program_objects[program_index] = glCreateProgramObjectARB();
    GLenum vs = glCreateShaderObjectARB(GL_VERTEX_SHADER);
    GLenum fs = glCreateShaderObjectARB(GL_FRAGMENT_SHADER);
    const char* vs_source = GetShaderSource(v);
    const char* fs_source = GetShaderSource(f);
    glShaderSourceARB(vs, 1, &vs_source, 0);
    glShaderSourceARB(fs, 1, &fs_source, 0);
    glCompileShaderARB(vs);
    ReportAnyShaderCompilationErrors(vs, v);
    glCompileShaderARB(fs);
    ReportAnyShaderCompilationErrors(fs, f);
    glAttachObjectARB(g_program_objects[program_index], vs);
    glAttachObjectARB(g_program_objects[program_index], fs);
    glBindAttribLocationARB(g_program_objects[program_index],
                            kPositionLocation,
                            "a_position");
    glBindAttribLocationARB(g_program_objects[program_index],
                            kTexCoordLocation,
                            "a_texCoord");
    glLinkProgramARB(g_program_objects[program_index]);
  }
  if (g_active_index != program_index)
    glUseProgramObjectARB(g_program_objects[program_index]);
  g_active_index = program_index;

  g_current_layer_transform = layer_transform;

  return g_program_objects[program_index];
}

void ConfigAndActivateShaderForNode(CCNode* n) {
  ShaderID vs = n->vertex_shader();
  ShaderID fs = n->fragment_shader();
  float* transform = n->transform();
  int program = ActivateShader(vs, fs, transform);
  if (vs == VERTEX_SHADER_POS_TEX_YUV_STRETCH) {
    GLint y_scale = glGetUniformLocationARB(program, "y_widthScaleFactor");
    GLint uv_scale = glGetUniformLocationARB(program, "uv_widthScaleFactor");
    glUniform1fARB(y_scale, 1.0);
    glUniform1fARB(uv_scale, 1.0);
  }
  if (vs == VERTEX_SHADER_POS_TEX_TRANSFORM) {
    GLint texTrans = glGetUniformLocationARB(program, "texTransform");
    glUniform4fARB(texTrans, 0.0, 0.0, 0.0, 0.0);
  }
  if (fs == FRAGMENT_SHADER_RGBA_TEX_FLIP_ALPHA) {
    DCHECK_EQ(n->num_textures(), 1u);
    DCHECK_NE(n->texture(0)->texID, -1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, n->texture(0)->texID);
    int sTexLoc = glGetUniformLocationARB(program, "s_texture");
    glUniform1iARB(sTexLoc, 0);
  }
  if (fs == FRAGMENT_SHADER_YUV_VIDEO) {
    DCHECK_EQ(n->num_textures(), 3u);
    DCHECK_NE(n->texture(0)->texID, -1);
    DCHECK_NE(n->texture(1)->texID, -1);
    DCHECK_NE(n->texture(2)->texID, -1);
    // Bind Y tex.
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, n->texture(0)->texID);
    int yTexLoc = glGetUniformLocationARB(program, "y_texture");
    glUniform1iARB(yTexLoc, 0);
    // Bind U tex.
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, n->texture(1)->texID);
    int uTexLoc = glGetUniformLocationARB(program, "u_texture");
    glUniform1iARB(uTexLoc, 1);
    // Bind V tex.
    glActiveTexture(GL_TEXTURE0 + 2);
    glBindTexture(GL_TEXTURE_2D, n->texture(2)->texID);
    int vTexLoc = glGetUniformLocationARB(program, "v_texture");
    glUniform1iARB(vTexLoc, 2);
    // Set YUV offset.
    int yuvAdjLoc = glGetUniformLocationARB(program, "yuv_adj");
    glUniform3fARB(yuvAdjLoc, -0.0625f, -0.5f, -0.5f);
    // Set YUV matrix.
    int ccMatLoc = glGetUniformLocationARB(program, "cc_matrix");
    glUniformMatrix3fvARB(ccMatLoc, 1, false, yuv2RGB);
  }
  GLint alpha = glGetUniformLocationARB(program, "alpha");
  glUniform1fARB(alpha, 0.9);
}

void ConfigAndActivateShaderForTiling(ContentLayerNode* n) {
  int program = ActivateShader(VERTEX_SHADER_POS_TEX_TRANSFORM,
                               FRAGMENT_SHADER_RGBA_TEX_ALPHA,
                               n->transform());
  GLint texTrans = glGetUniformLocationARB(program, "texTransform");
  glUniform4fARB(texTrans, 0.0, 0.0, 1.0, 1.0);
  GLint alpha = glGetUniformLocationARB(program, "alpha");
  glUniform1fARB(alpha, 0.9);

  g_current_tile_layer_width = n->width();
  g_current_tile_layer_height = n->height();
  g_current_tile_width = n->tile_width();
  g_current_tile_height = n->tile_height();
}

void DeleteShaders() {
  g_active_index = -1;
  glUseProgramObjectARB(0);
  for (int i = 0; i < SHADER_ID_MAX*SHADER_ID_MAX; ++i) {
    if (g_program_objects[i]) {
      glDeleteObjectARB(g_program_objects[i]);
    }
    g_program_objects[i] = 0;
  }
}

void InitBuffers() {
  // Vertex positions and texture coordinates for the 4 corners of a 1x1 quad.
  float vertices[] = { -0.5f,  0.5f, 0.0f, 0.0f,  1.0f,
                       -0.5f, -0.5f, 0.0f, 0.0f,  0.0f,
                       0.5f,  -0.5f, 0.0f, 1.0f,  0.0f,
                       0.5f,   0.5f, 0.0f, 1.0f,  1.0f };
  uint16_t indices[] = { 0, 1, 2, 0, 2, 3};

  glGenBuffers(1, &g_quad_vertices_vbo);
  glGenBuffers(1, &g_quad_elements_vbo);
  glBindBuffer(GL_ARRAY_BUFFER, g_quad_vertices_vbo);
  glBufferData(GL_ARRAY_BUFFER,
               sizeof(vertices),
               vertices,
               GL_STATIC_DRAW);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_quad_elements_vbo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER,
               sizeof(indices),
               indices,
               GL_STATIC_DRAW);
}

void BeginFrame() {
  glBindBuffer(GL_ARRAY_BUFFER, g_quad_vertices_vbo);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_quad_elements_vbo);
  unsigned offset = 0;
  glVertexAttribPointer(kPositionLocation,
                        3,
                        GL_FLOAT,
                        false,
                        5 * sizeof(float),
                        reinterpret_cast<void*>(offset));
  offset += 3 * sizeof(float);
  glVertexAttribPointer(kTexCoordLocation,
                        2,
                        GL_FLOAT,
                        false,
                        5 * sizeof(float),
                        reinterpret_cast<void*>(offset));
  glEnableVertexAttribArray(kPositionLocation);
  glEnableVertexAttribArray(kTexCoordLocation);
}

void DrawQuad(float width, float height) {
  float mv_transform[16];
  float proj_transform[16];
  Scale(g_current_layer_transform, mv_transform, width, height, 1.0);
  Project(mv_transform, proj_transform);
  GLint mat = glGetUniformLocationARB(g_program_objects[g_active_index],
                                      "matrix");
  glUniformMatrix4fvARB(mat, 1, GL_TRUE, proj_transform);

  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

void DrawTileQuad(GLuint texID, int x, int y) {
  float left = g_current_tile_width*x;
  float top = g_current_tile_height*y;
  if (left > g_current_tile_layer_width || top > g_current_tile_layer_height)
    return;

  float right = min(left+g_current_tile_width, g_current_tile_layer_width);
  float bottom = min(top+g_current_tile_height, g_current_tile_layer_height);
  float width = right-left;
  float height = bottom-top;

  int prog = g_program_objects[g_active_index];

  // Scale the texture if the full tile rectangle doesn't get drawn.
  float u_scale = width / g_current_tile_width;
  float v_scale = height / g_current_tile_height;
  GLint texTrans = glGetUniformLocationARB(prog, "texTransform");
  glUniform4fARB(texTrans, 0.0, 0.0, u_scale, v_scale);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texID);
  int texLoc = glGetUniformLocationARB(prog, "s_texture");
  glUniform1iARB(texLoc, 0);

  float mv_transform[16];
  float proj_transform[16];
  Scale(g_current_layer_transform, mv_transform, width, height, 1.0);

  // We have to position the tile by its center.
  float center_x = (left+right)/2 - g_current_tile_layer_width/2;
  float center_y = (top+bottom)/2 - g_current_tile_layer_height/2;
  TranslateInPlace(mv_transform, center_x, center_y, 0.0);

  Project(mv_transform, proj_transform);
  GLint mat = glGetUniformLocationARB(prog, "matrix");
  glUniformMatrix4fvARB(mat, 1, GL_TRUE, proj_transform);

  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

