import 'package:flutter_cache_manager/src/cache_managers/image_cache_manager.dart';

import '../../flutter_cache_manager.dart';
import '../config/config.dart';

/// The DefaultCacheManager that can be easily used directly. The code of
/// this implementation can be used as inspiration for more complex cache
/// managers.
class DefaultCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'libCachedImageData';

  static DefaultCacheManager _instance;
  factory DefaultCacheManager() {
    _instance ??= DefaultCacheManager._();
    return _instance;
  }

  DefaultCacheManager._() : super(Config(key));
}
