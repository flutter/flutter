import 'dart:async';

String systemLocale = 'en_US';

String? _defaultLocale;

set defaultLocale(String? newLocale) {
  _defaultLocale = newLocale;
}

String? get defaultLocale {
  var zoneLocale = Zone.current[#Intl.locale] as String?;
  return zoneLocale == null ? _defaultLocale : zoneLocale;
}

String getCurrentLocale() {
  defaultLocale ??= systemLocale;
  return defaultLocale!;
}
