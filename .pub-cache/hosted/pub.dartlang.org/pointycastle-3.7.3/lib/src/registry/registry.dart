// See file LICENSE for more information.

library src.registry;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registration.dart';

final FactoryRegistry registry = _RegistryImpl();

abstract class FactoryRegistry {
  T create<T>(String registrableName);

  void register<T>(FactoryConfig config);
}

typedef /*Registrable*/ RegistrableConstructor = Function();
typedef DynamicConstructorFactory = RegistrableConstructor Function(
    String registrableName, Match match);

abstract class FactoryConfig {
  final Type type;

  FactoryConfig(this.type);
}

class StaticFactoryConfig extends FactoryConfig {
  final String algorithmName;
  final RegistrableConstructor factory;

  StaticFactoryConfig(Type type, this.algorithmName, this.factory)
      : super(type);
}

// From the PatternCharacter rule here:
// http://ecma-international.org/ecma-262/5.1/#sec-15.10
final _specialRegExpChars = RegExp(r'([\\\^\$\.\|\+\[\]\(\)\{\}])');

/// Escapes special regular expression characters in [str] so that it can be
/// used as a literal match inside of a [RegExp].
///
/// The special characters are: \ ^ $ . | + [ ] ( ) { }
/// as defined here: http://ecma-international.org/ecma-262/5.1/#sec-15.10
String _escapeRegExp(String str) => str.splitMapJoin(_specialRegExpChars,
    onMatch: (Match m) => '\\${m.group(0)}', onNonMatch: (s) => s);

class DynamicFactoryConfig extends FactoryConfig {
  final RegExp regExp;
  final DynamicConstructorFactory factory;

  DynamicFactoryConfig(Type type, this.regExp, this.factory) : super(type);

  DynamicFactoryConfig.regex(
      Type type, String regexString, DynamicConstructorFactory factory)
      : this(type, RegExp(regexString), factory);

  /// A dynamic registry that matches by prefix.
  /// The part after the prefix will be in `match.group(1)`.
  DynamicFactoryConfig.prefix(
      Type type, String prefix, DynamicConstructorFactory factory)
      : this.regex(type, '^${_escapeRegExp(prefix)}(.+)\$', factory);

  /// A dynamic registry that matches by suffix.
  /// The part before the suffix will be in `match.group(1)`.
  DynamicFactoryConfig.suffix(
      Type type, String suffix, DynamicConstructorFactory factory)
      : this.regex(type, '^(.+)${_escapeRegExp(suffix)}\$', factory);

  /// Invokes the factory when it matches. Else returns null.
  RegistrableConstructor? tryFactory(String algorithmName) {
    Match? match = regExp.firstMatch(algorithmName);
    if (match == null) {
      return null;
    }
    return factory(algorithmName, match);
  }
}

class _RegistryImpl implements FactoryRegistry {
  static const int _CONSTRUCTOR_CACHE_SIZE = 25;

  final Map<Type, Map<String, RegistrableConstructor>> _staticFactories;
  final Map<Type, Set<DynamicFactoryConfig>> _dynamicFactories;

  final Map<String, RegistrableConstructor> _constructorCache =
      <String, RegistrableConstructor>{};

  bool _initialized = false;

  _RegistryImpl()
      : _staticFactories = <Type, Map<String, RegistrableConstructor>>{},
        _dynamicFactories = <Type, Set<DynamicFactoryConfig>>{};

  @override
  T create<T>(String registrableName) {
    var type = T;
    var constructor = getConstructor(type, registrableName);
    var result = constructor() as T;
    return result;
  }

  RegistrableConstructor getConstructor(Type type, String registrableName) {
    var constructor = _constructorCache['$type.$registrableName'];

    if (constructor == null) {
      constructor = _createConstructor(type, registrableName);
      if (_constructorCache.length > _CONSTRUCTOR_CACHE_SIZE) {
        _constructorCache.clear();
      }
      _constructorCache['$type.$registrableName'] = constructor!;
    }
    return constructor;
  }

  RegistrableConstructor? _createConstructor(
      Type type, String registrableName) {
    // Init lazily
    _checkInit();

    if (_staticFactories.containsKey(type) &&
        _staticFactories[type]!.containsKey(registrableName)) {
      return _staticFactories[type]![registrableName];
    }

    if (_dynamicFactories.containsKey(type)) {
      for (var factory in _dynamicFactories[type]!) {
        var constructor = factory.tryFactory(registrableName);
        if (constructor != null) {
          return constructor;
        }
      }
    }

    // No factory found
    throw RegistryFactoryException.unknown(registrableName, type);
  }

  void _checkInit() {
    if (!_initialized) {
      _initialize();
    }
  }

  @override
  void register<T>(FactoryConfig config) {
    if (config is StaticFactoryConfig) {
      _addStaticFactoryConfig(config);
    } else if (config is DynamicFactoryConfig) {
      _addDynamicFactoryConfig(config);
    }
  }

  void _addStaticFactoryConfig(StaticFactoryConfig config) {
    Map factories = _staticFactories.putIfAbsent(
        config.type, () => <String, RegistrableConstructor>{});
    factories[config.algorithmName] = config.factory;
  }

  void _addDynamicFactoryConfig(DynamicFactoryConfig config) {
    Set factories = _dynamicFactories.putIfAbsent(
        config.type, () => <DynamicFactoryConfig>{});
    factories.add(config);
  }

  void _initialize() {
    registerFactories(this);
    _initialized = true;
  }
}
