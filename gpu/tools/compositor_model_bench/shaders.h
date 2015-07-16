// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Shaders from Chromium and an interface for setting them up

#ifndef GPU_TOOLS_COMPOSITOR_MODEL_BENCH_SHADERS_H_
#define GPU_TOOLS_COMPOSITOR_MODEL_BENCH_SHADERS_H_

#include <string>

// Forward declarations.
class CCNode;
class ContentLayerNode;

typedef unsigned int GLuint;

enum ShaderID {
  SHADER_UNRECOGNIZED = 0,
  VERTEX_SHADER_POS_TEX_YUV_STRETCH,
  VERTEX_SHADER_POS_TEX,
  VERTEX_SHADER_POS_TEX_TRANSFORM,
  FRAGMENT_SHADER_YUV_VIDEO,
  FRAGMENT_SHADER_RGBA_TEX_FLIP_ALPHA,
  FRAGMENT_SHADER_RGBA_TEX_ALPHA,
  SHADER_ID_MAX
};

ShaderID ShaderIDFromString(std::string name);
std::string ShaderNameFromID(ShaderID id);

void ConfigAndActivateShaderForNode(CCNode* n);

// Call once to set up the parameters for an entire tiled layer, then use
// DrawTileQuad for each tile to be drawn.
void ConfigAndActivateShaderForTiling(ContentLayerNode* n);

// One-off function to set up global VBO's that will be used every time
// we want to draw a quad.
void InitBuffers();

// Per-frame initialization of the VBO's (to replicate behavior in Chrome.)
void BeginFrame();

// Draw the quad in those VBO's.
void DrawQuad(float width, float height);

// Draw the quad in those VBO's for an individual tile within a tiled layer.
// x and y give the 2D index of the tile.
void DrawTileQuad(GLuint texID, int x, int y);

#endif  // GPU_TOOLS_COMPOSITOR_MODEL_BENCH_SHADERS_H_
