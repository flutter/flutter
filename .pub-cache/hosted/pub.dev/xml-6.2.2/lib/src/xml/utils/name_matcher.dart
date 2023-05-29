import '../mixins/has_name.dart';
import 'functions.dart';

/// Internal factory to create element lookups.
///
/// The `name` is considered to be a local name if a `namespaceUri` is provided,
/// otherwise `name` is considered to be fully qualified.
Predicate<XmlHasName> createNameLookup(String name, String? namespace) {
  if (namespace == null) {
    return (named) => named.name.qualified == name;
  } else {
    return (named) =>
        named.name.local == name && named.name.namespaceUri == namespace;
  }
}

/// Internal factory to create element matchers with wildcards.
Predicate<XmlHasName> createNameMatcher(String name, String? namespace) {
  if (name == '*') {
    if (namespace == null || namespace == '*') {
      return (named) => true;
    } else {
      return (named) => named.name.namespaceUri == namespace;
    }
  } else {
    if (namespace == null) {
      return (named) => named.name.qualified == name;
    } else if (namespace == '*') {
      return (named) => named.name.local == name;
    } else {
      return (named) =>
          named.name.local == name && named.name.namespaceUri == namespace;
    }
  }
}
