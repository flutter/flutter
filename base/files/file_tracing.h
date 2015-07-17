// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_FILE_TRACING_H_
#define BASE_FILES_FILE_TRACING_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/macros.h"

#define FILE_TRACING_PREFIX "File"

#define SCOPED_FILE_TRACE_WITH_SIZE(name, size) \
    FileTracing::ScopedTrace scoped_file_trace; \
    if (FileTracing::IsCategoryEnabled()) \
      scoped_file_trace.Initialize(FILE_TRACING_PREFIX "::" name, this, size)

#define SCOPED_FILE_TRACE(name) SCOPED_FILE_TRACE_WITH_SIZE(name, 0)

namespace base {

class File;
class FilePath;

class BASE_EXPORT FileTracing {
 public:
  // Whether the file tracing category is enabled.
  static bool IsCategoryEnabled();

  class Provider {
   public:
    virtual ~Provider() = default;

    // Whether the file tracing category is currently enabled.
    virtual bool FileTracingCategoryIsEnabled() const = 0;

    // Enables file tracing for |id|. Must be called before recording events.
    virtual void FileTracingEnable(void* id) = 0;

    // Disables file tracing for |id|.
    virtual void FileTracingDisable(void* id) = 0;

    // Begins an event for |id| with |name|. |path| tells where in the directory
    // structure the event is happening (and may be blank). |size| is the number
    // of bytes involved in the event.
    virtual void FileTracingEventBegin(
        const char* name, void* id, const FilePath& path, int64 size) = 0;

    // Ends an event for |id| with |name|.
    virtual void FileTracingEventEnd(const char* name, void* id) = 0;
  };

  // Sets a global file tracing provider to query categories and record events.
  static void SetProvider(Provider* provider);

  // Enables file tracing while in scope.
  class ScopedEnabler {
   public:
    ScopedEnabler();
    ~ScopedEnabler();
  };

  class ScopedTrace {
   public:
    ScopedTrace();
    ~ScopedTrace();

    // Called only if the tracing category is enabled. |name| is the name of the
    // event to trace (e.g. "Read", "Write") and must have an application
    // lifetime (e.g. static or literal). |file| is the file being traced; must
    // outlive this class. |size| is the size (in bytes) of this event.
    void Initialize(const char* name, File* file, int64 size);

   private:
    // The ID of this trace. Based on the |file| passed to |Initialize()|. Must
    // outlive this class.
    void* id_;

    // The name of the event to trace (e.g. "Read", "Write"). Prefixed with
    // "File".
    const char* name_;

    DISALLOW_COPY_AND_ASSIGN(ScopedTrace);
  };

  DISALLOW_COPY_AND_ASSIGN(FileTracing);
};

}  // namespace base

#endif  // BASE_FILES_FILE_TRACING_H_
