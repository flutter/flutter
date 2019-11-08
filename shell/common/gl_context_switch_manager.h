// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_GL_CONTEXT_SWITCH_MANAGER_H_
#define FLUTTER_SHELL_COMMON_GL_CONTEXT_SWITCH_MANAGER_H_

#include <memory>
#include "flutter/fml/macros.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Manages `GLContextSwitch`.
///
/// Should be subclassed for platforms that uses GL and requires context
/// switching. Always use `MakeCurrent` and `ResourceMakeCurrent` in the
/// `GLContextSwitchManager` to set gl contexts.
///
class GLContextSwitchManager {
 public:
  //------------------------------------------------------------------------------
  /// Switches the gl context to the flutter's contexts.
  ///
  /// Should be subclassed for each platform embedder that uses GL.
  /// In construction, it should set the current context to a flutter's context
  /// In destruction, it should rest the current context.
  ///
  class GLContextSwitch {
   public:
    GLContextSwitch();

    virtual ~GLContextSwitch();

    virtual bool GetSwitchResult() = 0;

    FML_DISALLOW_COPY_AND_ASSIGN(GLContextSwitch);
  };

  GLContextSwitchManager();
  ~GLContextSwitchManager();

  //----------------------------------------------------------------------------
  /// @brief      Creates a shell instance using the provided settings. The
  ///             callbacks to create the various shell subcomponents will be
  ///             called on the appropriate threads before this method returns.
  ///             If this is the first instance of a shell in the process, this
  ///             call also bootstraps the Dart VM.
  ///
  /// @param[in]  task_runners             The task runners
  /// @param[in]  settings                 The settings
  /// @param[in]  on_create_platform_view  The callback that must return a
  ///                                      platform view. This will be called on
  ///                                      the platform task runner before this
  ///                                      method returns.
  /// @param[in]  on_create_rasterizer     That callback that must provide a
  ///                                      valid rasterizer. This will be called
  ///                                      on the render task runner before this
  ///                                      method returns.
  ///
  /// @return     A full initialized shell if the settings and callbacks are
  ///             valid. The root isolate has been created but not yet launched.
  ///             It may be launched by obtaining the engine weak pointer and
  ///             posting a task onto the UI task runner with a valid run
  ///             configuration to run the isolate. The embedder must always
  ///             check the validity of the shell (using the IsSetup call)
  ///             immediately after getting a pointer to it.
  ///

  //----------------------------------------------------------------------------
  /// @brief      Make the flutter's context as current context.
  ///
  /// @return     A `GLContextSwitch` with `GetSwitchResult` returning true if
  /// the setting process is succesful.
  virtual std::unique_ptr<GLContextSwitch> MakeCurrent() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Make the flutter's resources context as current context.
  ///
  /// @return     A `GLContextSwitch` with `GetSwitchResult` returning true if
  /// the setting process is succesful.
  virtual std::unique_ptr<GLContextSwitch> ResourceMakeCurrent() = 0;

  //------------------------------------------------------------------------------
  /// A representation of a `GLContextSwitch` that doesn't require actual
  /// context switching.
  ///
  class GLContextSwitchPureResult final : public GLContextSwitch {
   public:
    // Constructor that creates an `GLContextSwitchPureResult`.
    // The `GetSwitchResult` will return the same value as `switch_result`.

    //----------------------------------------------------------------------------
    /// @brief      Constructs a  `GLContextSwitchPureResult`.
    ///
    /// @param[in]  switch_result       the switch result that will be returned
    /// in `GetSwitchResult()`
    ///
    GLContextSwitchPureResult(bool switch_result);

    ~GLContextSwitchPureResult();

    bool GetSwitchResult() override;

   private:
    bool switch_result_;

    FML_DISALLOW_COPY_AND_ASSIGN(GLContextSwitchPureResult);
  };

  FML_DISALLOW_COPY_AND_ASSIGN(GLContextSwitchManager);
};

}  // namespace flutter

#endif
