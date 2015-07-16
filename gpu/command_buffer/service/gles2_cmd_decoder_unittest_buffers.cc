// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"

using ::gfx::MockGLInterface;
using ::testing::_;
using ::testing::Return;
using ::testing::SetArgPointee;

namespace gpu {
namespace gles2 {

using namespace cmds;

namespace {

}  // namespace anonymous

TEST_P(GLES2DecoderTest, MapBufferRangeUnmapBufferReadSucceeds) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_READ_BIT;

  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  // uint32_t is Result for both MapBufferRange and UnmapBuffer commands.
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(uint32_t);

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }

  {  // MapBufferRange
    EXPECT_CALL(*gl_,
                MapBufferRange(kTarget, kOffset, kSize, kAccess))
        .WillOnce(Return(&data[0]))
        .RetiresOnSaturation();

    typedef MapBufferRange::Result Result;
    Result* result = GetSharedMemoryAs<Result*>();

    MapBufferRange cmd;
    cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
             result_shm_id, result_shm_offset);
    decoder_->set_unsafe_es3_apis_enabled(false);
    *result = 0;
    EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
    EXPECT_EQ(0u, *result);
    decoder_->set_unsafe_es3_apis_enabled(true);
    *result = 0;
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
    EXPECT_EQ(0, memcmp(&data[0], mem, kSize));
    EXPECT_EQ(1u, *result);
  }

  {  // UnmapBuffer
    EXPECT_CALL(*gl_, UnmapBuffer(kTarget))
        .WillOnce(Return(GL_TRUE))
        .RetiresOnSaturation();

    UnmapBuffer cmd;
    cmd.Init(kTarget);
    decoder_->set_unsafe_es3_apis_enabled(false);
    EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
    decoder_->set_unsafe_es3_apis_enabled(true);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  }

  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, MapBufferRangeUnmapBufferWriteSucceeds) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_WRITE_BIT;
  const GLbitfield kMappedAccess = GL_MAP_WRITE_BIT | GL_MAP_READ_BIT;

  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  // uint32_t is Result for both MapBufferRange and UnmapBuffer commands.
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(uint32_t);

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }

  {  // MapBufferRange succeeds
    EXPECT_CALL(*gl_,
                MapBufferRange(kTarget, kOffset, kSize, kMappedAccess))
        .WillOnce(Return(&data[0]))
        .RetiresOnSaturation();

    typedef MapBufferRange::Result Result;
    Result* result = GetSharedMemoryAs<Result*>();

    MapBufferRange cmd;
    cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
             result_shm_id, result_shm_offset);
    decoder_->set_unsafe_es3_apis_enabled(false);
    *result = 0;
    EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
    EXPECT_EQ(0u, *result);
    decoder_->set_unsafe_es3_apis_enabled(true);
    *result = 0;
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
    EXPECT_EQ(0, memcmp(&data[0], mem, kSize));
    EXPECT_EQ(1u, *result);
  }

  { // UnmapBuffer succeeds
    EXPECT_CALL(*gl_, UnmapBuffer(kTarget))
        .WillOnce(Return(GL_TRUE))
        .RetiresOnSaturation();

    UnmapBuffer cmd;
    cmd.Init(kTarget);
    decoder_->set_unsafe_es3_apis_enabled(false);
    EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
    decoder_->set_unsafe_es3_apis_enabled(true);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  }

  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, MapBufferRangeNotInitFails) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_READ_BIT;
  std::vector<int8_t> data(kSize);

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 1;  // Any value other than 0.
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
           result_shm_id, result_shm_offset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, MapBufferRangeWriteInvalidateRangeSucceeds) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  // With MAP_INVALIDATE_RANGE_BIT, no need to append MAP_READ_BIT.
  const GLbitfield kAccess = GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_RANGE_BIT;

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }
  EXPECT_CALL(*gl_,
              MapBufferRange(kTarget, kOffset, kSize, kAccess))
      .WillOnce(Return(&data[0]))
      .RetiresOnSaturation();

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 0;
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
  memset(mem, 72, kSize);  // Init to a random value other than 0.

  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
           result_shm_id, result_shm_offset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, MapBufferRangeWriteInvalidateBufferSucceeds) {
  // Test INVALIDATE_BUFFER_BIT is mapped to INVALIDATE_RANGE_BIT.
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT;
  // With MAP_INVALIDATE_BUFFER_BIT, no need to append MAP_READ_BIT.
  const GLbitfield kFilteredAccess =
      GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_RANGE_BIT;

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }
  EXPECT_CALL(*gl_,
              MapBufferRange(kTarget, kOffset, kSize, kFilteredAccess))
      .WillOnce(Return(&data[0]))
      .RetiresOnSaturation();

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 0;
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
  memset(mem, 72, kSize);  // Init to a random value other than 0.

  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
           result_shm_id, result_shm_offset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, MapBufferRangeWriteUnsynchronizedBit) {
  // Test UNSYNCHRONIZED_BIT is filtered out.
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_WRITE_BIT | GL_MAP_UNSYNCHRONIZED_BIT;
  const GLbitfield kFilteredAccess = GL_MAP_WRITE_BIT | GL_MAP_READ_BIT;

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }
  EXPECT_CALL(*gl_,
              MapBufferRange(kTarget, kOffset, kSize, kFilteredAccess))
      .WillOnce(Return(&data[0]))
      .RetiresOnSaturation();

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 0;
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
  memset(mem, 72, kSize);  // Init to a random value other than 0.

  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
           result_shm_id, result_shm_offset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, memcmp(&data[0], mem, kSize));
}

TEST_P(GLES2DecoderTest, MapBufferRangeWithError) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_READ_BIT;
  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }
  EXPECT_CALL(*gl_,
              MapBufferRange(kTarget, kOffset, kSize, kAccess))
      .WillOnce(Return(nullptr))  // Return nullptr to indicate a GL error.
      .RetiresOnSaturation();

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 0;
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  int8_t* mem = reinterpret_cast<int8_t*>(&result[1]);
  memset(mem, 72, kSize);  // Init to a random value other than 0.

  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
           result_shm_id, result_shm_offset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  memset(&data[0], 72, kSize);
  // Mem is untouched.
  EXPECT_EQ(0, memcmp(&data[0], mem, kSize));
  EXPECT_EQ(0u, *result);
}

TEST_P(GLES2DecoderTest, MapBufferRangeBadSharedMemoryFails) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_READ_BIT;
  std::vector<int8_t> data(kSize);
  for (GLsizeiptr ii = 0; ii < kSize; ++ii) {
    data[ii] = static_cast<int8_t>(ii % 255);
  }

  typedef MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = 0;
  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(*result);

  decoder_->set_unsafe_es3_apis_enabled(true);
  MapBufferRange cmd;
  cmd.Init(kTarget, kOffset, kSize, kAccess,
           kInvalidSharedMemoryId, data_shm_offset,
           result_shm_id, result_shm_offset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(kTarget, kOffset, kSize, kAccess,
           data_shm_id, data_shm_offset,
           kInvalidSharedMemoryId, result_shm_offset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(kTarget, kOffset, kSize, kAccess,
           data_shm_id, kInvalidSharedMemoryOffset,
           result_shm_id, result_shm_offset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(kTarget, kOffset, kSize, kAccess,
           data_shm_id, data_shm_offset,
           result_shm_id, kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, UnmapBufferWriteNotMappedFails) {
  const GLenum kTarget = GL_ARRAY_BUFFER;

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  UnmapBuffer cmd;
  cmd.Init(kTarget);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, UnmapBufferWriteNoBoundBufferFails) {
  const GLenum kTarget = GL_ARRAY_BUFFER;

  UnmapBuffer cmd;
  cmd.Init(kTarget);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, BufferDataDestroysDataStore) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_WRITE_BIT;
  const GLbitfield kFilteredAccess = GL_MAP_WRITE_BIT | GL_MAP_READ_BIT;

  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  // uint32_t is Result for both MapBufferRange and UnmapBuffer commands.
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(uint32_t);

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);

  decoder_->set_unsafe_es3_apis_enabled(true);

  {  // MapBufferRange succeeds
    EXPECT_CALL(*gl_,
                MapBufferRange(kTarget, kOffset, kSize, kFilteredAccess))
        .WillOnce(Return(&data[0]))
        .RetiresOnSaturation();

    typedef MapBufferRange::Result Result;
    Result* result = GetSharedMemoryAs<Result*>();

    MapBufferRange cmd;
    cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
             result_shm_id, result_shm_offset);
    *result = 0;
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(1u, *result);
  }

  {  // BufferData unmaps the data store.
    DoBufferData(kTarget, kSize * 2);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }

  {  // UnmapBuffer fails.
    UnmapBuffer cmd;
    cmd.Init(kTarget);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  }
}

TEST_P(GLES2DecoderTest, DeleteBuffersDestroysDataStore) {
  const GLenum kTarget = GL_ARRAY_BUFFER;
  const GLintptr kOffset = 10;
  const GLsizeiptr kSize = 64;
  const GLbitfield kAccess = GL_MAP_WRITE_BIT;
  const GLbitfield kFilteredAccess = GL_MAP_WRITE_BIT | GL_MAP_READ_BIT;

  uint32_t result_shm_id = kSharedMemoryId;
  uint32_t result_shm_offset = kSharedMemoryOffset;
  uint32_t data_shm_id = kSharedMemoryId;
  // uint32_t is Result for both MapBufferRange and UnmapBuffer commands.
  uint32_t data_shm_offset = kSharedMemoryOffset + sizeof(uint32_t);

  DoBindBuffer(kTarget, client_buffer_id_, kServiceBufferId);

  std::vector<int8_t> data(kSize);

  decoder_->set_unsafe_es3_apis_enabled(true);

  {  // MapBufferRange succeeds
    EXPECT_CALL(*gl_,
                MapBufferRange(kTarget, kOffset, kSize, kFilteredAccess))
        .WillOnce(Return(&data[0]))
        .RetiresOnSaturation();

    typedef MapBufferRange::Result Result;
    Result* result = GetSharedMemoryAs<Result*>();

    MapBufferRange cmd;
    cmd.Init(kTarget, kOffset, kSize, kAccess, data_shm_id, data_shm_offset,
             result_shm_id, result_shm_offset);
    *result = 0;
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(1u, *result);
  }

  {  // DeleteBuffers unmaps the data store.
    DoDeleteBuffer(client_buffer_id_, kServiceBufferId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }

  {  // UnmapBuffer fails.
    UnmapBuffer cmd;
    cmd.Init(kTarget);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  }
}

}  // namespace gles2
}  // namespace gpu
