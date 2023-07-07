import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'size_extension.dart';

class RSizedBox extends SizedBox {
  const RSizedBox({
    Key? key,
    double? height,
    double? width,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, width: width, height: height);

  const RSizedBox.vertical(
    double? height, {
    Key? key,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, height: height);

  const RSizedBox.horizontal(
    double? width, {
    Key? key,
    Widget? child,
  })  : _square = false,
        super(key: key, child: child, width: width);

  const RSizedBox.square({
    Key? key,
    double? height,
    double? dimension,
    Widget? child,
  })  : _square = true,
        super.square(key: key, child: child, dimension: dimension);

  RSizedBox.fromSize({
    Key? key,
    Size? size,
    Widget? child,
  })  : _square = false,
        super.fromSize(key: key, child: child, size: size);

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      additionalConstraints: _additionalConstraints,
    );
  }

  final bool _square;

  BoxConstraints get _additionalConstraints {
    final boxConstraints =
        BoxConstraints.tightFor(width: width, height: height);
    return _square ? boxConstraints.r : boxConstraints.hw;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }
}
