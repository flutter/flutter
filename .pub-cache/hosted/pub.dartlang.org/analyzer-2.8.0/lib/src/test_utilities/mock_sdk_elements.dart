// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

class MockSdkElements {
  final LibraryElementImpl coreLibrary;
  final LibraryElementImpl asyncLibrary;

  factory MockSdkElements(
    engine.AnalysisContext analysisContext,
    AnalysisSessionImpl analysisSession,
  ) {
    var builder = _MockSdkElementsBuilder(analysisContext, analysisSession);
    var coreLibrary = builder._buildCore();
    var asyncLibrary = builder._buildAsync();
    return MockSdkElements._(coreLibrary, asyncLibrary);
  }

  MockSdkElements._(this.coreLibrary, this.asyncLibrary);
}

class _MockSdkElementsBuilder {
  final engine.AnalysisContext analysisContext;
  final AnalysisSessionImpl analysisSession;

  ClassElementImpl? _boolElement;
  ClassElementImpl? _comparableElement;
  ClassElementImpl? _completerElement;
  ClassElementImpl? _deprecatedElement;
  ClassElementImpl? _doubleElement;
  ClassElementImpl? _functionElement;
  ClassElementImpl? _futureElement;
  ClassElementImpl? _futureOrElement;
  ClassElementImpl? _intElement;
  ClassElementImpl? _iterableElement;
  ClassElementImpl? _iteratorElement;
  ClassElementImpl? _listElement;
  ClassElementImpl? _mapElement;
  ClassElementImpl? _nullElement;
  ClassElementImpl? _numElement;
  ClassElementImpl? _objectElement;
  ClassElementImpl? _overrideElement;
  ClassElementImpl? _proxyElement;
  ClassElementImpl? _setElement;
  ClassElementImpl? _stackTraceElement;
  ClassElementImpl? _streamElement;
  ClassElementImpl? _streamSubscriptionElement;
  ClassElementImpl? _stringElement;
  ClassElementImpl? _symbolElement;
  ClassElementImpl? _typeElement;

  InterfaceType? _boolType;
  InterfaceType? _doubleType;
  InterfaceType? _intType;
  InterfaceType? _numType;
  InterfaceType? _objectType;
  InterfaceType? _stringType;
  InterfaceType? _typeType;

  _MockSdkElementsBuilder(
    this.analysisContext,
    this.analysisSession,
  );

  ClassElementImpl get boolElement {
    var boolElement = _boolElement;
    if (boolElement != null) return boolElement;

    _boolElement = boolElement = _class(name: 'bool');
    boolElement.supertype = objectType;

    boolElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', boolType),
        ],
      ),
    ];

    return boolElement;
  }

  InterfaceType get boolType {
    return _boolType ??= _interfaceType(boolElement);
  }

  ClassElementImpl get comparableElement {
    var comparableElement = _comparableElement;
    if (comparableElement != null) return comparableElement;

    var tElement = _typeParameter('T');
    _comparableElement = comparableElement = _class(
      name: 'Comparable',
      isAbstract: true,
      typeParameters: [tElement],
    );
    comparableElement.supertype = objectType;

    return comparableElement;
  }

  ClassElementImpl get completerElement {
    var completerElement = _completerElement;
    if (completerElement != null) return completerElement;

    var tElement = _typeParameter('T');
    _completerElement = completerElement = _class(
      name: 'Completer',
      isAbstract: true,
      typeParameters: [tElement],
    );
    completerElement.supertype = objectType;

    return completerElement;
  }

  ClassElementImpl get deprecatedElement {
    var deprecatedElement = _deprecatedElement;
    if (deprecatedElement != null) return deprecatedElement;

    _deprecatedElement = deprecatedElement = _class(name: 'Deprecated');
    deprecatedElement.supertype = objectType;

    deprecatedElement.fields = <FieldElement>[
      _field('message', stringType, isFinal: true),
    ];

    deprecatedElement.accessors =
        deprecatedElement.fields.map((f) => f.getter!).toList();

    deprecatedElement.constructors = [
      _constructor(
        isConst: true,
        parameters: [
          _requiredParameter('message', stringType),
        ],
      ),
    ];

    return deprecatedElement;
  }

  ClassElementImpl get doubleElement {
    var doubleElement = _doubleElement;
    if (doubleElement != null) return doubleElement;

    _doubleElement = doubleElement = _class(
      name: 'double',
      isAbstract: true,
    );
    doubleElement.supertype = numType;

    FieldElement staticConstDoubleField(String name) {
      return _field(name, doubleType, isStatic: true, isConst: true);
    }

    doubleElement.fields = <FieldElement>[
      staticConstDoubleField('nan'),
      staticConstDoubleField('infinity'),
      staticConstDoubleField('negativeInfinity'),
      staticConstDoubleField('minPositive'),
      staticConstDoubleField('maxFinite'),
    ];

    doubleElement.accessors =
        doubleElement.fields.map((field) => field.getter!).toList();

    doubleElement.methods = [
      _method('+', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('*', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('%', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('/', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('~/', intType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('abs', doubleType),
      _method('ceil', doubleType),
      _method('floor', doubleType),
      _method('remainder', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('round', doubleType),
      _method('toString', stringType),
      _method('truncate', doubleType),
    ];

    return doubleElement;
  }

  InterfaceType get doubleType {
    return _doubleType ??= _interfaceType(doubleElement);
  }

  DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

  ClassElementImpl get functionElement {
    var functionElement = _functionElement;
    if (functionElement != null) return functionElement;

    _functionElement = functionElement = _class(
      name: 'Function',
      isAbstract: true,
    );
    functionElement.supertype = objectType;

    return functionElement;
  }

  InterfaceType get functionType {
    return _interfaceType(functionElement);
  }

  ClassElementImpl get futureElement {
    var futureElement = _futureElement;
    if (futureElement != null) return futureElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _futureElement = futureElement = _class(
      name: 'Future',
      isAbstract: true,
      typeParameters: [tElement],
    );
    futureElement.supertype = objectType;

    //   factory Future.value([FutureOr<T> value])
    futureElement.constructors = [
      _constructor(
        isFactory: true,
        parameters: [
          _positionalParameter('value', futureOrType(tType)),
        ],
      ),
    ];

    //   Future<R> then<R>(FutureOr<R> onValue(T value), {Function onError})
    var rElement = _typeParameter('R');
    var rType = _typeParameterType(rElement);
    futureElement.methods = [
      _method(
        'then',
        futureType(rType),
        parameters: [
          _requiredParameter(
            'onValue',
            _functionType(
              returnType: futureOrType(rType),
              parameters: [
                _requiredParameter('value', tType),
              ],
            ),
          ),
          _positionalParameter('onError', functionType),
        ],
      ),
    ];

    return futureElement;
  }

  ClassElementImpl get futureOrElement {
    var futureOrElement = _futureOrElement;
    if (futureOrElement != null) return futureOrElement;

    var tElement = _typeParameter('T');
    _futureOrElement = futureOrElement = _class(
      name: 'FutureOr',
      typeParameters: [tElement],
    );
    futureOrElement.supertype = objectType;

    return futureOrElement;
  }

  ClassElementImpl get intElement {
    var intElement = _intElement;
    if (intElement != null) return intElement;

    _intElement = intElement = _class(name: 'int', isAbstract: true);
    intElement.supertype = numType;

    intElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', intType),
        ],
      ),
    ];

    intElement.methods = [
      _method('&', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('|', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('^', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('~', intType),
      _method('<<', intType, parameters: [
        _requiredParameter('shiftAmount', intType),
      ]),
      _method('>>', intType, parameters: [
        _requiredParameter('shiftAmount', intType),
      ]),
      _method('-', intType),
      _method('abs', intType),
      _method('round', intType),
      _method('floor', intType),
      _method('ceil', intType),
      _method('truncate', intType),
      _method('toString', stringType),
    ];

    return intElement;
  }

  InterfaceType get intType {
    return _intType ??= _interfaceType(intElement);
  }

  ClassElementImpl get iterableElement {
    var iterableElement = _iterableElement;
    if (iterableElement != null) return iterableElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iterableElement = iterableElement = _class(
      name: 'Iterable',
      isAbstract: true,
      typeParameters: [eElement],
    );
    iterableElement.supertype = objectType;

    iterableElement.constructors = [
      _constructor(isConst: true),
    ];

    _setAccessors(iterableElement, [
      _getter('iterator', iteratorType(eType)),
      _getter('last', eType),
    ]);

    return iterableElement;
  }

  ClassElementImpl get iteratorElement {
    var iteratorElement = _iteratorElement;
    if (iteratorElement != null) return iteratorElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iteratorElement = iteratorElement = _class(
      name: 'Iterator',
      isAbstract: true,
      typeParameters: [eElement],
    );
    iteratorElement.supertype = objectType;

    _setAccessors(iterableElement, [
      _getter('current', eType),
    ]);

    return iteratorElement;
  }

  ClassElementImpl get listElement {
    var listElement = _listElement;
    if (listElement != null) return listElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _listElement = listElement = _class(
      name: 'List',
      isAbstract: true,
      typeParameters: [eElement],
    );
    listElement.supertype = objectType;
    listElement.interfaces = [
      iterableType(eType),
    ];

    listElement.constructors = [
      _constructor(isFactory: true, parameters: [
        _positionalParameter('length', intType),
      ]),
    ];

    _setAccessors(listElement, [
      _getter('length', intType),
    ]);

    listElement.methods = [
      _method('[]', eType, parameters: [
        _requiredParameter('index', intType),
      ]),
      _method('[]=', voidType, parameters: [
        _requiredParameter('index', intType),
        _requiredParameter('value', eType),
      ]),
      _method('add', voidType, parameters: [
        _requiredParameter('value', eType),
      ]),
    ];

    return listElement;
  }

  ClassElementImpl get mapElement {
    var mapElement = _mapElement;
    if (mapElement != null) return mapElement;

    var kElement = _typeParameter('K');
    var vElement = _typeParameter('V');
    var kType = _typeParameterType(kElement);
    var vType = _typeParameterType(vElement);

    _mapElement = mapElement = _class(
      name: 'Map',
      isAbstract: true,
      typeParameters: [kElement, vElement],
    );
    mapElement.supertype = objectType;

    _setAccessors(mapElement, [
      _getter('length', intType),
    ]);

    mapElement.methods = [
      _method('[]', vType, parameters: [
        _requiredParameter('key', objectType),
      ]),
      _method('[]=', voidType, parameters: [
        _requiredParameter('key', kType),
        _requiredParameter('value', vType),
      ]),
    ];

    return mapElement;
  }

  ClassElementImpl get nullElement {
    var nullElement = _nullElement;
    if (nullElement != null) return nullElement;

    _nullElement = nullElement = _class(name: 'Null');
    nullElement.supertype = objectType;

    nullElement.constructors = [
      _constructor(
        name: '_uninstantiatable',
        isFactory: true,
      ),
    ];

    return nullElement;
  }

  ClassElementImpl get numElement {
    var numElement = _numElement;
    if (numElement != null) return numElement;

    _numElement = numElement = _class(name: 'num', isAbstract: true);
    numElement.supertype = objectType;
    numElement.interfaces = [
      _interfaceType(
        comparableElement,
        typeArguments: [numType],
      ),
    ];

    numElement.methods = [
      _method('+', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('*', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('%', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('/', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('~/', intType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('remainder', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('<', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('<=', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('>', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('>=', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('==', boolType, parameters: [
        _requiredParameter('other', objectType),
      ]),
      _method('abs', numType),
      _method('floor', numType),
      _method('ceil', numType),
      _method('round', numType),
      _method('truncate', numType),
      _method('toInt', intType),
      _method('toDouble', doubleType),
      _method('toStringAsFixed', stringType, parameters: [
        _requiredParameter('fractionDigits', intType),
      ]),
      _method('toStringAsExponential', stringType, parameters: [
        _requiredParameter('fractionDigits', intType),
      ]),
      _method('toStringAsPrecision', stringType, parameters: [
        _requiredParameter('precision', intType),
      ]),
    ];

    _setAccessors(numElement, [
      _getter('isInfinite', boolType),
      _getter('isNaN', boolType),
      _getter('isNegative', boolType),
    ]);

    return numElement;
  }

  InterfaceType get numType {
    return _numType ??= _interfaceType(numElement);
  }

  ClassElementImpl get objectElement {
    var objectElement = _objectElement;
    if (objectElement != null) return objectElement;

    _objectElement = objectElement = ElementFactory.object;
    objectElement.interfaces = const <InterfaceType>[];
    objectElement.mixins = const <InterfaceType>[];
    objectElement.typeParameters = const <TypeParameterElement>[];
    objectElement.constructors = [
      _constructor(isConst: true),
    ];

    objectElement.methods = [
      _method('toString', stringType),
      _method('==', boolType, parameters: [
        _requiredParameter('other', objectType),
      ]),
      _method('noSuchMethod', dynamicType, parameters: [
        _requiredParameter('other', dynamicType),
      ]),
    ];

    _setAccessors(objectElement, [
      _getter('hashCode', intType),
      _getter('runtimeType', typeType),
    ]);

    return objectElement;
  }

  InterfaceType get objectType {
    return _objectType ??= _interfaceType(objectElement);
  }

  ClassElementImpl get overrideElement {
    var overrideElement = _overrideElement;
    if (overrideElement != null) return overrideElement;

    _overrideElement = overrideElement = _class(name: '_Override');
    overrideElement.supertype = objectType;

    overrideElement.constructors = [
      _constructor(isConst: true),
    ];

    return overrideElement;
  }

  ClassElementImpl get proxyElement {
    var proxyElement = _proxyElement;
    if (proxyElement != null) return proxyElement;

    _proxyElement = proxyElement = _class(name: '_Proxy');
    proxyElement.supertype = objectType;

    proxyElement.constructors = [
      _constructor(isConst: true),
    ];

    return proxyElement;
  }

  ClassElementImpl get setElement {
    var setElement = _setElement;
    if (setElement != null) return setElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _setElement = setElement = _class(
      name: 'Set',
      isAbstract: true,
      typeParameters: [eElement],
    );
    setElement.supertype = objectType;
    setElement.interfaces = [
      iterableType(eType),
    ];

    return setElement;
  }

  ClassElementImpl get stackTraceElement {
    var stackTraceElement = _stackTraceElement;
    if (stackTraceElement != null) return stackTraceElement;

    _stackTraceElement = stackTraceElement = _class(
      name: 'StackTrace',
      isAbstract: true,
    );
    stackTraceElement.supertype = objectType;

    return stackTraceElement;
  }

  ClassElementImpl get streamElement {
    var streamElement = _streamElement;
    if (streamElement != null) return streamElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _streamElement = streamElement = _class(
      name: 'Stream',
      isAbstract: true,
      typeParameters: [tElement],
    );
    streamElement.isAbstract = true;
    streamElement.supertype = objectType;

    //    StreamSubscription<T> listen(void onData(T event),
    //        {Function onError, void onDone(), bool cancelOnError});
    streamElement.methods = [
      _method(
        'listen',
        streamSubscriptionType(tType),
        parameters: [
          _requiredParameter(
            'onData',
            _functionType(
              returnType: voidType,
              parameters: [
                _requiredParameter('event', tType),
              ],
            ),
          ),
          _namedParameter('onError', functionType),
          _namedParameter(
            'onDone',
            _functionType(returnType: voidType),
          ),
          _namedParameter('cancelOnError', boolType),
        ],
      ),
    ];

    return streamElement;
  }

  ClassElementImpl get streamSubscriptionElement {
    var streamSubscriptionElement = _streamSubscriptionElement;
    if (streamSubscriptionElement != null) return streamSubscriptionElement;

    var tElement = _typeParameter('T');
    _streamSubscriptionElement = streamSubscriptionElement = _class(
      name: 'StreamSubscription',
      isAbstract: true,
      typeParameters: [tElement],
    );
    streamSubscriptionElement.supertype = objectType;

    return streamSubscriptionElement;
  }

  ClassElementImpl get stringElement {
    var stringElement = _stringElement;
    if (stringElement != null) return stringElement;

    _stringElement = stringElement = _class(
      name: 'String',
      isAbstract: true,
    );
    stringElement.supertype = objectType;

    stringElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', stringType),
        ],
      ),
    ];

    _setAccessors(stringElement, [
      _getter('isEmpty', boolType),
      _getter('length', intType),
      _getter('codeUnits', listType(intType)),
    ]);

    stringElement.methods = [
      _method('+', stringType, parameters: [
        _requiredParameter('other', stringType),
      ]),
      _method('toLowerCase', stringType),
      _method('toUpperCase', stringType),
    ];

    return stringElement;
  }

  InterfaceType get stringType {
    return _stringType ??= _interfaceType(stringElement);
  }

  ClassElementImpl get symbolElement {
    var symbolElement = _symbolElement;
    if (symbolElement != null) return symbolElement;

    _symbolElement = symbolElement = _class(
      name: 'Symbol',
      isAbstract: true,
    );
    symbolElement.supertype = objectType;

    symbolElement.constructors = [
      _constructor(
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
        ],
      ),
    ];

    return symbolElement;
  }

  ClassElementImpl get typeElement {
    var typeElement = _typeElement;
    if (typeElement != null) return typeElement;

    _typeElement = typeElement = _class(
      name: 'Type',
      isAbstract: true,
    );
    typeElement.supertype = objectType;

    return typeElement;
  }

  InterfaceType get typeType {
    return _typeType ??= _interfaceType(typeElement);
  }

  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  InterfaceType futureOrType(DartType elementType) {
    return _interfaceType(
      futureOrElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType futureType(DartType elementType) {
    return _interfaceType(
      futureElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType iterableType(DartType elementType) {
    return _interfaceType(
      iterableElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType iteratorType(DartType elementType) {
    return _interfaceType(
      iteratorElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType listType(DartType elementType) {
    return _interfaceType(
      listElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType streamSubscriptionType(DartType valueType) {
    return _interfaceType(
      streamSubscriptionElement,
      typeArguments: [valueType],
    );
  }

  LibraryElementImpl _buildAsync() {
    var asyncLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.async',
      0,
      0,
      FeatureSet.latestLanguageVersion(),
    );

    var asyncUnit = CompilationUnitElementImpl();
    var asyncSource = analysisContext.sourceFactory.forUri('dart:async')!;
    asyncUnit.librarySource = asyncUnit.source = asyncSource;
    asyncLibrary.definingCompilationUnit = asyncUnit;

    asyncUnit.classes = <ClassElement>[
      completerElement,
      futureElement,
      futureOrElement,
      streamElement,
      streamSubscriptionElement
    ];

    return asyncLibrary;
  }

  LibraryElementImpl _buildCore() {
    var coreUnit = CompilationUnitElementImpl();

    var coreSource = analysisContext.sourceFactory.forUri('dart:core')!;
    coreUnit.librarySource = coreUnit.source = coreSource;

    coreUnit.classes = <ClassElement>[
      boolElement,
      comparableElement,
      deprecatedElement,
      doubleElement,
      functionElement,
      intElement,
      iterableElement,
      iteratorElement,
      listElement,
      mapElement,
      nullElement,
      numElement,
      objectElement,
      overrideElement,
      proxyElement,
      setElement,
      stackTraceElement,
      stringElement,
      symbolElement,
      typeElement,
    ];

    coreUnit.functions = <FunctionElement>[
      _function('identical', boolType, parameters: [
        _requiredParameter('a', objectType),
        _requiredParameter('b', objectType),
      ]),
      _function('print', voidType, parameters: [
        _requiredParameter('object', objectType),
      ]),
    ];

    var deprecatedVariable = _topLevelVariable(
      'deprecated',
      _interfaceType(deprecatedElement),
      isConst: true,
    );

    var overrideVariable = _topLevelVariable(
      'override',
      _interfaceType(overrideElement),
      isConst: true,
    );

    var proxyVariable = _topLevelVariable(
      'proxy',
      _interfaceType(proxyElement),
      isConst: true,
    );

    coreUnit.accessors = <PropertyAccessorElement>[
      deprecatedVariable.getter!,
      overrideVariable.getter!,
      proxyVariable.getter!,
    ];
    coreUnit.topLevelVariables = <TopLevelVariableElement>[
      deprecatedVariable,
      overrideVariable,
      proxyVariable,
    ];

    var coreLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.core',
      0,
      0,
      FeatureSet.latestLanguageVersion(),
    );
    coreLibrary.definingCompilationUnit = coreUnit;

    return coreLibrary;
  }

  ClassElementImpl _class({
    required String name,
    bool isAbstract = false,
    List<TypeParameterElement> typeParameters = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.constructors = <ConstructorElement>[
      _constructor(),
    ];
    return element;
  }

  ConstructorElement _constructor({
    String name = '',
    bool isConst = false,
    bool isFactory = false,
    List<ParameterElement> parameters = const [],
  }) {
    var element = ConstructorElementImpl(name, 0);
    element.isFactory = isFactory;
    element.isConst = isConst;
    element.parameters = parameters;
    return element;
  }

  FieldElement _field(
    String name,
    DartType type, {
    bool isConst = false,
    bool isFinal = false,
    bool isStatic = false,
  }) {
    return ElementFactory.fieldElement(name, isStatic, isFinal, isConst, type);
  }

  FunctionElement _function(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return FunctionElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
  }

  FunctionType _functionType({
    required DartType returnType,
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  PropertyAccessorElement _getter(
    String name,
    DartType type, {
    bool isStatic = false,
  }) {
    var field = FieldElementImpl(name, -1);
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;

    var getter = PropertyAccessorElementImpl(name, 0);
    getter.isGetter = true;
    getter.isStatic = isStatic;
    getter.isSynthetic = false;
    getter.returnType = type;
    getter.variable = field;

    field.getter = getter;
    return getter;
  }

  InterfaceType _interfaceType(
    ClassElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  MethodElement _method(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return MethodElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
  }

  ParameterElement _namedParameter(String name, DartType type,
      {String? initializerCode}) {
    var parameter = DefaultParameterElementImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.NAMED,
    );
    parameter.type = type;
    parameter.defaultValueCode = initializerCode;
    return parameter;
  }

  ParameterElement _positionalParameter(String name, DartType type) {
    var parameter = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.POSITIONAL,
    );
    parameter.type = type;
    return parameter;
  }

  ParameterElement _requiredParameter(String name, DartType type) {
    var parameter = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.REQUIRED,
    );
    parameter.type = type;
    return parameter;
  }

  /// Set the [accessors] and the corresponding fields for the [classElement].
  void _setAccessors(
    ClassElementImpl classElement,
    List<PropertyAccessorElement> accessors,
  ) {
    classElement.accessors = accessors;
    classElement.fields = accessors
        .map((accessor) => accessor.variable)
        .cast<FieldElement>()
        .toList();
  }

  TopLevelVariableElement _topLevelVariable(
    String name,
    DartType type, {
    bool isConst = false,
    bool isFinal = false,
  }) {
    return ElementFactory.topLevelVariableElement3(
        name, isConst, isFinal, type);
  }

  TypeParameterElementImpl _typeParameter(String name) {
    return TypeParameterElementImpl(name, 0);
  }

  TypeParameterType _typeParameterType(TypeParameterElement element) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
