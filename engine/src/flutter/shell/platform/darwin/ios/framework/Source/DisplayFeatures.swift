// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// Mirrors the index order of `dart:ui`'s `DisplayFeatureType`.
enum DisplayFeatureType: Int32 {
  case unknown = 0
  case fold = 1
  case hinge = 2
  case cutout = 3
}

/// Mirrors the index order of `dart:ui`'s `DisplayFeatureState`.
enum DisplayFeatureState: Int32 {
  case unknown = 0
  case postureFlat = 1
  case postureHalfOpened = 2
}

/// The hinge posture as the mapping needs it. Mirrors `UIHinge.Status`, so the mapping can be
/// exercised without a hinge.
enum HingeStatus {
  case unknown
  case closed
  case partiallyOpen
  case fullyOpen

  @available(iOS 27.1, *)
  init(_ status: UIHinge.Status?) {
    switch status {
    case .closed:
      self = .closed
    case .partiallyOpen:
      self = .partiallyOpen
    case .fullyOpen:
      self = .fullyOpen
    case .unknown, .none:
      self = .unknown
    @unknown default:
      self = .unknown
    }
  }
}

/// A reserved region as read from `UIView.reservedRegions(kind:options:)`, reduced to what the
/// mapping needs.
struct ReservedRegionInfo: Equatable {
  /// In the view's logical coordinates (points).
  let frame: CGRect
  /// True for `.division` (the fold), false for `.occlusion` (a camera).
  let isDivision: Bool
  /// A division is inactive while the device is flat. This lags the hinge.
  let isActive: Bool
}

/// Display features in logical pixels, laid out the way `ViewportMetrics` expects: four values per
/// feature (left, top, right, bottom) and one type and one state per feature. The caller scales
/// `bounds` by the device pixel ratio.
@objc(FlutterDisplayFeatureList)
final class DisplayFeatureList: NSObject {
  @objc let bounds: [Double]
  @objc let types: [Int32]
  @objc let states: [Int32]

  @objc init(bounds: [Double], types: [Int32], states: [Int32]) {
    self.bounds = bounds
    self.types = types
    self.states = states
    super.init()
  }

  /// An empty list: no display features.
  @objc override convenience init() {
    self.init(bounds: [], types: [], states: [])
  }

  var isEmpty: Bool { types.isEmpty }

  /// Converts the hinge posture and reserved regions into display features.
  ///
  /// Rules, each of which exists to keep `DisplayFeatureSubScreen` from splitting an app's layout
  /// when there is no visible fold:
  ///
  /// * Nothing is reported while the device is closed. `dart:ui` has no closed posture, and with
  ///   the device shut the view is on the cover display, which has no fold.
  /// * A division is only reported while the hinge is partially open. The hinge status is
  ///   immediate, but a region's `isActive` lags it: measured on the iPhone Duo simulator, a
  ///   division still reads active inside the update handler that reports fully open, and clears a
  ///   few milliseconds later with no further hinge update or layout pass to pick that up. Trusting
  ///   it would leave a 40pt `postureFlat` fold splitting every dialog on a flat device.
  /// * Inactive regions are never reported.
  /// * A region whose shortest side is zero is never reported. Combined with `postureHalfOpened`
  ///   it would still satisfy `DisplayFeatureSubScreen.avoidBounds` and split the screen in two.
  /// * Occlusions become `cutout` with state `unknown`, which `dart:ui` asserts.
  /// * Divisions become `fold`, not `hinge`: the inner display is one continuous panel with no
  ///   physical gap between two separate screens.
  convenience init(regions: [ReservedRegionInfo], hingeStatus: HingeStatus) {
    // With the device closed the view is on the cover display, which has no fold, and dart:ui has
    // no posture to describe "closed" anyway.
    if hingeStatus == .closed {
      self.init()
      return
    }

    var bounds: [Double] = []
    var types: [Int32] = []
    var states: [Int32] = []
    for region in regions where region.isActive {
      // A zero-width feature still trips DisplayFeatureSubScreen.avoidBounds when its state is
      // postureHalfOpened, splitting the screen with no visible fold.
      if region.frame.width <= 0 || region.frame.height <= 0 {
        continue
      }

      let type: DisplayFeatureType
      let state: DisplayFeatureState
      if region.isDivision {
        // The hinge status is immediate; isActive lags it and can still read true in the very
        // update that reports fully open, with nothing following to correct it. The posture
        // therefore decides whether there is a fold.
        if hingeStatus != .partiallyOpen {
          continue
        }
        // The inner display is one continuous panel; there is no physical gap, so this is a fold
        // rather than a hinge.
        type = .fold
        state = .postureHalfOpened
      } else {
        // dart:ui asserts that a cutout carries the unknown state.
        type = .cutout
        state = .unknown
      }

      bounds.append(contentsOf: [
        region.frame.minX,
        region.frame.minY,
        region.frame.maxX,
        region.frame.maxY,
      ])
      types.append(type.rawValue)
      states.append(state.rawValue)
    }
    self.init(bounds: bounds, types: types, states: states)
  }
}

/// Observes the hinge and the reserved regions of a view and reports them as display features
/// whenever either changes.
///
/// The regions are only ever read during layout, from `refresh()`. The hinge handler contributes
/// the posture alone: when it changes, the monitor requests a layout pass on the view rather than
/// reading the regions itself, since the handler runs on every change of the angle while the
/// regions change only with the posture.
///
/// The owner calls `invalidate()` when it is done, which removes the interaction from the view.
@available(iOS 27.1, *)
@objc(FlutterDisplayFeaturesMonitor)
@MainActor
final class DisplayFeaturesMonitor: NSObject {
  private weak var view: UIView?
  private var onUpdate: ((DisplayFeatureList) -> Void)?
  private var interaction: UIHingeInteraction?
  private(set) var status: HingeStatus = .unknown

  /// Starts observing `view`. `onUpdate` is called on the main thread with the current features
  /// on every `refresh()`.
  @objc init(view: UIView, onUpdate: @escaping (DisplayFeatureList) -> Void) {
    self.view = view
    self.onUpdate = onUpdate
    super.init()

    let interaction = UIHingeInteraction { [weak self] _, update in
      guard let self else { return }
      // A nil hinge means this device has none, or the interaction left a hierarchy that provides
      // hinge updates.
      let status = HingeStatus(update.hinge?.status)
      // This handler runs on every change of the angle, many times a second while the device is
      // folding. Only the posture matters here, and the regions are read during layout, so a
      // change of posture requests a layout pass rather than reading anything itself.
      if status == self.status {
        return
      }
      self.status = status
      self.view?.setNeedsLayout()
    }
    self.interaction = interaction
    view.addInteraction(interaction)
  }

  /// Re-reads the reserved regions and reports again.
  ///
  /// This must be called from the view controller's `viewDidLayoutSubviews`. Reserved regions lag
  /// the hinge, and UIKit offers no notification for them; instead a read made during layout is
  /// tracked, and UIKit runs layout again when the region changes. Apple documents this for
  /// `updateConstraints` ("UIKit tracks the regions you read in updateConstraints() and runs it
  /// again when they change"):
  /// https://developer.apple.com/documentation/uikit/uiview/reservedregion
  /// and lists `viewDidLayoutSubviews` among the methods with automatic observation tracking:
  /// https://developer.apple.com/documentation/uikit/automatic-observation-tracking
  /// Measured on the iPhone Duo simulator: with the read inside `viewDidLayoutSubviews`, a layout
  /// pass follows every change of the division (about a second after the hinge reads partially
  /// open, and within 15 ms of it reading fully open). With the read made only outside layout, no
  /// layout pass follows at all, because the view's bounds do not change while folding.
  @objc func refresh() {
    guard let view else { return }

    var regions: [ReservedRegionInfo] = []
    // The fold is inactive while the device is flat, so it is requested with includeInactive; the
    // mapping drops inactive regions itself, and this keeps the query, and so the dependency UIKit
    // tracks, identical across postures.
    for region in view.reservedRegions(kind: .division, options: .includeInactive) {
      regions.append(
        ReservedRegionInfo(frame: region.frame, isDivision: true, isActive: region.isActive))
    }
    // An occlusion is only active while that camera is in use.
    for region in view.reservedRegions(kind: .occlusion) {
      regions.append(
        ReservedRegionInfo(frame: region.frame, isDivision: false, isActive: region.isActive))
    }

    // Held locally so that a handler which ends up invalidating this monitor cannot release the
    // closure while it is running.
    let onUpdate = self.onUpdate
    onUpdate?(DisplayFeatureList(regions: regions, hingeStatus: status))
  }

  /// Stops observing and removes the interaction from the view.
  @objc func invalidate() {
    if let interaction {
      view?.removeInteraction(interaction)
      self.interaction = nil
    }
    onUpdate = nil
  }
}
