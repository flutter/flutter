// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_H_

#include <memory>

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/common/graphics/texture.h"
#include "flutter/common/settings.h"
#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/sync_switch.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#include "impeller/display_list/aiks_context.h"

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Manages the lifetime of the on-screen and off-screen rendering
///             contexts on iOS. On-screen contexts are used by Flutter for
///             rendering into the surface. The lifecycle of this context may be
///             tied to the lifecycle of the surface. On the other hand, the
///             lifecycle of the off-screen context it tied to that of the
///             platform view. This one object used to manage both context
///             because GPU handles may need to be shared between the two
///             context. To achieve this, context may need references to one
///             another at creation time. This one object manages the creation,
///             use and collection of both contexts in a client rendering API
///             agnostic manner.
///
class IOSContext {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Create an iOS context object capable of creating the on-screen
  ///             and off-screen GPU context for use by Impeller.
  ///
  /// @return     A valid context on success. `nullptr` on failure.
  ///
  static std::unique_ptr<IOSContext> Create(
      const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch,
      const Settings& settings);

  //----------------------------------------------------------------------------
  /// @brief      Collects the context object. This must happen on the thread on
  ///             which this object was created.
  ///
  virtual ~IOSContext();

  //----------------------------------------------------------------------------
  /// @brief      Creates an external texture proxy of the appropriate client
  ///             rendering API.
  ///
  /// @param[in]  texture_id  The texture identifier
  /// @param[in]  texture     The texture
  ///
  /// @return     The texture proxy if the rendering backend supports embedder
  ///             provided external textures.
  ///
  virtual std::unique_ptr<Texture> CreateExternalTexture(int64_t texture_id,
                                                         NSObject<FlutterTexture>* texture) = 0;

  virtual std::shared_ptr<impeller::Context> GetImpellerContext() const;

  virtual std::shared_ptr<impeller::AiksContext> GetAiksContext() const;

 protected:
  explicit IOSContext();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(IOSContext);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_H_
