// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing
import UIKit

@testable import InternalFlutterSwift

// The iPhone Duo inner display as measured on the simulator: 951x669pt with a 40pt fold division
// through the centre.
private let innerWidth: CGFloat = 951
private let innerHeight: CGFloat = 669

private func division(width: CGFloat, active: Bool) -> ReservedRegionInfo {
  ReservedRegionInfo(
    frame: CGRect(x: (innerWidth - width) / 2, y: 0, width: width, height: innerHeight),
    isDivision: true,
    isActive: active)
}

private func occlusion(active: Bool) -> ReservedRegionInfo {
  ReservedRegionInfo(
    frame: CGRect(x: 867, y: 0, width: 84, height: 120),
    isDivision: false,
    isActive: active)
}

@Suite struct DisplayFeatureListTests {
  @Test func partiallyOpenDivisionBecomesHalfOpenedFold() {
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: true)], hingeStatus: .partiallyOpen)

    #expect(features.types == [DisplayFeatureType.fold.rawValue])
    #expect(features.states == [DisplayFeatureState.postureHalfOpened.rawValue])
    // Bounds are left, top, right, bottom in logical pixels.
    #expect(features.bounds == [455.5, 0, 495.5, Double(innerHeight)])
  }

  @Test func fullyOpenReportsNoFoldEvenIfTheDivisionStillReadsActive() {
    // isActive lags the hinge: in the update that reports fully open the division still reads
    // active, and nothing follows to correct it. A 40pt postureFlat fold would split every dialog
    // on a device lying flat.
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: true)], hingeStatus: .fullyOpen)

    #expect(features.isEmpty)
  }

  @Test func fullyOpenStillReportsAnActiveOcclusion() {
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: true), occlusion(active: true)],
      hingeStatus: .fullyOpen)

    #expect(features.types == [DisplayFeatureType.cutout.rawValue])
  }

  @Test func closedReportsNothing() {
    // The view is on the cover display, which has no fold, and dart:ui has no closed posture to
    // describe it with.
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: true), occlusion(active: true)], hingeStatus: .closed)

    #expect(features.bounds.isEmpty)
    #expect(features.types.isEmpty)
    #expect(features.states.isEmpty)
  }

  @Test func inactiveDivisionIsDropped() {
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: false)], hingeStatus: .partiallyOpen)

    #expect(features.isEmpty)
  }

  @Test func zeroWidthDivisionIsDroppedEvenWhenHalfOpened() {
    // This is the combination that would split the screen with no visible fold:
    // DisplayFeatureSubScreen.avoidBounds treats a zero-width feature as an obstruction when its
    // state is postureHalfOpened.
    let features = DisplayFeatureList(
      regions: [division(width: 0, active: true)], hingeStatus: .partiallyOpen)

    #expect(features.isEmpty)
  }

  @Test func occlusionBecomesCutoutWithUnknownState() {
    let features = DisplayFeatureList(
      regions: [occlusion(active: true)], hingeStatus: .partiallyOpen)

    #expect(features.types == [DisplayFeatureType.cutout.rawValue])
    // dart:ui asserts this pairing in the DisplayFeature constructor.
    #expect(features.states == [DisplayFeatureState.unknown.rawValue])
  }

  @Test func inactiveOcclusionIsDropped() {
    let features = DisplayFeatureList(
      regions: [occlusion(active: false)], hingeStatus: .fullyOpen)

    #expect(features.isEmpty)
  }

  @Test func mixedRegionsKeepOrderAndParallelArrays() {
    let features = DisplayFeatureList(
      regions: [
        division(width: 40, active: true),
        occlusion(active: true),
        division(width: 0, active: true),
      ],
      hingeStatus: .partiallyOpen)

    #expect(
      features.types == [DisplayFeatureType.fold.rawValue, DisplayFeatureType.cutout.rawValue])
    #expect(features.states.count == 2)
    #expect(features.bounds.count == 8)
  }

  @Test func unknownStatusReportsNoFold() {
    let features = DisplayFeatureList(
      regions: [division(width: 40, active: true)], hingeStatus: .unknown)

    #expect(features.isEmpty)
  }

  @Test func emptyInitializerReportsNothing() {
    let features = DisplayFeatureList()

    #expect(features.isEmpty)
    #expect(features.bounds.isEmpty)
    #expect(features.states.isEmpty)
  }
}

@MainActor
@Suite struct DisplayFeaturesMonitorTests {
  @Test func hingeStatusMapsFromUIHingeStatus() {
    guard #available(iOS 27.1, *) else { return }
    #expect(HingeStatus(UIHinge.Status.closed) == .closed)
    #expect(HingeStatus(UIHinge.Status.partiallyOpen) == .partiallyOpen)
    #expect(HingeStatus(UIHinge.Status.fullyOpen) == .fullyOpen)
    #expect(HingeStatus(UIHinge.Status.unknown) == .unknown)
    // A nil hinge means the device has none.
    #expect(HingeStatus(nil) == .unknown)
  }

  @Test func addsAHingeInteractionToTheViewAndRemovesItOnInvalidate() {
    guard #available(iOS 27.1, *) else { return }
    let view = UIView()
    let monitor = DisplayFeaturesMonitor(view: view) { _ in }

    #expect(view.interactions.contains { $0 is UIHingeInteraction })

    monitor.invalidate()

    #expect(!view.interactions.contains { $0 is UIHingeInteraction })
  }

  @Test func refreshReportsTheFeaturesOfTheView() {
    guard #available(iOS 27.1, *) else { return }
    // Every layout pass relies on a refresh reporting, whatever the regions are. A view in no
    // window has seen no hinge update either, so the posture is still unknown.
    let view = UIView()
    var reports: [DisplayFeatureList] = []
    let monitor = DisplayFeaturesMonitor(view: view) { reports.append($0) }

    monitor.refresh()

    #expect(reports.count == 1)
    #expect(monitor.status == .unknown)
    monitor.invalidate()
  }

  @Test func refreshAfterInvalidateReportsNothing() {
    guard #available(iOS 27.1, *) else { return }
    let view = UIView()
    var reports = 0
    let monitor = DisplayFeaturesMonitor(view: view) { _ in reports += 1 }
    monitor.invalidate()

    monitor.refresh()

    #expect(reports == 0)
  }
}
