// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Visibility enum matching ASURFACE_TRANSACTION_VISIBILITY_*.
enum class AndroidSurfaceControlVisibility : int8_t {
  kHide = 0,
  kShow = 1,
};

/// @brief Transform enum matching ASURFACE_TRANSFORM_*.
enum class AndroidSurfaceControlTransform : int32_t {
  kIdentity = 0,
  kMirrorHorizontal = 1,
  kMirrorVertical = 2,
  kRotate180 = 3,
  kRotate90 = 4,
  kRotate270 = 7,
};

/// @brief 2D integer rectangle matching Android ARect.
struct AndroidSurfaceControlRect {
  int32_t left = 0;
  int32_t top = 0;
  int32_t right = 0;
  int32_t bottom = 0;

  int32_t Width() const { return right - left; }
  int32_t Height() const { return bottom - top; }
  bool IsEmpty() const { return left >= right || top >= bottom; }

  bool operator==(const AndroidSurfaceControlRect& other) const {
    return left == other.left && top == other.top && right == other.right &&
           bottom == other.bottom;
  }

  bool operator!=(const AndroidSurfaceControlRect& other) const {
    return !(*this == other);
  }
};

/// @brief Presentation and completion stats matching ASurfaceTransactionStats.
struct AndroidSurfaceControlStats {
  int previous_release_fence_fd = -1;
  int64_t present_time_nanos = 0;
  int64_t latch_time_nanos = 0;

  bool operator==(const AndroidSurfaceControlStats& other) const {
    return previous_release_fence_fd == other.previous_release_fence_fd &&
           present_time_nanos == other.present_time_nanos &&
           latch_time_nanos == other.latch_time_nanos;
  }

  bool operator!=(const AndroidSurfaceControlStats& other) const {
    return !(*this == other);
  }
};

/// @brief RGBA float color representation for surface background coloring.
struct AndroidSurfaceControlColor {
  float r = 0.0f;
  float g = 0.0f;
  float b = 0.0f;
  float a = 1.0f;

  bool operator==(const AndroidSurfaceControlColor& other) const {
    return r == other.r && g == other.g && b == other.b && a == other.a;
  }

  bool operator!=(const AndroidSurfaceControlColor& other) const {
    return !(*this == other);
  }
};

/// @brief Comprehensive state snapshot of an AndroidSurfaceControl node.
struct AndroidSurfaceControlState {
  uint64_t id = 0;
  std::string debug_name;
  void* handle = nullptr;
  void* parent_handle = nullptr;
  uint64_t parent_id = 0;
  bool is_valid = true;
  int32_t ref_count = 1;
  AndroidSurfaceControlVisibility visibility =
      AndroidSurfaceControlVisibility::kShow;
  int32_t z_order = 0;
  AndroidSurfaceControlRect source_rect;
  AndroidSurfaceControlRect destination_rect;
  AndroidSurfaceControlTransform transform =
      AndroidSurfaceControlTransform::kIdentity;
  std::vector<AndroidSurfaceControlRect> damage_region;
  void* buffer_handle = nullptr;
  int buffer_fence_fd = -1;
  float alpha = 1.0f;
  AndroidSurfaceControlColor color;

  bool operator==(const AndroidSurfaceControlState& other) const {
    return id == other.id && debug_name == other.debug_name &&
           handle == other.handle && parent_handle == other.parent_handle &&
           parent_id == other.parent_id && is_valid == other.is_valid &&
           ref_count == other.ref_count && visibility == other.visibility &&
           z_order == other.z_order && source_rect == other.source_rect &&
           destination_rect == other.destination_rect &&
           transform == other.transform &&
           damage_region == other.damage_region &&
           buffer_handle == other.buffer_handle &&
           buffer_fence_fd == other.buffer_fence_fd && alpha == other.alpha &&
           color == other.color;
  }

  bool operator!=(const AndroidSurfaceControlState& other) const {
    return !(*this == other);
  }
};

class DefaultAndroidSurfaceControlProvider;
class InMemoryAndroidSurfaceControlProvider;

/// @brief Abstract C++ wrapper for an ASurfaceControl node in the compositor
/// hierarchy.
class AndroidSurfaceControl {
 public:
  virtual ~AndroidSurfaceControl() = default;

  /// @brief Returns the native ASurfaceControl* handle.
  virtual void* GetHandle() const = 0;

  /// @brief Returns the debug name assigned to this surface control.
  virtual const std::string& GetDebugName() const = 0;

  /// @brief Returns the unique identifier of this surface control node.
  virtual uint64_t GetId() const = 0;

  /// @brief Returns whether this surface control is valid.
  virtual bool IsValid() const = 0;

  /// @brief Increments the reference count of this surface control.
  virtual void Acquire() = 0;

  /// @brief Decrements the reference count of this surface control.
  virtual void Release() = 0;

  /// @brief Removes this surface control from its parent hierarchy.
  virtual bool RemoveFromParent() = 0;

  /// @brief Returns the parent native handle if any.
  virtual void* GetParentHandle() const = 0;

  /// @brief Returns the parent surface control ID if known.
  virtual uint64_t GetParentId() const = 0;
};

/// @brief Abstract C++ wrapper for an ASurfaceTransaction atomic update batch.
class AndroidSurfaceTransaction {
 public:
  using OnCompleteCallback =
      std::function<void(const AndroidSurfaceControlStats&)>;

  virtual ~AndroidSurfaceTransaction() = default;

  /// @brief Returns the native ASurfaceTransaction* handle.
  virtual void* GetHandle() const = 0;

  /// @brief Returns whether this transaction is valid.
  virtual bool IsValid() const = 0;

  /// @brief Sets the visibility of a surface control in this transaction.
  virtual bool SetVisibility(AndroidSurfaceControl* surface_control,
                             AndroidSurfaceControlVisibility visibility) = 0;

  /// @brief Sets the z-order (layer stack order) of a surface control.
  virtual bool SetZOrder(AndroidSurfaceControl* surface_control,
                         int32_t z_order) = 0;

  /// @brief Sets the backing AHardwareBuffer and acquire fence on a surface
  /// control.
  virtual bool SetBuffer(AndroidSurfaceControl* surface_control,
                         void* hardware_buffer,
                         int acquire_fence_fd = -1) = 0;

  /// @brief Sets geometry crop, scaling, and transform on a surface control.
  virtual bool SetGeometry(AndroidSurfaceControl* surface_control,
                           const AndroidSurfaceControlRect& source,
                           const AndroidSurfaceControlRect& destination,
                           AndroidSurfaceControlTransform transform =
                               AndroidSurfaceControlTransform::kIdentity) = 0;

  /// @brief Sets damage regions on a surface control.
  virtual bool SetDamageRegion(
      AndroidSurfaceControl* surface_control,
      const std::vector<AndroidSurfaceControlRect>& rects) = 0;

  /// @brief Sets buffer alpha transparency (0.0f - 1.0f) on a surface control.
  virtual bool SetBufferAlpha(AndroidSurfaceControl* surface_control,
                              float alpha) = 0;

  /// @brief Sets solid background color on a surface control.
  virtual bool SetColor(AndroidSurfaceControl* surface_control,
                        float r,
                        float g,
                        float b,
                        float alpha) = 0;

  /// @brief Reparents a surface control under a new parent node.
  virtual bool Reparent(AndroidSurfaceControl* surface_control,
                        AndroidSurfaceControl* new_parent) = 0;

  /// @brief Registers an on-complete callback for transaction commitment.
  virtual bool SetOnComplete(OnCompleteCallback callback) = 0;

  /// @brief Applies and commits all pending operations in this transaction.
  virtual bool Apply() = 0;
};

/// @brief Abstract provider interface for ASurfaceControl / ASurfaceTransaction
/// virtualization.
class AndroidSurfaceControlProvider {
 public:
  virtual ~AndroidSurfaceControlProvider() = default;

  /// @brief Returns whether SurfaceControl is supported and available on this
  /// platform.
  virtual bool IsAvailable() const = 0;

  /// @brief Creates a surface control as a child of a window (e.g.
  /// ANativeWindow*).
  virtual std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* window,
      const std::string& debug_name = "FlutterParentControl") = 0;

  /// @brief Creates a child surface control under an existing surface control
  /// parent.
  virtual std::unique_ptr<AndroidSurfaceControl> Create(
      AndroidSurfaceControl* parent,
      const std::string& debug_name = "FlutterChildControl") = 0;

  /// @brief Wraps an existing native ASurfaceControl* handle.
  virtual std::unique_ptr<AndroidSurfaceControl> CreateFromNativeHandle(
      void* handle,
      const std::string& debug_name = "",
      bool take_ownership = false) = 0;

  /// @brief Allocates a new atomic surface transaction.
  virtual std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() = 0;

  /// @brief Wraps an existing native ASurfaceTransaction* handle.
  virtual std::unique_ptr<AndroidSurfaceTransaction>
  CreateTransactionFromNativeHandle(void* handle,
                                    bool take_ownership = false) = 0;

  /// @brief Increments reference count on a native ASurfaceControl* handle.
  virtual void Acquire(void* handle) = 0;

  /// @brief Decrements reference count on a native ASurfaceControl* handle.
  virtual void Release(void* handle) = 0;

  /// @brief Deletes a native ASurfaceTransaction* handle.
  virtual void DeleteTransaction(void* transaction_handle) = 0;

  /// @brief Applies a native ASurfaceTransaction* handle.
  virtual bool ApplyTransaction(void* transaction_handle) = 0;

  /// @brief Reparents a surface control handle via a transaction handle.
  virtual bool Reparent(void* transaction_handle,
                        void* surface_control_handle,
                        void* new_parent_handle) = 0;

  /// @brief Sets visibility via a transaction handle.
  virtual bool SetVisibility(void* transaction_handle,
                             void* surface_control_handle,
                             int8_t visibility) = 0;

  /// @brief Sets z-order via a transaction handle.
  virtual bool SetZOrder(void* transaction_handle,
                         void* surface_control_handle,
                         int32_t z_order) = 0;

  /// @brief Sets buffer and fence via a transaction handle.
  virtual bool SetBuffer(void* transaction_handle,
                         void* surface_control_handle,
                         void* hardware_buffer,
                         int acquire_fence_fd) = 0;

  /// @brief Sets geometry via a transaction handle.
  virtual bool SetGeometry(void* transaction_handle,
                           void* surface_control_handle,
                           const AndroidSurfaceControlRect* source,
                           const AndroidSurfaceControlRect* destination,
                           int32_t transform) = 0;

  /// @brief Sets damage region rects via a transaction handle.
  virtual bool SetDamageRegion(void* transaction_handle,
                               void* surface_control_handle,
                               const AndroidSurfaceControlRect* rects,
                               uint32_t count) = 0;

  /// @brief Sets buffer alpha via a transaction handle.
  virtual bool SetBufferAlpha(void* transaction_handle,
                              void* surface_control_handle,
                              float alpha) = 0;

  /// @brief Sets solid color via a transaction handle.
  virtual bool SetColor(void* transaction_handle,
                        void* surface_control_handle,
                        float r,
                        float g,
                        float b,
                        float alpha) = 0;

  /// @brief Registers an on-complete callback via a transaction handle.
  virtual bool SetOnComplete(
      void* transaction_handle,
      std::function<void(const AndroidSurfaceControlStats&)> callback) = 0;
};

/// @brief Default production implementation wrapping ASurfaceControl*.
class DefaultAndroidSurfaceControl : public AndroidSurfaceControl {
 public:
  DefaultAndroidSurfaceControl(
      void* handle,
      std::string debug_name,
      uint64_t id,
      void* parent_handle,
      uint64_t parent_id,
      bool owns_handle,
      std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider);
  ~DefaultAndroidSurfaceControl() override;

  void* GetHandle() const override;
  const std::string& GetDebugName() const override;
  uint64_t GetId() const override;
  bool IsValid() const override;
  void Acquire() override;
  void Release() override;
  bool RemoveFromParent() override;
  void* GetParentHandle() const override;
  uint64_t GetParentId() const override;

 private:
  void* handle_ = nullptr;
  std::string debug_name_;
  uint64_t id_ = 0;
  void* parent_handle_ = nullptr;
  uint64_t parent_id_ = 0;
  bool owns_handle_ = true;
  std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceControl);
};

/// @brief Default production implementation wrapping ASurfaceTransaction*.
class DefaultAndroidSurfaceTransaction : public AndroidSurfaceTransaction {
 public:
  DefaultAndroidSurfaceTransaction(
      void* handle,
      bool owns_handle,
      std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider);
  ~DefaultAndroidSurfaceTransaction() override;

  void* GetHandle() const override;
  bool IsValid() const override;

  bool SetVisibility(AndroidSurfaceControl* surface_control,
                     AndroidSurfaceControlVisibility visibility) override;
  bool SetZOrder(AndroidSurfaceControl* surface_control,
                 int32_t z_order) override;
  bool SetBuffer(AndroidSurfaceControl* surface_control,
                 void* hardware_buffer,
                 int acquire_fence_fd = -1) override;
  bool SetGeometry(AndroidSurfaceControl* surface_control,
                   const AndroidSurfaceControlRect& source,
                   const AndroidSurfaceControlRect& destination,
                   AndroidSurfaceControlTransform transform =
                       AndroidSurfaceControlTransform::kIdentity) override;
  bool SetDamageRegion(
      AndroidSurfaceControl* surface_control,
      const std::vector<AndroidSurfaceControlRect>& rects) override;
  bool SetBufferAlpha(AndroidSurfaceControl* surface_control,
                      float alpha) override;
  bool SetColor(AndroidSurfaceControl* surface_control,
                float r,
                float g,
                float b,
                float alpha) override;
  bool Reparent(AndroidSurfaceControl* surface_control,
                AndroidSurfaceControl* new_parent) override;
  bool SetOnComplete(OnCompleteCallback callback) override;
  bool Apply() override;

 private:
  void* handle_ = nullptr;
  bool owns_handle_ = true;
  std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider_;
  OnCompleteCallback on_complete_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceTransaction);
};

/// @brief Default dynamic provider that resolves
/// ASurfaceControl/ASurfaceTransaction symbols dynamically via OSLibraryLoader
/// from libandroid.so.
class DefaultAndroidSurfaceControlProvider
    : public AndroidSurfaceControlProvider,
      public std::enable_shared_from_this<
          DefaultAndroidSurfaceControlProvider> {
 public:
  explicit DefaultAndroidSurfaceControlProvider(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr);
  ~DefaultAndroidSurfaceControlProvider() override;

  bool IsAvailable() const override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* window,
      const std::string& debug_name = "FlutterParentControl") override;

  std::unique_ptr<AndroidSurfaceControl> Create(
      AndroidSurfaceControl* parent,
      const std::string& debug_name = "FlutterChildControl") override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromNativeHandle(
      void* handle,
      const std::string& debug_name = "",
      bool take_ownership = false) override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransactionFromNativeHandle(
      void* handle,
      bool take_ownership = false) override;

  void Acquire(void* handle) override;
  void Release(void* handle) override;
  void DeleteTransaction(void* transaction_handle) override;
  bool ApplyTransaction(void* transaction_handle) override;
  bool Reparent(void* transaction_handle,
                void* surface_control_handle,
                void* new_parent_handle) override;
  bool SetVisibility(void* transaction_handle,
                     void* surface_control_handle,
                     int8_t visibility) override;
  bool SetZOrder(void* transaction_handle,
                 void* surface_control_handle,
                 int32_t z_order) override;
  bool SetBuffer(void* transaction_handle,
                 void* surface_control_handle,
                 void* hardware_buffer,
                 int acquire_fence_fd) override;
  bool SetGeometry(void* transaction_handle,
                   void* surface_control_handle,
                   const AndroidSurfaceControlRect* source,
                   const AndroidSurfaceControlRect* destination,
                   int32_t transform) override;
  bool SetDamageRegion(void* transaction_handle,
                       void* surface_control_handle,
                       const AndroidSurfaceControlRect* rects,
                       uint32_t count) override;
  bool SetBufferAlpha(void* transaction_handle,
                      void* surface_control_handle,
                      float alpha) override;
  bool SetColor(void* transaction_handle,
                void* surface_control_handle,
                float r,
                float g,
                float b,
                float alpha) override;
  bool SetOnComplete(
      void* transaction_handle,
      std::function<void(const AndroidSurfaceControlStats&)> callback) override;

 private:
  void EnsureLoaded() const;

  mutable std::shared_ptr<OSLibraryLoader> library_loader_;
  mutable std::shared_ptr<OSLibrary> libandroid_;
  mutable std::mutex mutex_;
  mutable bool loaded_ = false;
  mutable bool is_available_ = false;
  mutable uint64_t next_id_ = 1;

  mutable void* create_from_window_fn_ = nullptr;
  mutable void* create_fn_ = nullptr;
  mutable void* acquire_fn_ = nullptr;
  mutable void* release_fn_ = nullptr;
  mutable void* transaction_create_fn_ = nullptr;
  mutable void* transaction_delete_fn_ = nullptr;
  mutable void* transaction_apply_fn_ = nullptr;
  mutable void* transaction_reparent_fn_ = nullptr;
  mutable void* transaction_set_visibility_fn_ = nullptr;
  mutable void* transaction_set_z_order_fn_ = nullptr;
  mutable void* transaction_set_buffer_fn_ = nullptr;
  mutable void* transaction_set_geometry_fn_ = nullptr;
  mutable void* transaction_set_damage_region_fn_ = nullptr;
  mutable void* transaction_set_buffer_alpha_fn_ = nullptr;
  mutable void* transaction_set_color_fn_ = nullptr;
  mutable void* transaction_set_on_complete_fn_ = nullptr;
  mutable void* stats_get_release_fence_fn_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceControlProvider);
};

/// @brief In-memory mock surface control for host tests.
class InMemoryAndroidSurfaceControl : public AndroidSurfaceControl {
 public:
  InMemoryAndroidSurfaceControl(
      uint64_t id,
      std::string debug_name,
      void* handle,
      void* parent_handle,
      uint64_t parent_id,
      bool owns_handle,
      std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider);
  ~InMemoryAndroidSurfaceControl() override;

  void* GetHandle() const override;
  const std::string& GetDebugName() const override;
  uint64_t GetId() const override;
  bool IsValid() const override;
  void Acquire() override;
  void Release() override;
  bool RemoveFromParent() override;
  void* GetParentHandle() const override;
  uint64_t GetParentId() const override;

 private:
  uint64_t id_ = 0;
  std::string debug_name_;
  void* handle_ = nullptr;
  void* parent_handle_ = nullptr;
  uint64_t parent_id_ = 0;
  bool owns_handle_ = true;
  std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceControl);
};

/// @brief In-memory mock surface transaction for host tests.
class InMemoryAndroidSurfaceTransaction : public AndroidSurfaceTransaction {
 public:
  InMemoryAndroidSurfaceTransaction(
      void* handle,
      bool owns_handle,
      std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider);
  ~InMemoryAndroidSurfaceTransaction() override;

  void* GetHandle() const override;
  bool IsValid() const override;

  bool SetVisibility(AndroidSurfaceControl* surface_control,
                     AndroidSurfaceControlVisibility visibility) override;
  bool SetZOrder(AndroidSurfaceControl* surface_control,
                 int32_t z_order) override;
  bool SetBuffer(AndroidSurfaceControl* surface_control,
                 void* hardware_buffer,
                 int acquire_fence_fd = -1) override;
  bool SetGeometry(AndroidSurfaceControl* surface_control,
                   const AndroidSurfaceControlRect& source,
                   const AndroidSurfaceControlRect& destination,
                   AndroidSurfaceControlTransform transform =
                       AndroidSurfaceControlTransform::kIdentity) override;
  bool SetDamageRegion(
      AndroidSurfaceControl* surface_control,
      const std::vector<AndroidSurfaceControlRect>& rects) override;
  bool SetBufferAlpha(AndroidSurfaceControl* surface_control,
                      float alpha) override;
  bool SetColor(AndroidSurfaceControl* surface_control,
                float r,
                float g,
                float b,
                float alpha) override;
  bool Reparent(AndroidSurfaceControl* surface_control,
                AndroidSurfaceControl* new_parent) override;
  bool SetOnComplete(OnCompleteCallback callback) override;
  bool Apply() override;

 private:
  void* handle_ = nullptr;
  bool owns_handle_ = true;
  std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider_;
  OnCompleteCallback on_complete_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceTransaction);
};

/// @brief In-memory mock provider for unit tests on host platforms without
/// libandroid.so.
class InMemoryAndroidSurfaceControlProvider
    : public AndroidSurfaceControlProvider,
      public std::enable_shared_from_this<
          InMemoryAndroidSurfaceControlProvider> {
 public:
  InMemoryAndroidSurfaceControlProvider();
  ~InMemoryAndroidSurfaceControlProvider() override;

  bool IsAvailable() const override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* window,
      const std::string& debug_name = "FlutterParentControl") override;

  std::unique_ptr<AndroidSurfaceControl> Create(
      AndroidSurfaceControl* parent,
      const std::string& debug_name = "FlutterChildControl") override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromNativeHandle(
      void* handle,
      const std::string& debug_name = "",
      bool take_ownership = false) override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransactionFromNativeHandle(
      void* handle,
      bool take_ownership = false) override;

  void Acquire(void* handle) override;
  void Release(void* handle) override;
  void DeleteTransaction(void* transaction_handle) override;
  bool ApplyTransaction(void* transaction_handle) override;
  bool Reparent(void* transaction_handle,
                void* surface_control_handle,
                void* new_parent_handle) override;
  bool SetVisibility(void* transaction_handle,
                     void* surface_control_handle,
                     int8_t visibility) override;
  bool SetZOrder(void* transaction_handle,
                 void* surface_control_handle,
                 int32_t z_order) override;
  bool SetBuffer(void* transaction_handle,
                 void* surface_control_handle,
                 void* hardware_buffer,
                 int acquire_fence_fd) override;
  bool SetGeometry(void* transaction_handle,
                   void* surface_control_handle,
                   const AndroidSurfaceControlRect* source,
                   const AndroidSurfaceControlRect* destination,
                   int32_t transform) override;
  bool SetDamageRegion(void* transaction_handle,
                       void* surface_control_handle,
                       const AndroidSurfaceControlRect* rects,
                       uint32_t count) override;
  bool SetBufferAlpha(void* transaction_handle,
                      void* surface_control_handle,
                      float alpha) override;
  bool SetColor(void* transaction_handle,
                void* surface_control_handle,
                float r,
                float g,
                float b,
                float alpha) override;
  bool SetOnComplete(
      void* transaction_handle,
      std::function<void(const AndroidSurfaceControlStats&)> callback) override;

  // Test inspection and control methods:
  void SetAvailable(bool available);
  void SetCreationFailure(bool fail);
  size_t GetActiveSurfaceControlCount() const;
  size_t GetTransactionCount() const;
  size_t GetApplyCount() const;
  std::optional<AndroidSurfaceControlState> GetSurfaceState(uint64_t id) const;
  std::optional<AndroidSurfaceControlState> GetSurfaceStateByHandle(
      void* handle) const;
  void Clear();

 private:
  mutable std::mutex mutex_;
  bool is_available_ = true;
  bool creation_failure_ = false;
  uint64_t next_id_ = 1;
  uint64_t next_transaction_id_ = 1;
  size_t apply_count_ = 0;

  std::map<uint64_t, AndroidSurfaceControlState> surfaces_;
  std::unordered_map<void*, uint64_t> handle_to_id_;

  struct PendingTransaction {
    void* handle = nullptr;
    std::map<void*, AndroidSurfaceControlState> updates;
    std::function<void(const AndroidSurfaceControlStats&)> on_complete;
  };
  std::unordered_map<void*, PendingTransaction> transactions_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceControlProvider);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_
