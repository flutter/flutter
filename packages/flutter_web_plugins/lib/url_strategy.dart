export 'src/navigation_common/url_strategy.dart';

export 'src/navigation_non_web/url_strategy.dart'
    if (dart.library.html) 'src/navigation/url_strategy.dart';
