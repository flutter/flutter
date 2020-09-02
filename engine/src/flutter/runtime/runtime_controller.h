// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
#define FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_

#include <memory>
#include <vector>

#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/macros.h"
#include "flutter/lib/ui/io_manager.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/platform_data.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"

namespace flutter {

class Scene;
class RuntimeDelegate;
class View;
class Window;

//------------------------------------------------------------------------------
/// Represents an instance of a running root isolate with window bindings. In
/// normal operation, a single instance of this object is owned by the engine
/// per shell. This object may only be created, used, and collected on the UI
/// task runner. Window state queried by the root isolate is stored by this
/// object. In cold-restart scenarios, the engine may collect this before
/// installing a new runtime controller in its place. The Clone method may be
/// used by the engine to copy the currently accumulated window state so it can
/// be referenced by the new runtime controller.
///
class RuntimeController : public PlatformConfigurationClient {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Creates a new instance of a runtime controller. This is
  ///             usually only done by the engine instance associated with the
  ///             shell.
  ///
  /// @param      client                      The runtime delegate. This is
  ///                                         usually the `Engine` instance.
  /// @param      vm                          A reference to a running Dart VM.
  ///                                         The runtime controller must be
  ///                                         collected before the VM is
  ///                                         destroyed (this order is
  ///                                         guaranteed by the shell).
  /// @param[in]  isolate_snapshot            The isolate snapshot used to start
  ///                                         the root isolate managed by this
  ///                                         runtime controller. The isolate
  ///                                         must be transitioned into the
  ///                                         running phase manually by the
  ///                                         caller.
  /// @param[in]  task_runners                The task runners used by the shell
  ///                                         hosting this runtime controller.
  ///                                         This may be used by the isolate to
  ///                                         scheduled asynchronous texture
  ///                                         uploads or post tasks to the
  ///                                         platform task runner.
  /// @param[in]  snapshot_delegate           The snapshot delegate used by the
  ///                                         isolate to gather raster snapshots
  ///                                         of Flutter view hierarchies.
  /// @param[in]  io_manager                  The IO manager used by the isolate
  ///                                         for asynchronous texture uploads.
  /// @param[in]  unref_queue                 The unref queue used by the
  ///                                         isolate to collect resources that
  ///                                         may reference resources on the
  ///                                         GPU.
  /// @param[in]  image_decoder               The image decoder
  /// @param[in]  advisory_script_uri         The advisory script URI (only used
  ///                                         for debugging). This does not
  ///                                         affect the code being run in the
  ///                                         isolate in any way.
  /// @param[in]  advisory_script_entrypoint  The advisory script entrypoint
  ///                                         (only used for debugging). This
  ///                                         does not affect the code being run
  ///                                         in the isolate in any way. The
  ///                                         isolate must be transitioned to
  ///                                         the running state explicitly by
  ///                                         the caller.
  /// @param[in]  idle_notification_callback  The idle notification callback.
  ///                                         This allows callers to run native
  ///                                         code in isolate scope when the VM
  ///                                         is about to be notified that the
  ///                                         engine is going to be idle.
  /// @param[in]  platform_data                 The window data (if exists).
  /// @param[in]  isolate_create_callback     The isolate create callback. This
  ///                                         allows callers to run native code
  ///                                         in isolate scope on the UI task
  ///                                         runner as soon as the root isolate
  ///                                         has been created.
  /// @param[in]  isolate_shutdown_callback   The isolate shutdown callback.
  ///                                         This allows callers to run native
  ///                                         code in isolate scoped on the UI
  ///                                         task runner just as the root
  ///                                         isolate is about to be torn down.
  /// @param[in]  persistent_isolate_data     Unstructured persistent read-only
  ///                                         data that the root isolate can
  ///                                         access in a synchronous manner.
  ///
  RuntimeController(
      RuntimeDelegate& client,
      DartVM* vm,
      fml::RefPtr<const DartSnapshot> isolate_snapshot,
      TaskRunners task_runners,
      fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
      fml::WeakPtr<IOManager> io_manager,
      fml::RefPtr<SkiaUnrefQueue> unref_queue,
      fml::WeakPtr<ImageDecoder> image_decoder,
      std::string advisory_script_uri,
      std::string advisory_script_entrypoint,
      const std::function<void(int64_t)>& idle_notification_callback,
      const PlatformData& platform_data,
      const fml::closure& isolate_create_callback,
      const fml::closure& isolate_shutdown_callback,
      std::shared_ptr<const fml::Mapping> persistent_isolate_data);

  // |PlatformConfigurationClient|
  ~RuntimeController() override;

  //----------------------------------------------------------------------------
  /// @brief      Clone the the runtime controller. This re-creates the root
  ///             isolate with the same snapshots and copies all window data to
  ///             the new instance. This is usually only used in the debug
  ///             runtime mode to support the cold-restart scenario.
  ///
  /// @return     A clone of the existing runtime controller.
  ///
  std::unique_ptr<RuntimeController> Clone() const;

  //----------------------------------------------------------------------------
  /// @brief      Forward the specified viewport metrics to the running isolate.
  ///             If the isolate is not running, these metrics will be saved and
  ///             flushed to the isolate when it starts.
  ///
  /// @param[in]  metrics  The viewport metrics.
  ///
  /// @return     If the window metrics were forwarded to the running isolate.
  ///
  bool SetViewportMetrics(const ViewportMetrics& metrics);

  //----------------------------------------------------------------------------
  /// @brief      Forward the specified locale data to the running isolate. If
  ///             the isolate is not running, this data will be saved and
  ///             flushed to the isolate when it starts running.
  ///
  /// @deprecated The persistent isolate data must be used for this purpose
  ///             instead.
  ///
  /// @param[in]  locale_data  The locale data. This should consist of groups of
  ///             4 strings, each group representing a single locale.
  ///
  /// @return     If the locale data was forwarded to the running isolate.
  ///
  bool SetLocales(const std::vector<std::string>& locale_data);

  //----------------------------------------------------------------------------
  /// @brief      Forward the user settings data to the running isolate. If the
  ///             isolate is not running, this data will be saved and flushed to
  ///             the isolate when it starts running.
  ///
  /// @deprecated The persistent isolate data must be used for this purpose
  ///             instead.
  ///
  /// @param[in]  data  The user settings data.
  ///
  /// @return     If the user settings data was forwarded to the running
  ///             isolate.
  ///
  bool SetUserSettingsData(const std::string& data);

  //----------------------------------------------------------------------------
  /// @brief      Forward the lifecycle state data to the running isolate. If
  ///             the isolate is not running, this data will be saved and
  ///             flushed to the isolate when it starts running.
  ///
  /// @deprecated The persistent isolate data must be used for this purpose
  ///             instead.
  ///
  /// @param[in]  data  The lifecycle state data.
  ///
  /// @return     If the lifecycle state data was forwarded to the running
  ///             isolate.
  ///
  bool SetLifecycleState(const std::string& data);

  //----------------------------------------------------------------------------
  /// @brief      Notifies the running isolate about whether the semantics tree
  ///             should be generated or not. If the isolate is not running,
  ///             this preference will be saved and flushed to the isolate when
  ///             it starts running.
  ///
  /// @param[in]  enabled  Indicates whether to generate the semantics tree.
  ///
  /// @return     If the semantics tree generation preference was forwarded to
  ///             the running isolate.
  ///
  bool SetSemanticsEnabled(bool enabled);

  //----------------------------------------------------------------------------
  /// @brief      Forward the preference of accessibility features that must be
  ///             enabled in the semantics tree to the running isolate. If the
  ///             isolate is not running, this data will be saved and flushed to
  ///             the isolate when it starts running.
  ///
  /// @param[in]  flags  The accessibility features that must be generated in
  ///             the semantics tree.
  ///
  /// @return     If the preference of accessibility features was forwarded to
  ///             the running isolate.
  ///
  bool SetAccessibilityFeatures(int32_t flags);

  //----------------------------------------------------------------------------
  /// @brief      Notifies the running isolate that it should start generating a
  ///             new frame.
  ///
  /// @see        `Engine::BeginFrame` for more context.
  ///
  /// @param[in]  frame_time  The point at which the current frame interval
  ///                         began. May be used by animation interpolators,
  ///                         physics simulations, etc.
  ///
  /// @return     If notification to begin frame rendering was delivered to the
  ///             running isolate.
  ///
  bool BeginFrame(fml::TimePoint frame_time);

  //----------------------------------------------------------------------------
  /// @brief      Dart code cannot fully measure the time it takes for a
  ///             specific frame to be rendered. This is because Dart code only
  ///             runs on the UI task runner. That is only a small part of the
  ///             overall frame workload. The GPU task runner frame workload is
  ///             executed on a thread where Dart code cannot run (and hence
  ///             instrument). Besides, due to the pipelined nature of rendering
  ///             in Flutter, there may be multiple frame workloads being
  ///             processed at any given time. However, for non-Timeline based
  ///             profiling, it is useful for trace collection and processing to
  ///             happen in Dart. To do this, the GPU task runner frame
  ///             workloads need to be instrumented separately. After a set
  ///             number of these profiles have been gathered, they need to be
  ///             reported back to Dart code. The engine reports this extra
  ///             instrumentation information back to Dart code running on the
  ///             engine by invoking this method at predefined intervals.
  ///
  /// @see        `Engine::ReportTimings`, `FrameTiming`
  ///
  /// @param[in]  timings  Collection of `FrameTiming::kCount` * `n` timestamps
  ///                      for `n` frames whose timings have not been reported
  ///                      yet. A collection of integers is reported here for
  ///                      easier conversions to Dart objects. The timestamps
  ///                      are measured against the system monotonic clock
  ///                      measured in microseconds.
  ///
  bool ReportTimings(std::vector<int64_t> timings);

  //----------------------------------------------------------------------------
  /// @brief      Notify the Dart VM that no frame workloads are expected on the
  ///             UI task runner till the specified deadline. The VM uses this
  ///             opportunity to perform garbage collection operations is a
  ///             manner that interferes as little as possible with frame
  ///             rendering.
  ///
  /// NotifyIdle is advisory. The VM may or may not run a garbage collection
  /// when this is called, and will eventually perform garbage collections even
  /// if it is not called or it is called with insufficient deadlines.
  ///
  /// The garbage collection mechanism and its thresholds are internal
  /// implementation details and absolutely no guarantees are made about the
  /// threshold discussed below. This discussion is also an oversimplification
  /// but hopefully serves to calibrate expectations about GC behavior:
  /// * When the Dart VM and its root isolate are initialized, the memory
  ///   consumed upto that point are treated as a baseline.
  /// * A fixed percentage of the memory consumed (~20%) over the baseline is
  ///   treated as the hard threshold.
  /// * The memory in play is divided into old space and new space. The new
  ///   space is typically very small and fills up rapidly.
  /// * The baseline plus the threshold is considered the old space while the
  ///   small new space is a separate region (typically a few pages).
  /// * The total old space size minus the max new space size is treated as the
  ///   soft threshold.
  /// * In a world where there is no call to NotifyIdle, when the total
  ///   allocation exceeds the soft threshold, a concurrent mark is initiated in
  ///   the VM. There is a “small” pause that occurs when the concurrent mark is
  ///   initiated and another pause when the mark concludes and a sweep is
  ///   initiated.
  /// * If the total allocations exceeds the the hard threshold, a “big”
  ///   stop-the-world pause is initiated.
  /// * If after either the sweep after the concurrent mark, or, the
  ///   stop-the-world pause, the consumption returns to be below the soft
  ///   threshold, the dance begins anew.
  /// * If after both the “small” and “big” pauses, memory usage is still over
  ///   the hard threshold, i.e, the objects are still reachable, that amount of
  ///   memory is treated as the new baseline and a fixed percentage of the new
  ///   baseline over the new baseline is now the new hard threshold.
  /// * Updating the baseline will continue till memory for the updated old
  ///   space can be allocated from the operating system. These allocations will
  ///   typically fail due to address space exhaustion on 32-bit systems and
  ///   page table exhaustion on 64-bit systems.
  /// * NotifyIdle initiates the concurrent mark preemptively. The deadline is
  ///   used by the VM to determine if the corresponding sweep can be performed
  ///   within the deadline. This way, jank due to “small” pauses can be
  ///   ameliorated.
  /// * There is no ability to stop a “big” pause on reaching the hard threshold
  ///   in the old space. The best you can do is release (by making them
  ///   unreachable) objects eagerly so that the are marked as unreachable in
  ///   the concurrent mark initiated by either reaching the soft threshold or
  ///   an explicit NotifyIdle.
  /// * If you are running out of memory, its because too many large objects
  ///   were allocation and remained reachable such that the the old space kept
  ///   growing till it could grow no more.
  /// * At the edges of allocation thresholds, failures can occur gracefully if
  ///   the instigating allocation was made in the Dart VM or rather gracelessly
  ///   if the allocation is made by some native component.
  ///
  /// @see        `Dart_TimelineGetMicros`
  ///
  /// @bug        The `deadline` argument must be converted to `std::chrono`
  ///             instead of a raw integer.
  ///
  /// @param[in]  deadline  The deadline measures in microseconds against the
  ///             system's monotonic time. The clock can be accessed via
  ///             `Dart_TimelineGetMicros`.
  ///
  /// @return     If the idle notification was forwarded to the running isolate.
  ///
  bool NotifyIdle(int64_t deadline);

  //----------------------------------------------------------------------------
  /// @brief      Returns if the root isolate is running. The isolate must be
  ///             transitioned to the running phase manually. The isolate can
  ///             stop running if it terminates execution on its own.
  ///
  /// @return     True if root isolate running, False otherwise.
  ///
  virtual bool IsRootIsolateRunning() const;

  //----------------------------------------------------------------------------
  /// @brief      Dispatch the specified platform message to running root
  ///             isolate.
  ///
  /// @param[in]  message  The message to dispatch to the isolate.
  ///
  /// @return     If the message was dispatched to the running root isolate.
  ///             This may fail is an isolate is not running.
  ///
  virtual bool DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message);

  //----------------------------------------------------------------------------
  /// @brief      Dispatch the specified pointer data message to the running
  ///             root isolate.
  ///
  /// @param[in]  packet  The pointer data message to dispatch to the isolate.
  ///
  /// @return     If the pointer data message was dispatched. This may fail is
  ///             an isolate is not running.
  ///
  bool DispatchPointerDataPacket(const PointerDataPacket& packet);

  //----------------------------------------------------------------------------
  /// @brief      Dispatch the semantics action to the specified accessibility
  ///             node.
  ///
  /// @param[in]  id      The identified of the accessibility node.
  /// @param[in]  action  The semantics action to perform on the specified
  ///                     accessibility node.
  /// @param[in]  args    Optional data that applies to the specified action.
  ///
  /// @return     If the semantics action was dispatched. This may fail if an
  ///             isolate is not running.
  ///
  bool DispatchSemanticsAction(int32_t id,
                               SemanticsAction action,
                               std::vector<uint8_t> args);

  //----------------------------------------------------------------------------
  /// @brief      Gets the main port identifier of the root isolate.
  ///
  /// @return     The main port identifier. If no root isolate is running,
  ///             returns `ILLEGAL_PORT`.
  ///
  Dart_Port GetMainPort();

  //----------------------------------------------------------------------------
  /// @brief      Gets the debug name of the root isolate. But default, the
  ///             debug name of the isolate is derived from its advisory script
  ///             URI, advisory main entrypoint and its main port name. For
  ///             example, "main.dart$main-1234" where the script URI is
  ///             "main.dart", the entrypoint is "main" and the port name
  ///             "1234". Once launched, the isolate may re-christen itself
  ///             using a name it selects via `setIsolateDebugName` in
  ///             `window.dart`. This name is purely advisory and only used by
  ///             instrumentation and reporting purposes.
  ///
  /// @return     The debug name of the root isolate.
  ///
  std::string GetIsolateName();

  //----------------------------------------------------------------------------
  /// @brief      Returns if the root isolate has any live receive ports.
  ///
  /// @return     True if there are live receive ports, False otherwise. Return
  ///             False if the root isolate is not running as well.
  ///
  bool HasLivePorts();

  //----------------------------------------------------------------------------
  /// @brief      Get the last error encountered by the microtask queue.
  ///
  /// @return     The last error encountered by the microtask queue.
  ///
  tonic::DartErrorHandleType GetLastError();

  //----------------------------------------------------------------------------
  /// @brief      Get a weak pointer to the root Dart isolate. This isolate may
  ///             only be locked on the UI task runner. Callers use this
  ///             accessor to transition to the root isolate to the running
  ///             phase.
  ///
  /// @return     The root isolate reference.
  ///
  std::weak_ptr<DartIsolate> GetRootIsolate();

  //----------------------------------------------------------------------------
  /// @brief      Get the return code specified by the root isolate (if one is
  ///             present).
  ///
  /// @bug        Change this method to return `std::optional<uint32_t>`
  ///             instead.
  ///
  /// @return     The root isolate return code. The first argument in the pair
  ///             indicates if one is specified by the root isolate.
  ///
  std::pair<bool, uint32_t> GetRootIsolateReturnCode();

 protected:
  /// Constructor for Mocks.
  RuntimeController(RuntimeDelegate& client, TaskRunners p_task_runners);

 private:
  struct Locale {
    Locale(std::string language_code_,
           std::string country_code_,
           std::string script_code_,
           std::string variant_code_);

    ~Locale();

    std::string language_code;
    std::string country_code;
    std::string script_code;
    std::string variant_code;
  };

  RuntimeDelegate& client_;
  DartVM* const vm_;
  fml::RefPtr<const DartSnapshot> isolate_snapshot_;
  TaskRunners task_runners_;
  fml::WeakPtr<SnapshotDelegate> snapshot_delegate_;
  fml::WeakPtr<IOManager> io_manager_;
  fml::RefPtr<SkiaUnrefQueue> unref_queue_;
  fml::WeakPtr<ImageDecoder> image_decoder_;
  std::string advisory_script_uri_;
  std::string advisory_script_entrypoint_;
  std::function<void(int64_t)> idle_notification_callback_;
  PlatformData platform_data_;
  std::weak_ptr<DartIsolate> root_isolate_;
  std::pair<bool, uint32_t> root_isolate_return_code_ = {false, 0};
  const fml::closure isolate_create_callback_;
  const fml::closure isolate_shutdown_callback_;
  std::shared_ptr<const fml::Mapping> persistent_isolate_data_;

  PlatformConfiguration* GetPlatformConfigurationIfAvailable();

  bool FlushRuntimeStateToIsolate();

  // |PlatformConfigurationClient|
  std::string DefaultRouteName() override;

  // |PlatformConfigurationClient|
  void ScheduleFrame() override;

  // |PlatformConfigurationClient|
  void Render(Scene* scene) override;

  // |PlatformConfigurationClient|
  void UpdateSemantics(SemanticsUpdate* update) override;

  // |PlatformConfigurationClient|
  void HandlePlatformMessage(fml::RefPtr<PlatformMessage> message) override;

  // |PlatformConfigurationClient|
  FontCollection& GetFontCollection() override;

  // |PlatformConfigurationClient|
  void UpdateIsolateDescription(const std::string isolate_name,
                                int64_t isolate_port) override;

  // |PlatformConfigurationClient|
  void SetNeedsReportTimings(bool value) override;

  // |PlatformConfigurationClient|
  std::shared_ptr<const fml::Mapping> GetPersistentIsolateData() override;

  // |PlatformConfigurationClient|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocale(
      const std::vector<std::string>& supported_locale_data) override;

  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeController);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
