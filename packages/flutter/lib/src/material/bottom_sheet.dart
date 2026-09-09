// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Bottom sheets and Scaffold share their implementation so persistent sheets
// can extend their surface without exposing presentation details as public API.
export 'scaffold.dart'
    show
        BottomSheet,
        BottomSheetDragEndHandler,
        BottomSheetDragStartHandler,
        ModalBottomSheetRoute,
        showBottomSheet,
        showModalBottomSheet;
