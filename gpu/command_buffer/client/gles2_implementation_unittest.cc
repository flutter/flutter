// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests for GLES2Implementation.

#include "gpu/command_buffer/client/gles2_implementation.h"

#include <limits>

#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>
#include <GLES3/gl3.h>
#include "base/compiler_specific.h"
#include "gpu/command_buffer/client/client_test_helper.h"
#include "gpu/command_buffer/client/program_info_manager.h"
#include "gpu/command_buffer/client/transfer_buffer.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gmock/include/gmock/gmock.h"

#if !defined(GLES2_SUPPORT_CLIENT_SIDE_ARRAYS)
#define GLES2_SUPPORT_CLIENT_SIDE_ARRAYS
#endif

using testing::_;
using testing::AtLeast;
using testing::AnyNumber;
using testing::DoAll;
using testing::InSequence;
using testing::Invoke;
using testing::Mock;
using testing::Sequence;
using testing::StrictMock;
using testing::Truly;
using testing::Return;

namespace gpu {
namespace gles2 {

ACTION_P2(SetMemory, dst, obj) {
  memcpy(dst, &obj, sizeof(obj));
}

ACTION_P3(SetMemoryFromArray, dst, array, size) {
  memcpy(dst, array, size);
}

// Used to help set the transfer buffer result to SizedResult of a single value.
template <typename T>
class SizedResultHelper {
 public:
  explicit SizedResultHelper(T result)
      : size_(sizeof(result)) {
    memcpy(result_, &result, sizeof(T));
  }

 private:
  uint32 size_;
  char result_[sizeof(T)];
};

// Struct to make it easy to pass a vec4 worth of floats.
struct FourFloats {
  FourFloats(float _x, float _y, float _z, float _w)
      : x(_x),
        y(_y),
        z(_z),
        w(_w) {
  }

  float x;
  float y;
  float z;
  float w;
};

#pragma pack(push, 1)
// Struct that holds 7 characters.
struct Str7 {
  char str[7];
};
#pragma pack(pop)

class MockTransferBuffer : public TransferBufferInterface {
 public:
  struct ExpectedMemoryInfo {
    uint32 offset;
    int32 id;
    uint8* ptr;
  };

  MockTransferBuffer(
      CommandBuffer* command_buffer,
      unsigned int size,
      unsigned int result_size,
      unsigned int alignment,
      bool initialize_fail)
      : command_buffer_(command_buffer),
        size_(size),
        result_size_(result_size),
        alignment_(alignment),
        actual_buffer_index_(0),
        expected_buffer_index_(0),
        last_alloc_(NULL),
        expected_offset_(result_size),
        actual_offset_(result_size),
        initialize_fail_(initialize_fail) {
    // We have to allocate the buffers here because
    // we need to know their address before GLES2Implementation::Initialize
    // is called.
    for (int ii = 0; ii < kNumBuffers; ++ii) {
      buffers_[ii] = command_buffer_->CreateTransferBuffer(
          size_ + ii * alignment_,
          &buffer_ids_[ii]);
      EXPECT_NE(-1, buffer_ids_[ii]);
    }
  }

  ~MockTransferBuffer() override {}

  bool Initialize(unsigned int starting_buffer_size,
                  unsigned int result_size,
                  unsigned int /* min_buffer_size */,
                  unsigned int /* max_buffer_size */,
                  unsigned int alignment,
                  unsigned int size_to_flush) override;
  int GetShmId() override;
  void* GetResultBuffer() override;
  int GetResultOffset() override;
  void Free() override;
  bool HaveBuffer() const override;
  void* AllocUpTo(unsigned int size, unsigned int* size_allocated) override;
  void* Alloc(unsigned int size) override;
  RingBuffer::Offset GetOffset(void* pointer) const override;
  void FreePendingToken(void* p, unsigned int /* token */) override;

  size_t MaxTransferBufferSize() {
    return size_ - result_size_;
  }

  unsigned int RoundToAlignment(unsigned int size) {
    return (size + alignment_ - 1) & ~(alignment_ - 1);
  }

  bool InSync() {
    return expected_buffer_index_ == actual_buffer_index_ &&
           expected_offset_ == actual_offset_;
  }

  ExpectedMemoryInfo GetExpectedMemory(size_t size) {
    ExpectedMemoryInfo mem;
    mem.offset = AllocateExpectedTransferBuffer(size);
    mem.id = GetExpectedTransferBufferId();
    mem.ptr = static_cast<uint8*>(
       GetExpectedTransferAddressFromOffset(mem.offset, size));
    return mem;
  }

  ExpectedMemoryInfo GetExpectedResultMemory(size_t size) {
    ExpectedMemoryInfo mem;
    mem.offset = GetExpectedResultBufferOffset();
    mem.id = GetExpectedResultBufferId();
    mem.ptr = static_cast<uint8*>(
        GetExpectedTransferAddressFromOffset(mem.offset, size));
    return mem;
  }

 private:
  static const int kNumBuffers = 2;

  uint8* actual_buffer() const {
    return static_cast<uint8*>(buffers_[actual_buffer_index_]->memory());
  }

  uint8* expected_buffer() const {
    return static_cast<uint8*>(buffers_[expected_buffer_index_]->memory());
  }

  uint32 AllocateExpectedTransferBuffer(size_t size) {
    EXPECT_LE(size, MaxTransferBufferSize());

    // Toggle which buffer we get each time to simulate the buffer being
    // reallocated.
    expected_buffer_index_ = (expected_buffer_index_ + 1) % kNumBuffers;

    if (expected_offset_ + size > size_) {
      expected_offset_ = result_size_;
    }
    uint32 offset = expected_offset_;
    expected_offset_ += RoundToAlignment(size);

    // Make sure each buffer has a different offset.
    return offset + expected_buffer_index_ * alignment_;
  }

  void* GetExpectedTransferAddressFromOffset(uint32 offset, size_t size) {
    EXPECT_GE(offset, expected_buffer_index_ * alignment_);
    EXPECT_LE(offset + size, size_ + expected_buffer_index_ * alignment_);
    return expected_buffer() + offset;
  }

  int GetExpectedResultBufferId() {
    return buffer_ids_[expected_buffer_index_];
  }

  uint32 GetExpectedResultBufferOffset() {
    return expected_buffer_index_ * alignment_;
  }

  int GetExpectedTransferBufferId() {
    return buffer_ids_[expected_buffer_index_];
  }

  CommandBuffer* command_buffer_;
  size_t size_;
  size_t result_size_;
  uint32 alignment_;
  int buffer_ids_[kNumBuffers];
  scoped_refptr<Buffer> buffers_[kNumBuffers];
  int actual_buffer_index_;
  int expected_buffer_index_;
  void* last_alloc_;
  uint32 expected_offset_;
  uint32 actual_offset_;
  bool initialize_fail_;

  DISALLOW_COPY_AND_ASSIGN(MockTransferBuffer);
};

bool MockTransferBuffer::Initialize(
    unsigned int starting_buffer_size,
    unsigned int result_size,
    unsigned int /* min_buffer_size */,
    unsigned int /* max_buffer_size */,
    unsigned int alignment,
    unsigned int /* size_to_flush */) {
  // Just check they match.
  return size_ == starting_buffer_size &&
         result_size_ == result_size &&
         alignment_ == alignment && !initialize_fail_;
};

int MockTransferBuffer::GetShmId() {
  return buffer_ids_[actual_buffer_index_];
}

void* MockTransferBuffer::GetResultBuffer() {
  return actual_buffer() + actual_buffer_index_ * alignment_;
}

int MockTransferBuffer::GetResultOffset() {
  return actual_buffer_index_ * alignment_;
}

void MockTransferBuffer::Free() {
  NOTREACHED();
}

bool MockTransferBuffer::HaveBuffer() const {
  return true;
}

void* MockTransferBuffer::AllocUpTo(
    unsigned int size, unsigned int* size_allocated) {
  EXPECT_TRUE(size_allocated != NULL);
  EXPECT_TRUE(last_alloc_ == NULL);

  // Toggle which buffer we get each time to simulate the buffer being
  // reallocated.
  actual_buffer_index_ = (actual_buffer_index_ + 1) % kNumBuffers;

  size = std::min(static_cast<size_t>(size), MaxTransferBufferSize());
  if (actual_offset_ + size > size_) {
    actual_offset_ = result_size_;
  }
  uint32 offset = actual_offset_;
  actual_offset_ += RoundToAlignment(size);
  *size_allocated = size;

  // Make sure each buffer has a different offset.
  last_alloc_ = actual_buffer() + offset + actual_buffer_index_ * alignment_;
  return last_alloc_;
}

void* MockTransferBuffer::Alloc(unsigned int size) {
  EXPECT_LE(size, MaxTransferBufferSize());
  unsigned int temp = 0;
  void* p = AllocUpTo(size, &temp);
  EXPECT_EQ(temp, size);
  return p;
}

RingBuffer::Offset MockTransferBuffer::GetOffset(void* pointer) const {
  // Make sure each buffer has a different offset.
  return static_cast<uint8*>(pointer) - actual_buffer();
}

void MockTransferBuffer::FreePendingToken(void* p, unsigned int /* token */) {
  EXPECT_EQ(last_alloc_, p);
  last_alloc_ = NULL;
}

// API wrapper for Buffers.
class GenBuffersAPI {
 public:
  static void Gen(GLES2Implementation* gl_impl, GLsizei n, GLuint* ids) {
    gl_impl->GenBuffers(n, ids);
  }

  static void Delete(GLES2Implementation* gl_impl,
                     GLsizei n,
                     const GLuint* ids) {
    gl_impl->DeleteBuffers(n, ids);
  }
};

// API wrapper for Framebuffers.
class GenFramebuffersAPI {
 public:
  static void Gen(GLES2Implementation* gl_impl, GLsizei n, GLuint* ids) {
    gl_impl->GenFramebuffers(n, ids);
  }

  static void Delete(GLES2Implementation* gl_impl,
                     GLsizei n,
                     const GLuint* ids) {
    gl_impl->DeleteFramebuffers(n, ids);
  }
};

// API wrapper for Renderbuffers.
class GenRenderbuffersAPI {
 public:
  static void Gen(GLES2Implementation* gl_impl, GLsizei n, GLuint* ids) {
    gl_impl->GenRenderbuffers(n, ids);
  }

  static void Delete(GLES2Implementation* gl_impl,
                     GLsizei n,
                     const GLuint* ids) {
    gl_impl->DeleteRenderbuffers(n, ids);
  }
};

// API wrapper for Textures.
class GenTexturesAPI {
 public:
  static void Gen(GLES2Implementation* gl_impl, GLsizei n, GLuint* ids) {
    gl_impl->GenTextures(n, ids);
  }

  static void Delete(GLES2Implementation* gl_impl,
                     GLsizei n,
                     const GLuint* ids) {
    gl_impl->DeleteTextures(n, ids);
  }
};

class GLES2ImplementationTest : public testing::Test {
 protected:
  static const int kNumTestContexts = 2;
  static const uint8 kInitialValue = 0xBD;
  static const int32 kNumCommandEntries = 500;
  static const int32 kCommandBufferSizeBytes =
      kNumCommandEntries * sizeof(CommandBufferEntry);
  static const size_t kTransferBufferSize = 512;

  static const GLint kMaxCombinedTextureImageUnits = 8;
  static const GLint kMaxCubeMapTextureSize = 64;
  static const GLint kMaxFragmentUniformVectors = 16;
  static const GLint kMaxRenderbufferSize = 64;
  static const GLint kMaxTextureImageUnits = 8;
  static const GLint kMaxTextureSize = 128;
  static const GLint kMaxVaryingVectors = 8;
  static const GLint kMaxVertexAttribs = 8;
  static const GLint kMaxVertexTextureImageUnits = 0;
  static const GLint kMaxVertexUniformVectors = 128;
  static const GLint kNumCompressedTextureFormats = 0;
  static const GLint kNumShaderBinaryFormats = 0;
  static const GLuint kMaxTransformFeedbackSeparateAttribs = 4;
  static const GLuint kMaxUniformBufferBindings = 36;
  static const GLuint kStartId = 1024;
  static const GLuint kBuffersStartId = 1;
  static const GLuint kFramebuffersStartId = 1;
  static const GLuint kProgramsAndShadersStartId = 1;
  static const GLuint kRenderbuffersStartId = 1;
  static const GLuint kSamplersStartId = 1;
  static const GLuint kTexturesStartId = 1;
  static const GLuint kTransformFeedbacksStartId = 1;
  static const GLuint kQueriesStartId = 1;
  static const GLuint kVertexArraysStartId = 1;
  static const GLuint kValuebuffersStartId = 1;

  typedef MockTransferBuffer::ExpectedMemoryInfo ExpectedMemoryInfo;

  class TestContext {
   public:
    TestContext() : commands_(NULL), token_(0) {}

    bool Initialize(ShareGroup* share_group,
                    bool bind_generates_resource_client,
                    bool bind_generates_resource_service,
                    bool lose_context_when_out_of_memory,
                    bool transfer_buffer_initialize_fail) {
      command_buffer_.reset(new StrictMock<MockClientCommandBuffer>());
      if (!command_buffer_->Initialize())
        return false;

      transfer_buffer_.reset(
          new MockTransferBuffer(command_buffer_.get(),
                                 kTransferBufferSize,
                                 GLES2Implementation::kStartingOffset,
                                 GLES2Implementation::kAlignment,
                                 transfer_buffer_initialize_fail));

      helper_.reset(new GLES2CmdHelper(command_buffer()));
      helper_->Initialize(kCommandBufferSizeBytes);

      gpu_control_.reset(new StrictMock<MockClientGpuControl>());
      Capabilities capabilities;
      capabilities.VisitPrecisions(
          [](GLenum shader, GLenum type,
             Capabilities::ShaderPrecision* precision) {
            precision->min_range = 3;
            precision->max_range = 5;
            precision->precision = 7;
          });
      capabilities.max_combined_texture_image_units =
          kMaxCombinedTextureImageUnits;
      capabilities.max_cube_map_texture_size = kMaxCubeMapTextureSize;
      capabilities.max_fragment_uniform_vectors = kMaxFragmentUniformVectors;
      capabilities.max_renderbuffer_size = kMaxRenderbufferSize;
      capabilities.max_texture_image_units = kMaxTextureImageUnits;
      capabilities.max_texture_size = kMaxTextureSize;
      capabilities.max_varying_vectors = kMaxVaryingVectors;
      capabilities.max_vertex_attribs = kMaxVertexAttribs;
      capabilities.max_vertex_texture_image_units = kMaxVertexTextureImageUnits;
      capabilities.max_vertex_uniform_vectors = kMaxVertexUniformVectors;
      capabilities.num_compressed_texture_formats =
          kNumCompressedTextureFormats;
      capabilities.num_shader_binary_formats = kNumShaderBinaryFormats;
      capabilities.max_transform_feedback_separate_attribs =
          kMaxTransformFeedbackSeparateAttribs;
      capabilities.max_uniform_buffer_bindings = kMaxUniformBufferBindings;
      capabilities.bind_generates_resource_chromium =
          bind_generates_resource_service ? 1 : 0;
      EXPECT_CALL(*gpu_control_, GetCapabilities())
          .WillOnce(testing::Return(capabilities));

      {
        InSequence sequence;

        const bool support_client_side_arrays = true;
        gl_.reset(new GLES2Implementation(helper_.get(),
                                          share_group,
                                          transfer_buffer_.get(),
                                          bind_generates_resource_client,
                                          lose_context_when_out_of_memory,
                                          support_client_side_arrays,
                                          gpu_control_.get()));

        if (!gl_->Initialize(kTransferBufferSize,
                             kTransferBufferSize,
                             kTransferBufferSize,
                             GLES2Implementation::kNoLimit))
          return false;
      }

      helper_->CommandBufferHelper::Finish();
      ::testing::Mock::VerifyAndClearExpectations(gl_.get());

      scoped_refptr<Buffer> ring_buffer = helper_->get_ring_buffer();
      commands_ = static_cast<CommandBufferEntry*>(ring_buffer->memory()) +
                  command_buffer()->GetPutOffset();
      ClearCommands();
      EXPECT_TRUE(transfer_buffer_->InSync());

      ::testing::Mock::VerifyAndClearExpectations(command_buffer());
      return true;
    }

    void TearDown() {
      Mock::VerifyAndClear(gl_.get());
      EXPECT_CALL(*command_buffer(), OnFlush()).Times(AnyNumber());
      // For command buffer.
      EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
          .Times(AtLeast(1));
      gl_.reset();
    }

    MockClientCommandBuffer* command_buffer() const {
      return command_buffer_.get();
    }

    int GetNextToken() { return ++token_; }

    void ClearCommands() {
      scoped_refptr<Buffer> ring_buffer = helper_->get_ring_buffer();
      memset(ring_buffer->memory(), kInitialValue, ring_buffer->size());
    }

    scoped_ptr<MockClientCommandBuffer> command_buffer_;
    scoped_ptr<MockClientGpuControl> gpu_control_;
    scoped_ptr<GLES2CmdHelper> helper_;
    scoped_ptr<MockTransferBuffer> transfer_buffer_;
    scoped_ptr<GLES2Implementation> gl_;
    CommandBufferEntry* commands_;
    int token_;
  };

  GLES2ImplementationTest() : commands_(NULL) {}

  void SetUp() override;
  void TearDown() override;

  bool NoCommandsWritten() {
    scoped_refptr<Buffer> ring_buffer = helper_->get_ring_buffer();
    const uint8* cmds = reinterpret_cast<const uint8*>(ring_buffer->memory());
    const uint8* end = cmds + ring_buffer->size();
    for (; cmds < end; ++cmds) {
      if (*cmds != kInitialValue) {
        return false;
      }
    }
    return true;
  }

  QueryTracker::Query* GetQuery(GLuint id) {
    return gl_->query_tracker_->GetQuery(id);
  }

  struct ContextInitOptions {
    ContextInitOptions()
        : bind_generates_resource_client(true),
          bind_generates_resource_service(true),
          lose_context_when_out_of_memory(false),
          transfer_buffer_initialize_fail(false) {}

    bool bind_generates_resource_client;
    bool bind_generates_resource_service;
    bool lose_context_when_out_of_memory;
    bool transfer_buffer_initialize_fail;
  };

  bool Initialize(const ContextInitOptions& init_options) {
    bool success = true;
    share_group_ = new ShareGroup(init_options.bind_generates_resource_client);

    for (int i = 0; i < kNumTestContexts; i++) {
      if (!test_contexts_[i].Initialize(
              share_group_.get(),
              init_options.bind_generates_resource_client,
              init_options.bind_generates_resource_service,
              init_options.lose_context_when_out_of_memory,
              init_options.transfer_buffer_initialize_fail))
        success = false;
    }

    // Default to test context 0.
    gpu_control_ = test_contexts_[0].gpu_control_.get();
    helper_ = test_contexts_[0].helper_.get();
    transfer_buffer_ = test_contexts_[0].transfer_buffer_.get();
    gl_ = test_contexts_[0].gl_.get();
    commands_ = test_contexts_[0].commands_;
    return success;
  }

  MockClientCommandBuffer* command_buffer() const {
    return test_contexts_[0].command_buffer_.get();
  }

  int GetNextToken() { return test_contexts_[0].GetNextToken(); }

  const void* GetPut() {
    return helper_->GetSpace(0);
  }

  void ClearCommands() {
    scoped_refptr<Buffer> ring_buffer = helper_->get_ring_buffer();
    memset(ring_buffer->memory(), kInitialValue, ring_buffer->size());
  }

  size_t MaxTransferBufferSize() {
    return transfer_buffer_->MaxTransferBufferSize();
  }

  ExpectedMemoryInfo GetExpectedMemory(size_t size) {
    return transfer_buffer_->GetExpectedMemory(size);
  }

  ExpectedMemoryInfo GetExpectedResultMemory(size_t size) {
    return transfer_buffer_->GetExpectedResultMemory(size);
  }

  // Sets the ProgramInfoManager. The manager will be owned
  // by the ShareGroup.
  void SetProgramInfoManager(ProgramInfoManager* manager) {
    gl_->share_group()->set_program_info_manager(manager);
  }

  int CheckError() {
    ExpectedMemoryInfo result =
        GetExpectedResultMemory(sizeof(cmds::GetError::Result));
    EXPECT_CALL(*command_buffer(), OnFlush())
        .WillOnce(SetMemory(result.ptr, GLuint(GL_NO_ERROR)))
        .RetiresOnSaturation();
    return gl_->GetError();
  }

  const std::string& GetLastError() {
    return gl_->GetLastError();
  }

  bool GetBucketContents(uint32 bucket_id, std::vector<int8>* data) {
    return gl_->GetBucketContents(bucket_id, data);
  }

  TestContext test_contexts_[kNumTestContexts];

  scoped_refptr<ShareGroup> share_group_;
  MockClientGpuControl* gpu_control_;
  GLES2CmdHelper* helper_;
  MockTransferBuffer* transfer_buffer_;
  GLES2Implementation* gl_;
  CommandBufferEntry* commands_;
};

void GLES2ImplementationTest::SetUp() {
  ContextInitOptions init_options;
  ASSERT_TRUE(Initialize(init_options));
}

void GLES2ImplementationTest::TearDown() {
  for (int i = 0; i < kNumTestContexts; i++)
    test_contexts_[i].TearDown();
}

class GLES2ImplementationManualInitTest : public GLES2ImplementationTest {
 protected:
  void SetUp() override {}
};

class GLES2ImplementationStrictSharedTest : public GLES2ImplementationTest {
 protected:
  void SetUp() override;

  template <class ResApi>
  void FlushGenerationTest() {
    GLuint id1, id2, id3;

    // Generate valid id.
    ResApi::Gen(gl_, 1, &id1);
    EXPECT_NE(id1, 0u);

    // Delete id1 and generate id2.  id1 should not be reused.
    ResApi::Delete(gl_, 1, &id1);
    ResApi::Gen(gl_, 1, &id2);
    EXPECT_NE(id2, 0u);
    EXPECT_NE(id2, id1);

    // Expect id1 reuse after Flush.
    gl_->Flush();
    ResApi::Gen(gl_, 1, &id3);
    EXPECT_EQ(id3, id1);
  }

  // Ids should not be reused unless the |Deleting| context does a Flush()
  // AND triggers a lazy release after that.
  template <class ResApi>
  void CrossContextGenerationTest() {
    GLES2Implementation* gl1 = test_contexts_[0].gl_.get();
    GLES2Implementation* gl2 = test_contexts_[1].gl_.get();
    GLuint id1, id2, id3;

    // Delete, no flush on context 1.  No reuse.
    ResApi::Gen(gl1, 1, &id1);
    ResApi::Delete(gl1, 1, &id1);
    ResApi::Gen(gl1, 1, &id2);
    EXPECT_NE(id1, id2);

    // Flush context 2.  Still no reuse.
    gl2->Flush();
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_NE(id1, id3);
    EXPECT_NE(id2, id3);

    // Flush on context 1, but no lazy release.  Still no reuse.
    gl1->Flush();
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_NE(id1, id3);

    // Lazy release triggered by another Delete.  Should reuse id1.
    ResApi::Delete(gl1, 1, &id2);
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_EQ(id1, id3);
  }

  // Same as CrossContextGenerationTest(), but triggers an Auto Flush on
  // the Delete().  Tests an edge case regression.
  template <class ResApi>
  void CrossContextGenerationAutoFlushTest() {
    GLES2Implementation* gl1 = test_contexts_[0].gl_.get();
    GLES2Implementation* gl2 = test_contexts_[1].gl_.get();
    GLuint id1, id2, id3;

    // Delete, no flush on context 1.  No reuse.
    // By half filling the buffer, an internal flush is forced on the Delete().
    ResApi::Gen(gl1, 1, &id1);
    gl1->helper()->Noop(kNumCommandEntries / 2);
    ResApi::Delete(gl1, 1, &id1);
    ResApi::Gen(gl1, 1, &id2);
    EXPECT_NE(id1, id2);

    // Flush context 2.  Still no reuse.
    gl2->Flush();
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_NE(id1, id3);
    EXPECT_NE(id2, id3);

    // Flush on context 1, but no lazy release.  Still no reuse.
    gl1->Flush();
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_NE(id1, id3);

    // Lazy release triggered by another Delete.  Should reuse id1.
    ResApi::Delete(gl1, 1, &id2);
    ResApi::Gen(gl2, 1, &id3);
    EXPECT_EQ(id1, id3);
  }
};

void GLES2ImplementationStrictSharedTest::SetUp() {
  ContextInitOptions init_options;
  init_options.bind_generates_resource_client = false;
  init_options.bind_generates_resource_service = false;
  ASSERT_TRUE(Initialize(init_options));
}

// GCC requires these declarations, but MSVC requires they not be present
#ifndef _MSC_VER
const uint8 GLES2ImplementationTest::kInitialValue;
const int32 GLES2ImplementationTest::kNumCommandEntries;
const int32 GLES2ImplementationTest::kCommandBufferSizeBytes;
const size_t GLES2ImplementationTest::kTransferBufferSize;
const GLint GLES2ImplementationTest::kMaxCombinedTextureImageUnits;
const GLint GLES2ImplementationTest::kMaxCubeMapTextureSize;
const GLint GLES2ImplementationTest::kMaxFragmentUniformVectors;
const GLint GLES2ImplementationTest::kMaxRenderbufferSize;
const GLint GLES2ImplementationTest::kMaxTextureImageUnits;
const GLint GLES2ImplementationTest::kMaxTextureSize;
const GLint GLES2ImplementationTest::kMaxVaryingVectors;
const GLint GLES2ImplementationTest::kMaxVertexAttribs;
const GLint GLES2ImplementationTest::kMaxVertexTextureImageUnits;
const GLint GLES2ImplementationTest::kMaxVertexUniformVectors;
const GLint GLES2ImplementationTest::kNumCompressedTextureFormats;
const GLint GLES2ImplementationTest::kNumShaderBinaryFormats;
const GLuint GLES2ImplementationTest::kStartId;
const GLuint GLES2ImplementationTest::kBuffersStartId;
const GLuint GLES2ImplementationTest::kFramebuffersStartId;
const GLuint GLES2ImplementationTest::kProgramsAndShadersStartId;
const GLuint GLES2ImplementationTest::kRenderbuffersStartId;
const GLuint GLES2ImplementationTest::kSamplersStartId;
const GLuint GLES2ImplementationTest::kTexturesStartId;
const GLuint GLES2ImplementationTest::kTransformFeedbacksStartId;
const GLuint GLES2ImplementationTest::kQueriesStartId;
const GLuint GLES2ImplementationTest::kVertexArraysStartId;
const GLuint GLES2ImplementationTest::kValuebuffersStartId;
#endif

TEST_F(GLES2ImplementationTest, Basic) {
  EXPECT_TRUE(gl_->share_group() != NULL);
}

TEST_F(GLES2ImplementationTest, GetBucketContents) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const uint32 kTestSize = MaxTransferBufferSize() + 32;

  scoped_ptr<uint8[]> buf(new uint8 [kTestSize]);
  uint8* expected_data = buf.get();
  for (uint32 ii = 0; ii < kTestSize; ++ii) {
    expected_data[ii] = ii * 3;
  }

  struct Cmds {
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::GetBucketData get_bucket_data;
    cmd::SetToken set_token2;
    cmd::SetBucketSize set_bucket_size2;
  };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 = GetExpectedResultMemory(sizeof(uint32));
  ExpectedMemoryInfo mem2 = GetExpectedMemory(
      kTestSize - MaxTransferBufferSize());

  Cmds expected;
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.get_bucket_data.Init(
      kBucketId, MaxTransferBufferSize(),
      kTestSize - MaxTransferBufferSize(), mem2.id, mem2.offset);
  expected.set_bucket_size2.Init(kBucketId, 0);
  expected.set_token2.Init(GetNextToken());

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(
          SetMemory(result1.ptr, kTestSize),
          SetMemoryFromArray(
              mem1.ptr, expected_data, MaxTransferBufferSize())))
      .WillOnce(SetMemoryFromArray(
          mem2.ptr, expected_data + MaxTransferBufferSize(),
          kTestSize - MaxTransferBufferSize()))
      .RetiresOnSaturation();

  std::vector<int8> data;
  GetBucketContents(kBucketId, &data);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  ASSERT_EQ(kTestSize, data.size());
  EXPECT_EQ(0, memcmp(expected_data, &data[0], data.size()));
}

TEST_F(GLES2ImplementationTest, GetShaderPrecisionFormat) {
  struct Cmds {
    cmds::GetShaderPrecisionFormat cmd;
  };
  typedef cmds::GetShaderPrecisionFormat::Result Result;
  const unsigned kDummyType1 = 3;
  const unsigned kDummyType2 = 4;

  // The first call for dummy type 1 should trigger a command buffer request.
  GLint range1[2] = {0, 0};
  GLint precision1 = 0;
  Cmds expected1;
  ExpectedMemoryInfo client_result1 = GetExpectedResultMemory(4);
  expected1.cmd.Init(GL_FRAGMENT_SHADER, kDummyType1, client_result1.id,
                     client_result1.offset);
  Result server_result1 = {true, 14, 14, 10};
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(client_result1.ptr, server_result1))
      .RetiresOnSaturation();
  gl_->GetShaderPrecisionFormat(GL_FRAGMENT_SHADER, kDummyType1, range1,
                                &precision1);
  const void* commands2 = GetPut();
  EXPECT_NE(commands_, commands2);
  EXPECT_EQ(0, memcmp(&expected1, commands_, sizeof(expected1)));
  EXPECT_EQ(range1[0], 14);
  EXPECT_EQ(range1[1], 14);
  EXPECT_EQ(precision1, 10);

  // The second call for dummy type 1 should use the cached value and avoid
  // triggering a command buffer request, so we do not expect a call to
  // OnFlush() here. We do expect the results to be correct though.
  GLint range2[2] = {0, 0};
  GLint precision2 = 0;
  gl_->GetShaderPrecisionFormat(GL_FRAGMENT_SHADER, kDummyType1, range2,
                                &precision2);
  const void* commands3 = GetPut();
  EXPECT_EQ(commands2, commands3);
  EXPECT_EQ(range2[0], 14);
  EXPECT_EQ(range2[1], 14);
  EXPECT_EQ(precision2, 10);

  // If we then make a request for dummy type 2, we should get another command
  // buffer request since it hasn't been cached yet.
  GLint range3[2] = {0, 0};
  GLint precision3 = 0;
  Cmds expected3;
  ExpectedMemoryInfo result3 = GetExpectedResultMemory(4);
  expected3.cmd.Init(GL_FRAGMENT_SHADER, kDummyType2, result3.id,
                     result3.offset);
  Result result3_source = {true, 62, 62, 16};
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result3.ptr, result3_source))
      .RetiresOnSaturation();
  gl_->GetShaderPrecisionFormat(GL_FRAGMENT_SHADER, kDummyType2, range3,
                                &precision3);
  const void* commands4 = GetPut();
  EXPECT_NE(commands3, commands4);
  EXPECT_EQ(0, memcmp(&expected3, commands3, sizeof(expected3)));
  EXPECT_EQ(range3[0], 62);
  EXPECT_EQ(range3[1], 62);
  EXPECT_EQ(precision3, 16);

  // Any call for predefined types should use the cached value from the
  // Capabilities  and avoid triggering a command buffer request, so we do not
  // expect a call to OnFlush() here. We do expect the results to be correct
  // though.
  GLint range4[2] = {0, 0};
  GLint precision4 = 0;
  gl_->GetShaderPrecisionFormat(GL_FRAGMENT_SHADER, GL_MEDIUM_FLOAT, range4,
                                &precision4);
  const void* commands5 = GetPut();
  EXPECT_EQ(commands4, commands5);
  EXPECT_EQ(range4[0], 3);
  EXPECT_EQ(range4[1], 5);
  EXPECT_EQ(precision4, 7);
}

TEST_F(GLES2ImplementationTest, GetShaderSource) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const GLuint kShaderId = 456;
  const Str7 kString = {"foobar"};
  const char kBad = 0x12;
  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetShaderSource get_shader_source;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 = GetExpectedResultMemory(sizeof(uint32));

  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_shader_source.Init(kShaderId, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  char buf[sizeof(kString) + 1];
  memset(buf, kBad, sizeof(buf));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr, kString)))
      .RetiresOnSaturation();

  GLsizei length = 0;
  gl_->GetShaderSource(kShaderId, sizeof(buf), &length, buf);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(sizeof(kString) - 1, static_cast<size_t>(length));
  EXPECT_STREQ(kString.str, buf);
  EXPECT_EQ(buf[sizeof(kString)], kBad);
}

#if defined(GLES2_SUPPORT_CLIENT_SIDE_ARRAYS)

TEST_F(GLES2ImplementationTest, DrawArraysClientSideBuffers) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawArrays draw;
    cmds::BindBuffer restore;
  };
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLint kFirst = 1;
  const GLsizei kCount = 2;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      arraysize(verts) * kNumComponents2 * sizeof(verts[0][0]);
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize2);

  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem2.id, mem2.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(
      kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kFirst, kCount);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);
  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(
      kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->DrawArrays(GL_POINTS, kFirst, kCount);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, DrawArraysInstancedANGLEClientSideBuffers) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::VertexAttribDivisorANGLE divisor;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawArraysInstancedANGLE draw;
    cmds::BindBuffer restore;
  };
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLint kFirst = 1;
  const GLsizei kCount = 2;
  const GLuint kDivisor = 1;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      1 * kNumComponents2 * sizeof(verts[0][0]);
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize2);

  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.divisor.Init(kAttribIndex2, kDivisor);
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem2.id, mem2.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(
      kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kFirst, kCount, 1);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);
  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(
      kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribDivisorANGLE(kAttribIndex2, kDivisor);
  gl_->DrawArraysInstancedANGLE(GL_POINTS, kFirst, kCount, 1);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, DrawElementsClientSideBuffers) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  static const uint16 indices[] = {
    1, 2,
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::BindBuffer bind_to_index_emu;
    cmds::BufferData set_index_size;
    cmds::BufferSubData copy_data0;
    cmd::SetToken set_token0;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawElements draw;
    cmds::BindBuffer restore;
    cmds::BindBuffer restore_element;
  };
  const GLsizei kIndexSize = sizeof(indices);
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kEmuIndexBufferId =
      GLES2Implementation::kClientSideElementArrayId;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLsizei kCount = 2;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      arraysize(verts) * kNumComponents2 * sizeof(verts[0][0]);
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kIndexSize);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem3 = GetExpectedMemory(kSize2);

  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.bind_to_index_emu.Init(GL_ELEMENT_ARRAY_BUFFER, kEmuIndexBufferId);
  expected.set_index_size.Init(
      GL_ELEMENT_ARRAY_BUFFER, kIndexSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data0.Init(
      GL_ELEMENT_ARRAY_BUFFER, 0, kIndexSize, mem1.id, mem1.offset);
  expected.set_token0.Init(GetNextToken());
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem2.id, mem2.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem3.id, mem3.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(kAttribIndex2, kNumComponents2,
                             GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kCount, GL_UNSIGNED_SHORT, 0);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);
  expected.restore_element.Init(GL_ELEMENT_ARRAY_BUFFER, 0);
  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->DrawElements(GL_POINTS, kCount, GL_UNSIGNED_SHORT, indices);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, DrawElementsClientSideBuffersIndexUint) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  static const uint32 indices[] = {
    1, 2,
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::BindBuffer bind_to_index_emu;
    cmds::BufferData set_index_size;
    cmds::BufferSubData copy_data0;
    cmd::SetToken set_token0;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawElements draw;
    cmds::BindBuffer restore;
    cmds::BindBuffer restore_element;
  };
  const GLsizei kIndexSize = sizeof(indices);
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kEmuIndexBufferId =
      GLES2Implementation::kClientSideElementArrayId;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLsizei kCount = 2;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      arraysize(verts) * kNumComponents2 * sizeof(verts[0][0]);
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kIndexSize);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem3 = GetExpectedMemory(kSize2);

  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.bind_to_index_emu.Init(GL_ELEMENT_ARRAY_BUFFER, kEmuIndexBufferId);
  expected.set_index_size.Init(
      GL_ELEMENT_ARRAY_BUFFER, kIndexSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data0.Init(
      GL_ELEMENT_ARRAY_BUFFER, 0, kIndexSize, mem1.id, mem1.offset);
  expected.set_token0.Init(GetNextToken());
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem2.id, mem2.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem3.id, mem3.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(kAttribIndex2, kNumComponents2,
                             GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kCount, GL_UNSIGNED_INT, 0);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);
  expected.restore_element.Init(GL_ELEMENT_ARRAY_BUFFER, 0);
  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->DrawElements(GL_POINTS, kCount, GL_UNSIGNED_INT, indices);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, DrawElementsClientSideBuffersInvalidIndexUint) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  static const uint32 indices[] = {
    1, 0x90000000
  };

  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLsizei kCount = 2;

  EXPECT_CALL(*command_buffer(), OnFlush())
      .Times(1)
      .RetiresOnSaturation();

  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->DrawElements(GL_POINTS, kCount, GL_UNSIGNED_INT, indices);

  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), gl_->GetError());
}

TEST_F(GLES2ImplementationTest,
       DrawElementsClientSideBuffersServiceSideIndices) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::BindBuffer bind_to_index;
    cmds::GetMaxValueInBufferCHROMIUM get_max;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawElements draw;
    cmds::BindBuffer restore;
  };
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kClientIndexBufferId = 0x789;
  const GLuint kIndexOffset = 0x40;
  const GLuint kMaxIndex = 2;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLsizei kCount = 2;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      arraysize(verts) * kNumComponents2 * sizeof(verts[0][0]);
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedResultMemory(sizeof(uint32));
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem3 = GetExpectedMemory(kSize2);


  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.bind_to_index.Init(GL_ELEMENT_ARRAY_BUFFER, kClientIndexBufferId);
  expected.get_max.Init(kClientIndexBufferId, kCount, GL_UNSIGNED_SHORT,
                        kIndexOffset, mem1.id, mem1.offset);
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem2.id, mem2.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(kAttribIndex1, kNumComponents1,
                             GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem3.id, mem3.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(kAttribIndex2, kNumComponents2,
                             GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kCount, GL_UNSIGNED_SHORT, kIndexOffset);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(mem1.ptr,kMaxIndex))
      .RetiresOnSaturation();

  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->BindBuffer(GL_ELEMENT_ARRAY_BUFFER, kClientIndexBufferId);
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->DrawElements(GL_POINTS, kCount, GL_UNSIGNED_SHORT,
                    reinterpret_cast<const void*>(kIndexOffset));
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, DrawElementsInstancedANGLEClientSideBuffers) {
  static const float verts[][4] = {
    { 12.0f, 23.0f, 34.0f, 45.0f, },
    { 56.0f, 67.0f, 78.0f, 89.0f, },
    { 13.0f, 24.0f, 35.0f, 46.0f, },
  };
  static const uint16 indices[] = {
    1, 2,
  };
  struct Cmds {
    cmds::EnableVertexAttribArray enable1;
    cmds::EnableVertexAttribArray enable2;
    cmds::VertexAttribDivisorANGLE divisor;
    cmds::BindBuffer bind_to_index_emu;
    cmds::BufferData set_index_size;
    cmds::BufferSubData copy_data0;
    cmd::SetToken set_token0;
    cmds::BindBuffer bind_to_emu;
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::VertexAttribPointer set_pointer1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
    cmds::VertexAttribPointer set_pointer2;
    cmds::DrawElementsInstancedANGLE draw;
    cmds::BindBuffer restore;
    cmds::BindBuffer restore_element;
  };
  const GLsizei kIndexSize = sizeof(indices);
  const GLuint kEmuBufferId = GLES2Implementation::kClientSideArrayId;
  const GLuint kEmuIndexBufferId =
      GLES2Implementation::kClientSideElementArrayId;
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kClientStride = sizeof(verts[0]);
  const GLsizei kCount = 2;
  const GLsizei kSize1 =
      arraysize(verts) * kNumComponents1 * sizeof(verts[0][0]);
  const GLsizei kSize2 =
      1 * kNumComponents2 * sizeof(verts[0][0]);
  const GLuint kDivisor = 1;
  const GLsizei kEmuOffset1 = 0;
  const GLsizei kEmuOffset2 = kSize1;
  const GLsizei kTotalSize = kSize1 + kSize2;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kIndexSize);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kSize1);
  ExpectedMemoryInfo mem3 = GetExpectedMemory(kSize2);

  Cmds expected;
  expected.enable1.Init(kAttribIndex1);
  expected.enable2.Init(kAttribIndex2);
  expected.divisor.Init(kAttribIndex2, kDivisor);
  expected.bind_to_index_emu.Init(GL_ELEMENT_ARRAY_BUFFER, kEmuIndexBufferId);
  expected.set_index_size.Init(
      GL_ELEMENT_ARRAY_BUFFER, kIndexSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data0.Init(
      GL_ELEMENT_ARRAY_BUFFER, 0, kIndexSize, mem1.id, mem1.offset);
  expected.set_token0.Init(GetNextToken());
  expected.bind_to_emu.Init(GL_ARRAY_BUFFER, kEmuBufferId);
  expected.set_size.Init(GL_ARRAY_BUFFER, kTotalSize, 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, kEmuOffset1, kSize1, mem2.id, mem2.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_pointer1.Init(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, 0, kEmuOffset1);
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kEmuOffset2, kSize2, mem3.id, mem3.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_pointer2.Init(kAttribIndex2, kNumComponents2,
                             GL_FLOAT, GL_FALSE, 0, kEmuOffset2);
  expected.draw.Init(GL_POINTS, kCount, GL_UNSIGNED_SHORT, 0, 1);
  expected.restore.Init(GL_ARRAY_BUFFER, 0);
  expected.restore_element.Init(GL_ELEMENT_ARRAY_BUFFER, 0);
  gl_->EnableVertexAttribArray(kAttribIndex1);
  gl_->EnableVertexAttribArray(kAttribIndex2);
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kClientStride, verts);
  gl_->VertexAttribDivisorANGLE(kAttribIndex2, kDivisor);
  gl_->DrawElementsInstancedANGLE(
      GL_POINTS, kCount, GL_UNSIGNED_SHORT, indices, 1);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, GetVertexBufferPointerv) {
  static const float verts[1] = { 0.0f, };
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kStride1 = 12;
  const GLsizei kStride2 = 0;
  const GLuint kBufferId = 0x123;
  const GLint kOffset2 = 0x456;

  // It's all cached on the client side so no get commands are issued.
  struct Cmds {
    cmds::BindBuffer bind;
    cmds::VertexAttribPointer set_pointer;
  };

  Cmds expected;
  expected.bind.Init(GL_ARRAY_BUFFER, kBufferId);
  expected.set_pointer.Init(kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE,
                            kStride2, kOffset2);

  // Set one client side buffer.
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kStride1, verts);
  // Set one VBO
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kStride2,
                           reinterpret_cast<const void*>(kOffset2));
  // now get them both.
  void* ptr1 = NULL;
  void* ptr2 = NULL;

  gl_->GetVertexAttribPointerv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_POINTER, &ptr1);
  gl_->GetVertexAttribPointerv(
      kAttribIndex2, GL_VERTEX_ATTRIB_ARRAY_POINTER, &ptr2);

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(static_cast<const void*>(&verts) == ptr1);
  EXPECT_TRUE(ptr2 == reinterpret_cast<void*>(kOffset2));
}

TEST_F(GLES2ImplementationTest, GetVertexAttrib) {
  static const float verts[1] = { 0.0f, };
  const GLuint kAttribIndex1 = 1;
  const GLuint kAttribIndex2 = 3;
  const GLint kNumComponents1 = 3;
  const GLint kNumComponents2 = 2;
  const GLsizei kStride1 = 12;
  const GLsizei kStride2 = 0;
  const GLuint kBufferId = 0x123;
  const GLint kOffset2 = 0x456;

  // Only one set and one get because the client side buffer's info is stored
  // on the client side.
  struct Cmds {
    cmds::EnableVertexAttribArray enable;
    cmds::BindBuffer bind;
    cmds::VertexAttribPointer set_pointer;
    cmds::GetVertexAttribfv get2;  // for getting the value from attrib1
  };

  ExpectedMemoryInfo mem2 = GetExpectedResultMemory(16);

  Cmds expected;
  expected.enable.Init(kAttribIndex1);
  expected.bind.Init(GL_ARRAY_BUFFER, kBufferId);
  expected.set_pointer.Init(kAttribIndex2, kNumComponents2, GL_FLOAT, GL_FALSE,
                            kStride2, kOffset2);
  expected.get2.Init(kAttribIndex1,
                     GL_CURRENT_VERTEX_ATTRIB,
                     mem2.id, mem2.offset);

  FourFloats current_attrib(1.2f, 3.4f, 5.6f, 7.8f);

  // One call to flush to wait for last call to GetVertexAttribiv
  // as others are all cached.
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(
          mem2.ptr, SizedResultHelper<FourFloats>(current_attrib)))
      .RetiresOnSaturation();

  gl_->EnableVertexAttribArray(kAttribIndex1);
  // Set one client side buffer.
  gl_->VertexAttribPointer(kAttribIndex1, kNumComponents1,
                           GL_FLOAT, GL_FALSE, kStride1, verts);
  // Set one VBO
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);
  gl_->VertexAttribPointer(kAttribIndex2, kNumComponents2,
                           GL_FLOAT, GL_FALSE, kStride2,
                           reinterpret_cast<const void*>(kOffset2));
  // first get the service side once to see that we make a command
  GLint buffer_id = 0;
  GLint enabled = 0;
  GLint size = 0;
  GLint stride = 0;
  GLint type = 0;
  GLint normalized = 1;
  float current[4] = { 0.0f, };

  gl_->GetVertexAttribiv(
      kAttribIndex2, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &buffer_id);
  EXPECT_EQ(kBufferId, static_cast<GLuint>(buffer_id));
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &buffer_id);
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &enabled);
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_SIZE, &size);
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_STRIDE, &stride);
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_TYPE, &type);
  gl_->GetVertexAttribiv(
      kAttribIndex1, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &normalized);
  gl_->GetVertexAttribfv(
      kAttribIndex1, GL_CURRENT_VERTEX_ATTRIB, &current[0]);

  EXPECT_EQ(0, buffer_id);
  EXPECT_EQ(GL_TRUE, enabled);
  EXPECT_EQ(kNumComponents1, size);
  EXPECT_EQ(kStride1, stride);
  EXPECT_EQ(GL_FLOAT, type);
  EXPECT_EQ(GL_FALSE, normalized);
  EXPECT_EQ(0, memcmp(&current_attrib, &current, sizeof(current_attrib)));

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, ReservedIds) {
  // Only the get error command should be issued.
  struct Cmds {
    cmds::GetError get;
  };
  Cmds expected;

  ExpectedMemoryInfo mem1 = GetExpectedResultMemory(
      sizeof(cmds::GetError::Result));

  expected.get.Init(mem1.id, mem1.offset);

  // One call to flush to wait for GetError
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(mem1.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  gl_->BindBuffer(
      GL_ARRAY_BUFFER,
      GLES2Implementation::kClientSideArrayId);
  gl_->BindBuffer(
      GL_ARRAY_BUFFER,
      GLES2Implementation::kClientSideElementArrayId);
  GLenum err = gl_->GetError();
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), err);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

#endif  // defined(GLES2_SUPPORT_CLIENT_SIDE_ARRAYS)

TEST_F(GLES2ImplementationTest, ReadPixels2Reads) {
  struct Cmds {
    cmds::ReadPixels read1;
    cmd::SetToken set_token1;
    cmds::ReadPixels read2;
    cmd::SetToken set_token2;
  };
  const GLint kBytesPerPixel = 4;
  const GLint kWidth =
      (kTransferBufferSize - GLES2Implementation::kStartingOffset) /
      kBytesPerPixel;
  const GLint kHeight = 2;
  const GLenum kFormat = GL_RGBA;
  const GLenum kType = GL_UNSIGNED_BYTE;

  ExpectedMemoryInfo mem1 =
      GetExpectedMemory(kWidth * kHeight / 2 * kBytesPerPixel);
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::ReadPixels::Result));
  ExpectedMemoryInfo mem2 =
      GetExpectedMemory(kWidth * kHeight / 2 * kBytesPerPixel);
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::ReadPixels::Result));

  Cmds expected;
  expected.read1.Init(
      0, 0, kWidth, kHeight / 2, kFormat, kType,
      mem1.id, mem1.offset, result1.id, result1.offset,
      false);
  expected.set_token1.Init(GetNextToken());
  expected.read2.Init(
      0, kHeight / 2, kWidth, kHeight / 2, kFormat, kType,
      mem2.id, mem2.offset, result2.id, result2.offset, false);
  expected.set_token2.Init(GetNextToken());
  scoped_ptr<int8[]> buffer(new int8[kWidth * kHeight * kBytesPerPixel]);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, static_cast<uint32>(1)))
      .WillOnce(SetMemory(result2.ptr, static_cast<uint32>(1)))
      .RetiresOnSaturation();

  gl_->ReadPixels(0, 0, kWidth, kHeight, kFormat, kType, buffer.get());
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, ReadPixelsBadFormatType) {
  struct Cmds {
    cmds::ReadPixels read;
    cmd::SetToken set_token;
  };
  const GLint kBytesPerPixel = 4;
  const GLint kWidth = 2;
  const GLint kHeight = 2;
  const GLenum kFormat = 0;
  const GLenum kType = 0;

  ExpectedMemoryInfo mem1 =
      GetExpectedMemory(kWidth * kHeight * kBytesPerPixel);
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::ReadPixels::Result));

  Cmds expected;
  expected.read.Init(
      0, 0, kWidth, kHeight, kFormat, kType,
      mem1.id, mem1.offset, result1.id, result1.offset, false);
  expected.set_token.Init(GetNextToken());
  scoped_ptr<int8[]> buffer(new int8[kWidth * kHeight * kBytesPerPixel]);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .Times(1)
      .RetiresOnSaturation();

  gl_->ReadPixels(0, 0, kWidth, kHeight, kFormat, kType, buffer.get());
}

TEST_F(GLES2ImplementationTest, FreeUnusedSharedMemory) {
  struct Cmds {
    cmds::BufferSubData buf;
    cmd::SetToken set_token;
  };
  const GLenum kTarget = GL_ELEMENT_ARRAY_BUFFER;
  const GLintptr kOffset = 15;
  const GLsizeiptr kSize = 16;

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kSize);

  Cmds expected;
  expected.buf.Init(
    kTarget, kOffset, kSize, mem1.id, mem1.offset);
  expected.set_token.Init(GetNextToken());

  void* mem = gl_->MapBufferSubDataCHROMIUM(
      kTarget, kOffset, kSize, GL_WRITE_ONLY);
  ASSERT_TRUE(mem != NULL);
  gl_->UnmapBufferSubDataCHROMIUM(mem);
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  gl_->FreeUnusedSharedMemory();
}

TEST_F(GLES2ImplementationTest, MapUnmapBufferSubDataCHROMIUM) {
  struct Cmds {
    cmds::BufferSubData buf;
    cmd::SetToken set_token;
  };
  const GLenum kTarget = GL_ELEMENT_ARRAY_BUFFER;
  const GLintptr kOffset = 15;
  const GLsizeiptr kSize = 16;

  uint32 offset = 0;
  Cmds expected;
  expected.buf.Init(
      kTarget, kOffset, kSize,
      command_buffer()->GetNextFreeTransferBufferId(), offset);
  expected.set_token.Init(GetNextToken());

  void* mem = gl_->MapBufferSubDataCHROMIUM(
      kTarget, kOffset, kSize, GL_WRITE_ONLY);
  ASSERT_TRUE(mem != NULL);
  gl_->UnmapBufferSubDataCHROMIUM(mem);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, MapUnmapBufferSubDataCHROMIUMBadArgs) {
  const GLenum kTarget = GL_ELEMENT_ARRAY_BUFFER;
  const GLintptr kOffset = 15;
  const GLsizeiptr kSize = 16;

  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result3 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result4 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  // Calls to flush to wait for GetError
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result3.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result4.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  void* mem;
  mem = gl_->MapBufferSubDataCHROMIUM(kTarget, -1, kSize, GL_WRITE_ONLY);
  ASSERT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapBufferSubDataCHROMIUM(kTarget, kOffset, -1, GL_WRITE_ONLY);
  ASSERT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapBufferSubDataCHROMIUM(kTarget, kOffset, kSize, GL_READ_ONLY);
  ASSERT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_ENUM), gl_->GetError());
  const char* kPtr = "something";
  gl_->UnmapBufferSubDataCHROMIUM(kPtr);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
}

TEST_F(GLES2ImplementationTest, MapUnmapTexSubImage2DCHROMIUM) {
  struct Cmds {
    cmds::TexSubImage2D tex;
    cmd::SetToken set_token;
  };
  const GLint kLevel = 1;
  const GLint kXOffset = 2;
  const GLint kYOffset = 3;
  const GLint kWidth = 4;
  const GLint kHeight = 5;
  const GLenum kFormat = GL_RGBA;
  const GLenum kType = GL_UNSIGNED_BYTE;

  uint32 offset = 0;
  Cmds expected;
  expected.tex.Init(
      GL_TEXTURE_2D, kLevel, kXOffset, kYOffset, kWidth, kHeight, kFormat,
      kType,
      command_buffer()->GetNextFreeTransferBufferId(), offset, GL_FALSE);
  expected.set_token.Init(GetNextToken());

  void* mem = gl_->MapTexSubImage2DCHROMIUM(
      GL_TEXTURE_2D,
      kLevel,
      kXOffset,
      kYOffset,
      kWidth,
      kHeight,
      kFormat,
      kType,
      GL_WRITE_ONLY);
  ASSERT_TRUE(mem != NULL);
  gl_->UnmapTexSubImage2DCHROMIUM(mem);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, MapUnmapTexSubImage2DCHROMIUMBadArgs) {
  const GLint kLevel = 1;
  const GLint kXOffset = 2;
  const GLint kYOffset = 3;
  const GLint kWidth = 4;
  const GLint kHeight = 5;
  const GLenum kFormat = GL_RGBA;
  const GLenum kType = GL_UNSIGNED_BYTE;

  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result3 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result4 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result5 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result6 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result7 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  // Calls to flush to wait for GetError
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result3.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result4.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result5.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result6.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result7.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  void* mem;
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    -1,
    kXOffset,
    kYOffset,
    kWidth,
    kHeight,
    kFormat,
    kType,
    GL_WRITE_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    kLevel,
    -1,
    kYOffset,
    kWidth,
    kHeight,
    kFormat,
    kType,
    GL_WRITE_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    kLevel,
    kXOffset,
    -1,
    kWidth,
    kHeight,
    kFormat,
    kType,
    GL_WRITE_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    kLevel,
    kXOffset,
    kYOffset,
    -1,
    kHeight,
    kFormat,
    kType,
    GL_WRITE_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    kLevel,
    kXOffset,
    kYOffset,
    kWidth,
    -1,
    kFormat,
    kType,
    GL_WRITE_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  mem = gl_->MapTexSubImage2DCHROMIUM(
    GL_TEXTURE_2D,
    kLevel,
    kXOffset,
    kYOffset,
    kWidth,
    kHeight,
    kFormat,
    kType,
    GL_READ_ONLY);
  EXPECT_TRUE(mem == NULL);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_ENUM), gl_->GetError());
  const char* kPtr = "something";
  gl_->UnmapTexSubImage2DCHROMIUM(kPtr);
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
}

TEST_F(GLES2ImplementationTest, GetProgramInfoCHROMIUMGoodArgs) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const GLuint kProgramId = 123;
  const char kBad = 0x12;
  GLsizei size = 0;
  const Str7 kString = {"foobar"};
  char buf[20];

  ExpectedMemoryInfo mem1 =
      GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  memset(buf, kBad, sizeof(buf));
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr, kString)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetProgramInfoCHROMIUM get_program_info;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };
  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_program_info.Init(kProgramId, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  gl_->GetProgramInfoCHROMIUM(kProgramId, sizeof(buf), &size, &buf);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), gl_->GetError());
  EXPECT_EQ(sizeof(kString), static_cast<size_t>(size));
  EXPECT_STREQ(kString.str, buf);
  EXPECT_EQ(buf[sizeof(kString)], kBad);
}

TEST_F(GLES2ImplementationTest, GetProgramInfoCHROMIUMBadArgs) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const GLuint kProgramId = 123;
  GLsizei size = 0;
  const Str7 kString = {"foobar"};
  char buf[20];

  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result3 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result4 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr,  kString)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result3.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result4.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  // try bufsize not big enough.
  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetProgramInfoCHROMIUM get_program_info;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };
  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_program_info.Init(kProgramId, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  gl_->GetProgramInfoCHROMIUM(kProgramId, 6, &size, &buf);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), gl_->GetError());
  ClearCommands();

  // try bad bufsize
  gl_->GetProgramInfoCHROMIUM(kProgramId, -1, &size, &buf);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  ClearCommands();
  // try no size ptr.
  gl_->GetProgramInfoCHROMIUM(kProgramId, sizeof(buf), NULL, &buf);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
}

TEST_F(GLES2ImplementationTest, GetUniformBlocksCHROMIUMGoodArgs) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const GLuint kProgramId = 123;
  const char kBad = 0x12;
  GLsizei size = 0;
  const Str7 kString = {"foobar"};
  char buf[20];

  ExpectedMemoryInfo mem1 =
      GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  memset(buf, kBad, sizeof(buf));
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr, kString)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetUniformBlocksCHROMIUM get_uniform_blocks;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };
  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_uniform_blocks.Init(kProgramId, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  gl_->GetUniformBlocksCHROMIUM(kProgramId, sizeof(buf), &size, &buf);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), gl_->GetError());
  EXPECT_EQ(sizeof(kString), static_cast<size_t>(size));
  EXPECT_STREQ(kString.str, buf);
  EXPECT_EQ(buf[sizeof(kString)], kBad);
}

TEST_F(GLES2ImplementationTest, GetUniformBlocksCHROMIUMBadArgs) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const GLuint kProgramId = 123;
  GLsizei size = 0;
  const Str7 kString = {"foobar"};
  char buf[20];

  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));
  ExpectedMemoryInfo result2 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result3 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));
  ExpectedMemoryInfo result4 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr,  kString)))
      .WillOnce(SetMemory(result2.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result3.ptr, GLuint(GL_NO_ERROR)))
      .WillOnce(SetMemory(result4.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();

  // try bufsize not big enough.
  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetUniformBlocksCHROMIUM get_uniform_blocks;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };
  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_uniform_blocks.Init(kProgramId, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  gl_->GetUniformBlocksCHROMIUM(kProgramId, 6, &size, &buf);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_OPERATION), gl_->GetError());
  ClearCommands();

  // try bad bufsize
  gl_->GetUniformBlocksCHROMIUM(kProgramId, -1, &size, &buf);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
  ClearCommands();
  // try no size ptr.
  gl_->GetUniformBlocksCHROMIUM(kProgramId, sizeof(buf), NULL, &buf);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(static_cast<GLenum>(GL_INVALID_VALUE), gl_->GetError());
}

// Test that things are cached
TEST_F(GLES2ImplementationTest, GetIntegerCacheRead) {
  struct PNameValue {
    GLenum pname;
    GLint expected;
  };
  const PNameValue pairs[] = {
      {GL_ACTIVE_TEXTURE, GL_TEXTURE0, },
      {GL_TEXTURE_BINDING_2D, 0, },
      {GL_TEXTURE_BINDING_CUBE_MAP, 0, },
      {GL_TEXTURE_BINDING_EXTERNAL_OES, 0, },
      {GL_FRAMEBUFFER_BINDING, 0, },
      {GL_RENDERBUFFER_BINDING, 0, },
      {GL_ARRAY_BUFFER_BINDING, 0, },
      {GL_ELEMENT_ARRAY_BUFFER_BINDING, 0, },
      {GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, kMaxCombinedTextureImageUnits, },
      {GL_MAX_CUBE_MAP_TEXTURE_SIZE, kMaxCubeMapTextureSize, },
      {GL_MAX_FRAGMENT_UNIFORM_VECTORS, kMaxFragmentUniformVectors, },
      {GL_MAX_RENDERBUFFER_SIZE, kMaxRenderbufferSize, },
      {GL_MAX_TEXTURE_IMAGE_UNITS, kMaxTextureImageUnits, },
      {GL_MAX_TEXTURE_SIZE, kMaxTextureSize, },
      {GL_MAX_VARYING_VECTORS, kMaxVaryingVectors, },
      {GL_MAX_VERTEX_ATTRIBS, kMaxVertexAttribs, },
      {GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, kMaxVertexTextureImageUnits, },
      {GL_MAX_VERTEX_UNIFORM_VECTORS, kMaxVertexUniformVectors, },
      {GL_NUM_COMPRESSED_TEXTURE_FORMATS, kNumCompressedTextureFormats, },
      {GL_NUM_SHADER_BINARY_FORMATS, kNumShaderBinaryFormats, }, };
  size_t num_pairs = sizeof(pairs) / sizeof(pairs[0]);
  for (size_t ii = 0; ii < num_pairs; ++ii) {
    const PNameValue& pv = pairs[ii];
    GLint v = -1;
    gl_->GetIntegerv(pv.pname, &v);
    EXPECT_TRUE(NoCommandsWritten());
    EXPECT_EQ(pv.expected, v);
  }

  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), gl_->GetError());
}

TEST_F(GLES2ImplementationTest, GetIntegerCacheWrite) {
  struct PNameValue {
    GLenum pname;
    GLint expected;
  };
  gl_->ActiveTexture(GL_TEXTURE4);
  gl_->BindBuffer(GL_ARRAY_BUFFER, 2);
  gl_->BindBuffer(GL_ELEMENT_ARRAY_BUFFER, 3);
  gl_->BindFramebuffer(GL_FRAMEBUFFER, 4);
  gl_->BindRenderbuffer(GL_RENDERBUFFER, 5);
  gl_->BindTexture(GL_TEXTURE_2D, 6);
  gl_->BindTexture(GL_TEXTURE_CUBE_MAP, 7);
  gl_->BindTexture(GL_TEXTURE_EXTERNAL_OES, 8);

  const PNameValue pairs[] = {{GL_ACTIVE_TEXTURE, GL_TEXTURE4, },
                              {GL_ARRAY_BUFFER_BINDING, 2, },
                              {GL_ELEMENT_ARRAY_BUFFER_BINDING, 3, },
                              {GL_FRAMEBUFFER_BINDING, 4, },
                              {GL_RENDERBUFFER_BINDING, 5, },
                              {GL_TEXTURE_BINDING_2D, 6, },
                              {GL_TEXTURE_BINDING_CUBE_MAP, 7, },
                              {GL_TEXTURE_BINDING_EXTERNAL_OES, 8, }, };
  size_t num_pairs = sizeof(pairs) / sizeof(pairs[0]);
  for (size_t ii = 0; ii < num_pairs; ++ii) {
    const PNameValue& pv = pairs[ii];
    GLint v = -1;
    gl_->GetIntegerv(pv.pname, &v);
    EXPECT_EQ(pv.expected, v);
  }

  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::GetError::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, GLuint(GL_NO_ERROR)))
      .RetiresOnSaturation();
  EXPECT_EQ(static_cast<GLenum>(GL_NO_ERROR), gl_->GetError());
}

static bool CheckRect(
    int width, int height, GLenum format, GLenum type, int alignment,
    bool flip_y, const uint8* r1, const uint8* r2) {
  uint32 size = 0;
  uint32 unpadded_row_size = 0;
  uint32 padded_row_size = 0;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, alignment, &size, &unpadded_row_size,
      &padded_row_size)) {
    return false;
  }

  int r2_stride = flip_y ?
      -static_cast<int>(padded_row_size) :
      static_cast<int>(padded_row_size);
  r2 = flip_y ? (r2 + (height - 1) * padded_row_size) : r2;

  for (int y = 0; y < height; ++y) {
    if (memcmp(r1, r2, unpadded_row_size) != 0) {
      return false;
    }
    r1 += padded_row_size;
    r2 += r2_stride;
  }
  return true;
}

ACTION_P8(CheckRectAction, width, height, format, type, alignment, flip_y,
          r1, r2) {
  EXPECT_TRUE(CheckRect(
      width, height, format, type, alignment, flip_y, r1, r2));
}

// Test TexImage2D with and without flip_y
TEST_F(GLES2ImplementationTest, TexImage2D) {
  struct Cmds {
    cmds::TexImage2D tex_image_2d;
    cmd::SetToken set_token;
  };
  struct Cmds2 {
    cmds::TexImage2D tex_image_2d;
    cmd::SetToken set_token;
  };
  const GLenum kTarget = GL_TEXTURE_2D;
  const GLint kLevel = 0;
  const GLenum kFormat = GL_RGB;
  const GLsizei kWidth = 3;
  const GLsizei kHeight = 4;
  const GLint kBorder = 0;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  static uint8 pixels[] = {
    11, 12, 13, 13, 14, 15, 15, 16, 17, 101, 102, 103,
    21, 22, 23, 23, 24, 25, 25, 26, 27, 201, 202, 203,
    31, 32, 33, 33, 34, 35, 35, 36, 37, 123, 124, 125,
    41, 42, 43, 43, 44, 45, 45, 46, 47,
  };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(sizeof(pixels));

  Cmds expected;
  expected.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kFormat, kType,
      mem1.id, mem1.offset);
  expected.set_token.Init(GetNextToken());
  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kBorder, kFormat, kType,
      pixels);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight, kFormat, kType, kPixelStoreUnpackAlignment, false,
      pixels, mem1.ptr));

  ClearCommands();
  gl_->PixelStorei(GL_UNPACK_FLIP_Y_CHROMIUM, GL_TRUE);

  ExpectedMemoryInfo mem2 = GetExpectedMemory(sizeof(pixels));
  Cmds2 expected2;
  expected2.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kFormat, kType,
      mem2.id, mem2.offset);
  expected2.set_token.Init(GetNextToken());
  const void* commands2 = GetPut();
  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kBorder, kFormat, kType,
      pixels);
  EXPECT_EQ(0, memcmp(&expected2, commands2, sizeof(expected2)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight, kFormat, kType, kPixelStoreUnpackAlignment, true,
      pixels, mem2.ptr));
}

// Test TexImage2D with 2 writes
TEST_F(GLES2ImplementationTest, TexImage2D2Writes) {
  struct Cmds {
    cmds::TexImage2D tex_image_2d;
    cmds::TexSubImage2D tex_sub_image_2d1;
    cmd::SetToken set_token1;
    cmds::TexSubImage2D tex_sub_image_2d2;
    cmd::SetToken set_token2;
  };
  const GLenum kTarget = GL_TEXTURE_2D;
  const GLint kLevel = 0;
  const GLenum kFormat = GL_RGB;
  const GLint kBorder = 0;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  const GLsizei kWidth = 3;

  uint32 size = 0;
  uint32 unpadded_row_size = 0;
  uint32 padded_row_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, 2, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, &unpadded_row_size, &padded_row_size));
  const GLsizei kHeight = (MaxTransferBufferSize() / padded_row_size) * 2;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, NULL, NULL));
  uint32 half_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight / 2, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &half_size, NULL, NULL));

  scoped_ptr<uint8[]> pixels(new uint8[size]);
  for (uint32 ii = 0; ii < size; ++ii) {
    pixels[ii] = static_cast<uint8>(ii);
  }

  ExpectedMemoryInfo mem1 = GetExpectedMemory(half_size);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(half_size);

  Cmds expected;
  expected.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kFormat, kType,
      0, 0);
  expected.tex_sub_image_2d1.Init(
      kTarget, kLevel, 0, 0, kWidth, kHeight / 2, kFormat, kType,
      mem1.id, mem1.offset, true);
  expected.set_token1.Init(GetNextToken());
  expected.tex_sub_image_2d2.Init(
      kTarget, kLevel, 0, kHeight / 2, kWidth, kHeight / 2, kFormat, kType,
      mem2.id, mem2.offset, true);
  expected.set_token2.Init(GetNextToken());

  // TODO(gman): Make it possible to run this test
  // EXPECT_CALL(*command_buffer(), OnFlush())
  //     .WillOnce(CheckRectAction(
  //         kWidth, kHeight / 2, kFormat, kType, kPixelStoreUnpackAlignment,
  //         false, pixels.get(),
  //         GetExpectedTransferAddressFromOffsetAs<uint8>(offset1, half_size)))
  //     .RetiresOnSaturation();

  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kBorder, kFormat, kType,
      pixels.get());
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight / 2, kFormat, kType, kPixelStoreUnpackAlignment, false,
      pixels.get() + kHeight / 2 * padded_row_size, mem2.ptr));

  ClearCommands();
  gl_->PixelStorei(GL_UNPACK_FLIP_Y_CHROMIUM, GL_TRUE);
  const void* commands2 = GetPut();
  ExpectedMemoryInfo mem3 = GetExpectedMemory(half_size);
  ExpectedMemoryInfo mem4 = GetExpectedMemory(half_size);
  expected.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kFormat, kType,
      0, 0);
  expected.tex_sub_image_2d1.Init(
      kTarget, kLevel, 0, kHeight / 2, kWidth, kHeight / 2, kFormat, kType,
      mem3.id, mem3.offset, true);
  expected.set_token1.Init(GetNextToken());
  expected.tex_sub_image_2d2.Init(
      kTarget, kLevel, 0, 0, kWidth, kHeight / 2, kFormat, kType,
      mem4.id, mem4.offset, true);
  expected.set_token2.Init(GetNextToken());

  // TODO(gman): Make it possible to run this test
  // EXPECT_CALL(*command_buffer(), OnFlush())
  //     .WillOnce(CheckRectAction(
  //         kWidth, kHeight / 2, kFormat, kType, kPixelStoreUnpackAlignment,
  //         true, pixels.get(),
  //         GetExpectedTransferAddressFromOffsetAs<uint8>(offset3, half_size)))
  //     .RetiresOnSaturation();

  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kBorder, kFormat, kType,
      pixels.get());
  EXPECT_EQ(0, memcmp(&expected, commands2, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight / 2, kFormat, kType, kPixelStoreUnpackAlignment, true,
      pixels.get() + kHeight / 2 * padded_row_size, mem4.ptr));
}

// Test TexSubImage2D with GL_PACK_FLIP_Y set and partial multirow transfers
TEST_F(GLES2ImplementationTest, TexSubImage2DFlipY) {
  const GLsizei kTextureWidth = MaxTransferBufferSize() / 4;
  const GLsizei kTextureHeight = 7;
  const GLsizei kSubImageWidth = MaxTransferBufferSize() / 8;
  const GLsizei kSubImageHeight = 4;
  const GLint kSubImageXOffset = 1;
  const GLint kSubImageYOffset = 2;
  const GLenum kFormat = GL_RGBA;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLenum kTarget = GL_TEXTURE_2D;
  const GLint kLevel = 0;
  const GLint kBorder = 0;
  const GLint kPixelStoreUnpackAlignment = 4;

  struct Cmds {
    cmds::PixelStorei pixel_store_i1;
    cmds::TexImage2D tex_image_2d;
    cmds::PixelStorei pixel_store_i2;
    cmds::TexSubImage2D tex_sub_image_2d1;
    cmd::SetToken set_token1;
    cmds::TexSubImage2D tex_sub_image_2d2;
    cmd::SetToken set_token2;
  };

  uint32 sub_2_high_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kSubImageWidth, 2, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &sub_2_high_size, NULL, NULL));

  ExpectedMemoryInfo mem1 = GetExpectedMemory(sub_2_high_size);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(sub_2_high_size);

  Cmds expected;
  expected.pixel_store_i1.Init(GL_UNPACK_ALIGNMENT, kPixelStoreUnpackAlignment);
  expected.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kTextureWidth, kTextureHeight, kFormat,
      kType, 0, 0);
  expected.pixel_store_i2.Init(GL_UNPACK_FLIP_Y_CHROMIUM, GL_TRUE);
  expected.tex_sub_image_2d1.Init(kTarget, kLevel, kSubImageXOffset,
      kSubImageYOffset + 2, kSubImageWidth, 2, kFormat, kType,
      mem1.id, mem1.offset, false);
  expected.set_token1.Init(GetNextToken());
  expected.tex_sub_image_2d2.Init(kTarget, kLevel, kSubImageXOffset,
      kSubImageYOffset, kSubImageWidth , 2, kFormat, kType,
      mem2.id, mem2.offset, false);
  expected.set_token2.Init(GetNextToken());

  gl_->PixelStorei(GL_UNPACK_ALIGNMENT, kPixelStoreUnpackAlignment);
  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kTextureWidth, kTextureHeight, kBorder, kFormat,
      kType, NULL);
  gl_->PixelStorei(GL_UNPACK_FLIP_Y_CHROMIUM, GL_TRUE);
  scoped_ptr<uint32[]> pixels(new uint32[kSubImageWidth * kSubImageHeight]);
  for (int y = 0; y < kSubImageHeight; ++y) {
    for (int x = 0; x < kSubImageWidth; ++x) {
      pixels.get()[kSubImageWidth * y + x] = x | (y << 16);
    }
  }
  gl_->TexSubImage2D(
      GL_TEXTURE_2D, 0, kSubImageXOffset, kSubImageYOffset, kSubImageWidth,
      kSubImageHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixels.get());

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kSubImageWidth, 2, kFormat, kType, kPixelStoreUnpackAlignment, true,
      reinterpret_cast<uint8*>(pixels.get() + 2 * kSubImageWidth),
      mem2.ptr));
}

TEST_F(GLES2ImplementationTest, SubImageUnpack) {
  static const GLint unpack_alignments[] = { 1, 2, 4, 8 };

  static const GLenum kFormat = GL_RGB;
  static const GLenum kType = GL_UNSIGNED_BYTE;
  static const GLint kLevel = 0;
  static const GLint kBorder = 0;
  // We're testing using the unpack params to pull a subimage out of a larger
  // source of pixels. Here we specify the subimage by its border rows /
  // columns.
  static const GLint kSrcWidth = 33;
  static const GLint kSrcSubImageX0 = 11;
  static const GLint kSrcSubImageX1 = 20;
  static const GLint kSrcSubImageY0 = 18;
  static const GLint kSrcSubImageY1 = 23;
  static const GLint kSrcSubImageWidth = kSrcSubImageX1 - kSrcSubImageX0;
  static const GLint kSrcSubImageHeight = kSrcSubImageY1 - kSrcSubImageY0;

  // these are only used in the texsubimage tests
  static const GLint kTexWidth = 1023;
  static const GLint kTexHeight = 511;
  static const GLint kTexSubXOffset = 419;
  static const GLint kTexSubYOffset = 103;

  struct {
    cmds::PixelStorei pixel_store_i;
    cmds::PixelStorei pixel_store_i2;
    cmds::TexImage2D tex_image_2d;
  } texImageExpected;

  struct  {
    cmds::PixelStorei pixel_store_i;
    cmds::PixelStorei pixel_store_i2;
    cmds::TexImage2D tex_image_2d;
    cmds::TexSubImage2D tex_sub_image_2d;
  } texSubImageExpected;

  uint32 src_size;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kSrcWidth, kSrcSubImageY1, 1, kFormat, kType, 8, &src_size, NULL, NULL));
  scoped_ptr<uint8[]> src_pixels;
  src_pixels.reset(new uint8[src_size]);
  for (size_t i = 0; i < src_size; ++i) {
    src_pixels[i] = static_cast<int8>(i);
  }

  for (int sub = 0; sub < 2; ++sub) {
    for (int flip_y = 0; flip_y < 2; ++flip_y) {
      for (size_t a = 0; a < arraysize(unpack_alignments); ++a) {
        GLint alignment = unpack_alignments[a];
        uint32 size;
        uint32 unpadded_row_size;
        uint32 padded_row_size;
        ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
            kSrcSubImageWidth, kSrcSubImageHeight, 1, kFormat, kType, alignment,
            &size, &unpadded_row_size, &padded_row_size));
        ASSERT_TRUE(size <= MaxTransferBufferSize());
        ExpectedMemoryInfo mem = GetExpectedMemory(size);

        const void* commands = GetPut();
        gl_->PixelStorei(GL_UNPACK_ALIGNMENT, alignment);
        gl_->PixelStorei(GL_UNPACK_ROW_LENGTH_EXT, kSrcWidth);
        gl_->PixelStorei(GL_UNPACK_SKIP_PIXELS_EXT, kSrcSubImageX0);
        gl_->PixelStorei(GL_UNPACK_SKIP_ROWS_EXT, kSrcSubImageY0);
        gl_->PixelStorei(GL_UNPACK_FLIP_Y_CHROMIUM, flip_y);
        if (sub) {
          gl_->TexImage2D(
              GL_TEXTURE_2D, kLevel, kFormat, kTexWidth, kTexHeight, kBorder,
              kFormat, kType, NULL);
          gl_->TexSubImage2D(
              GL_TEXTURE_2D, kLevel, kTexSubXOffset, kTexSubYOffset,
              kSrcSubImageWidth, kSrcSubImageHeight, kFormat, kType,
              src_pixels.get());
          texSubImageExpected.pixel_store_i.Init(
              GL_UNPACK_ALIGNMENT, alignment);
          texSubImageExpected.pixel_store_i2.Init(
              GL_UNPACK_FLIP_Y_CHROMIUM, flip_y);
          texSubImageExpected.tex_image_2d.Init(
              GL_TEXTURE_2D, kLevel, kFormat, kTexWidth, kTexHeight,
              kFormat, kType, 0, 0);
          texSubImageExpected.tex_sub_image_2d.Init(
              GL_TEXTURE_2D, kLevel, kTexSubXOffset, kTexSubYOffset,
              kSrcSubImageWidth, kSrcSubImageHeight, kFormat, kType, mem.id,
              mem.offset, GL_FALSE);
          EXPECT_EQ(0, memcmp(
              &texSubImageExpected, commands, sizeof(texSubImageExpected)));
        } else {
          gl_->TexImage2D(
              GL_TEXTURE_2D, kLevel, kFormat,
              kSrcSubImageWidth, kSrcSubImageHeight, kBorder, kFormat, kType,
              src_pixels.get());
          texImageExpected.pixel_store_i.Init(GL_UNPACK_ALIGNMENT, alignment);
          texImageExpected.pixel_store_i2.Init(
              GL_UNPACK_FLIP_Y_CHROMIUM, flip_y);
          texImageExpected.tex_image_2d.Init(
              GL_TEXTURE_2D, kLevel, kFormat, kSrcSubImageWidth,
              kSrcSubImageHeight, kFormat, kType, mem.id, mem.offset);
          EXPECT_EQ(0, memcmp(
              &texImageExpected, commands, sizeof(texImageExpected)));
        }
        uint32 src_padded_row_size;
        ASSERT_TRUE(GLES2Util::ComputeImagePaddedRowSize(
            kSrcWidth, kFormat, kType, alignment, &src_padded_row_size));
        uint32 bytes_per_group = GLES2Util::ComputeImageGroupSize(
            kFormat, kType);
        for (int y = 0; y < kSrcSubImageHeight; ++y) {
          GLint src_sub_y = flip_y ? kSrcSubImageHeight - y - 1 : y;
          const uint8* src_row = src_pixels.get() +
              (kSrcSubImageY0 + src_sub_y) * src_padded_row_size +
              bytes_per_group * kSrcSubImageX0;
          const uint8* dst_row = mem.ptr + y * padded_row_size;
          EXPECT_EQ(0, memcmp(src_row, dst_row, unpadded_row_size));
        }
        ClearCommands();
      }
    }
  }
}

// Test texture related calls with invalid arguments.
TEST_F(GLES2ImplementationTest, TextureInvalidArguments) {
  struct Cmds {
    cmds::TexImage2D tex_image_2d;
    cmd::SetToken set_token;
  };
  const GLenum kTarget = GL_TEXTURE_2D;
  const GLint kLevel = 0;
  const GLenum kFormat = GL_RGB;
  const GLsizei kWidth = 3;
  const GLsizei kHeight = 4;
  const GLint kBorder = 0;
  const GLint kInvalidBorder = 1;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  static uint8 pixels[] = {
    11, 12, 13, 13, 14, 15, 15, 16, 17, 101, 102, 103,
    21, 22, 23, 23, 24, 25, 25, 26, 27, 201, 202, 203,
    31, 32, 33, 33, 34, 35, 35, 36, 37, 123, 124, 125,
    41, 42, 43, 43, 44, 45, 45, 46, 47,
  };

  // Verify that something works.

  ExpectedMemoryInfo mem1 = GetExpectedMemory(sizeof(pixels));

  Cmds expected;
  expected.tex_image_2d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kFormat, kType,
      mem1.id, mem1.offset);
  expected.set_token.Init(GetNextToken());
  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kBorder, kFormat, kType,
      pixels);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight, kFormat, kType, kPixelStoreUnpackAlignment, false,
      pixels, mem1.ptr));

  ClearCommands();

  // Use invalid border.
  gl_->TexImage2D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kInvalidBorder, kFormat, kType,
      pixels);

  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_VALUE, CheckError());

  ClearCommands();

  gl_->AsyncTexImage2DCHROMIUM(
      kTarget, kLevel, kFormat, kWidth, kHeight, kInvalidBorder, kFormat, kType,
      NULL);

  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_VALUE, CheckError());

  ClearCommands();

  // Checking for CompressedTexImage2D argument validation is a bit tricky due
  // to (runtime-detected) compression formats. Try to infer the error with an
  // aux check.
  const GLenum kCompressedFormat = GL_ETC1_RGB8_OES;
  gl_->CompressedTexImage2D(
      kTarget, kLevel, kCompressedFormat, kWidth, kHeight, kBorder,
      arraysize(pixels), pixels);

  // In the above, kCompressedFormat and arraysize(pixels) are possibly wrong
  // values. First ensure that these do not cause failures at the client. If
  // this check ever fails, it probably means that client checks more than at
  // the time of writing of this test. In this case, more code needs to be
  // written for this test.
  EXPECT_FALSE(NoCommandsWritten());

  ClearCommands();

  // Changing border to invalid border should make the call fail at the client
  // checks.
  gl_->CompressedTexImage2D(
      kTarget, kLevel, kCompressedFormat, kWidth, kHeight, kInvalidBorder,
      arraysize(pixels), pixels);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_VALUE, CheckError());
}

TEST_F(GLES2ImplementationTest, TexImage3DSingleCommand) {
  struct Cmds {
    cmds::TexImage3D tex_image_3d;
  };
  const GLenum kTarget = GL_TEXTURE_3D;
  const GLint kLevel = 0;
  const GLint kBorder = 0;
  const GLenum kFormat = GL_RGB;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  const GLsizei kWidth = 3;
  const GLsizei kDepth = 2;

  uint32 size = 0;
  uint32 unpadded_row_size = 0;
  uint32 padded_row_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, 2, kDepth, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, &unpadded_row_size, &padded_row_size));
  // Makes sure we can just send over the data in one command.
  const GLsizei kHeight = MaxTransferBufferSize() / padded_row_size / kDepth;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, NULL, NULL));

  scoped_ptr<uint8[]> pixels(new uint8[size]);
  for (uint32 ii = 0; ii < size; ++ii) {
    pixels[ii] = static_cast<uint8>(ii);
  }

  ExpectedMemoryInfo mem = GetExpectedMemory(size);

  Cmds expected;
  expected.tex_image_3d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, kDepth,
      kFormat, kType, mem.id, mem.offset);

  gl_->TexImage3D(
      kTarget, kLevel, kFormat, kWidth, kHeight, kDepth, kBorder,
      kFormat, kType, pixels.get());

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(CheckRect(
      kWidth, kHeight * kDepth, kFormat, kType, kPixelStoreUnpackAlignment,
      false, reinterpret_cast<uint8*>(pixels.get()), mem.ptr));
}

TEST_F(GLES2ImplementationTest, TexImage3DViaTexSubImage3D) {
  struct Cmds {
    cmds::TexImage3D tex_image_3d;
    cmds::TexSubImage3D tex_sub_image_3d1;
    cmd::SetToken set_token;
    cmds::TexSubImage3D tex_sub_image_3d2;
  };
  const GLenum kTarget = GL_TEXTURE_3D;
  const GLint kLevel = 0;
  const GLint kBorder = 0;
  const GLenum kFormat = GL_RGB;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  const GLsizei kWidth = 3;

  uint32 size = 0;
  uint32 unpadded_row_size = 0;
  uint32 padded_row_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, 2, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, &unpadded_row_size, &padded_row_size));
  // Makes sure the data is more than one command can hold.
  const GLsizei kHeight = MaxTransferBufferSize() / padded_row_size + 3;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, NULL, NULL));
  uint32 first_size = padded_row_size * (kHeight - 3);
  uint32 second_size =
      padded_row_size * 3 - (padded_row_size - unpadded_row_size);
  EXPECT_EQ(size, first_size + second_size);
  ExpectedMemoryInfo mem1 = GetExpectedMemory(first_size);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(second_size);
  scoped_ptr<uint8[]> pixels(new uint8[size]);
  for (uint32 ii = 0; ii < size; ++ii) {
    pixels[ii] = static_cast<uint8>(ii);
  }

  Cmds expected;
  expected.tex_image_3d.Init(
      kTarget, kLevel, kFormat, kWidth, kHeight, 1, kFormat, kType, 0, 0);
  expected.tex_sub_image_3d1.Init(
      kTarget, kLevel, 0, 0, 0, kWidth, kHeight - 3, 1, kFormat, kType,
      mem1.id, mem1.offset, GL_TRUE);
  expected.tex_sub_image_3d2.Init(
      kTarget, kLevel, 0, kHeight - 3, 0, kWidth, 3, 1, kFormat, kType,
      mem2.id, mem2.offset, GL_TRUE);
  expected.set_token.Init(GetNextToken());

  gl_->TexImage3D(
      kTarget, kLevel, kFormat, kWidth, kHeight, 1, kBorder,
      kFormat, kType, pixels.get());
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

// Test TexSubImage3D with 4 writes
TEST_F(GLES2ImplementationTest, TexSubImage3D4Writes) {
  struct Cmds {
    cmds::TexSubImage3D tex_sub_image_3d1_1;
    cmd::SetToken set_token1;
    cmds::TexSubImage3D tex_sub_image_3d1_2;
    cmd::SetToken set_token2;
    cmds::TexSubImage3D tex_sub_image_3d2_1;
    cmd::SetToken set_token3;
    cmds::TexSubImage3D tex_sub_image_3d2_2;
  };
  const GLenum kTarget = GL_TEXTURE_3D;
  const GLint kLevel = 0;
  const GLint kXOffset = 0;
  const GLint kYOffset = 0;
  const GLint kZOffset = 0;
  const GLenum kFormat = GL_RGB;
  const GLenum kType = GL_UNSIGNED_BYTE;
  const GLint kPixelStoreUnpackAlignment = 4;
  const GLsizei kWidth = 3;
  const GLsizei kDepth = 2;

  uint32 size = 0;
  uint32 unpadded_row_size = 0;
  uint32 padded_row_size = 0;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, 2, 1, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, &unpadded_row_size, &padded_row_size));
  const GLsizei kHeight = MaxTransferBufferSize() / padded_row_size + 2;
  ASSERT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, kFormat, kType, kPixelStoreUnpackAlignment,
      &size, NULL, NULL));
  uint32 first_size = (kHeight - 2) * padded_row_size;
  uint32 second_size = 2 * padded_row_size;
  uint32 third_size = first_size;
  uint32 fourth_size = second_size - (padded_row_size - unpadded_row_size);
  EXPECT_EQ(size, first_size + second_size + third_size + fourth_size);

  scoped_ptr<uint8[]> pixels(new uint8[size]);
  for (uint32 ii = 0; ii < size; ++ii) {
    pixels[ii] = static_cast<uint8>(ii);
  }

  ExpectedMemoryInfo mem1_1 = GetExpectedMemory(first_size);
  ExpectedMemoryInfo mem1_2 = GetExpectedMemory(second_size);
  ExpectedMemoryInfo mem2_1 = GetExpectedMemory(third_size);
  ExpectedMemoryInfo mem2_2 = GetExpectedMemory(fourth_size);

  Cmds expected;
  expected.tex_sub_image_3d1_1.Init(
      kTarget, kLevel, kXOffset, kYOffset, kZOffset,
      kWidth, kHeight - 2, 1, kFormat, kType,
      mem1_1.id, mem1_1.offset, GL_FALSE);
  expected.tex_sub_image_3d1_2.Init(
      kTarget, kLevel, kXOffset, kYOffset + kHeight - 2, kZOffset,
      kWidth, 2, 1, kFormat, kType, mem1_2.id, mem1_2.offset, GL_FALSE);
  expected.tex_sub_image_3d2_1.Init(
      kTarget, kLevel, kXOffset, kYOffset, kZOffset + 1,
      kWidth, kHeight - 2, 1, kFormat, kType,
      mem2_1.id, mem2_1.offset, GL_FALSE);
  expected.tex_sub_image_3d2_2.Init(
      kTarget, kLevel, kXOffset, kYOffset + kHeight - 2, kZOffset + 1,
      kWidth, 2, 1, kFormat, kType, mem2_2.id, mem2_2.offset, GL_FALSE);
  expected.set_token1.Init(GetNextToken());
  expected.set_token2.Init(GetNextToken());
  expected.set_token3.Init(GetNextToken());

  gl_->TexSubImage3D(
      kTarget, kLevel, kXOffset, kYOffset, kZOffset, kWidth, kHeight, kDepth,
      kFormat, kType, pixels.get());

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  uint32 offset_to_last = first_size + second_size + third_size;
  EXPECT_TRUE(CheckRect(
      kWidth, 2, kFormat, kType, kPixelStoreUnpackAlignment, false,
      reinterpret_cast<uint8*>(pixels.get()) + offset_to_last, mem2_2.ptr));
}

// glGen* Ids must not be reused until glDelete* commands have been
// flushed by glFlush.
TEST_F(GLES2ImplementationStrictSharedTest, FlushGenerationTestBuffers) {
  FlushGenerationTest<GenBuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest, FlushGenerationTestFramebuffers) {
  FlushGenerationTest<GenFramebuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest, FlushGenerationTestRenderbuffers) {
  FlushGenerationTest<GenRenderbuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest, FlushGenerationTestTextures) {
  FlushGenerationTest<GenTexturesAPI>();
}

// glGen* Ids must not be reused cross-context until glDelete* commands are
// flushed by glFlush, and the Ids are lazily freed after.
TEST_F(GLES2ImplementationStrictSharedTest, CrossContextGenerationTestBuffers) {
  CrossContextGenerationTest<GenBuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationTestFramebuffers) {
  CrossContextGenerationTest<GenFramebuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationTestRenderbuffers) {
  CrossContextGenerationTest<GenRenderbuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationTestTextures) {
  CrossContextGenerationTest<GenTexturesAPI>();
}

// Test Delete which causes auto flush.  Tests a regression case that occurred
// in testing.
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationAutoFlushTestBuffers) {
  CrossContextGenerationAutoFlushTest<GenBuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationAutoFlushTestFramebuffers) {
  CrossContextGenerationAutoFlushTest<GenFramebuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationAutoFlushTestRenderbuffers) {
  CrossContextGenerationAutoFlushTest<GenRenderbuffersAPI>();
}
TEST_F(GLES2ImplementationStrictSharedTest,
       CrossContextGenerationAutoFlushTestTextures) {
  CrossContextGenerationAutoFlushTest<GenTexturesAPI>();
}

TEST_F(GLES2ImplementationTest, GetString) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const Str7 kString = {"foobar"};
  // GL_CHROMIUM_map_sub GL_CHROMIUM_flipy are hard coded into
  // GLES2Implementation.
  const char* expected_str =
      "foobar "
      "GL_CHROMIUM_flipy "
      "GL_EXT_unpack_subimage "
      "GL_CHROMIUM_map_sub";
  const char kBad = 0x12;
  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetString get_string;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
  };
  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));
  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_string.Init(GL_EXTENSIONS, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  char buf[sizeof(kString) + 1];
  memset(buf, kBad, sizeof(buf));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr, kString)))
      .RetiresOnSaturation();

  const GLubyte* result = gl_->GetString(GL_EXTENSIONS);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_STREQ(expected_str, reinterpret_cast<const char*>(result));
}

TEST_F(GLES2ImplementationTest, PixelStoreiGLPackReverseRowOrderANGLE) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const Str7 kString = {"foobar"};
  struct Cmds {
    cmd::SetBucketSize set_bucket_size1;
    cmds::GetString get_string;
    cmd::GetBucketStart get_bucket_start;
    cmd::SetToken set_token1;
    cmd::SetBucketSize set_bucket_size2;
    cmds::PixelStorei pixel_store;
  };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(MaxTransferBufferSize());
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmd::GetBucketStart::Result));

  Cmds expected;
  expected.set_bucket_size1.Init(kBucketId, 0);
  expected.get_string.Init(GL_EXTENSIONS, kBucketId);
  expected.get_bucket_start.Init(
      kBucketId, result1.id, result1.offset,
      MaxTransferBufferSize(), mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_size2.Init(kBucketId, 0);
  expected.pixel_store.Init(GL_PACK_REVERSE_ROW_ORDER_ANGLE, 1);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(DoAll(SetMemory(result1.ptr, uint32(sizeof(kString))),
                      SetMemory(mem1.ptr, kString)))
      .RetiresOnSaturation();

  gl_->PixelStorei(GL_PACK_REVERSE_ROW_ORDER_ANGLE, 1);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, CreateProgram) {
  struct Cmds {
    cmds::CreateProgram cmd;
  };

  Cmds expected;
  expected.cmd.Init(kProgramsAndShadersStartId);
  GLuint id = gl_->CreateProgram();
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(kProgramsAndShadersStartId, id);
}

TEST_F(GLES2ImplementationTest, BufferDataLargerThanTransferBuffer) {
  struct Cmds {
    cmds::BufferData set_size;
    cmds::BufferSubData copy_data1;
    cmd::SetToken set_token1;
    cmds::BufferSubData copy_data2;
    cmd::SetToken set_token2;
  };
  const unsigned kUsableSize =
      kTransferBufferSize - GLES2Implementation::kStartingOffset;
  uint8 buf[kUsableSize * 2] = { 0, };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kUsableSize);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kUsableSize);

  Cmds expected;
  expected.set_size.Init(
      GL_ARRAY_BUFFER, arraysize(buf), 0, 0, GL_DYNAMIC_DRAW);
  expected.copy_data1.Init(
      GL_ARRAY_BUFFER, 0, kUsableSize, mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.copy_data2.Init(
      GL_ARRAY_BUFFER, kUsableSize, kUsableSize, mem2.id, mem2.offset);
  expected.set_token2.Init(GetNextToken());
  gl_->BufferData(GL_ARRAY_BUFFER, arraysize(buf), buf, GL_DYNAMIC_DRAW);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, CapabilitiesAreCached) {
  static const GLenum kStates[] = {
    GL_DITHER,
    GL_BLEND,
    GL_CULL_FACE,
    GL_DEPTH_TEST,
    GL_POLYGON_OFFSET_FILL,
    GL_SAMPLE_ALPHA_TO_COVERAGE,
    GL_SAMPLE_COVERAGE,
    GL_SCISSOR_TEST,
    GL_STENCIL_TEST,
  };
  struct Cmds {
    cmds::Enable enable_cmd;
  };
  Cmds expected;

  for (size_t ii = 0; ii < arraysize(kStates); ++ii) {
    GLenum state = kStates[ii];
    expected.enable_cmd.Init(state);
    GLboolean result = gl_->IsEnabled(state);
    EXPECT_EQ(static_cast<GLboolean>(ii == 0), result);
    EXPECT_TRUE(NoCommandsWritten());
    const void* commands = GetPut();
    if (!result) {
      gl_->Enable(state);
      EXPECT_EQ(0, memcmp(&expected, commands, sizeof(expected)));
    }
    ClearCommands();
    result = gl_->IsEnabled(state);
    EXPECT_TRUE(result);
    EXPECT_TRUE(NoCommandsWritten());
  }
}

TEST_F(GLES2ImplementationTest, BindVertexArrayOES) {
  GLuint id = 0;
  gl_->GenVertexArraysOES(1, &id);
  ClearCommands();

  struct Cmds {
    cmds::BindVertexArrayOES cmd;
  };
  Cmds expected;
  expected.cmd.Init(id);

  const void* commands = GetPut();
  gl_->BindVertexArrayOES(id);
  EXPECT_EQ(0, memcmp(&expected, commands, sizeof(expected)));
  ClearCommands();
  gl_->BindVertexArrayOES(id);
  EXPECT_TRUE(NoCommandsWritten());
}

TEST_F(GLES2ImplementationTest, BeginEndQueryEXT) {
  // Test GetQueryivEXT returns 0 if no current query.
  GLint param = -1;
  gl_->GetQueryivEXT(GL_ANY_SAMPLES_PASSED_EXT, GL_CURRENT_QUERY_EXT, &param);
  EXPECT_EQ(0, param);

  GLuint expected_ids[2] = { 1, 2 }; // These must match what's actually genned.
  struct GenCmds {
    cmds::GenQueriesEXTImmediate gen;
    GLuint data[2];
  };
  GenCmds expected_gen_cmds;
  expected_gen_cmds.gen.Init(arraysize(expected_ids), &expected_ids[0]);
  GLuint ids[arraysize(expected_ids)] = { 0, };
  gl_->GenQueriesEXT(arraysize(expected_ids), &ids[0]);
  EXPECT_EQ(0, memcmp(
      &expected_gen_cmds, commands_, sizeof(expected_gen_cmds)));
  GLuint id1 = ids[0];
  GLuint id2 = ids[1];
  ClearCommands();

  // Test BeginQueryEXT fails if id = 0.
  gl_->BeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, 0);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test BeginQueryEXT inserts command.
  struct BeginCmds {
    cmds::BeginQueryEXT begin_query;
  };
  BeginCmds expected_begin_cmds;
  const void* commands = GetPut();
  gl_->BeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, id1);
  QueryTracker::Query* query = GetQuery(id1);
  ASSERT_TRUE(query != NULL);
  expected_begin_cmds.begin_query.Init(
      GL_ANY_SAMPLES_PASSED_EXT, id1, query->shm_id(), query->shm_offset());
  EXPECT_EQ(0, memcmp(
      &expected_begin_cmds, commands, sizeof(expected_begin_cmds)));
  ClearCommands();

  // Test GetQueryivEXT returns id.
  param = -1;
  gl_->GetQueryivEXT(GL_ANY_SAMPLES_PASSED_EXT, GL_CURRENT_QUERY_EXT, &param);
  EXPECT_EQ(id1, static_cast<GLuint>(param));
  gl_->GetQueryivEXT(
      GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT, GL_CURRENT_QUERY_EXT, &param);
  EXPECT_EQ(0, param);

  // Test BeginQueryEXT fails if between Begin/End.
  gl_->BeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, id2);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test EndQueryEXT fails if target not same as current query.
  ClearCommands();
  gl_->EndQueryEXT(GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test EndQueryEXT sends command
  struct EndCmds {
    cmds::EndQueryEXT end_query;
  };
  EndCmds expected_end_cmds;
  expected_end_cmds.end_query.Init(
      GL_ANY_SAMPLES_PASSED_EXT, query->submit_count());
  commands = GetPut();
  gl_->EndQueryEXT(GL_ANY_SAMPLES_PASSED_EXT);
  EXPECT_EQ(0, memcmp(
      &expected_end_cmds, commands, sizeof(expected_end_cmds)));

  // Test EndQueryEXT fails if no current query.
  ClearCommands();
  gl_->EndQueryEXT(GL_ANY_SAMPLES_PASSED_EXT);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test 2nd Begin/End increments count.
  base::subtle::Atomic32 old_submit_count = query->submit_count();
  gl_->BeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, id1);
  EXPECT_NE(old_submit_count, query->submit_count());
  expected_end_cmds.end_query.Init(
      GL_ANY_SAMPLES_PASSED_EXT, query->submit_count());
  commands = GetPut();
  gl_->EndQueryEXT(GL_ANY_SAMPLES_PASSED_EXT);
  EXPECT_EQ(0, memcmp(
      &expected_end_cmds, commands, sizeof(expected_end_cmds)));

  // Test BeginQueryEXT fails if target changed.
  ClearCommands();
  gl_->BeginQueryEXT(GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT, id1);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test GetQueryObjectuivEXT fails if unused id
  GLuint available = 0xBDu;
  ClearCommands();
  gl_->GetQueryObjectuivEXT(id2, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(0xBDu, available);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test GetQueryObjectuivEXT fails if bad id
  ClearCommands();
  gl_->GetQueryObjectuivEXT(4567, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(0xBDu, available);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  // Test GetQueryObjectuivEXT CheckResultsAvailable
  ClearCommands();
  gl_->GetQueryObjectuivEXT(id1, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  EXPECT_EQ(0u, available);
}

TEST_F(GLES2ImplementationTest, ErrorQuery) {
  GLuint id = 0;
  gl_->GenQueriesEXT(1, &id);
  ClearCommands();

  // Test BeginQueryEXT does NOT insert commands.
  gl_->BeginQueryEXT(GL_GET_ERROR_QUERY_CHROMIUM, id);
  EXPECT_TRUE(NoCommandsWritten());
  QueryTracker::Query* query = GetQuery(id);
  ASSERT_TRUE(query != NULL);

  // Test EndQueryEXT sends both begin and end command
  struct EndCmds {
    cmds::BeginQueryEXT begin_query;
    cmds::EndQueryEXT end_query;
  };
  EndCmds expected_end_cmds;
  expected_end_cmds.begin_query.Init(
      GL_GET_ERROR_QUERY_CHROMIUM, id, query->shm_id(), query->shm_offset());
  expected_end_cmds.end_query.Init(
      GL_GET_ERROR_QUERY_CHROMIUM, query->submit_count());
  const void* commands = GetPut();
  gl_->EndQueryEXT(GL_GET_ERROR_QUERY_CHROMIUM);
  EXPECT_EQ(0, memcmp(
      &expected_end_cmds, commands, sizeof(expected_end_cmds)));
  ClearCommands();

  // Check result is not yet available.
  GLuint available = 0xBDu;
  gl_->GetQueryObjectuivEXT(id, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(0u, available);

  // Test no commands are sent if there is a client side error.

  // Generate a client side error
  gl_->ActiveTexture(GL_TEXTURE0 - 1);

  gl_->BeginQueryEXT(GL_GET_ERROR_QUERY_CHROMIUM, id);
  gl_->EndQueryEXT(GL_GET_ERROR_QUERY_CHROMIUM);
  EXPECT_TRUE(NoCommandsWritten());

  // Check result is available.
  gl_->GetQueryObjectuivEXT(id, GL_QUERY_RESULT_AVAILABLE_EXT, &available);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_NE(0u, available);

  // Check result.
  GLuint result = 0xBDu;
  gl_->GetQueryObjectuivEXT(id, GL_QUERY_RESULT_EXT, &result);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(static_cast<GLuint>(GL_INVALID_ENUM), result);
}

#if !defined(GLES2_SUPPORT_CLIENT_SIDE_ARRAYS)
TEST_F(GLES2ImplementationTest, VertexArrays) {
  const GLuint kAttribIndex1 = 1;
  const GLint kNumComponents1 = 3;
  const GLsizei kClientStride = 12;

  GLuint id = 0;
  gl_->GenVertexArraysOES(1, &id);
  ClearCommands();

  gl_->BindVertexArrayOES(id);

  // Test that VertexAttribPointer cannot be called with a bound buffer of 0
  // unless the offset is NULL
  gl_->BindBuffer(GL_ARRAY_BUFFER, 0);

  gl_->VertexAttribPointer(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, kClientStride,
      reinterpret_cast<const void*>(4));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  gl_->VertexAttribPointer(
      kAttribIndex1, kNumComponents1, GL_FLOAT, GL_FALSE, kClientStride, NULL);
  EXPECT_EQ(GL_NO_ERROR, CheckError());
}
#endif

TEST_F(GLES2ImplementationTest, Disable) {
  struct Cmds {
    cmds::Disable cmd;
  };
  Cmds expected;
  expected.cmd.Init(GL_DITHER);  // Note: DITHER defaults to enabled.

  gl_->Disable(GL_DITHER);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  // Check it's cached and not called again.
  ClearCommands();
  gl_->Disable(GL_DITHER);
  EXPECT_TRUE(NoCommandsWritten());
}

TEST_F(GLES2ImplementationTest, Enable) {
  struct Cmds {
    cmds::Enable cmd;
  };
  Cmds expected;
  expected.cmd.Init(GL_BLEND);  // Note: BLEND defaults to disabled.

  gl_->Enable(GL_BLEND);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  // Check it's cached and not called again.
  ClearCommands();
  gl_->Enable(GL_BLEND);
  EXPECT_TRUE(NoCommandsWritten());
}

TEST_F(GLES2ImplementationTest, ConsumeTextureCHROMIUM) {
  struct Cmds {
    cmds::ConsumeTextureCHROMIUMImmediate cmd;
    GLbyte data[64];
  };

  Mailbox mailbox = Mailbox::Generate();
  Cmds expected;
  expected.cmd.Init(GL_TEXTURE_2D, mailbox.name);
  gl_->ConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, CreateAndConsumeTextureCHROMIUM) {
  struct Cmds {
    cmds::CreateAndConsumeTextureCHROMIUMImmediate cmd;
    GLbyte data[64];
  };

  Mailbox mailbox = Mailbox::Generate();
  Cmds expected;
  expected.cmd.Init(GL_TEXTURE_2D, kTexturesStartId, mailbox.name);
  GLuint id = gl_->CreateAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(kTexturesStartId, id);
}

TEST_F(GLES2ImplementationTest, ProduceTextureCHROMIUM) {
  struct Cmds {
    cmds::ProduceTextureCHROMIUMImmediate cmd;
    GLbyte data[64];
  };

  Mailbox mailbox = Mailbox::Generate();
  Cmds expected;
  expected.cmd.Init(GL_TEXTURE_2D, mailbox.name);
  gl_->ProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, ProduceTextureDirectCHROMIUM) {
  struct Cmds {
    cmds::ProduceTextureDirectCHROMIUMImmediate cmd;
    GLbyte data[64];
  };

  Mailbox mailbox = Mailbox::Generate();
  Cmds expected;
  expected.cmd.Init(kTexturesStartId, GL_TEXTURE_2D, mailbox.name);
  gl_->ProduceTextureDirectCHROMIUM(
      kTexturesStartId, GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, LimitSizeAndOffsetTo32Bit) {
  GLsizeiptr size;
  GLintptr offset;
  if (sizeof(size) <= 4 || sizeof(offset) <= 4)
    return;
  // The below two casts should be no-op, as we return early if
  // it's 32-bit system.
  int64 value64 = 0x100000000;
  size = static_cast<GLsizeiptr>(value64);
  offset = static_cast<GLintptr>(value64);

  const char kSizeOverflowMessage[] = "size more than 32-bit";
  const char kOffsetOverflowMessage[] = "offset more than 32-bit";

  const GLfloat buf[] = { 1.0, 1.0, 1.0, 1.0 };
  const GLubyte indices[] = { 0 };

  const GLuint kClientArrayBufferId = 0x789;
  const GLuint kClientElementArrayBufferId = 0x790;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kClientArrayBufferId);
  gl_->BindBuffer(GL_ELEMENT_ARRAY_BUFFER, kClientElementArrayBufferId);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // Call BufferData() should succeed with legal paramaters.
  gl_->BufferData(GL_ARRAY_BUFFER, sizeof(buf), buf, GL_DYNAMIC_DRAW);
  gl_->BufferData(
      GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_DYNAMIC_DRAW);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // BufferData: size
  gl_->BufferData(GL_ARRAY_BUFFER, size, buf, GL_DYNAMIC_DRAW);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kSizeOverflowMessage, GetLastError().c_str());

  // Call BufferSubData() should succeed with legal paramaters.
  gl_->BufferSubData(GL_ARRAY_BUFFER, 0, sizeof(buf[0]), buf);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // BufferSubData: offset
  gl_->BufferSubData(GL_ARRAY_BUFFER, offset, 1, buf);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kOffsetOverflowMessage, GetLastError().c_str());

  // BufferSubData: size
  EXPECT_EQ(GL_NO_ERROR, CheckError());
  gl_->BufferSubData(GL_ARRAY_BUFFER, 0, size, buf);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kSizeOverflowMessage, GetLastError().c_str());

  // Call MapBufferSubDataCHROMIUM() should succeed with legal paramaters.
  void* mem =
      gl_->MapBufferSubDataCHROMIUM(GL_ARRAY_BUFFER, 0, 1, GL_WRITE_ONLY);
  EXPECT_TRUE(NULL != mem);
  EXPECT_EQ(GL_NO_ERROR, CheckError());
  gl_->UnmapBufferSubDataCHROMIUM(mem);

  // MapBufferSubDataCHROMIUM: offset
  EXPECT_TRUE(NULL == gl_->MapBufferSubDataCHROMIUM(
      GL_ARRAY_BUFFER, offset, 1, GL_WRITE_ONLY));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kOffsetOverflowMessage, GetLastError().c_str());

  // MapBufferSubDataCHROMIUM: size
  EXPECT_EQ(GL_NO_ERROR, CheckError());
  EXPECT_TRUE(NULL == gl_->MapBufferSubDataCHROMIUM(
      GL_ARRAY_BUFFER, 0, size, GL_WRITE_ONLY));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kSizeOverflowMessage, GetLastError().c_str());

  // Call DrawElements() should succeed with legal paramaters.
  gl_->DrawElements(GL_POINTS, 1, GL_UNSIGNED_BYTE, NULL);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // DrawElements: offset
  gl_->DrawElements(
      GL_POINTS, 1, GL_UNSIGNED_BYTE, reinterpret_cast<void*>(offset));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kOffsetOverflowMessage, GetLastError().c_str());

  // Call DrawElementsInstancedANGLE() should succeed with legal paramaters.
  gl_->DrawElementsInstancedANGLE(GL_POINTS, 1, GL_UNSIGNED_BYTE, NULL, 1);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // DrawElementsInstancedANGLE: offset
  gl_->DrawElementsInstancedANGLE(
      GL_POINTS, 1, GL_UNSIGNED_BYTE, reinterpret_cast<void*>(offset), 1);
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kOffsetOverflowMessage, GetLastError().c_str());

  // Call VertexAttribPointer() should succeed with legal paramaters.
  const GLuint kAttribIndex = 1;
  const GLsizei kStride = 4;
  gl_->VertexAttribPointer(
      kAttribIndex, 1, GL_FLOAT, GL_FALSE, kStride, NULL);
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // VertexAttribPointer: offset
  gl_->VertexAttribPointer(
      kAttribIndex, 1, GL_FLOAT, GL_FALSE, kStride,
      reinterpret_cast<void*>(offset));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
  EXPECT_STREQ(kOffsetOverflowMessage, GetLastError().c_str());
}

TEST_F(GLES2ImplementationTest, TraceBeginCHROMIUM) {
  const uint32 kCategoryBucketId = GLES2Implementation::kResultBucketId;
  const uint32 kNameBucketId = GLES2Implementation::kResultBucketId + 1;
  const std::string category_name = "test category";
  const std::string trace_name = "test trace";
  const size_t kPaddedString1Size =
      transfer_buffer_->RoundToAlignment(category_name.size() + 1);
  const size_t kPaddedString2Size =
      transfer_buffer_->RoundToAlignment(trace_name.size() + 1);

  gl_->TraceBeginCHROMIUM(category_name.c_str(), trace_name.c_str());
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  struct Cmds {
    cmd::SetBucketSize category_size1;
    cmd::SetBucketData category_data;
    cmd::SetToken set_token1;
    cmd::SetBucketSize name_size1;
    cmd::SetBucketData name_data;
    cmd::SetToken set_token2;
    cmds::TraceBeginCHROMIUM trace_call_begin;
    cmd::SetBucketSize category_size2;
    cmd::SetBucketSize name_size2;
  };

  ExpectedMemoryInfo mem1 = GetExpectedMemory(kPaddedString1Size);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kPaddedString2Size);

  ASSERT_STREQ(category_name.c_str(), reinterpret_cast<char*>(mem1.ptr));
  ASSERT_STREQ(trace_name.c_str(), reinterpret_cast<char*>(mem2.ptr));

  Cmds expected;
  expected.category_size1.Init(kCategoryBucketId, category_name.size() + 1);
  expected.category_data.Init(
      kCategoryBucketId, 0, category_name.size() + 1, mem1.id, mem1.offset);
  expected.set_token1.Init(GetNextToken());
  expected.name_size1.Init(kNameBucketId, trace_name.size() + 1);
  expected.name_data.Init(
      kNameBucketId, 0, trace_name.size() + 1, mem2.id, mem2.offset);
  expected.set_token2.Init(GetNextToken());
  expected.trace_call_begin.Init(kCategoryBucketId, kNameBucketId);
  expected.category_size2.Init(kCategoryBucketId, 0);
  expected.name_size2.Init(kNameBucketId, 0);

  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, AllowNestedTracesCHROMIUM) {
  const std::string category1_name = "test category 1";
  const std::string trace1_name = "test trace 1";
  const std::string category2_name = "test category 2";
  const std::string trace2_name = "test trace 2";

  gl_->TraceBeginCHROMIUM(category1_name.c_str(), trace1_name.c_str());
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  gl_->TraceBeginCHROMIUM(category2_name.c_str(), trace2_name.c_str());
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  gl_->TraceEndCHROMIUM();
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  gl_->TraceEndCHROMIUM();
  EXPECT_EQ(GL_NO_ERROR, CheckError());

  // No more corresponding begin tracer marker should error.
  gl_->TraceEndCHROMIUM();
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
}

TEST_F(GLES2ImplementationTest, IsEnabled) {
  // If we use a valid enum, its state is cached on client side, so no command
  // is actually generated, and this test will fail.
  // TODO(zmo): it seems we never need the command. Maybe remove it.
  GLenum kCap = 1;
  struct Cmds {
    cmds::IsEnabled cmd;
  };

  Cmds expected;
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::IsEnabled::Result));
  expected.cmd.Init(kCap, result1.id, result1.offset);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, uint32_t(GL_TRUE)))
      .RetiresOnSaturation();

  GLboolean result = gl_->IsEnabled(kCap);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(result);
}

TEST_F(GLES2ImplementationTest, ClientWaitSync) {
  const GLuint client_sync_id = 36;
  struct Cmds {
    cmds::ClientWaitSync cmd;
  };

  Cmds expected;
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::ClientWaitSync::Result));
  const GLuint64 kTimeout = 0xABCDEF0123456789;
  uint32_t v32_0 = 0, v32_1 = 0;
  GLES2Util::MapUint64ToTwoUint32(kTimeout, &v32_0, &v32_1);
  expected.cmd.Init(client_sync_id, GL_SYNC_FLUSH_COMMANDS_BIT,
                    v32_0, v32_1, result1.id, result1.offset);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, uint32_t(GL_CONDITION_SATISFIED)))
      .RetiresOnSaturation();

  GLenum result = gl_->ClientWaitSync(
      reinterpret_cast<GLsync>(client_sync_id), GL_SYNC_FLUSH_COMMANDS_BIT,
      kTimeout);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<GLenum>(GL_CONDITION_SATISFIED), result);
}

TEST_F(GLES2ImplementationTest, WaitSync) {
  const GLuint kClientSyncId = 36;
  struct Cmds {
    cmds::WaitSync cmd;
  };
  Cmds expected;
  const GLuint64 kTimeout = GL_TIMEOUT_IGNORED;
  uint32_t v32_0 = 0, v32_1 = 0;
  GLES2Util::MapUint64ToTwoUint32(kTimeout, &v32_0, &v32_1);
  expected.cmd.Init(kClientSyncId, 0, v32_0, v32_1);

  gl_->WaitSync(reinterpret_cast<GLsync>(kClientSyncId), 0, kTimeout);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationTest, MapBufferRangeUnmapBufferWrite) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(1)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_WRITE_BIT);
  EXPECT_TRUE(mem != nullptr);

  EXPECT_TRUE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
}

TEST_F(GLES2ImplementationTest, MapBufferRangeWriteWithInvalidateBit) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(1)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  GLsizeiptr kSize = 64;
  void* mem = gl_->MapBufferRange(
      GL_ARRAY_BUFFER, 10, kSize,
      GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_RANGE_BIT);
  EXPECT_TRUE(mem != nullptr);
  std::vector<int8_t> zero(kSize);
  memset(&zero[0], 0, kSize);
  EXPECT_EQ(0, memcmp(mem, &zero[0], kSize));
}

TEST_F(GLES2ImplementationTest, MapBufferRangeWriteWithGLError) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  // Return a result of 0 to indicate an GL error.
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(0)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_WRITE_BIT);
  EXPECT_TRUE(mem == nullptr);
}

TEST_F(GLES2ImplementationTest, MapBufferRangeUnmapBufferRead) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(1)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_READ_BIT);
  EXPECT_TRUE(mem != nullptr);

  EXPECT_TRUE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
}

TEST_F(GLES2ImplementationTest, MapBufferRangeReadWithGLError) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  // Return a result of 0 to indicate an GL error.
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(0)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_READ_BIT);
  EXPECT_TRUE(mem == nullptr);
}

TEST_F(GLES2ImplementationTest, UnmapBufferFails) {
  // No bound buffer.
  EXPECT_FALSE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  // Buffer is unmapped.
  EXPECT_FALSE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
}

TEST_F(GLES2ImplementationTest, BufferDataUnmapsDataStore) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(1)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_WRITE_BIT);
  EXPECT_TRUE(mem != nullptr);

  std::vector<uint8_t> data(16);
  // BufferData unmaps the data store.
  gl_->BufferData(GL_ARRAY_BUFFER, 16, &data[0], GL_STREAM_DRAW);

  EXPECT_FALSE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
}

TEST_F(GLES2ImplementationTest, DeleteBuffersUnmapsDataStore) {
  ExpectedMemoryInfo result =
      GetExpectedResultMemory(sizeof(cmds::MapBufferRange::Result));

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result.ptr, uint32_t(1)))
      .RetiresOnSaturation();

  const GLuint kBufferId = 123;
  gl_->BindBuffer(GL_ARRAY_BUFFER, kBufferId);

  void* mem = gl_->MapBufferRange(GL_ARRAY_BUFFER, 10, 64, GL_MAP_WRITE_BIT);
  EXPECT_TRUE(mem != nullptr);

  std::vector<uint8_t> data(16);
  // DeleteBuffers unmaps the data store.
  gl_->DeleteBuffers(1, &kBufferId);

  EXPECT_FALSE(gl_->UnmapBuffer(GL_ARRAY_BUFFER));
  EXPECT_EQ(GL_INVALID_OPERATION, CheckError());
}

TEST_F(GLES2ImplementationManualInitTest, LoseContextOnOOM) {
  ContextInitOptions init_options;
  init_options.lose_context_when_out_of_memory = true;
  ASSERT_TRUE(Initialize(init_options));

  struct Cmds {
    cmds::LoseContextCHROMIUM cmd;
  };

  GLsizei max = std::numeric_limits<GLsizei>::max();
  EXPECT_CALL(*gpu_control_, CreateGpuMemoryBufferImage(max, max, _, _))
      .WillOnce(Return(-1));
  gl_->CreateGpuMemoryBufferImageCHROMIUM(max, max, GL_RGBA, GL_MAP_CHROMIUM);
  // The context should be lost.
  Cmds expected;
  expected.cmd.Init(GL_GUILTY_CONTEXT_RESET_ARB, GL_UNKNOWN_CONTEXT_RESET_ARB);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}

TEST_F(GLES2ImplementationManualInitTest, NoLoseContextOnOOM) {
  ContextInitOptions init_options;
  ASSERT_TRUE(Initialize(init_options));

  struct Cmds {
    cmds::LoseContextCHROMIUM cmd;
  };

  GLsizei max = std::numeric_limits<GLsizei>::max();
  EXPECT_CALL(*gpu_control_, CreateGpuMemoryBufferImage(max, max, _, _))
      .WillOnce(Return(-1));
  gl_->CreateGpuMemoryBufferImageCHROMIUM(max, max, GL_RGBA, GL_MAP_CHROMIUM);
  // The context should not be lost.
  EXPECT_TRUE(NoCommandsWritten());
}

TEST_F(GLES2ImplementationManualInitTest, FailInitOnBGRMismatch1) {
  ContextInitOptions init_options;
  init_options.bind_generates_resource_client = false;
  init_options.bind_generates_resource_service = true;
  EXPECT_FALSE(Initialize(init_options));
}

TEST_F(GLES2ImplementationManualInitTest, FailInitOnBGRMismatch2) {
  ContextInitOptions init_options;
  init_options.bind_generates_resource_client = true;
  init_options.bind_generates_resource_service = false;
  EXPECT_FALSE(Initialize(init_options));
}

TEST_F(GLES2ImplementationManualInitTest, FailInitOnTransferBufferFail) {
  ContextInitOptions init_options;
  init_options.transfer_buffer_initialize_fail = true;
  EXPECT_FALSE(Initialize(init_options));
}

#include "gpu/command_buffer/client/gles2_implementation_unittest_autogen.h"

}  // namespace gles2
}  // namespace gpu
