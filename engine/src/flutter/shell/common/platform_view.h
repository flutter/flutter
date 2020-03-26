// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMMON_PLATFORM_VIEW_H_
#define COMMON_PLATFORM_VIEW_H_

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/semantics/custom_accessibility_action.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/pointer_data_packet_converter.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/pointer_data_dispatcher.h"
#include "flutter/shell/common/surface.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter {

class Shell;

//------------------------------------------------------------------------------
/// @brief      Platform views are created by the shell on the platform task
///             runner. Unless explicitly specified, all platform view methods
///             are called on the platform task runner as well. Platform views
///             are usually sub-classed on a per platform basis and the bulk of
///             the window system integration happens using that subclass. Since
///             most platform window toolkits are usually only safe to access on
///             a single "main" thread, any interaction that requires access to
///             the underlying platform's window toolkit is routed through the
///             platform view associated with that shell. This involves
///             operations like settings up and tearing down the render surface,
///             platform messages, interacting with accessibility features on
///             the platform, input events, etc.
///
class PlatformView {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Used to forward events from the platform view to interested
  ///             subsystems. This forwarding is done by the shell which sets
  ///             itself up as the delegate of the platform view.
  ///
  class Delegate {
   public:
    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the platform view was created
    ///             with the given render surface. This surface is platform
    ///             (iOS, Android) and client-rendering API (OpenGL, Software,
    ///             Metal, Vulkan) specific. This is usually a sign to the
    ///             rasterizer to setup and begin rendering to that surface.
    ///
    /// @param[in]  surface  The surface
    ///
    virtual void OnPlatformViewCreated(std::unique_ptr<Surface> surface) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the platform view was destroyed.
    ///             This is usually a sign to the rasterizer to suspend
    ///             rendering a previously configured surface and collect any
    ///             intermediate resources.
    ///
    virtual void OnPlatformViewDestroyed() = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the specified callback needs to
    ///             be invoked after the rasterizer is done rendering the next
    ///             frame. This callback will be called on the render thread and
    ///             it is caller responsibility to perform any re-threading as
    ///             necessary. Due to the asynchronous nature of rendering in
    ///             Flutter, embedders usually add a placeholder over the
    ///             contents in which Flutter is going to render when Flutter is
    ///             first initialized. This callback may be used as a signal to
    ///             remove that placeholder.
    ///
    /// @attention  The callback will be invoked on the render thread and not
    ///             the calling thread.
    ///
    /// @param[in]  closure  The callback to execute on the next frame.
    ///
    virtual void OnPlatformViewSetNextFrameCallback(
        const fml::closure& closure) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate the viewport metrics of the platform
    ///             view have been updated. The rasterizer will need to be
    ///             reconfigured to render the frame in the updated viewport
    ///             metrics.
    ///
    /// @param[in]  metrics  The updated viewport metrics.
    ///
    virtual void OnPlatformViewSetViewportMetrics(
        const ViewportMetrics& metrics) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the platform has dispatched a
    ///             platform message from the embedder to the Flutter
    ///             application. This message must be forwarded to the running
    ///             isolate hosted by the engine on the UI thread.
    ///
    /// @param[in]  message  The platform message to dispatch to the running
    ///                      root isolate.
    ///
    virtual void OnPlatformViewDispatchPlatformMessage(
        fml::RefPtr<PlatformMessage> message) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the platform view has encountered
    ///             a pointer event. This pointer event needs to be forwarded to
    ///             the running root isolate hosted by the engine on the UI
    ///             thread.
    ///
    /// @param[in]  packet  The pointer data packet containing multiple pointer
    ///                     events.
    ///
    virtual void OnPlatformViewDispatchPointerDataPacket(
        std::unique_ptr<PointerDataPacket> packet) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the platform view has encountered
    ///             an accessibility related action on the specified node. This
    ///             event must be forwarded to the running root isolate hosted
    ///             by the engine on the UI thread.
    ///
    /// @param[in]  id      The identifier of the accessibility node.
    /// @param[in]  action  The accessibility related action performed on the
    ///                     node of the specified ID.
    /// @param[in]  args    An optional list of argument that apply to the
    ///                     specified action.
    ///
    virtual void OnPlatformViewDispatchSemanticsAction(
        int32_t id,
        SemanticsAction action,
        std::vector<uint8_t> args) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder has expressed an
    ///             opinion about whether the accessibility tree needs to be
    ///             enabled or disabled. This information needs to be forwarded
    ///             to the root isolate running on the UI thread.
    ///
    /// @param[in]  enabled  Whether the accessibility tree is enabled or
    ///                      disabled.
    ///
    virtual void OnPlatformViewSetSemanticsEnabled(bool enabled) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder has expressed an
    ///             opinion about the features to enable in the accessibility
    ///             tree.
    ///
    ///             The engine does not care about the accessibility feature
    ///             flags as all it does is forward this information from the
    ///             embedder to the framework. However, curious readers may
    ///             refer to `AccessibilityFeatures` in `window.dart` for
    ///             currently supported accessibility feature flags.
    ///
    /// @param[in]  flags  The features to enable in the accessibility tree.
    ///
    virtual void OnPlatformViewSetAccessibilityFeatures(int32_t flags) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder has specified a
    ///             texture that it want the rasterizer to composite within the
    ///             Flutter layer tree. All textures must have a unique
    ///             identifier. When the rasterizer encounters an external
    ///             texture within its hierarchy, it gives the embedder a chance
    ///             to update that texture on the raster thread before it
    ///             composites the same on-screen.
    ///
    /// @param[in]  texture  The texture that is being updated by the embedder
    ///                      but composited by Flutter in its own hierarchy.
    ///
    virtual void OnPlatformViewRegisterTexture(
        std::shared_ptr<Texture> texture) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder will no longer
    ///             attempt to composite the specified texture within the layer
    ///             tree. This allows the rasterizer to collect associated
    ///             resources.
    ///
    /// @param[in]  texture_id  The identifier of the texture to unregister. If
    ///                         the texture has not been previously registered,
    ///                         this call does nothing.
    ///
    virtual void OnPlatformViewUnregisterTexture(int64_t texture_id) = 0;

    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder has updated the
    ///             contents of the texture with the specified identifier.
    ///             Typically, Flutter will only render a frame if there is an
    ///             updated layer tree. However, in cases where the layer tree
    ///             is static but one of the externally composited textures has
    ///             been updated by the embedder, the embedder needs to notify
    ///             the rasterizer to render a new frame. In such cases, the
    ///             existing layer tree may be reused with the frame composited
    ///             with all updated external textures.
    ///
    /// @param[in]  texture_id  The identifier of the texture that has been
    ///                         updated.
    ///
    virtual void OnPlatformViewMarkTextureFrameAvailable(
        int64_t texture_id) = 0;
  };

  //----------------------------------------------------------------------------
  /// @brief      Creates a platform view with the specified delegate and task
  ///             runner. The base class by itself does not do much but is
  ///             suitable for use in test environments where full platform
  ///             integration may not be necessary. The platform view may only
  ///             be created, accessed and destroyed on the platform task
  ///             runner.
  ///
  /// @param      delegate      The delegate. This is typically the shell.
  /// @param[in]  task_runners  The task runners used by this platform view.
  ///
  explicit PlatformView(Delegate& delegate, TaskRunners task_runners);

  //----------------------------------------------------------------------------
  /// @brief      Destroys the platform view. The platform view is owned by the
  ///             shell and will be destroyed by the same on the platform tasks
  ///             runner.
  ///
  virtual ~PlatformView();

  //----------------------------------------------------------------------------
  /// @brief      Invoked by the shell to obtain a platform specific vsync
  ///             waiter. It is optional for platforms to override this method
  ///             and provide a custom vsync waiter because a timer based
  ///             fall-back waiter is used by default. However, it is highly
  ///             recommended that platform provide their own Vsync waiter as
  ///             the timer based fall-back will not render frames aligned with
  ///             vsync boundaries.
  ///
  /// @attention  If a timer based fall-back is used, a warning is logged to the
  ///             console. In case this method is overridden in a subclass, it
  ///             must return a valid vsync waiter. Returning null will lead to
  ///             internal errors. If a valid vsync waiter cannot be returned,
  ///             subclasses should just call the based class method instead.
  ///
  /// @return     A vsync waiter. If is an internal error to return a null
  ///             waiter.
  ///
  virtual std::unique_ptr<VsyncWaiter> CreateVSyncWaiter();

  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to dispatch a platform message to a
  ///             running root isolate hosted by the engine. If an isolate is
  ///             not running, the message is dropped. If there is no one on the
  ///             other side listening on the channel, the message is dropped.
  ///             When a platform message is dropped, any response handles
  ///             associated with that message will be dropped as well. All
  ///             users of platform messages must assume that message may not be
  ///             delivered and/or their response handles may not be invoked.
  ///             Platform messages are not buffered.
  ///
  ///             For embedders that wish to respond to platform message
  ///             directed from the framework to the embedder, the
  ///             `HandlePlatformMessage` method may be overridden.
  ///
  /// @see        HandlePlatformMessage()
  ///
  /// @param[in]  message  The platform message to deliver to the root isolate.
  ///
  void DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message);

  //----------------------------------------------------------------------------
  /// @brief      Overridden by embedders to perform actions in response to
  ///             platform messages sent from the framework to the embedder.
  ///             Default implementation of this method simply returns an empty
  ///             response.
  ///
  ///             Embedders that wish to send platform messages to the framework
  ///             may use the `DispatchPlatformMessage` method. This method is
  ///             for messages that go the other way.
  ///
  /// @see        DisplatchPlatformMessage()
  ///
  /// @param[in]  message  The message
  ///
  virtual void HandlePlatformMessage(fml::RefPtr<PlatformMessage> message);

  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to dispatch an accessibility action to a
  ///             running isolate hosted by the engine.
  ///
  /// @param[in]  id      The identifier of the accessibility node on which to
  ///                     perform the action.
  /// @param[in]  action  The action
  /// @param[in]  args    The arguments
  ///
  void DispatchSemanticsAction(int32_t id,
                               SemanticsAction action,
                               std::vector<uint8_t> args);

  //----------------------------------------------------------------------------
  /// @brief      Used by embedder to notify the running isolate hosted by the
  ///             engine on the UI thread that the accessibility tree needs to
  ///             be generated.
  ///
  /// @attention  Subclasses may choose to override this method to perform
  ///             platform specific functions. However, they must call the base
  ///             class method at some point in their implementation.
  ///
  /// @param[in]  enabled  Whether the accessibility tree needs to be generated.
  ///
  virtual void SetSemanticsEnabled(bool enabled);

  //----------------------------------------------------------------------------
  /// @brief      Used by the embedder to specify the features to enable in the
  ///             accessibility tree generated by the isolate. This information
  ///             is forwarded to the root isolate hosted by the engine on the
  ///             UI thread.
  ///
  ///             The engine does not care about the accessibility feature flags
  ///             as all it does is forward this information from the embedder
  ///             to the framework. However, curious readers may refer to
  ///             `AccessibilityFeatures` in `window.dart` for currently
  ///             supported accessibility feature flags.
  ///
  /// @attention  Subclasses may choose to override this method to perform
  ///             platform specific functions. However, they must call the base
  ///             class method at some point in their implementation.
  ///
  /// @param[in]  flags  The features to enable in the accessibility tree.
  ///
  virtual void SetAccessibilityFeatures(int32_t flags);

  //----------------------------------------------------------------------------
  /// @brief      Used by the framework to tell the embedder to apply the
  ///             specified semantics node updates. The default implementation
  ///             of this method does nothing.
  ///
  /// @see        SemanticsNode, SemticsNodeUpdates,
  ///             CustomAccessibilityActionUpdates
  ///
  /// @param[in]  updates  A map with the stable semantics node identifier as
  ///                      key and the node properties as the value.
  /// @param[in]  actions  A map with the stable semantics node identifier as
  ///                      key and the custom node action as the value.
  ///
  virtual void UpdateSemantics(SemanticsNodeUpdates updates,
                               CustomAccessibilityActionUpdates actions);

  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to specify the updated viewport metrics. In
  ///             response to this call, on the raster thread, the rasterizer
  ///             may need to be reconfigured to the updated viewport
  ///             dimensions. On the UI thread, the framework may need to start
  ///             generating a new frame for the updated viewport metrics as
  ///             well.
  ///
  /// @param[in]  metrics  The updated viewport metrics.
  ///
  void SetViewportMetrics(const ViewportMetrics& metrics);

  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to notify the shell that a platform view
  ///             has been created. This notification is used to create a
  ///             rendering surface and pick the client rendering API to use to
  ///             render into this surface. No frames will be scheduled or
  ///             rendered before this call. The surface must remain valid till
  ///             the corresponding call to NotifyDestroyed.
  ///
  void NotifyCreated();

  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to notify the shell that the platform view
  ///             has been destroyed. This notification used to collect the
  ///             rendering surface and all associated resources. Frame
  ///             scheduling is also suspended.
  ///
  /// @attention  Subclasses may choose to override this method to perform
  ///             platform specific functions. However, they must call the base
  ///             class method at some point in their implementation.
  ///
  virtual void NotifyDestroyed();

  //----------------------------------------------------------------------------
  /// @brief      Used by the shell to obtain a Skia GPU context that is capable
  ///             of operating on the IO thread. The context must be in the same
  ///             share-group as the Skia GPU context used on the render thread.
  ///             This context will always be used on the IO thread. Because it
  ///             is in the same share-group as the separate render thread
  ///             context, any GPU resources uploaded in this context will be
  ///             visible to the render thread context (synchronization of GPU
  ///             resources is managed by Skia).
  ///
  ///             If such context cannot be created on the IO thread, callers
  ///             may return `nullptr`. This will mean that all texture uploads
  ///             will be queued onto the render thread which will cause
  ///             performance issues. When this context is `nullptr`, an error
  ///             is logged to the console. It is highly recommended that all
  ///             platforms provide a resource context.
  ///
  /// @attention  Unlike all other methods on the platform view, this will be
  ///             called on IO task runner.
  ///
  /// @return     The Skia GPU context that is in the same share-group as the
  ///             main render thread GPU context. May be `nullptr` in case such
  ///             a context cannot be created.
  ///
  virtual sk_sp<GrContext> CreateResourceContext() const;

  //----------------------------------------------------------------------------
  /// @brief      Used by the shell to notify the embedder that the resource
  ///             context previously obtained via a call to
  ///             `CreateResourceContext()` is being collected. The embedder is
  ///             free to collect an platform specific resources associated with
  ///             this context.
  ///
  /// @attention  Unlike all other methods on the platform view, this will be
  ///             called on IO task runner.
  ///
  virtual void ReleaseResourceContext() const;

  //--------------------------------------------------------------------------
  /// @brief      Returns a platform-specific PointerDataDispatcherMaker so the
  ///             `Engine` can construct the PointerDataPacketDispatcher based
  ///             on platforms.
  virtual PointerDataDispatcherMaker GetDispatcherMaker();

  //----------------------------------------------------------------------------
  /// @brief      Returns a weak pointer to the platform view. Since the
  ///             platform view may only be created, accessed and destroyed
  ///             on the platform thread, any access to the platform view
  ///             from a non-platform task runner needs a weak pointer to
  ///             the platform view along with a reference to the platform
  ///             task runner. A task must be posted to the platform task
  ///             runner with the weak pointer captured in the same. The
  ///             platform view method may only be called in the posted task
  ///             once the weak pointer validity has been checked. This
  ///             method is used by callers to obtain that weak pointer.
  ///
  /// @return     The weak pointer to the platform view.
  ///
  fml::WeakPtr<PlatformView> GetWeakPtr() const;

  //----------------------------------------------------------------------------
  /// @brief      Gives embedders a chance to react to a "cold restart" of the
  ///             running isolate. The default implementation of this method
  ///             does nothing.
  ///
  ///             While a "hot restart" patches a running isolate, a "cold
  ///             restart" restarts the root isolate in a running shell.
  ///
  virtual void OnPreEngineRestart() const;

  //----------------------------------------------------------------------------
  /// @brief      Sets a callback that gets executed when the rasterizer renders
  ///             the next frame. Due to the asynchronous nature of
  ///             rendering in Flutter, embedders usually add a placeholder
  ///             over the contents in which Flutter is going to render when
  ///             Flutter is first initialized. This callback may be used as
  ///             a signal to remove that placeholder. The callback is
  ///             executed on the render task runner and not the platform
  ///             task runner. It is the embedder's responsibility to
  ///             re-thread as necessary.
  ///
  /// @attention  The callback is executed on the render task runner and not the
  ///             platform task runner. Embedders must re-thread as necessary.
  ///
  /// @param[in]  closure  The callback to execute on the render thread when the
  ///                      next frame gets rendered.
  ///
  void SetNextFrameCallback(const fml::closure& closure);

  //----------------------------------------------------------------------------
  /// @brief      Dispatches pointer events from the embedder to the
  ///             framework. Each pointer data packet may contain multiple
  ///             pointer input events. Each call to this method wakes up
  ///             the UI thread.
  ///
  /// @param[in]  packet  The pointer data packet to dispatch to the framework.
  ///
  void DispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet);

  //--------------------------------------------------------------------------
  /// @brief      Used by the embedder to specify a texture that it wants the
  ///             rasterizer to composite within the Flutter layer tree. All
  ///             textures must have a unique identifier. When the
  ///             rasterizer encounters an external texture within its
  ///             hierarchy, it gives the embedder a chance to update that
  ///             texture on the raster thread before it composites the same
  ///             on-screen.
  ///
  /// @attention  This method must only be called once per texture. When the
  ///             texture is updated, calling `MarkTextureFrameAvailable`
  ///             with the specified texture identifier is sufficient to
  ///             make Flutter re-render the frame with the updated texture
  ///             composited in-line.
  ///
  /// @see        UnregisterTexture, MarkTextureFrameAvailable
  ///
  /// @param[in]  texture  The texture that is being updated by the embedder
  ///                      but composited by Flutter in its own hierarchy.
  ///
  void RegisterTexture(std::shared_ptr<flutter::Texture> texture);

  //--------------------------------------------------------------------------
  /// @brief      Used by the embedder to notify the rasterizer that it will
  /// no
  ///             longer attempt to composite the specified texture within
  ///             the layer tree. This allows the rasterizer to collect
  ///             associated resources.
  ///
  /// @attention  This call must only be called once per texture identifier.
  ///
  /// @see        RegisterTexture, MarkTextureFrameAvailable
  ///
  /// @param[in]  texture_id  The identifier of the texture to unregister. If
  ///                         the texture has not been previously registered,
  ///                         this call does nothing.
  ///
  void UnregisterTexture(int64_t texture_id);

  //--------------------------------------------------------------------------
  /// @brief      Used by the embedder to notify the rasterizer that the context
  ///             of the previously registered texture have been updated.
  ///             Typically, Flutter will only render a frame if there is an
  ///             updated layer tree. However, in cases where the layer tree
  ///             is static but one of the externally composited textures
  ///             has been updated by the embedder, the embedder needs to
  ///             notify the rasterizer to render a new frame. In such
  ///             cases, the existing layer tree may be reused with the
  ///             frame re-composited with all updated external textures.
  ///             Unlike the calls to register and unregister the texture,
  ///             this call must be made each time a new texture frame is
  ///             available.
  ///
  /// @see        RegisterTexture, UnregisterTexture
  ///
  /// @param[in]  texture_id  The identifier of the texture that has been
  ///                         updated.
  ///
  void MarkTextureFrameAvailable(int64_t texture_id);

 protected:
  PlatformView::Delegate& delegate_;
  const TaskRunners task_runners_;

  PointerDataPacketConverter pointer_data_packet_converter_;
  SkISize size_;
  fml::WeakPtrFactory<PlatformView> weak_factory_;

  // Unlike all other methods on the platform view, this is called on the
  // GPU task runner.
  virtual std::unique_ptr<Surface> CreateRenderingSurface();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace flutter

#endif  // COMMON_PLATFORM_VIEW_H_
