// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Whole-tree processing that's likely to be helpful in multiple render models.

#ifndef GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_MODEL_UTILS_H_
#define GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_MODEL_UTILS_H_

#include <map>
#include <set>
#include <vector>

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/tools/compositor_model_bench/render_tree.h"

// This is a visitor that runs over the tree structure that was built from the
// configuration file. It creates OpenGL textures (random checkerboards) that
// match the specifications of the original textures and overwrites the old
// texture ID's in the tree, replacing them with the matching new textures.
class TextureGenerator : public RenderNodeVisitor {
 public:
  typedef scoped_ptr<uint8[]> ImagePtr;
  typedef std::vector<Tile>::iterator tile_iter;

  explicit TextureGenerator(RenderNode* root);
  ~TextureGenerator() override;

  // RenderNodeVisitor functions look for textures and pass them
  // off to HandleTexture (which behaves appropriately depending
  // on which pass we are in.)
  void BeginVisitRenderNode(RenderNode* node) override;
  void BeginVisitCCNode(CCNode* node) override;

 private:
  enum TextureGenStage {
    DiscoveryStage,
    RemappingStage,
    ImageGenerationStage
  };

  void DiscoverInputIDs(RenderNode* root);
  void GenerateGLTexIDs();
  void AssignIDMapping();
  void WriteOutNewIDs(RenderNode* root);
  void AllocateImageArray();
  void BuildTextureImages(RenderNode* root);
  void HandleTexture(int* texID, int width, int height, GLenum format);
  void GenerateImageForTexture(int texID, int width, int height, GLenum format);

  TextureGenStage stage_;
  std::set<int> discovered_ids_;
  scoped_ptr<GLuint[]> tex_ids_;
  std::map<int, int> remapped_ids_;
  scoped_ptr<ImagePtr[]> image_data_;
  int images_generated_;
  std::set<int> ids_for_completed_textures_;
};

#endif  // GPU_TOOLS_COMPOSITOR_MODEL_BENCH_RENDER_MODEL_UTILS_H_

