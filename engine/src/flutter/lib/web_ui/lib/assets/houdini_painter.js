// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(yjbanov): Consider the following optimizations:
// - Switch from JSON to typed arrays. See:
//   https://github.com/w3c/css-houdini-drafts/issues/136
// - When there is no DOM-rendered content, then clipping in the canvas is more
//   efficient than DOM-rendered clipping.
// - When DOM-rendered clip is the only option, then clipping _again_ in the
//   canvas is superfluous.
// - When transform is a 2D transform and there is no DOM-rendered content, then
//   canvas transform is more efficient than DOM-rendered transform.
// - If a transform must be DOM-rendered, then clipping in the canvas _again_ is
//   superfluous.

/**
 * Applies paint commands to CSS Paint API (a.k.a. Houdini).
 *
 * This painter is driven by houdini_canvas.dart. This painter and the
 * HoudiniCanvas class must be kept in sync with each other.
 */
class FlutterPainter {
  /**
   * Properties used by this painter.
   *
   * @return {string[]} list of CSS properties this painter depends on.
   */
  static get inputProperties() {
    return ['--flt'];
  }

  /**
   * Implements the painter interface.
   */
  paint(ctx, geom, properties) {
    let fltProp = properties.get('--flt').toString();
    if (!fltProp) {
      // Nothing to paint.
      return;
    }
    const commands = JSON.parse(fltProp);
    for (let i = 0; i < commands.length; i++) {
      let command = commands[i];
      // TODO(yjbanov): we should probably move command identifiers into an enum
      switch (command[0]) {
        case 1:
          this._save(ctx, geom, command);
          break;
        case 2:
          this._restore(ctx, geom, command);
          break;
        case 3:
          this._translate(ctx, geom, command);
          break;
        case 4:
          this._scale(ctx, geom, command);
          break;
        case 5:
          this._rotate(ctx, geom, command);
          break;
        // Skip case 6: implemented in the DOM for now.
        case 7:
          this._skew(ctx, geom, command);
          break;
        case 8:
          this._clipRect(ctx, geom, command);
          break;
        case 9:
          this._clipRRect(ctx, geom, command);
          break;
        case 10:
          this._clipPath(ctx, geom, command);
          break;
        case 11:
          this._drawColor(ctx, geom, command);
          break;
        case 12:
          this._drawLine(ctx, geom, command);
          break;
        case 13:
          this._drawPaint(ctx, geom, command);
          break;
        case 14:
          this._drawRect(ctx, geom, command);
          break;
        case 15:
          this._drawRRect(ctx, geom, command);
          break;
        case 16:
          this._drawDRRect(ctx, geom, command);
          break;
        case 17:
          this._drawOval(ctx, geom, command);
          break;
        case 18:
          this._drawCircle(ctx, geom, command);
          break;
        case 19:
          this._drawPath(ctx, geom, command);
          break;
        case 20:
          this._drawShadow(ctx, geom, command);
          break;
        default:
          throw new Error(`Unsupported command ID: ${command[0]}`);
      }
    }
  }

  _applyPaint(ctx, paint) {
    let blendMode = _stringForBlendMode(paint.blendMode);
    ctx.globalCompositeOperation = blendMode ? blendMode : 'source-over';
    ctx.lineWidth = paint.strokeWidth ? paint.strokeWidth : 1.0;

    let strokeCap = _stringForStrokeCap(paint.strokeCap);
    ctx.lineCap = strokeCap ? strokeCap : 'butt';

    if (paint.shader != null) {
      let paintStyle = paint.shader.createPaintStyle(ctx);
      ctx.fillStyle = paintStyle;
      ctx.strokeStyle = paintStyle;
    } else if (paint.color != null) {
      let colorString = paint.color;
      ctx.fillStyle = colorString;
      ctx.strokeStyle = colorString;
    }
    if (paint.maskFilter != null) {
      ctx.filter = `blur(${paint.maskFilter[1]}px)`;
    }
  }

  _strokeOrFill(ctx, paint, resetPaint) {
    switch (paint.style) {
      case PaintingStyle.stroke:
        ctx.stroke();
        break;
      case PaintingStyle.fill:
      default:
        ctx.fill();
        break;
    }
    if (resetPaint) {
      this._resetPaint(ctx);
    }
  }

  _resetPaint(ctx) {
    ctx.globalCompositeOperation = 'source-over';
    ctx.lineWidth = 1.0;
    ctx.lineCap = 'butt';
    ctx.filter = 'none';
    ctx.fillStyle = null;
    ctx.strokeStyle = null;
  }

  _save(ctx, geom, command) {
    ctx.save();
  }

  _restore(ctx, geom, command) {
    ctx.restore();
  }

  _translate(ctx, geom, command) {
    ctx.translate(command[1], command[2]);
  }

  _scale(ctx, geom, command) {
    ctx.translate(command[1], command[2]);
  }

  _rotate(ctx, geom, command) {
    ctx.rotate(command[1]);
  }

  _skew(ctx, geom, command) {
    ctx.translate(command[1], command[2]);
  }

  _drawRect(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let rect = scanner.scanRect();
    let paint = scanner.scanPaint();
    this._applyPaint(ctx, paint);
    ctx.beginPath();
    ctx.rect(rect.left, rect.top, rect.width(), rect.height());
    this._strokeOrFill(ctx, paint, true);
  }

  _drawRRect(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let rrect = scanner.scanRRect();
    let paint = scanner.scanPaint();

    this._applyPaint(ctx, paint);
    this._drawRRectPath(ctx, rrect, true);
    this._strokeOrFill(ctx, paint, true);
  }

  _drawDRRect(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let outer = scanner.scanRRect();
    let inner = scanner.scanRRect();
    let paint = scanner.scanPaint();
    this._applyPaint(ctx, paint);
    this._drawRRectPath(ctx, outer, true);
    this._drawRRectPathReverse(ctx, inner, false);
    this._strokeOrFill(ctx, paint, true);
  }

  _drawRRectPath(ctx, rrect, startNewPath) {
    // TODO(mdebbar): there's a bug in this code, it doesn't correctly handle
    //                the case when the radius is greater than the width of the
    //                rect. When we fix that in BitmapCanvas, we need to fix it
    //                here too.
    // To draw the rounded rectangle, perform the following 8 steps:
    //   1. draw the line for the top
    //   2. draw the arc for the top-right corner
    //   3. draw the line for the right side
    //   4. draw the arc for the bottom-right corner
    //   5. draw the line for the bottom of the rectangle
    //   6. draw the arc for the bottom-left corner
    //   7. draw the line for the left side
    //   8. draw the arc for the top-left corner
    //
    // After drawing, the current point will be the left side of the top of the
    // rounded rectangle (after the corner).
    // TODO(het): Confirm that this is the end point in Flutter for RRect

    if (startNewPath) {
      ctx.beginPath();
    }

    ctx.moveTo(rrect.left + rrect.trRadiusX, rrect.top);

    // Top side and top-right corner
    ctx.lineTo(rrect.right - rrect.trRadiusX, rrect.top);
    ctx.ellipse(
        rrect.right - rrect.trRadiusX,
        rrect.top + rrect.trRadiusY,
        rrect.trRadiusX,
        rrect.trRadiusY,
        0,
        1.5 * Math.PI,
        2.0 * Math.PI,
        false,
    );

    // Right side and bottom-right corner
    ctx.lineTo(rrect.right, rrect.bottom - rrect.brRadiusY);
    ctx.ellipse(
        rrect.right - rrect.brRadiusX,
        rrect.bottom - rrect.brRadiusY,
        rrect.brRadiusX,
        rrect.brRadiusY,
        0,
        0,
        0.5 * Math.PI,
        false,
    );

    // Bottom side and bottom-left corner
    ctx.lineTo(rrect.left + rrect.blRadiusX, rrect.bottom);
    ctx.ellipse(
        rrect.left + rrect.blRadiusX,
        rrect.bottom - rrect.blRadiusY,
        rrect.blRadiusX,
        rrect.blRadiusY,
        0,
        0.5 * Math.PI,
        Math.PI,
        false,
    );

    // Left side and top-left corner
    ctx.lineTo(rrect.left, rrect.top + rrect.tlRadiusY);
    ctx.ellipse(
        rrect.left + rrect.tlRadiusX,
        rrect.top + rrect.tlRadiusY,
        rrect.tlRadiusX,
        rrect.tlRadiusY,
        0,
        Math.PI,
        1.5 * Math.PI,
        false,
    );
  }

  _drawRRectPathReverse(ctx, rrect, startNewPath) {
    // Draw the rounded rectangle, counterclockwise.
    ctx.moveTo(rrect.right - rrect.trRadiusX, rrect.top);

    if (startNewPath) {
      ctx.beginPath();
    }

    // Top side and top-left corner
    ctx.lineTo(rrect.left + rrect.tlRadiusX, rrect.top);
    ctx.ellipse(
        rrect.left + rrect.tlRadiusX,
        rrect.top + rrect.tlRadiusY,
        rrect.tlRadiusX,
        rrect.tlRadiusY,
        0,
        1.5 * Math.PI,
        Math.PI,
        true,
    );

    // Left side and bottom-left corner
    ctx.lineTo(rrect.left, rrect.bottom - rrect.blRadiusY);
    ctx.ellipse(
        rrect.left + rrect.blRadiusX,
        rrect.bottom - rrect.blRadiusY,
        rrect.blRadiusX,
        rrect.blRadiusY,
        0,
        Math.PI,
        0.5 * Math.PI,
        true,
    );

    // Bottom side and bottom-right corner
    ctx.lineTo(rrect.right - rrect.brRadiusX, rrect.bottom);
    ctx.ellipse(
        rrect.right - rrect.brRadiusX,
        rrect.bottom - rrect.brRadiusY,
        rrect.brRadiusX,
        rrect.brRadiusY,
        0,
        0.5 * Math.PI,
        0,
        true,
    );

    // Right side and top-right corner
    ctx.lineTo(rrect.right, rrect.top + rrect.trRadiusY);
    ctx.ellipse(
        rrect.right - rrect.trRadiusX,
        rrect.top + rrect.trRadiusY,
        rrect.trRadiusX,
        rrect.trRadiusY,
        0,
        0,
        1.5 * Math.PI,
        true,
    );
  }

  _clipRect(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let rect = scanner.scanRect();
    ctx.beginPath();
    ctx.rect(rect.left, rect.top, rect.width(), rect.height());
    ctx.clip();
  }

  _clipRRect(ctx, geom, command) {
    let path = new Path([]);
    let commands = [new RRectCommand(command[1])];
    path.subpaths.push(new Subpath(commands));
    this._runPath(ctx, path);
    ctx.clip();
  }

  _clipPath(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let path = scanner.scanPath();
    this._runPath(ctx, path);
    ctx.clip();
  }

  _drawCircle(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let dx = scanner.scanNumber();
    let dy = scanner.scanNumber();
    let radius = scanner.scanNumber();
    let paint = scanner.scanPaint();

    this._applyPaint(ctx, paint);
    ctx.beginPath();
    ctx.ellipse(dx, dy, radius, radius, 0, 0, 2.0 * Math.PI, false);
    this._strokeOrFill(ctx, paint, true);
  }

  _drawOval(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let rect = scanner.scanRect();
    let paint = scanner.scanPaint();

    this._applyPaint(ctx, paint);
    ctx.beginPath();
    ctx.ellipse(
        (rect.left + rect.right) / 2, (rect.top + rect.bottom) / 2,
        rect.width / 2, rect.height / 2, 0, 0, 2.0 * Math.PI, false);
    this._strokeOrFill(ctx, paint, true);
  }

  _drawPath(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let path = scanner.scanPath();
    let paint = scanner.scanPaint();
    this._applyPaint(ctx, paint);
    this._runPath(ctx, path);
    this._strokeOrFill(ctx, paint, true);
  }

  _drawShadow(ctx, geom, command) {
    // TODO: this is mostly a stub; implement properly.
    let scanner = _scanCommand(command);
    let path = scanner.scanPath();
    let color = scanner.scanArray();
    let elevation = scanner.scanNumber();
    let transparentOccluder = scanner.scanBool();

    let shadows = _computeShadowsForElevation(elevation, color);
    for (let i = 0; i < shadows.length; i++) {
      let shadow = shadows[i];

      let paint = new Paint(
          null,                             // blendMode
          PaintingStyle.fill,               // style
          1.0,                              // strokeWidth
          null,                             // strokeCap
          true,                             // isAntialias
          shadow.color,                     // color
          null,                             // shader
          [BlurStyle.normal, shadow.blur],  // maskFilter
          null,                             // filterQuality
          null                              // colorFilter
      );

      ctx.save();
      ctx.translate(shadow.offsetX, shadow.offsetY);
      this._applyPaint(ctx, paint);
      this._runPath(ctx, path, true);
      this._strokeOrFill(ctx, paint, false);
      ctx.restore();
    }
    this._resetPaint(ctx);
  }

  _runPath(ctx, path) {
    ctx.beginPath();
    for (let i = 0; i < path.subpaths.length; i++) {
      let subpath = path.subpaths[i];
      for (let j = 0; j < subpath.commands.length; j++) {
        let command = subpath.commands[j];
        switch (command.type()) {
          case PathCommandType.bezierCurveTo:
            ctx.bezierCurveTo(
                command.x1, command.y1, command.x2, command.y2, command.x3,
                command.y3);
            break;
          case PathCommandType.close:
            ctx.closePath();
            break;
          case PathCommandType.ellipse:
            ctx.ellipse(
                command.x, command.y, command.radiusX, command.radiusY,
                command.rotation, command.startAngle, command.endAngle,
                command.anticlockwise);
            break;
          case PathCommandType.lineTo:
            ctx.lineTo(command.x, command.y);
            break;
          case PathCommandType.moveTo:
            ctx.moveTo(command.x, command.y);
            break;
          case PathCommandType.rrect:
            this._drawRRectPath(ctx, command.rrect, false);
            break;
          case PathCommandType.rect:
            ctx.rect(command.x, command.y, command.width, command.height);
            break;
          case PathCommandType.quadraticCurveTo:
            ctx.quadraticCurveTo(
                command.x1, command.y1, command.x2, command.y2);
            break;
          default:
            throw new Error(`Unknown path command ${command.type()}`);
        }
      }
    }
  }

  _drawColor(ctx, geom, command) {
    ctx.globalCompositeOperation = _stringForBlendMode(command[2]);
    ctx.fillStyle = command[1];

    // Fill a virtually infinite rect with the color.
    //
    // We can't use (0, 0, width, height) because the current transform can
    // cause it to not fill the entire clip.
    ctx.fillRect(-10000, -10000, 20000, 20000);
    this._resetPaint(ctx);
  }

  _drawLine(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let p1dx = scanner.scanNumber();
    let p1dy = scanner.scanNumber();
    let p2dx = scanner.scanNumber();
    let p2dy = scanner.scanNumber();
    let paint = scanner.scanPaint();
    this._applyPaint(ctx, paint);
    ctx.beginPath();
    ctx.moveTo(p1dx, p1dy);
    ctx.lineTo(p2dx, p2dy);
    ctx.stroke();
    this._resetPaint(ctx);
  }

  _drawPaint(ctx, geom, command) {
    let scanner = _scanCommand(command);
    let paint = scanner.scanPaint();
    this._applyPaint(ctx, paint);
    ctx.beginPath();

    // Fill a virtually infinite rect with the color.
    //
    // We can't use (0, 0, width, height) because the current transform can
    // cause it to not fill the entire clip.
    ctx.fillRect(-10000, -10000, 20000, 20000);
    this._resetPaint(ctx);
  }
}

function _scanCommand(command) {
  return new CommandScanner(command);
}

const PaintingStyle = {
  fill: 0,
  stroke: 1,
};

/// A singleton used to parse serialized commands.
class CommandScanner {
  constructor(command) {
    // Skip the first element, which is always the command ID.
    this.index = 1;
    this.command = command;
  }

  scanRect() {
    let rect = this.command[this.index++];
    return new Rect(rect[0], rect[1], rect[2], rect[3]);
  }

  scanRRect() {
    let rrect = this.command[this.index++];
    return new RRect(
        rrect[0], rrect[1], rrect[2], rrect[3], rrect[4], rrect[5], rrect[6],
        rrect[7], rrect[8], rrect[9], rrect[10], rrect[11]);
  }

  scanPaint() {
    let paint = this.command[this.index++];
    return new Paint(
        paint[0], paint[1], paint[2], paint[3], paint[4], paint[5], paint[6],
        paint[7], paint[8], paint[9]);
  }

  scanNumber() {
    return this.command[this.index++];
  }

  scanString() {
    return this.command[this.index++];
  }

  scanBool() {
    return this.command[this.index++];
  }

  scanPath() {
    let subpaths = this.command[this.index++];
    return new Path(subpaths);
  }

  scanArray() {
    return this.command[this.index++];
  }
}

class Rect {
  constructor(left, top, right, bottom) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  width() {
    return this.right - this.left;
  }

  height() {
    return this.bottom - this.top;
  }
}

class RRect {
  constructor(
      left, top, right, bottom, tlRadiusX, tlRadiusY, trRadiusX, trRadiusY,
      brRadiusX, brRadiusY, blRadiusX, blRadiusY) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
    this.tlRadiusX = tlRadiusX;
    this.tlRadiusY = tlRadiusY;
    this.trRadiusX = trRadiusX;
    this.trRadiusY = trRadiusY;
    this.brRadiusX = brRadiusX;
    this.brRadiusY = brRadiusY;
    this.blRadiusX = blRadiusX;
    this.blRadiusY = blRadiusY;
  }

  tallMiddleRect() {
    let leftRadius = Math.max(this.blRadiusX, this.tlRadiusX);
    let rightRadius = Math.max(this.trRadiusX, this.brRadiusX);
    return new Rect(
        this.left + leftRadius, this.top, this.right - rightRadius,
        this.bottom);
  }

  middleRect() {
    let leftRadius = Math.max(this.blRadiusX, this.tlRadiusX);
    let topRadius = Math.max(this.tlRadiusY, this.trRadiusY);
    let rightRadius = Math.max(this.trRadiusX, this.brRadiusX);
    let bottomRadius = Math.max(this.brRadiusY, this.blRadiusY);
    return new Rect(
        this.left + leftRadius, this.top + topRadius, this.right - rightRadius,
        this.bottom - bottomRadius);
  }

  wideMiddleRect() {
    let topRadius = Math.max(this.tlRadiusY, this.trRadiusY);
    let bottomRadius = Math.max(this.brRadiusY, this.blRadiusY);
    return new Rect(
        this.left, this.top + topRadius, this.right,
        this.bottom - bottomRadius);
  }
}

class Paint {
  constructor(
      blendMode, style, strokeWidth, strokeCap, isAntialias, color, shader,
      maskFilter, filterQuality, colorFilter) {
    this.blendMode = blendMode;
    this.style = style;
    this.strokeWidth = strokeWidth;
    this.strokeCap = strokeCap;
    this.isAntialias = isAntialias;
    this.color = color;
    this.shader = _deserializeShader(shader);  // TODO: deserialize
    this.maskFilter = maskFilter;
    this.filterQuality = filterQuality;
    this.colorFilter = colorFilter;  // TODO: deserialize
  }
}

function _deserializeShader(data) {
  if (!data) {
    return null;
  }

  switch (data[0]) {
    case 1:
      return new GradientLinear(data);
    default:
      throw new Error(`Shader type not supported: ${data}`);
  }
}

class GradientLinear {
  constructor(data) {
    this.fromX = data[1];
    this.fromY = data[2];
    this.toX = data[3];
    this.toY = data[4];
    this.colors = data[5];
    this.colorStops = data[6];
    this.tileMode = data[7];
  }

  createPaintStyle(ctx) {
    let gradient =
        ctx.createLinearGradient(this.fromX, this.fromY, this.toX, this.toY);
    if (this.colorStops == null) {
      gradient.addColorStop(0, this.colors[0]);
      gradient.addColorStop(1, this.colors[1]);
      return gradient;
    }
    for (let i = 0; i < this.colors.length; i++) {
      gradient.addColorStop(this.colorStops[i], this.colors[i]);
    }
    return gradient;
  }
}

const BlendMode = {
  clear: 0,
  src: 1,
  dst: 2,
  srcOver: 3,
  dstOver: 4,
  srcIn: 5,
  dstIn: 6,
  srcOut: 7,
  dstOut: 8,
  srcATop: 9,
  dstATop: 10,
  xor: 11,
  plus: 12,
  modulate: 13,
  screen: 14,
  overlay: 15,
  darken: 16,
  lighten: 17,
  colorDodge: 18,
  colorBurn: 19,
  hardLight: 20,
  softLight: 21,
  difference: 22,
  exclusion: 23,
  multiply: 24,
  hue: 25,
  saturation: 26,
  color: 27,
  luminosity: 28,
};

function _stringForBlendMode(blendMode) {
  if (blendMode == null) return null;
  switch (blendMode) {
    case BlendMode.srcOver:
      return 'source-over';
    case BlendMode.srcIn:
      return 'source-in';
    case BlendMode.srcOut:
      return 'source-out';
    case BlendMode.srcATop:
      return 'source-atop';
    case BlendMode.dstOver:
      return 'destination-over';
    case BlendMode.dstIn:
      return 'destination-in';
    case BlendMode.dstOut:
      return 'destination-out';
    case BlendMode.dstATop:
      return 'destination-atop';
    case BlendMode.plus:
      return 'lighten';
    case BlendMode.src:
      return 'copy';
    case BlendMode.xor:
      return 'xor';
    case BlendMode.multiply:
      // Falling back to multiply, ignoring alpha channel.
      // TODO(flutter_web): only used for debug, find better fallback for web.
    case BlendMode.modulate:
      return 'multiply';
    case BlendMode.screen:
      return 'screen';
    case BlendMode.overlay:
      return 'overlay';
    case BlendMode.darken:
      return 'darken';
    case BlendMode.lighten:
      return 'lighten';
    case BlendMode.colorDodge:
      return 'color-dodge';
    case BlendMode.colorBurn:
      return 'color-burn';
    case BlendMode.hardLight:
      return 'hard-light';
    case BlendMode.softLight:
      return 'soft-light';
    case BlendMode.difference:
      return 'difference';
    case BlendMode.exclusion:
      return 'exclusion';
    case BlendMode.hue:
      return 'hue';
    case BlendMode.saturation:
      return 'saturation';
    case BlendMode.color:
      return 'color';
    case BlendMode.luminosity:
      return 'luminosity';
    default:
      throw new Error(
          'Flutter web does not support the blend mode: $blendMode');
  }
}

const StrokeCap = {
  butt: 0,
  round: 1,
  square: 2,
};

function _stringForStrokeCap(strokeCap) {
  if (strokeCap == null) return null;
  switch (strokeCap) {
    case StrokeCap.butt:
      return 'butt';
    case StrokeCap.round:
      return 'round';
    case StrokeCap.square:
    default:
      return 'square';
  }
}

class Path {
  constructor(serializedSubpaths) {
    this.subpaths = [];
    for (let i = 0; i < serializedSubpaths.length; i++) {
      let subpath = serializedSubpaths[i];
      let pathCommands = [];
      for (let j = 0; j < subpath.length; j++) {
        let pathCommand = subpath[j];
        switch (pathCommand[0]) {
          case 1:
            pathCommands.push(new MoveTo(pathCommand));
            break;
          case 2:
            pathCommands.push(new LineTo(pathCommand));
            break;
          case 3:
            pathCommands.push(new Ellipse(pathCommand));
            break;
          case 4:
            pathCommands.push(new QuadraticCurveTo(pathCommand));
            break;
          case 5:
            pathCommands.push(new BezierCurveTo(pathCommand));
            break;
          case 6:
            pathCommands.push(new RectCommand(pathCommand));
            break;
          case 7:
            pathCommands.push(new RRectCommand(pathCommand));
            break;
          case 8:
            pathCommands.push(new CloseCommand());
            break;
          default:
            throw new Error(`Unsupported path command: ${pathCommand}`);
        }
      }

      this.subpaths.push(new Subpath(pathCommands));
    }
  }
}

class Subpath {
  constructor(commands) {
    this.commands = commands;
  }
}

class MoveTo {
  constructor(data) {
    this.x = data[1];
    this.y = data[2];
  }

  type() {
    return PathCommandType.moveTo;
  }
}

class LineTo {
  constructor(data) {
    this.x = data[1];
    this.y = data[2];
  }

  type() {
    return PathCommandType.lineTo;
  }
}

class Ellipse {
  constructor(data) {
    this.x = data[1];
    this.y = data[2];
    this.radiusX = data[3];
    this.radiusY = data[4];
    this.rotation = data[5];
    this.startAngle = data[6];
    this.endAngle = data[7];
    this.anticlockwise = data[8];
  }

  type() {
    return PathCommandType.ellipse;
  }
}

class QuadraticCurveTo {
  constructor(data) {
    this.x1 = data[1];
    this.y1 = data[2];
    this.x2 = data[3];
    this.y2 = data[4];
  }

  type() {
    return PathCommandType.quadraticCurveTo;
  }
}

class BezierCurveTo {
  constructor(data) {
    this.x1 = data[1];
    this.y1 = data[2];
    this.x2 = data[3];
    this.y2 = data[4];
    this.x3 = data[5];
    this.y3 = data[6];
  }

  type() {
    return PathCommandType.bezierCurveTo;
  }
}

class RectCommand {
  constructor(data) {
    this.x = data[1];
    this.y = data[2];
    this.width = data[3];
    this.height = data[4];
  }

  type() {
    return PathCommandType.rect;
  }
}

class RRectCommand {
  constructor(data) {
    let scanner = _scanCommand(data);
    this.rrect = scanner.scanRRect();
  }

  type() {
    return PathCommandType.rrect;
  }
}

class CloseCommand {
  type() {
    return PathCommandType.close;
  }
}

class CanvasShadow {
  constructor(offsetX, offsetY, blur, spread, color) {
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.blur = blur;
    this.spread = spread;
    this.color = color;
  }
}

const _noShadows = [];

function _computeShadowsForElevation(elevation, color) {
  if (elevation <= 0.0) {
    return _noShadows;
  } else if (elevation <= 1.0) {
    return _computeShadowElevation(2, color);
  } else if (elevation <= 2.0) {
    return _computeShadowElevation(4, color);
  } else if (elevation <= 3.0) {
    return _computeShadowElevation(6, color);
  } else if (elevation <= 4.0) {
    return _computeShadowElevation(8, color);
  } else if (elevation <= 5.0) {
    return _computeShadowElevation(16, color);
  } else {
    return _computeShadowElevation(24, color);
  }
}

function _computeShadowElevation(dp, color) {
  // TODO(yjbanov): multiple shadows are very expensive. Find a more efficient
  //                method to render them.
  let red = color[1];
  let green = color[2];
  let blue = color[3];

  // let penumbraColor = `rgba(${red}, ${green}, ${blue}, 0.14)`;
  // let ambientShadowColor = `rgba(${red}, ${green}, ${blue}, 0.12)`;
  let umbraColor = `rgba(${red}, ${green}, ${blue}, 0.2)`;

  let result = [];
  if (dp === 2) {
    // result.push(new CanvasShadow(0.0, 2.0, 1.0, 0.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 3.0, 0.5, -2.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 1.0, 2.5, 0.0, umbraColor));
  } else if (dp === 3) {
    // result.push(new CanvasShadow(0.0, 1.5, 4.0, 0.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 3.0, 1.5, -2.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 1.0, 4.0, 0.0, umbraColor));
  } else if (dp === 4) {
    // result.push(new CanvasShadow(0.0, 4.0, 2.5, 0.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 1.0, 5.0, 0.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 2.0, 2.0, -1.0, umbraColor));
  } else if (dp === 6) {
    // result.push(new CanvasShadow(0.0, 6.0, 5.0, 0.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 1.0, 9.0, 0.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 3.0, 2.5, -1.0, umbraColor));
  } else if (dp === 8) {
    // result.push(new CanvasShadow(0.0, 4.0, 10.0, 1.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 3.0, 7.0, 2.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 5.0, 2.5, -3.0, umbraColor));
  } else if (dp === 12) {
    // result.push(new CanvasShadow(0.0, 12.0, 8.5, 2.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 5.0, 11.0, 4.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 7.0, 4.0, -4.0, umbraColor));
  } else if (dp === 16) {
    // result.push(new CanvasShadow(0.0, 16.0, 12.0, 2.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 6.0, 15.0, 5.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 0.0, 5.0, -5.0, umbraColor));
  } else {
    // result.push(new CanvasShadow(0.0, 24.0, 18.0, 3.0, penumbraColor));
    // result.push(new CanvasShadow(0.0, 9.0, 23.0, 8.0, ambientShadowColor));
    result.push(new CanvasShadow(0.0, 11.0, 7.5, -7.0, umbraColor));
  }
  return result;
}

const PathCommandType = {
  moveTo: 0,
  lineTo: 1,
  ellipse: 2,
  close: 3,
  quadraticCurveTo: 4,
  bezierCurveTo: 5,
  rect: 6,
  rrect: 7,
};

const TileMode = {
  clamp: 0,
  repeated: 1,
};

const BlurStyle = {
  normal: 0,
  solid: 1,
  outer: 2,
  inner: 3,
};

/// This makes the painter available as "background-image: paint(flt)".
registerPaint('flt', FlutterPainter);
