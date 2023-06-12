import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

mixin CacheInfoRepositoryHelperMethods on CacheInfoRepository {
  var openConnections = 0;
  Completer<bool>? openCompleter;

  bool shouldOpenOnNewConnection() {
    openConnections++;
    openCompleter ??= Completer<bool>();
    return openConnections == 1;
  }

  bool opened() {
    openCompleter!.complete(true);
    return true;
  }

  bool shouldClose() {
    openConnections--;
    if (openConnections == 0) {
      openCompleter = null;
    }
    return openConnections == 0;
  }
}
