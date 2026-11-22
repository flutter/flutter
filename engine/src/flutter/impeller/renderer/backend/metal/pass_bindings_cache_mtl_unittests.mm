// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Metal/Metal.h>

#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/metal/pass_bindings_cache_mtl.h"

// Stands in for a render command encoder, counting the calls the cache lets
// through. Only the selectors the cache uses are implemented.
@interface FakeRenderEncoder : NSObject
@property(nonatomic) int buffers;
@property(nonatomic) int offsets;
@property(nonatomic) int textures;
@property(nonatomic) int samplers;
@end

@implementation FakeRenderEncoder
- (void)setVertexBuffer:(id)buffer
                 offset:(NSUInteger)offset
                atIndex:(NSUInteger)index {
  self.buffers++;
}
- (void)setFragmentBuffer:(id)buffer
                   offset:(NSUInteger)offset
                  atIndex:(NSUInteger)index {
  self.buffers++;
}
- (void)setVertexBufferOffset:(NSUInteger)offset atIndex:(NSUInteger)index {
  self.offsets++;
}
- (void)setFragmentBufferOffset:(NSUInteger)offset atIndex:(NSUInteger)index {
  self.offsets++;
}
- (void)setVertexTexture:(id)texture atIndex:(NSUInteger)index {
  self.textures++;
}
- (void)setFragmentTexture:(id)texture atIndex:(NSUInteger)index {
  self.textures++;
}
- (void)setVertexSamplerState:(id)sampler atIndex:(NSUInteger)index {
  self.samplers++;
}
- (void)setFragmentSamplerState:(id)sampler atIndex:(NSUInteger)index {
  self.samplers++;
}
@end

namespace impeller {
namespace testing {

namespace {

// The cache only compares these, so any object will do.
id<MTLBuffer> Buffer(NSObject* object) {
  return (id<MTLBuffer>)object;
}

id<MTLTexture> Texture(NSObject* object) {
  return (id<MTLTexture>)object;
}

id<MTLSamplerState> Sampler(NSObject* object) {
  return (id<MTLSamplerState>)object;
}

}  // namespace

class PassBindingsCacheMTLTest : public ::testing::Test {
 protected:
  void SetUp() override {
    encoder_ = [[FakeRenderEncoder alloc] init];
    cache_.SetEncoder((id<MTLRenderCommandEncoder>)encoder_);
  }

  FakeRenderEncoder* encoder_;
  PassBindingsCacheMTL cache_;
  NSObject* first_ = [[NSObject alloc] init];
  NSObject* second_ = [[NSObject alloc] init];
};

TEST_F(PassBindingsCacheMTLTest, RepeatedBuffersAreFiltered) {
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 0, 0, Buffer(first_)));
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 0, 0, Buffer(first_)));
  EXPECT_EQ(encoder_.buffers, 1);
  EXPECT_EQ(encoder_.offsets, 0);

  // Only the offset changed.
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 0, 16, Buffer(first_)));
  EXPECT_EQ(encoder_.buffers, 1);
  EXPECT_EQ(encoder_.offsets, 1);

  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 0, 16, Buffer(second_)));
  EXPECT_EQ(encoder_.buffers, 2);
}

TEST_F(PassBindingsCacheMTLTest, StagesAndIndicesAreIndependent) {
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 0, 0, Buffer(first_)));
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kFragment, 0, 0, Buffer(first_)));
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, 1, 0, Buffer(first_)));
  EXPECT_EQ(encoder_.buffers, 3);

  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kVertex, 0, Texture(first_)));
  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kFragment, 0, Texture(first_)));
  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kFragment, 0, Texture(first_)));
  EXPECT_EQ(encoder_.textures, 2);

  EXPECT_TRUE(cache_.SetSampler(ShaderStage::kVertex, 0, Sampler(first_)));
  EXPECT_TRUE(cache_.SetSampler(ShaderStage::kFragment, 0, Sampler(first_)));
  EXPECT_TRUE(cache_.SetSampler(ShaderStage::kFragment, 0, Sampler(first_)));
  EXPECT_EQ(encoder_.samplers, 2);
}

// Metal allows more textures than the cache holds. They must still be bound.
TEST_F(PassBindingsCacheMTLTest, BindingsPastTheCacheStillReachTheEncoder) {
  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kFragment, 100, Texture(first_)));
  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kFragment, 100, Texture(first_)));
  EXPECT_EQ(encoder_.textures, 2);
}

TEST_F(PassBindingsCacheMTLTest, OptimizedOutBindingsAreSkipped) {
  EXPECT_TRUE(cache_.SetBuffer(ShaderStage::kVertex, kOptimizedOutBinding, 0,
                               Buffer(first_)));
  EXPECT_TRUE(cache_.SetTexture(ShaderStage::kFragment, kOptimizedOutBinding,
                                Texture(first_)));
  EXPECT_TRUE(cache_.SetSampler(ShaderStage::kFragment, kOptimizedOutBinding,
                                Sampler(first_)));
  EXPECT_EQ(encoder_.buffers, 0);
  EXPECT_EQ(encoder_.textures, 0);
  EXPECT_EQ(encoder_.samplers, 0);
}

TEST_F(PassBindingsCacheMTLTest, OtherStagesAreRejected) {
  ScopedValidationDisable disable_validation;
  EXPECT_FALSE(cache_.SetBuffer(ShaderStage::kCompute, 0, 0, Buffer(first_)));
  EXPECT_FALSE(cache_.SetTexture(ShaderStage::kCompute, 0, Texture(first_)));
  EXPECT_FALSE(cache_.SetSampler(ShaderStage::kCompute, 0, Sampler(first_)));
}

}  // namespace testing
}  // namespace impeller
