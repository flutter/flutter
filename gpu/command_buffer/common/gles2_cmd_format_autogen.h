// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#ifndef GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_FORMAT_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_FORMAT_AUTOGEN_H_

#define GL_SYNC_FLUSH_COMMANDS_BIT 0x00000001
#define GL_SYNC_GPU_COMMANDS_COMPLETE 0x9117

struct ActiveTexture {
  typedef ActiveTexture ValueType;
  static const CommandId kCmdId = kActiveTexture;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _texture) {
    SetHeader();
    texture = _texture;
  }

  void* Set(void* cmd, GLenum _texture) {
    static_cast<ValueType*>(cmd)->Init(_texture);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t texture;
};

static_assert(sizeof(ActiveTexture) == 8, "size of ActiveTexture should be 8");
static_assert(offsetof(ActiveTexture, header) == 0,
              "offset of ActiveTexture header should be 0");
static_assert(offsetof(ActiveTexture, texture) == 4,
              "offset of ActiveTexture texture should be 4");

struct AttachShader {
  typedef AttachShader ValueType;
  static const CommandId kCmdId = kAttachShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, GLuint _shader) {
    SetHeader();
    program = _program;
    shader = _shader;
  }

  void* Set(void* cmd, GLuint _program, GLuint _shader) {
    static_cast<ValueType*>(cmd)->Init(_program, _shader);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t shader;
};

static_assert(sizeof(AttachShader) == 12, "size of AttachShader should be 12");
static_assert(offsetof(AttachShader, header) == 0,
              "offset of AttachShader header should be 0");
static_assert(offsetof(AttachShader, program) == 4,
              "offset of AttachShader program should be 4");
static_assert(offsetof(AttachShader, shader) == 8,
              "offset of AttachShader shader should be 8");

struct BindAttribLocationBucket {
  typedef BindAttribLocationBucket ValueType;
  static const CommandId kCmdId = kBindAttribLocationBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, GLuint _index, uint32_t _name_bucket_id) {
    SetHeader();
    program = _program;
    index = _index;
    name_bucket_id = _name_bucket_id;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _name_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t name_bucket_id;
};

static_assert(sizeof(BindAttribLocationBucket) == 16,
              "size of BindAttribLocationBucket should be 16");
static_assert(offsetof(BindAttribLocationBucket, header) == 0,
              "offset of BindAttribLocationBucket header should be 0");
static_assert(offsetof(BindAttribLocationBucket, program) == 4,
              "offset of BindAttribLocationBucket program should be 4");
static_assert(offsetof(BindAttribLocationBucket, index) == 8,
              "offset of BindAttribLocationBucket index should be 8");
static_assert(offsetof(BindAttribLocationBucket, name_bucket_id) == 12,
              "offset of BindAttribLocationBucket name_bucket_id should be 12");

struct BindBuffer {
  typedef BindBuffer ValueType;
  static const CommandId kCmdId = kBindBuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _buffer) {
    SetHeader();
    target = _target;
    buffer = _buffer;
  }

  void* Set(void* cmd, GLenum _target, GLuint _buffer) {
    static_cast<ValueType*>(cmd)->Init(_target, _buffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t buffer;
};

static_assert(sizeof(BindBuffer) == 12, "size of BindBuffer should be 12");
static_assert(offsetof(BindBuffer, header) == 0,
              "offset of BindBuffer header should be 0");
static_assert(offsetof(BindBuffer, target) == 4,
              "offset of BindBuffer target should be 4");
static_assert(offsetof(BindBuffer, buffer) == 8,
              "offset of BindBuffer buffer should be 8");

struct BindBufferBase {
  typedef BindBufferBase ValueType;
  static const CommandId kCmdId = kBindBufferBase;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _index, GLuint _buffer) {
    SetHeader();
    target = _target;
    index = _index;
    buffer = _buffer;
  }

  void* Set(void* cmd, GLenum _target, GLuint _index, GLuint _buffer) {
    static_cast<ValueType*>(cmd)->Init(_target, _index, _buffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t index;
  uint32_t buffer;
};

static_assert(sizeof(BindBufferBase) == 16,
              "size of BindBufferBase should be 16");
static_assert(offsetof(BindBufferBase, header) == 0,
              "offset of BindBufferBase header should be 0");
static_assert(offsetof(BindBufferBase, target) == 4,
              "offset of BindBufferBase target should be 4");
static_assert(offsetof(BindBufferBase, index) == 8,
              "offset of BindBufferBase index should be 8");
static_assert(offsetof(BindBufferBase, buffer) == 12,
              "offset of BindBufferBase buffer should be 12");

struct BindBufferRange {
  typedef BindBufferRange ValueType;
  static const CommandId kCmdId = kBindBufferRange;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLuint _index,
            GLuint _buffer,
            GLintptr _offset,
            GLsizeiptr _size) {
    SetHeader();
    target = _target;
    index = _index;
    buffer = _buffer;
    offset = _offset;
    size = _size;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLuint _index,
            GLuint _buffer,
            GLintptr _offset,
            GLsizeiptr _size) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _index, _buffer, _offset, _size);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t index;
  uint32_t buffer;
  int32_t offset;
  int32_t size;
};

static_assert(sizeof(BindBufferRange) == 24,
              "size of BindBufferRange should be 24");
static_assert(offsetof(BindBufferRange, header) == 0,
              "offset of BindBufferRange header should be 0");
static_assert(offsetof(BindBufferRange, target) == 4,
              "offset of BindBufferRange target should be 4");
static_assert(offsetof(BindBufferRange, index) == 8,
              "offset of BindBufferRange index should be 8");
static_assert(offsetof(BindBufferRange, buffer) == 12,
              "offset of BindBufferRange buffer should be 12");
static_assert(offsetof(BindBufferRange, offset) == 16,
              "offset of BindBufferRange offset should be 16");
static_assert(offsetof(BindBufferRange, size) == 20,
              "offset of BindBufferRange size should be 20");

struct BindFramebuffer {
  typedef BindFramebuffer ValueType;
  static const CommandId kCmdId = kBindFramebuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _framebuffer) {
    SetHeader();
    target = _target;
    framebuffer = _framebuffer;
  }

  void* Set(void* cmd, GLenum _target, GLuint _framebuffer) {
    static_cast<ValueType*>(cmd)->Init(_target, _framebuffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t framebuffer;
};

static_assert(sizeof(BindFramebuffer) == 12,
              "size of BindFramebuffer should be 12");
static_assert(offsetof(BindFramebuffer, header) == 0,
              "offset of BindFramebuffer header should be 0");
static_assert(offsetof(BindFramebuffer, target) == 4,
              "offset of BindFramebuffer target should be 4");
static_assert(offsetof(BindFramebuffer, framebuffer) == 8,
              "offset of BindFramebuffer framebuffer should be 8");

struct BindRenderbuffer {
  typedef BindRenderbuffer ValueType;
  static const CommandId kCmdId = kBindRenderbuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _renderbuffer) {
    SetHeader();
    target = _target;
    renderbuffer = _renderbuffer;
  }

  void* Set(void* cmd, GLenum _target, GLuint _renderbuffer) {
    static_cast<ValueType*>(cmd)->Init(_target, _renderbuffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t renderbuffer;
};

static_assert(sizeof(BindRenderbuffer) == 12,
              "size of BindRenderbuffer should be 12");
static_assert(offsetof(BindRenderbuffer, header) == 0,
              "offset of BindRenderbuffer header should be 0");
static_assert(offsetof(BindRenderbuffer, target) == 4,
              "offset of BindRenderbuffer target should be 4");
static_assert(offsetof(BindRenderbuffer, renderbuffer) == 8,
              "offset of BindRenderbuffer renderbuffer should be 8");

struct BindSampler {
  typedef BindSampler ValueType;
  static const CommandId kCmdId = kBindSampler;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _unit, GLuint _sampler) {
    SetHeader();
    unit = _unit;
    sampler = _sampler;
  }

  void* Set(void* cmd, GLuint _unit, GLuint _sampler) {
    static_cast<ValueType*>(cmd)->Init(_unit, _sampler);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t unit;
  uint32_t sampler;
};

static_assert(sizeof(BindSampler) == 12, "size of BindSampler should be 12");
static_assert(offsetof(BindSampler, header) == 0,
              "offset of BindSampler header should be 0");
static_assert(offsetof(BindSampler, unit) == 4,
              "offset of BindSampler unit should be 4");
static_assert(offsetof(BindSampler, sampler) == 8,
              "offset of BindSampler sampler should be 8");

struct BindTexture {
  typedef BindTexture ValueType;
  static const CommandId kCmdId = kBindTexture;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _texture) {
    SetHeader();
    target = _target;
    texture = _texture;
  }

  void* Set(void* cmd, GLenum _target, GLuint _texture) {
    static_cast<ValueType*>(cmd)->Init(_target, _texture);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t texture;
};

static_assert(sizeof(BindTexture) == 12, "size of BindTexture should be 12");
static_assert(offsetof(BindTexture, header) == 0,
              "offset of BindTexture header should be 0");
static_assert(offsetof(BindTexture, target) == 4,
              "offset of BindTexture target should be 4");
static_assert(offsetof(BindTexture, texture) == 8,
              "offset of BindTexture texture should be 8");

struct BindTransformFeedback {
  typedef BindTransformFeedback ValueType;
  static const CommandId kCmdId = kBindTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _transformfeedback) {
    SetHeader();
    target = _target;
    transformfeedback = _transformfeedback;
  }

  void* Set(void* cmd, GLenum _target, GLuint _transformfeedback) {
    static_cast<ValueType*>(cmd)->Init(_target, _transformfeedback);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t transformfeedback;
};

static_assert(sizeof(BindTransformFeedback) == 12,
              "size of BindTransformFeedback should be 12");
static_assert(offsetof(BindTransformFeedback, header) == 0,
              "offset of BindTransformFeedback header should be 0");
static_assert(offsetof(BindTransformFeedback, target) == 4,
              "offset of BindTransformFeedback target should be 4");
static_assert(offsetof(BindTransformFeedback, transformfeedback) == 8,
              "offset of BindTransformFeedback transformfeedback should be 8");

struct BlendColor {
  typedef BlendColor ValueType;
  static const CommandId kCmdId = kBlendColor;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLclampf _red, GLclampf _green, GLclampf _blue, GLclampf _alpha) {
    SetHeader();
    red = _red;
    green = _green;
    blue = _blue;
    alpha = _alpha;
  }

  void* Set(void* cmd,
            GLclampf _red,
            GLclampf _green,
            GLclampf _blue,
            GLclampf _alpha) {
    static_cast<ValueType*>(cmd)->Init(_red, _green, _blue, _alpha);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float red;
  float green;
  float blue;
  float alpha;
};

static_assert(sizeof(BlendColor) == 20, "size of BlendColor should be 20");
static_assert(offsetof(BlendColor, header) == 0,
              "offset of BlendColor header should be 0");
static_assert(offsetof(BlendColor, red) == 4,
              "offset of BlendColor red should be 4");
static_assert(offsetof(BlendColor, green) == 8,
              "offset of BlendColor green should be 8");
static_assert(offsetof(BlendColor, blue) == 12,
              "offset of BlendColor blue should be 12");
static_assert(offsetof(BlendColor, alpha) == 16,
              "offset of BlendColor alpha should be 16");

struct BlendEquation {
  typedef BlendEquation ValueType;
  static const CommandId kCmdId = kBlendEquation;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode) {
    SetHeader();
    mode = _mode;
  }

  void* Set(void* cmd, GLenum _mode) {
    static_cast<ValueType*>(cmd)->Init(_mode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
};

static_assert(sizeof(BlendEquation) == 8, "size of BlendEquation should be 8");
static_assert(offsetof(BlendEquation, header) == 0,
              "offset of BlendEquation header should be 0");
static_assert(offsetof(BlendEquation, mode) == 4,
              "offset of BlendEquation mode should be 4");

struct BlendEquationSeparate {
  typedef BlendEquationSeparate ValueType;
  static const CommandId kCmdId = kBlendEquationSeparate;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _modeRGB, GLenum _modeAlpha) {
    SetHeader();
    modeRGB = _modeRGB;
    modeAlpha = _modeAlpha;
  }

  void* Set(void* cmd, GLenum _modeRGB, GLenum _modeAlpha) {
    static_cast<ValueType*>(cmd)->Init(_modeRGB, _modeAlpha);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t modeRGB;
  uint32_t modeAlpha;
};

static_assert(sizeof(BlendEquationSeparate) == 12,
              "size of BlendEquationSeparate should be 12");
static_assert(offsetof(BlendEquationSeparate, header) == 0,
              "offset of BlendEquationSeparate header should be 0");
static_assert(offsetof(BlendEquationSeparate, modeRGB) == 4,
              "offset of BlendEquationSeparate modeRGB should be 4");
static_assert(offsetof(BlendEquationSeparate, modeAlpha) == 8,
              "offset of BlendEquationSeparate modeAlpha should be 8");

struct BlendFunc {
  typedef BlendFunc ValueType;
  static const CommandId kCmdId = kBlendFunc;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _sfactor, GLenum _dfactor) {
    SetHeader();
    sfactor = _sfactor;
    dfactor = _dfactor;
  }

  void* Set(void* cmd, GLenum _sfactor, GLenum _dfactor) {
    static_cast<ValueType*>(cmd)->Init(_sfactor, _dfactor);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sfactor;
  uint32_t dfactor;
};

static_assert(sizeof(BlendFunc) == 12, "size of BlendFunc should be 12");
static_assert(offsetof(BlendFunc, header) == 0,
              "offset of BlendFunc header should be 0");
static_assert(offsetof(BlendFunc, sfactor) == 4,
              "offset of BlendFunc sfactor should be 4");
static_assert(offsetof(BlendFunc, dfactor) == 8,
              "offset of BlendFunc dfactor should be 8");

struct BlendFuncSeparate {
  typedef BlendFuncSeparate ValueType;
  static const CommandId kCmdId = kBlendFuncSeparate;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _srcRGB,
            GLenum _dstRGB,
            GLenum _srcAlpha,
            GLenum _dstAlpha) {
    SetHeader();
    srcRGB = _srcRGB;
    dstRGB = _dstRGB;
    srcAlpha = _srcAlpha;
    dstAlpha = _dstAlpha;
  }

  void* Set(void* cmd,
            GLenum _srcRGB,
            GLenum _dstRGB,
            GLenum _srcAlpha,
            GLenum _dstAlpha) {
    static_cast<ValueType*>(cmd)->Init(_srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t srcRGB;
  uint32_t dstRGB;
  uint32_t srcAlpha;
  uint32_t dstAlpha;
};

static_assert(sizeof(BlendFuncSeparate) == 20,
              "size of BlendFuncSeparate should be 20");
static_assert(offsetof(BlendFuncSeparate, header) == 0,
              "offset of BlendFuncSeparate header should be 0");
static_assert(offsetof(BlendFuncSeparate, srcRGB) == 4,
              "offset of BlendFuncSeparate srcRGB should be 4");
static_assert(offsetof(BlendFuncSeparate, dstRGB) == 8,
              "offset of BlendFuncSeparate dstRGB should be 8");
static_assert(offsetof(BlendFuncSeparate, srcAlpha) == 12,
              "offset of BlendFuncSeparate srcAlpha should be 12");
static_assert(offsetof(BlendFuncSeparate, dstAlpha) == 16,
              "offset of BlendFuncSeparate dstAlpha should be 16");

struct BufferData {
  typedef BufferData ValueType;
  static const CommandId kCmdId = kBufferData;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizeiptr _size,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            GLenum _usage) {
    SetHeader();
    target = _target;
    size = _size;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
    usage = _usage;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizeiptr _size,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            GLenum _usage) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _size, _data_shm_id, _data_shm_offset, _usage);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t size;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
  uint32_t usage;
};

static_assert(sizeof(BufferData) == 24, "size of BufferData should be 24");
static_assert(offsetof(BufferData, header) == 0,
              "offset of BufferData header should be 0");
static_assert(offsetof(BufferData, target) == 4,
              "offset of BufferData target should be 4");
static_assert(offsetof(BufferData, size) == 8,
              "offset of BufferData size should be 8");
static_assert(offsetof(BufferData, data_shm_id) == 12,
              "offset of BufferData data_shm_id should be 12");
static_assert(offsetof(BufferData, data_shm_offset) == 16,
              "offset of BufferData data_shm_offset should be 16");
static_assert(offsetof(BufferData, usage) == 20,
              "offset of BufferData usage should be 20");

struct BufferSubData {
  typedef BufferSubData ValueType;
  static const CommandId kCmdId = kBufferSubData;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLintptr _offset,
            GLsizeiptr _size,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    SetHeader();
    target = _target;
    offset = _offset;
    size = _size;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLintptr _offset,
            GLsizeiptr _size,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _offset, _size, _data_shm_id, _data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t offset;
  int32_t size;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
};

static_assert(sizeof(BufferSubData) == 24,
              "size of BufferSubData should be 24");
static_assert(offsetof(BufferSubData, header) == 0,
              "offset of BufferSubData header should be 0");
static_assert(offsetof(BufferSubData, target) == 4,
              "offset of BufferSubData target should be 4");
static_assert(offsetof(BufferSubData, offset) == 8,
              "offset of BufferSubData offset should be 8");
static_assert(offsetof(BufferSubData, size) == 12,
              "offset of BufferSubData size should be 12");
static_assert(offsetof(BufferSubData, data_shm_id) == 16,
              "offset of BufferSubData data_shm_id should be 16");
static_assert(offsetof(BufferSubData, data_shm_offset) == 20,
              "offset of BufferSubData data_shm_offset should be 20");

struct CheckFramebufferStatus {
  typedef CheckFramebufferStatus ValueType;
  static const CommandId kCmdId = kCheckFramebufferStatus;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLenum Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    target = _target;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(CheckFramebufferStatus) == 16,
              "size of CheckFramebufferStatus should be 16");
static_assert(offsetof(CheckFramebufferStatus, header) == 0,
              "offset of CheckFramebufferStatus header should be 0");
static_assert(offsetof(CheckFramebufferStatus, target) == 4,
              "offset of CheckFramebufferStatus target should be 4");
static_assert(offsetof(CheckFramebufferStatus, result_shm_id) == 8,
              "offset of CheckFramebufferStatus result_shm_id should be 8");
static_assert(
    offsetof(CheckFramebufferStatus, result_shm_offset) == 12,
    "offset of CheckFramebufferStatus result_shm_offset should be 12");

struct Clear {
  typedef Clear ValueType;
  static const CommandId kCmdId = kClear;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLbitfield _mask) {
    SetHeader();
    mask = _mask;
  }

  void* Set(void* cmd, GLbitfield _mask) {
    static_cast<ValueType*>(cmd)->Init(_mask);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mask;
};

static_assert(sizeof(Clear) == 8, "size of Clear should be 8");
static_assert(offsetof(Clear, header) == 0,
              "offset of Clear header should be 0");
static_assert(offsetof(Clear, mask) == 4, "offset of Clear mask should be 4");

struct ClearBufferfi {
  typedef ClearBufferfi ValueType;
  static const CommandId kCmdId = kClearBufferfi;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _buffer,
            GLint _drawbuffers,
            GLfloat _depth,
            GLint _stencil) {
    SetHeader();
    buffer = _buffer;
    drawbuffers = _drawbuffers;
    depth = _depth;
    stencil = _stencil;
  }

  void* Set(void* cmd,
            GLenum _buffer,
            GLint _drawbuffers,
            GLfloat _depth,
            GLint _stencil) {
    static_cast<ValueType*>(cmd)->Init(_buffer, _drawbuffers, _depth, _stencil);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t buffer;
  int32_t drawbuffers;
  float depth;
  int32_t stencil;
};

static_assert(sizeof(ClearBufferfi) == 20,
              "size of ClearBufferfi should be 20");
static_assert(offsetof(ClearBufferfi, header) == 0,
              "offset of ClearBufferfi header should be 0");
static_assert(offsetof(ClearBufferfi, buffer) == 4,
              "offset of ClearBufferfi buffer should be 4");
static_assert(offsetof(ClearBufferfi, drawbuffers) == 8,
              "offset of ClearBufferfi drawbuffers should be 8");
static_assert(offsetof(ClearBufferfi, depth) == 12,
              "offset of ClearBufferfi depth should be 12");
static_assert(offsetof(ClearBufferfi, stencil) == 16,
              "offset of ClearBufferfi stencil should be 16");

struct ClearBufferfvImmediate {
  typedef ClearBufferfvImmediate ValueType;
  static const CommandId kCmdId = kClearBufferfvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 4);
  }

  static uint32_t ComputeEffectiveDataSize(GLenum buffer) {
    return static_cast<uint32_t>(sizeof(GLfloat) *
                                 GLES2Util::CalcClearBufferfvDataCount(buffer));
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _buffer, GLint _drawbuffers, const GLfloat* _value) {
    SetHeader();
    buffer = _buffer;
    drawbuffers = _drawbuffers;
    memcpy(ImmediateDataAddress(this), _value,
           ComputeEffectiveDataSize(buffer));
    DCHECK_GE(ComputeDataSize(), ComputeEffectiveDataSize(buffer));
    char* pointer = reinterpret_cast<char*>(ImmediateDataAddress(this)) +
                    ComputeEffectiveDataSize(buffer);
    memset(pointer, 0, ComputeDataSize() - ComputeEffectiveDataSize(buffer));
  }

  void* Set(void* cmd,
            GLenum _buffer,
            GLint _drawbuffers,
            const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_buffer, _drawbuffers, _value);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t buffer;
  int32_t drawbuffers;
};

static_assert(sizeof(ClearBufferfvImmediate) == 12,
              "size of ClearBufferfvImmediate should be 12");
static_assert(offsetof(ClearBufferfvImmediate, header) == 0,
              "offset of ClearBufferfvImmediate header should be 0");
static_assert(offsetof(ClearBufferfvImmediate, buffer) == 4,
              "offset of ClearBufferfvImmediate buffer should be 4");
static_assert(offsetof(ClearBufferfvImmediate, drawbuffers) == 8,
              "offset of ClearBufferfvImmediate drawbuffers should be 8");

struct ClearBufferivImmediate {
  typedef ClearBufferivImmediate ValueType;
  static const CommandId kCmdId = kClearBufferivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLint) * 4);
  }

  static uint32_t ComputeEffectiveDataSize(GLenum buffer) {
    return static_cast<uint32_t>(sizeof(GLint) *
                                 GLES2Util::CalcClearBufferivDataCount(buffer));
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _buffer, GLint _drawbuffers, const GLint* _value) {
    SetHeader();
    buffer = _buffer;
    drawbuffers = _drawbuffers;
    memcpy(ImmediateDataAddress(this), _value,
           ComputeEffectiveDataSize(buffer));
    DCHECK_GE(ComputeDataSize(), ComputeEffectiveDataSize(buffer));
    char* pointer = reinterpret_cast<char*>(ImmediateDataAddress(this)) +
                    ComputeEffectiveDataSize(buffer);
    memset(pointer, 0, ComputeDataSize() - ComputeEffectiveDataSize(buffer));
  }

  void* Set(void* cmd,
            GLenum _buffer,
            GLint _drawbuffers,
            const GLint* _value) {
    static_cast<ValueType*>(cmd)->Init(_buffer, _drawbuffers, _value);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t buffer;
  int32_t drawbuffers;
};

static_assert(sizeof(ClearBufferivImmediate) == 12,
              "size of ClearBufferivImmediate should be 12");
static_assert(offsetof(ClearBufferivImmediate, header) == 0,
              "offset of ClearBufferivImmediate header should be 0");
static_assert(offsetof(ClearBufferivImmediate, buffer) == 4,
              "offset of ClearBufferivImmediate buffer should be 4");
static_assert(offsetof(ClearBufferivImmediate, drawbuffers) == 8,
              "offset of ClearBufferivImmediate drawbuffers should be 8");

struct ClearBufferuivImmediate {
  typedef ClearBufferuivImmediate ValueType;
  static const CommandId kCmdId = kClearBufferuivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLuint) * 4);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _buffer, GLint _drawbuffers, const GLuint* _value) {
    SetHeader();
    buffer = _buffer;
    drawbuffers = _drawbuffers;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize());
  }

  void* Set(void* cmd,
            GLenum _buffer,
            GLint _drawbuffers,
            const GLuint* _value) {
    static_cast<ValueType*>(cmd)->Init(_buffer, _drawbuffers, _value);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t buffer;
  int32_t drawbuffers;
};

static_assert(sizeof(ClearBufferuivImmediate) == 12,
              "size of ClearBufferuivImmediate should be 12");
static_assert(offsetof(ClearBufferuivImmediate, header) == 0,
              "offset of ClearBufferuivImmediate header should be 0");
static_assert(offsetof(ClearBufferuivImmediate, buffer) == 4,
              "offset of ClearBufferuivImmediate buffer should be 4");
static_assert(offsetof(ClearBufferuivImmediate, drawbuffers) == 8,
              "offset of ClearBufferuivImmediate drawbuffers should be 8");

struct ClearColor {
  typedef ClearColor ValueType;
  static const CommandId kCmdId = kClearColor;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLclampf _red, GLclampf _green, GLclampf _blue, GLclampf _alpha) {
    SetHeader();
    red = _red;
    green = _green;
    blue = _blue;
    alpha = _alpha;
  }

  void* Set(void* cmd,
            GLclampf _red,
            GLclampf _green,
            GLclampf _blue,
            GLclampf _alpha) {
    static_cast<ValueType*>(cmd)->Init(_red, _green, _blue, _alpha);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float red;
  float green;
  float blue;
  float alpha;
};

static_assert(sizeof(ClearColor) == 20, "size of ClearColor should be 20");
static_assert(offsetof(ClearColor, header) == 0,
              "offset of ClearColor header should be 0");
static_assert(offsetof(ClearColor, red) == 4,
              "offset of ClearColor red should be 4");
static_assert(offsetof(ClearColor, green) == 8,
              "offset of ClearColor green should be 8");
static_assert(offsetof(ClearColor, blue) == 12,
              "offset of ClearColor blue should be 12");
static_assert(offsetof(ClearColor, alpha) == 16,
              "offset of ClearColor alpha should be 16");

struct ClearDepthf {
  typedef ClearDepthf ValueType;
  static const CommandId kCmdId = kClearDepthf;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLclampf _depth) {
    SetHeader();
    depth = _depth;
  }

  void* Set(void* cmd, GLclampf _depth) {
    static_cast<ValueType*>(cmd)->Init(_depth);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float depth;
};

static_assert(sizeof(ClearDepthf) == 8, "size of ClearDepthf should be 8");
static_assert(offsetof(ClearDepthf, header) == 0,
              "offset of ClearDepthf header should be 0");
static_assert(offsetof(ClearDepthf, depth) == 4,
              "offset of ClearDepthf depth should be 4");

struct ClearStencil {
  typedef ClearStencil ValueType;
  static const CommandId kCmdId = kClearStencil;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _s) {
    SetHeader();
    s = _s;
  }

  void* Set(void* cmd, GLint _s) {
    static_cast<ValueType*>(cmd)->Init(_s);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t s;
};

static_assert(sizeof(ClearStencil) == 8, "size of ClearStencil should be 8");
static_assert(offsetof(ClearStencil, header) == 0,
              "offset of ClearStencil header should be 0");
static_assert(offsetof(ClearStencil, s) == 4,
              "offset of ClearStencil s should be 4");

struct ClientWaitSync {
  typedef ClientWaitSync ValueType;
  static const CommandId kCmdId = kClientWaitSync;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLenum Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync,
            GLbitfield _flags,
            GLuint _timeout_0,
            GLuint _timeout_1,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    sync = _sync;
    flags = _flags;
    timeout_0 = _timeout_0;
    timeout_1 = _timeout_1;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sync,
            GLbitfield _flags,
            GLuint _timeout_0,
            GLuint _timeout_1,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_sync, _flags, _timeout_0, _timeout_1,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync;
  uint32_t flags;
  uint32_t timeout_0;
  uint32_t timeout_1;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(ClientWaitSync) == 28,
              "size of ClientWaitSync should be 28");
static_assert(offsetof(ClientWaitSync, header) == 0,
              "offset of ClientWaitSync header should be 0");
static_assert(offsetof(ClientWaitSync, sync) == 4,
              "offset of ClientWaitSync sync should be 4");
static_assert(offsetof(ClientWaitSync, flags) == 8,
              "offset of ClientWaitSync flags should be 8");
static_assert(offsetof(ClientWaitSync, timeout_0) == 12,
              "offset of ClientWaitSync timeout_0 should be 12");
static_assert(offsetof(ClientWaitSync, timeout_1) == 16,
              "offset of ClientWaitSync timeout_1 should be 16");
static_assert(offsetof(ClientWaitSync, result_shm_id) == 20,
              "offset of ClientWaitSync result_shm_id should be 20");
static_assert(offsetof(ClientWaitSync, result_shm_offset) == 24,
              "offset of ClientWaitSync result_shm_offset should be 24");

struct ColorMask {
  typedef ColorMask ValueType;
  static const CommandId kCmdId = kColorMask;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLboolean _red,
            GLboolean _green,
            GLboolean _blue,
            GLboolean _alpha) {
    SetHeader();
    red = _red;
    green = _green;
    blue = _blue;
    alpha = _alpha;
  }

  void* Set(void* cmd,
            GLboolean _red,
            GLboolean _green,
            GLboolean _blue,
            GLboolean _alpha) {
    static_cast<ValueType*>(cmd)->Init(_red, _green, _blue, _alpha);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t red;
  uint32_t green;
  uint32_t blue;
  uint32_t alpha;
};

static_assert(sizeof(ColorMask) == 20, "size of ColorMask should be 20");
static_assert(offsetof(ColorMask, header) == 0,
              "offset of ColorMask header should be 0");
static_assert(offsetof(ColorMask, red) == 4,
              "offset of ColorMask red should be 4");
static_assert(offsetof(ColorMask, green) == 8,
              "offset of ColorMask green should be 8");
static_assert(offsetof(ColorMask, blue) == 12,
              "offset of ColorMask blue should be 12");
static_assert(offsetof(ColorMask, alpha) == 16,
              "offset of ColorMask alpha should be 16");

struct CompileShader {
  typedef CompileShader ValueType;
  static const CommandId kCmdId = kCompileShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader) {
    SetHeader();
    shader = _shader;
  }

  void* Set(void* cmd, GLuint _shader) {
    static_cast<ValueType*>(cmd)->Init(_shader);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
};

static_assert(sizeof(CompileShader) == 8, "size of CompileShader should be 8");
static_assert(offsetof(CompileShader, header) == 0,
              "offset of CompileShader header should be 0");
static_assert(offsetof(CompileShader, shader) == 4,
              "offset of CompileShader shader should be 4");

struct CompressedTexImage2DBucket {
  typedef CompressedTexImage2DBucket ValueType;
  static const CommandId kCmdId = kCompressedTexImage2DBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLuint _bucket_id) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    width = _width;
    height = _height;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLuint _bucket_id) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _internalformat, _width, _height, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  uint32_t internalformat;
  int32_t width;
  int32_t height;
  uint32_t bucket_id;
  static const int32_t border = 0;
};

static_assert(sizeof(CompressedTexImage2DBucket) == 28,
              "size of CompressedTexImage2DBucket should be 28");
static_assert(offsetof(CompressedTexImage2DBucket, header) == 0,
              "offset of CompressedTexImage2DBucket header should be 0");
static_assert(offsetof(CompressedTexImage2DBucket, target) == 4,
              "offset of CompressedTexImage2DBucket target should be 4");
static_assert(offsetof(CompressedTexImage2DBucket, level) == 8,
              "offset of CompressedTexImage2DBucket level should be 8");
static_assert(
    offsetof(CompressedTexImage2DBucket, internalformat) == 12,
    "offset of CompressedTexImage2DBucket internalformat should be 12");
static_assert(offsetof(CompressedTexImage2DBucket, width) == 16,
              "offset of CompressedTexImage2DBucket width should be 16");
static_assert(offsetof(CompressedTexImage2DBucket, height) == 20,
              "offset of CompressedTexImage2DBucket height should be 20");
static_assert(offsetof(CompressedTexImage2DBucket, bucket_id) == 24,
              "offset of CompressedTexImage2DBucket bucket_id should be 24");

struct CompressedTexImage2D {
  typedef CompressedTexImage2D ValueType;
  static const CommandId kCmdId = kCompressedTexImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _imageSize,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    width = _width;
    height = _height;
    imageSize = _imageSize;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _imageSize,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _internalformat, _width,
                                       _height, _imageSize, _data_shm_id,
                                       _data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  uint32_t internalformat;
  int32_t width;
  int32_t height;
  int32_t imageSize;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
  static const int32_t border = 0;
};

static_assert(sizeof(CompressedTexImage2D) == 36,
              "size of CompressedTexImage2D should be 36");
static_assert(offsetof(CompressedTexImage2D, header) == 0,
              "offset of CompressedTexImage2D header should be 0");
static_assert(offsetof(CompressedTexImage2D, target) == 4,
              "offset of CompressedTexImage2D target should be 4");
static_assert(offsetof(CompressedTexImage2D, level) == 8,
              "offset of CompressedTexImage2D level should be 8");
static_assert(offsetof(CompressedTexImage2D, internalformat) == 12,
              "offset of CompressedTexImage2D internalformat should be 12");
static_assert(offsetof(CompressedTexImage2D, width) == 16,
              "offset of CompressedTexImage2D width should be 16");
static_assert(offsetof(CompressedTexImage2D, height) == 20,
              "offset of CompressedTexImage2D height should be 20");
static_assert(offsetof(CompressedTexImage2D, imageSize) == 24,
              "offset of CompressedTexImage2D imageSize should be 24");
static_assert(offsetof(CompressedTexImage2D, data_shm_id) == 28,
              "offset of CompressedTexImage2D data_shm_id should be 28");
static_assert(offsetof(CompressedTexImage2D, data_shm_offset) == 32,
              "offset of CompressedTexImage2D data_shm_offset should be 32");

struct CompressedTexSubImage2DBucket {
  typedef CompressedTexSubImage2DBucket ValueType;
  static const CommandId kCmdId = kCompressedTexSubImage2DBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLuint _bucket_id) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    width = _width;
    height = _height;
    format = _format;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLuint _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _xoffset, _yoffset,
                                       _width, _height, _format, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t bucket_id;
};

static_assert(sizeof(CompressedTexSubImage2DBucket) == 36,
              "size of CompressedTexSubImage2DBucket should be 36");
static_assert(offsetof(CompressedTexSubImage2DBucket, header) == 0,
              "offset of CompressedTexSubImage2DBucket header should be 0");
static_assert(offsetof(CompressedTexSubImage2DBucket, target) == 4,
              "offset of CompressedTexSubImage2DBucket target should be 4");
static_assert(offsetof(CompressedTexSubImage2DBucket, level) == 8,
              "offset of CompressedTexSubImage2DBucket level should be 8");
static_assert(offsetof(CompressedTexSubImage2DBucket, xoffset) == 12,
              "offset of CompressedTexSubImage2DBucket xoffset should be 12");
static_assert(offsetof(CompressedTexSubImage2DBucket, yoffset) == 16,
              "offset of CompressedTexSubImage2DBucket yoffset should be 16");
static_assert(offsetof(CompressedTexSubImage2DBucket, width) == 20,
              "offset of CompressedTexSubImage2DBucket width should be 20");
static_assert(offsetof(CompressedTexSubImage2DBucket, height) == 24,
              "offset of CompressedTexSubImage2DBucket height should be 24");
static_assert(offsetof(CompressedTexSubImage2DBucket, format) == 28,
              "offset of CompressedTexSubImage2DBucket format should be 28");
static_assert(offsetof(CompressedTexSubImage2DBucket, bucket_id) == 32,
              "offset of CompressedTexSubImage2DBucket bucket_id should be 32");

struct CompressedTexSubImage2D {
  typedef CompressedTexSubImage2D ValueType;
  static const CommandId kCmdId = kCompressedTexSubImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLsizei _imageSize,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    width = _width;
    height = _height;
    format = _format;
    imageSize = _imageSize;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLsizei _imageSize,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _xoffset, _yoffset,
                                       _width, _height, _format, _imageSize,
                                       _data_shm_id, _data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t width;
  int32_t height;
  uint32_t format;
  int32_t imageSize;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
};

static_assert(sizeof(CompressedTexSubImage2D) == 44,
              "size of CompressedTexSubImage2D should be 44");
static_assert(offsetof(CompressedTexSubImage2D, header) == 0,
              "offset of CompressedTexSubImage2D header should be 0");
static_assert(offsetof(CompressedTexSubImage2D, target) == 4,
              "offset of CompressedTexSubImage2D target should be 4");
static_assert(offsetof(CompressedTexSubImage2D, level) == 8,
              "offset of CompressedTexSubImage2D level should be 8");
static_assert(offsetof(CompressedTexSubImage2D, xoffset) == 12,
              "offset of CompressedTexSubImage2D xoffset should be 12");
static_assert(offsetof(CompressedTexSubImage2D, yoffset) == 16,
              "offset of CompressedTexSubImage2D yoffset should be 16");
static_assert(offsetof(CompressedTexSubImage2D, width) == 20,
              "offset of CompressedTexSubImage2D width should be 20");
static_assert(offsetof(CompressedTexSubImage2D, height) == 24,
              "offset of CompressedTexSubImage2D height should be 24");
static_assert(offsetof(CompressedTexSubImage2D, format) == 28,
              "offset of CompressedTexSubImage2D format should be 28");
static_assert(offsetof(CompressedTexSubImage2D, imageSize) == 32,
              "offset of CompressedTexSubImage2D imageSize should be 32");
static_assert(offsetof(CompressedTexSubImage2D, data_shm_id) == 36,
              "offset of CompressedTexSubImage2D data_shm_id should be 36");
static_assert(offsetof(CompressedTexSubImage2D, data_shm_offset) == 40,
              "offset of CompressedTexSubImage2D data_shm_offset should be 40");

struct CopyBufferSubData {
  typedef CopyBufferSubData ValueType;
  static const CommandId kCmdId = kCopyBufferSubData;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _readtarget,
            GLenum _writetarget,
            GLintptr _readoffset,
            GLintptr _writeoffset,
            GLsizeiptr _size) {
    SetHeader();
    readtarget = _readtarget;
    writetarget = _writetarget;
    readoffset = _readoffset;
    writeoffset = _writeoffset;
    size = _size;
  }

  void* Set(void* cmd,
            GLenum _readtarget,
            GLenum _writetarget,
            GLintptr _readoffset,
            GLintptr _writeoffset,
            GLsizeiptr _size) {
    static_cast<ValueType*>(cmd)
        ->Init(_readtarget, _writetarget, _readoffset, _writeoffset, _size);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t readtarget;
  uint32_t writetarget;
  int32_t readoffset;
  int32_t writeoffset;
  int32_t size;
};

static_assert(sizeof(CopyBufferSubData) == 24,
              "size of CopyBufferSubData should be 24");
static_assert(offsetof(CopyBufferSubData, header) == 0,
              "offset of CopyBufferSubData header should be 0");
static_assert(offsetof(CopyBufferSubData, readtarget) == 4,
              "offset of CopyBufferSubData readtarget should be 4");
static_assert(offsetof(CopyBufferSubData, writetarget) == 8,
              "offset of CopyBufferSubData writetarget should be 8");
static_assert(offsetof(CopyBufferSubData, readoffset) == 12,
              "offset of CopyBufferSubData readoffset should be 12");
static_assert(offsetof(CopyBufferSubData, writeoffset) == 16,
              "offset of CopyBufferSubData writeoffset should be 16");
static_assert(offsetof(CopyBufferSubData, size) == 20,
              "offset of CopyBufferSubData size should be 20");

struct CopyTexImage2D {
  typedef CopyTexImage2D ValueType;
  static const CommandId kCmdId = kCopyTexImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLenum _internalformat,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _internalformat, _x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  uint32_t internalformat;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
  static const int32_t border = 0;
};

static_assert(sizeof(CopyTexImage2D) == 32,
              "size of CopyTexImage2D should be 32");
static_assert(offsetof(CopyTexImage2D, header) == 0,
              "offset of CopyTexImage2D header should be 0");
static_assert(offsetof(CopyTexImage2D, target) == 4,
              "offset of CopyTexImage2D target should be 4");
static_assert(offsetof(CopyTexImage2D, level) == 8,
              "offset of CopyTexImage2D level should be 8");
static_assert(offsetof(CopyTexImage2D, internalformat) == 12,
              "offset of CopyTexImage2D internalformat should be 12");
static_assert(offsetof(CopyTexImage2D, x) == 16,
              "offset of CopyTexImage2D x should be 16");
static_assert(offsetof(CopyTexImage2D, y) == 20,
              "offset of CopyTexImage2D y should be 20");
static_assert(offsetof(CopyTexImage2D, width) == 24,
              "offset of CopyTexImage2D width should be 24");
static_assert(offsetof(CopyTexImage2D, height) == 28,
              "offset of CopyTexImage2D height should be 28");

struct CopyTexSubImage2D {
  typedef CopyTexSubImage2D ValueType;
  static const CommandId kCmdId = kCopyTexSubImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _xoffset, _yoffset, _x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(CopyTexSubImage2D) == 36,
              "size of CopyTexSubImage2D should be 36");
static_assert(offsetof(CopyTexSubImage2D, header) == 0,
              "offset of CopyTexSubImage2D header should be 0");
static_assert(offsetof(CopyTexSubImage2D, target) == 4,
              "offset of CopyTexSubImage2D target should be 4");
static_assert(offsetof(CopyTexSubImage2D, level) == 8,
              "offset of CopyTexSubImage2D level should be 8");
static_assert(offsetof(CopyTexSubImage2D, xoffset) == 12,
              "offset of CopyTexSubImage2D xoffset should be 12");
static_assert(offsetof(CopyTexSubImage2D, yoffset) == 16,
              "offset of CopyTexSubImage2D yoffset should be 16");
static_assert(offsetof(CopyTexSubImage2D, x) == 20,
              "offset of CopyTexSubImage2D x should be 20");
static_assert(offsetof(CopyTexSubImage2D, y) == 24,
              "offset of CopyTexSubImage2D y should be 24");
static_assert(offsetof(CopyTexSubImage2D, width) == 28,
              "offset of CopyTexSubImage2D width should be 28");
static_assert(offsetof(CopyTexSubImage2D, height) == 32,
              "offset of CopyTexSubImage2D height should be 32");

struct CopyTexSubImage3D {
  typedef CopyTexSubImage3D ValueType;
  static const CommandId kCmdId = kCopyTexSubImage3D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _zoffset,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    zoffset = _zoffset;
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _zoffset,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _xoffset, _yoffset,
                                       _zoffset, _x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t zoffset;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(CopyTexSubImage3D) == 40,
              "size of CopyTexSubImage3D should be 40");
static_assert(offsetof(CopyTexSubImage3D, header) == 0,
              "offset of CopyTexSubImage3D header should be 0");
static_assert(offsetof(CopyTexSubImage3D, target) == 4,
              "offset of CopyTexSubImage3D target should be 4");
static_assert(offsetof(CopyTexSubImage3D, level) == 8,
              "offset of CopyTexSubImage3D level should be 8");
static_assert(offsetof(CopyTexSubImage3D, xoffset) == 12,
              "offset of CopyTexSubImage3D xoffset should be 12");
static_assert(offsetof(CopyTexSubImage3D, yoffset) == 16,
              "offset of CopyTexSubImage3D yoffset should be 16");
static_assert(offsetof(CopyTexSubImage3D, zoffset) == 20,
              "offset of CopyTexSubImage3D zoffset should be 20");
static_assert(offsetof(CopyTexSubImage3D, x) == 24,
              "offset of CopyTexSubImage3D x should be 24");
static_assert(offsetof(CopyTexSubImage3D, y) == 28,
              "offset of CopyTexSubImage3D y should be 28");
static_assert(offsetof(CopyTexSubImage3D, width) == 32,
              "offset of CopyTexSubImage3D width should be 32");
static_assert(offsetof(CopyTexSubImage3D, height) == 36,
              "offset of CopyTexSubImage3D height should be 36");

struct CreateProgram {
  typedef CreateProgram ValueType;
  static const CommandId kCmdId = kCreateProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(uint32_t _client_id) {
    SetHeader();
    client_id = _client_id;
  }

  void* Set(void* cmd, uint32_t _client_id) {
    static_cast<ValueType*>(cmd)->Init(_client_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t client_id;
};

static_assert(sizeof(CreateProgram) == 8, "size of CreateProgram should be 8");
static_assert(offsetof(CreateProgram, header) == 0,
              "offset of CreateProgram header should be 0");
static_assert(offsetof(CreateProgram, client_id) == 4,
              "offset of CreateProgram client_id should be 4");

struct CreateShader {
  typedef CreateShader ValueType;
  static const CommandId kCmdId = kCreateShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _type, uint32_t _client_id) {
    SetHeader();
    type = _type;
    client_id = _client_id;
  }

  void* Set(void* cmd, GLenum _type, uint32_t _client_id) {
    static_cast<ValueType*>(cmd)->Init(_type, _client_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t type;
  uint32_t client_id;
};

static_assert(sizeof(CreateShader) == 12, "size of CreateShader should be 12");
static_assert(offsetof(CreateShader, header) == 0,
              "offset of CreateShader header should be 0");
static_assert(offsetof(CreateShader, type) == 4,
              "offset of CreateShader type should be 4");
static_assert(offsetof(CreateShader, client_id) == 8,
              "offset of CreateShader client_id should be 8");

struct CullFace {
  typedef CullFace ValueType;
  static const CommandId kCmdId = kCullFace;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode) {
    SetHeader();
    mode = _mode;
  }

  void* Set(void* cmd, GLenum _mode) {
    static_cast<ValueType*>(cmd)->Init(_mode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
};

static_assert(sizeof(CullFace) == 8, "size of CullFace should be 8");
static_assert(offsetof(CullFace, header) == 0,
              "offset of CullFace header should be 0");
static_assert(offsetof(CullFace, mode) == 4,
              "offset of CullFace mode should be 4");

struct DeleteBuffersImmediate {
  typedef DeleteBuffersImmediate ValueType;
  static const CommandId kCmdId = kDeleteBuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _buffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _buffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _buffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _buffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteBuffersImmediate) == 8,
              "size of DeleteBuffersImmediate should be 8");
static_assert(offsetof(DeleteBuffersImmediate, header) == 0,
              "offset of DeleteBuffersImmediate header should be 0");
static_assert(offsetof(DeleteBuffersImmediate, n) == 4,
              "offset of DeleteBuffersImmediate n should be 4");

struct DeleteFramebuffersImmediate {
  typedef DeleteFramebuffersImmediate ValueType;
  static const CommandId kCmdId = kDeleteFramebuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _framebuffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _framebuffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _framebuffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _framebuffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteFramebuffersImmediate) == 8,
              "size of DeleteFramebuffersImmediate should be 8");
static_assert(offsetof(DeleteFramebuffersImmediate, header) == 0,
              "offset of DeleteFramebuffersImmediate header should be 0");
static_assert(offsetof(DeleteFramebuffersImmediate, n) == 4,
              "offset of DeleteFramebuffersImmediate n should be 4");

struct DeleteProgram {
  typedef DeleteProgram ValueType;
  static const CommandId kCmdId = kDeleteProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program) {
    SetHeader();
    program = _program;
  }

  void* Set(void* cmd, GLuint _program) {
    static_cast<ValueType*>(cmd)->Init(_program);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
};

static_assert(sizeof(DeleteProgram) == 8, "size of DeleteProgram should be 8");
static_assert(offsetof(DeleteProgram, header) == 0,
              "offset of DeleteProgram header should be 0");
static_assert(offsetof(DeleteProgram, program) == 4,
              "offset of DeleteProgram program should be 4");

struct DeleteRenderbuffersImmediate {
  typedef DeleteRenderbuffersImmediate ValueType;
  static const CommandId kCmdId = kDeleteRenderbuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _renderbuffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _renderbuffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _renderbuffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _renderbuffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteRenderbuffersImmediate) == 8,
              "size of DeleteRenderbuffersImmediate should be 8");
static_assert(offsetof(DeleteRenderbuffersImmediate, header) == 0,
              "offset of DeleteRenderbuffersImmediate header should be 0");
static_assert(offsetof(DeleteRenderbuffersImmediate, n) == 4,
              "offset of DeleteRenderbuffersImmediate n should be 4");

struct DeleteSamplersImmediate {
  typedef DeleteSamplersImmediate ValueType;
  static const CommandId kCmdId = kDeleteSamplersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _samplers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _samplers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _samplers) {
    static_cast<ValueType*>(cmd)->Init(_n, _samplers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteSamplersImmediate) == 8,
              "size of DeleteSamplersImmediate should be 8");
static_assert(offsetof(DeleteSamplersImmediate, header) == 0,
              "offset of DeleteSamplersImmediate header should be 0");
static_assert(offsetof(DeleteSamplersImmediate, n) == 4,
              "offset of DeleteSamplersImmediate n should be 4");

struct DeleteSync {
  typedef DeleteSync ValueType;
  static const CommandId kCmdId = kDeleteSync;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync) {
    SetHeader();
    sync = _sync;
  }

  void* Set(void* cmd, GLuint _sync) {
    static_cast<ValueType*>(cmd)->Init(_sync);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync;
};

static_assert(sizeof(DeleteSync) == 8, "size of DeleteSync should be 8");
static_assert(offsetof(DeleteSync, header) == 0,
              "offset of DeleteSync header should be 0");
static_assert(offsetof(DeleteSync, sync) == 4,
              "offset of DeleteSync sync should be 4");

struct DeleteShader {
  typedef DeleteShader ValueType;
  static const CommandId kCmdId = kDeleteShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader) {
    SetHeader();
    shader = _shader;
  }

  void* Set(void* cmd, GLuint _shader) {
    static_cast<ValueType*>(cmd)->Init(_shader);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
};

static_assert(sizeof(DeleteShader) == 8, "size of DeleteShader should be 8");
static_assert(offsetof(DeleteShader, header) == 0,
              "offset of DeleteShader header should be 0");
static_assert(offsetof(DeleteShader, shader) == 4,
              "offset of DeleteShader shader should be 4");

struct DeleteTexturesImmediate {
  typedef DeleteTexturesImmediate ValueType;
  static const CommandId kCmdId = kDeleteTexturesImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _textures) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _textures, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _textures) {
    static_cast<ValueType*>(cmd)->Init(_n, _textures);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteTexturesImmediate) == 8,
              "size of DeleteTexturesImmediate should be 8");
static_assert(offsetof(DeleteTexturesImmediate, header) == 0,
              "offset of DeleteTexturesImmediate header should be 0");
static_assert(offsetof(DeleteTexturesImmediate, n) == 4,
              "offset of DeleteTexturesImmediate n should be 4");

struct DeleteTransformFeedbacksImmediate {
  typedef DeleteTransformFeedbacksImmediate ValueType;
  static const CommandId kCmdId = kDeleteTransformFeedbacksImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _ids) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _ids, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _ids) {
    static_cast<ValueType*>(cmd)->Init(_n, _ids);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteTransformFeedbacksImmediate) == 8,
              "size of DeleteTransformFeedbacksImmediate should be 8");
static_assert(offsetof(DeleteTransformFeedbacksImmediate, header) == 0,
              "offset of DeleteTransformFeedbacksImmediate header should be 0");
static_assert(offsetof(DeleteTransformFeedbacksImmediate, n) == 4,
              "offset of DeleteTransformFeedbacksImmediate n should be 4");

struct DepthFunc {
  typedef DepthFunc ValueType;
  static const CommandId kCmdId = kDepthFunc;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _func) {
    SetHeader();
    func = _func;
  }

  void* Set(void* cmd, GLenum _func) {
    static_cast<ValueType*>(cmd)->Init(_func);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t func;
};

static_assert(sizeof(DepthFunc) == 8, "size of DepthFunc should be 8");
static_assert(offsetof(DepthFunc, header) == 0,
              "offset of DepthFunc header should be 0");
static_assert(offsetof(DepthFunc, func) == 4,
              "offset of DepthFunc func should be 4");

struct DepthMask {
  typedef DepthMask ValueType;
  static const CommandId kCmdId = kDepthMask;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLboolean _flag) {
    SetHeader();
    flag = _flag;
  }

  void* Set(void* cmd, GLboolean _flag) {
    static_cast<ValueType*>(cmd)->Init(_flag);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t flag;
};

static_assert(sizeof(DepthMask) == 8, "size of DepthMask should be 8");
static_assert(offsetof(DepthMask, header) == 0,
              "offset of DepthMask header should be 0");
static_assert(offsetof(DepthMask, flag) == 4,
              "offset of DepthMask flag should be 4");

struct DepthRangef {
  typedef DepthRangef ValueType;
  static const CommandId kCmdId = kDepthRangef;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLclampf _zNear, GLclampf _zFar) {
    SetHeader();
    zNear = _zNear;
    zFar = _zFar;
  }

  void* Set(void* cmd, GLclampf _zNear, GLclampf _zFar) {
    static_cast<ValueType*>(cmd)->Init(_zNear, _zFar);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float zNear;
  float zFar;
};

static_assert(sizeof(DepthRangef) == 12, "size of DepthRangef should be 12");
static_assert(offsetof(DepthRangef, header) == 0,
              "offset of DepthRangef header should be 0");
static_assert(offsetof(DepthRangef, zNear) == 4,
              "offset of DepthRangef zNear should be 4");
static_assert(offsetof(DepthRangef, zFar) == 8,
              "offset of DepthRangef zFar should be 8");

struct DetachShader {
  typedef DetachShader ValueType;
  static const CommandId kCmdId = kDetachShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, GLuint _shader) {
    SetHeader();
    program = _program;
    shader = _shader;
  }

  void* Set(void* cmd, GLuint _program, GLuint _shader) {
    static_cast<ValueType*>(cmd)->Init(_program, _shader);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t shader;
};

static_assert(sizeof(DetachShader) == 12, "size of DetachShader should be 12");
static_assert(offsetof(DetachShader, header) == 0,
              "offset of DetachShader header should be 0");
static_assert(offsetof(DetachShader, program) == 4,
              "offset of DetachShader program should be 4");
static_assert(offsetof(DetachShader, shader) == 8,
              "offset of DetachShader shader should be 8");

struct Disable {
  typedef Disable ValueType;
  static const CommandId kCmdId = kDisable;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _cap) {
    SetHeader();
    cap = _cap;
  }

  void* Set(void* cmd, GLenum _cap) {
    static_cast<ValueType*>(cmd)->Init(_cap);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t cap;
};

static_assert(sizeof(Disable) == 8, "size of Disable should be 8");
static_assert(offsetof(Disable, header) == 0,
              "offset of Disable header should be 0");
static_assert(offsetof(Disable, cap) == 4, "offset of Disable cap should be 4");

struct DisableVertexAttribArray {
  typedef DisableVertexAttribArray ValueType;
  static const CommandId kCmdId = kDisableVertexAttribArray;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index) {
    SetHeader();
    index = _index;
  }

  void* Set(void* cmd, GLuint _index) {
    static_cast<ValueType*>(cmd)->Init(_index);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
};

static_assert(sizeof(DisableVertexAttribArray) == 8,
              "size of DisableVertexAttribArray should be 8");
static_assert(offsetof(DisableVertexAttribArray, header) == 0,
              "offset of DisableVertexAttribArray header should be 0");
static_assert(offsetof(DisableVertexAttribArray, index) == 4,
              "offset of DisableVertexAttribArray index should be 4");

struct DrawArrays {
  typedef DrawArrays ValueType;
  static const CommandId kCmdId = kDrawArrays;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(2);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode, GLint _first, GLsizei _count) {
    SetHeader();
    mode = _mode;
    first = _first;
    count = _count;
  }

  void* Set(void* cmd, GLenum _mode, GLint _first, GLsizei _count) {
    static_cast<ValueType*>(cmd)->Init(_mode, _first, _count);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
  int32_t first;
  int32_t count;
};

static_assert(sizeof(DrawArrays) == 16, "size of DrawArrays should be 16");
static_assert(offsetof(DrawArrays, header) == 0,
              "offset of DrawArrays header should be 0");
static_assert(offsetof(DrawArrays, mode) == 4,
              "offset of DrawArrays mode should be 4");
static_assert(offsetof(DrawArrays, first) == 8,
              "offset of DrawArrays first should be 8");
static_assert(offsetof(DrawArrays, count) == 12,
              "offset of DrawArrays count should be 12");

struct DrawElements {
  typedef DrawElements ValueType;
  static const CommandId kCmdId = kDrawElements;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(2);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode, GLsizei _count, GLenum _type, GLuint _index_offset) {
    SetHeader();
    mode = _mode;
    count = _count;
    type = _type;
    index_offset = _index_offset;
  }

  void* Set(void* cmd,
            GLenum _mode,
            GLsizei _count,
            GLenum _type,
            GLuint _index_offset) {
    static_cast<ValueType*>(cmd)->Init(_mode, _count, _type, _index_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
  int32_t count;
  uint32_t type;
  uint32_t index_offset;
};

static_assert(sizeof(DrawElements) == 20, "size of DrawElements should be 20");
static_assert(offsetof(DrawElements, header) == 0,
              "offset of DrawElements header should be 0");
static_assert(offsetof(DrawElements, mode) == 4,
              "offset of DrawElements mode should be 4");
static_assert(offsetof(DrawElements, count) == 8,
              "offset of DrawElements count should be 8");
static_assert(offsetof(DrawElements, type) == 12,
              "offset of DrawElements type should be 12");
static_assert(offsetof(DrawElements, index_offset) == 16,
              "offset of DrawElements index_offset should be 16");

struct Enable {
  typedef Enable ValueType;
  static const CommandId kCmdId = kEnable;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _cap) {
    SetHeader();
    cap = _cap;
  }

  void* Set(void* cmd, GLenum _cap) {
    static_cast<ValueType*>(cmd)->Init(_cap);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t cap;
};

static_assert(sizeof(Enable) == 8, "size of Enable should be 8");
static_assert(offsetof(Enable, header) == 0,
              "offset of Enable header should be 0");
static_assert(offsetof(Enable, cap) == 4, "offset of Enable cap should be 4");

struct EnableVertexAttribArray {
  typedef EnableVertexAttribArray ValueType;
  static const CommandId kCmdId = kEnableVertexAttribArray;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index) {
    SetHeader();
    index = _index;
  }

  void* Set(void* cmd, GLuint _index) {
    static_cast<ValueType*>(cmd)->Init(_index);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
};

static_assert(sizeof(EnableVertexAttribArray) == 8,
              "size of EnableVertexAttribArray should be 8");
static_assert(offsetof(EnableVertexAttribArray, header) == 0,
              "offset of EnableVertexAttribArray header should be 0");
static_assert(offsetof(EnableVertexAttribArray, index) == 4,
              "offset of EnableVertexAttribArray index should be 4");

struct FenceSync {
  typedef FenceSync ValueType;
  static const CommandId kCmdId = kFenceSync;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(uint32_t _client_id) {
    SetHeader();
    client_id = _client_id;
  }

  void* Set(void* cmd, uint32_t _client_id) {
    static_cast<ValueType*>(cmd)->Init(_client_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t client_id;
  static const uint32_t condition = GL_SYNC_GPU_COMMANDS_COMPLETE;
  static const uint32_t flags = 0;
};

static_assert(sizeof(FenceSync) == 8, "size of FenceSync should be 8");
static_assert(offsetof(FenceSync, header) == 0,
              "offset of FenceSync header should be 0");
static_assert(offsetof(FenceSync, client_id) == 4,
              "offset of FenceSync client_id should be 4");

struct Finish {
  typedef Finish ValueType;
  static const CommandId kCmdId = kFinish;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(Finish) == 4, "size of Finish should be 4");
static_assert(offsetof(Finish, header) == 0,
              "offset of Finish header should be 0");

struct Flush {
  typedef Flush ValueType;
  static const CommandId kCmdId = kFlush;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(Flush) == 4, "size of Flush should be 4");
static_assert(offsetof(Flush, header) == 0,
              "offset of Flush header should be 0");

struct FramebufferRenderbuffer {
  typedef FramebufferRenderbuffer ValueType;
  static const CommandId kCmdId = kFramebufferRenderbuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _attachment,
            GLenum _renderbuffertarget,
            GLuint _renderbuffer) {
    SetHeader();
    target = _target;
    attachment = _attachment;
    renderbuffertarget = _renderbuffertarget;
    renderbuffer = _renderbuffer;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _attachment,
            GLenum _renderbuffertarget,
            GLuint _renderbuffer) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _attachment, _renderbuffertarget, _renderbuffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t attachment;
  uint32_t renderbuffertarget;
  uint32_t renderbuffer;
};

static_assert(sizeof(FramebufferRenderbuffer) == 20,
              "size of FramebufferRenderbuffer should be 20");
static_assert(offsetof(FramebufferRenderbuffer, header) == 0,
              "offset of FramebufferRenderbuffer header should be 0");
static_assert(offsetof(FramebufferRenderbuffer, target) == 4,
              "offset of FramebufferRenderbuffer target should be 4");
static_assert(offsetof(FramebufferRenderbuffer, attachment) == 8,
              "offset of FramebufferRenderbuffer attachment should be 8");
static_assert(
    offsetof(FramebufferRenderbuffer, renderbuffertarget) == 12,
    "offset of FramebufferRenderbuffer renderbuffertarget should be 12");
static_assert(offsetof(FramebufferRenderbuffer, renderbuffer) == 16,
              "offset of FramebufferRenderbuffer renderbuffer should be 16");

struct FramebufferTexture2D {
  typedef FramebufferTexture2D ValueType;
  static const CommandId kCmdId = kFramebufferTexture2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _attachment,
            GLenum _textarget,
            GLuint _texture) {
    SetHeader();
    target = _target;
    attachment = _attachment;
    textarget = _textarget;
    texture = _texture;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _attachment,
            GLenum _textarget,
            GLuint _texture) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _attachment, _textarget, _texture);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t attachment;
  uint32_t textarget;
  uint32_t texture;
  static const int32_t level = 0;
};

static_assert(sizeof(FramebufferTexture2D) == 20,
              "size of FramebufferTexture2D should be 20");
static_assert(offsetof(FramebufferTexture2D, header) == 0,
              "offset of FramebufferTexture2D header should be 0");
static_assert(offsetof(FramebufferTexture2D, target) == 4,
              "offset of FramebufferTexture2D target should be 4");
static_assert(offsetof(FramebufferTexture2D, attachment) == 8,
              "offset of FramebufferTexture2D attachment should be 8");
static_assert(offsetof(FramebufferTexture2D, textarget) == 12,
              "offset of FramebufferTexture2D textarget should be 12");
static_assert(offsetof(FramebufferTexture2D, texture) == 16,
              "offset of FramebufferTexture2D texture should be 16");

struct FramebufferTextureLayer {
  typedef FramebufferTextureLayer ValueType;
  static const CommandId kCmdId = kFramebufferTextureLayer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _attachment,
            GLuint _texture,
            GLint _level,
            GLint _layer) {
    SetHeader();
    target = _target;
    attachment = _attachment;
    texture = _texture;
    level = _level;
    layer = _layer;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _attachment,
            GLuint _texture,
            GLint _level,
            GLint _layer) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _attachment, _texture, _level, _layer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t attachment;
  uint32_t texture;
  int32_t level;
  int32_t layer;
};

static_assert(sizeof(FramebufferTextureLayer) == 24,
              "size of FramebufferTextureLayer should be 24");
static_assert(offsetof(FramebufferTextureLayer, header) == 0,
              "offset of FramebufferTextureLayer header should be 0");
static_assert(offsetof(FramebufferTextureLayer, target) == 4,
              "offset of FramebufferTextureLayer target should be 4");
static_assert(offsetof(FramebufferTextureLayer, attachment) == 8,
              "offset of FramebufferTextureLayer attachment should be 8");
static_assert(offsetof(FramebufferTextureLayer, texture) == 12,
              "offset of FramebufferTextureLayer texture should be 12");
static_assert(offsetof(FramebufferTextureLayer, level) == 16,
              "offset of FramebufferTextureLayer level should be 16");
static_assert(offsetof(FramebufferTextureLayer, layer) == 20,
              "offset of FramebufferTextureLayer layer should be 20");

struct FrontFace {
  typedef FrontFace ValueType;
  static const CommandId kCmdId = kFrontFace;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode) {
    SetHeader();
    mode = _mode;
  }

  void* Set(void* cmd, GLenum _mode) {
    static_cast<ValueType*>(cmd)->Init(_mode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
};

static_assert(sizeof(FrontFace) == 8, "size of FrontFace should be 8");
static_assert(offsetof(FrontFace, header) == 0,
              "offset of FrontFace header should be 0");
static_assert(offsetof(FrontFace, mode) == 4,
              "offset of FrontFace mode should be 4");

struct GenBuffersImmediate {
  typedef GenBuffersImmediate ValueType;
  static const CommandId kCmdId = kGenBuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _buffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _buffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _buffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _buffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenBuffersImmediate) == 8,
              "size of GenBuffersImmediate should be 8");
static_assert(offsetof(GenBuffersImmediate, header) == 0,
              "offset of GenBuffersImmediate header should be 0");
static_assert(offsetof(GenBuffersImmediate, n) == 4,
              "offset of GenBuffersImmediate n should be 4");

struct GenerateMipmap {
  typedef GenerateMipmap ValueType;
  static const CommandId kCmdId = kGenerateMipmap;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target) {
    SetHeader();
    target = _target;
  }

  void* Set(void* cmd, GLenum _target) {
    static_cast<ValueType*>(cmd)->Init(_target);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(GenerateMipmap) == 8,
              "size of GenerateMipmap should be 8");
static_assert(offsetof(GenerateMipmap, header) == 0,
              "offset of GenerateMipmap header should be 0");
static_assert(offsetof(GenerateMipmap, target) == 4,
              "offset of GenerateMipmap target should be 4");

struct GenFramebuffersImmediate {
  typedef GenFramebuffersImmediate ValueType;
  static const CommandId kCmdId = kGenFramebuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _framebuffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _framebuffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _framebuffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _framebuffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenFramebuffersImmediate) == 8,
              "size of GenFramebuffersImmediate should be 8");
static_assert(offsetof(GenFramebuffersImmediate, header) == 0,
              "offset of GenFramebuffersImmediate header should be 0");
static_assert(offsetof(GenFramebuffersImmediate, n) == 4,
              "offset of GenFramebuffersImmediate n should be 4");

struct GenRenderbuffersImmediate {
  typedef GenRenderbuffersImmediate ValueType;
  static const CommandId kCmdId = kGenRenderbuffersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _renderbuffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _renderbuffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _renderbuffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _renderbuffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenRenderbuffersImmediate) == 8,
              "size of GenRenderbuffersImmediate should be 8");
static_assert(offsetof(GenRenderbuffersImmediate, header) == 0,
              "offset of GenRenderbuffersImmediate header should be 0");
static_assert(offsetof(GenRenderbuffersImmediate, n) == 4,
              "offset of GenRenderbuffersImmediate n should be 4");

struct GenSamplersImmediate {
  typedef GenSamplersImmediate ValueType;
  static const CommandId kCmdId = kGenSamplersImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _samplers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _samplers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _samplers) {
    static_cast<ValueType*>(cmd)->Init(_n, _samplers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenSamplersImmediate) == 8,
              "size of GenSamplersImmediate should be 8");
static_assert(offsetof(GenSamplersImmediate, header) == 0,
              "offset of GenSamplersImmediate header should be 0");
static_assert(offsetof(GenSamplersImmediate, n) == 4,
              "offset of GenSamplersImmediate n should be 4");

struct GenTexturesImmediate {
  typedef GenTexturesImmediate ValueType;
  static const CommandId kCmdId = kGenTexturesImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _textures) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _textures, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _textures) {
    static_cast<ValueType*>(cmd)->Init(_n, _textures);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenTexturesImmediate) == 8,
              "size of GenTexturesImmediate should be 8");
static_assert(offsetof(GenTexturesImmediate, header) == 0,
              "offset of GenTexturesImmediate header should be 0");
static_assert(offsetof(GenTexturesImmediate, n) == 4,
              "offset of GenTexturesImmediate n should be 4");

struct GenTransformFeedbacksImmediate {
  typedef GenTransformFeedbacksImmediate ValueType;
  static const CommandId kCmdId = kGenTransformFeedbacksImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _ids) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _ids, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _ids) {
    static_cast<ValueType*>(cmd)->Init(_n, _ids);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenTransformFeedbacksImmediate) == 8,
              "size of GenTransformFeedbacksImmediate should be 8");
static_assert(offsetof(GenTransformFeedbacksImmediate, header) == 0,
              "offset of GenTransformFeedbacksImmediate header should be 0");
static_assert(offsetof(GenTransformFeedbacksImmediate, n) == 4,
              "offset of GenTransformFeedbacksImmediate n should be 4");

struct GetActiveAttrib {
  typedef GetActiveAttrib ValueType;
  static const CommandId kCmdId = kGetActiveAttrib;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  struct Result {
    int32_t success;
    int32_t size;
    uint32_t type;
  };

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    program = _program;
    index = _index;
    name_bucket_id = _name_bucket_id;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _name_bucket_id,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t name_bucket_id;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetActiveAttrib) == 24,
              "size of GetActiveAttrib should be 24");
static_assert(offsetof(GetActiveAttrib, header) == 0,
              "offset of GetActiveAttrib header should be 0");
static_assert(offsetof(GetActiveAttrib, program) == 4,
              "offset of GetActiveAttrib program should be 4");
static_assert(offsetof(GetActiveAttrib, index) == 8,
              "offset of GetActiveAttrib index should be 8");
static_assert(offsetof(GetActiveAttrib, name_bucket_id) == 12,
              "offset of GetActiveAttrib name_bucket_id should be 12");
static_assert(offsetof(GetActiveAttrib, result_shm_id) == 16,
              "offset of GetActiveAttrib result_shm_id should be 16");
static_assert(offsetof(GetActiveAttrib, result_shm_offset) == 20,
              "offset of GetActiveAttrib result_shm_offset should be 20");
static_assert(offsetof(GetActiveAttrib::Result, success) == 0,
              "offset of GetActiveAttrib Result success should be "
              "0");
static_assert(offsetof(GetActiveAttrib::Result, size) == 4,
              "offset of GetActiveAttrib Result size should be "
              "4");
static_assert(offsetof(GetActiveAttrib::Result, type) == 8,
              "offset of GetActiveAttrib Result type should be "
              "8");

struct GetActiveUniform {
  typedef GetActiveUniform ValueType;
  static const CommandId kCmdId = kGetActiveUniform;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  struct Result {
    int32_t success;
    int32_t size;
    uint32_t type;
  };

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    program = _program;
    index = _index;
    name_bucket_id = _name_bucket_id;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _name_bucket_id,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t name_bucket_id;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetActiveUniform) == 24,
              "size of GetActiveUniform should be 24");
static_assert(offsetof(GetActiveUniform, header) == 0,
              "offset of GetActiveUniform header should be 0");
static_assert(offsetof(GetActiveUniform, program) == 4,
              "offset of GetActiveUniform program should be 4");
static_assert(offsetof(GetActiveUniform, index) == 8,
              "offset of GetActiveUniform index should be 8");
static_assert(offsetof(GetActiveUniform, name_bucket_id) == 12,
              "offset of GetActiveUniform name_bucket_id should be 12");
static_assert(offsetof(GetActiveUniform, result_shm_id) == 16,
              "offset of GetActiveUniform result_shm_id should be 16");
static_assert(offsetof(GetActiveUniform, result_shm_offset) == 20,
              "offset of GetActiveUniform result_shm_offset should be 20");
static_assert(offsetof(GetActiveUniform::Result, success) == 0,
              "offset of GetActiveUniform Result success should be "
              "0");
static_assert(offsetof(GetActiveUniform::Result, size) == 4,
              "offset of GetActiveUniform Result size should be "
              "4");
static_assert(offsetof(GetActiveUniform::Result, type) == 8,
              "offset of GetActiveUniform Result type should be "
              "8");

struct GetActiveUniformBlockiv {
  typedef GetActiveUniformBlockiv ValueType;
  static const CommandId kCmdId = kGetActiveUniformBlockiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    program = _program;
    index = _index;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _index, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetActiveUniformBlockiv) == 24,
              "size of GetActiveUniformBlockiv should be 24");
static_assert(offsetof(GetActiveUniformBlockiv, header) == 0,
              "offset of GetActiveUniformBlockiv header should be 0");
static_assert(offsetof(GetActiveUniformBlockiv, program) == 4,
              "offset of GetActiveUniformBlockiv program should be 4");
static_assert(offsetof(GetActiveUniformBlockiv, index) == 8,
              "offset of GetActiveUniformBlockiv index should be 8");
static_assert(offsetof(GetActiveUniformBlockiv, pname) == 12,
              "offset of GetActiveUniformBlockiv pname should be 12");
static_assert(offsetof(GetActiveUniformBlockiv, params_shm_id) == 16,
              "offset of GetActiveUniformBlockiv params_shm_id should be 16");
static_assert(
    offsetof(GetActiveUniformBlockiv, params_shm_offset) == 20,
    "offset of GetActiveUniformBlockiv params_shm_offset should be 20");

struct GetActiveUniformBlockName {
  typedef GetActiveUniformBlockName ValueType;
  static const CommandId kCmdId = kGetActiveUniformBlockName;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef int32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    program = _program;
    index = _index;
    name_bucket_id = _name_bucket_id;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _name_bucket_id,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t name_bucket_id;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetActiveUniformBlockName) == 24,
              "size of GetActiveUniformBlockName should be 24");
static_assert(offsetof(GetActiveUniformBlockName, header) == 0,
              "offset of GetActiveUniformBlockName header should be 0");
static_assert(offsetof(GetActiveUniformBlockName, program) == 4,
              "offset of GetActiveUniformBlockName program should be 4");
static_assert(offsetof(GetActiveUniformBlockName, index) == 8,
              "offset of GetActiveUniformBlockName index should be 8");
static_assert(
    offsetof(GetActiveUniformBlockName, name_bucket_id) == 12,
    "offset of GetActiveUniformBlockName name_bucket_id should be 12");
static_assert(offsetof(GetActiveUniformBlockName, result_shm_id) == 16,
              "offset of GetActiveUniformBlockName result_shm_id should be 16");
static_assert(
    offsetof(GetActiveUniformBlockName, result_shm_offset) == 20,
    "offset of GetActiveUniformBlockName result_shm_offset should be 20");

struct GetActiveUniformsiv {
  typedef GetActiveUniformsiv ValueType;
  static const CommandId kCmdId = kGetActiveUniformsiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _indices_bucket_id,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    program = _program;
    indices_bucket_id = _indices_bucket_id;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _indices_bucket_id,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _indices_bucket_id, _pname,
                                       _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t indices_bucket_id;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetActiveUniformsiv) == 24,
              "size of GetActiveUniformsiv should be 24");
static_assert(offsetof(GetActiveUniformsiv, header) == 0,
              "offset of GetActiveUniformsiv header should be 0");
static_assert(offsetof(GetActiveUniformsiv, program) == 4,
              "offset of GetActiveUniformsiv program should be 4");
static_assert(offsetof(GetActiveUniformsiv, indices_bucket_id) == 8,
              "offset of GetActiveUniformsiv indices_bucket_id should be 8");
static_assert(offsetof(GetActiveUniformsiv, pname) == 12,
              "offset of GetActiveUniformsiv pname should be 12");
static_assert(offsetof(GetActiveUniformsiv, params_shm_id) == 16,
              "offset of GetActiveUniformsiv params_shm_id should be 16");
static_assert(offsetof(GetActiveUniformsiv, params_shm_offset) == 20,
              "offset of GetActiveUniformsiv params_shm_offset should be 20");

struct GetAttachedShaders {
  typedef GetAttachedShaders ValueType;
  static const CommandId kCmdId = kGetAttachedShaders;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLuint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset,
            uint32_t _result_size) {
    SetHeader();
    program = _program;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
    result_size = _result_size;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset,
            uint32_t _result_size) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _result_shm_id, _result_shm_offset, _result_size);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
  uint32_t result_size;
};

static_assert(sizeof(GetAttachedShaders) == 20,
              "size of GetAttachedShaders should be 20");
static_assert(offsetof(GetAttachedShaders, header) == 0,
              "offset of GetAttachedShaders header should be 0");
static_assert(offsetof(GetAttachedShaders, program) == 4,
              "offset of GetAttachedShaders program should be 4");
static_assert(offsetof(GetAttachedShaders, result_shm_id) == 8,
              "offset of GetAttachedShaders result_shm_id should be 8");
static_assert(offsetof(GetAttachedShaders, result_shm_offset) == 12,
              "offset of GetAttachedShaders result_shm_offset should be 12");
static_assert(offsetof(GetAttachedShaders, result_size) == 16,
              "offset of GetAttachedShaders result_size should be 16");

struct GetAttribLocation {
  typedef GetAttribLocation ValueType;
  static const CommandId kCmdId = kGetAttribLocation;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    SetHeader();
    program = _program;
    name_bucket_id = _name_bucket_id;
    location_shm_id = _location_shm_id;
    location_shm_offset = _location_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _name_bucket_id,
                                       _location_shm_id, _location_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t name_bucket_id;
  uint32_t location_shm_id;
  uint32_t location_shm_offset;
};

static_assert(sizeof(GetAttribLocation) == 20,
              "size of GetAttribLocation should be 20");
static_assert(offsetof(GetAttribLocation, header) == 0,
              "offset of GetAttribLocation header should be 0");
static_assert(offsetof(GetAttribLocation, program) == 4,
              "offset of GetAttribLocation program should be 4");
static_assert(offsetof(GetAttribLocation, name_bucket_id) == 8,
              "offset of GetAttribLocation name_bucket_id should be 8");
static_assert(offsetof(GetAttribLocation, location_shm_id) == 12,
              "offset of GetAttribLocation location_shm_id should be 12");
static_assert(offsetof(GetAttribLocation, location_shm_offset) == 16,
              "offset of GetAttribLocation location_shm_offset should be 16");

struct GetBooleanv {
  typedef GetBooleanv ValueType;
  static const CommandId kCmdId = kGetBooleanv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLboolean> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetBooleanv) == 16, "size of GetBooleanv should be 16");
static_assert(offsetof(GetBooleanv, header) == 0,
              "offset of GetBooleanv header should be 0");
static_assert(offsetof(GetBooleanv, pname) == 4,
              "offset of GetBooleanv pname should be 4");
static_assert(offsetof(GetBooleanv, params_shm_id) == 8,
              "offset of GetBooleanv params_shm_id should be 8");
static_assert(offsetof(GetBooleanv, params_shm_offset) == 12,
              "offset of GetBooleanv params_shm_offset should be 12");

struct GetBufferParameteriv {
  typedef GetBufferParameteriv ValueType;
  static const CommandId kCmdId = kGetBufferParameteriv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetBufferParameteriv) == 20,
              "size of GetBufferParameteriv should be 20");
static_assert(offsetof(GetBufferParameteriv, header) == 0,
              "offset of GetBufferParameteriv header should be 0");
static_assert(offsetof(GetBufferParameteriv, target) == 4,
              "offset of GetBufferParameteriv target should be 4");
static_assert(offsetof(GetBufferParameteriv, pname) == 8,
              "offset of GetBufferParameteriv pname should be 8");
static_assert(offsetof(GetBufferParameteriv, params_shm_id) == 12,
              "offset of GetBufferParameteriv params_shm_id should be 12");
static_assert(offsetof(GetBufferParameteriv, params_shm_offset) == 16,
              "offset of GetBufferParameteriv params_shm_offset should be 16");

struct GetError {
  typedef GetError ValueType;
  static const CommandId kCmdId = kGetError;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLenum Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(uint32_t _result_shm_id, uint32_t _result_shm_offset) {
    SetHeader();
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd, uint32_t _result_shm_id, uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetError) == 12, "size of GetError should be 12");
static_assert(offsetof(GetError, header) == 0,
              "offset of GetError header should be 0");
static_assert(offsetof(GetError, result_shm_id) == 4,
              "offset of GetError result_shm_id should be 4");
static_assert(offsetof(GetError, result_shm_offset) == 8,
              "offset of GetError result_shm_offset should be 8");

struct GetFloatv {
  typedef GetFloatv ValueType;
  static const CommandId kCmdId = kGetFloatv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLfloat> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetFloatv) == 16, "size of GetFloatv should be 16");
static_assert(offsetof(GetFloatv, header) == 0,
              "offset of GetFloatv header should be 0");
static_assert(offsetof(GetFloatv, pname) == 4,
              "offset of GetFloatv pname should be 4");
static_assert(offsetof(GetFloatv, params_shm_id) == 8,
              "offset of GetFloatv params_shm_id should be 8");
static_assert(offsetof(GetFloatv, params_shm_offset) == 12,
              "offset of GetFloatv params_shm_offset should be 12");

struct GetFragDataLocation {
  typedef GetFragDataLocation ValueType;
  static const CommandId kCmdId = kGetFragDataLocation;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    SetHeader();
    program = _program;
    name_bucket_id = _name_bucket_id;
    location_shm_id = _location_shm_id;
    location_shm_offset = _location_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _name_bucket_id,
                                       _location_shm_id, _location_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t name_bucket_id;
  uint32_t location_shm_id;
  uint32_t location_shm_offset;
};

static_assert(sizeof(GetFragDataLocation) == 20,
              "size of GetFragDataLocation should be 20");
static_assert(offsetof(GetFragDataLocation, header) == 0,
              "offset of GetFragDataLocation header should be 0");
static_assert(offsetof(GetFragDataLocation, program) == 4,
              "offset of GetFragDataLocation program should be 4");
static_assert(offsetof(GetFragDataLocation, name_bucket_id) == 8,
              "offset of GetFragDataLocation name_bucket_id should be 8");
static_assert(offsetof(GetFragDataLocation, location_shm_id) == 12,
              "offset of GetFragDataLocation location_shm_id should be 12");
static_assert(offsetof(GetFragDataLocation, location_shm_offset) == 16,
              "offset of GetFragDataLocation location_shm_offset should be 16");

struct GetFramebufferAttachmentParameteriv {
  typedef GetFramebufferAttachmentParameteriv ValueType;
  static const CommandId kCmdId = kGetFramebufferAttachmentParameteriv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _attachment,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    attachment = _attachment;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _attachment,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _attachment, _pname,
                                       _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t attachment;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetFramebufferAttachmentParameteriv) == 24,
              "size of GetFramebufferAttachmentParameteriv should be 24");
static_assert(
    offsetof(GetFramebufferAttachmentParameteriv, header) == 0,
    "offset of GetFramebufferAttachmentParameteriv header should be 0");
static_assert(
    offsetof(GetFramebufferAttachmentParameteriv, target) == 4,
    "offset of GetFramebufferAttachmentParameteriv target should be 4");
static_assert(
    offsetof(GetFramebufferAttachmentParameteriv, attachment) == 8,
    "offset of GetFramebufferAttachmentParameteriv attachment should be 8");
static_assert(
    offsetof(GetFramebufferAttachmentParameteriv, pname) == 12,
    "offset of GetFramebufferAttachmentParameteriv pname should be 12");
static_assert(
    offsetof(GetFramebufferAttachmentParameteriv, params_shm_id) == 16,
    "offset of GetFramebufferAttachmentParameteriv params_shm_id should be 16");
static_assert(offsetof(GetFramebufferAttachmentParameteriv,
                       params_shm_offset) == 20,
              "offset of GetFramebufferAttachmentParameteriv params_shm_offset "
              "should be 20");

struct GetInteger64v {
  typedef GetInteger64v ValueType;
  static const CommandId kCmdId = kGetInteger64v;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint64> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetInteger64v) == 16,
              "size of GetInteger64v should be 16");
static_assert(offsetof(GetInteger64v, header) == 0,
              "offset of GetInteger64v header should be 0");
static_assert(offsetof(GetInteger64v, pname) == 4,
              "offset of GetInteger64v pname should be 4");
static_assert(offsetof(GetInteger64v, params_shm_id) == 8,
              "offset of GetInteger64v params_shm_id should be 8");
static_assert(offsetof(GetInteger64v, params_shm_offset) == 12,
              "offset of GetInteger64v params_shm_offset should be 12");

struct GetIntegeri_v {
  typedef GetIntegeri_v ValueType;
  static const CommandId kCmdId = kGetIntegeri_v;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            GLuint _index,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    SetHeader();
    pname = _pname;
    index = _index;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            GLuint _index,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _index, _data_shm_id, _data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t index;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
};

static_assert(sizeof(GetIntegeri_v) == 20,
              "size of GetIntegeri_v should be 20");
static_assert(offsetof(GetIntegeri_v, header) == 0,
              "offset of GetIntegeri_v header should be 0");
static_assert(offsetof(GetIntegeri_v, pname) == 4,
              "offset of GetIntegeri_v pname should be 4");
static_assert(offsetof(GetIntegeri_v, index) == 8,
              "offset of GetIntegeri_v index should be 8");
static_assert(offsetof(GetIntegeri_v, data_shm_id) == 12,
              "offset of GetIntegeri_v data_shm_id should be 12");
static_assert(offsetof(GetIntegeri_v, data_shm_offset) == 16,
              "offset of GetIntegeri_v data_shm_offset should be 16");

struct GetInteger64i_v {
  typedef GetInteger64i_v ValueType;
  static const CommandId kCmdId = kGetInteger64i_v;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint64> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            GLuint _index,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    SetHeader();
    pname = _pname;
    index = _index;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            GLuint _index,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _index, _data_shm_id, _data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t index;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
};

static_assert(sizeof(GetInteger64i_v) == 20,
              "size of GetInteger64i_v should be 20");
static_assert(offsetof(GetInteger64i_v, header) == 0,
              "offset of GetInteger64i_v header should be 0");
static_assert(offsetof(GetInteger64i_v, pname) == 4,
              "offset of GetInteger64i_v pname should be 4");
static_assert(offsetof(GetInteger64i_v, index) == 8,
              "offset of GetInteger64i_v index should be 8");
static_assert(offsetof(GetInteger64i_v, data_shm_id) == 12,
              "offset of GetInteger64i_v data_shm_id should be 12");
static_assert(offsetof(GetInteger64i_v, data_shm_offset) == 16,
              "offset of GetInteger64i_v data_shm_offset should be 16");

struct GetIntegerv {
  typedef GetIntegerv ValueType;
  static const CommandId kCmdId = kGetIntegerv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetIntegerv) == 16, "size of GetIntegerv should be 16");
static_assert(offsetof(GetIntegerv, header) == 0,
              "offset of GetIntegerv header should be 0");
static_assert(offsetof(GetIntegerv, pname) == 4,
              "offset of GetIntegerv pname should be 4");
static_assert(offsetof(GetIntegerv, params_shm_id) == 8,
              "offset of GetIntegerv params_shm_id should be 8");
static_assert(offsetof(GetIntegerv, params_shm_offset) == 12,
              "offset of GetIntegerv params_shm_offset should be 12");

struct GetInternalformativ {
  typedef GetInternalformativ ValueType;
  static const CommandId kCmdId = kGetInternalformativ;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _format,
            GLenum _pname,
            GLsizei _bufSize,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    format = _format;
    pname = _pname;
    bufSize = _bufSize;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _format,
            GLenum _pname,
            GLsizei _bufSize,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _format, _pname, _bufSize,
                                       _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t format;
  uint32_t pname;
  int32_t bufSize;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetInternalformativ) == 28,
              "size of GetInternalformativ should be 28");
static_assert(offsetof(GetInternalformativ, header) == 0,
              "offset of GetInternalformativ header should be 0");
static_assert(offsetof(GetInternalformativ, target) == 4,
              "offset of GetInternalformativ target should be 4");
static_assert(offsetof(GetInternalformativ, format) == 8,
              "offset of GetInternalformativ format should be 8");
static_assert(offsetof(GetInternalformativ, pname) == 12,
              "offset of GetInternalformativ pname should be 12");
static_assert(offsetof(GetInternalformativ, bufSize) == 16,
              "offset of GetInternalformativ bufSize should be 16");
static_assert(offsetof(GetInternalformativ, params_shm_id) == 20,
              "offset of GetInternalformativ params_shm_id should be 20");
static_assert(offsetof(GetInternalformativ, params_shm_offset) == 24,
              "offset of GetInternalformativ params_shm_offset should be 24");

struct GetProgramiv {
  typedef GetProgramiv ValueType;
  static const CommandId kCmdId = kGetProgramiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    program = _program;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetProgramiv) == 20, "size of GetProgramiv should be 20");
static_assert(offsetof(GetProgramiv, header) == 0,
              "offset of GetProgramiv header should be 0");
static_assert(offsetof(GetProgramiv, program) == 4,
              "offset of GetProgramiv program should be 4");
static_assert(offsetof(GetProgramiv, pname) == 8,
              "offset of GetProgramiv pname should be 8");
static_assert(offsetof(GetProgramiv, params_shm_id) == 12,
              "offset of GetProgramiv params_shm_id should be 12");
static_assert(offsetof(GetProgramiv, params_shm_offset) == 16,
              "offset of GetProgramiv params_shm_offset should be 16");

struct GetProgramInfoLog {
  typedef GetProgramInfoLog ValueType;
  static const CommandId kCmdId = kGetProgramInfoLog;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _bucket_id) {
    SetHeader();
    program = _program;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _program, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t bucket_id;
};

static_assert(sizeof(GetProgramInfoLog) == 12,
              "size of GetProgramInfoLog should be 12");
static_assert(offsetof(GetProgramInfoLog, header) == 0,
              "offset of GetProgramInfoLog header should be 0");
static_assert(offsetof(GetProgramInfoLog, program) == 4,
              "offset of GetProgramInfoLog program should be 4");
static_assert(offsetof(GetProgramInfoLog, bucket_id) == 8,
              "offset of GetProgramInfoLog bucket_id should be 8");

struct GetRenderbufferParameteriv {
  typedef GetRenderbufferParameteriv ValueType;
  static const CommandId kCmdId = kGetRenderbufferParameteriv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetRenderbufferParameteriv) == 20,
              "size of GetRenderbufferParameteriv should be 20");
static_assert(offsetof(GetRenderbufferParameteriv, header) == 0,
              "offset of GetRenderbufferParameteriv header should be 0");
static_assert(offsetof(GetRenderbufferParameteriv, target) == 4,
              "offset of GetRenderbufferParameteriv target should be 4");
static_assert(offsetof(GetRenderbufferParameteriv, pname) == 8,
              "offset of GetRenderbufferParameteriv pname should be 8");
static_assert(
    offsetof(GetRenderbufferParameteriv, params_shm_id) == 12,
    "offset of GetRenderbufferParameteriv params_shm_id should be 12");
static_assert(
    offsetof(GetRenderbufferParameteriv, params_shm_offset) == 16,
    "offset of GetRenderbufferParameteriv params_shm_offset should be 16");

struct GetSamplerParameterfv {
  typedef GetSamplerParameterfv ValueType;
  static const CommandId kCmdId = kGetSamplerParameterfv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLfloat> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sampler,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sampler,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_sampler, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetSamplerParameterfv) == 20,
              "size of GetSamplerParameterfv should be 20");
static_assert(offsetof(GetSamplerParameterfv, header) == 0,
              "offset of GetSamplerParameterfv header should be 0");
static_assert(offsetof(GetSamplerParameterfv, sampler) == 4,
              "offset of GetSamplerParameterfv sampler should be 4");
static_assert(offsetof(GetSamplerParameterfv, pname) == 8,
              "offset of GetSamplerParameterfv pname should be 8");
static_assert(offsetof(GetSamplerParameterfv, params_shm_id) == 12,
              "offset of GetSamplerParameterfv params_shm_id should be 12");
static_assert(offsetof(GetSamplerParameterfv, params_shm_offset) == 16,
              "offset of GetSamplerParameterfv params_shm_offset should be 16");

struct GetSamplerParameteriv {
  typedef GetSamplerParameteriv ValueType;
  static const CommandId kCmdId = kGetSamplerParameteriv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sampler,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sampler,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_sampler, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetSamplerParameteriv) == 20,
              "size of GetSamplerParameteriv should be 20");
static_assert(offsetof(GetSamplerParameteriv, header) == 0,
              "offset of GetSamplerParameteriv header should be 0");
static_assert(offsetof(GetSamplerParameteriv, sampler) == 4,
              "offset of GetSamplerParameteriv sampler should be 4");
static_assert(offsetof(GetSamplerParameteriv, pname) == 8,
              "offset of GetSamplerParameteriv pname should be 8");
static_assert(offsetof(GetSamplerParameteriv, params_shm_id) == 12,
              "offset of GetSamplerParameteriv params_shm_id should be 12");
static_assert(offsetof(GetSamplerParameteriv, params_shm_offset) == 16,
              "offset of GetSamplerParameteriv params_shm_offset should be 16");

struct GetShaderiv {
  typedef GetShaderiv ValueType;
  static const CommandId kCmdId = kGetShaderiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    shader = _shader;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _shader,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_shader, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetShaderiv) == 20, "size of GetShaderiv should be 20");
static_assert(offsetof(GetShaderiv, header) == 0,
              "offset of GetShaderiv header should be 0");
static_assert(offsetof(GetShaderiv, shader) == 4,
              "offset of GetShaderiv shader should be 4");
static_assert(offsetof(GetShaderiv, pname) == 8,
              "offset of GetShaderiv pname should be 8");
static_assert(offsetof(GetShaderiv, params_shm_id) == 12,
              "offset of GetShaderiv params_shm_id should be 12");
static_assert(offsetof(GetShaderiv, params_shm_offset) == 16,
              "offset of GetShaderiv params_shm_offset should be 16");

struct GetShaderInfoLog {
  typedef GetShaderInfoLog ValueType;
  static const CommandId kCmdId = kGetShaderInfoLog;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader, uint32_t _bucket_id) {
    SetHeader();
    shader = _shader;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _shader, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_shader, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t bucket_id;
};

static_assert(sizeof(GetShaderInfoLog) == 12,
              "size of GetShaderInfoLog should be 12");
static_assert(offsetof(GetShaderInfoLog, header) == 0,
              "offset of GetShaderInfoLog header should be 0");
static_assert(offsetof(GetShaderInfoLog, shader) == 4,
              "offset of GetShaderInfoLog shader should be 4");
static_assert(offsetof(GetShaderInfoLog, bucket_id) == 8,
              "offset of GetShaderInfoLog bucket_id should be 8");

struct GetShaderPrecisionFormat {
  typedef GetShaderPrecisionFormat ValueType;
  static const CommandId kCmdId = kGetShaderPrecisionFormat;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  struct Result {
    int32_t success;
    int32_t min_range;
    int32_t max_range;
    int32_t precision;
  };

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _shadertype,
            GLenum _precisiontype,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    shadertype = _shadertype;
    precisiontype = _precisiontype;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _shadertype,
            GLenum _precisiontype,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_shadertype, _precisiontype, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shadertype;
  uint32_t precisiontype;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetShaderPrecisionFormat) == 20,
              "size of GetShaderPrecisionFormat should be 20");
static_assert(offsetof(GetShaderPrecisionFormat, header) == 0,
              "offset of GetShaderPrecisionFormat header should be 0");
static_assert(offsetof(GetShaderPrecisionFormat, shadertype) == 4,
              "offset of GetShaderPrecisionFormat shadertype should be 4");
static_assert(offsetof(GetShaderPrecisionFormat, precisiontype) == 8,
              "offset of GetShaderPrecisionFormat precisiontype should be 8");
static_assert(offsetof(GetShaderPrecisionFormat, result_shm_id) == 12,
              "offset of GetShaderPrecisionFormat result_shm_id should be 12");
static_assert(
    offsetof(GetShaderPrecisionFormat, result_shm_offset) == 16,
    "offset of GetShaderPrecisionFormat result_shm_offset should be 16");
static_assert(offsetof(GetShaderPrecisionFormat::Result, success) == 0,
              "offset of GetShaderPrecisionFormat Result success should be "
              "0");
static_assert(offsetof(GetShaderPrecisionFormat::Result, min_range) == 4,
              "offset of GetShaderPrecisionFormat Result min_range should be "
              "4");
static_assert(offsetof(GetShaderPrecisionFormat::Result, max_range) == 8,
              "offset of GetShaderPrecisionFormat Result max_range should be "
              "8");
static_assert(offsetof(GetShaderPrecisionFormat::Result, precision) == 12,
              "offset of GetShaderPrecisionFormat Result precision should be "
              "12");

struct GetShaderSource {
  typedef GetShaderSource ValueType;
  static const CommandId kCmdId = kGetShaderSource;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader, uint32_t _bucket_id) {
    SetHeader();
    shader = _shader;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _shader, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_shader, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t bucket_id;
};

static_assert(sizeof(GetShaderSource) == 12,
              "size of GetShaderSource should be 12");
static_assert(offsetof(GetShaderSource, header) == 0,
              "offset of GetShaderSource header should be 0");
static_assert(offsetof(GetShaderSource, shader) == 4,
              "offset of GetShaderSource shader should be 4");
static_assert(offsetof(GetShaderSource, bucket_id) == 8,
              "offset of GetShaderSource bucket_id should be 8");

struct GetString {
  typedef GetString ValueType;
  static const CommandId kCmdId = kGetString;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _name, uint32_t _bucket_id) {
    SetHeader();
    name = _name;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLenum _name, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_name, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t name;
  uint32_t bucket_id;
};

static_assert(sizeof(GetString) == 12, "size of GetString should be 12");
static_assert(offsetof(GetString, header) == 0,
              "offset of GetString header should be 0");
static_assert(offsetof(GetString, name) == 4,
              "offset of GetString name should be 4");
static_assert(offsetof(GetString, bucket_id) == 8,
              "offset of GetString bucket_id should be 8");

struct GetSynciv {
  typedef GetSynciv ValueType;
  static const CommandId kCmdId = kGetSynciv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync,
            GLenum _pname,
            uint32_t _values_shm_id,
            uint32_t _values_shm_offset) {
    SetHeader();
    sync = _sync;
    pname = _pname;
    values_shm_id = _values_shm_id;
    values_shm_offset = _values_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sync,
            GLenum _pname,
            uint32_t _values_shm_id,
            uint32_t _values_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_sync, _pname, _values_shm_id, _values_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync;
  uint32_t pname;
  uint32_t values_shm_id;
  uint32_t values_shm_offset;
};

static_assert(sizeof(GetSynciv) == 20, "size of GetSynciv should be 20");
static_assert(offsetof(GetSynciv, header) == 0,
              "offset of GetSynciv header should be 0");
static_assert(offsetof(GetSynciv, sync) == 4,
              "offset of GetSynciv sync should be 4");
static_assert(offsetof(GetSynciv, pname) == 8,
              "offset of GetSynciv pname should be 8");
static_assert(offsetof(GetSynciv, values_shm_id) == 12,
              "offset of GetSynciv values_shm_id should be 12");
static_assert(offsetof(GetSynciv, values_shm_offset) == 16,
              "offset of GetSynciv values_shm_offset should be 16");

struct GetTexParameterfv {
  typedef GetTexParameterfv ValueType;
  static const CommandId kCmdId = kGetTexParameterfv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLfloat> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetTexParameterfv) == 20,
              "size of GetTexParameterfv should be 20");
static_assert(offsetof(GetTexParameterfv, header) == 0,
              "offset of GetTexParameterfv header should be 0");
static_assert(offsetof(GetTexParameterfv, target) == 4,
              "offset of GetTexParameterfv target should be 4");
static_assert(offsetof(GetTexParameterfv, pname) == 8,
              "offset of GetTexParameterfv pname should be 8");
static_assert(offsetof(GetTexParameterfv, params_shm_id) == 12,
              "offset of GetTexParameterfv params_shm_id should be 12");
static_assert(offsetof(GetTexParameterfv, params_shm_offset) == 16,
              "offset of GetTexParameterfv params_shm_offset should be 16");

struct GetTexParameteriv {
  typedef GetTexParameteriv ValueType;
  static const CommandId kCmdId = kGetTexParameteriv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    target = _target;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetTexParameteriv) == 20,
              "size of GetTexParameteriv should be 20");
static_assert(offsetof(GetTexParameteriv, header) == 0,
              "offset of GetTexParameteriv header should be 0");
static_assert(offsetof(GetTexParameteriv, target) == 4,
              "offset of GetTexParameteriv target should be 4");
static_assert(offsetof(GetTexParameteriv, pname) == 8,
              "offset of GetTexParameteriv pname should be 8");
static_assert(offsetof(GetTexParameteriv, params_shm_id) == 12,
              "offset of GetTexParameteriv params_shm_id should be 12");
static_assert(offsetof(GetTexParameteriv, params_shm_offset) == 16,
              "offset of GetTexParameteriv params_shm_offset should be 16");

struct GetTransformFeedbackVarying {
  typedef GetTransformFeedbackVarying ValueType;
  static const CommandId kCmdId = kGetTransformFeedbackVarying;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  struct Result {
    int32_t success;
    int32_t size;
    uint32_t type;
  };

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    program = _program;
    index = _index;
    name_bucket_id = _name_bucket_id;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLuint _index,
            uint32_t _name_bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _name_bucket_id,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t name_bucket_id;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetTransformFeedbackVarying) == 24,
              "size of GetTransformFeedbackVarying should be 24");
static_assert(offsetof(GetTransformFeedbackVarying, header) == 0,
              "offset of GetTransformFeedbackVarying header should be 0");
static_assert(offsetof(GetTransformFeedbackVarying, program) == 4,
              "offset of GetTransformFeedbackVarying program should be 4");
static_assert(offsetof(GetTransformFeedbackVarying, index) == 8,
              "offset of GetTransformFeedbackVarying index should be 8");
static_assert(
    offsetof(GetTransformFeedbackVarying, name_bucket_id) == 12,
    "offset of GetTransformFeedbackVarying name_bucket_id should be 12");
static_assert(
    offsetof(GetTransformFeedbackVarying, result_shm_id) == 16,
    "offset of GetTransformFeedbackVarying result_shm_id should be 16");
static_assert(
    offsetof(GetTransformFeedbackVarying, result_shm_offset) == 20,
    "offset of GetTransformFeedbackVarying result_shm_offset should be 20");
static_assert(offsetof(GetTransformFeedbackVarying::Result, success) == 0,
              "offset of GetTransformFeedbackVarying Result success should be "
              "0");
static_assert(offsetof(GetTransformFeedbackVarying::Result, size) == 4,
              "offset of GetTransformFeedbackVarying Result size should be "
              "4");
static_assert(offsetof(GetTransformFeedbackVarying::Result, type) == 8,
              "offset of GetTransformFeedbackVarying Result type should be "
              "8");

struct GetUniformBlockIndex {
  typedef GetUniformBlockIndex ValueType;
  static const CommandId kCmdId = kGetUniformBlockIndex;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLuint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _index_shm_id,
            uint32_t _index_shm_offset) {
    SetHeader();
    program = _program;
    name_bucket_id = _name_bucket_id;
    index_shm_id = _index_shm_id;
    index_shm_offset = _index_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _index_shm_id,
            uint32_t _index_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _name_bucket_id, _index_shm_id, _index_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t name_bucket_id;
  uint32_t index_shm_id;
  uint32_t index_shm_offset;
};

static_assert(sizeof(GetUniformBlockIndex) == 20,
              "size of GetUniformBlockIndex should be 20");
static_assert(offsetof(GetUniformBlockIndex, header) == 0,
              "offset of GetUniformBlockIndex header should be 0");
static_assert(offsetof(GetUniformBlockIndex, program) == 4,
              "offset of GetUniformBlockIndex program should be 4");
static_assert(offsetof(GetUniformBlockIndex, name_bucket_id) == 8,
              "offset of GetUniformBlockIndex name_bucket_id should be 8");
static_assert(offsetof(GetUniformBlockIndex, index_shm_id) == 12,
              "offset of GetUniformBlockIndex index_shm_id should be 12");
static_assert(offsetof(GetUniformBlockIndex, index_shm_offset) == 16,
              "offset of GetUniformBlockIndex index_shm_offset should be 16");

struct GetUniformfv {
  typedef GetUniformfv ValueType;
  static const CommandId kCmdId = kGetUniformfv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLfloat> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLint _location,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    program = _program;
    location = _location;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLint _location,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _location, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  int32_t location;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetUniformfv) == 20, "size of GetUniformfv should be 20");
static_assert(offsetof(GetUniformfv, header) == 0,
              "offset of GetUniformfv header should be 0");
static_assert(offsetof(GetUniformfv, program) == 4,
              "offset of GetUniformfv program should be 4");
static_assert(offsetof(GetUniformfv, location) == 8,
              "offset of GetUniformfv location should be 8");
static_assert(offsetof(GetUniformfv, params_shm_id) == 12,
              "offset of GetUniformfv params_shm_id should be 12");
static_assert(offsetof(GetUniformfv, params_shm_offset) == 16,
              "offset of GetUniformfv params_shm_offset should be 16");

struct GetUniformiv {
  typedef GetUniformiv ValueType;
  static const CommandId kCmdId = kGetUniformiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            GLint _location,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    program = _program;
    location = _location;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLint _location,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _location, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  int32_t location;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetUniformiv) == 20, "size of GetUniformiv should be 20");
static_assert(offsetof(GetUniformiv, header) == 0,
              "offset of GetUniformiv header should be 0");
static_assert(offsetof(GetUniformiv, program) == 4,
              "offset of GetUniformiv program should be 4");
static_assert(offsetof(GetUniformiv, location) == 8,
              "offset of GetUniformiv location should be 8");
static_assert(offsetof(GetUniformiv, params_shm_id) == 12,
              "offset of GetUniformiv params_shm_id should be 12");
static_assert(offsetof(GetUniformiv, params_shm_offset) == 16,
              "offset of GetUniformiv params_shm_offset should be 16");

struct GetUniformIndices {
  typedef GetUniformIndices ValueType;
  static const CommandId kCmdId = kGetUniformIndices;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLuint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _names_bucket_id,
            uint32_t _indices_shm_id,
            uint32_t _indices_shm_offset) {
    SetHeader();
    program = _program;
    names_bucket_id = _names_bucket_id;
    indices_shm_id = _indices_shm_id;
    indices_shm_offset = _indices_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _names_bucket_id,
            uint32_t _indices_shm_id,
            uint32_t _indices_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _names_bucket_id,
                                       _indices_shm_id, _indices_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t names_bucket_id;
  uint32_t indices_shm_id;
  uint32_t indices_shm_offset;
};

static_assert(sizeof(GetUniformIndices) == 20,
              "size of GetUniformIndices should be 20");
static_assert(offsetof(GetUniformIndices, header) == 0,
              "offset of GetUniformIndices header should be 0");
static_assert(offsetof(GetUniformIndices, program) == 4,
              "offset of GetUniformIndices program should be 4");
static_assert(offsetof(GetUniformIndices, names_bucket_id) == 8,
              "offset of GetUniformIndices names_bucket_id should be 8");
static_assert(offsetof(GetUniformIndices, indices_shm_id) == 12,
              "offset of GetUniformIndices indices_shm_id should be 12");
static_assert(offsetof(GetUniformIndices, indices_shm_offset) == 16,
              "offset of GetUniformIndices indices_shm_offset should be 16");

struct GetUniformLocation {
  typedef GetUniformLocation ValueType;
  static const CommandId kCmdId = kGetUniformLocation;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    SetHeader();
    program = _program;
    name_bucket_id = _name_bucket_id;
    location_shm_id = _location_shm_id;
    location_shm_offset = _location_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _name_bucket_id,
            uint32_t _location_shm_id,
            uint32_t _location_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_program, _name_bucket_id,
                                       _location_shm_id, _location_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t name_bucket_id;
  uint32_t location_shm_id;
  uint32_t location_shm_offset;
};

static_assert(sizeof(GetUniformLocation) == 20,
              "size of GetUniformLocation should be 20");
static_assert(offsetof(GetUniformLocation, header) == 0,
              "offset of GetUniformLocation header should be 0");
static_assert(offsetof(GetUniformLocation, program) == 4,
              "offset of GetUniformLocation program should be 4");
static_assert(offsetof(GetUniformLocation, name_bucket_id) == 8,
              "offset of GetUniformLocation name_bucket_id should be 8");
static_assert(offsetof(GetUniformLocation, location_shm_id) == 12,
              "offset of GetUniformLocation location_shm_id should be 12");
static_assert(offsetof(GetUniformLocation, location_shm_offset) == 16,
              "offset of GetUniformLocation location_shm_offset should be 16");

struct GetVertexAttribfv {
  typedef GetVertexAttribfv ValueType;
  static const CommandId kCmdId = kGetVertexAttribfv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLfloat> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    index = _index;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_index, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetVertexAttribfv) == 20,
              "size of GetVertexAttribfv should be 20");
static_assert(offsetof(GetVertexAttribfv, header) == 0,
              "offset of GetVertexAttribfv header should be 0");
static_assert(offsetof(GetVertexAttribfv, index) == 4,
              "offset of GetVertexAttribfv index should be 4");
static_assert(offsetof(GetVertexAttribfv, pname) == 8,
              "offset of GetVertexAttribfv pname should be 8");
static_assert(offsetof(GetVertexAttribfv, params_shm_id) == 12,
              "offset of GetVertexAttribfv params_shm_id should be 12");
static_assert(offsetof(GetVertexAttribfv, params_shm_offset) == 16,
              "offset of GetVertexAttribfv params_shm_offset should be 16");

struct GetVertexAttribiv {
  typedef GetVertexAttribiv ValueType;
  static const CommandId kCmdId = kGetVertexAttribiv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    SetHeader();
    index = _index;
    pname = _pname;
    params_shm_id = _params_shm_id;
    params_shm_offset = _params_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _index,
            GLenum _pname,
            uint32_t _params_shm_id,
            uint32_t _params_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_index, _pname, _params_shm_id, _params_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
  uint32_t pname;
  uint32_t params_shm_id;
  uint32_t params_shm_offset;
};

static_assert(sizeof(GetVertexAttribiv) == 20,
              "size of GetVertexAttribiv should be 20");
static_assert(offsetof(GetVertexAttribiv, header) == 0,
              "offset of GetVertexAttribiv header should be 0");
static_assert(offsetof(GetVertexAttribiv, index) == 4,
              "offset of GetVertexAttribiv index should be 4");
static_assert(offsetof(GetVertexAttribiv, pname) == 8,
              "offset of GetVertexAttribiv pname should be 8");
static_assert(offsetof(GetVertexAttribiv, params_shm_id) == 12,
              "offset of GetVertexAttribiv params_shm_id should be 12");
static_assert(offsetof(GetVertexAttribiv, params_shm_offset) == 16,
              "offset of GetVertexAttribiv params_shm_offset should be 16");

struct GetVertexAttribPointerv {
  typedef GetVertexAttribPointerv ValueType;
  static const CommandId kCmdId = kGetVertexAttribPointerv;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef SizedResult<GLuint> Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index,
            GLenum _pname,
            uint32_t _pointer_shm_id,
            uint32_t _pointer_shm_offset) {
    SetHeader();
    index = _index;
    pname = _pname;
    pointer_shm_id = _pointer_shm_id;
    pointer_shm_offset = _pointer_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _index,
            GLenum _pname,
            uint32_t _pointer_shm_id,
            uint32_t _pointer_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_index, _pname, _pointer_shm_id, _pointer_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
  uint32_t pname;
  uint32_t pointer_shm_id;
  uint32_t pointer_shm_offset;
};

static_assert(sizeof(GetVertexAttribPointerv) == 20,
              "size of GetVertexAttribPointerv should be 20");
static_assert(offsetof(GetVertexAttribPointerv, header) == 0,
              "offset of GetVertexAttribPointerv header should be 0");
static_assert(offsetof(GetVertexAttribPointerv, index) == 4,
              "offset of GetVertexAttribPointerv index should be 4");
static_assert(offsetof(GetVertexAttribPointerv, pname) == 8,
              "offset of GetVertexAttribPointerv pname should be 8");
static_assert(offsetof(GetVertexAttribPointerv, pointer_shm_id) == 12,
              "offset of GetVertexAttribPointerv pointer_shm_id should be 12");
static_assert(
    offsetof(GetVertexAttribPointerv, pointer_shm_offset) == 16,
    "offset of GetVertexAttribPointerv pointer_shm_offset should be 16");

struct Hint {
  typedef Hint ValueType;
  static const CommandId kCmdId = kHint;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLenum _mode) {
    SetHeader();
    target = _target;
    mode = _mode;
  }

  void* Set(void* cmd, GLenum _target, GLenum _mode) {
    static_cast<ValueType*>(cmd)->Init(_target, _mode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t mode;
};

static_assert(sizeof(Hint) == 12, "size of Hint should be 12");
static_assert(offsetof(Hint, header) == 0, "offset of Hint header should be 0");
static_assert(offsetof(Hint, target) == 4, "offset of Hint target should be 4");
static_assert(offsetof(Hint, mode) == 8, "offset of Hint mode should be 8");

struct InvalidateFramebufferImmediate {
  typedef InvalidateFramebufferImmediate ValueType;
  static const CommandId kCmdId = kInvalidateFramebufferImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLenum) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLenum _target, GLsizei _count, const GLenum* _attachments) {
    SetHeader(_count);
    target = _target;
    count = _count;
    memcpy(ImmediateDataAddress(this), _attachments, ComputeDataSize(_count));
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _count,
            const GLenum* _attachments) {
    static_cast<ValueType*>(cmd)->Init(_target, _count, _attachments);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t count;
};

static_assert(sizeof(InvalidateFramebufferImmediate) == 12,
              "size of InvalidateFramebufferImmediate should be 12");
static_assert(offsetof(InvalidateFramebufferImmediate, header) == 0,
              "offset of InvalidateFramebufferImmediate header should be 0");
static_assert(offsetof(InvalidateFramebufferImmediate, target) == 4,
              "offset of InvalidateFramebufferImmediate target should be 4");
static_assert(offsetof(InvalidateFramebufferImmediate, count) == 8,
              "offset of InvalidateFramebufferImmediate count should be 8");

struct InvalidateSubFramebufferImmediate {
  typedef InvalidateSubFramebufferImmediate ValueType;
  static const CommandId kCmdId = kInvalidateSubFramebufferImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLenum) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLenum _target,
            GLsizei _count,
            const GLenum* _attachments,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    SetHeader(_count);
    target = _target;
    count = _count;
    x = _x;
    y = _y;
    width = _width;
    height = _height;
    memcpy(ImmediateDataAddress(this), _attachments, ComputeDataSize(_count));
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _count,
            const GLenum* _attachments,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _count, _attachments, _x, _y, _width, _height);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t count;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(InvalidateSubFramebufferImmediate) == 28,
              "size of InvalidateSubFramebufferImmediate should be 28");
static_assert(offsetof(InvalidateSubFramebufferImmediate, header) == 0,
              "offset of InvalidateSubFramebufferImmediate header should be 0");
static_assert(offsetof(InvalidateSubFramebufferImmediate, target) == 4,
              "offset of InvalidateSubFramebufferImmediate target should be 4");
static_assert(offsetof(InvalidateSubFramebufferImmediate, count) == 8,
              "offset of InvalidateSubFramebufferImmediate count should be 8");
static_assert(offsetof(InvalidateSubFramebufferImmediate, x) == 12,
              "offset of InvalidateSubFramebufferImmediate x should be 12");
static_assert(offsetof(InvalidateSubFramebufferImmediate, y) == 16,
              "offset of InvalidateSubFramebufferImmediate y should be 16");
static_assert(offsetof(InvalidateSubFramebufferImmediate, width) == 20,
              "offset of InvalidateSubFramebufferImmediate width should be 20");
static_assert(
    offsetof(InvalidateSubFramebufferImmediate, height) == 24,
    "offset of InvalidateSubFramebufferImmediate height should be 24");

struct IsBuffer {
  typedef IsBuffer ValueType;
  static const CommandId kCmdId = kIsBuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _buffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    buffer = _buffer;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _buffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_buffer, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t buffer;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsBuffer) == 16, "size of IsBuffer should be 16");
static_assert(offsetof(IsBuffer, header) == 0,
              "offset of IsBuffer header should be 0");
static_assert(offsetof(IsBuffer, buffer) == 4,
              "offset of IsBuffer buffer should be 4");
static_assert(offsetof(IsBuffer, result_shm_id) == 8,
              "offset of IsBuffer result_shm_id should be 8");
static_assert(offsetof(IsBuffer, result_shm_offset) == 12,
              "offset of IsBuffer result_shm_offset should be 12");

struct IsEnabled {
  typedef IsEnabled ValueType;
  static const CommandId kCmdId = kIsEnabled;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _cap, uint32_t _result_shm_id, uint32_t _result_shm_offset) {
    SetHeader();
    cap = _cap;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _cap,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_cap, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t cap;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsEnabled) == 16, "size of IsEnabled should be 16");
static_assert(offsetof(IsEnabled, header) == 0,
              "offset of IsEnabled header should be 0");
static_assert(offsetof(IsEnabled, cap) == 4,
              "offset of IsEnabled cap should be 4");
static_assert(offsetof(IsEnabled, result_shm_id) == 8,
              "offset of IsEnabled result_shm_id should be 8");
static_assert(offsetof(IsEnabled, result_shm_offset) == 12,
              "offset of IsEnabled result_shm_offset should be 12");

struct IsFramebuffer {
  typedef IsFramebuffer ValueType;
  static const CommandId kCmdId = kIsFramebuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _framebuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    framebuffer = _framebuffer;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _framebuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_framebuffer, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t framebuffer;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsFramebuffer) == 16,
              "size of IsFramebuffer should be 16");
static_assert(offsetof(IsFramebuffer, header) == 0,
              "offset of IsFramebuffer header should be 0");
static_assert(offsetof(IsFramebuffer, framebuffer) == 4,
              "offset of IsFramebuffer framebuffer should be 4");
static_assert(offsetof(IsFramebuffer, result_shm_id) == 8,
              "offset of IsFramebuffer result_shm_id should be 8");
static_assert(offsetof(IsFramebuffer, result_shm_offset) == 12,
              "offset of IsFramebuffer result_shm_offset should be 12");

struct IsProgram {
  typedef IsProgram ValueType;
  static const CommandId kCmdId = kIsProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    program = _program;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsProgram) == 16, "size of IsProgram should be 16");
static_assert(offsetof(IsProgram, header) == 0,
              "offset of IsProgram header should be 0");
static_assert(offsetof(IsProgram, program) == 4,
              "offset of IsProgram program should be 4");
static_assert(offsetof(IsProgram, result_shm_id) == 8,
              "offset of IsProgram result_shm_id should be 8");
static_assert(offsetof(IsProgram, result_shm_offset) == 12,
              "offset of IsProgram result_shm_offset should be 12");

struct IsRenderbuffer {
  typedef IsRenderbuffer ValueType;
  static const CommandId kCmdId = kIsRenderbuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _renderbuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    renderbuffer = _renderbuffer;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _renderbuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_renderbuffer, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t renderbuffer;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsRenderbuffer) == 16,
              "size of IsRenderbuffer should be 16");
static_assert(offsetof(IsRenderbuffer, header) == 0,
              "offset of IsRenderbuffer header should be 0");
static_assert(offsetof(IsRenderbuffer, renderbuffer) == 4,
              "offset of IsRenderbuffer renderbuffer should be 4");
static_assert(offsetof(IsRenderbuffer, result_shm_id) == 8,
              "offset of IsRenderbuffer result_shm_id should be 8");
static_assert(offsetof(IsRenderbuffer, result_shm_offset) == 12,
              "offset of IsRenderbuffer result_shm_offset should be 12");

struct IsSampler {
  typedef IsSampler ValueType;
  static const CommandId kCmdId = kIsSampler;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sampler,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    sampler = _sampler;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sampler,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_sampler, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsSampler) == 16, "size of IsSampler should be 16");
static_assert(offsetof(IsSampler, header) == 0,
              "offset of IsSampler header should be 0");
static_assert(offsetof(IsSampler, sampler) == 4,
              "offset of IsSampler sampler should be 4");
static_assert(offsetof(IsSampler, result_shm_id) == 8,
              "offset of IsSampler result_shm_id should be 8");
static_assert(offsetof(IsSampler, result_shm_offset) == 12,
              "offset of IsSampler result_shm_offset should be 12");

struct IsShader {
  typedef IsShader ValueType;
  static const CommandId kCmdId = kIsShader;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    shader = _shader;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _shader,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_shader, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsShader) == 16, "size of IsShader should be 16");
static_assert(offsetof(IsShader, header) == 0,
              "offset of IsShader header should be 0");
static_assert(offsetof(IsShader, shader) == 4,
              "offset of IsShader shader should be 4");
static_assert(offsetof(IsShader, result_shm_id) == 8,
              "offset of IsShader result_shm_id should be 8");
static_assert(offsetof(IsShader, result_shm_offset) == 12,
              "offset of IsShader result_shm_offset should be 12");

struct IsSync {
  typedef IsSync ValueType;
  static const CommandId kCmdId = kIsSync;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    sync = _sync;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _sync,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_sync, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsSync) == 16, "size of IsSync should be 16");
static_assert(offsetof(IsSync, header) == 0,
              "offset of IsSync header should be 0");
static_assert(offsetof(IsSync, sync) == 4, "offset of IsSync sync should be 4");
static_assert(offsetof(IsSync, result_shm_id) == 8,
              "offset of IsSync result_shm_id should be 8");
static_assert(offsetof(IsSync, result_shm_offset) == 12,
              "offset of IsSync result_shm_offset should be 12");

struct IsTexture {
  typedef IsTexture ValueType;
  static const CommandId kCmdId = kIsTexture;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _texture,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    texture = _texture;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _texture,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_texture, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t texture;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsTexture) == 16, "size of IsTexture should be 16");
static_assert(offsetof(IsTexture, header) == 0,
              "offset of IsTexture header should be 0");
static_assert(offsetof(IsTexture, texture) == 4,
              "offset of IsTexture texture should be 4");
static_assert(offsetof(IsTexture, result_shm_id) == 8,
              "offset of IsTexture result_shm_id should be 8");
static_assert(offsetof(IsTexture, result_shm_offset) == 12,
              "offset of IsTexture result_shm_offset should be 12");

struct IsTransformFeedback {
  typedef IsTransformFeedback ValueType;
  static const CommandId kCmdId = kIsTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _transformfeedback,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    transformfeedback = _transformfeedback;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _transformfeedback,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_transformfeedback, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t transformfeedback;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsTransformFeedback) == 16,
              "size of IsTransformFeedback should be 16");
static_assert(offsetof(IsTransformFeedback, header) == 0,
              "offset of IsTransformFeedback header should be 0");
static_assert(offsetof(IsTransformFeedback, transformfeedback) == 4,
              "offset of IsTransformFeedback transformfeedback should be 4");
static_assert(offsetof(IsTransformFeedback, result_shm_id) == 8,
              "offset of IsTransformFeedback result_shm_id should be 8");
static_assert(offsetof(IsTransformFeedback, result_shm_offset) == 12,
              "offset of IsTransformFeedback result_shm_offset should be 12");

struct LineWidth {
  typedef LineWidth ValueType;
  static const CommandId kCmdId = kLineWidth;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLfloat _width) {
    SetHeader();
    width = _width;
  }

  void* Set(void* cmd, GLfloat _width) {
    static_cast<ValueType*>(cmd)->Init(_width);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float width;
};

static_assert(sizeof(LineWidth) == 8, "size of LineWidth should be 8");
static_assert(offsetof(LineWidth, header) == 0,
              "offset of LineWidth header should be 0");
static_assert(offsetof(LineWidth, width) == 4,
              "offset of LineWidth width should be 4");

struct LinkProgram {
  typedef LinkProgram ValueType;
  static const CommandId kCmdId = kLinkProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program) {
    SetHeader();
    program = _program;
  }

  void* Set(void* cmd, GLuint _program) {
    static_cast<ValueType*>(cmd)->Init(_program);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
};

static_assert(sizeof(LinkProgram) == 8, "size of LinkProgram should be 8");
static_assert(offsetof(LinkProgram, header) == 0,
              "offset of LinkProgram header should be 0");
static_assert(offsetof(LinkProgram, program) == 4,
              "offset of LinkProgram program should be 4");

struct PauseTransformFeedback {
  typedef PauseTransformFeedback ValueType;
  static const CommandId kCmdId = kPauseTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(PauseTransformFeedback) == 4,
              "size of PauseTransformFeedback should be 4");
static_assert(offsetof(PauseTransformFeedback, header) == 0,
              "offset of PauseTransformFeedback header should be 0");

struct PixelStorei {
  typedef PixelStorei ValueType;
  static const CommandId kCmdId = kPixelStorei;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _pname, GLint _param) {
    SetHeader();
    pname = _pname;
    param = _param;
  }

  void* Set(void* cmd, GLenum _pname, GLint _param) {
    static_cast<ValueType*>(cmd)->Init(_pname, _param);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t pname;
  int32_t param;
};

static_assert(sizeof(PixelStorei) == 12, "size of PixelStorei should be 12");
static_assert(offsetof(PixelStorei, header) == 0,
              "offset of PixelStorei header should be 0");
static_assert(offsetof(PixelStorei, pname) == 4,
              "offset of PixelStorei pname should be 4");
static_assert(offsetof(PixelStorei, param) == 8,
              "offset of PixelStorei param should be 8");

struct PolygonOffset {
  typedef PolygonOffset ValueType;
  static const CommandId kCmdId = kPolygonOffset;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLfloat _factor, GLfloat _units) {
    SetHeader();
    factor = _factor;
    units = _units;
  }

  void* Set(void* cmd, GLfloat _factor, GLfloat _units) {
    static_cast<ValueType*>(cmd)->Init(_factor, _units);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float factor;
  float units;
};

static_assert(sizeof(PolygonOffset) == 12,
              "size of PolygonOffset should be 12");
static_assert(offsetof(PolygonOffset, header) == 0,
              "offset of PolygonOffset header should be 0");
static_assert(offsetof(PolygonOffset, factor) == 4,
              "offset of PolygonOffset factor should be 4");
static_assert(offsetof(PolygonOffset, units) == 8,
              "offset of PolygonOffset units should be 8");

struct ReadBuffer {
  typedef ReadBuffer ValueType;
  static const CommandId kCmdId = kReadBuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _src) {
    SetHeader();
    src = _src;
  }

  void* Set(void* cmd, GLenum _src) {
    static_cast<ValueType*>(cmd)->Init(_src);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t src;
};

static_assert(sizeof(ReadBuffer) == 8, "size of ReadBuffer should be 8");
static_assert(offsetof(ReadBuffer, header) == 0,
              "offset of ReadBuffer header should be 0");
static_assert(offsetof(ReadBuffer, src) == 4,
              "offset of ReadBuffer src should be 4");

// ReadPixels has the result separated from the pixel buffer so that
// it is easier to specify the result going to some specific place
// that exactly fits the rectangle of pixels.
struct ReadPixels {
  typedef ReadPixels ValueType;
  static const CommandId kCmdId = kReadPixels;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset,
            GLboolean _async) {
    SetHeader();
    x = _x;
    y = _y;
    width = _width;
    height = _height;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
    async = _async;
  }

  void* Set(void* cmd,
            GLint _x,
            GLint _y,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset,
            GLboolean _async) {
    static_cast<ValueType*>(cmd)
        ->Init(_x, _y, _width, _height, _format, _type, _pixels_shm_id,
               _pixels_shm_offset, _result_shm_id, _result_shm_offset, _async);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
  uint32_t async;
};

static_assert(sizeof(ReadPixels) == 48, "size of ReadPixels should be 48");
static_assert(offsetof(ReadPixels, header) == 0,
              "offset of ReadPixels header should be 0");
static_assert(offsetof(ReadPixels, x) == 4,
              "offset of ReadPixels x should be 4");
static_assert(offsetof(ReadPixels, y) == 8,
              "offset of ReadPixels y should be 8");
static_assert(offsetof(ReadPixels, width) == 12,
              "offset of ReadPixels width should be 12");
static_assert(offsetof(ReadPixels, height) == 16,
              "offset of ReadPixels height should be 16");
static_assert(offsetof(ReadPixels, format) == 20,
              "offset of ReadPixels format should be 20");
static_assert(offsetof(ReadPixels, type) == 24,
              "offset of ReadPixels type should be 24");
static_assert(offsetof(ReadPixels, pixels_shm_id) == 28,
              "offset of ReadPixels pixels_shm_id should be 28");
static_assert(offsetof(ReadPixels, pixels_shm_offset) == 32,
              "offset of ReadPixels pixels_shm_offset should be 32");
static_assert(offsetof(ReadPixels, result_shm_id) == 36,
              "offset of ReadPixels result_shm_id should be 36");
static_assert(offsetof(ReadPixels, result_shm_offset) == 40,
              "offset of ReadPixels result_shm_offset should be 40");
static_assert(offsetof(ReadPixels, async) == 44,
              "offset of ReadPixels async should be 44");

struct ReleaseShaderCompiler {
  typedef ReleaseShaderCompiler ValueType;
  static const CommandId kCmdId = kReleaseShaderCompiler;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(ReleaseShaderCompiler) == 4,
              "size of ReleaseShaderCompiler should be 4");
static_assert(offsetof(ReleaseShaderCompiler, header) == 0,
              "offset of ReleaseShaderCompiler header should be 0");

struct RenderbufferStorage {
  typedef RenderbufferStorage ValueType;
  static const CommandId kCmdId = kRenderbufferStorage;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    internalformat = _internalformat;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _internalformat, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t internalformat;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(RenderbufferStorage) == 20,
              "size of RenderbufferStorage should be 20");
static_assert(offsetof(RenderbufferStorage, header) == 0,
              "offset of RenderbufferStorage header should be 0");
static_assert(offsetof(RenderbufferStorage, target) == 4,
              "offset of RenderbufferStorage target should be 4");
static_assert(offsetof(RenderbufferStorage, internalformat) == 8,
              "offset of RenderbufferStorage internalformat should be 8");
static_assert(offsetof(RenderbufferStorage, width) == 12,
              "offset of RenderbufferStorage width should be 12");
static_assert(offsetof(RenderbufferStorage, height) == 16,
              "offset of RenderbufferStorage height should be 16");

struct ResumeTransformFeedback {
  typedef ResumeTransformFeedback ValueType;
  static const CommandId kCmdId = kResumeTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(ResumeTransformFeedback) == 4,
              "size of ResumeTransformFeedback should be 4");
static_assert(offsetof(ResumeTransformFeedback, header) == 0,
              "offset of ResumeTransformFeedback header should be 0");

struct SampleCoverage {
  typedef SampleCoverage ValueType;
  static const CommandId kCmdId = kSampleCoverage;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLclampf _value, GLboolean _invert) {
    SetHeader();
    value = _value;
    invert = _invert;
  }

  void* Set(void* cmd, GLclampf _value, GLboolean _invert) {
    static_cast<ValueType*>(cmd)->Init(_value, _invert);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  float value;
  uint32_t invert;
};

static_assert(sizeof(SampleCoverage) == 12,
              "size of SampleCoverage should be 12");
static_assert(offsetof(SampleCoverage, header) == 0,
              "offset of SampleCoverage header should be 0");
static_assert(offsetof(SampleCoverage, value) == 4,
              "offset of SampleCoverage value should be 4");
static_assert(offsetof(SampleCoverage, invert) == 8,
              "offset of SampleCoverage invert should be 8");

struct SamplerParameterf {
  typedef SamplerParameterf ValueType;
  static const CommandId kCmdId = kSamplerParameterf;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sampler, GLenum _pname, GLfloat _param) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    param = _param;
  }

  void* Set(void* cmd, GLuint _sampler, GLenum _pname, GLfloat _param) {
    static_cast<ValueType*>(cmd)->Init(_sampler, _pname, _param);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
  float param;
};

static_assert(sizeof(SamplerParameterf) == 16,
              "size of SamplerParameterf should be 16");
static_assert(offsetof(SamplerParameterf, header) == 0,
              "offset of SamplerParameterf header should be 0");
static_assert(offsetof(SamplerParameterf, sampler) == 4,
              "offset of SamplerParameterf sampler should be 4");
static_assert(offsetof(SamplerParameterf, pname) == 8,
              "offset of SamplerParameterf pname should be 8");
static_assert(offsetof(SamplerParameterf, param) == 12,
              "offset of SamplerParameterf param should be 12");

struct SamplerParameterfvImmediate {
  typedef SamplerParameterfvImmediate ValueType;
  static const CommandId kCmdId = kSamplerParameterfvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 1);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _sampler, GLenum _pname, const GLfloat* _params) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    memcpy(ImmediateDataAddress(this), _params, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _sampler, GLenum _pname, const GLfloat* _params) {
    static_cast<ValueType*>(cmd)->Init(_sampler, _pname, _params);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
};

static_assert(sizeof(SamplerParameterfvImmediate) == 12,
              "size of SamplerParameterfvImmediate should be 12");
static_assert(offsetof(SamplerParameterfvImmediate, header) == 0,
              "offset of SamplerParameterfvImmediate header should be 0");
static_assert(offsetof(SamplerParameterfvImmediate, sampler) == 4,
              "offset of SamplerParameterfvImmediate sampler should be 4");
static_assert(offsetof(SamplerParameterfvImmediate, pname) == 8,
              "offset of SamplerParameterfvImmediate pname should be 8");

struct SamplerParameteri {
  typedef SamplerParameteri ValueType;
  static const CommandId kCmdId = kSamplerParameteri;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sampler, GLenum _pname, GLint _param) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    param = _param;
  }

  void* Set(void* cmd, GLuint _sampler, GLenum _pname, GLint _param) {
    static_cast<ValueType*>(cmd)->Init(_sampler, _pname, _param);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
  int32_t param;
};

static_assert(sizeof(SamplerParameteri) == 16,
              "size of SamplerParameteri should be 16");
static_assert(offsetof(SamplerParameteri, header) == 0,
              "offset of SamplerParameteri header should be 0");
static_assert(offsetof(SamplerParameteri, sampler) == 4,
              "offset of SamplerParameteri sampler should be 4");
static_assert(offsetof(SamplerParameteri, pname) == 8,
              "offset of SamplerParameteri pname should be 8");
static_assert(offsetof(SamplerParameteri, param) == 12,
              "offset of SamplerParameteri param should be 12");

struct SamplerParameterivImmediate {
  typedef SamplerParameterivImmediate ValueType;
  static const CommandId kCmdId = kSamplerParameterivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLint) * 1);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _sampler, GLenum _pname, const GLint* _params) {
    SetHeader();
    sampler = _sampler;
    pname = _pname;
    memcpy(ImmediateDataAddress(this), _params, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _sampler, GLenum _pname, const GLint* _params) {
    static_cast<ValueType*>(cmd)->Init(_sampler, _pname, _params);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t sampler;
  uint32_t pname;
};

static_assert(sizeof(SamplerParameterivImmediate) == 12,
              "size of SamplerParameterivImmediate should be 12");
static_assert(offsetof(SamplerParameterivImmediate, header) == 0,
              "offset of SamplerParameterivImmediate header should be 0");
static_assert(offsetof(SamplerParameterivImmediate, sampler) == 4,
              "offset of SamplerParameterivImmediate sampler should be 4");
static_assert(offsetof(SamplerParameterivImmediate, pname) == 8,
              "offset of SamplerParameterivImmediate pname should be 8");

struct Scissor {
  typedef Scissor ValueType;
  static const CommandId kCmdId = kScissor;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _x, GLint _y, GLsizei _width, GLsizei _height) {
    SetHeader();
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd, GLint _x, GLint _y, GLsizei _width, GLsizei _height) {
    static_cast<ValueType*>(cmd)->Init(_x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(Scissor) == 20, "size of Scissor should be 20");
static_assert(offsetof(Scissor, header) == 0,
              "offset of Scissor header should be 0");
static_assert(offsetof(Scissor, x) == 4, "offset of Scissor x should be 4");
static_assert(offsetof(Scissor, y) == 8, "offset of Scissor y should be 8");
static_assert(offsetof(Scissor, width) == 12,
              "offset of Scissor width should be 12");
static_assert(offsetof(Scissor, height) == 16,
              "offset of Scissor height should be 16");

struct ShaderBinary {
  typedef ShaderBinary ValueType;
  static const CommandId kCmdId = kShaderBinary;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLsizei _n,
            uint32_t _shaders_shm_id,
            uint32_t _shaders_shm_offset,
            GLenum _binaryformat,
            uint32_t _binary_shm_id,
            uint32_t _binary_shm_offset,
            GLsizei _length) {
    SetHeader();
    n = _n;
    shaders_shm_id = _shaders_shm_id;
    shaders_shm_offset = _shaders_shm_offset;
    binaryformat = _binaryformat;
    binary_shm_id = _binary_shm_id;
    binary_shm_offset = _binary_shm_offset;
    length = _length;
  }

  void* Set(void* cmd,
            GLsizei _n,
            uint32_t _shaders_shm_id,
            uint32_t _shaders_shm_offset,
            GLenum _binaryformat,
            uint32_t _binary_shm_id,
            uint32_t _binary_shm_offset,
            GLsizei _length) {
    static_cast<ValueType*>(cmd)->Init(_n, _shaders_shm_id, _shaders_shm_offset,
                                       _binaryformat, _binary_shm_id,
                                       _binary_shm_offset, _length);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t n;
  uint32_t shaders_shm_id;
  uint32_t shaders_shm_offset;
  uint32_t binaryformat;
  uint32_t binary_shm_id;
  uint32_t binary_shm_offset;
  int32_t length;
};

static_assert(sizeof(ShaderBinary) == 32, "size of ShaderBinary should be 32");
static_assert(offsetof(ShaderBinary, header) == 0,
              "offset of ShaderBinary header should be 0");
static_assert(offsetof(ShaderBinary, n) == 4,
              "offset of ShaderBinary n should be 4");
static_assert(offsetof(ShaderBinary, shaders_shm_id) == 8,
              "offset of ShaderBinary shaders_shm_id should be 8");
static_assert(offsetof(ShaderBinary, shaders_shm_offset) == 12,
              "offset of ShaderBinary shaders_shm_offset should be 12");
static_assert(offsetof(ShaderBinary, binaryformat) == 16,
              "offset of ShaderBinary binaryformat should be 16");
static_assert(offsetof(ShaderBinary, binary_shm_id) == 20,
              "offset of ShaderBinary binary_shm_id should be 20");
static_assert(offsetof(ShaderBinary, binary_shm_offset) == 24,
              "offset of ShaderBinary binary_shm_offset should be 24");
static_assert(offsetof(ShaderBinary, length) == 28,
              "offset of ShaderBinary length should be 28");

struct ShaderSourceBucket {
  typedef ShaderSourceBucket ValueType;
  static const CommandId kCmdId = kShaderSourceBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader, uint32_t _str_bucket_id) {
    SetHeader();
    shader = _shader;
    str_bucket_id = _str_bucket_id;
  }

  void* Set(void* cmd, GLuint _shader, uint32_t _str_bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_shader, _str_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t str_bucket_id;
};

static_assert(sizeof(ShaderSourceBucket) == 12,
              "size of ShaderSourceBucket should be 12");
static_assert(offsetof(ShaderSourceBucket, header) == 0,
              "offset of ShaderSourceBucket header should be 0");
static_assert(offsetof(ShaderSourceBucket, shader) == 4,
              "offset of ShaderSourceBucket shader should be 4");
static_assert(offsetof(ShaderSourceBucket, str_bucket_id) == 8,
              "offset of ShaderSourceBucket str_bucket_id should be 8");

struct StencilFunc {
  typedef StencilFunc ValueType;
  static const CommandId kCmdId = kStencilFunc;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _func, GLint _ref, GLuint _mask) {
    SetHeader();
    func = _func;
    ref = _ref;
    mask = _mask;
  }

  void* Set(void* cmd, GLenum _func, GLint _ref, GLuint _mask) {
    static_cast<ValueType*>(cmd)->Init(_func, _ref, _mask);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t func;
  int32_t ref;
  uint32_t mask;
};

static_assert(sizeof(StencilFunc) == 16, "size of StencilFunc should be 16");
static_assert(offsetof(StencilFunc, header) == 0,
              "offset of StencilFunc header should be 0");
static_assert(offsetof(StencilFunc, func) == 4,
              "offset of StencilFunc func should be 4");
static_assert(offsetof(StencilFunc, ref) == 8,
              "offset of StencilFunc ref should be 8");
static_assert(offsetof(StencilFunc, mask) == 12,
              "offset of StencilFunc mask should be 12");

struct StencilFuncSeparate {
  typedef StencilFuncSeparate ValueType;
  static const CommandId kCmdId = kStencilFuncSeparate;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _face, GLenum _func, GLint _ref, GLuint _mask) {
    SetHeader();
    face = _face;
    func = _func;
    ref = _ref;
    mask = _mask;
  }

  void* Set(void* cmd, GLenum _face, GLenum _func, GLint _ref, GLuint _mask) {
    static_cast<ValueType*>(cmd)->Init(_face, _func, _ref, _mask);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t face;
  uint32_t func;
  int32_t ref;
  uint32_t mask;
};

static_assert(sizeof(StencilFuncSeparate) == 20,
              "size of StencilFuncSeparate should be 20");
static_assert(offsetof(StencilFuncSeparate, header) == 0,
              "offset of StencilFuncSeparate header should be 0");
static_assert(offsetof(StencilFuncSeparate, face) == 4,
              "offset of StencilFuncSeparate face should be 4");
static_assert(offsetof(StencilFuncSeparate, func) == 8,
              "offset of StencilFuncSeparate func should be 8");
static_assert(offsetof(StencilFuncSeparate, ref) == 12,
              "offset of StencilFuncSeparate ref should be 12");
static_assert(offsetof(StencilFuncSeparate, mask) == 16,
              "offset of StencilFuncSeparate mask should be 16");

struct StencilMask {
  typedef StencilMask ValueType;
  static const CommandId kCmdId = kStencilMask;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _mask) {
    SetHeader();
    mask = _mask;
  }

  void* Set(void* cmd, GLuint _mask) {
    static_cast<ValueType*>(cmd)->Init(_mask);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mask;
};

static_assert(sizeof(StencilMask) == 8, "size of StencilMask should be 8");
static_assert(offsetof(StencilMask, header) == 0,
              "offset of StencilMask header should be 0");
static_assert(offsetof(StencilMask, mask) == 4,
              "offset of StencilMask mask should be 4");

struct StencilMaskSeparate {
  typedef StencilMaskSeparate ValueType;
  static const CommandId kCmdId = kStencilMaskSeparate;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _face, GLuint _mask) {
    SetHeader();
    face = _face;
    mask = _mask;
  }

  void* Set(void* cmd, GLenum _face, GLuint _mask) {
    static_cast<ValueType*>(cmd)->Init(_face, _mask);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t face;
  uint32_t mask;
};

static_assert(sizeof(StencilMaskSeparate) == 12,
              "size of StencilMaskSeparate should be 12");
static_assert(offsetof(StencilMaskSeparate, header) == 0,
              "offset of StencilMaskSeparate header should be 0");
static_assert(offsetof(StencilMaskSeparate, face) == 4,
              "offset of StencilMaskSeparate face should be 4");
static_assert(offsetof(StencilMaskSeparate, mask) == 8,
              "offset of StencilMaskSeparate mask should be 8");

struct StencilOp {
  typedef StencilOp ValueType;
  static const CommandId kCmdId = kStencilOp;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _fail, GLenum _zfail, GLenum _zpass) {
    SetHeader();
    fail = _fail;
    zfail = _zfail;
    zpass = _zpass;
  }

  void* Set(void* cmd, GLenum _fail, GLenum _zfail, GLenum _zpass) {
    static_cast<ValueType*>(cmd)->Init(_fail, _zfail, _zpass);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t fail;
  uint32_t zfail;
  uint32_t zpass;
};

static_assert(sizeof(StencilOp) == 16, "size of StencilOp should be 16");
static_assert(offsetof(StencilOp, header) == 0,
              "offset of StencilOp header should be 0");
static_assert(offsetof(StencilOp, fail) == 4,
              "offset of StencilOp fail should be 4");
static_assert(offsetof(StencilOp, zfail) == 8,
              "offset of StencilOp zfail should be 8");
static_assert(offsetof(StencilOp, zpass) == 12,
              "offset of StencilOp zpass should be 12");

struct StencilOpSeparate {
  typedef StencilOpSeparate ValueType;
  static const CommandId kCmdId = kStencilOpSeparate;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _face, GLenum _fail, GLenum _zfail, GLenum _zpass) {
    SetHeader();
    face = _face;
    fail = _fail;
    zfail = _zfail;
    zpass = _zpass;
  }

  void* Set(void* cmd,
            GLenum _face,
            GLenum _fail,
            GLenum _zfail,
            GLenum _zpass) {
    static_cast<ValueType*>(cmd)->Init(_face, _fail, _zfail, _zpass);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t face;
  uint32_t fail;
  uint32_t zfail;
  uint32_t zpass;
};

static_assert(sizeof(StencilOpSeparate) == 20,
              "size of StencilOpSeparate should be 20");
static_assert(offsetof(StencilOpSeparate, header) == 0,
              "offset of StencilOpSeparate header should be 0");
static_assert(offsetof(StencilOpSeparate, face) == 4,
              "offset of StencilOpSeparate face should be 4");
static_assert(offsetof(StencilOpSeparate, fail) == 8,
              "offset of StencilOpSeparate fail should be 8");
static_assert(offsetof(StencilOpSeparate, zfail) == 12,
              "offset of StencilOpSeparate zfail should be 12");
static_assert(offsetof(StencilOpSeparate, zpass) == 16,
              "offset of StencilOpSeparate zpass should be 16");

struct TexImage2D {
  typedef TexImage2D ValueType;
  static const CommandId kCmdId = kTexImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    width = _width;
    height = _height;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _internalformat, _width,
                                       _height, _format, _type, _pixels_shm_id,
                                       _pixels_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t internalformat;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  static const int32_t border = 0;
};

static_assert(sizeof(TexImage2D) == 40, "size of TexImage2D should be 40");
static_assert(offsetof(TexImage2D, header) == 0,
              "offset of TexImage2D header should be 0");
static_assert(offsetof(TexImage2D, target) == 4,
              "offset of TexImage2D target should be 4");
static_assert(offsetof(TexImage2D, level) == 8,
              "offset of TexImage2D level should be 8");
static_assert(offsetof(TexImage2D, internalformat) == 12,
              "offset of TexImage2D internalformat should be 12");
static_assert(offsetof(TexImage2D, width) == 16,
              "offset of TexImage2D width should be 16");
static_assert(offsetof(TexImage2D, height) == 20,
              "offset of TexImage2D height should be 20");
static_assert(offsetof(TexImage2D, format) == 24,
              "offset of TexImage2D format should be 24");
static_assert(offsetof(TexImage2D, type) == 28,
              "offset of TexImage2D type should be 28");
static_assert(offsetof(TexImage2D, pixels_shm_id) == 32,
              "offset of TexImage2D pixels_shm_id should be 32");
static_assert(offsetof(TexImage2D, pixels_shm_offset) == 36,
              "offset of TexImage2D pixels_shm_offset should be 36");

struct TexImage3D {
  typedef TexImage3D ValueType;
  static const CommandId kCmdId = kTexImage3D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    width = _width;
    height = _height;
    depth = _depth;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _level, _internalformat, _width,
                                       _height, _depth, _format, _type,
                                       _pixels_shm_id, _pixels_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t internalformat;
  int32_t width;
  int32_t height;
  int32_t depth;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  static const int32_t border = 0;
};

static_assert(sizeof(TexImage3D) == 44, "size of TexImage3D should be 44");
static_assert(offsetof(TexImage3D, header) == 0,
              "offset of TexImage3D header should be 0");
static_assert(offsetof(TexImage3D, target) == 4,
              "offset of TexImage3D target should be 4");
static_assert(offsetof(TexImage3D, level) == 8,
              "offset of TexImage3D level should be 8");
static_assert(offsetof(TexImage3D, internalformat) == 12,
              "offset of TexImage3D internalformat should be 12");
static_assert(offsetof(TexImage3D, width) == 16,
              "offset of TexImage3D width should be 16");
static_assert(offsetof(TexImage3D, height) == 20,
              "offset of TexImage3D height should be 20");
static_assert(offsetof(TexImage3D, depth) == 24,
              "offset of TexImage3D depth should be 24");
static_assert(offsetof(TexImage3D, format) == 28,
              "offset of TexImage3D format should be 28");
static_assert(offsetof(TexImage3D, type) == 32,
              "offset of TexImage3D type should be 32");
static_assert(offsetof(TexImage3D, pixels_shm_id) == 36,
              "offset of TexImage3D pixels_shm_id should be 36");
static_assert(offsetof(TexImage3D, pixels_shm_offset) == 40,
              "offset of TexImage3D pixels_shm_offset should be 40");

struct TexParameterf {
  typedef TexParameterf ValueType;
  static const CommandId kCmdId = kTexParameterf;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLenum _pname, GLfloat _param) {
    SetHeader();
    target = _target;
    pname = _pname;
    param = _param;
  }

  void* Set(void* cmd, GLenum _target, GLenum _pname, GLfloat _param) {
    static_cast<ValueType*>(cmd)->Init(_target, _pname, _param);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  float param;
};

static_assert(sizeof(TexParameterf) == 16,
              "size of TexParameterf should be 16");
static_assert(offsetof(TexParameterf, header) == 0,
              "offset of TexParameterf header should be 0");
static_assert(offsetof(TexParameterf, target) == 4,
              "offset of TexParameterf target should be 4");
static_assert(offsetof(TexParameterf, pname) == 8,
              "offset of TexParameterf pname should be 8");
static_assert(offsetof(TexParameterf, param) == 12,
              "offset of TexParameterf param should be 12");

struct TexParameterfvImmediate {
  typedef TexParameterfvImmediate ValueType;
  static const CommandId kCmdId = kTexParameterfvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 1);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _target, GLenum _pname, const GLfloat* _params) {
    SetHeader();
    target = _target;
    pname = _pname;
    memcpy(ImmediateDataAddress(this), _params, ComputeDataSize());
  }

  void* Set(void* cmd, GLenum _target, GLenum _pname, const GLfloat* _params) {
    static_cast<ValueType*>(cmd)->Init(_target, _pname, _params);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
};

static_assert(sizeof(TexParameterfvImmediate) == 12,
              "size of TexParameterfvImmediate should be 12");
static_assert(offsetof(TexParameterfvImmediate, header) == 0,
              "offset of TexParameterfvImmediate header should be 0");
static_assert(offsetof(TexParameterfvImmediate, target) == 4,
              "offset of TexParameterfvImmediate target should be 4");
static_assert(offsetof(TexParameterfvImmediate, pname) == 8,
              "offset of TexParameterfvImmediate pname should be 8");

struct TexParameteri {
  typedef TexParameteri ValueType;
  static const CommandId kCmdId = kTexParameteri;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLenum _pname, GLint _param) {
    SetHeader();
    target = _target;
    pname = _pname;
    param = _param;
  }

  void* Set(void* cmd, GLenum _target, GLenum _pname, GLint _param) {
    static_cast<ValueType*>(cmd)->Init(_target, _pname, _param);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
  int32_t param;
};

static_assert(sizeof(TexParameteri) == 16,
              "size of TexParameteri should be 16");
static_assert(offsetof(TexParameteri, header) == 0,
              "offset of TexParameteri header should be 0");
static_assert(offsetof(TexParameteri, target) == 4,
              "offset of TexParameteri target should be 4");
static_assert(offsetof(TexParameteri, pname) == 8,
              "offset of TexParameteri pname should be 8");
static_assert(offsetof(TexParameteri, param) == 12,
              "offset of TexParameteri param should be 12");

struct TexParameterivImmediate {
  typedef TexParameterivImmediate ValueType;
  static const CommandId kCmdId = kTexParameterivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLint) * 1);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _target, GLenum _pname, const GLint* _params) {
    SetHeader();
    target = _target;
    pname = _pname;
    memcpy(ImmediateDataAddress(this), _params, ComputeDataSize());
  }

  void* Set(void* cmd, GLenum _target, GLenum _pname, const GLint* _params) {
    static_cast<ValueType*>(cmd)->Init(_target, _pname, _params);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t pname;
};

static_assert(sizeof(TexParameterivImmediate) == 12,
              "size of TexParameterivImmediate should be 12");
static_assert(offsetof(TexParameterivImmediate, header) == 0,
              "offset of TexParameterivImmediate header should be 0");
static_assert(offsetof(TexParameterivImmediate, target) == 4,
              "offset of TexParameterivImmediate target should be 4");
static_assert(offsetof(TexParameterivImmediate, pname) == 8,
              "offset of TexParameterivImmediate pname should be 8");

struct TexStorage3D {
  typedef TexStorage3D ValueType;
  static const CommandId kCmdId = kTexStorage3D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizei _levels,
            GLenum _internalFormat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth) {
    SetHeader();
    target = _target;
    levels = _levels;
    internalFormat = _internalFormat;
    width = _width;
    height = _height;
    depth = _depth;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _levels,
            GLenum _internalFormat,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _levels, _internalFormat, _width, _height, _depth);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t levels;
  uint32_t internalFormat;
  int32_t width;
  int32_t height;
  int32_t depth;
};

static_assert(sizeof(TexStorage3D) == 28, "size of TexStorage3D should be 28");
static_assert(offsetof(TexStorage3D, header) == 0,
              "offset of TexStorage3D header should be 0");
static_assert(offsetof(TexStorage3D, target) == 4,
              "offset of TexStorage3D target should be 4");
static_assert(offsetof(TexStorage3D, levels) == 8,
              "offset of TexStorage3D levels should be 8");
static_assert(offsetof(TexStorage3D, internalFormat) == 12,
              "offset of TexStorage3D internalFormat should be 12");
static_assert(offsetof(TexStorage3D, width) == 16,
              "offset of TexStorage3D width should be 16");
static_assert(offsetof(TexStorage3D, height) == 20,
              "offset of TexStorage3D height should be 20");
static_assert(offsetof(TexStorage3D, depth) == 24,
              "offset of TexStorage3D depth should be 24");

struct TexSubImage2D {
  typedef TexSubImage2D ValueType;
  static const CommandId kCmdId = kTexSubImage2D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            GLboolean _internal) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    width = _width;
    height = _height;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
    internal = _internal;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            GLboolean _internal) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _xoffset, _yoffset, _width, _height, _format,
               _type, _pixels_shm_id, _pixels_shm_offset, _internal);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  uint32_t internal;
};

static_assert(sizeof(TexSubImage2D) == 48,
              "size of TexSubImage2D should be 48");
static_assert(offsetof(TexSubImage2D, header) == 0,
              "offset of TexSubImage2D header should be 0");
static_assert(offsetof(TexSubImage2D, target) == 4,
              "offset of TexSubImage2D target should be 4");
static_assert(offsetof(TexSubImage2D, level) == 8,
              "offset of TexSubImage2D level should be 8");
static_assert(offsetof(TexSubImage2D, xoffset) == 12,
              "offset of TexSubImage2D xoffset should be 12");
static_assert(offsetof(TexSubImage2D, yoffset) == 16,
              "offset of TexSubImage2D yoffset should be 16");
static_assert(offsetof(TexSubImage2D, width) == 20,
              "offset of TexSubImage2D width should be 20");
static_assert(offsetof(TexSubImage2D, height) == 24,
              "offset of TexSubImage2D height should be 24");
static_assert(offsetof(TexSubImage2D, format) == 28,
              "offset of TexSubImage2D format should be 28");
static_assert(offsetof(TexSubImage2D, type) == 32,
              "offset of TexSubImage2D type should be 32");
static_assert(offsetof(TexSubImage2D, pixels_shm_id) == 36,
              "offset of TexSubImage2D pixels_shm_id should be 36");
static_assert(offsetof(TexSubImage2D, pixels_shm_offset) == 40,
              "offset of TexSubImage2D pixels_shm_offset should be 40");
static_assert(offsetof(TexSubImage2D, internal) == 44,
              "offset of TexSubImage2D internal should be 44");

struct TexSubImage3D {
  typedef TexSubImage3D ValueType;
  static const CommandId kCmdId = kTexSubImage3D;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _zoffset,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            GLboolean _internal) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    zoffset = _zoffset;
    width = _width;
    height = _height;
    depth = _depth;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
    internal = _internal;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLint _zoffset,
            GLsizei _width,
            GLsizei _height,
            GLsizei _depth,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            GLboolean _internal) {
    static_cast<ValueType*>(cmd)->Init(
        _target, _level, _xoffset, _yoffset, _zoffset, _width, _height, _depth,
        _format, _type, _pixels_shm_id, _pixels_shm_offset, _internal);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t zoffset;
  int32_t width;
  int32_t height;
  int32_t depth;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  uint32_t internal;
};

static_assert(sizeof(TexSubImage3D) == 56,
              "size of TexSubImage3D should be 56");
static_assert(offsetof(TexSubImage3D, header) == 0,
              "offset of TexSubImage3D header should be 0");
static_assert(offsetof(TexSubImage3D, target) == 4,
              "offset of TexSubImage3D target should be 4");
static_assert(offsetof(TexSubImage3D, level) == 8,
              "offset of TexSubImage3D level should be 8");
static_assert(offsetof(TexSubImage3D, xoffset) == 12,
              "offset of TexSubImage3D xoffset should be 12");
static_assert(offsetof(TexSubImage3D, yoffset) == 16,
              "offset of TexSubImage3D yoffset should be 16");
static_assert(offsetof(TexSubImage3D, zoffset) == 20,
              "offset of TexSubImage3D zoffset should be 20");
static_assert(offsetof(TexSubImage3D, width) == 24,
              "offset of TexSubImage3D width should be 24");
static_assert(offsetof(TexSubImage3D, height) == 28,
              "offset of TexSubImage3D height should be 28");
static_assert(offsetof(TexSubImage3D, depth) == 32,
              "offset of TexSubImage3D depth should be 32");
static_assert(offsetof(TexSubImage3D, format) == 36,
              "offset of TexSubImage3D format should be 36");
static_assert(offsetof(TexSubImage3D, type) == 40,
              "offset of TexSubImage3D type should be 40");
static_assert(offsetof(TexSubImage3D, pixels_shm_id) == 44,
              "offset of TexSubImage3D pixels_shm_id should be 44");
static_assert(offsetof(TexSubImage3D, pixels_shm_offset) == 48,
              "offset of TexSubImage3D pixels_shm_offset should be 48");
static_assert(offsetof(TexSubImage3D, internal) == 52,
              "offset of TexSubImage3D internal should be 52");

struct TransformFeedbackVaryingsBucket {
  typedef TransformFeedbackVaryingsBucket ValueType;
  static const CommandId kCmdId = kTransformFeedbackVaryingsBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _varyings_bucket_id, GLenum _buffermode) {
    SetHeader();
    program = _program;
    varyings_bucket_id = _varyings_bucket_id;
    buffermode = _buffermode;
  }

  void* Set(void* cmd,
            GLuint _program,
            uint32_t _varyings_bucket_id,
            GLenum _buffermode) {
    static_cast<ValueType*>(cmd)
        ->Init(_program, _varyings_bucket_id, _buffermode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t varyings_bucket_id;
  uint32_t buffermode;
};

static_assert(sizeof(TransformFeedbackVaryingsBucket) == 16,
              "size of TransformFeedbackVaryingsBucket should be 16");
static_assert(offsetof(TransformFeedbackVaryingsBucket, header) == 0,
              "offset of TransformFeedbackVaryingsBucket header should be 0");
static_assert(offsetof(TransformFeedbackVaryingsBucket, program) == 4,
              "offset of TransformFeedbackVaryingsBucket program should be 4");
static_assert(
    offsetof(TransformFeedbackVaryingsBucket, varyings_bucket_id) == 8,
    "offset of TransformFeedbackVaryingsBucket varyings_bucket_id should be 8");
static_assert(
    offsetof(TransformFeedbackVaryingsBucket, buffermode) == 12,
    "offset of TransformFeedbackVaryingsBucket buffermode should be 12");

struct Uniform1f {
  typedef Uniform1f ValueType;
  static const CommandId kCmdId = kUniform1f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLfloat _x) {
    SetHeader();
    location = _location;
    x = _x;
  }

  void* Set(void* cmd, GLint _location, GLfloat _x) {
    static_cast<ValueType*>(cmd)->Init(_location, _x);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  float x;
};

static_assert(sizeof(Uniform1f) == 12, "size of Uniform1f should be 12");
static_assert(offsetof(Uniform1f, header) == 0,
              "offset of Uniform1f header should be 0");
static_assert(offsetof(Uniform1f, location) == 4,
              "offset of Uniform1f location should be 4");
static_assert(offsetof(Uniform1f, x) == 8, "offset of Uniform1f x should be 8");

struct Uniform1fvImmediate {
  typedef Uniform1fvImmediate ValueType;
  static const CommandId kCmdId = kUniform1fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform1fvImmediate) == 12,
              "size of Uniform1fvImmediate should be 12");
static_assert(offsetof(Uniform1fvImmediate, header) == 0,
              "offset of Uniform1fvImmediate header should be 0");
static_assert(offsetof(Uniform1fvImmediate, location) == 4,
              "offset of Uniform1fvImmediate location should be 4");
static_assert(offsetof(Uniform1fvImmediate, count) == 8,
              "offset of Uniform1fvImmediate count should be 8");

struct Uniform1i {
  typedef Uniform1i ValueType;
  static const CommandId kCmdId = kUniform1i;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLint _x) {
    SetHeader();
    location = _location;
    x = _x;
  }

  void* Set(void* cmd, GLint _location, GLint _x) {
    static_cast<ValueType*>(cmd)->Init(_location, _x);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t x;
};

static_assert(sizeof(Uniform1i) == 12, "size of Uniform1i should be 12");
static_assert(offsetof(Uniform1i, header) == 0,
              "offset of Uniform1i header should be 0");
static_assert(offsetof(Uniform1i, location) == 4,
              "offset of Uniform1i location should be 4");
static_assert(offsetof(Uniform1i, x) == 8, "offset of Uniform1i x should be 8");

struct Uniform1ivImmediate {
  typedef Uniform1ivImmediate ValueType;
  static const CommandId kCmdId = kUniform1ivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLint) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform1ivImmediate) == 12,
              "size of Uniform1ivImmediate should be 12");
static_assert(offsetof(Uniform1ivImmediate, header) == 0,
              "offset of Uniform1ivImmediate header should be 0");
static_assert(offsetof(Uniform1ivImmediate, location) == 4,
              "offset of Uniform1ivImmediate location should be 4");
static_assert(offsetof(Uniform1ivImmediate, count) == 8,
              "offset of Uniform1ivImmediate count should be 8");

struct Uniform1ui {
  typedef Uniform1ui ValueType;
  static const CommandId kCmdId = kUniform1ui;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLuint _x) {
    SetHeader();
    location = _location;
    x = _x;
  }

  void* Set(void* cmd, GLint _location, GLuint _x) {
    static_cast<ValueType*>(cmd)->Init(_location, _x);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  uint32_t x;
};

static_assert(sizeof(Uniform1ui) == 12, "size of Uniform1ui should be 12");
static_assert(offsetof(Uniform1ui, header) == 0,
              "offset of Uniform1ui header should be 0");
static_assert(offsetof(Uniform1ui, location) == 4,
              "offset of Uniform1ui location should be 4");
static_assert(offsetof(Uniform1ui, x) == 8,
              "offset of Uniform1ui x should be 8");

struct Uniform1uivImmediate {
  typedef Uniform1uivImmediate ValueType;
  static const CommandId kCmdId = kUniform1uivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLuint) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLuint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLuint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform1uivImmediate) == 12,
              "size of Uniform1uivImmediate should be 12");
static_assert(offsetof(Uniform1uivImmediate, header) == 0,
              "offset of Uniform1uivImmediate header should be 0");
static_assert(offsetof(Uniform1uivImmediate, location) == 4,
              "offset of Uniform1uivImmediate location should be 4");
static_assert(offsetof(Uniform1uivImmediate, count) == 8,
              "offset of Uniform1uivImmediate count should be 8");

struct Uniform2f {
  typedef Uniform2f ValueType;
  static const CommandId kCmdId = kUniform2f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLfloat _x, GLfloat _y) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
  }

  void* Set(void* cmd, GLint _location, GLfloat _x, GLfloat _y) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  float x;
  float y;
};

static_assert(sizeof(Uniform2f) == 16, "size of Uniform2f should be 16");
static_assert(offsetof(Uniform2f, header) == 0,
              "offset of Uniform2f header should be 0");
static_assert(offsetof(Uniform2f, location) == 4,
              "offset of Uniform2f location should be 4");
static_assert(offsetof(Uniform2f, x) == 8, "offset of Uniform2f x should be 8");
static_assert(offsetof(Uniform2f, y) == 12,
              "offset of Uniform2f y should be 12");

struct Uniform2fvImmediate {
  typedef Uniform2fvImmediate ValueType;
  static const CommandId kCmdId = kUniform2fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 2 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform2fvImmediate) == 12,
              "size of Uniform2fvImmediate should be 12");
static_assert(offsetof(Uniform2fvImmediate, header) == 0,
              "offset of Uniform2fvImmediate header should be 0");
static_assert(offsetof(Uniform2fvImmediate, location) == 4,
              "offset of Uniform2fvImmediate location should be 4");
static_assert(offsetof(Uniform2fvImmediate, count) == 8,
              "offset of Uniform2fvImmediate count should be 8");

struct Uniform2i {
  typedef Uniform2i ValueType;
  static const CommandId kCmdId = kUniform2i;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLint _x, GLint _y) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
  }

  void* Set(void* cmd, GLint _location, GLint _x, GLint _y) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t x;
  int32_t y;
};

static_assert(sizeof(Uniform2i) == 16, "size of Uniform2i should be 16");
static_assert(offsetof(Uniform2i, header) == 0,
              "offset of Uniform2i header should be 0");
static_assert(offsetof(Uniform2i, location) == 4,
              "offset of Uniform2i location should be 4");
static_assert(offsetof(Uniform2i, x) == 8, "offset of Uniform2i x should be 8");
static_assert(offsetof(Uniform2i, y) == 12,
              "offset of Uniform2i y should be 12");

struct Uniform2ivImmediate {
  typedef Uniform2ivImmediate ValueType;
  static const CommandId kCmdId = kUniform2ivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLint) * 2 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform2ivImmediate) == 12,
              "size of Uniform2ivImmediate should be 12");
static_assert(offsetof(Uniform2ivImmediate, header) == 0,
              "offset of Uniform2ivImmediate header should be 0");
static_assert(offsetof(Uniform2ivImmediate, location) == 4,
              "offset of Uniform2ivImmediate location should be 4");
static_assert(offsetof(Uniform2ivImmediate, count) == 8,
              "offset of Uniform2ivImmediate count should be 8");

struct Uniform2ui {
  typedef Uniform2ui ValueType;
  static const CommandId kCmdId = kUniform2ui;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLuint _x, GLuint _y) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
  }

  void* Set(void* cmd, GLint _location, GLuint _x, GLuint _y) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  uint32_t x;
  uint32_t y;
};

static_assert(sizeof(Uniform2ui) == 16, "size of Uniform2ui should be 16");
static_assert(offsetof(Uniform2ui, header) == 0,
              "offset of Uniform2ui header should be 0");
static_assert(offsetof(Uniform2ui, location) == 4,
              "offset of Uniform2ui location should be 4");
static_assert(offsetof(Uniform2ui, x) == 8,
              "offset of Uniform2ui x should be 8");
static_assert(offsetof(Uniform2ui, y) == 12,
              "offset of Uniform2ui y should be 12");

struct Uniform2uivImmediate {
  typedef Uniform2uivImmediate ValueType;
  static const CommandId kCmdId = kUniform2uivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLuint) * 2 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLuint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLuint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform2uivImmediate) == 12,
              "size of Uniform2uivImmediate should be 12");
static_assert(offsetof(Uniform2uivImmediate, header) == 0,
              "offset of Uniform2uivImmediate header should be 0");
static_assert(offsetof(Uniform2uivImmediate, location) == 4,
              "offset of Uniform2uivImmediate location should be 4");
static_assert(offsetof(Uniform2uivImmediate, count) == 8,
              "offset of Uniform2uivImmediate count should be 8");

struct Uniform3f {
  typedef Uniform3f ValueType;
  static const CommandId kCmdId = kUniform3f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLfloat _x, GLfloat _y, GLfloat _z) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
  }

  void* Set(void* cmd, GLint _location, GLfloat _x, GLfloat _y, GLfloat _z) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  float x;
  float y;
  float z;
};

static_assert(sizeof(Uniform3f) == 20, "size of Uniform3f should be 20");
static_assert(offsetof(Uniform3f, header) == 0,
              "offset of Uniform3f header should be 0");
static_assert(offsetof(Uniform3f, location) == 4,
              "offset of Uniform3f location should be 4");
static_assert(offsetof(Uniform3f, x) == 8, "offset of Uniform3f x should be 8");
static_assert(offsetof(Uniform3f, y) == 12,
              "offset of Uniform3f y should be 12");
static_assert(offsetof(Uniform3f, z) == 16,
              "offset of Uniform3f z should be 16");

struct Uniform3fvImmediate {
  typedef Uniform3fvImmediate ValueType;
  static const CommandId kCmdId = kUniform3fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 3 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform3fvImmediate) == 12,
              "size of Uniform3fvImmediate should be 12");
static_assert(offsetof(Uniform3fvImmediate, header) == 0,
              "offset of Uniform3fvImmediate header should be 0");
static_assert(offsetof(Uniform3fvImmediate, location) == 4,
              "offset of Uniform3fvImmediate location should be 4");
static_assert(offsetof(Uniform3fvImmediate, count) == 8,
              "offset of Uniform3fvImmediate count should be 8");

struct Uniform3i {
  typedef Uniform3i ValueType;
  static const CommandId kCmdId = kUniform3i;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLint _x, GLint _y, GLint _z) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
  }

  void* Set(void* cmd, GLint _location, GLint _x, GLint _y, GLint _z) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t x;
  int32_t y;
  int32_t z;
};

static_assert(sizeof(Uniform3i) == 20, "size of Uniform3i should be 20");
static_assert(offsetof(Uniform3i, header) == 0,
              "offset of Uniform3i header should be 0");
static_assert(offsetof(Uniform3i, location) == 4,
              "offset of Uniform3i location should be 4");
static_assert(offsetof(Uniform3i, x) == 8, "offset of Uniform3i x should be 8");
static_assert(offsetof(Uniform3i, y) == 12,
              "offset of Uniform3i y should be 12");
static_assert(offsetof(Uniform3i, z) == 16,
              "offset of Uniform3i z should be 16");

struct Uniform3ivImmediate {
  typedef Uniform3ivImmediate ValueType;
  static const CommandId kCmdId = kUniform3ivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLint) * 3 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform3ivImmediate) == 12,
              "size of Uniform3ivImmediate should be 12");
static_assert(offsetof(Uniform3ivImmediate, header) == 0,
              "offset of Uniform3ivImmediate header should be 0");
static_assert(offsetof(Uniform3ivImmediate, location) == 4,
              "offset of Uniform3ivImmediate location should be 4");
static_assert(offsetof(Uniform3ivImmediate, count) == 8,
              "offset of Uniform3ivImmediate count should be 8");

struct Uniform3ui {
  typedef Uniform3ui ValueType;
  static const CommandId kCmdId = kUniform3ui;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLuint _x, GLuint _y, GLuint _z) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
  }

  void* Set(void* cmd, GLint _location, GLuint _x, GLuint _y, GLuint _z) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  uint32_t x;
  uint32_t y;
  uint32_t z;
};

static_assert(sizeof(Uniform3ui) == 20, "size of Uniform3ui should be 20");
static_assert(offsetof(Uniform3ui, header) == 0,
              "offset of Uniform3ui header should be 0");
static_assert(offsetof(Uniform3ui, location) == 4,
              "offset of Uniform3ui location should be 4");
static_assert(offsetof(Uniform3ui, x) == 8,
              "offset of Uniform3ui x should be 8");
static_assert(offsetof(Uniform3ui, y) == 12,
              "offset of Uniform3ui y should be 12");
static_assert(offsetof(Uniform3ui, z) == 16,
              "offset of Uniform3ui z should be 16");

struct Uniform3uivImmediate {
  typedef Uniform3uivImmediate ValueType;
  static const CommandId kCmdId = kUniform3uivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLuint) * 3 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLuint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLuint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform3uivImmediate) == 12,
              "size of Uniform3uivImmediate should be 12");
static_assert(offsetof(Uniform3uivImmediate, header) == 0,
              "offset of Uniform3uivImmediate header should be 0");
static_assert(offsetof(Uniform3uivImmediate, location) == 4,
              "offset of Uniform3uivImmediate location should be 4");
static_assert(offsetof(Uniform3uivImmediate, count) == 8,
              "offset of Uniform3uivImmediate count should be 8");

struct Uniform4f {
  typedef Uniform4f ValueType;
  static const CommandId kCmdId = kUniform4f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLfloat _x, GLfloat _y, GLfloat _z, GLfloat _w) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd,
            GLint _location,
            GLfloat _x,
            GLfloat _y,
            GLfloat _z,
            GLfloat _w) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  float x;
  float y;
  float z;
  float w;
};

static_assert(sizeof(Uniform4f) == 24, "size of Uniform4f should be 24");
static_assert(offsetof(Uniform4f, header) == 0,
              "offset of Uniform4f header should be 0");
static_assert(offsetof(Uniform4f, location) == 4,
              "offset of Uniform4f location should be 4");
static_assert(offsetof(Uniform4f, x) == 8, "offset of Uniform4f x should be 8");
static_assert(offsetof(Uniform4f, y) == 12,
              "offset of Uniform4f y should be 12");
static_assert(offsetof(Uniform4f, z) == 16,
              "offset of Uniform4f z should be 16");
static_assert(offsetof(Uniform4f, w) == 20,
              "offset of Uniform4f w should be 20");

struct Uniform4fvImmediate {
  typedef Uniform4fvImmediate ValueType;
  static const CommandId kCmdId = kUniform4fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 4 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform4fvImmediate) == 12,
              "size of Uniform4fvImmediate should be 12");
static_assert(offsetof(Uniform4fvImmediate, header) == 0,
              "offset of Uniform4fvImmediate header should be 0");
static_assert(offsetof(Uniform4fvImmediate, location) == 4,
              "offset of Uniform4fvImmediate location should be 4");
static_assert(offsetof(Uniform4fvImmediate, count) == 8,
              "offset of Uniform4fvImmediate count should be 8");

struct Uniform4i {
  typedef Uniform4i ValueType;
  static const CommandId kCmdId = kUniform4i;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLint _x, GLint _y, GLint _z, GLint _w) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd,
            GLint _location,
            GLint _x,
            GLint _y,
            GLint _z,
            GLint _w) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t x;
  int32_t y;
  int32_t z;
  int32_t w;
};

static_assert(sizeof(Uniform4i) == 24, "size of Uniform4i should be 24");
static_assert(offsetof(Uniform4i, header) == 0,
              "offset of Uniform4i header should be 0");
static_assert(offsetof(Uniform4i, location) == 4,
              "offset of Uniform4i location should be 4");
static_assert(offsetof(Uniform4i, x) == 8, "offset of Uniform4i x should be 8");
static_assert(offsetof(Uniform4i, y) == 12,
              "offset of Uniform4i y should be 12");
static_assert(offsetof(Uniform4i, z) == 16,
              "offset of Uniform4i z should be 16");
static_assert(offsetof(Uniform4i, w) == 20,
              "offset of Uniform4i w should be 20");

struct Uniform4ivImmediate {
  typedef Uniform4ivImmediate ValueType;
  static const CommandId kCmdId = kUniform4ivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLint) * 4 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform4ivImmediate) == 12,
              "size of Uniform4ivImmediate should be 12");
static_assert(offsetof(Uniform4ivImmediate, header) == 0,
              "offset of Uniform4ivImmediate header should be 0");
static_assert(offsetof(Uniform4ivImmediate, location) == 4,
              "offset of Uniform4ivImmediate location should be 4");
static_assert(offsetof(Uniform4ivImmediate, count) == 8,
              "offset of Uniform4ivImmediate count should be 8");

struct Uniform4ui {
  typedef Uniform4ui ValueType;
  static const CommandId kCmdId = kUniform4ui;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLuint _x, GLuint _y, GLuint _z, GLuint _w) {
    SetHeader();
    location = _location;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd,
            GLint _location,
            GLuint _x,
            GLuint _y,
            GLuint _z,
            GLuint _w) {
    static_cast<ValueType*>(cmd)->Init(_location, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  uint32_t x;
  uint32_t y;
  uint32_t z;
  uint32_t w;
};

static_assert(sizeof(Uniform4ui) == 24, "size of Uniform4ui should be 24");
static_assert(offsetof(Uniform4ui, header) == 0,
              "offset of Uniform4ui header should be 0");
static_assert(offsetof(Uniform4ui, location) == 4,
              "offset of Uniform4ui location should be 4");
static_assert(offsetof(Uniform4ui, x) == 8,
              "offset of Uniform4ui x should be 8");
static_assert(offsetof(Uniform4ui, y) == 12,
              "offset of Uniform4ui y should be 12");
static_assert(offsetof(Uniform4ui, z) == 16,
              "offset of Uniform4ui z should be 16");
static_assert(offsetof(Uniform4ui, w) == 20,
              "offset of Uniform4ui w should be 20");

struct Uniform4uivImmediate {
  typedef Uniform4uivImmediate ValueType;
  static const CommandId kCmdId = kUniform4uivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLuint) * 4 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLuint* _v) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _v, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLuint* _v) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _v);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
};

static_assert(sizeof(Uniform4uivImmediate) == 12,
              "size of Uniform4uivImmediate should be 12");
static_assert(offsetof(Uniform4uivImmediate, header) == 0,
              "offset of Uniform4uivImmediate header should be 0");
static_assert(offsetof(Uniform4uivImmediate, location) == 4,
              "offset of Uniform4uivImmediate location should be 4");
static_assert(offsetof(Uniform4uivImmediate, count) == 8,
              "offset of Uniform4uivImmediate count should be 8");

struct UniformBlockBinding {
  typedef UniformBlockBinding ValueType;
  static const CommandId kCmdId = kUniformBlockBinding;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, GLuint _index, GLuint _binding) {
    SetHeader();
    program = _program;
    index = _index;
    binding = _binding;
  }

  void* Set(void* cmd, GLuint _program, GLuint _index, GLuint _binding) {
    static_cast<ValueType*>(cmd)->Init(_program, _index, _binding);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t index;
  uint32_t binding;
};

static_assert(sizeof(UniformBlockBinding) == 16,
              "size of UniformBlockBinding should be 16");
static_assert(offsetof(UniformBlockBinding, header) == 0,
              "offset of UniformBlockBinding header should be 0");
static_assert(offsetof(UniformBlockBinding, program) == 4,
              "offset of UniformBlockBinding program should be 4");
static_assert(offsetof(UniformBlockBinding, index) == 8,
              "offset of UniformBlockBinding index should be 8");
static_assert(offsetof(UniformBlockBinding, binding) == 12,
              "offset of UniformBlockBinding binding should be 12");

struct UniformMatrix2fvImmediate {
  typedef UniformMatrix2fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix2fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 4 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix2fvImmediate) == 12,
              "size of UniformMatrix2fvImmediate should be 12");
static_assert(offsetof(UniformMatrix2fvImmediate, header) == 0,
              "offset of UniformMatrix2fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix2fvImmediate, location) == 4,
              "offset of UniformMatrix2fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix2fvImmediate, count) == 8,
              "offset of UniformMatrix2fvImmediate count should be 8");

struct UniformMatrix2x3fvImmediate {
  typedef UniformMatrix2x3fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix2x3fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 6 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix2x3fvImmediate) == 12,
              "size of UniformMatrix2x3fvImmediate should be 12");
static_assert(offsetof(UniformMatrix2x3fvImmediate, header) == 0,
              "offset of UniformMatrix2x3fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix2x3fvImmediate, location) == 4,
              "offset of UniformMatrix2x3fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix2x3fvImmediate, count) == 8,
              "offset of UniformMatrix2x3fvImmediate count should be 8");

struct UniformMatrix2x4fvImmediate {
  typedef UniformMatrix2x4fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix2x4fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 8 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix2x4fvImmediate) == 12,
              "size of UniformMatrix2x4fvImmediate should be 12");
static_assert(offsetof(UniformMatrix2x4fvImmediate, header) == 0,
              "offset of UniformMatrix2x4fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix2x4fvImmediate, location) == 4,
              "offset of UniformMatrix2x4fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix2x4fvImmediate, count) == 8,
              "offset of UniformMatrix2x4fvImmediate count should be 8");

struct UniformMatrix3fvImmediate {
  typedef UniformMatrix3fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix3fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 9 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix3fvImmediate) == 12,
              "size of UniformMatrix3fvImmediate should be 12");
static_assert(offsetof(UniformMatrix3fvImmediate, header) == 0,
              "offset of UniformMatrix3fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix3fvImmediate, location) == 4,
              "offset of UniformMatrix3fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix3fvImmediate, count) == 8,
              "offset of UniformMatrix3fvImmediate count should be 8");

struct UniformMatrix3x2fvImmediate {
  typedef UniformMatrix3x2fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix3x2fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 6 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix3x2fvImmediate) == 12,
              "size of UniformMatrix3x2fvImmediate should be 12");
static_assert(offsetof(UniformMatrix3x2fvImmediate, header) == 0,
              "offset of UniformMatrix3x2fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix3x2fvImmediate, location) == 4,
              "offset of UniformMatrix3x2fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix3x2fvImmediate, count) == 8,
              "offset of UniformMatrix3x2fvImmediate count should be 8");

struct UniformMatrix3x4fvImmediate {
  typedef UniformMatrix3x4fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix3x4fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 12 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix3x4fvImmediate) == 12,
              "size of UniformMatrix3x4fvImmediate should be 12");
static_assert(offsetof(UniformMatrix3x4fvImmediate, header) == 0,
              "offset of UniformMatrix3x4fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix3x4fvImmediate, location) == 4,
              "offset of UniformMatrix3x4fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix3x4fvImmediate, count) == 8,
              "offset of UniformMatrix3x4fvImmediate count should be 8");

struct UniformMatrix4fvImmediate {
  typedef UniformMatrix4fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix4fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 16 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix4fvImmediate) == 12,
              "size of UniformMatrix4fvImmediate should be 12");
static_assert(offsetof(UniformMatrix4fvImmediate, header) == 0,
              "offset of UniformMatrix4fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix4fvImmediate, location) == 4,
              "offset of UniformMatrix4fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix4fvImmediate, count) == 8,
              "offset of UniformMatrix4fvImmediate count should be 8");

struct UniformMatrix4x2fvImmediate {
  typedef UniformMatrix4x2fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix4x2fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 8 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix4x2fvImmediate) == 12,
              "size of UniformMatrix4x2fvImmediate should be 12");
static_assert(offsetof(UniformMatrix4x2fvImmediate, header) == 0,
              "offset of UniformMatrix4x2fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix4x2fvImmediate, location) == 4,
              "offset of UniformMatrix4x2fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix4x2fvImmediate, count) == 8,
              "offset of UniformMatrix4x2fvImmediate count should be 8");

struct UniformMatrix4x3fvImmediate {
  typedef UniformMatrix4x3fvImmediate ValueType;
  static const CommandId kCmdId = kUniformMatrix4x3fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLfloat) * 12 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLint _location, GLsizei _count, const GLfloat* _value) {
    SetHeader(_count);
    location = _location;
    count = _count;
    memcpy(ImmediateDataAddress(this), _value, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLint _location, GLsizei _count, const GLfloat* _value) {
    static_cast<ValueType*>(cmd)->Init(_location, _count, _value);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t location;
  int32_t count;
  static const uint32_t transpose = false;
};

static_assert(sizeof(UniformMatrix4x3fvImmediate) == 12,
              "size of UniformMatrix4x3fvImmediate should be 12");
static_assert(offsetof(UniformMatrix4x3fvImmediate, header) == 0,
              "offset of UniformMatrix4x3fvImmediate header should be 0");
static_assert(offsetof(UniformMatrix4x3fvImmediate, location) == 4,
              "offset of UniformMatrix4x3fvImmediate location should be 4");
static_assert(offsetof(UniformMatrix4x3fvImmediate, count) == 8,
              "offset of UniformMatrix4x3fvImmediate count should be 8");

struct UseProgram {
  typedef UseProgram ValueType;
  static const CommandId kCmdId = kUseProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program) {
    SetHeader();
    program = _program;
  }

  void* Set(void* cmd, GLuint _program) {
    static_cast<ValueType*>(cmd)->Init(_program);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
};

static_assert(sizeof(UseProgram) == 8, "size of UseProgram should be 8");
static_assert(offsetof(UseProgram, header) == 0,
              "offset of UseProgram header should be 0");
static_assert(offsetof(UseProgram, program) == 4,
              "offset of UseProgram program should be 4");

struct ValidateProgram {
  typedef ValidateProgram ValueType;
  static const CommandId kCmdId = kValidateProgram;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program) {
    SetHeader();
    program = _program;
  }

  void* Set(void* cmd, GLuint _program) {
    static_cast<ValueType*>(cmd)->Init(_program);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
};

static_assert(sizeof(ValidateProgram) == 8,
              "size of ValidateProgram should be 8");
static_assert(offsetof(ValidateProgram, header) == 0,
              "offset of ValidateProgram header should be 0");
static_assert(offsetof(ValidateProgram, program) == 4,
              "offset of ValidateProgram program should be 4");

struct VertexAttrib1f {
  typedef VertexAttrib1f ValueType;
  static const CommandId kCmdId = kVertexAttrib1f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLfloat _x) {
    SetHeader();
    indx = _indx;
    x = _x;
  }

  void* Set(void* cmd, GLuint _indx, GLfloat _x) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  float x;
};

static_assert(sizeof(VertexAttrib1f) == 12,
              "size of VertexAttrib1f should be 12");
static_assert(offsetof(VertexAttrib1f, header) == 0,
              "offset of VertexAttrib1f header should be 0");
static_assert(offsetof(VertexAttrib1f, indx) == 4,
              "offset of VertexAttrib1f indx should be 4");
static_assert(offsetof(VertexAttrib1f, x) == 8,
              "offset of VertexAttrib1f x should be 8");

struct VertexAttrib1fvImmediate {
  typedef VertexAttrib1fvImmediate ValueType;
  static const CommandId kCmdId = kVertexAttrib1fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 1);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLfloat* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLfloat* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttrib1fvImmediate) == 8,
              "size of VertexAttrib1fvImmediate should be 8");
static_assert(offsetof(VertexAttrib1fvImmediate, header) == 0,
              "offset of VertexAttrib1fvImmediate header should be 0");
static_assert(offsetof(VertexAttrib1fvImmediate, indx) == 4,
              "offset of VertexAttrib1fvImmediate indx should be 4");

struct VertexAttrib2f {
  typedef VertexAttrib2f ValueType;
  static const CommandId kCmdId = kVertexAttrib2f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLfloat _x, GLfloat _y) {
    SetHeader();
    indx = _indx;
    x = _x;
    y = _y;
  }

  void* Set(void* cmd, GLuint _indx, GLfloat _x, GLfloat _y) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x, _y);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  float x;
  float y;
};

static_assert(sizeof(VertexAttrib2f) == 16,
              "size of VertexAttrib2f should be 16");
static_assert(offsetof(VertexAttrib2f, header) == 0,
              "offset of VertexAttrib2f header should be 0");
static_assert(offsetof(VertexAttrib2f, indx) == 4,
              "offset of VertexAttrib2f indx should be 4");
static_assert(offsetof(VertexAttrib2f, x) == 8,
              "offset of VertexAttrib2f x should be 8");
static_assert(offsetof(VertexAttrib2f, y) == 12,
              "offset of VertexAttrib2f y should be 12");

struct VertexAttrib2fvImmediate {
  typedef VertexAttrib2fvImmediate ValueType;
  static const CommandId kCmdId = kVertexAttrib2fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 2);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLfloat* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLfloat* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttrib2fvImmediate) == 8,
              "size of VertexAttrib2fvImmediate should be 8");
static_assert(offsetof(VertexAttrib2fvImmediate, header) == 0,
              "offset of VertexAttrib2fvImmediate header should be 0");
static_assert(offsetof(VertexAttrib2fvImmediate, indx) == 4,
              "offset of VertexAttrib2fvImmediate indx should be 4");

struct VertexAttrib3f {
  typedef VertexAttrib3f ValueType;
  static const CommandId kCmdId = kVertexAttrib3f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLfloat _x, GLfloat _y, GLfloat _z) {
    SetHeader();
    indx = _indx;
    x = _x;
    y = _y;
    z = _z;
  }

  void* Set(void* cmd, GLuint _indx, GLfloat _x, GLfloat _y, GLfloat _z) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x, _y, _z);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  float x;
  float y;
  float z;
};

static_assert(sizeof(VertexAttrib3f) == 20,
              "size of VertexAttrib3f should be 20");
static_assert(offsetof(VertexAttrib3f, header) == 0,
              "offset of VertexAttrib3f header should be 0");
static_assert(offsetof(VertexAttrib3f, indx) == 4,
              "offset of VertexAttrib3f indx should be 4");
static_assert(offsetof(VertexAttrib3f, x) == 8,
              "offset of VertexAttrib3f x should be 8");
static_assert(offsetof(VertexAttrib3f, y) == 12,
              "offset of VertexAttrib3f y should be 12");
static_assert(offsetof(VertexAttrib3f, z) == 16,
              "offset of VertexAttrib3f z should be 16");

struct VertexAttrib3fvImmediate {
  typedef VertexAttrib3fvImmediate ValueType;
  static const CommandId kCmdId = kVertexAttrib3fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 3);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLfloat* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLfloat* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttrib3fvImmediate) == 8,
              "size of VertexAttrib3fvImmediate should be 8");
static_assert(offsetof(VertexAttrib3fvImmediate, header) == 0,
              "offset of VertexAttrib3fvImmediate header should be 0");
static_assert(offsetof(VertexAttrib3fvImmediate, indx) == 4,
              "offset of VertexAttrib3fvImmediate indx should be 4");

struct VertexAttrib4f {
  typedef VertexAttrib4f ValueType;
  static const CommandId kCmdId = kVertexAttrib4f;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLfloat _x, GLfloat _y, GLfloat _z, GLfloat _w) {
    SetHeader();
    indx = _indx;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd,
            GLuint _indx,
            GLfloat _x,
            GLfloat _y,
            GLfloat _z,
            GLfloat _w) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  float x;
  float y;
  float z;
  float w;
};

static_assert(sizeof(VertexAttrib4f) == 24,
              "size of VertexAttrib4f should be 24");
static_assert(offsetof(VertexAttrib4f, header) == 0,
              "offset of VertexAttrib4f header should be 0");
static_assert(offsetof(VertexAttrib4f, indx) == 4,
              "offset of VertexAttrib4f indx should be 4");
static_assert(offsetof(VertexAttrib4f, x) == 8,
              "offset of VertexAttrib4f x should be 8");
static_assert(offsetof(VertexAttrib4f, y) == 12,
              "offset of VertexAttrib4f y should be 12");
static_assert(offsetof(VertexAttrib4f, z) == 16,
              "offset of VertexAttrib4f z should be 16");
static_assert(offsetof(VertexAttrib4f, w) == 20,
              "offset of VertexAttrib4f w should be 20");

struct VertexAttrib4fvImmediate {
  typedef VertexAttrib4fvImmediate ValueType;
  static const CommandId kCmdId = kVertexAttrib4fvImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 4);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLfloat* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLfloat* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttrib4fvImmediate) == 8,
              "size of VertexAttrib4fvImmediate should be 8");
static_assert(offsetof(VertexAttrib4fvImmediate, header) == 0,
              "offset of VertexAttrib4fvImmediate header should be 0");
static_assert(offsetof(VertexAttrib4fvImmediate, indx) == 4,
              "offset of VertexAttrib4fvImmediate indx should be 4");

struct VertexAttribI4i {
  typedef VertexAttribI4i ValueType;
  static const CommandId kCmdId = kVertexAttribI4i;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLint _x, GLint _y, GLint _z, GLint _w) {
    SetHeader();
    indx = _indx;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd, GLuint _indx, GLint _x, GLint _y, GLint _z, GLint _w) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  int32_t x;
  int32_t y;
  int32_t z;
  int32_t w;
};

static_assert(sizeof(VertexAttribI4i) == 24,
              "size of VertexAttribI4i should be 24");
static_assert(offsetof(VertexAttribI4i, header) == 0,
              "offset of VertexAttribI4i header should be 0");
static_assert(offsetof(VertexAttribI4i, indx) == 4,
              "offset of VertexAttribI4i indx should be 4");
static_assert(offsetof(VertexAttribI4i, x) == 8,
              "offset of VertexAttribI4i x should be 8");
static_assert(offsetof(VertexAttribI4i, y) == 12,
              "offset of VertexAttribI4i y should be 12");
static_assert(offsetof(VertexAttribI4i, z) == 16,
              "offset of VertexAttribI4i z should be 16");
static_assert(offsetof(VertexAttribI4i, w) == 20,
              "offset of VertexAttribI4i w should be 20");

struct VertexAttribI4ivImmediate {
  typedef VertexAttribI4ivImmediate ValueType;
  static const CommandId kCmdId = kVertexAttribI4ivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLint) * 4);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLint* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLint* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttribI4ivImmediate) == 8,
              "size of VertexAttribI4ivImmediate should be 8");
static_assert(offsetof(VertexAttribI4ivImmediate, header) == 0,
              "offset of VertexAttribI4ivImmediate header should be 0");
static_assert(offsetof(VertexAttribI4ivImmediate, indx) == 4,
              "offset of VertexAttribI4ivImmediate indx should be 4");

struct VertexAttribI4ui {
  typedef VertexAttribI4ui ValueType;
  static const CommandId kCmdId = kVertexAttribI4ui;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx, GLuint _x, GLuint _y, GLuint _z, GLuint _w) {
    SetHeader();
    indx = _indx;
    x = _x;
    y = _y;
    z = _z;
    w = _w;
  }

  void* Set(void* cmd,
            GLuint _indx,
            GLuint _x,
            GLuint _y,
            GLuint _z,
            GLuint _w) {
    static_cast<ValueType*>(cmd)->Init(_indx, _x, _y, _z, _w);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  uint32_t x;
  uint32_t y;
  uint32_t z;
  uint32_t w;
};

static_assert(sizeof(VertexAttribI4ui) == 24,
              "size of VertexAttribI4ui should be 24");
static_assert(offsetof(VertexAttribI4ui, header) == 0,
              "offset of VertexAttribI4ui header should be 0");
static_assert(offsetof(VertexAttribI4ui, indx) == 4,
              "offset of VertexAttribI4ui indx should be 4");
static_assert(offsetof(VertexAttribI4ui, x) == 8,
              "offset of VertexAttribI4ui x should be 8");
static_assert(offsetof(VertexAttribI4ui, y) == 12,
              "offset of VertexAttribI4ui y should be 12");
static_assert(offsetof(VertexAttribI4ui, z) == 16,
              "offset of VertexAttribI4ui z should be 16");
static_assert(offsetof(VertexAttribI4ui, w) == 20,
              "offset of VertexAttribI4ui w should be 20");

struct VertexAttribI4uivImmediate {
  typedef VertexAttribI4uivImmediate ValueType;
  static const CommandId kCmdId = kVertexAttribI4uivImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLuint) * 4);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _indx, const GLuint* _values) {
    SetHeader();
    indx = _indx;
    memcpy(ImmediateDataAddress(this), _values, ComputeDataSize());
  }

  void* Set(void* cmd, GLuint _indx, const GLuint* _values) {
    static_cast<ValueType*>(cmd)->Init(_indx, _values);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t indx;
};

static_assert(sizeof(VertexAttribI4uivImmediate) == 8,
              "size of VertexAttribI4uivImmediate should be 8");
static_assert(offsetof(VertexAttribI4uivImmediate, header) == 0,
              "offset of VertexAttribI4uivImmediate header should be 0");
static_assert(offsetof(VertexAttribI4uivImmediate, indx) == 4,
              "offset of VertexAttribI4uivImmediate indx should be 4");

struct VertexAttribIPointer {
  typedef VertexAttribIPointer ValueType;
  static const CommandId kCmdId = kVertexAttribIPointer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx,
            GLint _size,
            GLenum _type,
            GLsizei _stride,
            GLuint _offset) {
    SetHeader();
    indx = _indx;
    size = _size;
    type = _type;
    stride = _stride;
    offset = _offset;
  }

  void* Set(void* cmd,
            GLuint _indx,
            GLint _size,
            GLenum _type,
            GLsizei _stride,
            GLuint _offset) {
    static_cast<ValueType*>(cmd)->Init(_indx, _size, _type, _stride, _offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  int32_t size;
  uint32_t type;
  int32_t stride;
  uint32_t offset;
};

static_assert(sizeof(VertexAttribIPointer) == 24,
              "size of VertexAttribIPointer should be 24");
static_assert(offsetof(VertexAttribIPointer, header) == 0,
              "offset of VertexAttribIPointer header should be 0");
static_assert(offsetof(VertexAttribIPointer, indx) == 4,
              "offset of VertexAttribIPointer indx should be 4");
static_assert(offsetof(VertexAttribIPointer, size) == 8,
              "offset of VertexAttribIPointer size should be 8");
static_assert(offsetof(VertexAttribIPointer, type) == 12,
              "offset of VertexAttribIPointer type should be 12");
static_assert(offsetof(VertexAttribIPointer, stride) == 16,
              "offset of VertexAttribIPointer stride should be 16");
static_assert(offsetof(VertexAttribIPointer, offset) == 20,
              "offset of VertexAttribIPointer offset should be 20");

struct VertexAttribPointer {
  typedef VertexAttribPointer ValueType;
  static const CommandId kCmdId = kVertexAttribPointer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _indx,
            GLint _size,
            GLenum _type,
            GLboolean _normalized,
            GLsizei _stride,
            GLuint _offset) {
    SetHeader();
    indx = _indx;
    size = _size;
    type = _type;
    normalized = _normalized;
    stride = _stride;
    offset = _offset;
  }

  void* Set(void* cmd,
            GLuint _indx,
            GLint _size,
            GLenum _type,
            GLboolean _normalized,
            GLsizei _stride,
            GLuint _offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_indx, _size, _type, _normalized, _stride, _offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t indx;
  int32_t size;
  uint32_t type;
  uint32_t normalized;
  int32_t stride;
  uint32_t offset;
};

static_assert(sizeof(VertexAttribPointer) == 28,
              "size of VertexAttribPointer should be 28");
static_assert(offsetof(VertexAttribPointer, header) == 0,
              "offset of VertexAttribPointer header should be 0");
static_assert(offsetof(VertexAttribPointer, indx) == 4,
              "offset of VertexAttribPointer indx should be 4");
static_assert(offsetof(VertexAttribPointer, size) == 8,
              "offset of VertexAttribPointer size should be 8");
static_assert(offsetof(VertexAttribPointer, type) == 12,
              "offset of VertexAttribPointer type should be 12");
static_assert(offsetof(VertexAttribPointer, normalized) == 16,
              "offset of VertexAttribPointer normalized should be 16");
static_assert(offsetof(VertexAttribPointer, stride) == 20,
              "offset of VertexAttribPointer stride should be 20");
static_assert(offsetof(VertexAttribPointer, offset) == 24,
              "offset of VertexAttribPointer offset should be 24");

struct Viewport {
  typedef Viewport ValueType;
  static const CommandId kCmdId = kViewport;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _x, GLint _y, GLsizei _width, GLsizei _height) {
    SetHeader();
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd, GLint _x, GLint _y, GLsizei _width, GLsizei _height) {
    static_cast<ValueType*>(cmd)->Init(_x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(Viewport) == 20, "size of Viewport should be 20");
static_assert(offsetof(Viewport, header) == 0,
              "offset of Viewport header should be 0");
static_assert(offsetof(Viewport, x) == 4, "offset of Viewport x should be 4");
static_assert(offsetof(Viewport, y) == 8, "offset of Viewport y should be 8");
static_assert(offsetof(Viewport, width) == 12,
              "offset of Viewport width should be 12");
static_assert(offsetof(Viewport, height) == 16,
              "offset of Viewport height should be 16");

struct WaitSync {
  typedef WaitSync ValueType;
  static const CommandId kCmdId = kWaitSync;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync,
            GLbitfield _flags,
            GLuint _timeout_0,
            GLuint _timeout_1) {
    SetHeader();
    sync = _sync;
    flags = _flags;
    timeout_0 = _timeout_0;
    timeout_1 = _timeout_1;
  }

  void* Set(void* cmd,
            GLuint _sync,
            GLbitfield _flags,
            GLuint _timeout_0,
            GLuint _timeout_1) {
    static_cast<ValueType*>(cmd)->Init(_sync, _flags, _timeout_0, _timeout_1);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync;
  uint32_t flags;
  uint32_t timeout_0;
  uint32_t timeout_1;
};

static_assert(sizeof(WaitSync) == 20, "size of WaitSync should be 20");
static_assert(offsetof(WaitSync, header) == 0,
              "offset of WaitSync header should be 0");
static_assert(offsetof(WaitSync, sync) == 4,
              "offset of WaitSync sync should be 4");
static_assert(offsetof(WaitSync, flags) == 8,
              "offset of WaitSync flags should be 8");
static_assert(offsetof(WaitSync, timeout_0) == 12,
              "offset of WaitSync timeout_0 should be 12");
static_assert(offsetof(WaitSync, timeout_1) == 16,
              "offset of WaitSync timeout_1 should be 16");

struct BlitFramebufferCHROMIUM {
  typedef BlitFramebufferCHROMIUM ValueType;
  static const CommandId kCmdId = kBlitFramebufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _srcX0,
            GLint _srcY0,
            GLint _srcX1,
            GLint _srcY1,
            GLint _dstX0,
            GLint _dstY0,
            GLint _dstX1,
            GLint _dstY1,
            GLbitfield _mask,
            GLenum _filter) {
    SetHeader();
    srcX0 = _srcX0;
    srcY0 = _srcY0;
    srcX1 = _srcX1;
    srcY1 = _srcY1;
    dstX0 = _dstX0;
    dstY0 = _dstY0;
    dstX1 = _dstX1;
    dstY1 = _dstY1;
    mask = _mask;
    filter = _filter;
  }

  void* Set(void* cmd,
            GLint _srcX0,
            GLint _srcY0,
            GLint _srcX1,
            GLint _srcY1,
            GLint _dstX0,
            GLint _dstY0,
            GLint _dstX1,
            GLint _dstY1,
            GLbitfield _mask,
            GLenum _filter) {
    static_cast<ValueType*>(cmd)->Init(_srcX0, _srcY0, _srcX1, _srcY1, _dstX0,
                                       _dstY0, _dstX1, _dstY1, _mask, _filter);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t srcX0;
  int32_t srcY0;
  int32_t srcX1;
  int32_t srcY1;
  int32_t dstX0;
  int32_t dstY0;
  int32_t dstX1;
  int32_t dstY1;
  uint32_t mask;
  uint32_t filter;
};

static_assert(sizeof(BlitFramebufferCHROMIUM) == 44,
              "size of BlitFramebufferCHROMIUM should be 44");
static_assert(offsetof(BlitFramebufferCHROMIUM, header) == 0,
              "offset of BlitFramebufferCHROMIUM header should be 0");
static_assert(offsetof(BlitFramebufferCHROMIUM, srcX0) == 4,
              "offset of BlitFramebufferCHROMIUM srcX0 should be 4");
static_assert(offsetof(BlitFramebufferCHROMIUM, srcY0) == 8,
              "offset of BlitFramebufferCHROMIUM srcY0 should be 8");
static_assert(offsetof(BlitFramebufferCHROMIUM, srcX1) == 12,
              "offset of BlitFramebufferCHROMIUM srcX1 should be 12");
static_assert(offsetof(BlitFramebufferCHROMIUM, srcY1) == 16,
              "offset of BlitFramebufferCHROMIUM srcY1 should be 16");
static_assert(offsetof(BlitFramebufferCHROMIUM, dstX0) == 20,
              "offset of BlitFramebufferCHROMIUM dstX0 should be 20");
static_assert(offsetof(BlitFramebufferCHROMIUM, dstY0) == 24,
              "offset of BlitFramebufferCHROMIUM dstY0 should be 24");
static_assert(offsetof(BlitFramebufferCHROMIUM, dstX1) == 28,
              "offset of BlitFramebufferCHROMIUM dstX1 should be 28");
static_assert(offsetof(BlitFramebufferCHROMIUM, dstY1) == 32,
              "offset of BlitFramebufferCHROMIUM dstY1 should be 32");
static_assert(offsetof(BlitFramebufferCHROMIUM, mask) == 36,
              "offset of BlitFramebufferCHROMIUM mask should be 36");
static_assert(offsetof(BlitFramebufferCHROMIUM, filter) == 40,
              "offset of BlitFramebufferCHROMIUM filter should be 40");

// GL_CHROMIUM_framebuffer_multisample
struct RenderbufferStorageMultisampleCHROMIUM {
  typedef RenderbufferStorageMultisampleCHROMIUM ValueType;
  static const CommandId kCmdId = kRenderbufferStorageMultisampleCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizei _samples,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    samples = _samples;
    internalformat = _internalformat;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _samples,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _samples, _internalformat, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t samples;
  uint32_t internalformat;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(RenderbufferStorageMultisampleCHROMIUM) == 24,
              "size of RenderbufferStorageMultisampleCHROMIUM should be 24");
static_assert(
    offsetof(RenderbufferStorageMultisampleCHROMIUM, header) == 0,
    "offset of RenderbufferStorageMultisampleCHROMIUM header should be 0");
static_assert(
    offsetof(RenderbufferStorageMultisampleCHROMIUM, target) == 4,
    "offset of RenderbufferStorageMultisampleCHROMIUM target should be 4");
static_assert(
    offsetof(RenderbufferStorageMultisampleCHROMIUM, samples) == 8,
    "offset of RenderbufferStorageMultisampleCHROMIUM samples should be 8");
static_assert(offsetof(RenderbufferStorageMultisampleCHROMIUM,
                       internalformat) == 12,
              "offset of RenderbufferStorageMultisampleCHROMIUM internalformat "
              "should be 12");
static_assert(
    offsetof(RenderbufferStorageMultisampleCHROMIUM, width) == 16,
    "offset of RenderbufferStorageMultisampleCHROMIUM width should be 16");
static_assert(
    offsetof(RenderbufferStorageMultisampleCHROMIUM, height) == 20,
    "offset of RenderbufferStorageMultisampleCHROMIUM height should be 20");

// GL_EXT_multisampled_render_to_texture
struct RenderbufferStorageMultisampleEXT {
  typedef RenderbufferStorageMultisampleEXT ValueType;
  static const CommandId kCmdId = kRenderbufferStorageMultisampleEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizei _samples,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    samples = _samples;
    internalformat = _internalformat;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _samples,
            GLenum _internalformat,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _samples, _internalformat, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t samples;
  uint32_t internalformat;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(RenderbufferStorageMultisampleEXT) == 24,
              "size of RenderbufferStorageMultisampleEXT should be 24");
static_assert(offsetof(RenderbufferStorageMultisampleEXT, header) == 0,
              "offset of RenderbufferStorageMultisampleEXT header should be 0");
static_assert(offsetof(RenderbufferStorageMultisampleEXT, target) == 4,
              "offset of RenderbufferStorageMultisampleEXT target should be 4");
static_assert(
    offsetof(RenderbufferStorageMultisampleEXT, samples) == 8,
    "offset of RenderbufferStorageMultisampleEXT samples should be 8");
static_assert(
    offsetof(RenderbufferStorageMultisampleEXT, internalformat) == 12,
    "offset of RenderbufferStorageMultisampleEXT internalformat should be 12");
static_assert(offsetof(RenderbufferStorageMultisampleEXT, width) == 16,
              "offset of RenderbufferStorageMultisampleEXT width should be 16");
static_assert(
    offsetof(RenderbufferStorageMultisampleEXT, height) == 20,
    "offset of RenderbufferStorageMultisampleEXT height should be 20");

struct FramebufferTexture2DMultisampleEXT {
  typedef FramebufferTexture2DMultisampleEXT ValueType;
  static const CommandId kCmdId = kFramebufferTexture2DMultisampleEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _attachment,
            GLenum _textarget,
            GLuint _texture,
            GLsizei _samples) {
    SetHeader();
    target = _target;
    attachment = _attachment;
    textarget = _textarget;
    texture = _texture;
    samples = _samples;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _attachment,
            GLenum _textarget,
            GLuint _texture,
            GLsizei _samples) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _attachment, _textarget, _texture, _samples);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t attachment;
  uint32_t textarget;
  uint32_t texture;
  int32_t samples;
  static const int32_t level = 0;
};

static_assert(sizeof(FramebufferTexture2DMultisampleEXT) == 24,
              "size of FramebufferTexture2DMultisampleEXT should be 24");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, header) == 0,
    "offset of FramebufferTexture2DMultisampleEXT header should be 0");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, target) == 4,
    "offset of FramebufferTexture2DMultisampleEXT target should be 4");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, attachment) == 8,
    "offset of FramebufferTexture2DMultisampleEXT attachment should be 8");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, textarget) == 12,
    "offset of FramebufferTexture2DMultisampleEXT textarget should be 12");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, texture) == 16,
    "offset of FramebufferTexture2DMultisampleEXT texture should be 16");
static_assert(
    offsetof(FramebufferTexture2DMultisampleEXT, samples) == 20,
    "offset of FramebufferTexture2DMultisampleEXT samples should be 20");

struct TexStorage2DEXT {
  typedef TexStorage2DEXT ValueType;
  static const CommandId kCmdId = kTexStorage2DEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizei _levels,
            GLenum _internalFormat,
            GLsizei _width,
            GLsizei _height) {
    SetHeader();
    target = _target;
    levels = _levels;
    internalFormat = _internalFormat;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _levels,
            GLenum _internalFormat,
            GLsizei _width,
            GLsizei _height) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _levels, _internalFormat, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t levels;
  uint32_t internalFormat;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(TexStorage2DEXT) == 24,
              "size of TexStorage2DEXT should be 24");
static_assert(offsetof(TexStorage2DEXT, header) == 0,
              "offset of TexStorage2DEXT header should be 0");
static_assert(offsetof(TexStorage2DEXT, target) == 4,
              "offset of TexStorage2DEXT target should be 4");
static_assert(offsetof(TexStorage2DEXT, levels) == 8,
              "offset of TexStorage2DEXT levels should be 8");
static_assert(offsetof(TexStorage2DEXT, internalFormat) == 12,
              "offset of TexStorage2DEXT internalFormat should be 12");
static_assert(offsetof(TexStorage2DEXT, width) == 16,
              "offset of TexStorage2DEXT width should be 16");
static_assert(offsetof(TexStorage2DEXT, height) == 20,
              "offset of TexStorage2DEXT height should be 20");

struct GenQueriesEXTImmediate {
  typedef GenQueriesEXTImmediate ValueType;
  static const CommandId kCmdId = kGenQueriesEXTImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _queries) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _queries, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _queries) {
    static_cast<ValueType*>(cmd)->Init(_n, _queries);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenQueriesEXTImmediate) == 8,
              "size of GenQueriesEXTImmediate should be 8");
static_assert(offsetof(GenQueriesEXTImmediate, header) == 0,
              "offset of GenQueriesEXTImmediate header should be 0");
static_assert(offsetof(GenQueriesEXTImmediate, n) == 4,
              "offset of GenQueriesEXTImmediate n should be 4");

struct DeleteQueriesEXTImmediate {
  typedef DeleteQueriesEXTImmediate ValueType;
  static const CommandId kCmdId = kDeleteQueriesEXTImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _queries) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _queries, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _queries) {
    static_cast<ValueType*>(cmd)->Init(_n, _queries);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteQueriesEXTImmediate) == 8,
              "size of DeleteQueriesEXTImmediate should be 8");
static_assert(offsetof(DeleteQueriesEXTImmediate, header) == 0,
              "offset of DeleteQueriesEXTImmediate header should be 0");
static_assert(offsetof(DeleteQueriesEXTImmediate, n) == 4,
              "offset of DeleteQueriesEXTImmediate n should be 4");

struct BeginQueryEXT {
  typedef BeginQueryEXT ValueType;
  static const CommandId kCmdId = kBeginQueryEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLuint _id,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    SetHeader();
    target = _target;
    id = _id;
    sync_data_shm_id = _sync_data_shm_id;
    sync_data_shm_offset = _sync_data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLuint _id,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _id, _sync_data_shm_id, _sync_data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t id;
  uint32_t sync_data_shm_id;
  uint32_t sync_data_shm_offset;
};

static_assert(sizeof(BeginQueryEXT) == 20,
              "size of BeginQueryEXT should be 20");
static_assert(offsetof(BeginQueryEXT, header) == 0,
              "offset of BeginQueryEXT header should be 0");
static_assert(offsetof(BeginQueryEXT, target) == 4,
              "offset of BeginQueryEXT target should be 4");
static_assert(offsetof(BeginQueryEXT, id) == 8,
              "offset of BeginQueryEXT id should be 8");
static_assert(offsetof(BeginQueryEXT, sync_data_shm_id) == 12,
              "offset of BeginQueryEXT sync_data_shm_id should be 12");
static_assert(offsetof(BeginQueryEXT, sync_data_shm_offset) == 16,
              "offset of BeginQueryEXT sync_data_shm_offset should be 16");

struct BeginTransformFeedback {
  typedef BeginTransformFeedback ValueType;
  static const CommandId kCmdId = kBeginTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _primitivemode) {
    SetHeader();
    primitivemode = _primitivemode;
  }

  void* Set(void* cmd, GLenum _primitivemode) {
    static_cast<ValueType*>(cmd)->Init(_primitivemode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t primitivemode;
};

static_assert(sizeof(BeginTransformFeedback) == 8,
              "size of BeginTransformFeedback should be 8");
static_assert(offsetof(BeginTransformFeedback, header) == 0,
              "offset of BeginTransformFeedback header should be 0");
static_assert(offsetof(BeginTransformFeedback, primitivemode) == 4,
              "offset of BeginTransformFeedback primitivemode should be 4");

struct EndQueryEXT {
  typedef EndQueryEXT ValueType;
  static const CommandId kCmdId = kEndQueryEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _submit_count) {
    SetHeader();
    target = _target;
    submit_count = _submit_count;
  }

  void* Set(void* cmd, GLenum _target, GLuint _submit_count) {
    static_cast<ValueType*>(cmd)->Init(_target, _submit_count);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t submit_count;
};

static_assert(sizeof(EndQueryEXT) == 12, "size of EndQueryEXT should be 12");
static_assert(offsetof(EndQueryEXT, header) == 0,
              "offset of EndQueryEXT header should be 0");
static_assert(offsetof(EndQueryEXT, target) == 4,
              "offset of EndQueryEXT target should be 4");
static_assert(offsetof(EndQueryEXT, submit_count) == 8,
              "offset of EndQueryEXT submit_count should be 8");

struct EndTransformFeedback {
  typedef EndTransformFeedback ValueType;
  static const CommandId kCmdId = kEndTransformFeedback;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(EndTransformFeedback) == 4,
              "size of EndTransformFeedback should be 4");
static_assert(offsetof(EndTransformFeedback, header) == 0,
              "offset of EndTransformFeedback header should be 0");

struct InsertEventMarkerEXT {
  typedef InsertEventMarkerEXT ValueType;
  static const CommandId kCmdId = kInsertEventMarkerEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _bucket_id) {
    SetHeader();
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t bucket_id;
};

static_assert(sizeof(InsertEventMarkerEXT) == 8,
              "size of InsertEventMarkerEXT should be 8");
static_assert(offsetof(InsertEventMarkerEXT, header) == 0,
              "offset of InsertEventMarkerEXT header should be 0");
static_assert(offsetof(InsertEventMarkerEXT, bucket_id) == 4,
              "offset of InsertEventMarkerEXT bucket_id should be 4");

struct PushGroupMarkerEXT {
  typedef PushGroupMarkerEXT ValueType;
  static const CommandId kCmdId = kPushGroupMarkerEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _bucket_id) {
    SetHeader();
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t bucket_id;
};

static_assert(sizeof(PushGroupMarkerEXT) == 8,
              "size of PushGroupMarkerEXT should be 8");
static_assert(offsetof(PushGroupMarkerEXT, header) == 0,
              "offset of PushGroupMarkerEXT header should be 0");
static_assert(offsetof(PushGroupMarkerEXT, bucket_id) == 4,
              "offset of PushGroupMarkerEXT bucket_id should be 4");

struct PopGroupMarkerEXT {
  typedef PopGroupMarkerEXT ValueType;
  static const CommandId kCmdId = kPopGroupMarkerEXT;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(PopGroupMarkerEXT) == 4,
              "size of PopGroupMarkerEXT should be 4");
static_assert(offsetof(PopGroupMarkerEXT, header) == 0,
              "offset of PopGroupMarkerEXT header should be 0");

struct GenVertexArraysOESImmediate {
  typedef GenVertexArraysOESImmediate ValueType;
  static const CommandId kCmdId = kGenVertexArraysOESImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _arrays) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _arrays, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _arrays) {
    static_cast<ValueType*>(cmd)->Init(_n, _arrays);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenVertexArraysOESImmediate) == 8,
              "size of GenVertexArraysOESImmediate should be 8");
static_assert(offsetof(GenVertexArraysOESImmediate, header) == 0,
              "offset of GenVertexArraysOESImmediate header should be 0");
static_assert(offsetof(GenVertexArraysOESImmediate, n) == 4,
              "offset of GenVertexArraysOESImmediate n should be 4");

struct DeleteVertexArraysOESImmediate {
  typedef DeleteVertexArraysOESImmediate ValueType;
  static const CommandId kCmdId = kDeleteVertexArraysOESImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _arrays) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _arrays, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _arrays) {
    static_cast<ValueType*>(cmd)->Init(_n, _arrays);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteVertexArraysOESImmediate) == 8,
              "size of DeleteVertexArraysOESImmediate should be 8");
static_assert(offsetof(DeleteVertexArraysOESImmediate, header) == 0,
              "offset of DeleteVertexArraysOESImmediate header should be 0");
static_assert(offsetof(DeleteVertexArraysOESImmediate, n) == 4,
              "offset of DeleteVertexArraysOESImmediate n should be 4");

struct IsVertexArrayOES {
  typedef IsVertexArrayOES ValueType;
  static const CommandId kCmdId = kIsVertexArrayOES;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _array,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    array = _array;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _array,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_array, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t array;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsVertexArrayOES) == 16,
              "size of IsVertexArrayOES should be 16");
static_assert(offsetof(IsVertexArrayOES, header) == 0,
              "offset of IsVertexArrayOES header should be 0");
static_assert(offsetof(IsVertexArrayOES, array) == 4,
              "offset of IsVertexArrayOES array should be 4");
static_assert(offsetof(IsVertexArrayOES, result_shm_id) == 8,
              "offset of IsVertexArrayOES result_shm_id should be 8");
static_assert(offsetof(IsVertexArrayOES, result_shm_offset) == 12,
              "offset of IsVertexArrayOES result_shm_offset should be 12");

struct BindVertexArrayOES {
  typedef BindVertexArrayOES ValueType;
  static const CommandId kCmdId = kBindVertexArrayOES;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _array) {
    SetHeader();
    array = _array;
  }

  void* Set(void* cmd, GLuint _array) {
    static_cast<ValueType*>(cmd)->Init(_array);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t array;
};

static_assert(sizeof(BindVertexArrayOES) == 8,
              "size of BindVertexArrayOES should be 8");
static_assert(offsetof(BindVertexArrayOES, header) == 0,
              "offset of BindVertexArrayOES header should be 0");
static_assert(offsetof(BindVertexArrayOES, array) == 4,
              "offset of BindVertexArrayOES array should be 4");

struct SwapBuffers {
  typedef SwapBuffers ValueType;
  static const CommandId kCmdId = kSwapBuffers;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(SwapBuffers) == 4, "size of SwapBuffers should be 4");
static_assert(offsetof(SwapBuffers, header) == 0,
              "offset of SwapBuffers header should be 0");

struct GetMaxValueInBufferCHROMIUM {
  typedef GetMaxValueInBufferCHROMIUM ValueType;
  static const CommandId kCmdId = kGetMaxValueInBufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLuint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _buffer_id,
            GLsizei _count,
            GLenum _type,
            GLuint _offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    buffer_id = _buffer_id;
    count = _count;
    type = _type;
    offset = _offset;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _buffer_id,
            GLsizei _count,
            GLenum _type,
            GLuint _offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_buffer_id, _count, _type, _offset,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t buffer_id;
  int32_t count;
  uint32_t type;
  uint32_t offset;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(GetMaxValueInBufferCHROMIUM) == 28,
              "size of GetMaxValueInBufferCHROMIUM should be 28");
static_assert(offsetof(GetMaxValueInBufferCHROMIUM, header) == 0,
              "offset of GetMaxValueInBufferCHROMIUM header should be 0");
static_assert(offsetof(GetMaxValueInBufferCHROMIUM, buffer_id) == 4,
              "offset of GetMaxValueInBufferCHROMIUM buffer_id should be 4");
static_assert(offsetof(GetMaxValueInBufferCHROMIUM, count) == 8,
              "offset of GetMaxValueInBufferCHROMIUM count should be 8");
static_assert(offsetof(GetMaxValueInBufferCHROMIUM, type) == 12,
              "offset of GetMaxValueInBufferCHROMIUM type should be 12");
static_assert(offsetof(GetMaxValueInBufferCHROMIUM, offset) == 16,
              "offset of GetMaxValueInBufferCHROMIUM offset should be 16");
static_assert(
    offsetof(GetMaxValueInBufferCHROMIUM, result_shm_id) == 20,
    "offset of GetMaxValueInBufferCHROMIUM result_shm_id should be 20");
static_assert(
    offsetof(GetMaxValueInBufferCHROMIUM, result_shm_offset) == 24,
    "offset of GetMaxValueInBufferCHROMIUM result_shm_offset should be 24");

struct EnableFeatureCHROMIUM {
  typedef EnableFeatureCHROMIUM ValueType;
  static const CommandId kCmdId = kEnableFeatureCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef GLint Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    bucket_id = _bucket_id;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _bucket_id,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_bucket_id, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t bucket_id;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(EnableFeatureCHROMIUM) == 16,
              "size of EnableFeatureCHROMIUM should be 16");
static_assert(offsetof(EnableFeatureCHROMIUM, header) == 0,
              "offset of EnableFeatureCHROMIUM header should be 0");
static_assert(offsetof(EnableFeatureCHROMIUM, bucket_id) == 4,
              "offset of EnableFeatureCHROMIUM bucket_id should be 4");
static_assert(offsetof(EnableFeatureCHROMIUM, result_shm_id) == 8,
              "offset of EnableFeatureCHROMIUM result_shm_id should be 8");
static_assert(offsetof(EnableFeatureCHROMIUM, result_shm_offset) == 12,
              "offset of EnableFeatureCHROMIUM result_shm_offset should be 12");

struct MapBufferRange {
  typedef MapBufferRange ValueType;
  static const CommandId kCmdId = kMapBufferRange;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLintptr _offset,
            GLsizeiptr _size,
            GLbitfield _access,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    target = _target;
    offset = _offset;
    size = _size;
    access = _access;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLintptr _offset,
            GLsizeiptr _size,
            GLbitfield _access,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)->Init(_target, _offset, _size, _access,
                                       _data_shm_id, _data_shm_offset,
                                       _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t offset;
  int32_t size;
  uint32_t access;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(MapBufferRange) == 36,
              "size of MapBufferRange should be 36");
static_assert(offsetof(MapBufferRange, header) == 0,
              "offset of MapBufferRange header should be 0");
static_assert(offsetof(MapBufferRange, target) == 4,
              "offset of MapBufferRange target should be 4");
static_assert(offsetof(MapBufferRange, offset) == 8,
              "offset of MapBufferRange offset should be 8");
static_assert(offsetof(MapBufferRange, size) == 12,
              "offset of MapBufferRange size should be 12");
static_assert(offsetof(MapBufferRange, access) == 16,
              "offset of MapBufferRange access should be 16");
static_assert(offsetof(MapBufferRange, data_shm_id) == 20,
              "offset of MapBufferRange data_shm_id should be 20");
static_assert(offsetof(MapBufferRange, data_shm_offset) == 24,
              "offset of MapBufferRange data_shm_offset should be 24");
static_assert(offsetof(MapBufferRange, result_shm_id) == 28,
              "offset of MapBufferRange result_shm_id should be 28");
static_assert(offsetof(MapBufferRange, result_shm_offset) == 32,
              "offset of MapBufferRange result_shm_offset should be 32");

struct UnmapBuffer {
  typedef UnmapBuffer ValueType;
  static const CommandId kCmdId = kUnmapBuffer;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target) {
    SetHeader();
    target = _target;
  }

  void* Set(void* cmd, GLenum _target) {
    static_cast<ValueType*>(cmd)->Init(_target);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(UnmapBuffer) == 8, "size of UnmapBuffer should be 8");
static_assert(offsetof(UnmapBuffer, header) == 0,
              "offset of UnmapBuffer header should be 0");
static_assert(offsetof(UnmapBuffer, target) == 4,
              "offset of UnmapBuffer target should be 4");

struct ResizeCHROMIUM {
  typedef ResizeCHROMIUM ValueType;
  static const CommandId kCmdId = kResizeCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _width, GLuint _height, GLfloat _scale_factor) {
    SetHeader();
    width = _width;
    height = _height;
    scale_factor = _scale_factor;
  }

  void* Set(void* cmd, GLuint _width, GLuint _height, GLfloat _scale_factor) {
    static_cast<ValueType*>(cmd)->Init(_width, _height, _scale_factor);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t width;
  uint32_t height;
  float scale_factor;
};

static_assert(sizeof(ResizeCHROMIUM) == 16,
              "size of ResizeCHROMIUM should be 16");
static_assert(offsetof(ResizeCHROMIUM, header) == 0,
              "offset of ResizeCHROMIUM header should be 0");
static_assert(offsetof(ResizeCHROMIUM, width) == 4,
              "offset of ResizeCHROMIUM width should be 4");
static_assert(offsetof(ResizeCHROMIUM, height) == 8,
              "offset of ResizeCHROMIUM height should be 8");
static_assert(offsetof(ResizeCHROMIUM, scale_factor) == 12,
              "offset of ResizeCHROMIUM scale_factor should be 12");

struct GetRequestableExtensionsCHROMIUM {
  typedef GetRequestableExtensionsCHROMIUM ValueType;
  static const CommandId kCmdId = kGetRequestableExtensionsCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(uint32_t _bucket_id) {
    SetHeader();
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t bucket_id;
};

static_assert(sizeof(GetRequestableExtensionsCHROMIUM) == 8,
              "size of GetRequestableExtensionsCHROMIUM should be 8");
static_assert(offsetof(GetRequestableExtensionsCHROMIUM, header) == 0,
              "offset of GetRequestableExtensionsCHROMIUM header should be 0");
static_assert(
    offsetof(GetRequestableExtensionsCHROMIUM, bucket_id) == 4,
    "offset of GetRequestableExtensionsCHROMIUM bucket_id should be 4");

struct RequestExtensionCHROMIUM {
  typedef RequestExtensionCHROMIUM ValueType;
  static const CommandId kCmdId = kRequestExtensionCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(uint32_t _bucket_id) {
    SetHeader();
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t bucket_id;
};

static_assert(sizeof(RequestExtensionCHROMIUM) == 8,
              "size of RequestExtensionCHROMIUM should be 8");
static_assert(offsetof(RequestExtensionCHROMIUM, header) == 0,
              "offset of RequestExtensionCHROMIUM header should be 0");
static_assert(offsetof(RequestExtensionCHROMIUM, bucket_id) == 4,
              "offset of RequestExtensionCHROMIUM bucket_id should be 4");

struct GetProgramInfoCHROMIUM {
  typedef GetProgramInfoCHROMIUM ValueType;
  static const CommandId kCmdId = kGetProgramInfoCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  struct Result {
    uint32_t link_status;
    uint32_t num_attribs;
    uint32_t num_uniforms;
  };

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _bucket_id) {
    SetHeader();
    program = _program;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _program, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t bucket_id;
};

static_assert(sizeof(GetProgramInfoCHROMIUM) == 12,
              "size of GetProgramInfoCHROMIUM should be 12");
static_assert(offsetof(GetProgramInfoCHROMIUM, header) == 0,
              "offset of GetProgramInfoCHROMIUM header should be 0");
static_assert(offsetof(GetProgramInfoCHROMIUM, program) == 4,
              "offset of GetProgramInfoCHROMIUM program should be 4");
static_assert(offsetof(GetProgramInfoCHROMIUM, bucket_id) == 8,
              "offset of GetProgramInfoCHROMIUM bucket_id should be 8");
static_assert(offsetof(GetProgramInfoCHROMIUM::Result, link_status) == 0,
              "offset of GetProgramInfoCHROMIUM Result link_status should be "
              "0");
static_assert(offsetof(GetProgramInfoCHROMIUM::Result, num_attribs) == 4,
              "offset of GetProgramInfoCHROMIUM Result num_attribs should be "
              "4");
static_assert(offsetof(GetProgramInfoCHROMIUM::Result, num_uniforms) == 8,
              "offset of GetProgramInfoCHROMIUM Result num_uniforms should be "
              "8");

struct GetUniformBlocksCHROMIUM {
  typedef GetUniformBlocksCHROMIUM ValueType;
  static const CommandId kCmdId = kGetUniformBlocksCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _bucket_id) {
    SetHeader();
    program = _program;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _program, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t bucket_id;
};

static_assert(sizeof(GetUniformBlocksCHROMIUM) == 12,
              "size of GetUniformBlocksCHROMIUM should be 12");
static_assert(offsetof(GetUniformBlocksCHROMIUM, header) == 0,
              "offset of GetUniformBlocksCHROMIUM header should be 0");
static_assert(offsetof(GetUniformBlocksCHROMIUM, program) == 4,
              "offset of GetUniformBlocksCHROMIUM program should be 4");
static_assert(offsetof(GetUniformBlocksCHROMIUM, bucket_id) == 8,
              "offset of GetUniformBlocksCHROMIUM bucket_id should be 8");

struct GetTransformFeedbackVaryingsCHROMIUM {
  typedef GetTransformFeedbackVaryingsCHROMIUM ValueType;
  static const CommandId kCmdId = kGetTransformFeedbackVaryingsCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _bucket_id) {
    SetHeader();
    program = _program;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _program, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t bucket_id;
};

static_assert(sizeof(GetTransformFeedbackVaryingsCHROMIUM) == 12,
              "size of GetTransformFeedbackVaryingsCHROMIUM should be 12");
static_assert(
    offsetof(GetTransformFeedbackVaryingsCHROMIUM, header) == 0,
    "offset of GetTransformFeedbackVaryingsCHROMIUM header should be 0");
static_assert(
    offsetof(GetTransformFeedbackVaryingsCHROMIUM, program) == 4,
    "offset of GetTransformFeedbackVaryingsCHROMIUM program should be 4");
static_assert(
    offsetof(GetTransformFeedbackVaryingsCHROMIUM, bucket_id) == 8,
    "offset of GetTransformFeedbackVaryingsCHROMIUM bucket_id should be 8");

struct GetUniformsES3CHROMIUM {
  typedef GetUniformsES3CHROMIUM ValueType;
  static const CommandId kCmdId = kGetUniformsES3CHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, uint32_t _bucket_id) {
    SetHeader();
    program = _program;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _program, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  uint32_t bucket_id;
};

static_assert(sizeof(GetUniformsES3CHROMIUM) == 12,
              "size of GetUniformsES3CHROMIUM should be 12");
static_assert(offsetof(GetUniformsES3CHROMIUM, header) == 0,
              "offset of GetUniformsES3CHROMIUM header should be 0");
static_assert(offsetof(GetUniformsES3CHROMIUM, program) == 4,
              "offset of GetUniformsES3CHROMIUM program should be 4");
static_assert(offsetof(GetUniformsES3CHROMIUM, bucket_id) == 8,
              "offset of GetUniformsES3CHROMIUM bucket_id should be 8");

struct GetTranslatedShaderSourceANGLE {
  typedef GetTranslatedShaderSourceANGLE ValueType;
  static const CommandId kCmdId = kGetTranslatedShaderSourceANGLE;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _shader, uint32_t _bucket_id) {
    SetHeader();
    shader = _shader;
    bucket_id = _bucket_id;
  }

  void* Set(void* cmd, GLuint _shader, uint32_t _bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_shader, _bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t shader;
  uint32_t bucket_id;
};

static_assert(sizeof(GetTranslatedShaderSourceANGLE) == 12,
              "size of GetTranslatedShaderSourceANGLE should be 12");
static_assert(offsetof(GetTranslatedShaderSourceANGLE, header) == 0,
              "offset of GetTranslatedShaderSourceANGLE header should be 0");
static_assert(offsetof(GetTranslatedShaderSourceANGLE, shader) == 4,
              "offset of GetTranslatedShaderSourceANGLE shader should be 4");
static_assert(offsetof(GetTranslatedShaderSourceANGLE, bucket_id) == 8,
              "offset of GetTranslatedShaderSourceANGLE bucket_id should be 8");

struct PostSubBufferCHROMIUM {
  typedef PostSubBufferCHROMIUM ValueType;
  static const CommandId kCmdId = kPostSubBufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _x, GLint _y, GLint _width, GLint _height) {
    SetHeader();
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  void* Set(void* cmd, GLint _x, GLint _y, GLint _width, GLint _height) {
    static_cast<ValueType*>(cmd)->Init(_x, _y, _width, _height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

static_assert(sizeof(PostSubBufferCHROMIUM) == 20,
              "size of PostSubBufferCHROMIUM should be 20");
static_assert(offsetof(PostSubBufferCHROMIUM, header) == 0,
              "offset of PostSubBufferCHROMIUM header should be 0");
static_assert(offsetof(PostSubBufferCHROMIUM, x) == 4,
              "offset of PostSubBufferCHROMIUM x should be 4");
static_assert(offsetof(PostSubBufferCHROMIUM, y) == 8,
              "offset of PostSubBufferCHROMIUM y should be 8");
static_assert(offsetof(PostSubBufferCHROMIUM, width) == 12,
              "offset of PostSubBufferCHROMIUM width should be 12");
static_assert(offsetof(PostSubBufferCHROMIUM, height) == 16,
              "offset of PostSubBufferCHROMIUM height should be 16");

struct TexImageIOSurface2DCHROMIUM {
  typedef TexImageIOSurface2DCHROMIUM ValueType;
  static const CommandId kCmdId = kTexImageIOSurface2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLsizei _width,
            GLsizei _height,
            GLuint _ioSurfaceId,
            GLuint _plane) {
    SetHeader();
    target = _target;
    width = _width;
    height = _height;
    ioSurfaceId = _ioSurfaceId;
    plane = _plane;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _width,
            GLsizei _height,
            GLuint _ioSurfaceId,
            GLuint _plane) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _width, _height, _ioSurfaceId, _plane);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t width;
  int32_t height;
  uint32_t ioSurfaceId;
  uint32_t plane;
};

static_assert(sizeof(TexImageIOSurface2DCHROMIUM) == 24,
              "size of TexImageIOSurface2DCHROMIUM should be 24");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, header) == 0,
              "offset of TexImageIOSurface2DCHROMIUM header should be 0");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, target) == 4,
              "offset of TexImageIOSurface2DCHROMIUM target should be 4");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, width) == 8,
              "offset of TexImageIOSurface2DCHROMIUM width should be 8");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, height) == 12,
              "offset of TexImageIOSurface2DCHROMIUM height should be 12");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, ioSurfaceId) == 16,
              "offset of TexImageIOSurface2DCHROMIUM ioSurfaceId should be 16");
static_assert(offsetof(TexImageIOSurface2DCHROMIUM, plane) == 20,
              "offset of TexImageIOSurface2DCHROMIUM plane should be 20");

struct CopyTextureCHROMIUM {
  typedef CopyTextureCHROMIUM ValueType;
  static const CommandId kCmdId = kCopyTextureCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _source_id,
            GLenum _dest_id,
            GLint _internalformat,
            GLenum _dest_type) {
    SetHeader();
    target = _target;
    source_id = _source_id;
    dest_id = _dest_id;
    internalformat = _internalformat;
    dest_type = _dest_type;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _source_id,
            GLenum _dest_id,
            GLint _internalformat,
            GLenum _dest_type) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _source_id, _dest_id, _internalformat, _dest_type);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t source_id;
  uint32_t dest_id;
  int32_t internalformat;
  uint32_t dest_type;
};

static_assert(sizeof(CopyTextureCHROMIUM) == 24,
              "size of CopyTextureCHROMIUM should be 24");
static_assert(offsetof(CopyTextureCHROMIUM, header) == 0,
              "offset of CopyTextureCHROMIUM header should be 0");
static_assert(offsetof(CopyTextureCHROMIUM, target) == 4,
              "offset of CopyTextureCHROMIUM target should be 4");
static_assert(offsetof(CopyTextureCHROMIUM, source_id) == 8,
              "offset of CopyTextureCHROMIUM source_id should be 8");
static_assert(offsetof(CopyTextureCHROMIUM, dest_id) == 12,
              "offset of CopyTextureCHROMIUM dest_id should be 12");
static_assert(offsetof(CopyTextureCHROMIUM, internalformat) == 16,
              "offset of CopyTextureCHROMIUM internalformat should be 16");
static_assert(offsetof(CopyTextureCHROMIUM, dest_type) == 20,
              "offset of CopyTextureCHROMIUM dest_type should be 20");

struct CopySubTextureCHROMIUM {
  typedef CopySubTextureCHROMIUM ValueType;
  static const CommandId kCmdId = kCopySubTextureCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLenum _source_id,
            GLenum _dest_id,
            GLint _xoffset,
            GLint _yoffset) {
    SetHeader();
    target = _target;
    source_id = _source_id;
    dest_id = _dest_id;
    xoffset = _xoffset;
    yoffset = _yoffset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLenum _source_id,
            GLenum _dest_id,
            GLint _xoffset,
            GLint _yoffset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _source_id, _dest_id, _xoffset, _yoffset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t source_id;
  uint32_t dest_id;
  int32_t xoffset;
  int32_t yoffset;
};

static_assert(sizeof(CopySubTextureCHROMIUM) == 24,
              "size of CopySubTextureCHROMIUM should be 24");
static_assert(offsetof(CopySubTextureCHROMIUM, header) == 0,
              "offset of CopySubTextureCHROMIUM header should be 0");
static_assert(offsetof(CopySubTextureCHROMIUM, target) == 4,
              "offset of CopySubTextureCHROMIUM target should be 4");
static_assert(offsetof(CopySubTextureCHROMIUM, source_id) == 8,
              "offset of CopySubTextureCHROMIUM source_id should be 8");
static_assert(offsetof(CopySubTextureCHROMIUM, dest_id) == 12,
              "offset of CopySubTextureCHROMIUM dest_id should be 12");
static_assert(offsetof(CopySubTextureCHROMIUM, xoffset) == 16,
              "offset of CopySubTextureCHROMIUM xoffset should be 16");
static_assert(offsetof(CopySubTextureCHROMIUM, yoffset) == 20,
              "offset of CopySubTextureCHROMIUM yoffset should be 20");

struct DrawArraysInstancedANGLE {
  typedef DrawArraysInstancedANGLE ValueType;
  static const CommandId kCmdId = kDrawArraysInstancedANGLE;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode, GLint _first, GLsizei _count, GLsizei _primcount) {
    SetHeader();
    mode = _mode;
    first = _first;
    count = _count;
    primcount = _primcount;
  }

  void* Set(void* cmd,
            GLenum _mode,
            GLint _first,
            GLsizei _count,
            GLsizei _primcount) {
    static_cast<ValueType*>(cmd)->Init(_mode, _first, _count, _primcount);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
  int32_t first;
  int32_t count;
  int32_t primcount;
};

static_assert(sizeof(DrawArraysInstancedANGLE) == 20,
              "size of DrawArraysInstancedANGLE should be 20");
static_assert(offsetof(DrawArraysInstancedANGLE, header) == 0,
              "offset of DrawArraysInstancedANGLE header should be 0");
static_assert(offsetof(DrawArraysInstancedANGLE, mode) == 4,
              "offset of DrawArraysInstancedANGLE mode should be 4");
static_assert(offsetof(DrawArraysInstancedANGLE, first) == 8,
              "offset of DrawArraysInstancedANGLE first should be 8");
static_assert(offsetof(DrawArraysInstancedANGLE, count) == 12,
              "offset of DrawArraysInstancedANGLE count should be 12");
static_assert(offsetof(DrawArraysInstancedANGLE, primcount) == 16,
              "offset of DrawArraysInstancedANGLE primcount should be 16");

struct DrawElementsInstancedANGLE {
  typedef DrawElementsInstancedANGLE ValueType;
  static const CommandId kCmdId = kDrawElementsInstancedANGLE;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _mode,
            GLsizei _count,
            GLenum _type,
            GLuint _index_offset,
            GLsizei _primcount) {
    SetHeader();
    mode = _mode;
    count = _count;
    type = _type;
    index_offset = _index_offset;
    primcount = _primcount;
  }

  void* Set(void* cmd,
            GLenum _mode,
            GLsizei _count,
            GLenum _type,
            GLuint _index_offset,
            GLsizei _primcount) {
    static_cast<ValueType*>(cmd)
        ->Init(_mode, _count, _type, _index_offset, _primcount);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t mode;
  int32_t count;
  uint32_t type;
  uint32_t index_offset;
  int32_t primcount;
};

static_assert(sizeof(DrawElementsInstancedANGLE) == 24,
              "size of DrawElementsInstancedANGLE should be 24");
static_assert(offsetof(DrawElementsInstancedANGLE, header) == 0,
              "offset of DrawElementsInstancedANGLE header should be 0");
static_assert(offsetof(DrawElementsInstancedANGLE, mode) == 4,
              "offset of DrawElementsInstancedANGLE mode should be 4");
static_assert(offsetof(DrawElementsInstancedANGLE, count) == 8,
              "offset of DrawElementsInstancedANGLE count should be 8");
static_assert(offsetof(DrawElementsInstancedANGLE, type) == 12,
              "offset of DrawElementsInstancedANGLE type should be 12");
static_assert(offsetof(DrawElementsInstancedANGLE, index_offset) == 16,
              "offset of DrawElementsInstancedANGLE index_offset should be 16");
static_assert(offsetof(DrawElementsInstancedANGLE, primcount) == 20,
              "offset of DrawElementsInstancedANGLE primcount should be 20");

struct VertexAttribDivisorANGLE {
  typedef VertexAttribDivisorANGLE ValueType;
  static const CommandId kCmdId = kVertexAttribDivisorANGLE;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _index, GLuint _divisor) {
    SetHeader();
    index = _index;
    divisor = _divisor;
  }

  void* Set(void* cmd, GLuint _index, GLuint _divisor) {
    static_cast<ValueType*>(cmd)->Init(_index, _divisor);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t index;
  uint32_t divisor;
};

static_assert(sizeof(VertexAttribDivisorANGLE) == 12,
              "size of VertexAttribDivisorANGLE should be 12");
static_assert(offsetof(VertexAttribDivisorANGLE, header) == 0,
              "offset of VertexAttribDivisorANGLE header should be 0");
static_assert(offsetof(VertexAttribDivisorANGLE, index) == 4,
              "offset of VertexAttribDivisorANGLE index should be 4");
static_assert(offsetof(VertexAttribDivisorANGLE, divisor) == 8,
              "offset of VertexAttribDivisorANGLE divisor should be 8");

struct ProduceTextureCHROMIUMImmediate {
  typedef ProduceTextureCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kProduceTextureCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLbyte) * 64);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _target, const GLbyte* _mailbox) {
    SetHeader();
    target = _target;
    memcpy(ImmediateDataAddress(this), _mailbox, ComputeDataSize());
  }

  void* Set(void* cmd, GLenum _target, const GLbyte* _mailbox) {
    static_cast<ValueType*>(cmd)->Init(_target, _mailbox);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(ProduceTextureCHROMIUMImmediate) == 8,
              "size of ProduceTextureCHROMIUMImmediate should be 8");
static_assert(offsetof(ProduceTextureCHROMIUMImmediate, header) == 0,
              "offset of ProduceTextureCHROMIUMImmediate header should be 0");
static_assert(offsetof(ProduceTextureCHROMIUMImmediate, target) == 4,
              "offset of ProduceTextureCHROMIUMImmediate target should be 4");

struct ProduceTextureDirectCHROMIUMImmediate {
  typedef ProduceTextureDirectCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kProduceTextureDirectCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLbyte) * 64);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLuint _texture, GLenum _target, const GLbyte* _mailbox) {
    SetHeader();
    texture = _texture;
    target = _target;
    memcpy(ImmediateDataAddress(this), _mailbox, ComputeDataSize());
  }

  void* Set(void* cmd,
            GLuint _texture,
            GLenum _target,
            const GLbyte* _mailbox) {
    static_cast<ValueType*>(cmd)->Init(_texture, _target, _mailbox);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t texture;
  uint32_t target;
};

static_assert(sizeof(ProduceTextureDirectCHROMIUMImmediate) == 12,
              "size of ProduceTextureDirectCHROMIUMImmediate should be 12");
static_assert(
    offsetof(ProduceTextureDirectCHROMIUMImmediate, header) == 0,
    "offset of ProduceTextureDirectCHROMIUMImmediate header should be 0");
static_assert(
    offsetof(ProduceTextureDirectCHROMIUMImmediate, texture) == 4,
    "offset of ProduceTextureDirectCHROMIUMImmediate texture should be 4");
static_assert(
    offsetof(ProduceTextureDirectCHROMIUMImmediate, target) == 8,
    "offset of ProduceTextureDirectCHROMIUMImmediate target should be 8");

struct ConsumeTextureCHROMIUMImmediate {
  typedef ConsumeTextureCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kConsumeTextureCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLbyte) * 64);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _target, const GLbyte* _mailbox) {
    SetHeader();
    target = _target;
    memcpy(ImmediateDataAddress(this), _mailbox, ComputeDataSize());
  }

  void* Set(void* cmd, GLenum _target, const GLbyte* _mailbox) {
    static_cast<ValueType*>(cmd)->Init(_target, _mailbox);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(ConsumeTextureCHROMIUMImmediate) == 8,
              "size of ConsumeTextureCHROMIUMImmediate should be 8");
static_assert(offsetof(ConsumeTextureCHROMIUMImmediate, header) == 0,
              "offset of ConsumeTextureCHROMIUMImmediate header should be 0");
static_assert(offsetof(ConsumeTextureCHROMIUMImmediate, target) == 4,
              "offset of ConsumeTextureCHROMIUMImmediate target should be 4");

struct BindUniformLocationCHROMIUMBucket {
  typedef BindUniformLocationCHROMIUMBucket ValueType;
  static const CommandId kCmdId = kBindUniformLocationCHROMIUMBucket;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _program, GLint _location, uint32_t _name_bucket_id) {
    SetHeader();
    program = _program;
    location = _location;
    name_bucket_id = _name_bucket_id;
  }

  void* Set(void* cmd,
            GLuint _program,
            GLint _location,
            uint32_t _name_bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_program, _location, _name_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t program;
  int32_t location;
  uint32_t name_bucket_id;
};

static_assert(sizeof(BindUniformLocationCHROMIUMBucket) == 16,
              "size of BindUniformLocationCHROMIUMBucket should be 16");
static_assert(offsetof(BindUniformLocationCHROMIUMBucket, header) == 0,
              "offset of BindUniformLocationCHROMIUMBucket header should be 0");
static_assert(
    offsetof(BindUniformLocationCHROMIUMBucket, program) == 4,
    "offset of BindUniformLocationCHROMIUMBucket program should be 4");
static_assert(
    offsetof(BindUniformLocationCHROMIUMBucket, location) == 8,
    "offset of BindUniformLocationCHROMIUMBucket location should be 8");
static_assert(
    offsetof(BindUniformLocationCHROMIUMBucket, name_bucket_id) == 12,
    "offset of BindUniformLocationCHROMIUMBucket name_bucket_id should be 12");

struct GenValuebuffersCHROMIUMImmediate {
  typedef GenValuebuffersCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kGenValuebuffersCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, GLuint* _buffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _buffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, GLuint* _buffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _buffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(GenValuebuffersCHROMIUMImmediate) == 8,
              "size of GenValuebuffersCHROMIUMImmediate should be 8");
static_assert(offsetof(GenValuebuffersCHROMIUMImmediate, header) == 0,
              "offset of GenValuebuffersCHROMIUMImmediate header should be 0");
static_assert(offsetof(GenValuebuffersCHROMIUMImmediate, n) == 4,
              "offset of GenValuebuffersCHROMIUMImmediate n should be 4");

struct DeleteValuebuffersCHROMIUMImmediate {
  typedef DeleteValuebuffersCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kDeleteValuebuffersCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei n) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(n));  // NOLINT
  }

  void SetHeader(GLsizei n) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));
  }

  void Init(GLsizei _n, const GLuint* _valuebuffers) {
    SetHeader(_n);
    n = _n;
    memcpy(ImmediateDataAddress(this), _valuebuffers, ComputeDataSize(_n));
  }

  void* Set(void* cmd, GLsizei _n, const GLuint* _valuebuffers) {
    static_cast<ValueType*>(cmd)->Init(_n, _valuebuffers);
    const uint32_t size = ComputeSize(_n);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t n;
};

static_assert(sizeof(DeleteValuebuffersCHROMIUMImmediate) == 8,
              "size of DeleteValuebuffersCHROMIUMImmediate should be 8");
static_assert(
    offsetof(DeleteValuebuffersCHROMIUMImmediate, header) == 0,
    "offset of DeleteValuebuffersCHROMIUMImmediate header should be 0");
static_assert(offsetof(DeleteValuebuffersCHROMIUMImmediate, n) == 4,
              "offset of DeleteValuebuffersCHROMIUMImmediate n should be 4");

struct IsValuebufferCHROMIUM {
  typedef IsValuebufferCHROMIUM ValueType;
  static const CommandId kCmdId = kIsValuebufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _valuebuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    SetHeader();
    valuebuffer = _valuebuffer;
    result_shm_id = _result_shm_id;
    result_shm_offset = _result_shm_offset;
  }

  void* Set(void* cmd,
            GLuint _valuebuffer,
            uint32_t _result_shm_id,
            uint32_t _result_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_valuebuffer, _result_shm_id, _result_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t valuebuffer;
  uint32_t result_shm_id;
  uint32_t result_shm_offset;
};

static_assert(sizeof(IsValuebufferCHROMIUM) == 16,
              "size of IsValuebufferCHROMIUM should be 16");
static_assert(offsetof(IsValuebufferCHROMIUM, header) == 0,
              "offset of IsValuebufferCHROMIUM header should be 0");
static_assert(offsetof(IsValuebufferCHROMIUM, valuebuffer) == 4,
              "offset of IsValuebufferCHROMIUM valuebuffer should be 4");
static_assert(offsetof(IsValuebufferCHROMIUM, result_shm_id) == 8,
              "offset of IsValuebufferCHROMIUM result_shm_id should be 8");
static_assert(offsetof(IsValuebufferCHROMIUM, result_shm_offset) == 12,
              "offset of IsValuebufferCHROMIUM result_shm_offset should be 12");

struct BindValuebufferCHROMIUM {
  typedef BindValuebufferCHROMIUM ValueType;
  static const CommandId kCmdId = kBindValuebufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLuint _valuebuffer) {
    SetHeader();
    target = _target;
    valuebuffer = _valuebuffer;
  }

  void* Set(void* cmd, GLenum _target, GLuint _valuebuffer) {
    static_cast<ValueType*>(cmd)->Init(_target, _valuebuffer);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t valuebuffer;
};

static_assert(sizeof(BindValuebufferCHROMIUM) == 12,
              "size of BindValuebufferCHROMIUM should be 12");
static_assert(offsetof(BindValuebufferCHROMIUM, header) == 0,
              "offset of BindValuebufferCHROMIUM header should be 0");
static_assert(offsetof(BindValuebufferCHROMIUM, target) == 4,
              "offset of BindValuebufferCHROMIUM target should be 4");
static_assert(offsetof(BindValuebufferCHROMIUM, valuebuffer) == 8,
              "offset of BindValuebufferCHROMIUM valuebuffer should be 8");

struct SubscribeValueCHROMIUM {
  typedef SubscribeValueCHROMIUM ValueType;
  static const CommandId kCmdId = kSubscribeValueCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLenum _subscription) {
    SetHeader();
    target = _target;
    subscription = _subscription;
  }

  void* Set(void* cmd, GLenum _target, GLenum _subscription) {
    static_cast<ValueType*>(cmd)->Init(_target, _subscription);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  uint32_t subscription;
};

static_assert(sizeof(SubscribeValueCHROMIUM) == 12,
              "size of SubscribeValueCHROMIUM should be 12");
static_assert(offsetof(SubscribeValueCHROMIUM, header) == 0,
              "offset of SubscribeValueCHROMIUM header should be 0");
static_assert(offsetof(SubscribeValueCHROMIUM, target) == 4,
              "offset of SubscribeValueCHROMIUM target should be 4");
static_assert(offsetof(SubscribeValueCHROMIUM, subscription) == 8,
              "offset of SubscribeValueCHROMIUM subscription should be 8");

struct PopulateSubscribedValuesCHROMIUM {
  typedef PopulateSubscribedValuesCHROMIUM ValueType;
  static const CommandId kCmdId = kPopulateSubscribedValuesCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target) {
    SetHeader();
    target = _target;
  }

  void* Set(void* cmd, GLenum _target) {
    static_cast<ValueType*>(cmd)->Init(_target);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(PopulateSubscribedValuesCHROMIUM) == 8,
              "size of PopulateSubscribedValuesCHROMIUM should be 8");
static_assert(offsetof(PopulateSubscribedValuesCHROMIUM, header) == 0,
              "offset of PopulateSubscribedValuesCHROMIUM header should be 0");
static_assert(offsetof(PopulateSubscribedValuesCHROMIUM, target) == 4,
              "offset of PopulateSubscribedValuesCHROMIUM target should be 4");

struct UniformValuebufferCHROMIUM {
  typedef UniformValuebufferCHROMIUM ValueType;
  static const CommandId kCmdId = kUniformValuebufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _location, GLenum _target, GLenum _subscription) {
    SetHeader();
    location = _location;
    target = _target;
    subscription = _subscription;
  }

  void* Set(void* cmd, GLint _location, GLenum _target, GLenum _subscription) {
    static_cast<ValueType*>(cmd)->Init(_location, _target, _subscription);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t location;
  uint32_t target;
  uint32_t subscription;
};

static_assert(sizeof(UniformValuebufferCHROMIUM) == 16,
              "size of UniformValuebufferCHROMIUM should be 16");
static_assert(offsetof(UniformValuebufferCHROMIUM, header) == 0,
              "offset of UniformValuebufferCHROMIUM header should be 0");
static_assert(offsetof(UniformValuebufferCHROMIUM, location) == 4,
              "offset of UniformValuebufferCHROMIUM location should be 4");
static_assert(offsetof(UniformValuebufferCHROMIUM, target) == 8,
              "offset of UniformValuebufferCHROMIUM target should be 8");
static_assert(offsetof(UniformValuebufferCHROMIUM, subscription) == 12,
              "offset of UniformValuebufferCHROMIUM subscription should be 12");

struct BindTexImage2DCHROMIUM {
  typedef BindTexImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kBindTexImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLint _imageId) {
    SetHeader();
    target = _target;
    imageId = _imageId;
  }

  void* Set(void* cmd, GLenum _target, GLint _imageId) {
    static_cast<ValueType*>(cmd)->Init(_target, _imageId);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t imageId;
};

static_assert(sizeof(BindTexImage2DCHROMIUM) == 12,
              "size of BindTexImage2DCHROMIUM should be 12");
static_assert(offsetof(BindTexImage2DCHROMIUM, header) == 0,
              "offset of BindTexImage2DCHROMIUM header should be 0");
static_assert(offsetof(BindTexImage2DCHROMIUM, target) == 4,
              "offset of BindTexImage2DCHROMIUM target should be 4");
static_assert(offsetof(BindTexImage2DCHROMIUM, imageId) == 8,
              "offset of BindTexImage2DCHROMIUM imageId should be 8");

struct ReleaseTexImage2DCHROMIUM {
  typedef ReleaseTexImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kReleaseTexImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target, GLint _imageId) {
    SetHeader();
    target = _target;
    imageId = _imageId;
  }

  void* Set(void* cmd, GLenum _target, GLint _imageId) {
    static_cast<ValueType*>(cmd)->Init(_target, _imageId);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t imageId;
};

static_assert(sizeof(ReleaseTexImage2DCHROMIUM) == 12,
              "size of ReleaseTexImage2DCHROMIUM should be 12");
static_assert(offsetof(ReleaseTexImage2DCHROMIUM, header) == 0,
              "offset of ReleaseTexImage2DCHROMIUM header should be 0");
static_assert(offsetof(ReleaseTexImage2DCHROMIUM, target) == 4,
              "offset of ReleaseTexImage2DCHROMIUM target should be 4");
static_assert(offsetof(ReleaseTexImage2DCHROMIUM, imageId) == 8,
              "offset of ReleaseTexImage2DCHROMIUM imageId should be 8");

struct TraceBeginCHROMIUM {
  typedef TraceBeginCHROMIUM ValueType;
  static const CommandId kCmdId = kTraceBeginCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _category_bucket_id, GLuint _name_bucket_id) {
    SetHeader();
    category_bucket_id = _category_bucket_id;
    name_bucket_id = _name_bucket_id;
  }

  void* Set(void* cmd, GLuint _category_bucket_id, GLuint _name_bucket_id) {
    static_cast<ValueType*>(cmd)->Init(_category_bucket_id, _name_bucket_id);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t category_bucket_id;
  uint32_t name_bucket_id;
};

static_assert(sizeof(TraceBeginCHROMIUM) == 12,
              "size of TraceBeginCHROMIUM should be 12");
static_assert(offsetof(TraceBeginCHROMIUM, header) == 0,
              "offset of TraceBeginCHROMIUM header should be 0");
static_assert(offsetof(TraceBeginCHROMIUM, category_bucket_id) == 4,
              "offset of TraceBeginCHROMIUM category_bucket_id should be 4");
static_assert(offsetof(TraceBeginCHROMIUM, name_bucket_id) == 8,
              "offset of TraceBeginCHROMIUM name_bucket_id should be 8");

struct TraceEndCHROMIUM {
  typedef TraceEndCHROMIUM ValueType;
  static const CommandId kCmdId = kTraceEndCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(TraceEndCHROMIUM) == 4,
              "size of TraceEndCHROMIUM should be 4");
static_assert(offsetof(TraceEndCHROMIUM, header) == 0,
              "offset of TraceEndCHROMIUM header should be 0");

struct AsyncTexSubImage2DCHROMIUM {
  typedef AsyncTexSubImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kAsyncTexSubImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            uint32_t _async_upload_token,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    xoffset = _xoffset;
    yoffset = _yoffset;
    width = _width;
    height = _height;
    format = _format;
    type = _type;
    data_shm_id = _data_shm_id;
    data_shm_offset = _data_shm_offset;
    async_upload_token = _async_upload_token;
    sync_data_shm_id = _sync_data_shm_id;
    sync_data_shm_offset = _sync_data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _xoffset,
            GLint _yoffset,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _data_shm_id,
            uint32_t _data_shm_offset,
            uint32_t _async_upload_token,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _xoffset, _yoffset, _width, _height, _format,
               _type, _data_shm_id, _data_shm_offset, _async_upload_token,
               _sync_data_shm_id, _sync_data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t xoffset;
  int32_t yoffset;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t type;
  uint32_t data_shm_id;
  uint32_t data_shm_offset;
  uint32_t async_upload_token;
  uint32_t sync_data_shm_id;
  uint32_t sync_data_shm_offset;
};

static_assert(sizeof(AsyncTexSubImage2DCHROMIUM) == 56,
              "size of AsyncTexSubImage2DCHROMIUM should be 56");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, header) == 0,
              "offset of AsyncTexSubImage2DCHROMIUM header should be 0");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, target) == 4,
              "offset of AsyncTexSubImage2DCHROMIUM target should be 4");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, level) == 8,
              "offset of AsyncTexSubImage2DCHROMIUM level should be 8");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, xoffset) == 12,
              "offset of AsyncTexSubImage2DCHROMIUM xoffset should be 12");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, yoffset) == 16,
              "offset of AsyncTexSubImage2DCHROMIUM yoffset should be 16");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, width) == 20,
              "offset of AsyncTexSubImage2DCHROMIUM width should be 20");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, height) == 24,
              "offset of AsyncTexSubImage2DCHROMIUM height should be 24");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, format) == 28,
              "offset of AsyncTexSubImage2DCHROMIUM format should be 28");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, type) == 32,
              "offset of AsyncTexSubImage2DCHROMIUM type should be 32");
static_assert(offsetof(AsyncTexSubImage2DCHROMIUM, data_shm_id) == 36,
              "offset of AsyncTexSubImage2DCHROMIUM data_shm_id should be 36");
static_assert(
    offsetof(AsyncTexSubImage2DCHROMIUM, data_shm_offset) == 40,
    "offset of AsyncTexSubImage2DCHROMIUM data_shm_offset should be 40");
static_assert(
    offsetof(AsyncTexSubImage2DCHROMIUM, async_upload_token) == 44,
    "offset of AsyncTexSubImage2DCHROMIUM async_upload_token should be 44");
static_assert(
    offsetof(AsyncTexSubImage2DCHROMIUM, sync_data_shm_id) == 48,
    "offset of AsyncTexSubImage2DCHROMIUM sync_data_shm_id should be 48");
static_assert(
    offsetof(AsyncTexSubImage2DCHROMIUM, sync_data_shm_offset) == 52,
    "offset of AsyncTexSubImage2DCHROMIUM sync_data_shm_offset should be 52");

struct AsyncTexImage2DCHROMIUM {
  typedef AsyncTexImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kAsyncTexImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            uint32_t _async_upload_token,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    SetHeader();
    target = _target;
    level = _level;
    internalformat = _internalformat;
    width = _width;
    height = _height;
    format = _format;
    type = _type;
    pixels_shm_id = _pixels_shm_id;
    pixels_shm_offset = _pixels_shm_offset;
    async_upload_token = _async_upload_token;
    sync_data_shm_id = _sync_data_shm_id;
    sync_data_shm_offset = _sync_data_shm_offset;
  }

  void* Set(void* cmd,
            GLenum _target,
            GLint _level,
            GLint _internalformat,
            GLsizei _width,
            GLsizei _height,
            GLenum _format,
            GLenum _type,
            uint32_t _pixels_shm_id,
            uint32_t _pixels_shm_offset,
            uint32_t _async_upload_token,
            uint32_t _sync_data_shm_id,
            uint32_t _sync_data_shm_offset) {
    static_cast<ValueType*>(cmd)
        ->Init(_target, _level, _internalformat, _width, _height, _format,
               _type, _pixels_shm_id, _pixels_shm_offset, _async_upload_token,
               _sync_data_shm_id, _sync_data_shm_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t level;
  int32_t internalformat;
  int32_t width;
  int32_t height;
  uint32_t format;
  uint32_t type;
  uint32_t pixels_shm_id;
  uint32_t pixels_shm_offset;
  uint32_t async_upload_token;
  uint32_t sync_data_shm_id;
  uint32_t sync_data_shm_offset;
  static const int32_t border = 0;
};

static_assert(sizeof(AsyncTexImage2DCHROMIUM) == 52,
              "size of AsyncTexImage2DCHROMIUM should be 52");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, header) == 0,
              "offset of AsyncTexImage2DCHROMIUM header should be 0");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, target) == 4,
              "offset of AsyncTexImage2DCHROMIUM target should be 4");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, level) == 8,
              "offset of AsyncTexImage2DCHROMIUM level should be 8");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, internalformat) == 12,
              "offset of AsyncTexImage2DCHROMIUM internalformat should be 12");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, width) == 16,
              "offset of AsyncTexImage2DCHROMIUM width should be 16");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, height) == 20,
              "offset of AsyncTexImage2DCHROMIUM height should be 20");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, format) == 24,
              "offset of AsyncTexImage2DCHROMIUM format should be 24");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, type) == 28,
              "offset of AsyncTexImage2DCHROMIUM type should be 28");
static_assert(offsetof(AsyncTexImage2DCHROMIUM, pixels_shm_id) == 32,
              "offset of AsyncTexImage2DCHROMIUM pixels_shm_id should be 32");
static_assert(
    offsetof(AsyncTexImage2DCHROMIUM, pixels_shm_offset) == 36,
    "offset of AsyncTexImage2DCHROMIUM pixels_shm_offset should be 36");
static_assert(
    offsetof(AsyncTexImage2DCHROMIUM, async_upload_token) == 40,
    "offset of AsyncTexImage2DCHROMIUM async_upload_token should be 40");
static_assert(
    offsetof(AsyncTexImage2DCHROMIUM, sync_data_shm_id) == 44,
    "offset of AsyncTexImage2DCHROMIUM sync_data_shm_id should be 44");
static_assert(
    offsetof(AsyncTexImage2DCHROMIUM, sync_data_shm_offset) == 48,
    "offset of AsyncTexImage2DCHROMIUM sync_data_shm_offset should be 48");

struct WaitAsyncTexImage2DCHROMIUM {
  typedef WaitAsyncTexImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kWaitAsyncTexImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _target) {
    SetHeader();
    target = _target;
  }

  void* Set(void* cmd, GLenum _target) {
    static_cast<ValueType*>(cmd)->Init(_target);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t target;
};

static_assert(sizeof(WaitAsyncTexImage2DCHROMIUM) == 8,
              "size of WaitAsyncTexImage2DCHROMIUM should be 8");
static_assert(offsetof(WaitAsyncTexImage2DCHROMIUM, header) == 0,
              "offset of WaitAsyncTexImage2DCHROMIUM header should be 0");
static_assert(offsetof(WaitAsyncTexImage2DCHROMIUM, target) == 4,
              "offset of WaitAsyncTexImage2DCHROMIUM target should be 4");

struct WaitAllAsyncTexImage2DCHROMIUM {
  typedef WaitAllAsyncTexImage2DCHROMIUM ValueType;
  static const CommandId kCmdId = kWaitAllAsyncTexImage2DCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(WaitAllAsyncTexImage2DCHROMIUM) == 4,
              "size of WaitAllAsyncTexImage2DCHROMIUM should be 4");
static_assert(offsetof(WaitAllAsyncTexImage2DCHROMIUM, header) == 0,
              "offset of WaitAllAsyncTexImage2DCHROMIUM header should be 0");

struct DiscardFramebufferEXTImmediate {
  typedef DiscardFramebufferEXTImmediate ValueType;
  static const CommandId kCmdId = kDiscardFramebufferEXTImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLenum) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLenum _target, GLsizei _count, const GLenum* _attachments) {
    SetHeader(_count);
    target = _target;
    count = _count;
    memcpy(ImmediateDataAddress(this), _attachments, ComputeDataSize(_count));
  }

  void* Set(void* cmd,
            GLenum _target,
            GLsizei _count,
            const GLenum* _attachments) {
    static_cast<ValueType*>(cmd)->Init(_target, _count, _attachments);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t target;
  int32_t count;
};

static_assert(sizeof(DiscardFramebufferEXTImmediate) == 12,
              "size of DiscardFramebufferEXTImmediate should be 12");
static_assert(offsetof(DiscardFramebufferEXTImmediate, header) == 0,
              "offset of DiscardFramebufferEXTImmediate header should be 0");
static_assert(offsetof(DiscardFramebufferEXTImmediate, target) == 4,
              "offset of DiscardFramebufferEXTImmediate target should be 4");
static_assert(offsetof(DiscardFramebufferEXTImmediate, count) == 8,
              "offset of DiscardFramebufferEXTImmediate count should be 8");

struct LoseContextCHROMIUM {
  typedef LoseContextCHROMIUM ValueType;
  static const CommandId kCmdId = kLoseContextCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _current, GLenum _other) {
    SetHeader();
    current = _current;
    other = _other;
  }

  void* Set(void* cmd, GLenum _current, GLenum _other) {
    static_cast<ValueType*>(cmd)->Init(_current, _other);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t current;
  uint32_t other;
};

static_assert(sizeof(LoseContextCHROMIUM) == 12,
              "size of LoseContextCHROMIUM should be 12");
static_assert(offsetof(LoseContextCHROMIUM, header) == 0,
              "offset of LoseContextCHROMIUM header should be 0");
static_assert(offsetof(LoseContextCHROMIUM, current) == 4,
              "offset of LoseContextCHROMIUM current should be 4");
static_assert(offsetof(LoseContextCHROMIUM, other) == 8,
              "offset of LoseContextCHROMIUM other should be 8");

struct WaitSyncPointCHROMIUM {
  typedef WaitSyncPointCHROMIUM ValueType;
  static const CommandId kCmdId = kWaitSyncPointCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLuint _sync_point) {
    SetHeader();
    sync_point = _sync_point;
  }

  void* Set(void* cmd, GLuint _sync_point) {
    static_cast<ValueType*>(cmd)->Init(_sync_point);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t sync_point;
};

static_assert(sizeof(WaitSyncPointCHROMIUM) == 8,
              "size of WaitSyncPointCHROMIUM should be 8");
static_assert(offsetof(WaitSyncPointCHROMIUM, header) == 0,
              "offset of WaitSyncPointCHROMIUM header should be 0");
static_assert(offsetof(WaitSyncPointCHROMIUM, sync_point) == 4,
              "offset of WaitSyncPointCHROMIUM sync_point should be 4");

struct DrawBuffersEXTImmediate {
  typedef DrawBuffersEXTImmediate ValueType;
  static const CommandId kCmdId = kDrawBuffersEXTImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(GLenum) * 1 * count);  // NOLINT
  }

  static uint32_t ComputeSize(GLsizei count) {
    return static_cast<uint32_t>(sizeof(ValueType) +
                                 ComputeDataSize(count));  // NOLINT
  }

  void SetHeader(GLsizei count) {
    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));
  }

  void Init(GLsizei _count, const GLenum* _bufs) {
    SetHeader(_count);
    count = _count;
    memcpy(ImmediateDataAddress(this), _bufs, ComputeDataSize(_count));
  }

  void* Set(void* cmd, GLsizei _count, const GLenum* _bufs) {
    static_cast<ValueType*>(cmd)->Init(_count, _bufs);
    const uint32_t size = ComputeSize(_count);
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  int32_t count;
};

static_assert(sizeof(DrawBuffersEXTImmediate) == 8,
              "size of DrawBuffersEXTImmediate should be 8");
static_assert(offsetof(DrawBuffersEXTImmediate, header) == 0,
              "offset of DrawBuffersEXTImmediate header should be 0");
static_assert(offsetof(DrawBuffersEXTImmediate, count) == 4,
              "offset of DrawBuffersEXTImmediate count should be 4");

struct DiscardBackbufferCHROMIUM {
  typedef DiscardBackbufferCHROMIUM ValueType;
  static const CommandId kCmdId = kDiscardBackbufferCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(DiscardBackbufferCHROMIUM) == 4,
              "size of DiscardBackbufferCHROMIUM should be 4");
static_assert(offsetof(DiscardBackbufferCHROMIUM, header) == 0,
              "offset of DiscardBackbufferCHROMIUM header should be 0");

struct ScheduleOverlayPlaneCHROMIUM {
  typedef ScheduleOverlayPlaneCHROMIUM ValueType;
  static const CommandId kCmdId = kScheduleOverlayPlaneCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _plane_z_order,
            GLenum _plane_transform,
            GLuint _overlay_texture_id,
            GLint _bounds_x,
            GLint _bounds_y,
            GLint _bounds_width,
            GLint _bounds_height,
            GLfloat _uv_x,
            GLfloat _uv_y,
            GLfloat _uv_width,
            GLfloat _uv_height) {
    SetHeader();
    plane_z_order = _plane_z_order;
    plane_transform = _plane_transform;
    overlay_texture_id = _overlay_texture_id;
    bounds_x = _bounds_x;
    bounds_y = _bounds_y;
    bounds_width = _bounds_width;
    bounds_height = _bounds_height;
    uv_x = _uv_x;
    uv_y = _uv_y;
    uv_width = _uv_width;
    uv_height = _uv_height;
  }

  void* Set(void* cmd,
            GLint _plane_z_order,
            GLenum _plane_transform,
            GLuint _overlay_texture_id,
            GLint _bounds_x,
            GLint _bounds_y,
            GLint _bounds_width,
            GLint _bounds_height,
            GLfloat _uv_x,
            GLfloat _uv_y,
            GLfloat _uv_width,
            GLfloat _uv_height) {
    static_cast<ValueType*>(cmd)->Init(_plane_z_order, _plane_transform,
                                       _overlay_texture_id, _bounds_x,
                                       _bounds_y, _bounds_width, _bounds_height,
                                       _uv_x, _uv_y, _uv_width, _uv_height);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t plane_z_order;
  uint32_t plane_transform;
  uint32_t overlay_texture_id;
  int32_t bounds_x;
  int32_t bounds_y;
  int32_t bounds_width;
  int32_t bounds_height;
  float uv_x;
  float uv_y;
  float uv_width;
  float uv_height;
};

static_assert(sizeof(ScheduleOverlayPlaneCHROMIUM) == 48,
              "size of ScheduleOverlayPlaneCHROMIUM should be 48");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, header) == 0,
              "offset of ScheduleOverlayPlaneCHROMIUM header should be 0");
static_assert(
    offsetof(ScheduleOverlayPlaneCHROMIUM, plane_z_order) == 4,
    "offset of ScheduleOverlayPlaneCHROMIUM plane_z_order should be 4");
static_assert(
    offsetof(ScheduleOverlayPlaneCHROMIUM, plane_transform) == 8,
    "offset of ScheduleOverlayPlaneCHROMIUM plane_transform should be 8");
static_assert(
    offsetof(ScheduleOverlayPlaneCHROMIUM, overlay_texture_id) == 12,
    "offset of ScheduleOverlayPlaneCHROMIUM overlay_texture_id should be 12");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, bounds_x) == 16,
              "offset of ScheduleOverlayPlaneCHROMIUM bounds_x should be 16");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, bounds_y) == 20,
              "offset of ScheduleOverlayPlaneCHROMIUM bounds_y should be 20");
static_assert(
    offsetof(ScheduleOverlayPlaneCHROMIUM, bounds_width) == 24,
    "offset of ScheduleOverlayPlaneCHROMIUM bounds_width should be 24");
static_assert(
    offsetof(ScheduleOverlayPlaneCHROMIUM, bounds_height) == 28,
    "offset of ScheduleOverlayPlaneCHROMIUM bounds_height should be 28");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, uv_x) == 32,
              "offset of ScheduleOverlayPlaneCHROMIUM uv_x should be 32");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, uv_y) == 36,
              "offset of ScheduleOverlayPlaneCHROMIUM uv_y should be 36");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, uv_width) == 40,
              "offset of ScheduleOverlayPlaneCHROMIUM uv_width should be 40");
static_assert(offsetof(ScheduleOverlayPlaneCHROMIUM, uv_height) == 44,
              "offset of ScheduleOverlayPlaneCHROMIUM uv_height should be 44");

struct SwapInterval {
  typedef SwapInterval ValueType;
  static const CommandId kCmdId = kSwapInterval;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(1);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLint _interval) {
    SetHeader();
    interval = _interval;
  }

  void* Set(void* cmd, GLint _interval) {
    static_cast<ValueType*>(cmd)->Init(_interval);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  int32_t interval;
};

static_assert(sizeof(SwapInterval) == 8, "size of SwapInterval should be 8");
static_assert(offsetof(SwapInterval, header) == 0,
              "offset of SwapInterval header should be 0");
static_assert(offsetof(SwapInterval, interval) == 4,
              "offset of SwapInterval interval should be 4");

struct MatrixLoadfCHROMIUMImmediate {
  typedef MatrixLoadfCHROMIUMImmediate ValueType;
  static const CommandId kCmdId = kMatrixLoadfCHROMIUMImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeDataSize() {
    return static_cast<uint32_t>(sizeof(GLfloat) * 16);
  }

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType) + ComputeDataSize());
  }

  void SetHeader() { header.SetCmdByTotalSize<ValueType>(ComputeSize()); }

  void Init(GLenum _matrixMode, const GLfloat* _m) {
    SetHeader();
    matrixMode = _matrixMode;
    memcpy(ImmediateDataAddress(this), _m, ComputeDataSize());
  }

  void* Set(void* cmd, GLenum _matrixMode, const GLfloat* _m) {
    static_cast<ValueType*>(cmd)->Init(_matrixMode, _m);
    const uint32_t size = ComputeSize();
    return NextImmediateCmdAddressTotalSize<ValueType>(cmd, size);
  }

  gpu::CommandHeader header;
  uint32_t matrixMode;
};

static_assert(sizeof(MatrixLoadfCHROMIUMImmediate) == 8,
              "size of MatrixLoadfCHROMIUMImmediate should be 8");
static_assert(offsetof(MatrixLoadfCHROMIUMImmediate, header) == 0,
              "offset of MatrixLoadfCHROMIUMImmediate header should be 0");
static_assert(offsetof(MatrixLoadfCHROMIUMImmediate, matrixMode) == 4,
              "offset of MatrixLoadfCHROMIUMImmediate matrixMode should be 4");

struct MatrixLoadIdentityCHROMIUM {
  typedef MatrixLoadIdentityCHROMIUM ValueType;
  static const CommandId kCmdId = kMatrixLoadIdentityCHROMIUM;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init(GLenum _matrixMode) {
    SetHeader();
    matrixMode = _matrixMode;
  }

  void* Set(void* cmd, GLenum _matrixMode) {
    static_cast<ValueType*>(cmd)->Init(_matrixMode);
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
  uint32_t matrixMode;
};

static_assert(sizeof(MatrixLoadIdentityCHROMIUM) == 8,
              "size of MatrixLoadIdentityCHROMIUM should be 8");
static_assert(offsetof(MatrixLoadIdentityCHROMIUM, header) == 0,
              "offset of MatrixLoadIdentityCHROMIUM header should be 0");
static_assert(offsetof(MatrixLoadIdentityCHROMIUM, matrixMode) == 4,
              "offset of MatrixLoadIdentityCHROMIUM matrixMode should be 4");

struct BlendBarrierKHR {
  typedef BlendBarrierKHR ValueType;
  static const CommandId kCmdId = kBlendBarrierKHR;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8 cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  static uint32_t ComputeSize() {
    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT
  }

  void SetHeader() { header.SetCmd<ValueType>(); }

  void Init() { SetHeader(); }

  void* Set(void* cmd) {
    static_cast<ValueType*>(cmd)->Init();
    return NextCmdAddress<ValueType>(cmd);
  }

  gpu::CommandHeader header;
};

static_assert(sizeof(BlendBarrierKHR) == 4,
              "size of BlendBarrierKHR should be 4");
static_assert(offsetof(BlendBarrierKHR, header) == 0,
              "offset of BlendBarrierKHR header should be 0");

#endif  // GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_FORMAT_AUTOGEN_H_
