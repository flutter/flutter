// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/surface_transaction_router.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using Route = SurfaceTransactionRouter::Route;

TEST(SurfaceTransactionRouter, DefaultsToDirectRouteWithNothingUncommitted) {
  SurfaceTransactionRouter router;

  EXPECT_EQ(router.GetFrameRoute(), Route::kDirect);
  EXPECT_FALSE(router.HasUncommittedPlatformFrames());
}

TEST(SurfaceTransactionRouter, FrameRouteIsLatchedUntilSetAgain) {
  SurfaceTransactionRouter router;

  router.SetFrameRoute(Route::kPlatform);
  EXPECT_EQ(router.GetFrameRoute(), Route::kPlatform);
  // The route is read once per surface submission; it must not be consumed
  // by the first read because one frame can submit an overlay and the root.
  EXPECT_EQ(router.GetFrameRoute(), Route::kPlatform);

  router.SetFrameRoute(Route::kDirect);
  EXPECT_EQ(router.GetFrameRoute(), Route::kDirect);
}

TEST(SurfaceTransactionRouter, PlatformFramesStayUncommittedUntilEachCommits) {
  SurfaceTransactionRouter router;

  router.OnPlatformFrameSubmitted();
  router.OnPlatformFrameSubmitted();
  EXPECT_TRUE(router.HasUncommittedPlatformFrames());

  router.OnPlatformFrameCommitted();
  EXPECT_TRUE(router.HasUncommittedPlatformFrames());

  router.OnPlatformFrameCommitted();
  EXPECT_FALSE(router.HasUncommittedPlatformFrames());
}

TEST(SurfaceTransactionRouter, UnmatchedCommitDoesNotMaskLaterSubmission) {
  SurfaceTransactionRouter router;

  router.OnPlatformFrameCommitted();
  EXPECT_FALSE(router.HasUncommittedPlatformFrames());

  // Had the stray commit driven the count negative, this submission would be
  // invisible and a direct frame could overtake it.
  router.OnPlatformFrameSubmitted();
  EXPECT_TRUE(router.HasUncommittedPlatformFrames());

  router.OnPlatformFrameCommitted();
  EXPECT_FALSE(router.HasUncommittedPlatformFrames());
}

}  // namespace testing
}  // namespace flutter
