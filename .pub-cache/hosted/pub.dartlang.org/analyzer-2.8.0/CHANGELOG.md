## 2.8.0
* Deprecations and renames for `getXyz` methods in `AnalysisDriver`.
* Removed uppercase named constants from `double` in mock SDK.
* Deprecated `path` and `uri` from `AnalysisResult`.
* Deprecated `UriResolver.restoreAbsolute`, use `pathToUri` instead.
* Deprecated `SourceFactory.restoreAbsolute`, use `pathToUri` instead.
* Deprecated `UriKind` and `Source.uriKind`.
* Deprecated `Source.modificationStamp`.
* Deprecated `Source.isInSystemLibrary`, use `uri.isScheme('dart')` instead.
* Fixed #47715.

## 2.7.0
* Updated `ConstructorElement.displayName` to either `Class` or `Class.constructor`.
* Deprecated `InterfaceType.getSmartLeastUpperBound`, use `TypeSystem.leastUpperBound` instead.
* Deprecated `MockSdk`, use `createMockSdk` and `FolderBasedDartSdk` instead.

## 2.6.0
* Deprecated `AnalysisResult.state`, check for specific valid or invalid subtypes.
* Deprecated `ResultState`.
* Deprecated `LibraryElement.hasExtUri`, FFI should be used instead.

## 2.5.0
* Updated `MockSdk` to include more declarations.

## 2.4.0
* Deprecated `ResourceProvider.getModificationTimes()`.
* Deprecated `MemoryResourceProvider.newDummyLink()`.
* Deprecated `MemoryResourceProvider.updateFile()`.
* Deprecated `TypeName`, use `NamedType` instead.
* Override `AstVisitor.visitNamedType()` instead of `visitTypeName()`.
* Deprecated `ClassTypeAlias.superclass`, use `superclass2` instead.
* Deprecated `ConstructorName.type`, use `type2` instead.
* Deprecated `ExtendsClause.superclass`, use `superclass2` instead.
* Deprecated `ImplementsClause.interfaces`, use `interfaces2` instead.
* Deprecated `OnClause.superclassConstraints`, use `superclassConstraints2` instead.
* Deprecated `TypeLiteral.typeName`, use `type` instead.
* Deprecated `WithClause.mixinTypes`, use `mixinTypes2` instead.
* Deprecated `AstFactory.typeName()`, use `namedType()` instead.

## 2.3.0
* Enable `constructor-tearoffs` feature by default in `2.15`.
* Improvements in constructors tear-off implementation.

## 2.2.0
* Improvements in constructors tear-off implementation.

## 2.1.0
* Changed `AnalysisResult.path` to be non-nullable.
* Changed `ParsedLibraryResult.units` to be non-nullable.
* Changed `ResolvedLibraryResult.element` to be non-nullable.
* Changed `ResolvedLibraryResult.units` to be non-nullable.
* Changed `ResolvedUnitResult.content` to be non-nullable.
* Changed `ResolvedUnitResult.unit` to be non-nullable.
* Deprecated and renamed `AnalysisSession.getXyz2()` into `getXyz()`.
* Changed `AnalysisDriver.results` to `Stream<Object>`.
  It used to always produce `ResolvedUnitResult`s, but sometimes its
  `content` and `unit` were `null`, when the result actually had only errors.
  Now it produces either `ResolvedUnitResult`, or `ErrorsResult`, or
  some other results that might be added in the future.
* Added `DartType.alias` with information about instantiated type alias.
  The type alias element and arguments are present or absent together.
* Deprecated `DartType.aliasElement` and `DartType.aliasArguments`.
* Updated the current language version to `2.15`.

## 2.0.0
* Removed deprecated `Scope.lookup2()`.
* Removed deprecated setters in API of AST.
* Removed deprecated `FunctionTypeAliasElement`.
* Updated `LineInfo.getLocation()` to return `CharacterLocation`.
* Removed deprecated `LineInfo_Location`.
* Removed deprecated methods from `AnalysisSession`.
* Changed `DartObject.type` from `ParameterizedType?` to `DartType?`.
* Changed `FunctionType` to implement `DartType`, not `ParameterizedType`.
* Removed `FunctionType.element` and `FunctionType.typeArguments`.
* Changed `DartObject.type` from `ParameterizedType?` to `DartType?`.
* Changed `FunctionType` to implement `DartType`, not `ParameterizedType`.
* Removed `FunctionType.element` and `FunctionType.typeArguments`.
* Added `StringInterpolation.firstString` and `lastString`, to express
  explicitly  that there are always (possibly empty) strings as the first
  and the last elements of an interpolation.
* Deprecated `ImportElement.prefixOffset`, use `prefix.nameOffset` instead.
* Deprecated `CompilationUnitElement.types`, use `classes` instead.
* Added `Element.nonSynthetic`, use it to get the element that caused creation
  of this element, e.g. the field for a synthetic getter.
* `FieldElement.isFinal` is `true` only when the field is not synthetic.
* Synthetic getters and setters now use `-1` as `nameOffset`.
* Fixed bug that `defaultValueCode` is `null` for field formal parameters.
* Updated `LibraryElement.name` so that it is non-nullable.

## 1.7.0
* Require `meta: ^1.4.0`.

## 1.6.0
* Deprecated `AnalysisDriver` default constructor.  Added `tmp1`. The goal
  is to allow deprecating and removing unused  parameters.
* Added AST structures and visit methods to support the upcoming "constructor
  tearoffs" feature: `ConstructorReference`, `FunctionReference`, and
  `TypeLiteral`.

## 1.5.0
* Support for the language version `2.14`.
* Deprecated `AnalysisSession.getUnitElement()`.
  Use `AnalysisSession.getUnitElement2()` instead.
* Deprecated `AnalysisSession.getResolvedUnit()`.
  Use `AnalysisSession.getResolvedUnit2()` instead.
* Deprecated `AnalysisSession.getResolvedLibrary()`.
  Use `AnalysisSession.getResolvedLibrary2()` instead.
* Deprecated `AnalysisSession.getResolvedLibraryByElement()`.
  Use `AnalysisSession.getResolvedLibraryByElement2()` instead.
* Deprecated `AnalysisSession.getLibraryByUri()`.
  Use `AnalysisSession.getLibraryByUri2()` instead.
* Deprecated `AnalysisSession.getErrors()`.
  Use `AnalysisSession.getErrors2()` instead.
* Deprecated `AnalysisSession.getParsedLibrary()`.
  Use `AnalysisSession.getParsedLibrary2()` instead.
* Deprecated `AnalysisSession.getParsedLibraryByElement()`.
  Use `AnalysisSession.getParsedLibraryByElement2()` instead.
* Deprecated `AnalysisSession.getParsedUnit()`.
  Use `AnalysisSession.getParsedUnit2()` instead.
* Deprecated `AnalysisSession.getFile()` and `getSourceKind()`.
  Use `AnalysisSession.getFile2()` instead.
* Deprecated `AnalysisSession.getUnitElementSignature()`.
  This method is not used by any known client, and will be removed.

## 1.4.0
* Deprecated `TypeProvider.nonSubtypableClasses`.
  Use `TypeProvider.isNonSubtypableClass` instead.
* Added `sdkPath` to `AnalysisContextCollection` constructor.
* Improved support for generalized type aliases.
* The feature `nonfunction-type-aliases` is enabled by default in the
  language version `2.13`.

## 1.3.0
* Added `Expression.inConstantContext` to API.
* Updated documentation comments for some getters that don't return `null`.
* Fixed an issue with accessing `CompilationUnitElement.mixins` before `types`.
* Implemented metadata resolution with type arguments and inference.
* Fixed issue with metadata on enum constants.

## 1.2.0
* Deprecated all setters in API of AST. Use `parseString()` instead.
* `AnalysisSession.getErrors()` does not return `null`, check its `state`.
* Support for `aliasElement` and `aliasArguments` for aliases of
  `InterfaceType`s and `TypeParameterType`s.

## 1.1.0
* Deprecated `TypeProvider.futureType2()`, `iterableType2()`, etc.
  Use corresponding `TypeProvider.futureType()`, `iterableType()`, etc.
* Remove experimental markers from Null Safety APIs.
* Added `Resource.parent2` and deprecated `Resource.parent`.
* Added `Folder.isRoot`.
* Added `FolderExtension` with `withAncestors`.
* Added `ContextRoot.workspace`, deprecated `AnalysisContext.workspace`.
* Deprecated `ElementVisitor.visitFunctionTypeAliasElement()`.
  Override `ElementVisitor.visitTypeAliasElement()` instead.
* Deprecated `FunctionTypeAliasElement`. Use `TypeAliasElement` instead.

## 1.0.0
* Stable null safety release.
* Updated dependencies to null safe releases.

## 0.42.0-nullsafety.0
* Migrated to null safety, min SDK is `2.12.0`.
* Deprecated `FunctionTypeAliasElement.function`.
  Use `TypeAliasElement.aliasedElement` instead.
* Widened the dependency on package:crypto to include version 3.0.0.
* Deprecated `CompilationUnitElement.functionTypeAliases`.
  Use `CompilationUnitElement.typeAliases` instead.
* Added `AnalysisContext.sdkRoot`.
* Removed `NullSafetyUnderstandingFlag`.
* Removed `functionTypeAliasElement` from `TypeSystem.instantiateToBounds2`.
* Added `Annotation.typeArguments` in preparation for supporting #44838.
* Removed `actualUri` from `UriResolver.resolveAbsolute`.
* Deprecated `FunctionType.element` and `FunctionType.typeArguments`.

## 0.41.1
* Updated `PackageBuildWorkspace` that supports `package:build` to stop
  at the first directory with `pubspec.yaml`, and don't try to go up
  and find another one with both `pubspec.yaml` and `.dart_tool/build`.
* Added a new constructor for non-API `ErrorCode` class. It will be used to
  migrate existing `ErrorCode` subclasses, and then deprecated and removed.

## 0.41.0
* Replaced `Scope.lookup({id, setter})` with `lookup(id)`.
* Deprecated `Scope.lookup2(id)`, use `lookup()` instead.
* Removed deprecated `Member.baseElement`.
* Removed deprecated `package:analyzer/analyzer.dart` library.
* Removed deprecated `ElementAnnotation.constantValue`.
* Removed deprecated `VariableElement.constantValue`.
* Removed deprecated `VariableElement.initializer`.
* Removed deprecated `auxiliaryElements`.
* The value of`FunctionType.element` for types created from a `typedef`
  is now `FunctionTypeAliasElement`, not its function element.
* Removed deprecated `GenericTypeAliasElement`.
* Removed `PhysicalResourceProvider.NORMALIZE_EOL_ALWAYS`.
* Changed the default `PhysicalResourceProvider` constructor to no longer take a
  required positional parameter (removed the existing `fileReadMode` positional
  parameter).

## 0.40.6
* The non_nullable feature is released in 2.12 language version.
* Updated the current language version to 2.12.
* Changed the default language version when the package does not specify one.
  Instead of the latest known language version, the language version of the
  SDK (against which analysis is done, not necessary the same as used to run
  the analyzer) is used.

## 0.40.5
* Deprecated `GenericTypeAliasElement`. Use `FunctionTypeAliasElement`.
* Read imports, exports, and parts on demand in `AnalysisDriver`.
  Specifically, `parseFileSync` will not read any referenced files.
* Types are not set anymore for classes/constructors/getters of
  identifiers in metadata (still set in arguments).

## 0.40.4
* Deprecated `IndexExpression.auxiliaryElements` and
  `SimpleIdentifier.auxiliaryElements`. Use `CompoundAssignmentExpression`.
* Removed internal `getReadType`, use `CompoundAssignmentExpression`.
* Bug fixes: 34699, 43524, 42990.

## 0.40.3
* Updated the current language version to `2.11`.
* Bug fixes: 43541, 27896, 28066, 28066, 43497, 43478, 28066, 43465,
  43462, 43439, 43162, 43397, 43200.

## 0.40.2
* Require `meta: ^1.2.3`.

## 0.40.1
* Added `LocalVariableElement.hasInitializer`,
  `PropertyInducingElement.hasInitializer`, `ParameterElement.hasDefaultValue`.
* `ElementImpl.toString()` uses `getDisplayString(withNullability: true)`.
* Deprecated `ElementAnnotation.constantValue`, it does not guarantee that
  the value has been computed. Use `computeConstantValue()` instead.
* Added `CompoundAssignmentExpression` with read/write element/type getters.
  This interface is implemented by `AssignmentExpression`, `PostfixExpression`
  and `PrefixExpression`. Use it instead of `staticElement` and `staticType`
  of the left-hand side expressions (target expressions in case of postfix
  or prefix expressions with increment operator).
* Changes to the way experiments are handled, and SDK version.
* Bug fixes: 43268, 43214, 39642, 42379, 42629, 43168, 43144, 43100,
  43032, 43073.

## 0.40.0
* Added `LibraryElement.featureSet`.
* Removed deprecated `EmbedderSdk` and related classes.
* `FunctionType` returned from `ExecutableElement.type` return `null`
   as its `element`. Use `ExecutableElement`s directly if necessary.
* `FunctionTypeAliasElement` does not implement `FunctionTypedElement`
   anymore, implements `TypeParameterizedElement` instead.
* Removed deprecated `CustomUriResolver`.
* Removed deprecated `ExplicitSourceResolver`, `FileUriResolver`,
  `LocalSourcePredicate`, `PackageUriResolver`, `RelativeFileUriResolver`.
* Removed deprecated `ErrorCode` instances.
* The `withNullability` flag in `DartType.getDisplayString()` is now required.
* Removed deprecated `DartType.substitute2`, and `FunctionType.substitute3`,
  use `ClassElement.instantiate`, `FunctionTypeAliasElement.instantiate()`,
  or `FunctionType.instantiate()`.
* Removed deprecated `FunctionType.boundTypeParameters`, use `typeFormals`
  for now. Later, it will be deprecated, and replaced with `typeParameters`.
* Removed `InterfaceType.instantiate()`, `InterfaceType.substitute4`,
  use `ClassElement.instantiate()`.
* Removed `typeParameters` and `instantiate()` from `ParameterizedType`.
  Use `typeParameters` and `instantiate()` from `ClassElement`.
* Removed deprecated methods from `DeclaredVariables`.
* Removed deprecated `typeProvider` and `typeSystem` getters.
  Use corresponding `LibraryElement` getters instead.
* Removed deprecated options from `AnalysisOptions`.
* Removed deprecated `ClassElement.hasReferenceToSuper`.
* Removed deprecated `DartType.isObject`.
  Use `DartType.isDartCoreObject` instead.
* Removed deprecated declarations in `AnalysisContext` and `ContextLocator`.
* Removed deprecated libraries.
* Removed deprecated declarations from TypeProvider.
* Removed deprecated `ParseResult` and `ResolveResult`.
* Removed deprecated `AnalysisContext.typeProvider` and `typeSystem`.
  Use the corresponding getters of `LibraryElement`.
* Removed deprecated methods of `AnalysisSession`.
* Removed deprecated declarations from `dart/ast/ast.dart`.
* Removed deprecated methods from `AstFactory`.
* Removed deprecated `parseFile2`..
* Removed deprecated `TypeDefiningElement.type`.
* Features in `Feature` are not constants anymore.
* Replaced `Feature.firstSupportedVersion` with `releaseVersion`.

## 0.39.17
* Depend on cli_util 0.2.0.

## 0.39.16
* Added `TypeVisitorWithArgument` and `DartType.acceptWithArgument`.
* Bumped the analyzer's SDK requirement to `>=2.7.0`, so that extension methods
  can be used within the analyzer implementation. Previously it was `2.6.0`,
  but there is an [issue](https://github.com/dart-lang/sdk/issues/42888).

## 0.39.15
* Move `asInstanceOf(ClassElement)` to `DartType`, so that it is also
  supported for `TypeParameterType` when its bound implements the
  requested interface.
* Fixed invalid implicit downcast in `InterfaceType.allSupertypes`.
* The internal `currentVersion` of the language updated to `2.10`.
* Bug fixes: 41065, 42797, 42770, 42668.

## 0.39.14
* Removed `defaultSdkDirectory()` and `getSdkProperty()` from internal
  `FolderBasedDartSdk`. It is up to the clients to decide how to
  find SDK, for example using `package:cli_util`.
* Fixed `LintDriver` for the new way to access `WorkspacePackage`.
* Deprecated `Scope.lookup()`, use `Scope.lookup2()` instead.
* Updated implementations of `ContextBuilder.createContext()` and
  `ContextLocator.locateContexts` to use the current SDK if `sdkPath`
  is not provided.
* Bug fixes: #41981, #29731, #42720, #33545, #42599, #42699.

## 0.39.13
* Added 'dart/sdk/build_sdk_summary.dart' with `buildSdkSummary`.
* Added `DynamicType`, `NeverType`, and `VoidType` interfaces.
* Added `TypeVisitor` and `DartType.accept(TypeVisitor)`.
* Changed `ConstructorElement.returnType` to `InterfaceType`.
* Added `InterfaceType.allSupertypes`.
* Added `InterfaceType.asInstanceOf(ClassElement)`.
* Removed deprecated internal `bogus-disabled` and `bogus-enabled`.
* Added `Scope`, `LibraryElement.scope`, and `PrefixElement.scope`.
* Bug fixes: #32192, #42620, #42256, #42605.

## 0.39.12
* Deprecated `canUseSummaries` in `DartSdkManager` constructor.
  Summaries are not supported this way for SDK.
* Set uri for implicit dart:core import.
* Add overrideKnownFeaturesAsync() for DartDoc testing.
* Remove DartSdk.useSummary.
* Move TypeSystemImpl to src/dart/element/type_system.dart

## 0.39.11
* Deprecated `ClassElement.hasReferenceToSuper`.
  It was used internally, should not be part of API.
* Deprecated `LibraryElement.languageVersionMajor/minor`.
  Use `LibraryElement.languageVersion` to access more specific information.
* Bug fixes: #42007, #42474, #37293, #42385, #36315, #42356, #42274, #42321,
  #42337, #27387, #34806, #37810, #41072, #42278, #38306, #35036, #23353,
  #42178, #42216, #42201.

## 0.39.10
* Restored the default constructor in internal `SummaryBuilder`,
  and the `featureSet` named parameter in `build`, for `build_resolvers`
  compatibility.  See #42163.

## 0.39.9
* Deprecated `DartType.isObject`, use `DartType.isDartCoreObject` for
  consistency with other similar getters.
* Deprecated `InstanceCreationExpression.staticElement`, use
  `constructorName.staticElement` instead, like for `MethodInvocation`.
* Added new error code: REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR.
* Bug fixes: #34370, #35710, #37552, #38676, #38799, #39644, #41151, #41592,
  #41614, #41724, #41741, #41797, #41803, #41844, #41997, #42077, #42093,
  and #42122.

## 0.39.8
* Deprecated `VariableElement.constantValue`, it does not guarantee that
  the value has been computed. Use `computeConstantValue()` instead.
* Deprecated the following members of `AnalysisOptions`:
  `analyzeFunctionBodiesPredicate`, `disableCacheFlushing`,
  `enableLazyAssignmentOperators`, `generateImplicitErrors`,
  `generateSdkErrors`, `patchPaths`, `preserveComments`,
  `trackCacheDependencies`, and `resetToDefaults`.
* Bug fixes: #35716, #37048, #40014, #40957, #41479, #41521, #41551, #41555,
  #41557, #41593, #41603, #41630, #41632, #41645.

## 0.39.7
* Added new error codes: ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING and
  THROW_OF_INVALID_TYPE.
* Changed error code NULLABLE_TYPE_IN_CATCH_CLAUSE to a hint.
* Bug fixes: #40554, #41378, #41399, #41412, and #41470.

## 0.39.6
* Added Window and DocumentFragment to analyzer's mock SDK.  These are required
  for upcoming changes to the unsafe_html lint.

## 0.39.5
* Deprecated `ClassElement.instantiateToBounds()` and
  `FunctionTypeAliasElement.instantiateToBounds()`. With the null-safety
  feature, type arguments derived from type parameter bounds cannot be used as
  is, and might require erasing nullability, when the element is instantiated
  from a legacy library. Use `TypeSystem.instantiateToBounds2()` instead.
* Deprecated `DeclaredVariables.getBool/getInt/getString()` and
  `TypeProvider.nullObject`. These methods are used internally for constants
  computation, and should not be used by clients.
* Deprecated `AstFactory.indexExpressionForCascade()`.  Please use
  `indexExpressionForCascade2` instead.
* Deprecated `AstFactory.indexExpressionForTarget()`.  Please use
  `indexExpressionForTarget2` instead.
* Deprecated `ClassElement.isOrInheritsProxy` and `ClassElement.isProxy`.  The
  `@proxy` annotation is deprecated in the langauge, and will be removed.
* Added new error codes: BODY_MIGHT_COMPLETE_NORMALLY,
  CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
  DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE, LATE_FINAL_LOCAL_ALREADY_ASSIGNED,
  SWITCH_CASE_COMPLETES_NORMALLY, EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER,
  FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER, GETTER_CONSTRUCTOR,
  MEMBER_WITH_CLASS_NAME, SETTER_CONSTRUCTOR, TYPE_PARAMETER_ON_OPERATOR, and
  VOID_WITH_TYPE_ARGUMENTS.
* Renamed error code DEFAULT_LIST_CONSTRUCTOR_MISMATCH to
  DEFAULT_LIST_CONSTRUCTOR.  This reflects a spec change: after null safety is
  enabled, it will be an error to call the default `List` constructor under all
  circumstances.
* Added new warning code: INVALID_NULL_AWARE_OPERATOR.
* Renamed warning code DEAD_NULL_COALESCE to DEAD_NULL_AWARE_EXPRESSION, to
  reflect the fact that it applies both to if-null expressions (`??`) and
  if-null compound assignment expressions (`??=`).
* Split warning code MISMATCHED_GETTER_AND_SETTER_TYPES into two codes:
  GETTER_NOT_ASSIGNABLE_SETTER_TYPES and GETTER_NOT_SUBTYPE_SETTER_TYPES.
* Coalesced warning codes UNNECESSARY_NULL_AWARE_CALL and
  UNNECESSARY_NULL_AWARE_SPREAD into one warning code:
  INVALID_NULL_AWARE_OPERATOR.
* Added new hint codes: EQUAL_ELEMENTS_IN_SET, EQUAL_KEYS_IN_MAP,
  INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION, UNNECESSARY_NULL_COMPARISON_FALSE,
  and UNNECESSARY_NULL_COMPARISON_TRUE.
* Downgraded warning INVALID_USE_OF_NEVER_VALUE to hint RECEIVER_OF_TYPE_NEVER.
* Re-introduced strong mode codes: DYNAMIC_INVOKE, IMPLICIT_DYNAMIC_FIELD,
  IMPLICIT_DYNAMIC_FUNCTION, IMPLICIT_DYNAMIC_INVOKE,
  IMPLICIT_DYNAMIC_LIST_LITERAL, IMPLICIT_DYNAMIC_MAP_LITERAL,
  IMPLICIT_DYNAMIC_METHOD, IMPLICIT_DYNAMIC_PARAMETER, IMPLICIT_DYNAMIC_RETURN,
  IMPLICIT_DYNAMIC_TYPE, and IMPLICIT_DYNAMIC_VARIABLE.  These were removed in
  version 0.39.3, but it turns out they are actually needed (see
  https://github.com/dart-lang/sdk/issues/40129).
* Fixed bugs 35940, 37122, 38554, 38666, 38791, 38990, 39059, 39597, 39694,
  39762, 39791, 39833, 39875, 39876, 39917, 39939, 39976, 40033, 40055, 40057,
  40110, 40129, 40221, 40279, 40283, 40287, 40299, 40304, 40316, 40333, 40392,
  40394, 40396, 40398, 40413, 40414, 40460, 40482, 40500, 40538, 40546, 40547,
  40572, 40578, 40603, 40609, 40677, 40689, 40701, 40704, 40734, 40764, 40837,
  40865, 40915, 40931, 40941, 40955, 40956, 40958, 40959, 41019, 41036, 41050,
  41095, 41130, and 41180.

## 0.39.4
* Deprecated `DartType.name`, use `element` or `getDisplayString()` instead.
* Fixed bugs 35108 and 39996.

## 0.39.3
* Bumped the analyzer's SDK requirement to `>=2.6.0`, so that extension methods
  can be used within the analyzer implementation.
* Deprecated `ErrorReporter.source` setter. One file - one reporter.
* Deprecated `Element.getAncestor`.  Use thisOrAncestorMatching or
  thisOrAncestorOfType instead.
* Deprecated `DartType.displayName`.  Use getDisplayString instead.
* Deprecated the following methods in `InterfaceType`: `lookupGetter`,
  `lookUpGetterInSuperclass`, `lookUpInheritedGetter`,
  `lookUpInheritedGetterOrMethod`, `lookUpInheritedMethod`,
  `lookUpInheritedSetter`, `lookUpMethod`, `lookUpMethodInSuperclass`,
  `lookUpSetter`, and `lookUpSetterInSuperclass`.  Use `lookUpGetter2()`,
  `lookUpMethod2()`, or `lookUpSetter2()` instead, with `concrete` or
  `inherited` flags as necessary.
* Deprecated `ErrorReporter.reportTypeErrorForNode`.  Use `reportErrorForNode`
  instead.
* Added new error codes: EXPORT_LEGACY_SYMBOL and DEAD_NULL_COALESCE.
* Removed error codes CONST_WITH_INVALID_TYPE_PARAMETERS and
  NEW_WITH_INVALID_TYPE_PARAMETERS.  WRONG_NUMBER_OF_TYPE_ARGUMENTS is now
  reported instead.
* Removed error codes: DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS,
  INVALID_OPTIONAL_PARAMETER_TYPE.
* Reclassified error codes as compile time errors: BREAK_LABEL_ON_SWITCH_MEMBER,
  CONTINUE_LABEL_ON_SWITCH, PART_OF_UNNAMED_LIBRARY.
* Removed error codes: ASSIGNMENT_CAST, StrongModeCode.DOWN_CAST_COMPOSITE,
  DOWN_CAST_IMPLICIT, DOWN_CAST_IMPLICIT_ASSIGN, DYNAMIC_CAST, DYNAMIC_INVOKE,
  IMPLICIT_DYNAMIC_FIELD, IMPLICIT_DYNAMIC_FUNCTION, IMPLICIT_DYNAMIC_INVOKE,
  IMPLICIT_DYNAMIC_LIST_LITERAL, IMPLICIT_DYNAMIC_MAP_LITERAL,
  IMPLICIT_DYNAMIC_METHOD, IMPLICIT_DYNAMIC_PARAMETER, IMPLICIT_DYNAMIC_RETURN,
  IMPLICIT_DYNAMIC_TYPE, IMPLICIT_DYNAMIC_VARIABLE, INFERRED_TYPE,
  INFERRED_TYPE_ALLOCATION, INFERRED_TYPE_CLOSURE, INFERRED_TYPE_LITERAL, and
  NON_GROUND_TYPE_CHECK_INFO.  These were used internally by the analyzer for
  testing and were not exposed to users.
* Fixed bugs 37116, 38281, 38859, 39524, 39598, 39651, 39667, 39668, 39709,
  39711, 39752, 39773, 39848, 39849, and 39880.

## 0.39.2+1
* Fixed bug #39702.

## 0.39.2
* Deprecated `AnalysisSession.typeProvider` and `AnalysisSession.typeSystem`.
  Please use the corresponding getters in `LibraryElement` instead.
* Added new error codes: AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER,
  DEFERRED_IMPORT_OF_EXTENSION, LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR,
  WRONG_TYPE_PARAMETER_VARIANCE_POSITION, and
  WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE.
* Added new hint codes: INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN,
  INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS,
  INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE,
  INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER,
  INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX,
  INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS, and
  INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES.
* Changed error code TYPE_PARAMETER_ON_CONSTRUCTOR from a CompileTimeErrorCode
  to a ParserErrorCode.
* Split warning code RETURN_OF_INVALID_TYPE into two warnings:
  RETURN_OF_INVALID_TYPE_FROM_FUNCTION and RETURN_OF_INVALID_TYPE_FROM_METHOD.
* Merged warning codes CONST_WITH_ABSTRACT_CLASS and NEW_WITH_ABSTRACT_CLASS
  into INSTANTIATE_ABSTRACT_CLASS.
* Removed warning code MIXED_RETURN_TYPES (this is now allowed by the language
  spec).
* Bug fixes: 33745, 35677, 35677, 37504, 37936, 38506, 38551, 38734, 38813,
  38878, 38953, 38992, 39051, 39115, 39117, 39120, 39192, 39250, 39267, 39380,
  39389, 39402, 39407, 39476, 39509, 39532, 39563, 39618.

## 0.39.1
* Deprecated `DartType.substitute2()`. Use `ClassElement.instantiate()`
  or `FunctionTypeAliasElement.instantiate()` instead.
* Deprecated `ParameterizedType.instantiate()` and
  `InterfaceType.instantiate()`. Use `ClassElement.instantiate()` instead.
  Using `FunctionType.instantiate()` is still valid.
* Deprecated `FunctionTypeAliasElement.instantiate2`, use `instantiate2`.
  In the next version `instantiate2` will be removed.
* Deprecated `ParameterizedType.typeParameters`.  Please use
  `ClassElement.typeParameters or FunctionType.typeFormals` instead.
* Bug fixes: 27617, 34378, 35607, 38494, 38582, 38583, 38643, 38761, 38991,
  39089, 39111, 39156, 39158, 39170, 39171, 39178.

## 0.39.0
* Removed deprecated `DartType.isEquivalentTo`.
* Removed `useDart2jsPaths` argument in `FolderBasedDartSdk` constructor.
  Dartium does not exist anymore, so there is just one `dart:html`.
* Removed several unused members of `SourceFactory`: `context`,
  `localSourcePredicate`, `clone`, `fromEncoding`, `isLocalSource`.
* Removed deprecated method `Element.computeNode`.
* Removed deprecated getter `CompilationUnitElement.unit`.
* Removed deprecated method `Element.computeDocumentationComment`.
* Removed unused `wrapped.dart` with `WrappedLibraryElement`, etc.
* Removed deprecated 'bestElement', 'bestType', 'propagatedElement',
  'propagatedType', etc. Use 'staticElement' and 'staticType' instead.
* Removed deprecated 'Declaration.element'.
  Use 'Declaration.declaredElement' instead.
* Removed deprecated 'Expression.precedence2'. Use 'precedence' instead.
* Removed `ResolutionMap resolutionMap`. Use corresponding accessors
  on AstNode(s) directly to get elements and types.
* Removed 'InheritanceManager2'. Use 'InheritanceManager3' instead.
* Removed 'InheritanceManager'. Use 'InheritanceManager3' instead.
* Removed deprecated methods in `DartType`: `flattenFutures`,
  `isAssignableTo`, `isEquivalentTo`, `isMoreSpecificThan`,
  `isSubtypeOf`, `isSupertypeOf`, `isDirectSupertypeOf`.
  Use corresponding methods of `TypeSystem` instead.
* Removed deprecated getters for checking a specific annotations on
  'Element': `isAlwaysThrows`, `isDeprecated`, `isFactory`, `isJS`,
  `isOverride`, `isProtected`, `isRequired`, `isVisibleForTesting`.
  Use corresponding `hasXyz` getters.
* Removed 'LocalElement.visibleRange'.
  Visible ranges of local variables and functions can be computed when
  AST is available.
* Removed unused `LibraryElement.libraryCycle`.
* Removed `ElementHandle` and `ElementResynthesizer`.
* Remove `ElementBuilder`, `DeclarationResolver`, `DirectiveResolver`,
  `TypeParameterBoundsResolver`, `TypeResolverVisitor`, etc.
  Use `ResolutionVisitor` instead, it combines all these operations.
* Removed `FunctionTypeAliasElement.instantiate`, use `instantiate2` for now.
  In the next version `instantiate` will be re-introduced with the same
  signature and semantics as `instantiate2`, and `instantiate2` will be
  deprecated and removed in the next breaking change version.
* Stop setting types for identifiers where they are not expressions.
  Specifically, where a SimpleIdentifier is the name of a declaration,
  or Identifier is the name of the class in a TypeName.
* Removed transitional `InheritanceManagerBase`.
* Removed deprecated method `ArgumentList.correspondingPropagatedParameters`.
  Use `ArgumentList.correspondingStaticParameters` instead.
* Removed deprecated getter `PrefixElement.importedLibraries`.  It was never
  implemented.
* Removed deprecated getter `VariableElement.isPotentiallyMutatedInClosure` and
  `VariableElement.isPotentiallyMutatedInScope`.  Please use the corresponding
  methods in `FunctionBody` instead.
* Bug fixes: 33441, 35777, 35993, 37898, 38560, 38803, 38811, 38900, 38911.

## 0.38.5
* Added the interface `PromotableElement`, which representing
  variables that can be type promoted (local variables and parameters,
  but not fields).
* Deprecated the boolean `AnalysisDriver.useSummary2`.  Summary1 support has
  been removed, so clients should assume Summary2 is in use now.
* Deprecated the constructor argument `useDart2jsPaths` for SdkLibrariesReader.
  We now always use Dart2js paths.
* Bug fixes: #37608, #37708, #37867, #38498, #38565, #38572, #38589, #38641,
  #38653, #38667, #38695, #38706.

## 0.38.4
* Bug fixes: #33300, #38484, #38505.

## 0.38.3
* Deprecated the following codes from `StaticWarningCode`.  Please use the
  corresponding error codes from `CompileTimeErrorCode` instead:
  * `EXTRA_POSITIONAL_ARGUMENTS`
  * `EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED`
  * `IMPORT_OF_NON_LIBRARY`
  * `NOT_ENOUGH_REQUIRED_ARGUMENTS`
  * `REDIRECT_TO_MISSING_CONSTRUCTOR`
  * `REDIRECT_TO_NON_CLASS`
  * `UNDEFINED_CLASS`
  * `UNDEFINED_NAMED_PARAMETER`
* Bug fixes: #33749, #35985, #37708, #37857, #37858, #37859, #37945, #38022,
  #38057, #38071, #38091, #38095, #38105, #38113, #38198, #38202, #38203,
  #38261, #38282, #38365, #38417, #38448, #38449.

## 0.38.2
* The type of `FunctionTypeAlias.declaredElement` has been refined to
  `FunctionTypeAliasElement`.  Since the new type is a refinement of
  the old one, the only effect on clients should be to make certain
  casts unnecessary.
* Deprecated `HintCode.INVALID_REQUIRED_PARAM` and replaced it with more
  specific hints, `HintCode.INVALID_REQUIRED_NAMED_PARAM`,
  `HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM`, and
  `HintCode.INVALID_REQUIRED_POSITIONAL_PARAM` to address #36966.
* Deprecated `CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS`.  It
  has been renamed to
  `CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS`.

## 0.38.1
* LinterVistor support for extension method AST nodes.

## 0.38.0
* The deprecated method `AstFactory.compilationUnit2` has been removed.  Clients
  should switch back to `AstFactory.compilationUnit`.
* Removed the deprecated constructor `ParsedLibraryResultImpl.tmp` and the
  deprecated method `ResolvedLibraryResultImpl.tmp`.  Please use
  `AnalysisSession.getParsedLibraryByElement` and
  `AnalysisSession.getResolvedLibraryByElement` instead.
* Removed `MethodElement.getReifiedType`.
* The return type of `ClassMemberElement.enclosingElement` was changed from
  `ClassElement` to `Element`.

## 0.37.1+1
* Reverted an unintentional breaking API change (the return type of
  `ClassMemberElement.enclosingElement` was changed from `ClassElement` to
  `Element`).  This change will be postponed until 0.38.0.

## 0.37.1
* Added the getters `isDartCoreList`, `isDartCoreMap`, `isDartCoreNum`,
  `isDartCoreSet`, `isDartCoreSymbol`, and `isDartCoreObject` to `DartType`.
* Added the method `DartObject.toFunctionValue`.
* Deprecated the `isEquivalentTo(DartType)` method of `DartType`.
  The operator `==` now correctly considers two types equal if and
  only if they represent the same type as defined by the spec.
* Deprecated the `isMoreSpecificThan(DartType)` method of `DartType`.
  Deprecated the `isMoreSpecificThan(DartType)` method of `TypeSystem`.
  Deprecated the `isSupertypeOf(DartType)` method of `TypeSystem`.
  Use `TypeSystem.isSubtypeOf(DartType)` instead.
* Deprecated methods `flattenFutures`, `isAssignableTo` of `DartType`.
  Use `TypeSystem.flatten()` and `TypeSystem.isAssignableTo` instead.
* Deprecated InheritanceManager2, and replaced with InheritanceManager3.
  InheritanceManager3 returns ExecutableElements, not FunctionType(s).
* Added the optional parameter `path` to `parseString`.
* Changed `TypeSystem.resolveToBound(DartType)` implementation to do
  what its documentation says.
* This version of the analyzer should contain all the necessary parsing support
  and AST data structures for the experimental "extension-methods" feature.
  Further element model improvements needed to support extension methods will be
  published in 0.38.x.
* Deprecated `InterfaceType.isDirectSupertypeOf`.  There is no replacement; this
  method was not intended to be used outside of the analyzer.

## 0.37.0
* Removed deprecated getter `DartType.isUndefined`.
* Removed deprecated class `SdkLibrariesReader`.
* Removed deprecated method `InstanceCreationExpressionImpl.canBeConst`.
* The `AstFactory.compilationUnit` method now uses named parameters.  Clients
  that prepared for this change by switching to `AstFactory.compilationUnit2`
  should now switch back to `AstFactory.compilationUnit`.
* Removed `AstNode.getAncestor`.  Please use `AstNode.thisOrAncestorMatching` or
  `AstNode.thisOrAncestorOfType`.
* Removed deprecated getter `TypeSystem.isStrong`, and its override
  `Dart2TypeSystem.isStrong`.
* Removed the deprecated getter `AnalysisError.isStaticOnly` and the deprecated
  setters `AnalysisError.isStaticOnly` and `AnalysisError.offset`.
* Removed the `abstract` setter in `ClassElementImpl`, `EnumElementImpl`,
  `MethodElementImpl`, and `PropertyAccessorElementImpl`.  `isAbstract` should
  be used instead.
* Removed methods `AstVisitor.ForStatement2`, `ListLiteral.elements2`,
  `SetOrMapLiteral.elements2`, `AstFactory.forStatement2`, and
  `NodeLintRegistry.addForStatement2`, as well as class `ForStatement2`.  Use
  the variants with out the "2" suffix instead.
* Changed the signature and behavior of `parseFile` to match `parseFile2`.
  Clients that switched to using `parseFile2` when `parseFile` was deprecated
  should now switch back to `parseFile`.
* Removed Parser setters `enableControlFlowCollections`, `enableNonNullable`,
  `enableSpreadCollections`, and `enableTripleShift`, and the method
  `configureFeatures`.  Made the `featureSet` parameter of the Parser
  constructor a required parameter.

## 0.36.4
* Deprecated the `isNonNullableUnit` parameter of the `TypeResolverVisitor`
  constructor.  TypeResolverVisitor should now be configured using the
  `featureSet` parameter.
* Refined the return type of the getter `TypeParameter.declaredElement`.  It is
  always guaranteed to return a `TypeParameterElement`.
* Deprecated the `abstract` setter in `ClassElementImpl`, `EnumElementImpl`,
  `MethodElementImpl`, and `PropertyAccessorElementImpl`.  `isAbstract` should
  be used instead.
* Changed the way function types are displayed from e.g. `(int) -> void` to
  `void Function(int)`. This is more consistent with the syntax of Dart, and it
  will avoid ambiguities when nullability is added to the type system. This
  impacts to value returned by `FunctionType.displayName` and
  `FunctionType.toString` and `ExecutableElement.toString`. Client code might be
  broken if it depends on the content of the returned value.
* Introduced the function `parseString` to the public API.  This can be used in
  place of the deprecated functions `parseCompilationUnit` and
  `parseDirectives`.  Note that there is no option to parse only directives,
  since this functionality is broken anyway (`parseDirectives`, despite its
  name, parses the entire compilation unit).
* Changed the return type of `ClassTypeAlias.declaredElement` to `ClassElement`.
  There is no functional change; it has always returned an instance of
  `ClassElement`.
* Deprecated `parseFile`.  Please use `parseFile2` instead--in addition to
  supporting the same `featureSet` and `throwIfDiagnostics` parameters as
  `parseString`, it is much more efficient than `parseFile`.
* Added more specific deprecation notices to `package:analyzer/analyzer.dart` to
  direct clients to suitable replacements.
* Deprecated the enable flags `bogus-disabled` and `bogus-enabled`.  Clients
  should not be relying on the presence of these flags.
* Deprecated the constructor parameter
  ConstantEvaluationEngine.forAnalysisDriver, which no longer has any effect.
* Deprecated ElementImpl.RIGHT_ARROW.

## 0.36.3
* Deprecated `AstFactory.compilationUnit`.  In a future analyzer release, this
  method will be changed so that all its parameters are named parameters.
  Clients wishing to prepare for this should switch to using
  `AstFactory.compilationUnit2`.
* Deprecated Parser setters `enableControlFlowCollections`, `enableNonNullable`,
  `enableSpreadCollections`, and `enableTripleShift`, as well as the
  recently-introduced method `configureFeatures`.  Parsers should now be
  configured by passing a FeatureSet object to the Parser constructor.
* Deprecated `AnalysisError.isStaticOnly`.
* Deprecated `AnalysisError.offset` setter.
* Added method `LinterContext.canBeConstConstructor`.
* Bug fixes: #36732, #36775.

## 0.36.2
* Bug fixes: #36724.

## 0.36.1
* Deprecated `DartType.isUndefined`, and now it always returns `false`.
* The "UI as code" features (control_flow_collections and spread_collections)
  are now enabled.
* Bug fixes: #32918, #36262, #36380, #36439, #36492, #36529, #36576, #36667,
  #36678, #36691.

## 0.36.0
* Changed the return type of `Expression.precendence` to `Precedence`.  Clients
  that prepared for this change by switching to `Expression.precedence2` should
  now return to using `Expression.precedence`.
* AST cleanup related to the "UI as code" feature:
  * Removed the following AST node types:
    * `ForEachStatement` (use `ForStatement` instead)
    * `MapLiteral` and `MapLiteral2` (use `SetOrMapLiteral` instead)
    * `SetLiteral` and `SetLiteral2` (use `SetOrMapLiteral` instead)
    * `ListLiteral2` (use `ListLiteral` instead)
  * Deprecated `ForStatement2` (use `ForStatement` instead)
  * Removed the following visit methods:
    * `visitForEachStatement` (override `visitForStatement` instead)
    * `visitMapLiteral` and `visitMapLiteral2` (override `visitSetOrMapLiteral`
      instead)
    * `visitSetLiteral` and `visitSetLiteral2` (override `visitSetOrMapLiteral`
      instead)
    * `visitListLiteral2` (override `visitListLiteral` instead)
  * Deprecated the `visitForStatement2` visit method (use `VisitForStatement`
    instead)
  * Removed the following AstFactory methods:
    * `mapLiteral` and `mapLiteral2` (use `setOrMapLiteral` instead)
    * `setLiteral` and `setLiteral2` (use `setOrMapLiteral` instead)
    * `listLiteral2` (use `listLiteral` instead)
  * Deprecated `AstFactory.forStatement2`, and introduced
    `AstFactory.forStatement` to replace it
  * Changed the type of the getter `ListLiteral.elements` to
    `NodeList<CollectionElement>`
  * Deprecated `ListLiteral.elements2` (use `ListLiteral.elements` instead)
  * Deprecated `SetOrMapLiteral.elements2`, and introduced
    `SetOrMapLiteral.elements` to replace it
  * Deprecated `NodeLintRegistry.addForStatement2` (use
    `NodeLintRegistry.addForStatement` instead)
* Bug fixes: #36158, #36212, #36255

## 0.35.4
* Deprecated AST structures that will no longer be used after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following AST node types are deprecated:
  * `ForEachStatement` (use `ForStatement2` instead)
  * `ForStatement` (use `ForStatement2` instead)
  * `MapLiteral` (use `SetOrMapLiteral` instead)
  * `SetLiteral` (use `SetOrMapLiteral` instead)
* Deprecated visit methods that will no longer be used after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following visit methods are deprecated:
  * `visitForEachStatement` (override `visitForStatement2` instead)
  * `visitForStatement` (override `visitForStatement2` instead)
  * `visitMapLiteral` (override `visitSetOrMapLiteral` instead)
  * `visitSetLiteral` (override `visitSetOrMapLiteral` instead)
* Deprecated ASTFactory methods that will no longer be available after the
  control_flow_collections and spread_collections experiments are enabled.  The
  following factory methods are deprecated:
  * `mapLiteral` and `mapLiteral2` (use `setOrMapLiteral` instead)
  * `setLiteral` and `setLiteral2` (use `setOrMapLiteral` instead)
* Bug fixes: #33119, #33241, #35747, #35900, #36048, #36129
* The analyzer no longer uses `package:html` (see #35802)

## 0.35.3
* Further updates to the AST structure for the control_flow_collections and
  spread_collections experiments.  The following AST node types will be
  deprecated soon:
  * `ForEachStatement` (use `ForStatement2` instead)
  * `ForStatement` (use `ForStatement2` instead)
  * `MapLiteral` (use `SetOrMapLiteral` instead)
  * `SetLiteral` (use `SetOrMapLiteral` instead)
* Deprecated `Expression.precedence`.  In analyzer version 0.36.0, its return
  type will be changed to `Precedence`.  Clients that wish to prepare for the
  change can switch to `Expression.precedence2`.
* Bug fixes: #35908, #35993 (workaround).

## 0.35.2
* Updated support in the AST structure for the control_flow_collections and
  spread_collections experiments.  The following methods are now deprecated:
  * `AstFactory.mapLiteral2` and `AstFactory.setLiteral2` (replaced by
    `AstFactory.setOrMapLiteral`).
  * `AstVisitor.visitListLiteral2` (clients should not need to override this
    anymore).
  * `AstVisitor.visitMapLiteral2 and AstVisitor.visitSetLiteral2` (replaced by
    `AstVisitor.visitSetOrMapLiteral`).
* Started to add support for strict-inference as an analysis option.
* Bug fixes: #35870, #35922, #35936, #35940,
  https://github.com/flutter/flutter-intellij/issues/3204

## 0.35.1
* The new "set literals" language feature is now enabled by default.
* The dev_dependency analysis_tool was created so that clients do not have to
  depend on code that is used internally in the analyzer at development time.
* The `InheritanceManager` class is now deprecated.  The new
  `InheritanceManager2` class now supports accessing inherited interface/class
  maps.
* Added quick assists to support set literals.
* Added the ability for linter tests to drive the analyzer using custom analysis
  options.
* Updated support in the AST structure for the control_flow_collections and
  spread_collections experiments.  The new AST structures are still in
  development.
* Bug fixes: #34437, #35127, #35141, #35306, #35621.

## 0.35.0
* Added support in the AST structure for the control_flow_collections and
  spread_collections experiments. This includes adding new visitor methods to
  `AstVisitor`, which will need to be implemented by any classes that implement
  `AstVisitor` directly. Concrete implementations were added to other visitor
  classes (such as `RecursiveAstVisitor`) so that clients that extend those
  other classes will not be impacted.
* Removed `EMPTY_LIST` constants.  Please use `const <...>[]` instead.
* Disabled support for the task model.  Please use the new `AnalysisSession`
  API.
* Removed `StrongTypeSystemImpl`.  Please use `Dart2TypeSystem` instead.
* Made ERROR the default severity for StaticWarningCode.  We no longer need to
  promote warnings to errors in "strong mode" because strong mode is the only
  mode.
* Added exact type analysis for set literals (#35742).
* Bug fixes: #35305, #35750.

## 0.34.3
* Non-breaking AST changes in support for the control_flow_collections and
  spread_collections experiments.  Clients who wish to begin adding support for
  these experiments can depend on this release of the analyzer and begin writing
  visit methods.  The visit methods won't be added to the AstVisitor base class
  until 0.35.0.
* Bug fixes: #35551, #35708, #35723.

## 0.34.2
* Removed support for the `@checked` annotation.  Please use the `covariant`
  keyword instead (#28797).
* Did additional work on the new set_literals and constant_update_2018 features.
* Began adding a string representation of initializer expressions to summaries
  (#35418).
* Added a pub aware workspace so that pub packages can be handled properly.
* Added logging in an effort to track down #35551.
* Split off DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE from DEPRECATED_MEMBER_USE
  (#30084).
* Removed the unused hint code INVALID_ASSIGNMENT.
* Added a hint enforcing the contract of `@literal`:
  NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR.
* Added a hint INVALID_LITERAL_ANNOTATION (#34259).
* Fixed handling of @immutable on mixins.
* Did work on @sealed annotation for classes and mixins.
* Bug fixes: #25860, #29394, #33930, #35090, #35441, #35458, #35467, #35548.

## 0.34.1
* Added logic to report a hint if a deprecated lint is specified in the user's
  analysis_options.yaml file, or if a lint is specified twice.
* Added a note to the `UriResolver` documentation alerting clients of an
  upcoming breaking change.
* Improved parser recovery.
* Speculative work on fine-grained dependency tracking (not yet enabled).
* Initial support for new language features set_literals and
  constant_update_2018.
* Early speculative work on non-nullable types.
* Added AnalysisDriver.resetUriResolution().
* Deprecated TypeSystem.isStrong.
* Added WorkspacePackage classes, for determining whether two files are in the
  "same package."
* Added a public API for the TypeSystem class.
* Bug fixes: #33946, #35151, #35223, #35241, #35438.

## 0.34.0
* Support for `declarations-casts` has been removed and the `implicit-casts`
  option now has the combined semantics of both options. This means that users
  that disable `implicit-casts` might now see errors that were not previously
  being reported.
* Minor changes to the AnalysisSession and AnalysisDriver APIs to make it easier
  for clients to transition away from using the task model.
* Minor changes to the linter API to make it easier for lint rules to define
  their own lint codes.
* Add a version of getAncestor that matches by type without a closure.
* Add an AST structure for set literals.
* Bug fixes: #35162, #35230, #34733, #34741, #33553, #35090, #32815, #34387,
  #34495, #35043, #33553, #34906, #34489.

## 0.33.6+1
* Added a note to the `UriResolver` documentation alerting clients of an
  upcoming breaking change.

## 0.33.6
* Deprecated `AstNode.getAncestor` and introduced
  `AstNode.thisOrAncestorMatching` as its replacement.

## 0.33.5
* Add AnalysisSession.getResolvedLibrary()/ByElement() APIs.

## 0.33.4
* Add a hint when either Future or Stream are imported from dart:core in a package that is expected to work with an SDK before 2.1 where they were required to be imported from dart:async.
* Add a new "deprecated" maturity for lints
* Don't report DEPRECATED_MEMBER_USE for deprecated mixins, top-level variables, and class fields.
* Various bug fixes.

## 0.33.3+2
* Update SDK requirement to 2.1.0-dev.5.0.  From now on, the analyzer may import
  Future from dart:core. (#35158)

## 0.33.3+1
* Fix missing import of dart:async. (#35158)

## 0.33.3
* Backport Parsed/ResolvedLibraryResultImpl and ElementDeclarationResult.

## 0.33.2
* Protect against self-referencing classes in InheritanceManager2. (#34333)
* Introduce API so that the linter can be migrated away from Element.context.

## 0.33.1
* Fix circular typedef stack overflow. (#33599)
* Check that the implemented member is a valid override of the member from
  the super constraint. (#34693)
* Begin replacing InheritanceManager with InheritanceManager2 and
  deprecate older members.
* Performance fixups with Analysis Driver.
* Verify the superconstraint signature invoked by a mixin. (#34896)
* In_matchInterfaceSubtypeOf, account for mixins having null. (#34907)

## 0.33.0
* Support handling 'class C with M', with extends missing.
* Report ABSTRACT_SUPER_MEMBER_REFERENCE as an error.
* Further support and bugfixes for Dart 2.1-style mixin declarations.
* Fixes for int2double support.
* Performance improvements for analysis and summary generation.
* Allow "yield" as a label, and "operator" as a static method name (#33672,
  #33673)

## 0.33.0-alpha.0
* Switch to using the parser from front_end.
* Start implementing the new mixin syntax.

## 0.32.4
* Updated SDK constraint to <3.0.0.
* Updated to be compatible with Dart 2 void usage semantics.
* Deprecate the `AnalysisOptions.strongMode` flag. This is now hard-coded to
  always return true.

## 0.32.3
* Pull fix in kernel package where non-executable util.dart was moved out of bin/.

## 0.32.2

* Improved const evaluation analysis (new errors for `const A(B())` if `B` is non-const).
* Parser recovery improvements.

## 0.32.1

* The Parser() class now by default will parse with optional new or const. This
  affects many APIs, for instance, `analyzer.dart`'s `parseCompilationUnit()`.
* Add the ability to specify a pathContext when creating a ContextRoot (not part
  of the officially supported API, but needed by some clients).
* AnalysisSession now exports resourceProvider.
* Function type parameters are now invariant. (#29014)
* New logic to find source files generated by package:build when that build
  system is detected.
* Data stored by FileDataStore is now checked using CRC32.
* Add ability for the angular plugin to set ErrorVerifier.enclosingClass.

## 0.32.0

* Allow annotations on enum constants.
* Analyzer fully supports being run on the VM with --preview-dart-2.
* Fix heap usage regression by not storing bytes in the file cache.
* Add AnalysisSessionHelper.getTopLevelPropertyAccessor().
* Don't infer types when there's an irreconcilable type mismatch (#32305)
* Many fasta parser improvements.
* Use @isTest and @isTestGroup to understand executable element as a
  test/group.  To use, add `@isTest` annotations (from package:meta)
  to the methods in their package which define a test.
```dart
@isTest
void myMagicTest(String name, FutureOr Function() body) {
  test(name, body);
}
```
  When subscribed to [notifications for outlines of a test file](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#notification_analysis.outline),
  they will include elements for UNIT_TEST_GROUP and UNIT_TEST_TEST.
* Improve guess for type name identifier. (#32765)
* Fix LineInfo.getOffsetOfLineAfter().
* Remove some flutter specific analysis code.
* Fix resolution tests when run locally.

## 0.31.2-alpha.2

* Refactoring to make element model logic sharable with
  linker. (#32525, #32674)
* Gracefully handle an invalid packages file. (#32560)
* Fix silent inconsistency in top level inference. (#32394)
* Fix test to determine whether a library is in the SDK. (#32707)
* Fix for type inference from instance creation arguments.
* Make GenericFunctionTypeElementForLink implement
  GenericFunctionTypeElementImpl (#32708)
* Check for missing required libraries dart:core and dart:async. (#32686)
* Add callable object support. (#32156, #32157, #32426)
* Avoid putting libraries of all analyzed units in the current
  session. (too expensive)
* Deprecate the option to enable using a URI in a part-of directive.
* Support implicit call() invocation in top-level inference. (#32740)
* Don't emit errors for lint rule names.
* Allow empty flutter: sections in pubspec files.
* Remove the special casing of 'packages' files from the analyzer and analysis
  server.
* Initial implementation of API to build analysis contexts (replacing
  ContextLocator.locateContexts).
* Fix regression in Analyzer callable function support. (#32769)
* Several performance enhancements, including:
  * Add a shared cache of FileState contents (making flutter repo analysis
    ~12% faster).
  * Replace SourceFactory.resolveUri() with resolveRelativeUri() in
    resynthesizer.  (10% faster flutter repo analysis)
  * Optimize computing exported namespaces in FileState.
  * Optimize computing exported namespaces in prelinker. (8% faster
    flutter repo analysis)
  * Add NodeLintRule and UnitLintRule that replace AstVisitor in lints.
    (6% faster flutter repo analysis)
* Remove fuzzy arrow support from analyzer. (#31637)
* More fixes for running the analyzer with Dart 2.
* Add isXYZ accessors to ParameterElementForLink_VariableSetter. (#32896)
* Demote IMPORT_DUPLICATED_LIBRARY_NAMED to a warning.
* Deprecated/removed some unused classes and libraries from the public API.
* Instantiate bounds to bounds.
* Use package:path instead of AbsolutePathContext.
* Check that argument is assignable to parameter in call() (#27098)
* preview-dart-2 is now the default for the command line analyzer, also
  implying strong.  Use --no-strong and --no-preview-dart-2 to handle
  Dart 1 code.
* Export SyntheticBeginToken and SyntheticToken from the analyzer for
  angular_analyzer_plugin.
* Improve error messages for annotations involving undefined names (#27788)
* Add support for getting parse results synchronously.
* Change linter subscriptions from functions to AstVisitor(s).

## 0.31.2-alpha.1

* Don't expect type arguments for class type parameters of static methods.
  (#32396)
* Beginnings of changes to make analyzer code --preview-dart-2 safe, though
  this version is not vetted for that.
* Infer type arguments in constructor redirections (#30855)
* Report errors on "as void" and "is void".
* Fix instantiating typedefs to bounds (#32114)
* preview-dart-2 implies strong-mode now and other preview-dart-2 fixes.
* Store method invocation arguments in summaries when needed for inference (partial fix for #32394)
* Fix top-level inference and implicit creation (#32397)
* Do not hint when only a responsive asset exists (#32250)
* Do not hint when using a deprecated parameter in the defining function
  (#32468)
* Fix parsing of super expressions (#32393)
* Disable conflicting generics test in the task model (#32421)
* Change how we find analysis roots (#31343, #31344)
* Fix problem with AST re-writing interacting poorly with inference (#32342)
* Disallow if a class inconsistently implements a generic interface.
* Infer void for operator[]= return in task mode for DDC (#32241)
* Finish and improve mixin type inference in the analyzer (#32146, #32353, #32372)
* Many enhancements to getElementDeclarations() (#29510, #32495)
* Remove hint when there's no return from a Future<void> and async method.
* Add a code range to ElementDeclaration (#29510)
* Many, many fasta parser changes and improvements.
* Add missing void annotation (#32161)
* Add more null-aware hints (#32239)
* Fix implicit new/const computation (#32221)
* Treat invocations on dynamic as unknown, except for return type of == (#32173)
* Fix crash in generic function type argument of unresolved class (#32162)
* Fix path formatting on windows (#32095)
* front_end implementation of mixin type inference (#31984)
* analysis_options no longer breaks some properties (#31345)

## 0.31.2-alpha.0

* front_end handling of callable classes (#32064)
* Improve fasta parser error reporting.
* Check for unresolved imports to improve handling of optional new/const (#32150).
* Changes to front_end handling of callable classes.
* Normalize Windows drive letters to uppercase for analysis (#32095, #32042, #28895).
* Relax void errors: no error assigning void to void variable.
* Keep unresolved import/export directives for task based analysis
  (dart-lang/angular#801).
* Promote `TOP_LEVEL_CYCLE` to an error.
* Code cleanups.

## 0.31.1

* Update to reflect that `_InternalLinkedHashMap` is not a subtype of `HashMap`
  in sdk 2.0.0-dev.22.0.

## 0.31.0+1

* Update SDK constraint to require Dart v2-dev release.

## 0.31.0

* **NOTE** This release was pulled from the package site due to an invalid SDK
  constraint that was fixed in `0.31.0+1`.

* A number of updates, including support for the new Function syntax.

## 0.30.0-alpha.0
* Changed the API for creating BazelWorkspace.  It should now be constructed using BazelWorkspace.find().  Note that this might return `null` in the event that the given path is not part of a BazelWorkspace.
* Added an AST structure to support asserts in constructor initializers (AssertInitializer).  AstVisitor classes must now implement visitAssertInitializer().
* Changed the API for creating PartOfDirective.  It now accepts a StringLiteral URI, to accommodate "part of" declarations with a URI string rather than a library name.
* Removed AST constructors.  AST nodes should now be created using `astFactory`, located in `package:analyzer/dart/ast/standard_ast_factory.dart`.

## 0.29.0-alpha.0
* Removed `Element.docRange`.

## 0.28.2-alpha.0
* Corresponds with the analyzer/server in the `1.20.0-dev.1.0` SDK.

## 0.28.0-alpha.2
* Fixed PubSummaryManager linking when a listed package does not have the unlinked bundle.

## 0.27.4-alpha.19
* Added support for running the dev compiler in the browser.

## 0.27.4-alpha.18
* Support for references to operators in doc comments (#26929).

## 0.27.4-alpha.17
* Support for trailing commas in parameter and argument lists (#26647).
* Strong mode breaking change: can now infer generic type arguments from the constructor invocation arguments (#25220).

## 0.27.4-alpha.16
* (Internal) Corresponds with the analyzer/server in the `1.18.0-dev.4.0` SDK.

## 0.27.4-alpha.9
* Restore EmbedderUriResolver API.

## 0.27.4-alpha.8
* Ignore processing performance improvements.
* EmbedderUriResolver API updates.

## 0.27.4

* Added support for 'analysis_options.yaml' files as an alternative to '.analysis_options' files.

## 0.27.1
* Moved the public and private API's for the element model into their proper places.
* Added back support for auto-processing of plugins.

## 0.27.0
* Support for DEP 37 (Assert with optional message).
* Lexical support for DEP 40 (Interface libraries). This does not include any semantic checking to ensure that the
  implementation libraries are compatible with the interface library.
* Cleaned up the initialization of plugins. Clients are now required to initialize plugins, possibly using the utility
  method AnalysisEngine.processRequiredPlugins().
* Removed the old task model and code that supported it. None of the removed code was intended to be public API, but
  might be in use anyway.
* Removed previously deprecated API's (marked with the @deprecated annotation).

## 0.26.4
* Options processing API updated to accept untyped options maps (#25126).

## 0.26.3
* (Internal) Support for `_embedder.yaml` discovery and processing.

## 0.26.2
* Add code generation utilities for use in both analyzer and analysis server.

## 0.26.1+17
* (Internal) Introduced context configuration logic (`configureContext()` extracted from server).

## 0.26.1+16
* (Internal) Options validation plugin API update.

## 0.26.1+15
* (Internal) Provisional options validation plugin API.

## 0.26.1+13
* (Internal) Plugin processing fixes.

## 0.26.1+11
* Fixes to address lint registry memory leaking.

## 0.26.1+10
* New `AnalysisContext` API for associating configuration data with contexts
  (`setConfigurationData()` and `getConfigurationData()`).

## 0.26.1+9
* `OptionsProcessor` extension point API changed to pass associated
  `AnalysisContext` instance into the `optionsProcessed` call-back.

## 0.26.1+6
* Provisional (internal) plugin manifest parsing.

## 0.26.1+5
* Plugin configuration `ErrorHandler` typedef API fix.

## 0.26.1+4
* Provisional (internal) support for plugin configuration via `.analysis_options`.

## 0.26.1+2

* Extension point for WorkManagerFactory(s).
* Resolve enum documentation comments.
* Fix display of parameter lists in servers Element structure (issue 24194)
* Band-aid fix for issue #24191.

## 0.26.1+1

* Removed a warning about importing unnamed libraries
* Fix handling of empty URIs in `.packages` files (issue 24126)

## 0.26.1

* Fix line starts in multiline comments (issue 23919).
* Various small fixes to Windows path handling.
* Update LineInfo computation during incremental resolution.
* Make exclude list apply to contexts (issue 23941).
* Fix type propagation for asynchronous for-in statements.
* Fix ToStringVisitor for external functions (issue 23968).
* Fix sorting of compilation unit members.
* Add forwarding for DefaultFormalParameter metadata.
* Fix most implementations of UriResolver.restoreAbsolute.
* Disable dart2js hints by default.
* Support older SDKs (Dart 1.11).

## 0.26.0

* Add hook for listening to implicitly analyzed files
* Add a PathFilter and AnalysisOptionsProvider utility classes to aid
  clients in excluding files from analysis when directed to do so by an
  options file.
* API change: `UriResolver.resolveUri(..)` now takes an optional `actualUri`.
* Change `ResolutionCopier.visitAwaitExpression` to copy *Type fields.
* Fix highlight range for missing enum constant in switch (issue 23904).
* Fix analyzer's treatment of `ClassName?.staticMember` to match spec.
* Implement DEP 34 (less restricted mixins).
* Fix some implementations of `UriResolver.resolveUri(..)` that did not
  properly handle the new `actualUri` argument.

## 0.25.2

* Requires Dart SDK 1.12-dev or greater
* Enable null-aware operators (DEP 9) by default.
* Generic method support in the element model.

## 0.25.2-alpha.1

* `dart:sdk` extension `.sdkext` changed to `_sdkext` (to play nicer with pub).

## 0.25.2-alpha.0

* Initial support for analyzing `dart:sdk` extensions from `.sdkext`.

## 0.25.1

* (Internal) code reorganization to address analysis warnings due to SDK reorg.
* First steps towards `.packages` support.

## 0.25.0

* Commandline interface moved to dedicated `analyzer_cli` package. Files moved:
  * `bin/analyzer.dart`
  * `lib/options.dart`
  * `lib/src/analyzer_impl.dart`
  * `lib/src/error_formatter.dart`
* Removed dependency on the `args` package.

## 0.22.1

* Changes in the async/await support.


## 0.22.0

  New API:

* `Source.uri` added.

  Breaking changes:

* `DartSdk.fromEncoding` replaced with `fromFileUri`.
* `Source.resolveRelative` replaced with `resolveRelativeUri`.
