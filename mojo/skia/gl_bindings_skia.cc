// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/gl_bindings_skia.h"

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif
#include "mojo/public/c/gpu/GLES2/gl2.h"
#include "mojo/public/c/gpu/GLES2/gl2ext.h"
#include "mojo/public/c/gpu/GLES2/gl2extmojo.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace mojo {
namespace skia {

sk_sp<GrGLInterface> CreateMojoSkiaGLBinding() {
  sk_sp<GrGLInterface> interface = sk_make_sp<GrGLInterface>();
  interface->fStandard = kGLES_GrGLStandard;
  interface->fExtensions.init(kGLES_GrGLStandard, glGetString, nullptr,
                              glGetIntegerv);

  GrGLInterface::Functions* functions = &interface->fFunctions;
  functions->fActiveTexture = glActiveTexture;
  functions->fAttachShader = glAttachShader;
  functions->fBindAttribLocation = glBindAttribLocation;
  functions->fBindBuffer = glBindBuffer;
  functions->fBindTexture = glBindTexture;
  functions->fBindVertexArray = glBindVertexArrayOES;
  functions->fBlendEquation = glBlendEquation;
  functions->fBlendBarrier = glBlendBarrierKHR;
  functions->fBlendColor = glBlendColor;
  functions->fBlendFunc = glBlendFunc;
  functions->fBufferData = glBufferData;
  functions->fBufferSubData = glBufferSubData;
  functions->fClear = glClear;
  functions->fClearColor = glClearColor;
  functions->fClearStencil = glClearStencil;
  functions->fColorMask = glColorMask;
  functions->fCompileShader = glCompileShader;
  functions->fCompressedTexImage2D = glCompressedTexImage2D;
  functions->fCopyTexSubImage2D = glCopyTexSubImage2D;
  functions->fCreateProgram = glCreateProgram;
  functions->fCreateShader = glCreateShader;
  functions->fCullFace = glCullFace;
  functions->fDeleteBuffers = glDeleteBuffers;
  functions->fDeleteProgram = glDeleteProgram;
  functions->fDeleteShader = glDeleteShader;
  functions->fDeleteTextures = glDeleteTextures;
  functions->fDeleteVertexArrays = glDeleteVertexArraysOES;
  functions->fDepthMask = glDepthMask;
  functions->fDisable = glDisable;
  functions->fDisableVertexAttribArray = glDisableVertexAttribArray;
  functions->fDiscardFramebuffer = glDiscardFramebufferEXT;
  functions->fDrawArrays = glDrawArrays;
  functions->fDrawElements = glDrawElements;
  functions->fEnable = glEnable;
  functions->fEnableVertexAttribArray = glEnableVertexAttribArray;
  functions->fFinish = glFinish;
  functions->fFlush = glFlush;
  functions->fFrontFace = glFrontFace;
  functions->fGenBuffers = glGenBuffers;
  functions->fGenTextures = glGenTextures;
  functions->fGenVertexArrays = glGenVertexArraysOES;
  functions->fGetBufferParameteriv = glGetBufferParameteriv;
  functions->fGetError = glGetError;
  functions->fGetIntegerv = glGetIntegerv;
  functions->fGetProgramInfoLog = glGetProgramInfoLog;
  functions->fGetProgramiv = glGetProgramiv;
  functions->fGetShaderInfoLog = glGetShaderInfoLog;
  functions->fGetShaderiv = glGetShaderiv;
  functions->fGetShaderPrecisionFormat = glGetShaderPrecisionFormat;
  functions->fGetString = glGetString;
  functions->fGetUniformLocation = glGetUniformLocation;
  functions->fInsertEventMarker = glInsertEventMarkerEXT;
  functions->fLineWidth = glLineWidth;
  functions->fLinkProgram = glLinkProgram;
  functions->fMapBufferSubData = glMapBufferSubDataCHROMIUM;
  functions->fMapTexSubImage2D = glMapTexSubImage2DCHROMIUM;
  functions->fPixelStorei = glPixelStorei;
  functions->fPopGroupMarker = glPopGroupMarkerEXT;
  functions->fPushGroupMarker = glPushGroupMarkerEXT;
  functions->fReadPixels = glReadPixels;
  functions->fScissor = glScissor;
  functions->fShaderSource = glShaderSource;
  functions->fStencilFunc = glStencilFunc;
  functions->fStencilFuncSeparate = glStencilFuncSeparate;
  functions->fStencilMask = glStencilMask;
  functions->fStencilMaskSeparate = glStencilMaskSeparate;
  functions->fStencilOp = glStencilOp;
  functions->fStencilOpSeparate = glStencilOpSeparate;
  functions->fTexImage2D = glTexImage2D;
  functions->fTexParameteri = glTexParameteri;
  functions->fTexParameteriv = glTexParameteriv;
  functions->fTexStorage2D = glTexStorage2DEXT;
  functions->fTexSubImage2D = glTexSubImage2D;
  functions->fUniform1f = glUniform1f;
  functions->fUniform1i = glUniform1i;
  functions->fUniform1fv = glUniform1fv;
  functions->fUniform1iv = glUniform1iv;
  functions->fUniform2f = glUniform2f;
  functions->fUniform2i = glUniform2i;
  functions->fUniform2fv = glUniform2fv;
  functions->fUniform2iv = glUniform2iv;
  functions->fUniform3f = glUniform3f;
  functions->fUniform3i = glUniform3i;
  functions->fUniform3fv = glUniform3fv;
  functions->fUniform3iv = glUniform3iv;
  functions->fUniform4f = glUniform4f;
  functions->fUniform4i = glUniform4i;
  functions->fUniform4fv = glUniform4fv;
  functions->fUniform4iv = glUniform4iv;
  functions->fUniformMatrix2fv = glUniformMatrix2fv;
  functions->fUniformMatrix3fv = glUniformMatrix3fv;
  functions->fUniformMatrix4fv = glUniformMatrix4fv;
  functions->fUnmapBufferSubData = glUnmapBufferSubDataCHROMIUM;
  functions->fUnmapTexSubImage2D = glUnmapTexSubImage2DCHROMIUM;
  functions->fUseProgram = glUseProgram;
  functions->fVertexAttrib1f = glVertexAttrib1f;
  functions->fVertexAttrib2fv = glVertexAttrib2fv;
  functions->fVertexAttrib3fv = glVertexAttrib3fv;
  functions->fVertexAttrib4fv = glVertexAttrib4fv;
  functions->fVertexAttribPointer = glVertexAttribPointer;
  functions->fViewport = glViewport;
  functions->fBindFramebuffer = glBindFramebuffer;
  functions->fBindRenderbuffer = glBindRenderbuffer;
  functions->fCheckFramebufferStatus = glCheckFramebufferStatus;
  functions->fDeleteFramebuffers = glDeleteFramebuffers;
  functions->fDeleteRenderbuffers = glDeleteRenderbuffers;
  functions->fFramebufferRenderbuffer = glFramebufferRenderbuffer;
  functions->fFramebufferTexture2D = glFramebufferTexture2D;
  functions->fFramebufferTexture2DMultisample =
      glFramebufferTexture2DMultisampleEXT;
  functions->fGenFramebuffers = glGenFramebuffers;
  functions->fGenRenderbuffers = glGenRenderbuffers;
  functions->fGetFramebufferAttachmentParameteriv =
      glGetFramebufferAttachmentParameteriv;
  functions->fGetRenderbufferParameteriv = glGetRenderbufferParameteriv;
  functions->fRenderbufferStorage = glRenderbufferStorage;
  functions->fRenderbufferStorageMultisample = nullptr;  // TODO: Implement.
  functions->fRenderbufferStorageMultisampleES2EXT =
      glRenderbufferStorageMultisampleEXT;
  functions->fBindUniformLocation = glBindUniformLocationCHROMIUM;
  functions->fBlitFramebuffer = nullptr;  // TODO: Implement.
  functions->fGenerateMipmap = glGenerateMipmap;
  functions->fMatrixLoadf = nullptr;         // TODO: Implement.
  functions->fMatrixLoadIdentity = nullptr;  // TODO: Implement.

  return interface;
}

}  // namespace skia
}  // namespace mojo
