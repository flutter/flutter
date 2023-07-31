// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

const isClassElement = TypeMatcher<ClassElement>();

const isCompilationUnitElement = TypeMatcher<CompilationUnitElement>();

const isConstructorElement = TypeMatcher<ConstructorElement>();

const isElementAnnotation = TypeMatcher<ElementAnnotation>();

const isExecutableElement = TypeMatcher<ExecutableElement>();

const isExportElement = TypeMatcher<LibraryExportElement>();

const isFieldElement = TypeMatcher<FieldElement>();

const isFieldFormalParameterElement =
    TypeMatcher<FieldFormalParameterElement>();

const isFunctionElement = TypeMatcher<FunctionElement>();

const isFunctionTypedElement = TypeMatcher<FunctionTypedElement>();

const isGenericFunctionTypeElement = TypeMatcher<GenericFunctionTypeElement>();

const isHideElementCombinator = TypeMatcher<HideElementCombinator>();

const isImportElement = TypeMatcher<LibraryImportElement>();

const isLabelElement = TypeMatcher<LabelElement>();

const isLibraryElement = TypeMatcher<LibraryElement>();

const isLocalElement = TypeMatcher<LocalElement>();

const isLocalVariableElement = TypeMatcher<LocalVariableElement>();

const isMethodElement = TypeMatcher<MethodElement>();

const isNamespaceCombinator = TypeMatcher<NamespaceCombinator>();

const isParameterElement = TypeMatcher<ParameterElement>();

const isPrefixElement = TypeMatcher<PrefixElement>();

const isPropertyAccessorElement = TypeMatcher<PropertyAccessorElement>();

const isPropertyInducingElement = TypeMatcher<PropertyInducingElement>();

const isShowElementCombinator = TypeMatcher<ShowElementCombinator>();

const isTopLevelVariableElement = TypeMatcher<TopLevelVariableElement>();

const isTypeDefiningElement = TypeMatcher<TypeDefiningElement>();

const isTypeParameterElement = TypeMatcher<TypeParameterElement>();

const isTypeParameterizedElement = TypeMatcher<TypeParameterizedElement>();

const isUriReferencedElement = TypeMatcher<UriReferencedElement>();

const isVariableElement = TypeMatcher<VariableElement>();
