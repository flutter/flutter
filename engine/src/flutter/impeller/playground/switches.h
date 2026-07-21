// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_SWITCHES_H_
#define FLUTTER_IMPELLER_PLAYGROUND_SWITCHES_H_

#include <chrono>
#include <optional>

#include "flutter/fml/command_line.h"
#include "impeller/base/flags.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

namespace impeller {

struct PlaygroundSwitchOption {
  PlaygroundSwitchOption(std::string name, bool& flag)
      : name(std::move(name)), flag(flag) {}

  std::string name;
  bool& flag;
};

/// There are 4 different ways that a Playground test can be rendered:
/// - offscreen - the default - renders the playground output to an
///   offscreen RenderTarget obtained from the context's allocator.
/// - onscreen - renders the playground output to an onscreen RenderTarget
///   obtained from the AcquireSurfaceFrame method of the surface.
/// - golden - renders the playground output to an offscreen RenderTarget
///   obtained from the allocator twice and saves the second output to
///   a file in the golden_output_dir.
/// - window - renders the playground output to a window so that the
///   developer can inspect and diagnose problems directly.
///
/// The default outputs are offscreen and onscreen.
struct PlaygroundOutputs {
  bool offscreen = true;
  bool onscreen = true;
  bool golden = false;
  bool window = false;

  void Clear() { offscreen = onscreen = golden = window = false; }

  bool Any() const { return offscreen || onscreen || golden || window; }

  std::array<PlaygroundSwitchOption, 4> switches() {
    return {{
        PlaygroundSwitchOption("offscreen", offscreen),
        PlaygroundSwitchOption("onscreen", onscreen),
        PlaygroundSwitchOption("golden", golden),
        PlaygroundSwitchOption("window", window),
    }};
  }

  bool operator==(const PlaygroundOutputs&) const = default;
};

/// The default list of backends over which the playground tests will be
/// executed depends mostly on which backends the platform supports, but
/// a given run may want to focus on a small number
struct PlaygroundBackends {
  bool metal = true;
  bool metal_sdf = true;
  bool opengles = true;
  bool opengles_sdf = true;
  bool vulkan = true;

  void Clear() { metal = metal_sdf = opengles = opengles_sdf = vulkan = false; }

  bool Any() const {
    return metal || metal_sdf || opengles || opengles_sdf || vulkan;
  }

  std::array<PlaygroundSwitchOption, 5> switches() {
    return {{
        PlaygroundSwitchOption("Metal", metal),
        PlaygroundSwitchOption("MetalSDF", metal_sdf),
        PlaygroundSwitchOption("OpenGLES", opengles),
        PlaygroundSwitchOption("OpenGLESSDF", opengles_sdf),
        PlaygroundSwitchOption("Vulkan", vulkan),
    }};
  }

  bool operator==(const PlaygroundBackends&) const = default;
};

struct PlaygroundSwitches {
  PlaygroundOutputs outputs_enabled;
  PlaygroundBackends backends_enabled;

  // If specified, the playgrounds will render for at least the duration
  // specified in the timeout. If the timeout is zero, exactly one frame will be
  // rendered in the playground.
  std::optional<std::chrono::milliseconds> timeout;
  bool enable_vulkan_validation = false;
  //----------------------------------------------------------------------------
  /// Seek a SwiftShader library in known locations and use it when running
  /// Vulkan. It is a fatal error to provide this option and not have the test
  /// find a SwiftShader implementation.
  ///
  bool use_swiftshader = false;
  /// Attempt to use Angle on the system instead of the available OpenGL ES
  /// implementation. This is on-by-default on macOS due to the broken-ness in
  /// the deprecated OpenGL implementation. On other platforms, it this opt-in
  /// via the flag with the system OpenGL ES implementation used by fault.
  ///
  bool use_angle = false;

  /// Whether the Playground instance can share contexts among multiple
  /// instantiations. This value is initialized by the Playground before
  /// it instantiates the |PlaygroundImpl| object. Implementations are free
  /// to share or not share contexts if this switch is true, but must create
  /// a new context for each Impl object created if the value is false.
  bool can_share_context = true;

  bool enable_wide_gamut = false;

  Flags flags;

  PlaygroundSwitches();

  static absl::StatusOr<PlaygroundSwitches> FromCommandLine(
      const fml::CommandLine& args);

  bool operator==(const PlaygroundSwitches&) const = default;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_SWITCHES_H_
