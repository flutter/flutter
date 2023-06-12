import '../flutter_cache_manager.dart';

/// Instance of the cache manager. Can be set to a custom one if preferred.
CacheLogger cacheLogger = CacheLogger();

/// Log levels of the cache manager. Debug shows failed downloads and verbose
/// also shows successful downloads and cache retrievals.
enum CacheManagerLogLevel {
  none,
  warning,
  debug,
  verbose,
}

/// [CacheLogger] which is used by the cache manager to log useful information
class CacheLogger {
  /// Function to log a message on a certain loglevel
  void log(String message, CacheManagerLogLevel level) {
    if (CacheManager.logLevel.index >= level.index) {
      print(message);
    }
  }
}
