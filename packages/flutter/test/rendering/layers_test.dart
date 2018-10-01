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

    a.markClean();  // ignore: invalid_use_of_protected_member
    b.markDirty();  // ignore: invalid_use_of_protected_member
    c.markClean();  // ignore: invalid_use_of_protected_member
    d.markClean();  // ignore: invalid_use_of_protected_member
    e.markClean();  // ignore: invalid_use_of_protected_member
    f.markClean();  // ignore: invalid_use_of_protected_member
    g.markClean();  // ignore: invalid_use_of_protected_member
    h.markClean();  // ignore: invalid_use_of_protected_member
    i.markClean();  // ignore: invalid_use_of_protected_member
    j.markDirty();  // ignore: invalid_use_of_protected_member

    a.updateSubtreeDirtiness();

    expect(a.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
    expect(b.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
    expect(c.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
    expect(g.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
    expect(j.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member

    expect(d.isSubtreeDirty, false);  // ignore: invalid_use_of_protected_member
    expect(e.isSubtreeDirty, false);  // ignore: invalid_use_of_protected_member
    expect(f.isSubtreeDirty, false);  // ignore: invalid_use_of_protected_member
    expect(h.isSubtreeDirty, false);  // ignore: invalid_use_of_protected_member
    expect(i.isSubtreeDirty, false);  // ignore: invalid_use_of_protected_member
  });

  test('leader and follower layers are always dirty', () {
    final LayerLink link = LayerLink();
    final LeaderLayer leaderLayer = LeaderLayer(link: link);
    final FollowerLayer followerLayer = FollowerLayer(link: link);
    leaderLayer.markClean();
    followerLayer.markClean();
    leaderLayer.updateSubtreeDirtiness();
    followerLayer.updateSubtreeDirtiness();
    expect(leaderLayer.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
    expect(followerLayer.isSubtreeDirty, true);  // ignore: invalid_use_of_protected_member
  });
}
