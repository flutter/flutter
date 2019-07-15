import 'dart:io';

import 'package:flutter/cupertino.dart';

const String kViewType = 'simple_view';

class SimplePlatformView extends StatelessWidget {
  
  const SimplePlatformView({Key key, this.onPlatformViewCreated}):super(key: key);
  
  final Function onPlatformViewCreated;
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        key: key,
        viewType: kViewType,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        key: key,
        viewType: kViewType,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }

    return null;
  }
}
