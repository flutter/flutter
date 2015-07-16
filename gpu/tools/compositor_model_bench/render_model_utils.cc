// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Whole-tree processing that's likely to be helpful in multiple render models.

#include "gpu/tools/compositor_model_bench/render_model_utils.h"

#include <cstdlib>
#include <map>
#include <set>
#include <vector>

#include "base/logging.h"

TextureGenerator::TextureGenerator(RenderNode* root)
    : stage_(DiscoveryStage),
      images_generated_(0) {
  DiscoverInputIDs(root);
  GenerateGLTexIDs();
  AssignIDMapping();
  WriteOutNewIDs(root);
  AllocateImageArray();
  BuildTextureImages(root);
}

TextureGenerator::~TextureGenerator() {
  if (tex_ids_.get()) {
    glDeleteTextures(discovered_ids_.size(), tex_ids_.get());
  }
}

void TextureGenerator::BeginVisitRenderNode(RenderNode* node) {
  for (size_t n = 0; n < node->num_tiles(); ++n) {
    Tile* i = node->tile(n);
    HandleTexture(&i->texID,
                  node->tile_width(),
                  node->tile_height(),
                  GL_RGBA);
  }
}

void TextureGenerator::BeginVisitCCNode(CCNode* node) {
  for (size_t n = 0; n < node->num_textures(); ++n) {
    Texture* i = node->texture(n);
    HandleTexture(&i->texID, i->width, i->height, i->format);
  }
  BeginVisitRenderNode(node);
}

void TextureGenerator::DiscoverInputIDs(RenderNode* root) {
  // Pass 1: see which texture ID's have been used.
  stage_ = DiscoveryStage;
  root->Accept(this);
}

void TextureGenerator::GenerateGLTexIDs() {
  int numTextures = discovered_ids_.size();
  tex_ids_.reset(new GLuint[numTextures]);
  glGenTextures(numTextures, tex_ids_.get());
}

void TextureGenerator::AssignIDMapping() {
  // In the original version of this code the assigned ID's were not
  // GL tex ID's, but newly generated consecutive ID's that indexed
  // into an array of GL tex ID's. There's no need for this and now
  // I'm instead generating the GL tex ID's upfront and assigning
  // *those* in the remapping -- this more accurately reflects the
  // behavior in Chromium, and it also takes out some design
  // complexity that came from the extra layer of indirection.
  // HOWEVER -- when I was assigning my own ID's before, I did some
  // clever tricks to make sure the assignation was idempotent.
  // Instead of going to even more clever lengths to preserve that
  // property, I now just assume that the visitor will encounter each
  // node (and consequently each texture) exactly once during a
  // traversal of the tree -- this shouldn't be a hard guarantee
  // to make.
  int j = 0;
  typedef std::set<int>::iterator id_itr;
  for (id_itr i = discovered_ids_.begin();
       i != discovered_ids_.end();
       ++i, ++j) {
    remapped_ids_[*i] = tex_ids_[j];
  }
}

void TextureGenerator::WriteOutNewIDs(RenderNode* root) {
  // Pass 2: write the new texture ID's back into the texture objects.
  stage_ = RemappingStage;
  root->Accept(this);
}

void TextureGenerator::AllocateImageArray() {
  image_data_.reset(new ImagePtr[discovered_ids_.size()]);
  images_generated_ = 0;
}

void TextureGenerator::BuildTextureImages(RenderNode* root) {
  // Pass 3: use the texture metadata to generate images for the
  // textures, and set up the textures for use by OpenGL. This
  // doesn't *have* to be a separate pass (it could be rolled
  // into pass 2) but I think this is more clear and performance
  // shouldn't be bad.
  stage_ = ImageGenerationStage;
  root->Accept(this);
}

void TextureGenerator::HandleTexture(int* texID,
                                     int width,
                                     int height,
                                     GLenum format) {
  if (*texID == -1)
    return;    // -1 means it's not a real texture.
  switch (stage_) {
    case DiscoveryStage:
      discovered_ids_.insert(*texID);
      break;
    case RemappingStage:
      *texID = remapped_ids_[*texID];
      break;
    case ImageGenerationStage:
      // Only handle this one if we haven't already built a
      // texture for its ID.
      if (ids_for_completed_textures_.count(*texID))
        return;
      GenerateImageForTexture(*texID, width, height, format);
      ids_for_completed_textures_.insert(*texID);
      break;
  }
}

void TextureGenerator::GenerateImageForTexture(int texID,
                                               int width,
                                               int height,
                                               GLenum format) {
  int bytes_per_pixel = FormatBytesPerPixel(format);
  DCHECK_LE(bytes_per_pixel, 4);
  int imgID = images_generated_++;
  image_data_[imgID].reset(new uint8[width*height*bytes_per_pixel]);
  // Pick random colors to use for this texture.
  uint8 random_color[4];
  for (int c = 0; c < 4; ++c) {
    random_color[c] = std::rand() % 255;
  }
  // Create the image from those colors.
  for (int x = 0; x < width; ++x) {
    for (int y = 0; y < height; ++y) {
      int pix_addr = (y * width + x) * bytes_per_pixel;
      for (int c = 0; c < bytes_per_pixel; ++c) {
        bool on = ((x/8) + (y/8)) % 2;
        uint8 v = on ? random_color[c] : ~random_color[c];
        (image_data_[imgID])[pix_addr + c] = v;
      }
      if (bytes_per_pixel == 4) {    // Randomize alpha.
        image_data_[imgID][pix_addr + 3] = std::rand() % 255;
      }
    }
  }
  // Set up GL texture.
  glBindTexture(GL_TEXTURE_2D, texID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D,
               0,
               format,
               width, height,
               0,
               format,
               GL_UNSIGNED_BYTE,
               image_data_[imgID].get());
}

