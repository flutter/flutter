// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A sprite toolkit built on top of Flutter.
library flutter_sprites;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:mojo/core.dart';
import 'package:sky_services/media/media.mojom.dart';
import 'package:vector_math/vector_math_64.dart';

part 'src/action.dart';
part 'src/action_spline.dart';
part 'src/color_sequence.dart';
part 'src/constraint.dart';
part 'src/effect_line.dart';
part 'src/image_map.dart';
part 'src/label.dart';
part 'src/layer.dart';
part 'src/nine_slice_sprite.dart';
part 'src/node.dart';
part 'src/node3d.dart';
part 'src/node_with_size.dart';
part 'src/particle_system.dart';
part 'src/sound.dart';
part 'src/sprite.dart';
part 'src/sprite_box.dart';
part 'src/sprite_widget.dart';
part 'src/spritesheet.dart';
part 'src/texture.dart';
part 'src/textured_line.dart';
part 'src/util.dart';
part 'src/virtual_joystick.dart';
