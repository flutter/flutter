// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker] and [showCupertinoModalPopup],
/// which have a [SelectableDayPredicate] parameter used
/// to specify allowable days in the date picker.
typedef SelectableDayPredicate = bool Function(DateTime day);
