// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Data structures for representing parts of Chromium's composited layer tree
// and a function to load it from the JSON configuration file

#ifndef GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_TREE_H_
#define GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_TREE_H_

#include <string>
#include <vector>

#include "base/compiler_specific.h"
#include "base/memory/scoped_vector.h"
#include "gpu/tools/compositor_model_bench/shaders.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"

// These are fairly arbitrary values based on how big my actual browser
// window was.
const int WINDOW_WIDTH = 1609;
const int WINDOW_HEIGHT = 993;

struct Tile {
  int x;
  int y;
  int texID;
};

struct Texture {
  int texID;
  int height;
  int width;
  GLenum format;
};

GLenum TextureFormatFromString(std::string format);
const char* TextureFormatName(GLenum format);
int FormatBytesPerPixel(GLenum format);

class RenderNodeVisitor;

class RenderNode {
 public:
  RenderNode();
  virtual ~RenderNode();
  virtual void Accept(RenderNodeVisitor* v);

  int layerID() {
    return layerID_;
  }

  void set_layerID(int id) {
    layerID_ = id;
  }

  int width() {
    return width_;
  }

  void set_width(int width) {
    width_ = width;
  }

  int height() {
    return height_;
  }

  void set_height(int height) {
    height_ = height;
  }

  bool drawsContent() {
    return drawsContent_;
  }

  void set_drawsContent(bool draws) {
    drawsContent_ = draws;
  }

  void set_targetSurface(int surface) {
    targetSurface_ = surface;
  }

  float* transform() {
    return transform_;
  }

  void set_transform(float* mat) {
    memcpy(reinterpret_cast<void*>(transform_),
           reinterpret_cast<void*>(mat),
           16 * sizeof(transform_[0]));
  }

  void add_tile(Tile t) {
    tiles_.push_back(t);
  }

  size_t num_tiles() {
    return tiles_.size();
  }

  Tile* tile(size_t index) {
    return &tiles_[index];
  }

  int tile_width() {
    return tile_width_;
  }

  void set_tile_width(int width) {
    tile_width_ = width;
  }

  int tile_height() {
    return tile_height_;
  }

  void set_tile_height(int height) {
    tile_height_ = height;
  }

 private:
  int layerID_;
  int width_;
  int height_;
  bool drawsContent_;
  int targetSurface_;
  float transform_[16];
  std::vector<Tile> tiles_;
  int tile_width_;
  int tile_height_;
};

class ContentLayerNode : public RenderNode {
 public:
  ContentLayerNode();
  ~ContentLayerNode() override;
  void Accept(RenderNodeVisitor* v) override;

  void set_skipsDraw(bool skips) {
    skipsDraw_ = skips;
  }

  void add_child(RenderNode* child) {
    children_.push_back(child);
  }

 private:
  ScopedVector<RenderNode> children_;
  bool skipsDraw_;
};

class CCNode : public RenderNode {
 public:
  CCNode();
  ~CCNode() override;

  void Accept(RenderNodeVisitor* v) override;

  ShaderID vertex_shader() {
    return vertex_shader_;
  }

  void set_vertex_shader(ShaderID shader) {
    vertex_shader_ = shader;
  }

  ShaderID fragment_shader() {
    return fragment_shader_;
  }

  void set_fragment_shader(ShaderID shader) {
    fragment_shader_ = shader;
  }

  void add_texture(Texture t) {
    textures_.push_back(t);
  }

  size_t num_textures() {
    return textures_.size();
  }

  Texture* texture(size_t index) {
    return &textures_[index];
  }

 private:
  ShaderID vertex_shader_;
  ShaderID fragment_shader_;
  std::vector<Texture> textures_;
};

class RenderNodeVisitor {
 public:
  virtual ~RenderNodeVisitor();

  virtual void BeginVisitRenderNode(RenderNode* v) = 0;
  virtual void BeginVisitContentLayerNode(ContentLayerNode* v);
  virtual void BeginVisitCCNode(CCNode* v);
  virtual void EndVisitRenderNode(RenderNode* v);
  virtual void EndVisitContentLayerNode(ContentLayerNode* v);
  virtual void EndVisitCCNode(CCNode* v);
};

RenderNode* BuildRenderTreeFromFile(const base::FilePath& path);

#endif  // GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_TREE_H_

