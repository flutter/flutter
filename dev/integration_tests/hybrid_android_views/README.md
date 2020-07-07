# Integration test for hybrid composition on Android

This test verifies that hybrid composition uses `FlutterImageView` when there's an
Android view in the frame or else a `FlutterSurfaceView`.

It also verifies that overlay surfaces and Android views are sized, positioned,
and stacked accordinly based on the paint order.
