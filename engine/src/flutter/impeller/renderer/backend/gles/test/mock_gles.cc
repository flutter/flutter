// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "GLES3/gl3.h"
#include "fml/logging.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

// OpenGLES is not thread safe.
//
// This mutex is used to ensure that only one test is using the mock at a time.
static std::mutex g_test_lock;

static std::weak_ptr<MockGLES> g_mock_gles;

static ProcTableGLES::Resolver g_resolver;

static std::vector<const unsigned char*> g_extensions;

static const unsigned char* g_version;

// Has friend visibility into MockGLES to record calls.
void RecordGLCall(const char* name) {
  if (auto mock_gles = g_mock_gles.lock()) {
    mock_gles->RecordCall(name);
  }
}

template <typename T, typename U>
struct CheckSameSignature : std::false_type {};

template <typename Ret, typename... Args>
struct CheckSameSignature<Ret(Args...), Ret(Args...)> : std::true_type {};

// This is a stub function that does nothing/records nothing.
void doNothing() {}

auto const kMockVendor = (unsigned char*)"MockGLES";
const auto kMockShadingLanguageVersion = (unsigned char*)"GLSL ES 1.0";
auto const kExtensions = std::vector<const unsigned char*>{
    (unsigned char*)"GL_KHR_debug"  //
};

const unsigned char* mockGetString(GLenum name) {
  switch (name) {
    case GL_VENDOR:
      return kMockVendor;
    case GL_VERSION:
      return g_version;
    case GL_SHADING_LANGUAGE_VERSION:
      return kMockShadingLanguageVersion;
    default:
      return (unsigned char*)"";
  }
}

static_assert(CheckSameSignature<decltype(mockGetString),  //
                                 decltype(glGetString)>::value);

const unsigned char* mockGetStringi(GLenum name, GLuint index) {
  switch (name) {
    case GL_EXTENSIONS:
      return g_extensions[index];
    default:
      return (unsigned char*)"";
  }
}

static_assert(CheckSameSignature<decltype(mockGetStringi),  //
                                 decltype(glGetStringi)>::value);

void mockGetIntegerv(GLenum name, int* value) {
  switch (name) {
    case GL_NUM_EXTENSIONS: {
      *value = g_extensions.size();
    } break;
    case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
      *value = 8;
      break;
    default:
      *value = 0;
      break;
  }
}

static_assert(CheckSameSignature<decltype(mockGetIntegerv),  //
                                 decltype(glGetIntegerv)>::value);

GLenum mockGetError() {
  return GL_NO_ERROR;
}

static_assert(CheckSameSignature<decltype(mockGetError),  //
                                 decltype(glGetError)>::value);

void mockPopDebugGroupKHR() {
  RecordGLCall("PopDebugGroupKHR");
}

static_assert(CheckSameSignature<decltype(mockPopDebugGroupKHR),  //
                                 decltype(glPopDebugGroupKHR)>::value);

void mockPushDebugGroupKHR(GLenum source,
                           GLuint id,
                           GLsizei length,
                           const GLchar* message) {
  RecordGLCall("PushDebugGroupKHR");
}

static_assert(CheckSameSignature<decltype(mockPushDebugGroupKHR),  //
                                 decltype(glPushDebugGroupKHR)>::value);

void mockGenQueriesEXT(GLsizei n, GLuint* ids) {
  RecordGLCall("glGenQueriesEXT");
  for (auto i = 0; i < n; i++) {
    ids[i] = i + 1;
  }
}

static_assert(CheckSameSignature<decltype(mockGenQueriesEXT),  //
                                 decltype(glGenQueriesEXT)>::value);

void mockBeginQueryEXT(GLenum target, GLuint id) {
  RecordGLCall("glBeginQueryEXT");
}

static_assert(CheckSameSignature<decltype(mockBeginQueryEXT),  //
                                 decltype(glBeginQueryEXT)>::value);

void mockEndQueryEXT(GLuint id) {
  RecordGLCall("glEndQueryEXT");
}

static_assert(CheckSameSignature<decltype(mockEndQueryEXT),  //
                                 decltype(glEndQueryEXT)>::value);

void mockGetQueryObjectuivEXT(GLuint id, GLenum target, GLuint* result) {
  RecordGLCall("glGetQueryObjectuivEXT");
  *result = GL_TRUE;
}

static_assert(CheckSameSignature<decltype(mockGetQueryObjectuivEXT),  //
                                 decltype(glGetQueryObjectuivEXT)>::value);

void mockGetQueryObjectui64vEXT(GLuint id, GLenum target, GLuint64* result) {
  RecordGLCall("glGetQueryObjectui64vEXT");
  *result = 1000u;
}

static_assert(CheckSameSignature<decltype(mockGetQueryObjectui64vEXT),  //
                                 decltype(glGetQueryObjectui64vEXT)>::value);

void mockDeleteQueriesEXT(GLsizei size, const GLuint* queries) {
  RecordGLCall("glDeleteQueriesEXT");
}

void mockDeleteTextures(GLsizei size, const GLuint* queries) {
  RecordGLCall("glDeleteTextures");
}

static_assert(CheckSameSignature<decltype(mockDeleteQueriesEXT),  //
                                 decltype(glDeleteQueriesEXT)>::value);

void mockUniform1fv(GLint location, GLsizei count, const GLfloat* value) {
  RecordGLCall("glUniform1fv");
}

static_assert(CheckSameSignature<decltype(mockUniform1fv),  //
                                 decltype(glUniform1fv)>::value);

std::shared_ptr<MockGLES> MockGLES::Init(
    const std::optional<std::vector<const unsigned char*>>& extensions,
    const char* version_string,
    ProcTableGLES::Resolver resolver) {
  // If we cannot obtain a lock, MockGLES is already being used elsewhere.
  FML_CHECK(g_test_lock.try_lock())
      << "MockGLES is already being used by another test.";
  g_version = (unsigned char*)version_string;
  g_extensions = extensions.value_or(kExtensions);
  auto mock_gles = std::shared_ptr<MockGLES>(new MockGLES(std::move(resolver)));
  g_mock_gles = mock_gles;
  return mock_gles;
}

const ProcTableGLES::Resolver kMockResolverGLES = [](const char* name) {
  if (strcmp(name, "glPopDebugGroupKHR") == 0) {
    return reinterpret_cast<void*>(&mockPopDebugGroupKHR);
  } else if (strcmp(name, "glPushDebugGroupKHR") == 0) {
    return reinterpret_cast<void*>(&mockPushDebugGroupKHR);
  } else if (strcmp(name, "glGetString") == 0) {
    return reinterpret_cast<void*>(&mockGetString);
  } else if (strcmp(name, "glGetStringi") == 0) {
    return reinterpret_cast<void*>(&mockGetStringi);
  } else if (strcmp(name, "glGetIntegerv") == 0) {
    return reinterpret_cast<void*>(&mockGetIntegerv);
  } else if (strcmp(name, "glGetError") == 0) {
    return reinterpret_cast<void*>(&mockGetError);
  } else if (strcmp(name, "glGenQueriesEXT") == 0) {
    return reinterpret_cast<void*>(&mockGenQueriesEXT);
  } else if (strcmp(name, "glBeginQueryEXT") == 0) {
    return reinterpret_cast<void*>(&mockBeginQueryEXT);
  } else if (strcmp(name, "glEndQueryEXT") == 0) {
    return reinterpret_cast<void*>(&mockEndQueryEXT);
  } else if (strcmp(name, "glDeleteQueriesEXT") == 0) {
    return reinterpret_cast<void*>(&mockDeleteQueriesEXT);
  } else if (strcmp(name, "glDeleteTextures") == 0) {
    return reinterpret_cast<void*>(&mockDeleteTextures);
  } else if (strcmp(name, "glGetQueryObjectui64vEXT") == 0) {
    return reinterpret_cast<void*>(mockGetQueryObjectui64vEXT);
  } else if (strcmp(name, "glGetQueryObjectuivEXT") == 0) {
    return reinterpret_cast<void*>(mockGetQueryObjectuivEXT);
  } else if (strcmp(name, "glUniform1fv") == 0) {
    return reinterpret_cast<void*>(mockUniform1fv);
  } else {
    return reinterpret_cast<void*>(&doNothing);
  }
};

MockGLES::MockGLES(ProcTableGLES::Resolver resolver)
    : proc_table_(std::move(resolver)) {}

MockGLES::~MockGLES() {
  g_test_lock.unlock();
}

}  // namespace testing
}  // namespace impeller
