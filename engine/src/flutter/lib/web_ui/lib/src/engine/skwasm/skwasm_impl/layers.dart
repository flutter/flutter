// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine/scene_painting.dart';
import 'package:ui/src/engine/vector_math.dart';
import 'package:ui/ui.dart' as ui;

class BackdropFilterLayer
  with PictureLayer
  implements ui.BackdropFilterEngineLayer {}
class BackdropFilterOperation implements LayerOperation {
  BackdropFilterOperation(this.filter, this.mode);

  final ui.ImageFilter filter;
  final ui.BlendMode mode;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayerWithFilter(contentRect, ui.Paint()..blendMode = mode, filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }
}

class ClipPathLayer
  with PictureLayer
  implements ui.ClipPathEngineLayer {}
class ClipPathOperation implements LayerOperation {
  ClipPathOperation(this.path, this.clip);

  final ui.Path path;
  final ui.Clip clip;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect.intersect(path.getBounds());

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipPath(path, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(path.getBounds(), ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }
}

class ClipRectLayer
  with PictureLayer
  implements ui.ClipRectEngineLayer {}
class ClipRectOperation implements LayerOperation {
  const ClipRectOperation(this.rect, this.clip);

  final ui.Rect rect;
  final ui.Clip clip;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect.intersect(rect);

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipRect(rect, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(rect, ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }
}

class ClipRRectLayer
  with PictureLayer
  implements ui.ClipRRectEngineLayer {}
class ClipRRectOperation implements LayerOperation {
  const ClipRRectOperation(this.rrect, this.clip);

  final ui.RRect rrect;
  final ui.Clip clip;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect.intersect(rrect.outerRect);

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipRRect(rrect, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(rrect.outerRect, ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }
}

class ColorFilterLayer
  with PictureLayer
  implements ui.ColorFilterEngineLayer {}
class ColorFilterOperation implements LayerOperation {
  ColorFilterOperation(this.filter);

  final ui.ColorFilter filter;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayer(contentRect, ui.Paint()..colorFilter = filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }
}

class ImageFilterLayer
  with PictureLayer
  implements ui.ImageFilterEngineLayer {}
class ImageFilterOperation implements LayerOperation {
  ImageFilterOperation(this.filter, this.offset);

  final ui.ImageFilter filter;
  final ui.Offset offset;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    if (offset != ui.Offset.zero) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
    }
    final ui.Rect adjustedContentRect =
      (filter as SceneImageFilter).filterBounds(contentRect);
    canvas.saveLayer(adjustedContentRect, ui.Paint()..imageFilter = filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (offset != ui.Offset.zero) {
      canvas.restore();
    }
    canvas.restore();
  }
}

class OffsetLayer
  with PictureLayer
  implements ui.OffsetEngineLayer {}
class OffsetOperation implements LayerOperation {
  OffsetOperation(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect.shift(ui.Offset(dx, dy));

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    canvas.save();
    canvas.translate(dx, dy);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }
}

class OpacityLayer
  with PictureLayer
  implements ui.OpacityEngineLayer {}
class OpacityOperation implements LayerOperation {
  OpacityOperation(this.alpha, this.offset);

  final int alpha;
  final ui.Offset offset;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect.shift(offset);

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    if (offset != ui.Offset.zero) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
    }
    canvas.saveLayer(
      cullRect,
      ui.Paint()..color = ui.Color.fromARGB(alpha, 0, 0, 0)
    );
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
    if (offset != ui.Offset.zero) {
      canvas.restore();
    }
  }
}

class TransformLayer
  with PictureLayer
  implements ui.TransformEngineLayer {}
class TransformOperation implements LayerOperation {
  TransformOperation(this.transform);

  final Float64List transform;

  @override
  ui.Rect cullRect(ui.Rect contentRect) =>
    Matrix4.fromFloat32List(toMatrix32(transform)).transformRect(contentRect);

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    canvas.save();
    canvas.transform(transform);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }
}

class ShaderMaskLayer
  with PictureLayer
  implements ui.ShaderMaskEngineLayer {}
class ShaderMaskOperation implements LayerOperation {
  ShaderMaskOperation(this.shader, this.maskRect, this.blendMode);

  final ui.Shader shader;
  final ui.Rect maskRect;
  final ui.BlendMode blendMode;

  @override
  ui.Rect cullRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayer(
      contentRect,
      ui.Paint(),
    );
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.translate(maskRect.left, maskRect.top);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, maskRect.width, maskRect.height),
      ui.Paint()
        ..blendMode = blendMode
        ..shader = shader
    );
    canvas.restore();
    canvas.restore();
  }
}


mixin PictureLayer implements ui.EngineLayer {
  ui.Picture? picture;

  @override
  void dispose() {
    picture?.dispose();
  }
}

abstract class LayerOperation {
  const LayerOperation();

  ui.Rect cullRect(ui.Rect contentRect);
  void pre(SceneCanvas canvas, ui.Rect contentRect);
  void post(SceneCanvas canvas, ui.Rect contentRect);
}

class PictureDrawCommand {
  PictureDrawCommand(this.offset, this.picture);

  ui.Offset offset;
  ui.Picture picture;
}

class LayerBuilder {
  factory LayerBuilder.rootLayer() {
    return LayerBuilder._(null, null, null);
  }

  factory LayerBuilder.childLayer({
    required LayerBuilder parent,
    required PictureLayer layer,
    required LayerOperation operation
  }) {
    return LayerBuilder._(parent, layer, operation);
  }

  LayerBuilder._(
    this.parent,
    this.layer,
    this.operation
  );

  final LayerBuilder? parent;
  final PictureLayer? layer;
  final LayerOperation? operation;
  final List<PictureDrawCommand> drawCommands = <PictureDrawCommand>[];
  ui.Rect? contentRect;

  ui.Picture build() {
    final ui.Rect drawnRect = contentRect ?? ui.Rect.zero;
    final ui.Rect rect = operation?.cullRect(drawnRect) ?? drawnRect;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final SceneCanvas canvas = ui.Canvas(recorder, rect) as SceneCanvas;

    operation?.pre(canvas, rect);
    for (final PictureDrawCommand command in drawCommands) {
      if (command.offset != ui.Offset.zero) {
        canvas.save();
        canvas.translate(command.offset.dx, command.offset.dy);
        canvas.drawPicture(command.picture);
        canvas.restore();
      } else {
        canvas.drawPicture(command.picture);
      }
    }
    operation?.post(canvas, rect);
    final ui.Picture picture = recorder.endRecording();
    layer?.picture = picture;
    return picture;
  }

  void addPicture(
    ui.Offset offset,
    ui.Picture picture, {
    bool isComplexHint = false,
    bool willChangeHint = false
  }) {
    drawCommands.add(PictureDrawCommand(offset, picture));
    final ui.Rect cullRect = (picture as ScenePicture).cullRect;
    final ui.Rect shiftedRect = cullRect.shift(offset);
    contentRect = contentRect?.expandToInclude(shiftedRect) ?? shiftedRect;
  }
}
