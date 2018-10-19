// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('non-painted layers are detached', () {
    RenderObject boundary, inner;
    final RenderOpacity root = RenderOpacity(
      child: boundary = RenderRepaintBoundary(
        child: inner = RenderDecoratedBox(
          decoration: const BoxDecoration(),
        ),
      ),
    );
    layout(root, phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isTrue); // this time it painted...

    root.opacity = 0.0;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isFalse); // this time it did not.

    root.opacity = 0.5;
    pumpFrame(phase: EnginePhase.paint);
    expect(inner.isRepaintBoundary, isFalse);
    expect(() => inner.layer, throwsAssertionError);
    expect(boundary.isRepaintBoundary, isTrue);
    expect(boundary.layer, isNotNull);
    expect(boundary.layer.attached, isTrue); // this time it did again!
  });

  test('layer subtree dirtiness is correctly computed', () {
    final ContainerLayer a = ContainerLayer();
    final ContainerLayer b = ContainerLayer();
    final ContainerLayer c = ContainerLayer();
    final ContainerLayer d = ContainerLayer();
    final ContainerLayer e = ContainerLayer();
    final ContainerLayer f = ContainerLayer();
    final ContainerLayer g = ContainerLayer();

    final PictureLayer h = PictureLayer(Rect.zero);
    final PictureLayer i = PictureLayer(Rect.zero);
    final PictureLayer j = PictureLayer(Rect.zero);

    // The tree is like the following where b and j are dirty:
    //        a____
    //       /     \
    //   (x)b___    c
    //     / \  \   |
    //    d   e  f  g
    //   / \        |
    //  h   i       j(x)
    a.append(b);
    a.append(c);
    b.append(d);
    b.append(e);
    b.append(f);
    d.append(h);
    d.append(i);
    c.append(g);
    g.append(j);

    a.markClean();
    b.markDirty();
    c.markClean();
    d.markClean();
    e.markClean();
    f.markClean();
    g.markClean();
    h.markClean();
    i.markClean();
    j.markDirty();

    a.updateSubtreeDirtiness();

    expect(a.isSubtreeDirty, true);
    expect(b.isSubtreeDirty, true);
    expect(c.isSubtreeDirty, true);
    expect(g.isSubtreeDirty, true);
    expect(j.isSubtreeDirty, true);

    expect(d.isSubtreeDirty, false);
    expect(e.isSubtreeDirty, false);
    expect(f.isSubtreeDirty, false);
    expect(h.isSubtreeDirty, false);
    expect(i.isSubtreeDirty, false);
  });

  test('leader and follower layers are always dirty', () {
    final LayerLink link = LayerLink();
    final LeaderLayer leaderLayer = LeaderLayer(link: link);
    final FollowerLayer followerLayer = FollowerLayer(link: link);
    leaderLayer.markClean();
    followerLayer.markClean();
    leaderLayer.updateSubtreeDirtiness();
    followerLayer.updateSubtreeDirtiness();
    expect(leaderLayer.isSubtreeDirty, true);
    expect(followerLayer.isSubtreeDirty, true);
  });
}
