// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "mirrors_patch.dart";

var _dirty = false; // Set to true by the VM when more libraries are loaded.

class _InternalMirrorError extends Error {
  final String _msg;
  _InternalMirrorError(this._msg);
  String toString() => _msg;
}

String _n(Symbol symbol) => internal.Symbol.getName(symbol as internal.Symbol);

Symbol _s(String name) {
  return new internal.Symbol.unvalidated(name);
}

Symbol? _sOpt(String? name) {
  if (name == null) return null;
  return new internal.Symbol.unvalidated(name);
}

Symbol _computeQualifiedName(DeclarationMirror? owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  return _s('${_n(owner.qualifiedName)}.${_n(simpleName)}');
}

String _makeSignatureString(
    TypeMirror returnType, List<ParameterMirror> parameters) {
  StringBuffer buf = new StringBuffer();
  buf.write('(');
  bool found_optional_positional = false;
  bool found_optional_named = false;

  for (int i = 0; i < parameters.length; i++) {
    var param = parameters[i];
    if (param.isOptional && param.isNamed && !found_optional_named) {
      buf.write('{');
      found_optional_named = true;
    }
    if (param.isOptional && !param.isNamed && !found_optional_positional) {
      buf.write('[');
      found_optional_positional = true;
    }
    if (param.isNamed) {
      buf.write(_n(param.simpleName));
      buf.write(': ');
    }
    buf.write(_n(param.type.qualifiedName));
    if (i < (parameters.length - 1)) {
      buf.write(', ');
    }
  }
  if (found_optional_named) {
    buf.write('}');
  }
  if (found_optional_positional) {
    buf.write(']');
  }
  buf.write(') -> ');
  buf.write(_n(returnType.qualifiedName));
  return buf.toString();
}

@pragma("vm:external-name", "DeclarationMirror_location")
external SourceLocation? _location(reflectee);

@pragma("vm:external-name", "DeclarationMirror_metadata")
external List<dynamic> _metadata(reflectee);

List<InstanceMirror> _wrapMetadata(List reflectees) {
  var mirrors = <InstanceMirror>[];
  for (var reflectee in reflectees) {
    mirrors.add(reflect(reflectee));
  }
  return new UnmodifiableListView<InstanceMirror>(mirrors);
}

@pragma("vm:external-name", "TypeMirror_subtypeTest")
external bool _subtypeTest(Type a, Type b);

class _MirrorSystem extends MirrorSystem {
  final TypeMirror dynamicType = new _SpecialTypeMirror._('dynamic');
  final TypeMirror voidType = new _SpecialTypeMirror._('void');
  final TypeMirror neverType = new _SpecialTypeMirror._('Never');

  var _libraries;
  Map<Uri, LibraryMirror> get libraries {
    if ((_libraries == null) || _dirty) {
      _libraries = new Map<Uri, LibraryMirror>();
      for (LibraryMirror lib in _computeLibraries()) {
        _libraries[lib.uri] = lib;
      }
      _libraries = new UnmodifiableMapView<Uri, LibraryMirror>(_libraries);
      _dirty = false;
    }
    return _libraries;
  }

  @pragma("vm:external-name", "MirrorSystem_libraries")
  external static List<dynamic> _computeLibraries();

  IsolateMirror? _isolate;
  IsolateMirror get isolate {
    var i = _isolate;
    if (i != null) return i;
    return _isolate = _computeIsolate();
  }

  @pragma("vm:external-name", "MirrorSystem_isolate")
  external static IsolateMirror _computeIsolate();

  String toString() => "MirrorSystem for isolate '${isolate.debugName}'";
}

class _SourceLocation implements SourceLocation {
  _SourceLocation._(uriString, this.line, this.column)
      : this.sourceUri = Uri.parse(uriString);

  // Line and column positions are 1-origin, or 0 if unknown.
  final int line;
  final int column;

  final Uri sourceUri;

  String toString() {
    return column == 0 ? "$sourceUri:$line" : "$sourceUri:$line:$column";
  }
}

class _IsolateMirror extends Mirror implements IsolateMirror {
  final String debugName;
  final LibraryMirror rootLibrary;

  _IsolateMirror._(this.debugName, this.rootLibrary);

  bool get isCurrent => true;

  String toString() => "IsolateMirror on '$debugName'";

  Future<LibraryMirror> loadUri(Uri uri) async {
    var result = _loadUri(uri.toString());
    if (result == null) {
      // Censored library.
      throw new Exception("Cannot load $uri");
    }
    return result;
  }

  @pragma("vm:external-name", "IsolateMirror_loadUri")
  external static LibraryMirror? _loadUri(String uri);
}

class _SyntheticAccessor implements MethodMirror {
  final DeclarationMirror owner;
  final Symbol simpleName;
  final bool isGetter;
  final bool isStatic;
  final bool isTopLevel;
  final _target;

  _SyntheticAccessor(this.owner, this.simpleName, this.isGetter, this.isStatic,
      this.isTopLevel, this._target);

  bool get isSynthetic => true;
  bool get isRegularMethod => false;
  bool get isOperator => false;
  bool get isConstructor => false;
  bool get isConstConstructor => false;
  bool get isGenerativeConstructor => false;
  bool get isFactoryConstructor => false;
  bool get isExternal => false;
  bool get isRedirectingConstructor => false;
  bool get isAbstract => false;
  bool get isExtensionMember => false;
  bool get isExtensionTypeMember => false;

  bool get isSetter => !isGetter;
  bool get isPrivate => _n(simpleName).startsWith('_');

  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);
  Symbol get constructorName => Symbol.empty;

  TypeMirror get returnType => _target.type;
  List<ParameterMirror> get parameters {
    if (isGetter) return const <ParameterMirror>[];
    return new UnmodifiableListView<ParameterMirror>(
        <ParameterMirror>[new _SyntheticSetterParameter(this, this._target)]);
  }

  SourceLocation? get location => null;
  List<InstanceMirror> get metadata => const <InstanceMirror>[];
  String? get source => null;
}

class _SyntheticSetterParameter implements ParameterMirror {
  final DeclarationMirror owner;
  final VariableMirror _target;

  _SyntheticSetterParameter(this.owner, this._target);

  Symbol get simpleName => _target.simpleName;
  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);
  TypeMirror get type => _target.type;

  bool get isOptional => false;
  bool get isNamed => false;
  bool get isStatic => false;
  bool get isTopLevel => false;
  bool get isConst => false;
  bool get isFinal => true;
  bool get isPrivate => false;
  bool get isExtensionMember => false;
  bool get isExtensionTypeMember => false;
  bool get hasDefaultValue => false;
  InstanceMirror? get defaultValue => null;
  SourceLocation? get location => null;
  List<InstanceMirror> get metadata => const <InstanceMirror>[];
}

abstract class _ObjectMirror extends Mirror implements ObjectMirror {
  _invoke(reflectee, functionName, arguments, argumentNames);
  _invokeGetter(reflectee, getterName);
  _invokeSetter(reflectee, setterName, value);

  final _reflectee; // May be a MirrorReference or an ordinary object.

  _ObjectMirror._(this._reflectee);

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {
    int numPositionalArguments = positionalArguments.length;
    int numNamedArguments = namedArguments.length;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List<dynamic>.filled(numArguments, null);
    arguments.setRange(0, numPositionalArguments, positionalArguments);
    List names = new List<dynamic>.filled(numNamedArguments, null);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(this._invoke(_reflectee, _n(memberName), arguments, names));
  }

  InstanceMirror getField(Symbol memberName) {
    return reflect(this._invokeGetter(_reflectee, _n(memberName)));
  }

  InstanceMirror setField(Symbol memberName, dynamic value) {
    this._invokeSetter(_reflectee, _n(memberName), value);
    return reflect(value);
  }

  delegate(Invocation invocation) {
    if (invocation.isMethod) {
      return this
          .invoke(invocation.memberName, invocation.positionalArguments,
              invocation.namedArguments)
          .reflectee;
    }
    if (invocation.isGetter) {
      return this.getField(invocation.memberName).reflectee;
    }
    if (invocation.isSetter) {
      var unwrapped = _n(invocation.memberName);
      var withoutEqual = _s(unwrapped.substring(0, unwrapped.length - 1));
      var arg = invocation.positionalArguments[0];
      this.setField(withoutEqual, arg).reflectee;
      return arg;
    }
    throw "UNREACHABLE";
  }
}

class _InstanceMirror extends _ObjectMirror implements InstanceMirror {
  _InstanceMirror._(reflectee) : super._(reflectee);

  ClassMirror? _type;
  ClassMirror get type {
    var t = _type;
    if (t != null) return t;

    // Note it not safe to use reflectee.runtimeType because runtimeType may
    // be overridden.
    return _type = reflectType(_computeType(reflectee)) as ClassMirror;
  }

  // LocalInstanceMirrors always reflect local instances
  bool get hasReflectee => true;

  get reflectee => _reflectee;

  String toString() => 'InstanceMirror on ${Error.safeToString(_reflectee)}';

  bool operator ==(Object other) {
    return other is _InstanceMirror && identical(_reflectee, other._reflectee);
  }

  int get hashCode {
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return identityHashCode(_reflectee) ^ 0x36363636;
  }

  InstanceMirror getField(Symbol memberName) {
    return reflect(_invokeGetter(_reflectee, _n(memberName)));
  }

  InstanceMirror setField(Symbol memberName, dynamic arg) {
    _invokeSetter(_reflectee, _n(memberName), arg);
    return reflect(arg);
  }

  // Override to include the receiver in the arguments.
  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {
    int numPositionalArguments = positionalArguments.length + 1; // Receiver.
    int numNamedArguments = namedArguments.length;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List<dynamic>.filled(numArguments, null);
    arguments[0] = _reflectee; // Receiver.
    arguments.setRange(1, numPositionalArguments, positionalArguments);
    List names = new List<dynamic>.filled(numNamedArguments, null);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(this._invoke(_reflectee, _n(memberName), arguments, names));
  }

  @pragma("vm:external-name", "InstanceMirror_invoke")
  external _invoke(reflectee, functionName, arguments, argumentNames);

  @pragma("vm:external-name", "InstanceMirror_invokeGetter")
  external _invokeGetter(reflectee, getterName);

  @pragma("vm:external-name", "InstanceMirror_invokeSetter")
  external _invokeSetter(reflectee, setterName, value);

  @pragma("vm:external-name", "InstanceMirror_computeType")
  external static _computeType(reflectee);
}

class _ClosureMirror extends _InstanceMirror implements ClosureMirror {
  _ClosureMirror._(reflectee) : super._(reflectee);

  MethodMirror? _function;
  MethodMirror get function {
    var f = _function;
    if (f != null) return f;
    return _function = _computeFunction(reflectee);
  }

  InstanceMirror apply(List positionalArguments,
      [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {
    return this.invoke(#call, positionalArguments, namedArguments);
  }

  String toString() => "ClosureMirror on '${Error.safeToString(_reflectee)}'";

  @pragma("vm:external-name", "ClosureMirror_function")
  external static _computeFunction(reflectee);
}

abstract class _TypeMirror {
  Type get _reflectedType;
}

class _ClassMirror extends _ObjectMirror implements ClassMirror, _TypeMirror {
  final Type _reflectedType;
  Symbol? _simpleName;
  DeclarationMirror? _owner;
  final bool isAbstract;
  final bool _isGeneric;

  // Since Dart 2, mixins are erased by kernel transformation.
  // Resulting classes have this flag set, and mixed-in type is pulled into
  // the end of interfaces list.
  final bool _isTransformedMixinApplication;

  final bool _isGenericDeclaration;
  final bool isEnum;
  Type _instantiator;

  _ClassMirror._(
      reflectee,
      reflectedType,
      String? simpleName,
      this._owner,
      this.isAbstract,
      this._isGeneric,
      this._isTransformedMixinApplication,
      this._isGenericDeclaration,
      this.isEnum)
      : this._simpleName = _sOpt(simpleName),
        this._reflectedType = reflectedType,
        this._instantiator = reflectedType,
        super._(reflectee);

  bool get hasReflectedType => !_isGenericDeclaration;
  Type get reflectedType {
    if (!hasReflectedType) {
      throw new UnsupportedError(
          "Declarations of generics have no reflected type");
    }
    return _reflectedType;
  }

  Symbol get simpleName {
    // All but anonymous mixin applications have their name set at construction.
    var n = _simpleName;
    if (n != null) return n;

    return _simpleName = this._mixinApplicationName;
  }

  Symbol? _qualifiedName;
  Symbol get qualifiedName {
    var n = _qualifiedName;
    if (n != null) return n;

    return _qualifiedName = _computeQualifiedName(owner, simpleName);
  }

  DeclarationMirror? get owner {
    var o = _owner;
    if (o != null) return o;

    var uri = _ClassMirror._libraryUri(_reflectee);
    return _owner = currentMirrorSystem().libraries[Uri.parse(uri)];
  }

  bool get isPrivate => _n(simpleName).startsWith('_');

  bool get isTopLevel => true;

  SourceLocation? get location {
    return _location(_reflectee);
  }

  _ClassMirror? _trueSuperclassField;
  _ClassMirror? get _trueSuperclass {
    if (_trueSuperclassField == null) {
      Type? supertype = isOriginalDeclaration
          ? _supertype(_reflectedType)
          : _supertypeInstantiated(_reflectedType);
      if (supertype == null) {
        // Object has no superclass.
        return null;
      }
      var supertypeMirror = reflectType(supertype) as _ClassMirror;
      supertypeMirror._instantiator = _instantiator;
      _trueSuperclassField = supertypeMirror;
    }
    return _trueSuperclassField;
  }

  ClassMirror? get superclass {
    return _trueSuperclass;
  }

  var _superinterfaces;
  List<ClassMirror> get superinterfaces {
    var i = _superinterfaces;
    if (i != null) return i;

    var interfaceTypes = isOriginalDeclaration
        ? _nativeInterfaces(_reflectedType)
        : _nativeInterfacesInstantiated(_reflectedType);
    if (_isTransformedMixinApplication) {
      interfaceTypes = interfaceTypes.sublist(0, interfaceTypes.length - 1);
    }
    var interfaceMirrors = <ClassMirror>[];
    for (var interfaceType in interfaceTypes) {
      interfaceMirrors.add(reflectType(interfaceType) as ClassMirror);
    }
    return _superinterfaces =
        new UnmodifiableListView<ClassMirror>(interfaceMirrors);
  }

  Symbol get _mixinApplicationName {
    var mixins = <ClassMirror>[];
    var klass = this;
    while (_nativeMixin(klass._reflectedType) != null) {
      mixins.add(klass.mixin);
      klass = klass.superclass as _ClassMirror;
    }
    return _s(_n(klass.qualifiedName) +
        ' with ' +
        mixins.reversed.map((ClassMirror m) => _n(m.qualifiedName)).join(', '));
  }

  ClassMirror? _mixin;
  ClassMirror get mixin {
    var m = _mixin;
    if (m != null) return m;

    Type? mixinType = _nativeMixinInstantiated(_reflectedType, _instantiator);
    if (mixinType == null) {
      // The reflectee is not a mixin application.
      return _mixin = this;
    } else {
      return _mixin = reflectType(mixinType) as ClassMirror;
    }
  }

  var _cachedStaticMembers;
  Map<Symbol, MethodMirror> get staticMembers {
    var m = _cachedStaticMembers;
    if (m != null) m;

    var result = new Map<Symbol, MethodMirror>();
    var library = this.owner as LibraryMirror;
    declarations.values.forEach((decl) {
      if (decl is MethodMirror && decl.isStatic && !decl.isConstructor) {
        result[decl.simpleName] = decl;
      }
      if (decl is VariableMirror && decl.isStatic) {
        var getterName = decl.simpleName;
        result[getterName] =
            new _SyntheticAccessor(this, getterName, true, true, false, decl);
        if (!decl.isFinal) {
          var setterName = _asSetter(decl.simpleName, library);
          result[setterName] = new _SyntheticAccessor(
              this, setterName, false, true, false, decl);
        }
      }
    });
    return _cachedStaticMembers =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  var _cachedInstanceMembers;
  Map<Symbol, MethodMirror> get instanceMembers {
    var m = _cachedInstanceMembers;
    if (m != null) return m;

    var result = new Map<Symbol, MethodMirror>();
    var library = this.owner as LibraryMirror;
    var sup = superclass;
    if (sup != null) {
      result.addAll(sup.instanceMembers);
    }
    declarations.values.forEach((decl) {
      if (decl is MethodMirror &&
          !decl.isStatic &&
          !decl.isConstructor &&
          !decl.isAbstract) {
        result[decl.simpleName] = decl;
      }
      if (decl is VariableMirror && !decl.isStatic) {
        var getterName = decl.simpleName;
        result[getterName] =
            new _SyntheticAccessor(this, getterName, true, false, false, decl);
        if (!decl.isFinal) {
          var setterName = _asSetter(decl.simpleName, library);
          result[setterName] = new _SyntheticAccessor(
              this, setterName, false, false, false, decl);
        }
      }
    });
    return _cachedInstanceMembers =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, DeclarationMirror>? _declarations;
  Map<Symbol, DeclarationMirror> get declarations {
    var d = _declarations;
    if (d != null) return d;

    var decls = new Map<Symbol, DeclarationMirror>();

    var members = _computeMembers(mixin, _instantiator, _reflectee);
    for (var member in members) {
      decls[member.simpleName] = member;
    }

    var constructors = _computeConstructors(_instantiator, _reflectee);
    var stringName = _n(simpleName);
    for (var constructor in constructors) {
      constructor._patchConstructorName(stringName);
      decls[constructor.simpleName] = constructor;
    }

    for (var typeVariable in typeVariables) {
      decls[typeVariable.simpleName] = typeVariable;
    }

    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(decls);
  }

  // Note: returns correct result only for Dart 1 anonymous mixin applications.
  bool get _isAnonymousMixinApplication {
    if (mixin == this) return false; // Not a mixin application.
    return true;
  }

  List<TypeVariableMirror>? _typeVariables;
  List<TypeVariableMirror> get typeVariables {
    var v = _typeVariables;
    if (v != null) return v;

    if (!_isTransformedMixinApplication && _isAnonymousMixinApplication) {
      return _typeVariables = const <TypeVariableMirror>[];
    }
    var result = <TypeVariableMirror>[];

    List params = _ClassMirror_type_variables(_reflectee);
    ClassMirror owner = originalDeclaration;
    var mirror;
    for (var i = 0; i < params.length; i += 2) {
      mirror = new _TypeVariableMirror._(params[i + 1], params[i], owner);
      result.add(mirror);
    }
    return _typeVariables =
        new UnmodifiableListView<TypeVariableMirror>(result);
  }

  List<TypeMirror>? _typeArguments;
  List<TypeMirror> get typeArguments {
    var a = _typeArguments;
    if (a != null) return a;

    if (_isGenericDeclaration ||
        (!_isTransformedMixinApplication && _isAnonymousMixinApplication)) {
      return _typeArguments = const <TypeMirror>[];
    } else {
      return _typeArguments = new UnmodifiableListView<TypeMirror>(
          _computeTypeArguments(_reflectedType).cast<TypeMirror>());
    }
  }

  bool get isOriginalDeclaration => !_isGeneric || _isGenericDeclaration;

  ClassMirror get originalDeclaration {
    if (isOriginalDeclaration) {
      return this;
    } else {
      return reflectClass(_reflectedType);
    }
  }

  String toString() => "ClassMirror on '${MirrorSystem.getName(simpleName)}'";

  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {
    // Native code will add the 1 or 2 implicit arguments depending on whether
    // we end up invoking a factory or constructor respectively.
    int numPositionalArguments = positionalArguments.length;
    int numNamedArguments = namedArguments.length;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List<dynamic>.filled(numArguments, null);
    arguments.setRange(0, numPositionalArguments, positionalArguments);
    List names = new List<dynamic>.filled(numNamedArguments, null);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(_invokeConstructor(
        _reflectee, _reflectedType, _n(constructorName), arguments, names));
  }

  List<InstanceMirror> get metadata {
    return _wrapMetadata(_metadata(_reflectee));
  }

  bool operator ==(Object other) {
    return other is _ClassMirror &&
        this._reflectee == other._reflectee &&
        this._reflectedType == other._reflectedType &&
        this._isGenericDeclaration == other._isGenericDeclaration;
  }

  int get hashCode => simpleName.hashCode;

  bool isSubtypeOf(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return true;
    if (other == currentMirrorSystem().neverType) return false;
    return _subtypeTest(_reflectedType, (other as _TypeMirror)._reflectedType);
  }

  bool isAssignableTo(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return true;
    if (other == currentMirrorSystem().neverType) return false;
    final otherReflectedType = (other as _TypeMirror)._reflectedType;
    return _subtypeTest(_reflectedType, otherReflectedType) ||
        _subtypeTest(otherReflectedType, _reflectedType);
  }

  bool isSubclassOf(ClassMirror other) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    ClassMirror otherDeclaration = other.originalDeclaration as ClassMirror;
    ClassMirror? c = this;
    while (c != null) {
      c = c.originalDeclaration as ClassMirror;
      if (c == otherDeclaration) return true;
      c = c.superclass as ClassMirror?;
    }
    return false;
  }

  @pragma("vm:external-name", "ClassMirror_libraryUri")
  external static String _libraryUri(reflectee);

  @pragma("vm:external-name", "ClassMirror_supertype")
  external static Type? _supertype(reflectedType);

  @pragma("vm:external-name", "ClassMirror_supertype_instantiated")
  external static Type? _supertypeInstantiated(reflectedType);

  @pragma("vm:external-name", "ClassMirror_interfaces")
  external static List<dynamic> _nativeInterfaces(reflectedType);

  @pragma("vm:external-name", "ClassMirror_interfaces_instantiated")
  external static List<dynamic> _nativeInterfacesInstantiated(reflectedType);

  @pragma("vm:external-name", "ClassMirror_mixin")
  external static Type? _nativeMixin(reflectedType);

  @pragma("vm:external-name", "ClassMirror_mixin_instantiated")
  external static Type? _nativeMixinInstantiated(reflectedType, instantiator);

  @pragma("vm:external-name", "ClassMirror_members")
  external static List<dynamic> _computeMembers(owner, reflectee, instantiator);

  @pragma("vm:external-name", "ClassMirror_constructors")
  external List<dynamic> _computeConstructors(reflectee, instantiator);

  @pragma("vm:external-name", "ClassMirror_invoke")
  external _invoke(reflectee, memberName, arguments, argumentNames);

  @pragma("vm:external-name", "ClassMirror_invokeGetter")
  external _invokeGetter(reflectee, getterName);

  @pragma("vm:external-name", "ClassMirror_invokeSetter")
  external _invokeSetter(reflectee, setterName, value);

  @pragma("vm:external-name", "ClassMirror_invokeConstructor")
  external static _invokeConstructor(
      reflectee, type, constructorName, arguments, argumentNames);

  @pragma("vm:external-name", "ClassMirror_type_variables")
  external static List<dynamic> _ClassMirror_type_variables(reflectee);

  @pragma("vm:external-name", "ClassMirror_type_arguments")
  external static List<dynamic> _computeTypeArguments(reflectee);
}

class _FunctionTypeMirror extends _ClassMirror implements FunctionTypeMirror {
  final _signatureReflectee;
  _FunctionTypeMirror._(reflectee, this._signatureReflectee, reflectedType)
      : super._(reflectee, reflectedType, null, null, false, false, false,
            false, false);

  bool get _isAnonymousMixinApplication => false;

  // FunctionTypeMirrors have a simpleName generated from their signature.
  Symbol? _simpleName;
  Symbol get simpleName {
    var n = _simpleName;
    if (n != null) return n;
    return _simpleName = _s(_makeSignatureString(returnType, parameters));
  }

  MethodMirror? _callMethod;
  MethodMirror get callMethod {
    var m = _callMethod;
    if (m != null) return m;
    return _callMethod = _FunctionTypeMirror_call_method(_signatureReflectee);
  }

  TypeMirror? _returnType;
  TypeMirror get returnType {
    var t = _returnType;
    if (t != null) return t;
    return _returnType =
        reflectType(_FunctionTypeMirror_return_type(_signatureReflectee));
  }

  List<ParameterMirror>? _parameters;
  List<ParameterMirror> get parameters {
    var p = _parameters;
    if (p != null) return p;
    return _parameters = new UnmodifiableListView<ParameterMirror>(
        _FunctionTypeMirror_parameters(_signatureReflectee)
            .cast<ParameterMirror>());
  }

  bool get isOriginalDeclaration => true;
  ClassMirror get originalDeclaration => this;
  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];
  List<TypeMirror> get typeArguments => const <TypeMirror>[];
  List<InstanceMirror> get metadata => const <InstanceMirror>[];
  SourceLocation? get location => null;

  String toString() => "FunctionTypeMirror on '${_n(simpleName)}'";

  @pragma("vm:external-name", "FunctionTypeMirror_call_method")
  external MethodMirror _FunctionTypeMirror_call_method(signatureReflectee);

  @pragma("vm:external-name", "FunctionTypeMirror_return_type")
  external static Type _FunctionTypeMirror_return_type(signatureReflectee);

  @pragma("vm:external-name", "FunctionTypeMirror_parameters")
  external List<dynamic> _FunctionTypeMirror_parameters(signatureReflectee);
}

abstract class _DeclarationMirror extends Mirror implements DeclarationMirror {
  final _reflectee;
  Symbol _simpleName;

  _DeclarationMirror._(this._reflectee, this._simpleName);

  Symbol get simpleName => _simpleName;

  Symbol? _qualifiedName;
  Symbol get qualifiedName {
    var n = _qualifiedName;
    if (n != null) return n;
    return _qualifiedName = _computeQualifiedName(owner, simpleName);
  }

  bool get isPrivate => _n(simpleName).startsWith('_');

  SourceLocation? get location {
    return _location(_reflectee);
  }

  List<InstanceMirror> get metadata {
    return _wrapMetadata(_metadata(_reflectee));
  }

  bool operator ==(Object other) {
    return other is _DeclarationMirror && this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;
}

class _TypeVariableMirror extends _DeclarationMirror
    implements TypeVariableMirror, _TypeMirror {
  _TypeVariableMirror._(reflectee, String simpleName, this._owner)
      : super._(reflectee, _s(simpleName));

  DeclarationMirror? _owner;
  DeclarationMirror get owner {
    var o = _owner;
    if (o != null) return o;
    return _owner = (_TypeVariableMirror_owner(_reflectee) as TypeMirror)
        .originalDeclaration;
  }

  bool get isStatic => false;
  bool get isTopLevel => false;

  TypeMirror? _upperBound;
  TypeMirror get upperBound {
    var b = _upperBound;
    if (b != null) return b;
    return _upperBound =
        reflectType(_TypeVariableMirror_upper_bound(_reflectee));
  }

  bool get hasReflectedType => false;
  Type get reflectedType {
    throw new UnsupportedError('Type variables have no reflected type');
  }

  Type get _reflectedType => _reflectee;

  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];
  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;

  String toString() => "TypeVariableMirror on '${_n(simpleName)}'";

  bool operator ==(Object other) {
    return other is TypeVariableMirror && simpleName == other.simpleName;
    // Type variables do not refer to owner.
  }

  int get hashCode => simpleName.hashCode;

  bool isSubtypeOf(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return true;
    if (other == currentMirrorSystem().neverType) return false;
    return _subtypeTest(_reflectedType, (other as _TypeMirror)._reflectedType);
  }

  bool isAssignableTo(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return true;
    if (other == currentMirrorSystem().neverType) return false;
    final otherReflectedType = (other as _TypeMirror)._reflectedType;
    return _subtypeTest(_reflectedType, otherReflectedType) ||
        _subtypeTest(otherReflectedType, _reflectedType);
  }

  @pragma("vm:external-name", "TypeVariableMirror_owner")
  external static DeclarationMirror _TypeVariableMirror_owner(reflectee);

  @pragma("vm:external-name", "TypeVariableMirror_upper_bound")
  external static Type _TypeVariableMirror_upper_bound(reflectee);
}

Symbol _asSetter(Symbol getter, LibraryMirror library) {
  var unwrapped = MirrorSystem.getName(getter);
  return MirrorSystem.getSymbol('${unwrapped}=', library);
}

class _LibraryMirror extends _ObjectMirror implements LibraryMirror {
  final Symbol simpleName;
  final Uri uri;

  _LibraryMirror._(reflectee, String simpleName, String url)
      : this.simpleName = _s(simpleName),
        this.uri = Uri.parse(url),
        super._(reflectee);

  // The simple name and the qualified name are the same for a library.
  Symbol get qualifiedName => simpleName;

  DeclarationMirror? get owner => null;

  bool get isPrivate => false;
  bool get isTopLevel => false;

  Type? get _instantiator => null;

  Map<Symbol, DeclarationMirror>? _declarations;
  Map<Symbol, DeclarationMirror> get declarations {
    var d = _declarations;
    if (d != null) return d;

    var decls = new Map<Symbol, DeclarationMirror>();
    var members = _computeMembers(_reflectee);
    for (var member in members) {
      decls[member.simpleName] = member;
    }

    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(decls);
  }

  SourceLocation? get location {
    return _location(_reflectee);
  }

  List<InstanceMirror> get metadata {
    return _wrapMetadata(_metadata(_reflectee));
  }

  bool operator ==(Object other) {
    return other is _LibraryMirror && this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "LibraryMirror on '${_n(simpleName)}'";

  var _cachedLibraryDependencies;
  get libraryDependencies {
    var d = _cachedLibraryDependencies;
    if (d != null) return d;
    return _cachedLibraryDependencies =
        new UnmodifiableListView<LibraryDependencyMirror>(
            _libraryDependencies(_reflectee).cast<LibraryDependencyMirror>());
  }

  @pragma("vm:external-name", "LibraryMirror_libraryDependencies")
  external List<dynamic> _libraryDependencies(reflectee);

  @pragma("vm:external-name", "LibraryMirror_invoke")
  external _invoke(reflectee, memberName, arguments, argumentNames);

  @pragma("vm:external-name", "LibraryMirror_invokeGetter")
  external _invokeGetter(reflectee, getterName);

  @pragma("vm:external-name", "LibraryMirror_invokeSetter")
  external _invokeSetter(reflectee, setterName, value);

  @pragma("vm:external-name", "LibraryMirror_members")
  external List<dynamic> _computeMembers(reflectee);
}

class _LibraryDependencyMirror extends Mirror
    implements LibraryDependencyMirror {
  final LibraryMirror sourceLibrary;
  var _targetMirrorOrPrefix;
  final List<CombinatorMirror> combinators;
  final Symbol? prefix;
  final bool isImport;
  final bool isDeferred;
  final List<InstanceMirror> metadata;

  _LibraryDependencyMirror._(
      this.sourceLibrary,
      this._targetMirrorOrPrefix,
      List<dynamic> mutableCombinators,
      prefixString,
      this.isImport,
      this.isDeferred,
      List<dynamic> unwrappedMetadata)
      : prefix = _sOpt(prefixString),
        combinators = new UnmodifiableListView<CombinatorMirror>(
            mutableCombinators.cast<CombinatorMirror>()),
        metadata = _wrapMetadata(unwrappedMetadata);

  bool get isExport => !isImport;

  LibraryMirror? get targetLibrary {
    if (_targetMirrorOrPrefix is _LibraryMirror) {
      return _targetMirrorOrPrefix;
    }
    var mirrorOrNull = _tryUpgradePrefix(_targetMirrorOrPrefix);
    if (mirrorOrNull != null) {
      _targetMirrorOrPrefix = mirrorOrNull;
    }
    return mirrorOrNull;
  }

  Future<LibraryMirror> loadLibrary() {
    if (_targetMirrorOrPrefix is _LibraryMirror) {
      return new Future.value(_targetMirrorOrPrefix);
    }
    var savedPrefix = _targetMirrorOrPrefix;
    return savedPrefix.loadLibrary().then((_) {
      return _tryUpgradePrefix(savedPrefix);
    });
  }

  @pragma("vm:external-name", "LibraryMirror_fromPrefix")
  external static LibraryMirror _tryUpgradePrefix(libraryPrefix);

  SourceLocation? get location => null;
}

class _CombinatorMirror extends Mirror implements CombinatorMirror {
  final List<Symbol> identifiers;
  final bool isShow;

  _CombinatorMirror._(identifierString, this.isShow)
      : this.identifiers =
            new UnmodifiableListView<Symbol>(<Symbol>[_s(identifierString)]);

  bool get isHide => !isShow;
}

class _MethodMirror extends _DeclarationMirror implements MethodMirror {
  final Type? _instantiator;
  final bool isStatic;
  final int _kindFlags;

  _MethodMirror._(reflectee, String simpleName, this._owner, this._instantiator,
      this.isStatic, this._kindFlags)
      : super._(reflectee, _s(simpleName));

  static const kAbstract = 0;
  static const kGetter = 1;
  static const kSetter = 2;
  static const kConstructor = 3;
  static const kConstCtor = 4;
  static const kGenerativeCtor = 5;
  static const kRedirectingCtor = 6;
  static const kFactoryCtor = 7;
  static const kExternal = 8;
  static const kSynthetic = 9;
  static const kExtensionMember = 10;
  static const kExtensionTypeMember = 11;

  // These offsets much be kept in sync with those in mirrors.h.
  bool get isAbstract => 0 != (_kindFlags & (1 << kAbstract));
  bool get isGetter => 0 != (_kindFlags & (1 << kGetter));
  bool get isSetter => 0 != (_kindFlags & (1 << kSetter));
  bool get isConstructor => 0 != (_kindFlags & (1 << kConstructor));
  bool get isConstConstructor => 0 != (_kindFlags & (1 << kConstCtor));
  bool get isGenerativeConstructor =>
      0 != (_kindFlags & (1 << kGenerativeCtor));
  bool get isRedirectingConstructor =>
      0 != (_kindFlags & (1 << kRedirectingCtor));
  bool get isFactoryConstructor => 0 != (_kindFlags & (1 << kFactoryCtor));
  bool get isExternal => 0 != (_kindFlags & (1 << kExternal));
  bool get isSynthetic => 0 != (_kindFlags & (1 << kSynthetic));
  bool get isExtensionMember => 0 != (_kindFlags & (1 << kExtensionMember));
  bool get isExtensionTypeMember =>
      0 != (_kindFlags & (1 << kExtensionTypeMember));

  static const _operators = const [
    "%", "&", "*", "+", "-", "/", "<", "<<", //
    "<=", "==", ">", ">=", ">>", "[]", "[]=",
    "^", "|", "~", "unary-", "~/",
  ];
  bool get isOperator => _operators.contains(_n(simpleName));

  DeclarationMirror? _owner;
  DeclarationMirror get owner {
    // For nested closures it is possible, that the mirror for the owner has not
    // been created yet.
    var o = _owner;
    if (o != null) return o;
    return _owner = _MethodMirror_owner(_reflectee, _instantiator);
  }

  bool get isPrivate =>
      _n(simpleName).startsWith('_') || _n(constructorName).startsWith('_');

  bool get isTopLevel => owner is LibraryMirror;

  TypeMirror? _returnType;
  TypeMirror get returnType {
    var t = _returnType;
    if (t != null) return t;
    if (isConstructor) {
      return _returnType = owner as _ClassMirror;
    } else {
      return _returnType =
          reflectType(_MethodMirror_return_type(_reflectee, _instantiator));
    }
  }

  List<ParameterMirror>? _parameters;
  List<ParameterMirror> get parameters {
    var p = _parameters;
    if (p != null) return p;
    return _parameters = new UnmodifiableListView<ParameterMirror>(
        _MethodMirror_parameters(_reflectee).cast<ParameterMirror>());
  }

  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  Symbol? _constructorName;
  Symbol get constructorName {
    var n = _constructorName;
    if (n != null) return n;

    if (!isConstructor) {
      return _constructorName = _s('');
    } else {
      var parts = MirrorSystem.getName(simpleName).split('.');
      if (parts.length > 2) {
        throw new _InternalMirrorError(
            'Internal error in MethodMirror.constructorName: '
            'malformed name <$simpleName>');
      } else if (parts.length == 2) {
        LibraryMirror definingLibrary = owner.owner as _LibraryMirror;
        return _constructorName =
            MirrorSystem.getSymbol(parts[1], definingLibrary);
      } else {
        return _constructorName = _s('');
      }
    }
  }

  String? get source => _MethodMirror_source(_reflectee);

  void _patchConstructorName(ownerName) {
    var cn = _n(constructorName);
    if (cn == '') {
      _simpleName = _s(ownerName);
    } else {
      _simpleName = _s(ownerName + "." + cn);
    }
  }

  String toString() => "MethodMirror on '${MirrorSystem.getName(simpleName)}'";

  @pragma("vm:external-name", "MethodMirror_owner")
  external static dynamic _MethodMirror_owner(reflectee, instantiator);

  @pragma("vm:external-name", "MethodMirror_return_type")
  external static dynamic _MethodMirror_return_type(reflectee, instantiator);

  @pragma("vm:external-name", "MethodMirror_parameters")
  external List<dynamic> _MethodMirror_parameters(reflectee);

  @pragma("vm:external-name", "MethodMirror_source")
  external static String? _MethodMirror_source(reflectee);
}

class _VariableMirror extends _DeclarationMirror implements VariableMirror {
  final DeclarationMirror owner;
  final bool isStatic;
  final bool isFinal;
  final bool isConst;
  final bool isExtensionMember;
  final bool isExtensionTypeMember;

  _VariableMirror._(
      reflectee,
      String simpleName,
      this.owner,
      this._type,
      this.isStatic,
      this.isFinal,
      this.isConst,
      this.isExtensionMember,
      this.isExtensionTypeMember)
      : super._(reflectee, _s(simpleName));

  bool get isTopLevel => owner is LibraryMirror;

  Type? get _instantiator {
    final o = owner; // Note: need local variable for promotion to happen.
    if (o is _ClassMirror) {
      return o._instantiator;
    } else if (o is _MethodMirror) {
      return o._instantiator;
    } else if (o is _LibraryMirror) {
      return o._instantiator;
    } else {
      throw new UnsupportedError("unexpected owner ${owner}");
    }
  }

  TypeMirror? _type;
  TypeMirror get type {
    var t = _type;
    if (t != null) return t;
    return _type = reflectType(_VariableMirror_type(_reflectee, _instantiator));
  }

  String toString() =>
      "VariableMirror on '${MirrorSystem.getName(simpleName)}'";

  @pragma("vm:external-name", "VariableMirror_type")
  external static _VariableMirror_type(reflectee, instantiator);
}

class _ParameterMirror extends _VariableMirror implements ParameterMirror {
  final int _position;
  final bool isOptional;
  final bool isNamed;
  final List? _unmirroredMetadata;

  _ParameterMirror._(
      reflectee,
      String simpleName,
      DeclarationMirror owner,
      this._position,
      this.isOptional,
      this.isNamed,
      bool isFinal,
      this._defaultValueReflectee,
      this._unmirroredMetadata)
      : super._(
          reflectee,
          simpleName,
          owner,
          null, // We override the type.
          false, // isStatic does not apply.
          isFinal,
          false, // Not const.
          false, // Not extension member.
          false, // Not extension type member.
        );

  Object? _defaultValueReflectee;
  InstanceMirror? _defaultValue;
  InstanceMirror? get defaultValue {
    if (!isOptional) {
      return null;
    }
    if (_defaultValue == null) {
      _defaultValue = reflect(_defaultValueReflectee);
    }
    return _defaultValue;
  }

  bool get hasDefaultValue => _defaultValueReflectee != null;

  SourceLocation? get location {
    throw new UnsupportedError("ParameterMirror.location unimplemented");
  }

  List<InstanceMirror> get metadata {
    var m = _unmirroredMetadata;
    if (m == null) return const <InstanceMirror>[];
    return _wrapMetadata(m);
  }

  TypeMirror? _type;
  TypeMirror get type {
    var t = _type;
    if (t != null) return t;
    return _type = reflectType(
        _ParameterMirror_type(_reflectee, _position, _instantiator));
  }

  String toString() => "ParameterMirror on '${_n(simpleName)}'";

  @pragma("vm:external-name", "ParameterMirror_type")
  external static Type _ParameterMirror_type(
      _reflectee, _position, instantiator);
}

class _SpecialTypeMirror extends Mirror
    implements TypeMirror, DeclarationMirror {
  final Symbol simpleName;

  _SpecialTypeMirror._(String name) : simpleName = _s(name);

  bool get isPrivate => false;
  bool get isTopLevel => true;

  DeclarationMirror? get owner => null;

  SourceLocation? get location => null;
  List<InstanceMirror> get metadata => const <InstanceMirror>[];

  bool get hasReflectedType => simpleName == #dynamic;
  Type get reflectedType {
    if (simpleName == #dynamic) return dynamic;
    throw new UnsupportedError("void has no reflected type");
  }

  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];
  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;

  Symbol get qualifiedName => simpleName;

  bool operator ==(Object other) {
    if (other is! _SpecialTypeMirror) {
      return false;
    }
    return this.simpleName == other.simpleName;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "TypeMirror on '${_n(simpleName)}'";

  bool isSubtypeOf(TypeMirror other) {
    return simpleName == #dynamic || other is _SpecialTypeMirror;
  }

  bool isAssignableTo(TypeMirror other) {
    return simpleName == #dynamic || other is _SpecialTypeMirror;
  }
}

class _Mirrors {
  static MirrorSystem _currentMirrorSystem = new _MirrorSystem();
  static MirrorSystem currentMirrorSystem() {
    return _currentMirrorSystem;
  }

  // Creates a new local mirror for some Object.
  static InstanceMirror reflect(dynamic reflectee) {
    return reflectee is Function
        ? new _ClosureMirror._(reflectee)
        : new _InstanceMirror._(reflectee);
  }

  @pragma("vm:external-name", "Mirrors_makeLocalClassMirror")
  external static _ClassMirror _makeLocalClassMirror(Type key);
  @pragma("vm:external-name", "Mirrors_makeLocalTypeMirror")
  external static TypeMirror _makeLocalTypeMirror(Type key);
  @pragma("vm:external-name", "Mirrors_instantiateGenericType")
  external static Type _instantiateGenericType(Type key, typeArguments);

  static Expando<_ClassMirror> _declarationCache = new Expando("ClassMirror");
  static Expando<TypeMirror> _instantiationCache = new Expando("TypeMirror");

  static ClassMirror reflectClass(Type key) {
    var classMirror = _declarationCache[key];
    if (classMirror == null) {
      classMirror = _makeLocalClassMirror(key);
      _declarationCache[key] = classMirror;
      if (!classMirror._isGeneric) {
        _instantiationCache[key] = classMirror;
      }
    }
    return classMirror;
  }

  static TypeMirror reflectType(Type key, [List<Type>? typeArguments]) {
    if (typeArguments != null) {
      key = _instantiateType(key, typeArguments);
    }
    var typeMirror = _instantiationCache[key];
    if (typeMirror == null) {
      typeMirror = _makeLocalTypeMirror(key);
      _instantiationCache[key] = typeMirror;
      if (typeMirror is _ClassMirror && !typeMirror._isGeneric) {
        _declarationCache[key] = typeMirror;
      }
    }
    return typeMirror;
  }

  static Type _instantiateType(Type key, List<Type> typeArguments) {
    if (typeArguments.isEmpty) {
      throw new ArgumentError.value(typeArguments, 'typeArguments',
          'Type arguments list cannot be empty.');
    }
    return _instantiateGenericType(key, typeArguments.toList(growable: false));
  }
}
