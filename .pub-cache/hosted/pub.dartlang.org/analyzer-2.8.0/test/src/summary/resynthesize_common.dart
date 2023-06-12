// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';

/// Abstract base class for resynthesizing and comparing elements.
///
/// The return type separator: →
abstract class AbstractResynthesizeTest with ResourceProviderMixin {
  /// The set of features enabled in this test.
  late FeatureSet featureSet;

  DeclaredVariables declaredVariables = DeclaredVariables();
  late final SourceFactory sourceFactory;
  late final FolderBasedDartSdk sdk;

  late String testFile;
  late Source testSource;
  Set<Source> otherLibrarySources = <Source>{};

  AbstractResynthesizeTest() {
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    sourceFactory = SourceFactory(
      [
        DartUriResolver(sdk),
        PackageMapUriResolver(resourceProvider, {
          'test': [
            getFolder('/home/test/lib'),
          ],
        }),
        ResourceUriResolver(resourceProvider),
      ],
    );

    testFile = convertPath('/test.dart');
  }

  void addLibrary(String uri) {
    var source = sourceFactory.forUri(uri)!;
    otherLibrarySources.add(source);
  }

  Source addLibrarySource(String filePath, String contents) {
    var source = addSource(filePath, contents);
    otherLibrarySources.add(source);
    return source;
  }

  Source addSource(String path, String contents) {
    var file = newFile(path, content: contents);
    var uri = sourceFactory.pathToUri(file.path)!;
    return sourceFactory.forUri2(uri)!;
  }

  Source addTestSource(String code, [Uri? uri]) {
    testSource = addSource(testFile, code);
    return testSource;
  }

  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors = false});
}

class FeatureSets {
  static final FeatureSet language_2_9 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.9.0'),
    flags: [],
  );

  static final FeatureSet language_2_12 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.12.0'),
    flags: [],
  );

  static final FeatureSet latestWithExperiments = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.15.0'),
    flags: [
      EnableString.constructor_tearoffs,
    ],
  );
}

/// Mixin containing test cases exercising summary resynthesis.  Intended to be
/// applied to a class implementing [AbstractResynthesizeTest].
mixin ResynthesizeTestCases on AbstractResynthesizeTest {
  test_class_abstract() async {
    var library = await checkLibrary('abstract class C {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        constructors
          synthetic @-1
''');
  }

  test_class_alias() async {
    var library = await checkLibrary('''
class C = D with E, F, G;
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @6
        supertype: D
        mixins
          E
          F
          G
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @32
        constructors
          synthetic @-1
      class E @43
        constructors
          synthetic @-1
      class F @54
        constructors
          synthetic @-1
      class G @65
        constructors
          synthetic @-1
''');
  }

  test_class_alias_abstract() async {
    var library = await checkLibrary('''
abstract class C = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class alias C @15
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @35
        constructors
          synthetic @-1
      class E @46
        constructors
          synthetic @-1
''');
  }

  test_class_alias_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @22
        documentationComment: /**\n * Docs\n */
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @43
        constructors
          synthetic @-1
      class E @54
        constructors
          synthetic @-1
''');
  }

  test_class_alias_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// b
/// cc
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @27
        documentationComment: /// aaa\n/// b\n/// cc
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @48
        constructors
          synthetic @-1
      class E @59
        constructors
          synthetic @-1
''');
  }

  test_class_alias_documented_withLeadingNonDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @66
        documentationComment: /**\n * Docs\n */
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @87
        constructors
          synthetic @-1
      class E @98
        constructors
          synthetic @-1
''');
  }

  test_class_alias_generic() async {
    var library = await checkLibrary('''
class Z = A with B<int>, C<double>;
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias Z @6
        supertype: A
        mixins
          B<int>
          C<double>
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
      class A @42
        constructors
          synthetic @-1
      class B @53
        typeParameters
          covariant B1 @55
            defaultType: dynamic
        constructors
          synthetic @-1
      class C @68
        typeParameters
          covariant C1 @70
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_alias_notSimplyBounded_self() async {
    var library = await checkLibrary('''
class C<T extends C> = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class alias C @6
        typeParameters
          covariant T @8
            bound: C<dynamic>
            defaultType: dynamic
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @39
        constructors
          synthetic @-1
      class E @50
        constructors
          synthetic @-1
''');
  }

  test_class_alias_notSimplyBounded_simple_no_type_parameter_bound() async {
    // If no bounds are specified, then the class is simply bounded by syntax
    // alone, so there is no reason to assign it a slot.
    var library = await checkLibrary('''
class C<T> = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @29
        constructors
          synthetic @-1
      class E @40
        constructors
          synthetic @-1
''');
  }

  test_class_alias_notSimplyBounded_simple_non_generic() async {
    // If no type parameters are specified, then the class is simply bounded, so
    // there is no reason to assign it a slot.
    var library = await checkLibrary('''
class C = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @6
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @26
        constructors
          synthetic @-1
      class E @37
        constructors
          synthetic @-1
''');
  }

  test_class_alias_with_const_constructors() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', r'''
class Base {
  const Base._priv();
  const Base();
  const Base.named();
}
''');
    var library = await checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class M @23
        constructors
          synthetic @-1
      class alias MixinApp @34
        supertype: Base
        mixins
          M
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: package:test/a.dart::@class::Base::@constructor::•
                superKeyword: super @0
          synthetic const named @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::named
                  staticType: null
                  token: named @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::named
                superKeyword: super @0
''');
  }

  test_class_alias_with_forwarding_constructors() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', r'''
class Base {
  bool x = true;
  Base._priv();
  Base();
  Base.noArgs();
  Base.requiredArg(x);
  Base.positionalArg([bool x = true]);
  Base.positionalArg2([this.x = true]);
  Base.namedArg({int x = 42});
  Base.namedArg2({this.x = true});
  factory Base.fact() => Base();
  factory Base.fact2() = Base.noArgs;
}
''');
    var library = await checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class M @23
        constructors
          synthetic @-1
      class alias MixinApp @34
        supertype: Base
        mixins
          M
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: package:test/a.dart::@class::Base::@constructor::•
                superKeyword: super @0
          synthetic noArgs @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::noArgs
                  staticType: null
                  token: noArgs @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::noArgs
                superKeyword: super @0
          synthetic requiredArg @-1
            parameters
              requiredPositional x @-1
                type: dynamic
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: x@-1
                      staticType: dynamic
                      token: x @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::requiredArg
                  staticType: null
                  token: requiredArg @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::requiredArg
                superKeyword: super @0
          synthetic positionalArg @-1
            parameters
              optionalPositional x @-1
                type: bool
                constantInitializer
                  BooleanLiteral
                    literal: true @127
                    staticType: bool
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: x@-1
                      staticType: bool
                      token: x @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::positionalArg
                  staticType: null
                  token: positionalArg @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::positionalArg
                superKeyword: super @0
          synthetic positionalArg2 @-1
            parameters
              optionalPositional final x @-1
                type: bool
                constantInitializer
                  BooleanLiteral
                    literal: true @167
                    staticType: bool
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: x@-1
                      staticType: bool
                      token: x @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::positionalArg2
                  staticType: null
                  token: positionalArg2 @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::positionalArg2
                superKeyword: super @0
          synthetic namedArg @-1
            parameters
              optionalNamed x @-1
                type: int
                constantInitializer
                  IntegerLiteral
                    literal: 42 @200
                    staticType: int
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: x@-1
                      staticType: int
                      token: x @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::namedArg
                  staticType: null
                  token: namedArg @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::namedArg
                superKeyword: super @0
          synthetic namedArg2 @-1
            parameters
              optionalNamed final x @-1
                type: bool
                constantInitializer
                  BooleanLiteral
                    literal: true @233
                    staticType: bool
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: x@-1
                      staticType: bool
                      token: x @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: package:test/a.dart::@class::Base::@constructor::namedArg2
                  staticType: null
                  token: namedArg2 @-1
                period: . @0
                staticElement: package:test/a.dart::@class::Base::@constructor::namedArg2
                superKeyword: super @0
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class Base @6
        typeParameters
          covariant T @11
            defaultType: dynamic
        constructors
          ctor @23
            periodOffset: 22
            nameEnd: 27
            parameters
              requiredPositional t @30
                type: T
              requiredPositional l @41
                type: List<T>
      class M @53
        constructors
          synthetic @-1
      class alias MixinApp @64
        supertype: Base<dynamic>
        mixins
          M
        constructors
          synthetic ctor @-1
            parameters
              requiredPositional t @-1
                type: dynamic
              requiredPositional l @-1
                type: List<dynamic>
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: t@-1
                      staticType: dynamic
                      token: t @-1
                    SimpleIdentifier
                      staticElement: l@-1
                      staticType: List<dynamic>
                      token: l @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: self::@class::Base::@constructor::ctor
                  staticType: null
                  token: ctor @-1
                period: . @0
                staticElement: self::@class::Base::@constructor::ctor
                superKeyword: super @0
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution_complex() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class Base @6
        typeParameters
          covariant T @11
            defaultType: dynamic
        constructors
          ctor @23
            periodOffset: 22
            nameEnd: 27
            parameters
              requiredPositional t @30
                type: T
              requiredPositional l @41
                type: List<T>
      class M @53
        constructors
          synthetic @-1
      class alias MixinApp @64
        typeParameters
          covariant U @73
            defaultType: dynamic
        supertype: Base<List<U>>
        mixins
          M
        constructors
          synthetic ctor @-1
            parameters
              requiredPositional t @-1
                type: List<U>
              requiredPositional l @-1
                type: List<List<U>>
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: t@-1
                      staticType: List<U>
                      token: t @-1
                    SimpleIdentifier
                      staticElement: l@-1
                      staticType: List<List<U>>
                      token: l @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: self::@class::Base::@constructor::ctor
                  staticType: null
                  token: ctor @-1
                period: . @0
                staticElement: self::@class::Base::@constructor::ctor
                superKeyword: super @0
''');
  }

  test_class_alias_with_mixin_members() async {
    var library = await checkLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @6
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @26
        constructors
          synthetic @-1
      class E @37
        fields
          x @105
            type: int
          synthetic a @-1
            type: int
          synthetic b @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          get a @51
            returnType: int
          set b @73
            parameters
              requiredPositional i @79
                type: int
            returnType: void
        methods
          f @92
            returnType: void
''');
  }

  test_class_constructor_const() async {
    var library = await checkLibrary('class C { const C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @16
''');
  }

  test_class_constructor_const_external() async {
    var library = await checkLibrary('class C { external const C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          external const @25
''');
  }

  test_class_constructor_explicit_named() async {
    var library = await checkLibrary('class C { C.foo(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          foo @12
            periodOffset: 11
            nameEnd: 15
''');
  }

  test_class_constructor_explicit_type_params() async {
    var library = await checkLibrary('class C<T, U> { C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          @16
''');
  }

  test_class_constructor_explicit_unnamed() async {
    var library = await checkLibrary('class C { C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @10
''');
  }

  test_class_constructor_external() async {
    var library = await checkLibrary('class C { external C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          external @19
''');
  }

  test_class_constructor_factory() async {
    var library = await checkLibrary('class C { factory C() => throw 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          factory @18
''');
  }

  test_class_constructor_field_formal_dynamic_dynamic() async {
    var library =
        await checkLibrary('class C { dynamic x; C(dynamic this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @18
            type: dynamic
        constructors
          @21
            parameters
              requiredPositional final this.x @36
                type: dynamic
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_dynamic_typed() async {
    var library = await checkLibrary('class C { dynamic x; C(int this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @18
            type: dynamic
        constructors
          @21
            parameters
              requiredPositional final this.x @32
                type: int
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_dynamic_untyped() async {
    var library = await checkLibrary('class C { dynamic x; C(this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @18
            type: dynamic
        constructors
          @21
            parameters
              requiredPositional final this.x @28
                type: dynamic
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_functionTyped_noReturnType() async {
    var library = await checkLibrary(r'''
class C {
  var x;
  C(this.x(double b));
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @16
            type: dynamic
        constructors
          @21
            parameters
              requiredPositional final this.x @28
                type: dynamic Function(double)
                parameters
                  requiredPositional b @37
                    type: double
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_functionTyped_withReturnType() async {
    var library = await checkLibrary(r'''
class C {
  var x;
  C(int this.x(double b));
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @16
            type: dynamic
        constructors
          @21
            parameters
              requiredPositional final this.x @32
                type: int Function(double)
                parameters
                  requiredPositional b @41
                    type: double
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_functionTyped_withReturnType_generic() async {
    var library = await checkLibrary(r'''
class C {
  Function() f;
  C(List<U> this.f<T, U>(T t));
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          f @23
            type: dynamic Function()
        constructors
          @28
            parameters
              requiredPositional final this.f @43
                type: List<U> Function<T, U>(T)
                typeParameters
                  covariant T @45
                  covariant U @48
                parameters
                  requiredPositional t @53
                    type: T
        accessors
          synthetic get f @-1
            returnType: dynamic Function()
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: dynamic Function()
            returnType: void
''');
  }

  test_class_constructor_field_formal_multiple_matching_fields() async {
    // This is a compile-time error but it should still analyze consistently.
    var library = await checkLibrary('class C { C(this.x); int x; String x; }',
        allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @25
            type: int
          x @35
            type: String
        constructors
          @10
            parameters
              requiredPositional final this.x @17
                type: int
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          synthetic get x @-1
            returnType: String
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: String
            returnType: void
''');
  }

  test_class_constructor_field_formal_no_matching_field() async {
    // This is a compile-time error but it should still analyze consistently.
    var library =
        await checkLibrary('class C { C(this.x); }', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @10
            parameters
              requiredPositional final this.x @17
                type: dynamic
''');
  }

  test_class_constructor_field_formal_typed_dynamic() async {
    var library = await checkLibrary('class C { num x; C(dynamic this.x); }',
        allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: num
        constructors
          @17
            parameters
              requiredPositional final this.x @32
                type: dynamic
        accessors
          synthetic get x @-1
            returnType: num
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: num
            returnType: void
''');
  }

  test_class_constructor_field_formal_typed_typed() async {
    var library = await checkLibrary('class C { num x; C(int this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: num
        constructors
          @17
            parameters
              requiredPositional final this.x @28
                type: int
        accessors
          synthetic get x @-1
            returnType: num
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: num
            returnType: void
''');
  }

  test_class_constructor_field_formal_typed_untyped() async {
    var library = await checkLibrary('class C { num x; C(this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: num
        constructors
          @17
            parameters
              requiredPositional final this.x @24
                type: num
        accessors
          synthetic get x @-1
            returnType: num
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: num
            returnType: void
''');
  }

  test_class_constructor_field_formal_untyped_dynamic() async {
    var library = await checkLibrary('class C { var x; C(dynamic this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: dynamic
        constructors
          @17
            parameters
              requiredPositional final this.x @32
                type: dynamic
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_untyped_typed() async {
    var library = await checkLibrary('class C { var x; C(int this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: dynamic
        constructors
          @17
            parameters
              requiredPositional final this.x @28
                type: int
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_field_formal_untyped_untyped() async {
    var library = await checkLibrary('class C { var x; C(this.x); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: dynamic
        constructors
          @17
            parameters
              requiredPositional final this.x @24
                type: dynamic
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_constructor_fieldFormal_named_noDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x}); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          @17
            parameters
              optionalNamed final this.x @25
                type: int
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_class_constructor_fieldFormal_named_withDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x: 42}); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          @17
            parameters
              optionalNamed final this.x @25
                type: int
                constantInitializer
                  IntegerLiteral
                    literal: 42 @28
                    staticType: int
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_class_constructor_fieldFormal_optional_noDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x]); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          @17
            parameters
              optionalPositional final this.x @25
                type: int
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_class_constructor_fieldFormal_optional_withDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x = 42]); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          @17
            parameters
              optionalPositional final this.x @25
                type: int
                constantInitializer
                  IntegerLiteral
                    literal: 42 @29
                    staticType: int
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_class_constructor_implicit_type_params() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_constructor_params() async {
    var library = await checkLibrary('class C { C(x, int y); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @10
            parameters
              requiredPositional x @12
                type: dynamic
              requiredPositional y @19
                type: int
''');
  }

  test_class_constructor_unnamed_implicit() async {
    var library = await checkLibrary('class C {}');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
            displayName: C
''',
        withDisplayName: true);
  }

  test_class_constructors_named() async {
    var library = await checkLibrary('''
class C {
  C.foo();
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        constructors
          foo @14
            displayName: C.foo
            periodOffset: 13
            nameEnd: 17
''',
        withDisplayName: true);
  }

  test_class_constructors_unnamed() async {
    var library = await checkLibrary('''
class C {
  C();
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @12
            displayName: C
''',
        withDisplayName: true);
  }

  test_class_constructors_unnamed_new() async {
    var library = await checkLibrary('''
class C {
  C.new();
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @14
            displayName: C
            periodOffset: 13
            nameEnd: 17
''',
        withDisplayName: true);
  }

  test_class_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        documentationComment: /**\n * Docs\n */
        constructors
          synthetic @-1
''');
  }

  test_class_documented_mix() async {
    var library = await checkLibrary('''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}

/**
 * aaa
 */
/// bbb
/// ccc
class B {}

/// aaa
/// bbb
/**
 * ccc
 */
class C {}

/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}

/**
 * aaa
 */
// bbb
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @36
        documentationComment: /**\n * bbb\n */
        constructors
          synthetic @-1
      class B @79
        documentationComment: /// bbb\n/// ccc
        constructors
          synthetic @-1
      class C @122
        documentationComment: /**\n * ccc\n */
        constructors
          synthetic @-1
      class D @173
        documentationComment: /// ddd
        constructors
          synthetic @-1
      class E @207
        documentationComment: /**\n * aaa\n */
        constructors
          synthetic @-1
''');
  }

  test_class_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// first
/// second
/// third
class C {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @37
        documentationComment: /// first\n/// second\n/// third
        constructors
          synthetic @-1
''');
  }

  test_class_documented_with_references() async {
    var library = await checkLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @47
        documentationComment: /**\n * Docs referring to [D] and [E]\n */
        constructors
          synthetic @-1
      class D @59
        constructors
          synthetic @-1
      class E @70
        constructors
          synthetic @-1
''');
  }

  test_class_documented_with_windows_line_endings() async {
    var library = await checkLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @25
        documentationComment: /**\n * Docs\n */
        constructors
          synthetic @-1
''');
  }

  test_class_documented_withLeadingNotDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @66
        documentationComment: /**\n * Docs\n */
        constructors
          synthetic @-1
''');
  }

  test_class_documented_withMetadata() async {
    var library = await checkLibrary('''
/// Comment 1
/// Comment 2
@Annotation()
class BeforeMeta {}

/// Comment 1
/// Comment 2
@Annotation.named()
class BeforeMetaNamed {}

@Annotation()
/// Comment 1
/// Comment 2
class AfterMeta {}

/// Comment 1
@Annotation()
/// Comment 2
class AroundMeta {}

/// Doc comment.
@Annotation()
// Not doc comment.
class DocBeforeMetaNotDocAfter {}

class Annotation {
  const Annotation();
  const Annotation.named();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class BeforeMeta @48
        documentationComment: /// Comment 1\n/// Comment 2
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @39
              rightParenthesis: ) @40
            atSign: @ @28
            element: self::@class::Annotation::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::Annotation
              staticType: null
              token: Annotation @29
        constructors
          synthetic @-1
      class BeforeMetaNamed @117
        documentationComment: /// Comment 1\n/// Comment 2
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @108
              rightParenthesis: ) @109
            atSign: @ @91
            element: self::@class::Annotation::@constructor::named
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@class::Annotation::@constructor::named
                staticType: null
                token: named @103
              period: . @102
              prefix: SimpleIdentifier
                staticElement: self::@class::Annotation
                staticType: null
                token: Annotation @92
              staticElement: self::@class::Annotation::@constructor::named
              staticType: null
        constructors
          synthetic @-1
      class AfterMeta @185
        documentationComment: /// Comment 1\n/// Comment 2
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @148
              rightParenthesis: ) @149
            atSign: @ @137
            element: self::@class::Annotation::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::Annotation
              staticType: null
              token: Annotation @138
        constructors
          synthetic @-1
      class AroundMeta @247
        documentationComment: /// Comment 2
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @224
              rightParenthesis: ) @225
            atSign: @ @213
            element: self::@class::Annotation::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::Annotation
              staticType: null
              token: Annotation @214
        constructors
          synthetic @-1
      class DocBeforeMetaNotDocAfter @319
        documentationComment: /// Doc comment.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @290
              rightParenthesis: ) @291
            atSign: @ @279
            element: self::@class::Annotation::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::Annotation
              staticType: null
              token: Annotation @280
        constructors
          synthetic @-1
      class Annotation @354
        constructors
          const @375
          const named @408
            periodOffset: 407
            nameEnd: 413
''');
  }

  test_class_field_const() async {
    var library = await checkLibrary('class C { static const int i = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const i @27
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @31
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get i @-1
            returnType: int
''');
  }

  test_class_field_const_late() async {
    var library =
        await checkLibrary('class C { static late const int i = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static late const i @32
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @36
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get i @-1
            returnType: int
''');
  }

  test_class_field_final_withSetter() async {
    var library = await checkLibrary(r'''
class A {
  final int foo;
  A(this.foo);
  set foo(int newValue) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          final foo @22
            type: int
        constructors
          @29
            parameters
              requiredPositional final this.foo @36
                type: int
        accessors
          synthetic get foo @-1
            returnType: int
          set foo @48
            parameters
              requiredPositional newValue @56
                type: int
            returnType: void
''');
  }

  test_class_field_implicit_type() async {
    var library = await checkLibrary('class C { var x; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_field_implicit_type_late() async {
    var library = await checkLibrary('class C { late var x; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          late x @19
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_class_field_inheritedContextType_double() async {
    var library = await checkLibrary('''
abstract class A {
  const A();
  double get foo;
}
class B extends A {
  const B();
  final foo = 2;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic foo @-1
            type: double
        constructors
          const @27
        accessors
          abstract get foo @45
            returnType: double
      class B @58
        supertype: A
        fields
          final foo @93
            type: double
            constantInitializer
              IntegerLiteral
                literal: 2 @99
                staticType: double
        constructors
          const @80
        accessors
          synthetic get foo @-1
            returnType: double
''');
  }

  test_class_field_static() async {
    var library = await checkLibrary('class C { static int i; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static i @21
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get i @-1
            returnType: int
          synthetic static set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
''');
  }

  test_class_field_static_final_hasConstConstructor() async {
    var library = await checkLibrary('''
class C {
  static final f = 0;
  const C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static final f @25
            type: int
        constructors
          const @40
        accessors
          synthetic static get f @-1
            returnType: int
''');
  }

  test_class_field_static_late() async {
    var library = await checkLibrary('class C { static late int i; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static late i @26
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get i @-1
            returnType: int
          synthetic static set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
''');
  }

  test_class_fields() async {
    var library = await checkLibrary('class C { int i; int j; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          i @14
            type: int
          j @21
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get i @-1
            returnType: int
          synthetic set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
          synthetic get j @-1
            returnType: int
          synthetic set j @-1
            parameters
              requiredPositional _j @-1
                type: int
            returnType: void
''');
  }

  test_class_fields_late() async {
    var library = await checkLibrary('''
class C {
  late int foo;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          late foo @21
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
            returnType: void
''');
  }

  test_class_fields_late_final() async {
    var library = await checkLibrary('''
class C {
  late final int foo;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          late final foo @27
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
            returnType: void
''');
  }

  test_class_fields_late_final_initialized() async {
    var library = await checkLibrary('''
class C {
  late final int foo = 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          late final foo @27
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
''');
  }

  test_class_fields_late_inference_usingSuper_methodInvocation() async {
    var library = await checkLibrary('''
class A {
  int foo() => 0;
}

class B extends A {
  late var f = super.foo();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          foo @16
            returnType: int
      class B @37
        supertype: A
        fields
          late f @62
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
''');
  }

  test_class_fields_late_inference_usingSuper_propertyAccess() async {
    var library = await checkLibrary('''
class A {
  int get foo => 0;
}

class B extends A {
  late var f = super.foo;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          synthetic foo @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get foo @20
            returnType: int
      class B @39
        supertype: A
        fields
          late f @64
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
''');
  }

  test_class_getter_abstract() async {
    var library = await checkLibrary('abstract class C { int get x; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @27
            returnType: int
''');
  }

  test_class_getter_external() async {
    var library = await checkLibrary('class C { external int get x; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          external get x @27
            returnType: int
''');
  }

  test_class_getter_implicit_return_type() async {
    var library = await checkLibrary('class C { get x => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @14
            returnType: dynamic
''');
  }

  test_class_getter_native() async {
    var library = await checkLibrary('''
class C {
  int get x() native;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          external get x @20
            returnType: int
''');
  }

  test_class_getter_static() async {
    var library = await checkLibrary('class C { static int get x => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic static x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          static get x @25
            returnType: int
''');
  }

  test_class_getters() async {
    var library =
        await checkLibrary('class C { int get x => null; get y => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
          synthetic y @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @18
            returnType: int
          get y @33
            returnType: dynamic
''');
  }

  test_class_implicitField_getterFirst() async {
    var library = await checkLibrary('''
class C {
  int get x => 0;
  void set x(int value) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @20
            returnType: int
          set x @39
            parameters
              requiredPositional value @45
                type: int
            returnType: void
''');
  }

  test_class_implicitField_setterFirst() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  int get x => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set x @21
            parameters
              requiredPositional value @27
                type: int
            returnType: void
          get x @47
            returnType: int
''');
  }

  test_class_interfaces() async {
    var library = await checkLibrary('''
class C implements D, E {}
class D {}
class E {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        interfaces
          D
          E
        constructors
          synthetic @-1
      class D @33
        constructors
          synthetic @-1
      class E @44
        constructors
          synthetic @-1
''');
  }

  test_class_interfaces_Function() async {
    var library = await checkLibrary('''
class A {}
class B {}
class C implements A, Function, B {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @17
        constructors
          synthetic @-1
      class C @28
        interfaces
          A
          B
        constructors
          synthetic @-1
''');
  }

  test_class_interfaces_unresolved() async {
    var library = await checkLibrary(
        'class C implements X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        interfaces
          X
          Z
        constructors
          synthetic @-1
      class X @36
        constructors
          synthetic @-1
      class Z @47
        constructors
          synthetic @-1
''');
  }

  test_class_method_abstract() async {
    var library = await checkLibrary('abstract class C { f(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        constructors
          synthetic @-1
        methods
          abstract f @19
            returnType: dynamic
''');
  }

  test_class_method_external() async {
    var library = await checkLibrary('class C { external f(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          external f @19
            returnType: dynamic
''');
  }

  test_class_method_namedAsSupertype() async {
    var library = await checkLibrary(r'''
class A {}
class B extends A {
  void A() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @17
        supertype: A
        constructors
          synthetic @-1
        methods
          A @38
            returnType: void
''');
  }

  test_class_method_native() async {
    var library = await checkLibrary('''
class C {
  int m() native;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          external m @16
            returnType: int
''');
  }

  test_class_method_params() async {
    var library = await checkLibrary('class C { f(x, y) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @10
            parameters
              requiredPositional x @12
                type: dynamic
              requiredPositional y @15
                type: dynamic
            returnType: dynamic
''');
  }

  test_class_method_static() async {
    var library = await checkLibrary('class C { static f() {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          static f @17
            returnType: dynamic
''');
  }

  test_class_methods() async {
    var library = await checkLibrary('class C { f() {} g() {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @10
            returnType: dynamic
          g @17
            returnType: dynamic
''');
  }

  test_class_mixins() async {
    var library = await checkLibrary('''
class C extends D with E, F, G {}
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        mixins
          E
          F
          G
        constructors
          synthetic @-1
      class D @40
        constructors
          synthetic @-1
      class E @51
        constructors
          synthetic @-1
      class F @62
        constructors
          synthetic @-1
      class G @73
        constructors
          synthetic @-1
''');
  }

  test_class_mixins_generic() async {
    var library = await checkLibrary('''
class Z extends A with B<int>, C<double> {}
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class Z @6
        supertype: A
        mixins
          B<int>
          C<double>
        constructors
          synthetic @-1
      class A @50
        constructors
          synthetic @-1
      class B @61
        typeParameters
          covariant B1 @63
            defaultType: dynamic
        constructors
          synthetic @-1
      class C @76
        typeParameters
          covariant C1 @78
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_mixins_unresolved() async {
    var library = await checkLibrary(
        'class C extends Object with X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: Object
        mixins
          X
          Z
        constructors
          synthetic @-1
      class X @45
        constructors
          synthetic @-1
      class Z @56
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_circularity_via_typedef() async {
    // C's type parameter T is not simply bounded because its bound, F, expands
    // to `dynamic F(C)`, which refers to C.
    var library = await checkLibrary('''
class C<T extends F> {}
typedef F(C value);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: dynamic
            defaultType: dynamic
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased notSimplyBounded F @32
        aliasedType: dynamic Function(C<dynamic>)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional value @36
              type: C<dynamic>
          returnType: dynamic
''');
  }

  test_class_notSimplyBounded_circularity_with_type_params() async {
    // C's type parameter T is simply bounded because even though it refers to
    // C, it specifies a bound.
    var library = await checkLibrary('''
class C<T extends C<dynamic>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: C<dynamic>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_class() async {
    var library = await checkLibrary('''
class C<T extends D> {}
class D<T extends C> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: D<dynamic>
            defaultType: dynamic
        constructors
          synthetic @-1
      notSimplyBounded class D @30
        typeParameters
          covariant T @32
            bound: C<dynamic>
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_typedef_functionType() async {
    var library = await checkLibrary('''
typedef C<T extends D> = void Function();
typedef D<T extends C> = void Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded C @8
        typeParameters
          unrelated T @10
            bound: dynamic
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
      notSimplyBounded D @50
        typeParameters
          unrelated T @52
            bound: dynamic
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_class_notSimplyBounded_complex_by_cycle_typedef_interfaceType() async {
    var library = await checkLibrary('''
typedef C<T extends D> = List<T>;
typedef D<T extends C> = List<T>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded C @8
        typeParameters
          covariant T @10
            bound: dynamic
            defaultType: dynamic
        aliasedType: List<T>
      notSimplyBounded D @42
        typeParameters
          covariant T @44
            bound: dynamic
            defaultType: dynamic
        aliasedType: List<T>
''');
  }

  test_class_notSimplyBounded_complex_by_reference_to_cycle() async {
    var library = await checkLibrary('''
class C<T extends D> {}
class D<T extends D> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: D<dynamic>
            defaultType: D<dynamic>
        constructors
          synthetic @-1
      notSimplyBounded class D @30
        typeParameters
          covariant T @32
            bound: D<dynamic>
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_complex_by_use_of_parameter() async {
    var library = await checkLibrary('''
class C<T extends D<T>> {}
class D<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: D<T>
            defaultType: D<dynamic>
        constructors
          synthetic @-1
      class D @33
        typeParameters
          covariant T @35
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_dependency_with_type_params() async {
    // C's type parameter T is simply bounded because even though it refers to
    // non-simply-bounded type D, it specifies a bound.
    var library = await checkLibrary('''
class C<T extends D<dynamic>> {}
class D<T extends D<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: D<dynamic>
            defaultType: D<dynamic>
        constructors
          synthetic @-1
      notSimplyBounded class D @39
        typeParameters
          covariant T @41
            bound: D<T>
            defaultType: D<dynamic>
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_function_typed_bound_complex_via_parameter_type() async {
    var library = await checkLibrary('''
class C<T extends void Function(T)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: void Function(T)
            defaultType: void Function(Never)
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_function_typed_bound_complex_via_parameter_type_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class C<T extends void Function(T)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: void Function(T*)*
            defaultType: void Function(Null*)*
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_function_typed_bound_complex_via_return_type() async {
    var library = await checkLibrary('''
class C<T extends T Function()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: T Function()
            defaultType: dynamic Function()
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_function_typed_bound_simple() async {
    var library = await checkLibrary('''
class C<T extends void Function()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: void Function()
            defaultType: void Function()
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_refers_to_circular_typedef() async {
    // C's type parameter T has a bound of F, which is a circular typedef.  This
    // is illegal in Dart, but we need to make sure it doesn't lead to a crash
    // or infinite loop.
    var library = await checkLibrary('''
class C<T extends F> {}
typedef F(G value);
typedef G(F value);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: dynamic
            defaultType: dynamic
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased notSimplyBounded F @32
        aliasedType: dynamic Function(dynamic)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional value @36
              type: dynamic
          returnType: dynamic
      functionTypeAliasBased notSimplyBounded G @52
        aliasedType: dynamic Function(dynamic)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional value @56
              type: dynamic
          returnType: dynamic
''');
  }

  test_class_notSimplyBounded_self() async {
    var library = await checkLibrary('''
class C<T extends C> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: C<dynamic>
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_simple_because_non_generic() async {
    // If no type parameters are specified, then the class is simply bounded, so
    // there is no reason to assign it a slot.
    var library = await checkLibrary('''
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_simple_by_lack_of_cycles() async {
    var library = await checkLibrary('''
class C<T extends D> {}
class D<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: D<dynamic>
            defaultType: D<dynamic>
        constructors
          synthetic @-1
      class D @30
        typeParameters
          covariant T @32
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_notSimplyBounded_simple_by_syntax() async {
    // If no bounds are specified, then the class is simply bounded by syntax
    // alone, so there is no reason to assign it a slot.
    var library = await checkLibrary('''
class C<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_ref_nullability_none() async {
    var library = await checkLibrary('''
class C {}
C c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static c @13
        type: C
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
''');
  }

  test_class_ref_nullability_question() async {
    var library = await checkLibrary('''
class C {}
C? c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static c @14
        type: C?
    accessors
      synthetic static get c @-1
        returnType: C?
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C?
        returnType: void
''');
  }

  test_class_ref_nullability_star() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class C {}
C c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static c @13
        type: C*
    accessors
      synthetic static get c @-1
        returnType: C*
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C*
        returnType: void
''');
  }

  test_class_setter_abstract() async {
    var library =
        await checkLibrary('abstract class C { void set x(int value); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @28
            parameters
              requiredPositional value @34
                type: int
            returnType: void
''');
  }

  test_class_setter_external() async {
    var library =
        await checkLibrary('class C { external void set x(int value); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          external set x @28
            parameters
              requiredPositional value @34
                type: int
            returnType: void
''');
  }

  test_class_setter_implicit_param_type() async {
    var library = await checkLibrary('class C { void set x(value) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @19
            parameters
              requiredPositional value @21
                type: dynamic
            returnType: void
''');
  }

  test_class_setter_implicit_return_type() async {
    var library = await checkLibrary('class C { set x(int value) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set x @14
            parameters
              requiredPositional value @20
                type: int
            returnType: void
''');
  }

  test_class_setter_invalid_named_parameter() async {
    var library = await checkLibrary('class C { void set x({a}) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @19
            parameters
              optionalNamed a @22
                type: dynamic
            returnType: void
''');
  }

  test_class_setter_invalid_no_parameter() async {
    var library = await checkLibrary('class C { void set x() {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @19
            returnType: void
''');
  }

  test_class_setter_invalid_optional_parameter() async {
    var library = await checkLibrary('class C { void set x([a]) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @19
            parameters
              optionalPositional a @22
                type: dynamic
            returnType: void
''');
  }

  test_class_setter_invalid_too_many_parameters() async {
    var library = await checkLibrary('class C { void set x(a, b) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @19
            parameters
              requiredPositional a @21
                type: dynamic
              requiredPositional b @24
                type: dynamic
            returnType: void
''');
  }

  test_class_setter_native() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) native;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          external set x @21
            parameters
              requiredPositional value @27
                type: int
            returnType: void
''');
  }

  test_class_setter_static() async {
    var library =
        await checkLibrary('class C { static void set x(int value) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic static x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          static set x @26
            parameters
              requiredPositional value @32
                type: int
            returnType: void
''');
  }

  test_class_setters() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  set y(value) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
          synthetic y @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @21
            parameters
              requiredPositional value @27
                type: int
            returnType: void
          set y @43
            parameters
              requiredPositional value @45
                type: dynamic
            returnType: void
''');
  }

  test_class_supertype() async {
    var library = await checkLibrary('''
class C extends D {}
class D {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        constructors
          synthetic @-1
      class D @27
        constructors
          synthetic @-1
''');
  }

  test_class_supertype_typeArguments() async {
    var library = await checkLibrary('''
class C extends D<int, double> {}
class D<T1, T2> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D<int, double>
        constructors
          synthetic @-1
      class D @40
        typeParameters
          covariant T1 @42
            defaultType: dynamic
          covariant T2 @46
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_supertype_typeArguments_self() async {
    var library = await checkLibrary('''
class A<T> {}
class B extends A<B> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @20
        supertype: A<B>
        constructors
          synthetic @-1
''');
  }

  test_class_supertype_unresolved() async {
    var library = await checkLibrary('class C extends D {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters_bound() async {
    var library = await checkLibrary('''
class C<T extends Object, U extends D> {}
class D {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: Object
            defaultType: Object
          covariant U @26
            bound: D
            defaultType: D
        constructors
          synthetic @-1
      class D @48
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters_cycle_1of1() async {
    var library = await checkLibrary('class C<T extends T> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: dynamic
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters_cycle_2of3() async {
    var library = await checkLibrary(r'''
class C<T extends V, U, V extends T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: dynamic
            defaultType: dynamic
          covariant U @21
            defaultType: dynamic
          covariant V @24
            bound: dynamic
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('class C<T extends List<U>, U> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: List<U>
            defaultType: List<dynamic>
          covariant U @27
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('class C<T extends U, U> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: U
            defaultType: dynamic
          covariant U @21
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_cycle_genericFunctionType() async {
    var library = await checkLibrary(r'''
class A<T extends void Function(A)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant T @8
            bound: void Function(A<dynamic>)
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_cycle_genericFunctionType2() async {
    var library = await checkLibrary(r'''
class C<T extends void Function<U extends C>()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: void Function<U extends C<dynamic>>()
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_contravariant_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary(r'''
typedef F<X> = void Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @40
        typeParameters
          covariant X @42
            bound: void Function(X*)*
              aliasElement: self::@typeAlias::F
              aliasArguments
                X*
            defaultType: void Function(Null*)*
              aliasElement: self::@typeAlias::F
              aliasArguments
                Null*
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          contravariant X @10
            defaultType: dynamic
        aliasedType: void Function(X*)*
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: X*
          returnType: void
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_contravariant_nullSafe() async {
    var library = await checkLibrary(r'''
typedef F<X> = void Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @40
        typeParameters
          covariant X @42
            bound: void Function(X)
              aliasElement: self::@typeAlias::F
              aliasArguments
                X
            defaultType: void Function(Never)
              aliasElement: self::@typeAlias::F
              aliasArguments
                Never
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          contravariant X @10
            defaultType: dynamic
        aliasedType: void Function(X)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: X
          returnType: void
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_covariant_nullSafe() async {
    var library = await checkLibrary(r'''
typedef F<X> = X Function();

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @36
        typeParameters
          covariant X @38
            bound: X Function()
              aliasElement: self::@typeAlias::F
              aliasArguments
                X
            defaultType: dynamic Function()
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          covariant X @10
            defaultType: dynamic
        aliasedType: X Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: X
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_invariant_legacy() async {
    var library = await checkLibrary(r'''
typedef F<X> = X Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @37
        typeParameters
          covariant X @39
            bound: X Function(X)
              aliasElement: self::@typeAlias::F
              aliasArguments
                X
            defaultType: dynamic Function(dynamic)
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          invariant X @10
            defaultType: dynamic
        aliasedType: X Function(X)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: X
          returnType: X
''');
  }

  test_class_typeParameters_defaultType_functionTypeAlias_invariant_nullSafe() async {
    var library = await checkLibrary(r'''
typedef F<X> = X Function(X);

class A<X extends F<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @37
        typeParameters
          covariant X @39
            bound: X Function(X)
              aliasElement: self::@typeAlias::F
              aliasArguments
                X
            defaultType: dynamic Function(dynamic)
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          invariant X @10
            defaultType: dynamic
        aliasedType: X Function(X)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: X
          returnType: X
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_both_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary(r'''
class A<X extends X Function(X)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: X* Function(X*)*
            defaultType: dynamic Function(Null*)*
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_both_nullSafe() async {
    var library = await checkLibrary(r'''
class A<X extends X Function(X)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: X Function(X)
            defaultType: dynamic Function(Never)
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_contravariant_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary(r'''
class A<X extends void Function(X)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: void Function(X*)*
            defaultType: void Function(Null*)*
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_contravariant_nullSafe() async {
    var library = await checkLibrary(r'''
class A<X extends void Function(X)> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: void Function(X)
            defaultType: void Function(Never)
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_covariant_legacy() async {
    var library = await checkLibrary(r'''
class A<X extends X Function()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: X Function()
            defaultType: dynamic Function()
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_genericFunctionType_covariant_nullSafe() async {
    var library = await checkLibrary(r'''
class A<X extends X Function()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class A @6
        typeParameters
          covariant X @8
            bound: X Function()
            defaultType: dynamic Function()
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_defaultType_typeAlias_interface_contravariant() async {
    var library = await checkLibrary(r'''
typedef A<X> = List<void Function(X)>;

class B<X extends A<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class B @46
        typeParameters
          covariant X @48
            bound: List<void Function(X)>
              aliasElement: self::@typeAlias::A
              aliasArguments
                X
            defaultType: List<void Function(Never)>
              aliasElement: self::@typeAlias::A
              aliasArguments
                Never
        constructors
          synthetic @-1
    typeAliases
      A @8
        typeParameters
          contravariant X @10
            defaultType: dynamic
        aliasedType: List<void Function(X)>
''');
  }

  test_class_typeParameters_defaultType_typeAlias_interface_covariant() async {
    var library = await checkLibrary(r'''
typedef A<X> = Map<X, int>;

class B<X extends A<X>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class B @35
        typeParameters
          covariant X @37
            bound: Map<X, int>
              aliasElement: self::@typeAlias::A
              aliasArguments
                X
            defaultType: Map<dynamic, int>
              aliasElement: self::@typeAlias::A
              aliasArguments
                dynamic
        constructors
          synthetic @-1
    typeAliases
      A @8
        typeParameters
          covariant X @10
            defaultType: dynamic
        aliasedType: Map<X, int>
''');
  }

  test_class_typeParameters_variance_contravariant() async {
    var library = await checkLibrary('class C<in T> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          contravariant T @11
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_variance_covariant() async {
    var library = await checkLibrary('class C<out T> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @12
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_variance_invariant() async {
    var library = await checkLibrary('class C<inout T> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          invariant T @14
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_class_typeParameters_variance_multiple() async {
    var library = await checkLibrary('class C<inout T, in U, out V> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          invariant T @14
            defaultType: dynamic
          contravariant U @20
            defaultType: dynamic
          covariant V @27
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_classes() async {
    var library = await checkLibrary('class C {} class D {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
      class D @17
        constructors
          synthetic @-1
''');
  }

  test_closure_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('''
f() {
  print(() {});
  print(() => () => 0);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        returnType: dynamic
''');
  }

  test_closure_generic() async {
    var library = await checkLibrary(r'''
final f = <U, V>(U x, V y) => y;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final f @6
        type: V Function<U, V>(U, V)
    accessors
      synthetic static get f @-1
        returnType: V Function<U, V>(U, V)
''');
  }

  test_closure_in_variable_declaration_in_part() async {
    addSource('/a.dart', 'part of lib; final f = (int i) => i.toDouble();');
    var library = await checkLibrary('''
library lib;
part "a.dart";
''');
    checkElementText(library, r'''
library
  name: lib
  nameOffset: 8
  definingUnit
  parts
    a.dart
      topLevelVariables
        static final f @19
          type: double Function(int)
      accessors
        synthetic static get f @-1
          returnType: double Function(int)
''');
  }

  test_codeRange_class() async {
    var library = await checkLibrary('''
class Raw {}

/// Comment 1.
/// Comment 2.
class HasDocComment {}

@Object()
class HasAnnotation {}

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment {}

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation {}

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class Raw @6
        codeOffset: 0
        codeLength: 12
        constructors
          synthetic @-1
      class HasDocComment @50
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 14
        codeLength: 52
        constructors
          synthetic @-1
      class HasAnnotation @84
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @75
              rightParenthesis: ) @76
            atSign: @ @68
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @69
        codeOffset: 68
        codeLength: 32
        constructors
          synthetic @-1
      class AnnotationThenComment @148
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @109
              rightParenthesis: ) @110
            atSign: @ @102
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @103
        codeOffset: 102
        codeLength: 70
        constructors
          synthetic @-1
      class CommentThenAnnotation @220
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @211
              rightParenthesis: ) @212
            atSign: @ @204
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @205
        codeOffset: 174
        codeLength: 70
        constructors
          synthetic @-1
      class CommentAroundAnnotation @292
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @268
              rightParenthesis: ) @269
            atSign: @ @261
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @262
        codeOffset: 261
        codeLength: 57
        constructors
          synthetic @-1
''',
        withCodeRanges: true);
  }

  test_codeRange_class_namedMixin() async {
    var library = await checkLibrary('''
class A {}

class B {}

class Raw = Object with A, B;

/// Comment 1.
/// Comment 2.
class HasDocComment = Object with A, B;

@Object()
class HasAnnotation = Object with A, B;

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment = Object with A, B;

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation = Object with A, B;

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation = Object with A, B;
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class A @6
        codeOffset: 0
        codeLength: 10
        constructors
          synthetic @-1
      class B @18
        codeOffset: 12
        codeLength: 10
        constructors
          synthetic @-1
      class alias Raw @30
        codeOffset: 24
        codeLength: 29
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
      class alias HasDocComment @91
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 55
        codeLength: 69
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
      class alias HasAnnotation @142
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @133
              rightParenthesis: ) @134
            atSign: @ @126
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @127
        codeOffset: 126
        codeLength: 49
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
      class alias AnnotationThenComment @223
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @184
              rightParenthesis: ) @185
            atSign: @ @177
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @178
        codeOffset: 177
        codeLength: 87
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
      class alias CommentThenAnnotation @312
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @303
              rightParenthesis: ) @304
            atSign: @ @296
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @297
        codeOffset: 266
        codeLength: 87
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
      class alias CommentAroundAnnotation @401
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @377
              rightParenthesis: ) @378
            atSign: @ @370
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @371
        codeOffset: 370
        codeLength: 74
        supertype: Object
        mixins
          A
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
''',
        withCodeRanges: true);
  }

  test_codeRange_constructor() async {
    var library = await checkLibrary('''
class C {
  C();

  C.raw() {}

  /// Comment 1.
  /// Comment 2.
  C.hasDocComment() {}

  @Object()
  C.hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  C.annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  C.commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  C.commentAroundAnnotation() {}
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        codeOffset: 0
        codeLength: 362
        constructors
          @12
            codeOffset: 12
            codeLength: 4
          raw @22
            codeOffset: 20
            codeLength: 10
            periodOffset: 21
            nameEnd: 25
          hasDocComment @70
            documentationComment: /// Comment 1.\n/// Comment 2.
            codeOffset: 34
            codeLength: 54
            periodOffset: 69
            nameEnd: 83
          hasAnnotation @106
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @99
                  rightParenthesis: ) @100
                atSign: @ @92
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @93
            codeOffset: 92
            codeLength: 32
            periodOffset: 105
            nameEnd: 119
          annotationThenComment @176
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @135
                  rightParenthesis: ) @136
                atSign: @ @128
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @129
            codeOffset: 128
            codeLength: 74
            periodOffset: 175
            nameEnd: 197
          commentThenAnnotation @254
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @247
                  rightParenthesis: ) @248
                atSign: @ @240
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @241
            codeOffset: 206
            codeLength: 74
            periodOffset: 253
            nameEnd: 275
          commentAroundAnnotation @332
            documentationComment: /// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @308
                  rightParenthesis: ) @309
                atSign: @ @301
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @302
            codeOffset: 301
            codeLength: 59
            periodOffset: 331
            nameEnd: 355
''',
        withCodeRanges: true);
  }

  test_codeRange_constructor_factory() async {
    var library = await checkLibrary('''
class C {
  factory C() => throw 0;

  factory C.raw() => throw 0;

  /// Comment 1.
  /// Comment 2.
  factory C.hasDocComment() => throw 0;

  @Object()
  factory C.hasAnnotation() => throw 0;

  @Object()
  /// Comment 1.
  /// Comment 2.
  factory C.annotationThenComment() => throw 0;

  /// Comment 1.
  /// Comment 2.
  @Object()
  factory C.commentThenAnnotation() => throw 0;

  /// Comment 1.
  @Object()
  /// Comment 2.
  factory C.commentAroundAnnotation() => throw 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        codeOffset: 0
        codeLength: 483
        constructors
          factory @20
            codeOffset: 12
            codeLength: 23
          factory raw @49
            codeOffset: 39
            codeLength: 27
            periodOffset: 48
            nameEnd: 52
          factory hasDocComment @114
            documentationComment: /// Comment 1.\n/// Comment 2.
            codeOffset: 70
            codeLength: 71
            periodOffset: 113
            nameEnd: 127
          factory hasAnnotation @167
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @152
                  rightParenthesis: ) @153
                atSign: @ @145
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @146
            codeOffset: 145
            codeLength: 49
            periodOffset: 166
            nameEnd: 180
          factory annotationThenComment @254
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @205
                  rightParenthesis: ) @206
                atSign: @ @198
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @199
            codeOffset: 198
            codeLength: 91
            periodOffset: 253
            nameEnd: 275
          factory commentThenAnnotation @349
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @334
                  rightParenthesis: ) @335
                atSign: @ @327
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @328
            codeOffset: 293
            codeLength: 91
            periodOffset: 348
            nameEnd: 370
          factory commentAroundAnnotation @444
            documentationComment: /// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @412
                  rightParenthesis: ) @413
                atSign: @ @405
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @406
            codeOffset: 405
            codeLength: 76
            periodOffset: 443
            nameEnd: 467
''',
        withCodeRanges: true);
  }

  test_codeRange_enum() async {
    var library = await checkLibrary('''
enum E {
  aaa, bbb, ccc
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    enums
      enum E @5
        codeOffset: 0
        codeLength: 26
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const aaa @11
            codeOffset: 11
            codeLength: 3
            type: E
          static const bbb @16
            codeOffset: 16
            codeLength: 3
            type: E
          static const ccc @21
            codeOffset: 21
            codeLength: 3
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get aaa @-1
            returnType: E
          synthetic static get bbb @-1
            returnType: E
          synthetic static get ccc @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''',
        withCodeRanges: true);
  }

  test_codeRange_extensions() async {
    var library = await checkLibrary('''
class A {}

extension Raw on A {}

/// Comment 1.
/// Comment 2.
extension HasDocComment on A {}

@Object()
extension HasAnnotation on A {}

@Object()
/// Comment 1.
/// Comment 2.
extension AnnotationThenComment on A {}

/// Comment 1.
/// Comment 2.
@Object()
extension CommentThenAnnotation on A {}

/// Comment 1.
@Object()
/// Comment 2.
extension CommentAroundAnnotation on A {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class A @6
        codeOffset: 0
        codeLength: 10
        constructors
          synthetic @-1
    extensions
      Raw @22
        codeOffset: 12
        codeLength: 21
        extendedType: A
      HasDocComment @75
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 35
        codeLength: 61
        extendedType: A
      HasAnnotation @118
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @105
              rightParenthesis: ) @106
            atSign: @ @98
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @99
        codeOffset: 98
        codeLength: 41
        extendedType: A
      AnnotationThenComment @191
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @148
              rightParenthesis: ) @149
            atSign: @ @141
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @142
        codeOffset: 141
        codeLength: 79
        extendedType: A
      CommentThenAnnotation @272
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @259
              rightParenthesis: ) @260
            atSign: @ @252
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @253
        codeOffset: 222
        codeLength: 79
        extendedType: A
      CommentAroundAnnotation @353
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @325
              rightParenthesis: ) @326
            atSign: @ @318
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @319
        codeOffset: 318
        codeLength: 66
        extendedType: A
''',
        withCodeRanges: true);
  }

  test_codeRange_field() async {
    var library = await checkLibrary('''
class C {
  int withInit = 1;

  int withoutInit;

  int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        codeOffset: 0
        codeLength: 115
        fields
          withInit @16
            codeOffset: 12
            codeLength: 16
            type: int
          withoutInit @37
            codeOffset: 33
            codeLength: 15
            type: int
          multiWithInit @57
            codeOffset: 53
            codeLength: 21
            type: int
          multiWithoutInit @76
            codeOffset: 76
            codeLength: 16
            type: int
          multiWithInit2 @94
            codeOffset: 94
            codeLength: 18
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get withInit @-1
            returnType: int
          synthetic set withInit @-1
            parameters
              requiredPositional _withInit @-1
                type: int
            returnType: void
          synthetic get withoutInit @-1
            returnType: int
          synthetic set withoutInit @-1
            parameters
              requiredPositional _withoutInit @-1
                type: int
            returnType: void
          synthetic get multiWithInit @-1
            returnType: int
          synthetic set multiWithInit @-1
            parameters
              requiredPositional _multiWithInit @-1
                type: int
            returnType: void
          synthetic get multiWithoutInit @-1
            returnType: int
          synthetic set multiWithoutInit @-1
            parameters
              requiredPositional _multiWithoutInit @-1
                type: int
            returnType: void
          synthetic get multiWithInit2 @-1
            returnType: int
          synthetic set multiWithInit2 @-1
            parameters
              requiredPositional _multiWithInit2 @-1
                type: int
            returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_field_annotations() async {
    var library = await checkLibrary('''
class C {
  /// Comment 1.
  /// Comment 2.
  int hasDocComment, hasDocComment2;

  @Object()
  int hasAnnotation, hasAnnotation2;

  @Object()
  /// Comment 1.
  /// Comment 2.
  int annotationThenComment, annotationThenComment2;

  /// Comment 1.
  /// Comment 2.
  @Object()
  int commentThenAnnotation, commentThenAnnotation2;

  /// Comment 1.
  @Object()
  /// Comment 2.
  int commentAroundAnnotation, commentAroundAnnotation2;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        codeOffset: 0
        codeLength: 436
        fields
          hasDocComment @50
            documentationComment: /// Comment 1.\n/// Comment 2.
            codeOffset: 12
            codeLength: 51
            type: int
          hasDocComment2 @65
            documentationComment: /// Comment 1.\n/// Comment 2.
            codeOffset: 65
            codeLength: 14
            type: int
          hasAnnotation @100
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @91
                  rightParenthesis: ) @92
                atSign: @ @84
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @85
            codeOffset: 84
            codeLength: 29
            type: int
          hasAnnotation2 @115
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @91
                  rightParenthesis: ) @92
                atSign: @ @84
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @85
            codeOffset: 115
            codeLength: 14
            type: int
          annotationThenComment @184
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @141
                  rightParenthesis: ) @142
                atSign: @ @134
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @135
            codeOffset: 134
            codeLength: 71
            type: int
          annotationThenComment2 @207
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @141
                  rightParenthesis: ) @142
                atSign: @ @134
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @135
            codeOffset: 207
            codeLength: 22
            type: int
          commentThenAnnotation @284
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @275
                  rightParenthesis: ) @276
                atSign: @ @268
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @269
            codeOffset: 234
            codeLength: 71
            type: int
          commentThenAnnotation2 @307
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @275
                  rightParenthesis: ) @276
                atSign: @ @268
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @269
            codeOffset: 307
            codeLength: 22
            type: int
          commentAroundAnnotation @384
            documentationComment: /// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @358
                  rightParenthesis: ) @359
                atSign: @ @351
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @352
            codeOffset: 351
            codeLength: 56
            type: int
          commentAroundAnnotation2 @409
            documentationComment: /// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @358
                  rightParenthesis: ) @359
                atSign: @ @351
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @352
            codeOffset: 409
            codeLength: 24
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get hasDocComment @-1
            returnType: int
          synthetic set hasDocComment @-1
            parameters
              requiredPositional _hasDocComment @-1
                type: int
            returnType: void
          synthetic get hasDocComment2 @-1
            returnType: int
          synthetic set hasDocComment2 @-1
            parameters
              requiredPositional _hasDocComment2 @-1
                type: int
            returnType: void
          synthetic get hasAnnotation @-1
            returnType: int
          synthetic set hasAnnotation @-1
            parameters
              requiredPositional _hasAnnotation @-1
                type: int
            returnType: void
          synthetic get hasAnnotation2 @-1
            returnType: int
          synthetic set hasAnnotation2 @-1
            parameters
              requiredPositional _hasAnnotation2 @-1
                type: int
            returnType: void
          synthetic get annotationThenComment @-1
            returnType: int
          synthetic set annotationThenComment @-1
            parameters
              requiredPositional _annotationThenComment @-1
                type: int
            returnType: void
          synthetic get annotationThenComment2 @-1
            returnType: int
          synthetic set annotationThenComment2 @-1
            parameters
              requiredPositional _annotationThenComment2 @-1
                type: int
            returnType: void
          synthetic get commentThenAnnotation @-1
            returnType: int
          synthetic set commentThenAnnotation @-1
            parameters
              requiredPositional _commentThenAnnotation @-1
                type: int
            returnType: void
          synthetic get commentThenAnnotation2 @-1
            returnType: int
          synthetic set commentThenAnnotation2 @-1
            parameters
              requiredPositional _commentThenAnnotation2 @-1
                type: int
            returnType: void
          synthetic get commentAroundAnnotation @-1
            returnType: int
          synthetic set commentAroundAnnotation @-1
            parameters
              requiredPositional _commentAroundAnnotation @-1
                type: int
            returnType: void
          synthetic get commentAroundAnnotation2 @-1
            returnType: int
          synthetic set commentAroundAnnotation2 @-1
            parameters
              requiredPositional _commentAroundAnnotation2 @-1
                type: int
            returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_function() async {
    var library = await checkLibrary('''
void raw() {}

/// Comment 1.
/// Comment 2.
void hasDocComment() {}

@Object()
void hasAnnotation() {}

@Object()
/// Comment 1.
/// Comment 2.
void annotationThenComment() {}

/// Comment 1.
/// Comment 2.
@Object()
void commentThenAnnotation() {}

/// Comment 1.
@Object()
/// Comment 2.
void commentAroundAnnotation() {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    functions
      raw @5
        codeOffset: 0
        codeLength: 13
        returnType: void
      hasDocComment @50
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 15
        codeLength: 53
        returnType: void
      hasAnnotation @85
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @77
              rightParenthesis: ) @78
            atSign: @ @70
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @71
        codeOffset: 70
        codeLength: 33
        returnType: void
      annotationThenComment @150
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @112
              rightParenthesis: ) @113
            atSign: @ @105
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @106
        codeOffset: 105
        codeLength: 71
        returnType: void
      commentThenAnnotation @223
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @215
              rightParenthesis: ) @216
            atSign: @ @208
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @209
        codeOffset: 178
        codeLength: 71
        returnType: void
      commentAroundAnnotation @296
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @273
              rightParenthesis: ) @274
            atSign: @ @266
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @267
        codeOffset: 266
        codeLength: 58
        returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_functionTypeAlias() async {
    var library = await checkLibrary('''
typedef Raw();

/// Comment 1.
/// Comment 2.
typedef HasDocComment();

@Object()
typedef HasAnnotation();

@Object()
/// Comment 1.
/// Comment 2.
typedef AnnotationThenComment();

/// Comment 1.
/// Comment 2.
@Object()
typedef CommentThenAnnotation();

/// Comment 1.
@Object()
/// Comment 2.
typedef CommentAroundAnnotation();
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased Raw @8
        codeOffset: 0
        codeLength: 14
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      functionTypeAliasBased HasDocComment @54
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 16
        codeLength: 54
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      functionTypeAliasBased HasAnnotation @90
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @79
              rightParenthesis: ) @80
            atSign: @ @72
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @73
        codeOffset: 72
        codeLength: 34
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      functionTypeAliasBased AnnotationThenComment @156
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @115
              rightParenthesis: ) @116
            atSign: @ @108
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @109
        codeOffset: 108
        codeLength: 72
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      functionTypeAliasBased CommentThenAnnotation @230
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @219
              rightParenthesis: ) @220
            atSign: @ @212
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @213
        codeOffset: 182
        codeLength: 72
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      functionTypeAliasBased CommentAroundAnnotation @304
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @278
              rightParenthesis: ) @279
            atSign: @ @271
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @272
        codeOffset: 271
        codeLength: 59
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''',
        withCodeRanges: true);
  }

  test_codeRange_genericTypeAlias() async {
    var library = await checkLibrary('''
typedef Raw = Function();

/// Comment 1.
/// Comment 2.
typedef HasDocComment = Function();

@Object()
typedef HasAnnotation = Function();

@Object()
/// Comment 1.
/// Comment 2.
typedef AnnotationThenComment = Function();

/// Comment 1.
/// Comment 2.
@Object()
typedef CommentThenAnnotation = Function();

/// Comment 1.
@Object()
/// Comment 2.
typedef CommentAroundAnnotation = Function();
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    typeAliases
      Raw @8
        codeOffset: 0
        codeLength: 25
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      HasDocComment @65
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 27
        codeLength: 65
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      HasAnnotation @112
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @101
              rightParenthesis: ) @102
            atSign: @ @94
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @95
        codeOffset: 94
        codeLength: 45
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      AnnotationThenComment @189
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @148
              rightParenthesis: ) @149
            atSign: @ @141
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @142
        codeOffset: 141
        codeLength: 83
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      CommentThenAnnotation @274
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @263
              rightParenthesis: ) @264
            atSign: @ @256
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @257
        codeOffset: 226
        codeLength: 83
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      CommentAroundAnnotation @359
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @333
              rightParenthesis: ) @334
            atSign: @ @326
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @327
        codeOffset: 326
        codeLength: 70
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''',
        withCodeRanges: true);
  }

  test_codeRange_method() async {
    var library = await checkLibrary('''
class C {
  void raw() {}

  /// Comment 1.
  /// Comment 2.
  void hasDocComment() {}

  @Object()
  void hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  void annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  void commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  void commentAroundAnnotation() {}
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        codeOffset: 0
        codeLength: 372
        constructors
          synthetic @-1
        methods
          raw @17
            codeOffset: 12
            codeLength: 13
            returnType: void
          hasDocComment @68
            documentationComment: /// Comment 1.\n/// Comment 2.
            codeOffset: 29
            codeLength: 57
            returnType: void
          hasAnnotation @107
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @97
                  rightParenthesis: ) @98
                atSign: @ @90
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @91
            codeOffset: 90
            codeLength: 35
            returnType: void
          annotationThenComment @180
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @136
                  rightParenthesis: ) @137
                atSign: @ @129
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @130
            codeOffset: 129
            codeLength: 77
            returnType: void
          commentThenAnnotation @261
            documentationComment: /// Comment 1.\n/// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @251
                  rightParenthesis: ) @252
                atSign: @ @244
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @245
            codeOffset: 210
            codeLength: 77
            returnType: void
          commentAroundAnnotation @342
            documentationComment: /// Comment 2.
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @315
                  rightParenthesis: ) @316
                atSign: @ @308
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @309
            codeOffset: 308
            codeLength: 62
            returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_parameter() async {
    var library = await checkLibrary('''
main({int a = 1, int b, int c = 2}) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      main @0
        parameters
          optionalNamed a @10
            type: int
            constantInitializer
              IntegerLiteral
                literal: 1 @14
                staticType: int
          optionalNamed b @21
            type: int
          optionalNamed c @28
            type: int
            constantInitializer
              IntegerLiteral
                literal: 2 @32
                staticType: int
        returnType: dynamic
''');
  }

  test_codeRange_parameter_annotations() async {
    var library = await checkLibrary('''
main(@Object() int a, int b, @Object() int c) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      main @0
        parameters
          requiredPositional a @19
            type: int
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @12
                  rightParenthesis: ) @13
                atSign: @ @5
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @6
          requiredPositional b @26
            type: int
          requiredPositional c @43
            type: int
            metadata
              Annotation
                arguments: ArgumentList
                  leftParenthesis: ( @36
                  rightParenthesis: ) @37
                atSign: @ @29
                element: dart:core::@class::Object::@constructor::•
                name: SimpleIdentifier
                  staticElement: dart:core::@class::Object
                  staticType: null
                  token: Object @30
        returnType: dynamic
''');
  }

  test_codeRange_topLevelVariable() async {
    var library = await checkLibrary('''
int withInit = 1 + 2 * 3;

int withoutInit;

int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3;
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      static withInit @4
        codeOffset: 0
        codeLength: 24
        type: int
      static withoutInit @31
        codeOffset: 27
        codeLength: 15
        type: int
      static multiWithInit @49
        codeOffset: 45
        codeLength: 21
        type: int
      static multiWithoutInit @68
        codeOffset: 68
        codeLength: 16
        type: int
      static multiWithInit2 @86
        codeOffset: 86
        codeLength: 18
        type: int
    accessors
      synthetic static get withInit @-1
        returnType: int
      synthetic static set withInit @-1
        parameters
          requiredPositional _withInit @-1
            type: int
        returnType: void
      synthetic static get withoutInit @-1
        returnType: int
      synthetic static set withoutInit @-1
        parameters
          requiredPositional _withoutInit @-1
            type: int
        returnType: void
      synthetic static get multiWithInit @-1
        returnType: int
      synthetic static set multiWithInit @-1
        parameters
          requiredPositional _multiWithInit @-1
            type: int
        returnType: void
      synthetic static get multiWithoutInit @-1
        returnType: int
      synthetic static set multiWithoutInit @-1
        parameters
          requiredPositional _multiWithoutInit @-1
            type: int
        returnType: void
      synthetic static get multiWithInit2 @-1
        returnType: int
      synthetic static set multiWithInit2 @-1
        parameters
          requiredPositional _multiWithInit2 @-1
            type: int
        returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_topLevelVariable_annotations() async {
    var library = await checkLibrary('''
/// Comment 1.
/// Comment 2.
int hasDocComment, hasDocComment2;

@Object()
int hasAnnotation, hasAnnotation2;

@Object()
/// Comment 1.
/// Comment 2.
int annotationThenComment, annotationThenComment2;

/// Comment 1.
/// Comment 2.
@Object()
int commentThenAnnotation, commentThenAnnotation2;

/// Comment 1.
@Object()
/// Comment 2.
int commentAroundAnnotation, commentAroundAnnotation2;
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      static hasDocComment @34
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 0
        codeLength: 47
        type: int
      static hasDocComment2 @49
        documentationComment: /// Comment 1.\n/// Comment 2.
        codeOffset: 49
        codeLength: 14
        type: int
      static hasAnnotation @80
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @73
              rightParenthesis: ) @74
            atSign: @ @66
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @67
        codeOffset: 66
        codeLength: 27
        type: int
      static hasAnnotation2 @95
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @73
              rightParenthesis: ) @74
            atSign: @ @66
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @67
        codeOffset: 95
        codeLength: 14
        type: int
      static annotationThenComment @156
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @119
              rightParenthesis: ) @120
            atSign: @ @112
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @113
        codeOffset: 112
        codeLength: 65
        type: int
      static annotationThenComment2 @179
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @119
              rightParenthesis: ) @120
            atSign: @ @112
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @113
        codeOffset: 179
        codeLength: 22
        type: int
      static commentThenAnnotation @248
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @241
              rightParenthesis: ) @242
            atSign: @ @234
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @235
        codeOffset: 204
        codeLength: 65
        type: int
      static commentThenAnnotation2 @271
        documentationComment: /// Comment 1.\n/// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @241
              rightParenthesis: ) @242
            atSign: @ @234
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @235
        codeOffset: 271
        codeLength: 22
        type: int
      static commentAroundAnnotation @340
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @318
              rightParenthesis: ) @319
            atSign: @ @311
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @312
        codeOffset: 311
        codeLength: 52
        type: int
      static commentAroundAnnotation2 @365
        documentationComment: /// Comment 2.
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @318
              rightParenthesis: ) @319
            atSign: @ @311
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @312
        codeOffset: 365
        codeLength: 24
        type: int
    accessors
      synthetic static get hasDocComment @-1
        returnType: int
      synthetic static set hasDocComment @-1
        parameters
          requiredPositional _hasDocComment @-1
            type: int
        returnType: void
      synthetic static get hasDocComment2 @-1
        returnType: int
      synthetic static set hasDocComment2 @-1
        parameters
          requiredPositional _hasDocComment2 @-1
            type: int
        returnType: void
      synthetic static get hasAnnotation @-1
        returnType: int
      synthetic static set hasAnnotation @-1
        parameters
          requiredPositional _hasAnnotation @-1
            type: int
        returnType: void
      synthetic static get hasAnnotation2 @-1
        returnType: int
      synthetic static set hasAnnotation2 @-1
        parameters
          requiredPositional _hasAnnotation2 @-1
            type: int
        returnType: void
      synthetic static get annotationThenComment @-1
        returnType: int
      synthetic static set annotationThenComment @-1
        parameters
          requiredPositional _annotationThenComment @-1
            type: int
        returnType: void
      synthetic static get annotationThenComment2 @-1
        returnType: int
      synthetic static set annotationThenComment2 @-1
        parameters
          requiredPositional _annotationThenComment2 @-1
            type: int
        returnType: void
      synthetic static get commentThenAnnotation @-1
        returnType: int
      synthetic static set commentThenAnnotation @-1
        parameters
          requiredPositional _commentThenAnnotation @-1
            type: int
        returnType: void
      synthetic static get commentThenAnnotation2 @-1
        returnType: int
      synthetic static set commentThenAnnotation2 @-1
        parameters
          requiredPositional _commentThenAnnotation2 @-1
            type: int
        returnType: void
      synthetic static get commentAroundAnnotation @-1
        returnType: int
      synthetic static set commentAroundAnnotation @-1
        parameters
          requiredPositional _commentAroundAnnotation @-1
            type: int
        returnType: void
      synthetic static get commentAroundAnnotation2 @-1
        returnType: int
      synthetic static set commentAroundAnnotation2 @-1
        parameters
          requiredPositional _commentAroundAnnotation2 @-1
            type: int
        returnType: void
''',
        withCodeRanges: true);
  }

  test_codeRange_type_parameter() async {
    var library = await checkLibrary('''
class A<T> {}
void f<U extends num> {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class A @6
        codeOffset: 0
        codeLength: 13
        typeParameters
          covariant T @8
            codeOffset: 8
            codeLength: 1
            defaultType: dynamic
        constructors
          synthetic @-1
    functions
      f @19
        codeOffset: 14
        codeLength: 24
        typeParameters
          covariant U @21
            codeOffset: 21
            codeLength: 13
            bound: num
        returnType: void
''',
        withCodeRanges: true);
  }

  test_compilationUnit_nnbd_disabled_via_dart_directive() async {
    var library = await checkLibrary('''
// @dart=2.2
''');
    expect(library.isNonNullableByDefault, isFalse);
  }

  test_compilationUnit_nnbd_disabled_via_feature_set() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('');
    expect(library.isNonNullableByDefault, isFalse);
  }

  test_compilationUnit_nnbd_enabled() async {
    var library = await checkLibrary('');
    expect(library.isNonNullableByDefault, isTrue);
  }

  test_const_asExpression() async {
    var library = await checkLibrary('''
const num a = 0;
const b = a as int;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @10
        type: num
        constantInitializer
          IntegerLiteral
            literal: 0 @14
            staticType: int
      static const b @23
        type: int
        constantInitializer
          AsExpression
            asOperator: as @29
            expression: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: num
              token: a @27
            staticType: int
            type: NamedType
              name: SimpleIdentifier
                staticElement: dart:core::@class::int
                staticType: null
                token: int @32
              type: int
    accessors
      synthetic static get a @-1
        returnType: num
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_assignmentExpression() async {
    var library = await checkLibrary(r'''
const a = 0;
const b = (a += 1);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static const b @19
        type: int
        constantInitializer
          ParenthesizedExpression
            expression: AssignmentExpression
              leftHandSide: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: a @24
              operator: += @26
              readElement: self::@getter::a
              readType: int
              rightHandSide: IntegerLiteral
                literal: 1 @29
                staticType: int
              staticElement: dart:core::@class::num::@method::+
              staticType: int
              writeElement: self::@getter::a
              writeType: dynamic
            leftParenthesis: ( @23
            rightParenthesis: ) @30
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_cascadeExpression() async {
    var library = await checkLibrary(r'''
const a = 0..isEven..abs();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          CascadeExpression
            cascadeSections
              PropertyAccess
                operator: .. @11
                propertyName: SimpleIdentifier
                  staticElement: dart:core::@class::int::@getter::isEven
                  staticType: bool
                  token: isEven @13
                staticType: bool
              MethodInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @24
                  rightParenthesis: ) @25
                methodName: SimpleIdentifier
                  staticElement: dart:core::@class::int::@method::abs
                  staticType: int Function()
                  token: abs @21
                operator: .. @19
                staticInvokeType: int Function()
                staticType: int
            staticType: int
            target: IntegerLiteral
              literal: 0 @10
              staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_const_classField() async {
    var library = await checkLibrary(r'''
class C {
  static const int f1 = 1;
  static const int f2 = C.f1, f3 = C.f2;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const f1 @29
            type: int
            constantInitializer
              IntegerLiteral
                literal: 1 @34
                staticType: int
          static const f2 @56
            type: int
            constantInitializer
              PrefixedIdentifier
                identifier: SimpleIdentifier
                  staticElement: self::@class::C::@getter::f1
                  staticType: int
                  token: f1 @63
                period: . @62
                prefix: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @61
                staticElement: self::@class::C::@getter::f1
                staticType: int
          static const f3 @67
            type: int
            constantInitializer
              PrefixedIdentifier
                identifier: SimpleIdentifier
                  staticElement: self::@class::C::@getter::f2
                  staticType: int
                  token: f2 @74
                period: . @73
                prefix: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @72
                staticElement: self::@class::C::@getter::f2
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get f1 @-1
            returnType: int
          synthetic static get f2 @-1
            returnType: int
          synthetic static get f3 @-1
            returnType: int
''');
  }

  test_const_constructor_inferred_args() async {
    var library = await checkLibrary('''
class C<T> {
  final T t;
  const C(this.t);
  const C.named(this.t);
}
const Object x = const C(0);
const Object y = const C.named(0);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          final t @23
            type: T
        constructors
          const @34
            parameters
              requiredPositional final this.t @41
                type: T
          const named @55
            periodOffset: 54
            nameEnd: 60
            parameters
              requiredPositional final this.t @66
                type: T
        accessors
          synthetic get t @-1
            returnType: T
    topLevelVariables
      static const x @85
        type: Object
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @97
                  staticType: int
              leftParenthesis: ( @96
              rightParenthesis: ) @98
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::•
                substitution: {T: int}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @95
                type: C<int>
            keyword: const @89
            staticType: C<int>
      static const y @114
        type: Object
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @132
                  staticType: int
              leftParenthesis: ( @131
              rightParenthesis: ) @133
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: ConstructorMember
                  base: self::@class::C::@constructor::named
                  substitution: {T: dynamic}
                staticType: null
                token: named @126
              period: . @125
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::named
                substitution: {T: int}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @124
                type: C<int>
            keyword: const @118
            staticType: C<int>
    accessors
      synthetic static get x @-1
        returnType: Object
      synthetic static get y @-1
        returnType: Object
''');
    var x = library.definingCompilationUnit.topLevelVariables[0]
        as TopLevelVariableElementImpl;
    var xExpr = x.constantInitializer as InstanceCreationExpression;
    var xType = xExpr.constructorName.staticElement!.returnType;
    _assertTypeStr(
      xType,
      'C<int>',
    );
    var y = library.definingCompilationUnit.topLevelVariables[0]
        as TopLevelVariableElementImpl;
    var yExpr = y.constantInitializer as InstanceCreationExpression;
    var yType = yExpr.constructorName.staticElement!.returnType;
    _assertTypeStr(yType, 'C<int>');
  }

  test_const_constructorReference() async {
    var library = await checkLibrary(r'''
class A {
  A.named();
}
const v = A.named;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          named @14
            periodOffset: 13
            nameEnd: 19
    topLevelVariables
      static const v @31
        type: A Function()
        constantInitializer
          ConstructorReference
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: self::@class::A::@constructor::named
                staticType: null
                token: named @37
              period: . @36
              staticElement: self::@class::A::@constructor::named
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @35
                type: null
            staticType: A Function()
    accessors
      synthetic static get v @-1
        returnType: A Function()
''');
  }

  test_const_finalField_hasConstConstructor() async {
    var library = await checkLibrary(r'''
class C {
  final int f = 42;
  const C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final f @22
            type: int
            constantInitializer
              IntegerLiteral
                literal: 42 @26
                staticType: int
        constructors
          const @38
        accessors
          synthetic get f @-1
            returnType: int
''');
  }

  test_const_functionExpression_typeArgumentTypes() async {
    var library = await checkLibrary('''
void f<T>(T a) {}

const void Function(int) v = f;
''');
    checkElementText(library, '''
library
  definingUnit
    topLevelVariables
      static const v @44
        type: void Function(int)
        constantInitializer
          FunctionReference
            function: SimpleIdentifier
              staticElement: self::@function::f
              staticType: void Function<T>(T)
              token: f @48
            staticType: void Function(int)
            typeArgumentTypes
              int
    accessors
      synthetic static get v @-1
        returnType: void Function(int)
    functions
      f @5
        typeParameters
          covariant T @7
        parameters
          requiredPositional a @12
            type: T
        returnType: void
''');
  }

  test_const_functionReference() async {
    var library = await checkLibrary(r'''
void f<T>(T a) {}
const v = f<int>;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @24
        type: void Function(int)
        constantInitializer
          FunctionReference
            function: SimpleIdentifier
              staticElement: self::@function::f
              staticType: void Function<T>(T)
              token: f @28
            staticType: void Function(int)
            typeArgumentTypes
              int
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @30
                  type: int
              leftBracket: < @29
              rightBracket: > @33
    accessors
      synthetic static get v @-1
        returnType: void Function(int)
    functions
      f @5
        typeParameters
          covariant T @7
        parameters
          requiredPositional a @12
            type: T
        returnType: void
''');
  }

  test_const_indexExpression() async {
    var library = await checkLibrary(r'''
const a = [0];
const b = 0;
const c = a[b];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: List<int>
        constantInitializer
          ListLiteral
            elements
              IntegerLiteral
                literal: 0 @11
                staticType: int
            leftBracket: [ @10
            rightBracket: ] @12
            staticType: List<int>
      static const b @21
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @25
            staticType: int
      static const c @34
        type: int
        constantInitializer
          IndexExpression
            index: SimpleIdentifier
              staticElement: self::@getter::b
              staticType: int
              token: b @40
            leftBracket: [ @39
            rightBracket: ] @41
            staticElement: MethodMember
              base: dart:core::@class::List::@method::[]
              substitution: {E: int}
            staticType: int
            target: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: List<int>
              token: a @38
    accessors
      synthetic static get a @-1
        returnType: List<int>
      synthetic static get b @-1
        returnType: int
      synthetic static get c @-1
        returnType: int
''');
  }

  test_const_inference_downward_list() async {
    var library = await checkLibrary('''
class P<T> {
  const P();
}

class P1<T> extends P<T> {
  const P1();
}

class P2<T> extends P<T> {
  const P2();
}

const List<P> values = [
  P1(),
  P2<int>(),
];
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class P @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class P1 @35
        typeParameters
          covariant T @38
            defaultType: dynamic
        supertype: P<T>
        constructors
          const @64
      class P2 @79
        typeParameters
          covariant T @82
            defaultType: dynamic
        supertype: P<T>
        constructors
          const @108
    topLevelVariables
      static const values @131
        type: List<P<dynamic>>
        constantInitializer
          ListLiteral
            elements
              InstanceCreationExpression
                argumentList: ArgumentList
                  leftParenthesis: ( @146
                  rightParenthesis: ) @147
                constructorName: ConstructorName
                  staticElement: ConstructorMember
                    base: self::@class::P1::@constructor::•
                    substitution: {T: dynamic}
                  type: NamedType
                    name: SimpleIdentifier
                      staticElement: self::@class::P1
                      staticType: null
                      token: P1 @144
                    type: P1<dynamic>
                staticType: P1<dynamic>
              InstanceCreationExpression
                argumentList: ArgumentList
                  leftParenthesis: ( @159
                  rightParenthesis: ) @160
                constructorName: ConstructorName
                  staticElement: ConstructorMember
                    base: self::@class::P2::@constructor::•
                    substitution: {T: int}
                  type: NamedType
                    name: SimpleIdentifier
                      staticElement: self::@class::P2
                      staticType: null
                      token: P2 @152
                    type: P2<int>
                    typeArguments: TypeArgumentList
                      arguments
                        NamedType
                          name: SimpleIdentifier
                            staticElement: dart:core::@class::int
                            staticType: null
                            token: int @155
                          type: int
                      leftBracket: < @154
                      rightBracket: > @158
                staticType: P2<int>
            leftBracket: [ @140
            rightBracket: ] @163
            staticType: List<P<dynamic>>
    accessors
      synthetic static get values @-1
        returnType: List<P<dynamic>>
''');
  }

  test_const_invalid_field_const() async {
    var library = await checkLibrary(r'''
class C {
  static const f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const f @25
            type: int
            constantInitializer
              BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @29
                  staticType: int
                operator: + @31
                rightOperand: MethodInvocation
                  argumentList: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  methodName: SimpleIdentifier
                    staticElement: self::@function::foo
                    staticType: int Function()
                    token: foo @33
                  staticInvokeType: int Function()
                  staticType: int
                staticElement: dart:core::@class::num::@method::+
                staticInvokeType: num Function(num)
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get f @-1
            returnType: int
    functions
      foo @46
        returnType: int
''');
  }

  test_const_invalid_field_final() async {
    var library = await checkLibrary(r'''
class C {
  final f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final f @18
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
    functions
      foo @39
        returnType: int
''');
  }

  test_const_invalid_functionExpression() async {
    var library = await checkLibrary('''
const v = () { return 0; };
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: int Function()
        constantInitializer
          FunctionExpression
            body: BlockFunctionBody
              block: Block
                leftBracket: { @0
                rightBracket: } @25
            declaredElement: <null>
            parameters: FormalParameterList
              leftParenthesis: ( @10
              rightParenthesis: ) @0
            staticType: null
    accessors
      synthetic static get v @-1
        returnType: int Function()
''');
  }

  test_const_invalid_functionExpression_nested() async {
    var library = await checkLibrary('''
const v = () { return 0; } + 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: dynamic
        constantInitializer
          BinaryExpression
            leftOperand: FunctionExpression
              body: BlockFunctionBody
                block: Block
                  leftBracket: { @0
                  rightBracket: } @25
              declaredElement: <null>
              parameters: FormalParameterList
                leftParenthesis: ( @10
                rightParenthesis: ) @0
              staticType: null
            operator: + @27
            rightOperand: IntegerLiteral
              literal: 2 @29
              staticType: int
            staticElement: <null>
            staticInvokeType: null
            staticType: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_const_invalid_intLiteral() async {
    var library = await checkLibrary(r'''
const int x = 0x;
''', allowErrors: true);
    checkElementText(library, r'''
const int x = 0;
''');
  }

  test_const_invalid_topLevel() async {
    var library = await checkLibrary(r'''
const v = 1 + foo();
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @10
              staticType: int
            operator: + @12
            rightOperand: MethodInvocation
              argumentList: ArgumentList
                leftParenthesis: ( @17
                rightParenthesis: ) @18
              methodName: SimpleIdentifier
                staticElement: self::@function::foo
                staticType: int Function()
                token: foo @14
              staticInvokeType: int Function()
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
    accessors
      synthetic static get v @-1
        returnType: int
    functions
      foo @25
        returnType: int
''');
  }

  test_const_invalid_typeMismatch() async {
    var library = await checkLibrary(r'''
const int a = 0;
const bool b = a + 5;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @10
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @14
            staticType: int
      static const b @28
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int
              token: a @32
            operator: + @34
            rightOperand: IntegerLiteral
              literal: 5 @36
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: bool
''');
  }

  test_const_invokeConstructor_generic_named() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C.named(K k, V v);
}
const V = const C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          const named @26
            periodOffset: 25
            nameEnd: 31
            parameters
              requiredPositional k @34
                type: K
              requiredPositional v @39
                type: V
    topLevelVariables
      static const V @51
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 1 @82
                  staticType: int
                SimpleStringLiteral
                  literal: '222' @85
              leftParenthesis: ( @81
              rightParenthesis: ) @90
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: ConstructorMember
                  base: self::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                staticType: null
                token: named @76
              period: . @75
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::named
                substitution: {K: int, V: String}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @61
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @63
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @68
                      type: String
                  leftBracket: < @62
                  rightBracket: > @74
            keyword: const @55
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_generic_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 1 @54
                  staticType: int
                SimpleStringLiteral
                  literal: '222' @57
              leftParenthesis: ( @53
              rightParenthesis: ) @62
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: ConstructorMember
                  base: a.dart::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                staticType: null
                token: named @48
              period: . @47
              staticElement: ConstructorMember
                base: a.dart::@class::C::@constructor::named
                substitution: {K: int, V: String}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: a.dart::@class::C
                  staticType: null
                  token: C @33
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @35
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @40
                      type: String
                  leftBracket: < @34
                  rightBracket: > @46
            keyword: const @27
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 1 @61
                  staticType: int
                SimpleStringLiteral
                  literal: '222' @64
              leftParenthesis: ( @60
              rightParenthesis: ) @69
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: ConstructorMember
                  base: a.dart::@class::C::@constructor::named
                  substitution: {K: int, V: String}
                staticType: null
                token: named @55
              period: . @54
              staticElement: ConstructorMember
                base: a.dart::@class::C::@constructor::named
                substitution: {K: int, V: String}
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: a.dart::@class::C
                  staticType: null
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @42
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @47
                      type: String
                  leftBracket: < @41
                  rightBracket: > @53
            keyword: const @32
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_generic_noTypeArguments() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          const @24
    topLevelVariables
      static const V @37
        type: C<dynamic, dynamic>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @48
              rightParenthesis: ) @49
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::•
                substitution: {K: dynamic, V: dynamic}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @47
                type: C<dynamic, dynamic>
            keyword: const @41
            staticType: C<dynamic, dynamic>
    accessors
      synthetic static get V @-1
        returnType: C<dynamic, dynamic>
''');
  }

  test_const_invokeConstructor_generic_unnamed() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C<int, String>();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          const @24
    topLevelVariables
      static const V @37
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @61
              rightParenthesis: ) @62
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::•
                substitution: {K: int, V: String}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @47
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @49
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @54
                      type: String
                  leftBracket: < @48
                  rightBracket: > @60
            keyword: const @41
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @47
              rightParenthesis: ) @48
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: a.dart::@class::C::@constructor::•
                substitution: {K: int, V: String}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: a.dart::@class::C
                  staticType: null
                  token: C @33
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @35
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @40
                      type: String
                  leftBracket: < @34
                  rightBracket: > @46
            keyword: const @27
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>();
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: C<int, String>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @54
              rightParenthesis: ) @55
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: a.dart::@class::C::@constructor::•
                substitution: {K: int, V: String}
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: a.dart::@class::C
                  staticType: null
                type: C<int, String>
                typeArguments: TypeArgumentList
                  arguments
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @42
                      type: int
                    NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::String
                        staticType: null
                        token: String @47
                      type: String
                  leftBracket: < @41
                  rightBracket: > @53
            keyword: const @32
            staticType: C<int, String>
    accessors
      synthetic static get V @-1
        returnType: C<int, String>
''');
  }

  test_const_invokeConstructor_named() async {
    var library = await checkLibrary(r'''
class C {
  const C.named(bool a, int b, int c, {String d, double e});
}
const V = const C.named(true, 1, 2, d: 'ccc', e: 3.4);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const named @20
            periodOffset: 19
            nameEnd: 25
            parameters
              requiredPositional a @31
                type: bool
              requiredPositional b @38
                type: int
              requiredPositional c @45
                type: int
              optionalNamed d @56
                type: String
              optionalNamed e @66
                type: double
    topLevelVariables
      static const V @79
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                BooleanLiteral
                  literal: true @97
                  staticType: bool
                IntegerLiteral
                  literal: 1 @103
                  staticType: int
                IntegerLiteral
                  literal: 2 @106
                  staticType: int
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      staticElement: self::@class::C::@constructor::named::@parameter::d
                      staticType: null
                      token: d @109
                  expression: SimpleStringLiteral
                    literal: 'ccc' @112
                NamedExpression
                  name: Label
                    label: SimpleIdentifier
                      staticElement: self::@class::C::@constructor::named::@parameter::e
                      staticType: null
                      token: e @119
                  expression: DoubleLiteral
                    literal: 3.4 @122
                    staticType: double
              leftParenthesis: ( @96
              rightParenthesis: ) @125
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: self::@class::C::@constructor::named
                staticType: null
                token: named @91
              period: . @90
              staticElement: self::@class::C::@constructor::named
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @89
                type: C
            keyword: const @83
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C.named();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @40
              rightParenthesis: ) @41
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: a.dart::@class::C::@constructor::named
                staticType: null
                token: named @35
              period: . @34
              staticElement: a.dart::@class::C::@constructor::named
              type: NamedType
                name: SimpleIdentifier
                  staticElement: a.dart::@class::C
                  staticType: null
                  token: C @33
                type: C
            keyword: const @27
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @47
              rightParenthesis: ) @48
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: a.dart::@class::C::@constructor::named
                staticType: null
                token: named @42
              period: . @41
              staticElement: a.dart::@class::C::@constructor::named
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: a.dart::@class::C
                  staticType: null
                type: C
            keyword: const @32
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_named_unresolved() async {
    var library = await checkLibrary(r'''
class C {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static const V @17
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @34
              rightParenthesis: ) @35
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: named @29
              period: . @28
              staticElement: <null>
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @27
                type: C
            keyword: const @21
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_named_unresolved2() async {
    var library = await checkLibrary(r'''
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @6
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @23
              rightParenthesis: ) @24
            constructorName: ConstructorName
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: named @18
                  period: . @17
                  prefix: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: C @16
                  staticElement: <null>
                  staticType: null
                type: dynamic
            keyword: const @10
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_invokeConstructor_named_unresolved3() async {
    addLibrarySource('/a.dart', r'''
class C {
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @47
              rightParenthesis: ) @48
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: named @42
              period: . @41
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: a.dart::@class::C
                  staticType: null
                type: C
            keyword: const @32
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_named_unresolved4() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @47
              rightParenthesis: ) @48
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: named @42
              period: . @41
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: <null>
                  staticType: null
                type: dynamic
            keyword: const @32
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_invokeConstructor_named_unresolved5() async {
    var library = await checkLibrary(r'''
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @6
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @25
              rightParenthesis: ) @26
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: named @20
              period: . @19
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: C @18
                  period: . @17
                  prefix: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: p @16
                  staticElement: <null>
                  staticType: null
                type: dynamic
            keyword: const @10
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_invokeConstructor_named_unresolved6() async {
    var library = await checkLibrary(r'''
class C<T> {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
    topLevelVariables
      static const V @20
        type: C<dynamic>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @37
              rightParenthesis: ) @38
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: named @32
              period: . @31
              staticElement: <null>
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @30
                type: C<dynamic>
            keyword: const @24
            staticType: C<dynamic>
    accessors
      synthetic static get V @-1
        returnType: C<dynamic>
''');
  }

  test_const_invokeConstructor_unnamed() async {
    var library = await checkLibrary(r'''
class C {
  const C();
}
const V = const C();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
    topLevelVariables
      static const V @31
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @42
              rightParenthesis: ) @43
            constructorName: ConstructorName
              staticElement: self::@class::C::@constructor::•
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @41
                type: C
            keyword: const @35
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @34
              rightParenthesis: ) @35
            constructorName: ConstructorName
              staticElement: a.dart::@class::C::@constructor::•
              type: NamedType
                name: SimpleIdentifier
                  staticElement: a.dart::@class::C
                  staticType: null
                  token: C @33
                type: C
            keyword: const @27
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @41
              rightParenthesis: ) @42
            constructorName: ConstructorName
              staticElement: a.dart::@class::C::@constructor::•
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: a.dart::@class::C
                  staticType: null
                type: C
            keyword: const @32
            staticType: C
    accessors
      synthetic static get V @-1
        returnType: C
''');
  }

  test_const_invokeConstructor_unnamed_unresolved() async {
    var library = await checkLibrary(r'''
const V = const C();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @6
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @17
              rightParenthesis: ) @18
            constructorName: ConstructorName
              staticElement: <null>
              type: NamedType
                name: SimpleIdentifier
                  staticElement: <null>
                  staticType: null
                  token: C @16
                type: dynamic
            keyword: const @10
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_invokeConstructor_unnamed_unresolved2() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @41
              rightParenthesis: ) @42
            constructorName: ConstructorName
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: C @40
                  period: . @39
                  prefix: SimpleIdentifier
                    staticElement: self::@prefix::p
                    staticType: null
                    token: p @38
                  staticElement: <null>
                  staticType: null
                type: dynamic
            keyword: const @32
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_invokeConstructor_unnamed_unresolved3() async {
    var library = await checkLibrary(r'''
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @6
        type: dynamic
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @19
              rightParenthesis: ) @20
            constructorName: ConstructorName
              staticElement: <null>
              type: NamedType
                name: PrefixedIdentifier
                  identifier: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: C @18
                  period: . @17
                  prefix: SimpleIdentifier
                    staticElement: <null>
                    staticType: null
                    token: p @16
                  staticElement: <null>
                  staticType: null
                type: dynamic
            keyword: const @10
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_isExpression() async {
    var library = await checkLibrary('''
const a = 0;
const b = a is int;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static const b @19
        type: bool
        constantInitializer
          IsExpression
            expression: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int
              token: a @23
            isOperator: is @25
            staticType: bool
            type: NamedType
              name: SimpleIdentifier
                staticElement: dart:core::@class::int
                staticType: null
                token: int @28
              type: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: bool
''');
  }

  test_const_length_ofClassConstField() async {
    var library = await checkLibrary(r'''
class C {
  static const String F = '';
}
const int v = C.F.length;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const F @32
            type: String
            constantInitializer
              SimpleStringLiteral
                literal: '' @36
        constructors
          synthetic @-1
        accessors
          synthetic static get F @-1
            returnType: String
    topLevelVariables
      static const v @52
        type: int
        constantInitializer
          PropertyAccess
            operator: . @59
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @60
            staticType: int
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@class::C::@getter::F
                staticType: String
                token: F @58
              period: . @57
              prefix: SimpleIdentifier
                staticElement: self::@class::C
                staticType: null
                token: C @56
              staticElement: self::@class::C::@getter::F
              staticType: String
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofClassConstField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const int v = C.F.length;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const v @27
        type: int
        constantInitializer
          PropertyAccess
            operator: . @34
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @35
            staticType: int
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@class::C::@getter::F
                staticType: String
                token: F @33
              period: . @32
              prefix: SimpleIdentifier
                staticElement: a.dart::@class::C
                staticType: null
                token: C @31
              staticElement: a.dart::@class::C::@getter::F
              staticType: String
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofClassConstField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const int v = p.C.F.length;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const v @32
        type: int
        constantInitializer
          PropertyAccess
            operator: . @41
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @42
            staticType: int
            target: PropertyAccess
              operator: . @39
              propertyName: SimpleIdentifier
                staticElement: a.dart::@class::C::@getter::F
                staticType: String
                token: F @40
              staticType: String
              target: PrefixedIdentifier
                identifier: SimpleIdentifier
                  staticElement: a.dart::@class::C
                  staticType: null
                  token: C @38
                period: . @37
                prefix: SimpleIdentifier
                  staticElement: self::@prefix::p
                  staticType: null
                  token: p @36
                staticElement: a.dart::@class::C
                staticType: null
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofStringLiteral() async {
    var library = await checkLibrary(r'''
const v = 'abc'.length;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: int
        constantInitializer
          PropertyAccess
            operator: . @15
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @16
            staticType: int
            target: SimpleStringLiteral
              literal: 'abc' @10
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofTopLevelVariable() async {
    var library = await checkLibrary(r'''
const String S = 'abc';
const v = S.length;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const S @13
        type: String
        constantInitializer
          SimpleStringLiteral
            literal: 'abc' @17
      static const v @30
        type: int
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @36
            period: . @35
            prefix: SimpleIdentifier
              staticElement: self::@getter::S
              staticType: String
              token: S @34
            staticElement: dart:core::@class::String::@getter::length
            staticType: int
    accessors
      synthetic static get S @-1
        returnType: String
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofTopLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = S.length;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const v @23
        type: int
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @29
            period: . @28
            prefix: SimpleIdentifier
              staticElement: a.dart::@getter::S
              staticType: String
              token: S @27
            staticElement: dart:core::@class::String::@getter::length
            staticType: int
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = p.S.length;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const v @28
        type: int
        constantInitializer
          PropertyAccess
            operator: . @35
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @36
            staticType: int
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@getter::S
                staticType: String
                token: S @34
              period: . @33
              prefix: SimpleIdentifier
                staticElement: self::@prefix::p
                staticType: null
                token: p @32
              staticElement: a.dart::@getter::S
              staticType: String
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_const_length_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int length() => 42;
}
const v = C.length;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          static length @23
            returnType: int
    topLevelVariables
      static const v @47
        type: int Function()
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: self::@class::C::@method::length
              staticType: int Function()
              token: length @53
            period: . @52
            prefix: SimpleIdentifier
              staticElement: self::@class::C
              staticType: null
              token: C @51
            staticElement: self::@class::C::@method::length
            staticType: int Function()
    accessors
      synthetic static get v @-1
        returnType: int Function()
''');
  }

  test_const_list_if() async {
    var library = await checkLibrary('''
const Object x = const <int>[if (true) 1];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          ListLiteral
            constKeyword: const @17
            elements
              IfElement
                condition: BooleanLiteral
                  literal: true @33
                  staticType: bool
                thenStatement: IntegerLiteral
                  literal: 1 @39
                  staticType: int
            leftBracket: [ @28
            rightBracket: ] @40
            staticType: List<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_list_if_else() async {
    var library = await checkLibrary('''
const Object x = const <int>[if (true) 1 else 2];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          ListLiteral
            constKeyword: const @17
            elements
              IfElement
                condition: BooleanLiteral
                  literal: true @33
                  staticType: bool
                elseStatement: IntegerLiteral
                  literal: 2 @46
                  staticType: int
                thenStatement: IntegerLiteral
                  literal: 1 @39
                  staticType: int
            leftBracket: [ @28
            rightBracket: ] @47
            staticType: List<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_list_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const [1];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          ListLiteral
            constKeyword: const @17
            elements
              IntegerLiteral
                literal: 1 @24
                staticType: int
            leftBracket: [ @23
            rightBracket: ] @25
            staticType: List<int>
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_list_spread() async {
    var library = await checkLibrary('''
const Object x = const <int>[...<int>[1]];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          ListLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: ListLiteral
                  elements
                    IntegerLiteral
                      literal: 1 @38
                      staticType: int
                  leftBracket: [ @37
                  rightBracket: ] @39
                  staticType: List<int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @33
                        type: int
                    leftBracket: < @32
                    rightBracket: > @36
                spreadOperator: ... @29
            leftBracket: [ @28
            rightBracket: ] @40
            staticType: List<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_list_spread_null_aware() async {
    var library = await checkLibrary('''
const Object x = const <int>[...?<int>[1]];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          ListLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: ListLiteral
                  elements
                    IntegerLiteral
                      literal: 1 @39
                      staticType: int
                  leftBracket: [ @38
                  rightBracket: ] @40
                  staticType: List<int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @34
                        type: int
                    leftBracket: < @33
                    rightBracket: > @37
                spreadOperator: ...? @29
            leftBracket: [ @28
            rightBracket: ] @41
            staticType: List<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_map_if() async {
    var library = await checkLibrary('''
const Object x = const <int, int>{if (true) 1: 2};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              IfElement
                condition: BooleanLiteral
                  literal: true @38
                  staticType: bool
                thenStatement: SetOrMapLiteral
                  key: IntegerLiteral
                    literal: 1 @44
                    staticType: int
                  value: IntegerLiteral
                    literal: 2 @47
                    staticType: int
            isMap: true
            leftBracket: { @33
            rightBracket: } @48
            staticType: Map<int, int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @29
                  type: int
              leftBracket: < @23
              rightBracket: > @32
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_const_map_if_else() async {
    var library = await checkLibrary('''
const Object x = const <int, int>{if (true) 1: 2 else 3: 4];
''');
    checkElementText(library, r'''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{if (true) 1: 2 else 3: 4}/*isMap*/;
''');
  }

  test_const_map_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const {1: 1.0};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              SetOrMapLiteral
                key: IntegerLiteral
                  literal: 1 @24
                  staticType: int
                value: DoubleLiteral
                  literal: 1.0 @27
                  staticType: double
            isMap: true
            leftBracket: { @23
            rightBracket: } @30
            staticType: Map<int, double>
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_map_spread() async {
    var library = await checkLibrary('''
const Object x = const <int, int>{...<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: SetOrMapLiteral
                  elements
                    SetOrMapLiteral
                      key: IntegerLiteral
                        literal: 1 @48
                        staticType: int
                      value: IntegerLiteral
                        literal: 2 @51
                        staticType: int
                  isMap: true
                  leftBracket: { @47
                  rightBracket: } @52
                  staticType: Map<int, int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @38
                        type: int
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @43
                        type: int
                    leftBracket: < @37
                    rightBracket: > @46
                spreadOperator: ... @34
            isMap: true
            leftBracket: { @33
            rightBracket: } @53
            staticType: Map<int, int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @29
                  type: int
              leftBracket: < @23
              rightBracket: > @32
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_map_spread_null_aware() async {
    var library = await checkLibrary('''
const Object x = const <int, int>{...?<int, int>{1: 2}};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: SetOrMapLiteral
                  elements
                    SetOrMapLiteral
                      key: IntegerLiteral
                        literal: 1 @49
                        staticType: int
                      value: IntegerLiteral
                        literal: 2 @52
                        staticType: int
                  isMap: true
                  leftBracket: { @48
                  rightBracket: } @53
                  staticType: Map<int, int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @39
                        type: int
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @44
                        type: int
                    leftBracket: < @38
                    rightBracket: > @47
                spreadOperator: ...? @34
            isMap: true
            leftBracket: { @33
            rightBracket: } @54
            staticType: Map<int, int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @29
                  type: int
              leftBracket: < @23
              rightBracket: > @32
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_methodInvocation() async {
    var library = await checkLibrary(r'''
T f<T>(T a) => a;
const b = f<int>(0);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const b @24
        type: int
        constantInitializer
          MethodInvocation
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @35
                  staticType: int
              leftParenthesis: ( @34
              rightParenthesis: ) @36
            methodName: SimpleIdentifier
              staticElement: self::@function::f
              staticType: T Function<T>(T)
              token: f @28
            staticInvokeType: int Function(int)
            staticType: int
            typeArgumentTypes
              int
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @30
                  type: int
              leftBracket: < @29
              rightBracket: > @33
    accessors
      synthetic static get b @-1
        returnType: int
    functions
      f @2
        typeParameters
          covariant T @4
        parameters
          requiredPositional a @9
            type: T
        returnType: T
''');
  }

  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: foo});
}
int foo() => 42;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            parameters
              optionalNamed final this.x @37
                type: dynamic
                constantInitializer
                  SimpleIdentifier
                    staticElement: self::@function::foo
                    staticType: int Function()
                    token: foo @40
        accessors
          synthetic get x @-1
            returnType: dynamic
    functions
      foo @53
        returnType: int
''');
  }

  test_const_parameterDefaultValue_initializingFormal_named() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: 1 + 2});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            parameters
              optionalNamed final this.x @37
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @40
                      staticType: int
                    operator: + @42
                    rightOperand: IntegerLiteral
                      literal: 2 @44
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_const_parameterDefaultValue_initializingFormal_positional() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C([this.x = 1 + 2]);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            parameters
              optionalPositional final this.x @37
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @41
                      staticType: int
                    operator: + @43
                    rightOperand: IntegerLiteral
                      literal: 2 @45
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_const_parameterDefaultValue_normal() async {
    var library = await checkLibrary(r'''
class C {
  const C.positional([p = 1 + 2]);
  const C.named({p: 1 + 2});
  void methodPositional([p = 1 + 2]) {}
  void methodPositionalWithoutDefault([p]) {}
  void methodNamed({p: 1 + 2}) {}
  void methodNamedWithoutDefault({p}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const positional @20
            periodOffset: 19
            nameEnd: 30
            parameters
              optionalPositional p @32
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @36
                      staticType: int
                    operator: + @38
                    rightOperand: IntegerLiteral
                      literal: 2 @40
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
          const named @55
            periodOffset: 54
            nameEnd: 60
            parameters
              optionalNamed p @62
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @65
                      staticType: int
                    operator: + @67
                    rightOperand: IntegerLiteral
                      literal: 2 @69
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
        methods
          methodPositional @81
            parameters
              optionalPositional p @99
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @103
                      staticType: int
                    operator: + @105
                    rightOperand: IntegerLiteral
                      literal: 2 @107
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
            returnType: void
          methodPositionalWithoutDefault @121
            parameters
              optionalPositional p @153
                type: dynamic
            returnType: void
          methodNamed @167
            parameters
              optionalNamed p @180
                type: dynamic
                constantInitializer
                  BinaryExpression
                    leftOperand: IntegerLiteral
                      literal: 1 @183
                      staticType: int
                    operator: + @185
                    rightOperand: IntegerLiteral
                      literal: 2 @187
                      staticType: int
                    staticElement: dart:core::@class::num::@method::+
                    staticInvokeType: num Function(num)
                    staticType: int
            returnType: void
          methodNamedWithoutDefault @201
            parameters
              optionalNamed p @228
                type: dynamic
            returnType: void
''');
  }

  test_const_postfixExpression_increment() async {
    var library = await checkLibrary(r'''
const a = 0;
const b = a++;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static const b @19
        type: int
        constantInitializer
          PostfixExpression
            operand: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: a @23
            operator: ++ @24
            readElement: self::@getter::a
            readType: int
            staticElement: dart:core::@class::num::@method::+
            staticType: int
            writeElement: self::@getter::a
            writeType: dynamic
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_postfixExpression_nullCheck() async {
    var library = await checkLibrary(r'''
const int? a = 0;
const b = a!;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @11
        type: int?
        constantInitializer
          IntegerLiteral
            literal: 0 @15
            staticType: int
      static const b @24
        type: int
        constantInitializer
          PostfixExpression
            operand: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int?
              token: a @28
            operator: ! @29
            staticElement: <null>
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int?
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_prefixExpression_class_unaryMinus() async {
    var library = await checkLibrary(r'''
const a = 0;
const b = -a;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static const b @19
        type: int
        constantInitializer
          PrefixExpression
            operand: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int
              token: a @24
            operator: - @23
            staticElement: dart:core::@class::int::@method::unary-
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_prefixExpression_extension_unaryMinus() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', r'''
extension E on Object {
  int operator -() => 0;
}
const a = const Object();
''');
    var library = await checkLibrary('''
import 'a.dart';
const b = -a;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    topLevelVariables
      static const b @23
        type: int
        constantInitializer
          PrefixExpression
            operand: SimpleIdentifier
              staticElement: package:test/a.dart::@getter::a
              staticType: Object
              token: a @28
            operator: - @27
            staticElement: package:test/a.dart::@extension::E::@method::unary-
            staticType: int
    accessors
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_prefixExpression_increment() async {
    var library = await checkLibrary(r'''
const a = 0;
const b = ++a;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static const b @19
        type: int
        constantInitializer
          PrefixExpression
            operand: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: a @25
            operator: ++ @23
            readElement: self::@getter::a
            readType: int
            staticElement: dart:core::@class::num::@method::+
            staticType: int
            writeElement: self::@getter::a
            writeType: dynamic
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get b @-1
        returnType: int
''');
  }

  test_const_reference_staticField() async {
    var library = await checkLibrary(r'''
class C {
  static const int F = 42;
}
const V = C.F;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const F @29
            type: int
            constantInitializer
              IntegerLiteral
                literal: 42 @33
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get F @-1
            returnType: int
    topLevelVariables
      static const V @45
        type: int
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: self::@class::C::@getter::F
              staticType: int
              token: F @51
            period: . @50
            prefix: SimpleIdentifier
              staticElement: self::@class::C
              staticType: null
              token: C @49
            staticElement: self::@class::C::@getter::F
            staticType: int
    accessors
      synthetic static get V @-1
        returnType: int
''');
  }

  test_const_reference_staticField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.F;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: int
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@class::C::@getter::F
              staticType: int
              token: F @29
            period: . @28
            prefix: SimpleIdentifier
              staticElement: a.dart::@class::C
              staticType: null
              token: C @27
            staticElement: a.dart::@class::C::@getter::F
            staticType: int
    accessors
      synthetic static get V @-1
        returnType: int
''');
  }

  test_const_reference_staticField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.F;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: int
        constantInitializer
          PropertyAccess
            operator: . @35
            propertyName: SimpleIdentifier
              staticElement: a.dart::@class::C::@getter::F
              staticType: int
              token: F @36
            staticType: int
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@class::C
                staticType: null
                token: C @34
              period: . @33
              prefix: SimpleIdentifier
                staticElement: self::@prefix::p
                staticType: null
                token: p @32
              staticElement: a.dart::@class::C
              staticType: null
    accessors
      synthetic static get V @-1
        returnType: int
''');
  }

  test_const_reference_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int m(int a, String b) => 42;
}
const V = C.m;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          static m @23
            parameters
              requiredPositional a @29
                type: int
              requiredPositional b @39
                type: String
            returnType: int
    topLevelVariables
      static const V @57
        type: int Function(int, String)
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: self::@class::C::@method::m
              staticType: int Function(int, String)
              token: m @63
            period: . @62
            prefix: SimpleIdentifier
              staticElement: self::@class::C
              staticType: null
              token: C @61
            staticElement: self::@class::C::@method::m
            staticType: int Function(int, String)
    accessors
      synthetic static get V @-1
        returnType: int Function(int, String)
''');
  }

  test_const_reference_staticMethod_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.m;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: int Function(int, String)
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@class::C::@method::m
              staticType: int Function(int, String)
              token: m @29
            period: . @28
            prefix: SimpleIdentifier
              staticElement: a.dart::@class::C
              staticType: null
              token: C @27
            staticElement: a.dart::@class::C::@method::m
            staticType: int Function(int, String)
    accessors
      synthetic static get V @-1
        returnType: int Function(int, String)
''');
  }

  test_const_reference_staticMethod_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.m;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: int Function(int, String)
        constantInitializer
          PropertyAccess
            operator: . @35
            propertyName: SimpleIdentifier
              staticElement: a.dart::@class::C::@method::m
              staticType: int Function(int, String)
              token: m @36
            staticType: int Function(int, String)
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@class::C
                staticType: null
                token: C @34
              period: . @33
              prefix: SimpleIdentifier
                staticElement: self::@prefix::p
                staticType: null
                token: p @32
              staticElement: a.dart::@class::C
              staticType: null
    accessors
      synthetic static get V @-1
        returnType: int Function(int, String)
''');
  }

  test_const_reference_staticMethod_ofExtension() async {
    var library = await checkLibrary('''
class A {}
extension E on A {
  static void f() {}
}
const x = E.f;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    extensions
      E @21
        extendedType: A
        methods
          static f @44
            returnType: void
    topLevelVariables
      static const x @59
        type: void Function()
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: self::@extension::E::@method::f
              staticType: void Function()
              token: f @65
            period: . @64
            prefix: SimpleIdentifier
              staticElement: self::@extension::E
              staticType: null
              token: E @63
            staticElement: self::@extension::E::@method::f
            staticType: void Function()
    accessors
      synthetic static get x @-1
        returnType: void Function()
''');
  }

  test_const_reference_topLevelFunction() async {
    var library = await checkLibrary(r'''
foo() {}
const V = foo;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @15
        type: dynamic Function()
        constantInitializer
          SimpleIdentifier
            staticElement: self::@function::foo
            staticType: dynamic Function()
            token: foo @19
    accessors
      synthetic static get V @-1
        returnType: dynamic Function()
    functions
      foo @0
        returnType: dynamic
''');
  }

  test_const_reference_topLevelFunction_generic() async {
    var library = await checkLibrary(r'''
R foo<P, R>(P p) {}
const V = foo;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @26
        type: R Function<P, R>(P)
        constantInitializer
          SimpleIdentifier
            staticElement: self::@function::foo
            staticType: R Function<P, R>(P)
            token: foo @30
    accessors
      synthetic static get V @-1
        returnType: R Function<P, R>(P)
    functions
      foo @2
        typeParameters
          covariant P @6
          covariant R @9
        parameters
          requiredPositional p @14
            type: P
        returnType: R
''');
  }

  test_const_reference_topLevelFunction_imported() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = foo;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const V @23
        type: dynamic Function()
        constantInitializer
          SimpleIdentifier
            staticElement: a.dart::@function::foo
            staticType: dynamic Function()
            token: foo @27
    accessors
      synthetic static get V @-1
        returnType: dynamic Function()
''');
  }

  test_const_reference_topLevelFunction_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.foo;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const V @28
        type: dynamic Function()
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@function::foo
              staticType: dynamic Function()
              token: foo @34
            period: . @33
            prefix: SimpleIdentifier
              staticElement: self::@prefix::p
              staticType: null
              token: p @32
            staticElement: a.dart::@function::foo
            staticType: dynamic Function()
    accessors
      synthetic static get V @-1
        returnType: dynamic Function()
''');
  }

  test_const_reference_topLevelVariable() async {
    var library = await checkLibrary(r'''
const A = 1;
const B = A + 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const A @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 1 @10
            staticType: int
      static const B @19
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: SimpleIdentifier
              staticElement: self::@getter::A
              staticType: int
              token: A @23
            operator: + @25
            rightOperand: IntegerLiteral
              literal: 2 @27
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
    accessors
      synthetic static get A @-1
        returnType: int
      synthetic static get B @-1
        returnType: int
''');
  }

  test_const_reference_topLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const B = A + 2;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const B @23
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: SimpleIdentifier
              staticElement: a.dart::@getter::A
              staticType: int
              token: A @27
            operator: + @29
            rightOperand: IntegerLiteral
              literal: 2 @31
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
    accessors
      synthetic static get B @-1
        returnType: int
''');
  }

  test_const_reference_topLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const B = p.A + 2;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const B @28
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@getter::A
                staticType: int
                token: A @34
              period: . @33
              prefix: SimpleIdentifier
                staticElement: self::@prefix::p
                staticType: null
                token: p @32
              staticElement: a.dart::@getter::A
              staticType: int
            operator: + @36
            rightOperand: IntegerLiteral
              literal: 2 @38
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
    accessors
      synthetic static get B @-1
        returnType: int
''');
  }

  test_const_reference_type() async {
    var library = await checkLibrary(r'''
class C {}
class D<T> {}
enum E {a, b, c}
typedef F(int a, String b);
const vDynamic = dynamic;
const vNull = Null;
const vObject = Object;
const vClass = C;
const vGenericClass = D;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
      class D @17
        typeParameters
          covariant T @19
            defaultType: dynamic
        constructors
          synthetic @-1
    enums
      enum E @30
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @33
            type: E
          static const b @36
            type: E
          static const c @39
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
          synthetic static get c @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    typeAliases
      functionTypeAliasBased F @50
        aliasedType: dynamic Function(int, String)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @56
              type: int
            requiredPositional b @66
              type: String
          returnType: dynamic
    topLevelVariables
      static const vDynamic @76
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: dynamic@-1
            staticType: Type
            token: dynamic @87
      static const vNull @102
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: dart:core::@class::Null
            staticType: Type
            token: Null @110
      static const vObject @122
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: dart:core::@class::Object
            staticType: Type
            token: Object @132
      static const vClass @146
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: self::@class::C
            staticType: Type
            token: C @155
      static const vGenericClass @164
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: self::@class::D
            staticType: Type
            token: D @180
      static const vEnum @189
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: self::@enum::E
            staticType: Type
            token: E @197
      static const vFunctionTypeAlias @206
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: self::@typeAlias::F
            staticType: Type
            token: F @227
    accessors
      synthetic static get vDynamic @-1
        returnType: Type
      synthetic static get vNull @-1
        returnType: Type
      synthetic static get vObject @-1
        returnType: Type
      synthetic static get vClass @-1
        returnType: Type
      synthetic static get vGenericClass @-1
        returnType: Type
      synthetic static get vEnum @-1
        returnType: Type
      synthetic static get vFunctionTypeAlias @-1
        returnType: Type
''');
  }

  test_const_reference_type_functionType() async {
    var library = await checkLibrary(r'''
typedef F();
class C {
  final f = <F>[];
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @19
        fields
          final f @31
            type: List<dynamic Function()>
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: List<dynamic Function()>
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_const_reference_type_imported() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const vClass = C;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const vClass @23
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: a.dart::@class::C
            staticType: Type
            token: C @32
      static const vEnum @41
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: a.dart::@enum::E
            staticType: Type
            token: E @49
      static const vFunctionTypeAlias @58
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: a.dart::@typeAlias::F
            staticType: Type
            token: F @79
    accessors
      synthetic static get vClass @-1
        returnType: Type
      synthetic static get vEnum @-1
        returnType: Type
      synthetic static get vFunctionTypeAlias @-1
        returnType: Type
''');
  }

  test_const_reference_type_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const vClass = p.C;
const vEnum = p.E;
const vFunctionTypeAlias = p.F;
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const vClass @28
        type: Type
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@class::C
              staticType: Type
              token: C @39
            period: . @38
            prefix: SimpleIdentifier
              staticElement: self::@prefix::p
              staticType: null
              token: p @37
            staticElement: a.dart::@class::C
            staticType: Type
      static const vEnum @48
        type: Type
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@enum::E
              staticType: Type
              token: E @58
            period: . @57
            prefix: SimpleIdentifier
              staticElement: self::@prefix::p
              staticType: null
              token: p @56
            staticElement: a.dart::@enum::E
            staticType: Type
      static const vFunctionTypeAlias @67
        type: Type
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: a.dart::@typeAlias::F
              staticType: Type
              token: F @90
            period: . @89
            prefix: SimpleIdentifier
              staticElement: self::@prefix::p
              staticType: null
              token: p @88
            staticElement: a.dart::@typeAlias::F
            staticType: Type
    accessors
      synthetic static get vClass @-1
        returnType: Type
      synthetic static get vEnum @-1
        returnType: Type
      synthetic static get vFunctionTypeAlias @-1
        returnType: Type
''');
  }

  test_const_reference_type_typeParameter() async {
    var library = await checkLibrary(r'''
class C<T> {
  final f = <T>[];
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          final f @21
            type: List<T>
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: List<T>
''');
  }

  test_const_reference_unresolved_prefix0() async {
    var library = await checkLibrary(r'''
const V = foo;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const V @6
        type: dynamic
        constantInitializer
          SimpleIdentifier
            staticElement: <null>
            staticType: dynamic
            token: foo @10
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_reference_unresolved_prefix1() async {
    var library = await checkLibrary(r'''
class C {}
const V = C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static const V @17
        type: dynamic
        constantInitializer
          PrefixedIdentifier
            identifier: SimpleIdentifier
              staticElement: <null>
              staticType: dynamic
              token: foo @23
            period: . @22
            prefix: SimpleIdentifier
              staticElement: self::@class::C
              staticType: null
              token: C @21
            staticElement: <null>
            staticType: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_reference_unresolved_prefix2() async {
    addLibrarySource('/foo.dart', '''
class C {}
''');
    var library = await checkLibrary(r'''
import 'foo.dart' as p;
const V = p.C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
library
  imports
    foo.dart as p @21
  definingUnit
    topLevelVariables
      static const V @30
        type: dynamic
        constantInitializer
          PropertyAccess
            operator: . @37
            propertyName: SimpleIdentifier
              staticElement: <null>
              staticType: dynamic
              token: foo @38
            staticType: dynamic
            target: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: foo.dart::@class::C
                staticType: null
                token: C @36
              period: . @35
              prefix: SimpleIdentifier
                staticElement: self::@prefix::p
                staticType: null
                token: p @34
              staticElement: foo.dart::@class::C
              staticType: null
    accessors
      synthetic static get V @-1
        returnType: dynamic
''');
  }

  test_const_set_if() async {
    var library = await checkLibrary('''
const Object x = const <int>{if (true) 1};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              IfElement
                condition: BooleanLiteral
                  literal: true @33
                  staticType: bool
                thenStatement: IntegerLiteral
                  literal: 1 @39
                  staticType: int
            isMap: false
            leftBracket: { @28
            rightBracket: } @40
            staticType: Set<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_const_set_if_else() async {
    var library = await checkLibrary('''
const Object x = const <int>{if (true) 1 else 2];
''');
    checkElementText(library, r'''
const Object x = const <
        int/*location: dart:core;int*/>{if (true) 1 else 2}/*isSet*/;
''');
  }

  test_const_set_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const {1};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              IntegerLiteral
                literal: 1 @24
                staticType: int
            isMap: false
            leftBracket: { @23
            rightBracket: } @25
            staticType: Set<int>
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_set_spread() async {
    var library = await checkLibrary('''
const Object x = const <int>{...<int>{1}};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: SetOrMapLiteral
                  elements
                    IntegerLiteral
                      literal: 1 @38
                      staticType: int
                  isMap: false
                  leftBracket: { @37
                  rightBracket: } @39
                  staticType: Set<int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @33
                        type: int
                    leftBracket: < @32
                    rightBracket: > @36
                spreadOperator: ... @29
            isMap: false
            leftBracket: { @28
            rightBracket: } @40
            staticType: Set<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_set_spread_null_aware() async {
    var library = await checkLibrary('''
const Object x = const <int>{...?<int>{1}};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const x @13
        type: Object
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @17
            elements
              SpreadElement
                expression: SetOrMapLiteral
                  elements
                    IntegerLiteral
                      literal: 1 @39
                      staticType: int
                  isMap: false
                  leftBracket: { @38
                  rightBracket: } @40
                  staticType: Set<int>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @34
                        type: int
                    leftBracket: < @33
                    rightBracket: > @37
                spreadOperator: ...? @29
            isMap: false
            leftBracket: { @28
            rightBracket: } @41
            staticType: Set<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @24
                  type: int
              leftBracket: < @23
              rightBracket: > @27
    accessors
      synthetic static get x @-1
        returnType: Object
''');
  }

  test_const_topLevel_binary() async {
    var library = await checkLibrary(r'''
const vEqual = 1 == 2;
const vAnd = true && false;
const vOr = false || true;
const vBitXor = 1 ^ 2;
const vBitAnd = 1 & 2;
const vBitOr = 1 | 2;
const vBitShiftLeft = 1 << 2;
const vBitShiftRight = 1 >> 2;
const vAdd = 1 + 2;
const vSubtract = 1 - 2;
const vMiltiply = 1 * 2;
const vDivide = 1 / 2;
const vFloorDivide = 1 ~/ 2;
const vModulo = 1 % 2;
const vGreater = 1 > 2;
const vGreaterEqual = 1 >= 2;
const vLess = 1 < 2;
const vLessEqual = 1 <= 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vEqual @6
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @15
              staticType: int
            operator: == @17
            rightOperand: IntegerLiteral
              literal: 2 @20
              staticType: int
            staticElement: dart:core::@class::num::@method::==
            staticInvokeType: bool Function(Object)
            staticType: bool
      static const vAnd @29
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: BooleanLiteral
              literal: true @36
              staticType: bool
            operator: && @41
            rightOperand: BooleanLiteral
              literal: false @44
              staticType: bool
            staticElement: <null>
            staticInvokeType: null
            staticType: bool
      static const vOr @57
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: BooleanLiteral
              literal: false @63
              staticType: bool
            operator: || @69
            rightOperand: BooleanLiteral
              literal: true @72
              staticType: bool
            staticElement: <null>
            staticInvokeType: null
            staticType: bool
      static const vBitXor @84
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @94
              staticType: int
            operator: ^ @96
            rightOperand: IntegerLiteral
              literal: 2 @98
              staticType: int
            staticElement: dart:core::@class::int::@method::^
            staticInvokeType: int Function(int)
            staticType: int
      static const vBitAnd @107
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @117
              staticType: int
            operator: & @119
            rightOperand: IntegerLiteral
              literal: 2 @121
              staticType: int
            staticElement: dart:core::@class::int::@method::&
            staticInvokeType: int Function(int)
            staticType: int
      static const vBitOr @130
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @139
              staticType: int
            operator: | @141
            rightOperand: IntegerLiteral
              literal: 2 @143
              staticType: int
            staticElement: dart:core::@class::int::@method::|
            staticInvokeType: int Function(int)
            staticType: int
      static const vBitShiftLeft @152
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @168
              staticType: int
            operator: << @170
            rightOperand: IntegerLiteral
              literal: 2 @173
              staticType: int
            staticElement: dart:core::@class::int::@method::<<
            staticInvokeType: int Function(int)
            staticType: int
      static const vBitShiftRight @182
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @199
              staticType: int
            operator: >> @201
            rightOperand: IntegerLiteral
              literal: 2 @204
              staticType: int
            staticElement: dart:core::@class::int::@method::>>
            staticInvokeType: int Function(int)
            staticType: int
      static const vAdd @213
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @220
              staticType: int
            operator: + @222
            rightOperand: IntegerLiteral
              literal: 2 @224
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
      static const vSubtract @233
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @245
              staticType: int
            operator: - @247
            rightOperand: IntegerLiteral
              literal: 2 @249
              staticType: int
            staticElement: dart:core::@class::num::@method::-
            staticInvokeType: num Function(num)
            staticType: int
      static const vMiltiply @258
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @270
              staticType: int
            operator: * @272
            rightOperand: IntegerLiteral
              literal: 2 @274
              staticType: int
            staticElement: dart:core::@class::num::@method::*
            staticInvokeType: num Function(num)
            staticType: int
      static const vDivide @283
        type: double
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @293
              staticType: int
            operator: / @295
            rightOperand: IntegerLiteral
              literal: 2 @297
              staticType: int
            staticElement: dart:core::@class::num::@method::/
            staticInvokeType: double Function(num)
            staticType: double
      static const vFloorDivide @306
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @321
              staticType: int
            operator: ~/ @323
            rightOperand: IntegerLiteral
              literal: 2 @326
              staticType: int
            staticElement: dart:core::@class::num::@method::~/
            staticInvokeType: int Function(num)
            staticType: int
      static const vModulo @335
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @345
              staticType: int
            operator: % @347
            rightOperand: IntegerLiteral
              literal: 2 @349
              staticType: int
            staticElement: dart:core::@class::num::@method::%
            staticInvokeType: num Function(num)
            staticType: int
      static const vGreater @358
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @369
              staticType: int
            operator: > @371
            rightOperand: IntegerLiteral
              literal: 2 @373
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      static const vGreaterEqual @382
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @398
              staticType: int
            operator: >= @400
            rightOperand: IntegerLiteral
              literal: 2 @403
              staticType: int
            staticElement: dart:core::@class::num::@method::>=
            staticInvokeType: bool Function(num)
            staticType: bool
      static const vLess @412
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @420
              staticType: int
            operator: < @422
            rightOperand: IntegerLiteral
              literal: 2 @424
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      static const vLessEqual @433
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @446
              staticType: int
            operator: <= @448
            rightOperand: IntegerLiteral
              literal: 2 @451
              staticType: int
            staticElement: dart:core::@class::num::@method::<=
            staticInvokeType: bool Function(num)
            staticType: bool
    accessors
      synthetic static get vEqual @-1
        returnType: bool
      synthetic static get vAnd @-1
        returnType: bool
      synthetic static get vOr @-1
        returnType: bool
      synthetic static get vBitXor @-1
        returnType: int
      synthetic static get vBitAnd @-1
        returnType: int
      synthetic static get vBitOr @-1
        returnType: int
      synthetic static get vBitShiftLeft @-1
        returnType: int
      synthetic static get vBitShiftRight @-1
        returnType: int
      synthetic static get vAdd @-1
        returnType: int
      synthetic static get vSubtract @-1
        returnType: int
      synthetic static get vMiltiply @-1
        returnType: int
      synthetic static get vDivide @-1
        returnType: double
      synthetic static get vFloorDivide @-1
        returnType: int
      synthetic static get vModulo @-1
        returnType: int
      synthetic static get vGreater @-1
        returnType: bool
      synthetic static get vGreaterEqual @-1
        returnType: bool
      synthetic static get vLess @-1
        returnType: bool
      synthetic static get vLessEqual @-1
        returnType: bool
''');
  }

  test_const_topLevel_conditional() async {
    var library = await checkLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vConditional @6
        type: int
        constantInitializer
          ConditionalExpression
            colon: : @35
            condition: ParenthesizedExpression
              expression: BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @22
                  staticType: int
                operator: == @24
                rightOperand: IntegerLiteral
                  literal: 2 @27
                  staticType: int
                staticElement: dart:core::@class::num::@method::==
                staticInvokeType: bool Function(Object)
                staticType: bool
              leftParenthesis: ( @21
              rightParenthesis: ) @28
              staticType: bool
            elseExpression: IntegerLiteral
              literal: 22 @37
              staticType: int
            question: ? @30
            staticType: int
            thenExpression: IntegerLiteral
              literal: 11 @32
              staticType: int
    accessors
      synthetic static get vConditional @-1
        returnType: int
''');
  }

  test_const_topLevel_identical() async {
    var library = await checkLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vIdentical @6
        type: int
        constantInitializer
          ConditionalExpression
            colon: : @33
            condition: ParenthesizedExpression
              expression: BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @20
                  staticType: int
                operator: == @22
                rightOperand: IntegerLiteral
                  literal: 2 @25
                  staticType: int
                staticElement: dart:core::@class::num::@method::==
                staticInvokeType: bool Function(Object)
                staticType: bool
              leftParenthesis: ( @19
              rightParenthesis: ) @26
              staticType: bool
            elseExpression: IntegerLiteral
              literal: 22 @35
              staticType: int
            question: ? @28
            staticType: int
            thenExpression: IntegerLiteral
              literal: 11 @30
              staticType: int
    accessors
      synthetic static get vIdentical @-1
        returnType: int
''');
  }

  test_const_topLevel_ifNull() async {
    var library = await checkLibrary(r'''
const vIfNull = 1 ?? 2.0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vIfNull @6
        type: num
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @16
              staticType: int
            operator: ?? @18
            rightOperand: DoubleLiteral
              literal: 2.0 @21
              staticType: double
            staticElement: <null>
            staticInvokeType: null
            staticType: num
    accessors
      synthetic static get vIfNull @-1
        returnType: num
''');
  }

  test_const_topLevel_literal() async {
    var library = await checkLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vIntPositive = 1;
const vIntNegative = -2;
const vIntLong1 = 0x7FFFFFFFFFFFFFFF;
const vIntLong2 = 0xFFFFFFFFFFFFFFFF;
const vIntLong3 = 0x8000000000000000;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vNull @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @14
            staticType: Null
      static const vBoolFalse @26
        type: bool
        constantInitializer
          BooleanLiteral
            literal: false @39
            staticType: bool
      static const vBoolTrue @52
        type: bool
        constantInitializer
          BooleanLiteral
            literal: true @64
            staticType: bool
      static const vIntPositive @76
        type: int
        constantInitializer
          IntegerLiteral
            literal: 1 @91
            staticType: int
      static const vIntNegative @100
        type: int
        constantInitializer
          PrefixExpression
            operand: IntegerLiteral
              literal: 2 @116
              staticType: int
            operator: - @115
            staticElement: dart:core::@class::int::@method::unary-
            staticType: int
      static const vIntLong1 @125
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0x7FFFFFFFFFFFFFFF @137
            staticType: int
      static const vIntLong2 @163
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0xFFFFFFFFFFFFFFFF @175
            staticType: int
      static const vIntLong3 @201
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0x8000000000000000 @213
            staticType: int
      static const vDouble @239
        type: double
        constantInitializer
          DoubleLiteral
            literal: 2.3 @249
            staticType: double
      static const vString @260
        type: String
        constantInitializer
          SimpleStringLiteral
            literal: 'abc' @270
      static const vStringConcat @283
        type: String
        constantInitializer
          AdjacentStrings
            staticType: String
            stringValue: aaabbb
            strings
              SimpleStringLiteral
                literal: 'aaa' @299
              SimpleStringLiteral
                literal: 'bbb' @305
      static const vStringInterpolation @318
        type: String
        constantInitializer
          StringInterpolation
            elements
              InterpolationString
                contents: 'aaa  @341
              InterpolationExpression
                expression: BooleanLiteral
                  literal: true @348
                  staticType: bool
                leftBracket: ${ @346
                rightBracket: } @352
              InterpolationString
                contents:   @353
              InterpolationExpression
                expression: IntegerLiteral
                  literal: 42 @356
                  staticType: int
                leftBracket: ${ @354
                rightBracket: } @358
              InterpolationString
                contents:  bbb' @359
            staticType: String
            stringValue: null
      static const vSymbol @372
        type: Symbol
        constantInitializer
          SymbolLiteral
            components
              components: aaa
                offset: 383
              components: bbb
                offset: 387
              components: ccc
                offset: 391
            poundSign: # @382
    accessors
      synthetic static get vNull @-1
        returnType: dynamic
      synthetic static get vBoolFalse @-1
        returnType: bool
      synthetic static get vBoolTrue @-1
        returnType: bool
      synthetic static get vIntPositive @-1
        returnType: int
      synthetic static get vIntNegative @-1
        returnType: int
      synthetic static get vIntLong1 @-1
        returnType: int
      synthetic static get vIntLong2 @-1
        returnType: int
      synthetic static get vIntLong3 @-1
        returnType: int
      synthetic static get vDouble @-1
        returnType: double
      synthetic static get vString @-1
        returnType: String
      synthetic static get vStringConcat @-1
        returnType: String
      synthetic static get vStringInterpolation @-1
        returnType: String
      synthetic static get vSymbol @-1
        returnType: Symbol
''');
  }

  test_const_topLevel_methodInvocation_questionPeriod() async {
    var library = await checkLibrary(r'''
const int? a = 0;
const b = a?.toString();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @11
        type: int?
        constantInitializer
          IntegerLiteral
            literal: 0 @15
            staticType: int
      static const b @24
        type: String?
        constantInitializer
          MethodInvocation
            argumentList: ArgumentList
              leftParenthesis: ( @39
              rightParenthesis: ) @40
            methodName: SimpleIdentifier
              staticElement: dart:core::@class::int::@method::toString
              staticType: String Function()
              token: toString @31
            operator: ?. @29
            staticInvokeType: String Function()
            staticType: String?
            target: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int?
              token: a @28
    accessors
      synthetic static get a @-1
        returnType: int?
      synthetic static get b @-1
        returnType: String?
''');
  }

  test_const_topLevel_methodInvocation_questionPeriodPeriod() async {
    var library = await checkLibrary(r'''
const int? a = 0;
const b = a?..toString();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @11
        type: int?
        constantInitializer
          IntegerLiteral
            literal: 0 @15
            staticType: int
      static const b @24
        type: int?
        constantInitializer
          CascadeExpression
            cascadeSections
              MethodInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @40
                  rightParenthesis: ) @41
                methodName: SimpleIdentifier
                  staticElement: dart:core::@class::int::@method::toString
                  staticType: String Function()
                  token: toString @32
                operator: ?.. @29
                staticInvokeType: String Function()
                staticType: String
            staticType: int?
            target: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: int?
              token: a @28
    accessors
      synthetic static get a @-1
        returnType: int?
      synthetic static get b @-1
        returnType: int?
''');
  }

  test_const_topLevel_nullSafe_nullAware_propertyAccess() async {
    var library = await checkLibrary(r'''
const String? a = '';

const List<int?> b = [
  a?.length,
];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @14
        type: String?
        constantInitializer
          SimpleStringLiteral
            literal: '' @18
      static const b @40
        type: List<int?>
        constantInitializer
          ListLiteral
            elements
              PropertyAccess
                operator: ?. @49
                propertyName: SimpleIdentifier
                  staticElement: dart:core::@class::String::@getter::length
                  staticType: int
                  token: length @51
                staticType: int?
                target: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: String?
                  token: a @48
            leftBracket: [ @44
            rightBracket: ] @59
            staticType: List<int?>
    accessors
      synthetic static get a @-1
        returnType: String?
      synthetic static get b @-1
        returnType: List<int?>
''');
  }

  test_const_topLevel_parenthesis() async {
    var library = await checkLibrary(r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').length;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v1 @10
        type: int
        constantInitializer
          BinaryExpression
            leftOperand: ParenthesizedExpression
              expression: BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @16
                  staticType: int
                operator: + @18
                rightOperand: IntegerLiteral
                  literal: 2 @20
                  staticType: int
                staticElement: dart:core::@class::num::@method::+
                staticInvokeType: num Function(num)
                staticType: int
              leftParenthesis: ( @15
              rightParenthesis: ) @21
              staticType: int
            operator: * @23
            rightOperand: IntegerLiteral
              literal: 3 @25
              staticType: int
            staticElement: dart:core::@class::num::@method::*
            staticInvokeType: num Function(num)
            staticType: int
      static const v2 @38
        type: int
        constantInitializer
          PrefixExpression
            operand: ParenthesizedExpression
              expression: BinaryExpression
                leftOperand: IntegerLiteral
                  literal: 1 @45
                  staticType: int
                operator: + @47
                rightOperand: IntegerLiteral
                  literal: 2 @49
                  staticType: int
                staticElement: dart:core::@class::num::@method::+
                staticInvokeType: num Function(num)
                staticType: int
              leftParenthesis: ( @44
              rightParenthesis: ) @50
              staticType: int
            operator: - @43
            staticElement: dart:core::@class::int::@method::unary-
            staticType: int
      static const v3 @63
        type: int
        constantInitializer
          PropertyAccess
            operator: . @83
            propertyName: SimpleIdentifier
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
              token: length @84
            staticType: int
            target: ParenthesizedExpression
              expression: BinaryExpression
                leftOperand: SimpleStringLiteral
                  literal: 'aaa' @69
                operator: + @75
                rightOperand: SimpleStringLiteral
                  literal: 'bbb' @77
                staticElement: dart:core::@class::String::@method::+
                staticInvokeType: String Function(String)
                staticType: String
              leftParenthesis: ( @68
              rightParenthesis: ) @82
              staticType: String
    accessors
      synthetic static get v1 @-1
        returnType: int
      synthetic static get v2 @-1
        returnType: int
      synthetic static get v3 @-1
        returnType: int
''');
  }

  test_const_topLevel_prefix() async {
    var library = await checkLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vNotEqual @6
        type: bool
        constantInitializer
          BinaryExpression
            leftOperand: IntegerLiteral
              literal: 1 @18
              staticType: int
            operator: != @20
            rightOperand: IntegerLiteral
              literal: 2 @23
              staticType: int
            staticElement: dart:core::@class::num::@method::==
            staticInvokeType: bool Function(Object)
            staticType: bool
      static const vNot @32
        type: bool
        constantInitializer
          PrefixExpression
            operand: BooleanLiteral
              literal: true @40
              staticType: bool
            operator: ! @39
            staticElement: <null>
            staticType: bool
      static const vNegate @52
        type: int
        constantInitializer
          PrefixExpression
            operand: IntegerLiteral
              literal: 1 @63
              staticType: int
            operator: - @62
            staticElement: dart:core::@class::int::@method::unary-
            staticType: int
      static const vComplement @72
        type: int
        constantInitializer
          PrefixExpression
            operand: IntegerLiteral
              literal: 1 @87
              staticType: int
            operator: ~ @86
            staticElement: dart:core::@class::int::@method::~
            staticType: int
    accessors
      synthetic static get vNotEqual @-1
        returnType: bool
      synthetic static get vNot @-1
        returnType: bool
      synthetic static get vNegate @-1
        returnType: int
      synthetic static get vComplement @-1
        returnType: int
''');
  }

  test_const_topLevel_super() async {
    var library = await checkLibrary(r'''
const vSuper = super;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vSuper @6
        type: dynamic
        constantInitializer
          SuperExpression
            staticType: dynamic
            superKeyword: super @15
    accessors
      synthetic static get vSuper @-1
        returnType: dynamic
''');
  }

  test_const_topLevel_this() async {
    var library = await checkLibrary(r'''
const vThis = this;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vThis @6
        type: dynamic
        constantInitializer
          ThisExpression
            staticType: dynamic
            thisKeyword: this @14
    accessors
      synthetic static get vThis @-1
        returnType: dynamic
''');
  }

  test_const_topLevel_throw() async {
    var library = await checkLibrary(r'''
const c = throw 42;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const c @6
        type: Never
        constantInitializer
          ThrowExpression
            expression: IntegerLiteral
              literal: 42 @16
              staticType: int
            staticType: Never
    accessors
      synthetic static get c @-1
        returnType: Never
''');
  }

  test_const_topLevel_throw_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary(r'''
const c = throw 42;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const c @6
        type: dynamic
        constantInitializer
          ThrowExpression
            expression: IntegerLiteral
              literal: 42 @16
              staticType: int*
            staticType: Never*
    accessors
      synthetic static get c @-1
        returnType: dynamic
''');
  }

  test_const_topLevel_typedList() async {
    var library = await checkLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vNull @6
        type: List<Null>
        constantInitializer
          ListLiteral
            constKeyword: const @14
            leftBracket: [ @26
            rightBracket: ] @27
            staticType: List<Null>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::Null
                    staticType: null
                    token: Null @21
                  type: Null
              leftBracket: < @20
              rightBracket: > @25
      static const vDynamic @36
        type: List<dynamic>
        constantInitializer
          ListLiteral
            constKeyword: const @47
            elements
              IntegerLiteral
                literal: 1 @63
                staticType: int
              IntegerLiteral
                literal: 2 @66
                staticType: int
              IntegerLiteral
                literal: 3 @69
                staticType: int
            leftBracket: [ @62
            rightBracket: ] @70
            staticType: List<dynamic>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dynamic@-1
                    staticType: null
                    token: dynamic @54
                  type: dynamic
              leftBracket: < @53
              rightBracket: > @61
      static const vInterfaceNoTypeParameters @79
        type: List<int>
        constantInitializer
          ListLiteral
            constKeyword: const @108
            elements
              IntegerLiteral
                literal: 1 @120
                staticType: int
              IntegerLiteral
                literal: 2 @123
                staticType: int
              IntegerLiteral
                literal: 3 @126
                staticType: int
            leftBracket: [ @119
            rightBracket: ] @127
            staticType: List<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @115
                  type: int
              leftBracket: < @114
              rightBracket: > @118
      static const vInterfaceNoTypeArguments @136
        type: List<List<dynamic>>
        constantInitializer
          ListLiteral
            constKeyword: const @164
            leftBracket: [ @176
            rightBracket: ] @177
            staticType: List<List<dynamic>>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::List
                    staticType: null
                    token: List @171
                  type: List<dynamic>
              leftBracket: < @170
              rightBracket: > @175
      static const vInterfaceWithTypeArguments @186
        type: List<List<String>>
        constantInitializer
          ListLiteral
            constKeyword: const @216
            leftBracket: [ @236
            rightBracket: ] @237
            staticType: List<List<String>>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::List
                    staticType: null
                    token: List @223
                  type: List<String>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @228
                        type: String
                    leftBracket: < @227
                    rightBracket: > @234
              leftBracket: < @222
              rightBracket: > @235
      static const vInterfaceWithTypeArguments2 @246
        type: List<Map<int, List<String>>>
        constantInitializer
          ListLiteral
            constKeyword: const @277
            leftBracket: [ @307
            rightBracket: ] @308
            staticType: List<Map<int, List<String>>>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::Map
                    staticType: null
                    token: Map @284
                  type: Map<int, List<String>>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::int
                          staticType: null
                          token: int @288
                        type: int
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::List
                          staticType: null
                          token: List @293
                        type: List<String>
                        typeArguments: TypeArgumentList
                          arguments
                            NamedType
                              name: SimpleIdentifier
                                staticElement: dart:core::@class::String
                                staticType: null
                                token: String @298
                              type: String
                          leftBracket: < @297
                          rightBracket: > @304
                    leftBracket: < @287
                    rightBracket: > @305
              leftBracket: < @283
              rightBracket: > @306
    accessors
      synthetic static get vNull @-1
        returnType: List<Null>
      synthetic static get vDynamic @-1
        returnType: List<dynamic>
      synthetic static get vInterfaceNoTypeParameters @-1
        returnType: List<int>
      synthetic static get vInterfaceNoTypeArguments @-1
        returnType: List<List<dynamic>>
      synthetic static get vInterfaceWithTypeArguments @-1
        returnType: List<List<String>>
      synthetic static get vInterfaceWithTypeArguments2 @-1
        returnType: List<Map<int, List<String>>>
''');
  }

  test_const_topLevel_typedList_imported() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = const <C>[];
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static const v @23
        type: List<C>
        constantInitializer
          ListLiteral
            constKeyword: const @27
            leftBracket: [ @36
            rightBracket: ] @37
            staticType: List<C>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: a.dart::@class::C
                    staticType: null
                    token: C @34
                  type: C
              leftBracket: < @33
              rightBracket: > @35
    accessors
      synthetic static get v @-1
        returnType: List<C>
''');
  }

  test_const_topLevel_typedList_importedWithPrefix() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
    checkElementText(library, r'''
library
  imports
    a.dart as p @19
  definingUnit
    topLevelVariables
      static const v @28
        type: List<C>
        constantInitializer
          ListLiteral
            constKeyword: const @32
            leftBracket: [ @43
            rightBracket: ] @44
            staticType: List<C>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: PrefixedIdentifier
                    identifier: SimpleIdentifier
                      staticElement: a.dart::@class::C
                      staticType: null
                      token: C @41
                    period: . @40
                    prefix: SimpleIdentifier
                      staticElement: self::@prefix::p
                      staticType: null
                      token: p @39
                    staticElement: a.dart::@class::C
                    staticType: null
                  type: C
              leftBracket: < @38
              rightBracket: > @42
    accessors
      synthetic static get v @-1
        returnType: List<C>
''');
  }

  test_const_topLevel_typedList_typedefArgument() async {
    var library = await checkLibrary(r'''
typedef int F(String id);
const v = const <F>[];
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @12
        aliasedType: int Function(String)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional id @21
              type: String
          returnType: int
    topLevelVariables
      static const v @32
        type: List<int Function(String)>
        constantInitializer
          ListLiteral
            constKeyword: const @36
            leftBracket: [ @45
            rightBracket: ] @46
            staticType: List<int Function(String)>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: self::@typeAlias::F
                    staticType: null
                    token: F @43
                  type: int Function(String)
              leftBracket: < @42
              rightBracket: > @44
    accessors
      synthetic static get v @-1
        returnType: List<int Function(String)>
''');
  }

  test_const_topLevel_typedMap() async {
    var library = await checkLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vDynamic1 @6
        type: Map<dynamic, int>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @18
            isMap: true
            leftBracket: { @38
            rightBracket: } @39
            staticType: Map<dynamic, int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dynamic@-1
                    staticType: null
                    token: dynamic @25
                  type: dynamic
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @34
                  type: int
              leftBracket: < @24
              rightBracket: > @37
      static const vDynamic2 @48
        type: Map<int, dynamic>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @60
            isMap: true
            leftBracket: { @80
            rightBracket: } @81
            staticType: Map<int, dynamic>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @67
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dynamic@-1
                    staticType: null
                    token: dynamic @72
                  type: dynamic
              leftBracket: < @66
              rightBracket: > @79
      static const vInterface @90
        type: Map<int, String>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @103
            isMap: true
            leftBracket: { @122
            rightBracket: } @123
            staticType: Map<int, String>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @110
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::String
                    staticType: null
                    token: String @115
                  type: String
              leftBracket: < @109
              rightBracket: > @121
      static const vInterfaceWithTypeArguments @132
        type: Map<int, List<String>>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @162
            isMap: true
            leftBracket: { @187
            rightBracket: } @188
            staticType: Map<int, List<String>>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @169
                  type: int
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::List
                    staticType: null
                    token: List @174
                  type: List<String>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @179
                        type: String
                    leftBracket: < @178
                    rightBracket: > @185
              leftBracket: < @168
              rightBracket: > @186
    accessors
      synthetic static get vDynamic1 @-1
        returnType: Map<dynamic, int>
      synthetic static get vDynamic2 @-1
        returnType: Map<int, dynamic>
      synthetic static get vInterface @-1
        returnType: Map<int, String>
      synthetic static get vInterfaceWithTypeArguments @-1
        returnType: Map<int, List<String>>
''');
  }

  test_const_topLevel_typedSet() async {
    var library = await checkLibrary(r'''
const vDynamic1 = const <dynamic>{};
const vInterface = const <int>{};
const vInterfaceWithTypeArguments = const <List<String>>{};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const vDynamic1 @6
        type: Set<dynamic>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @18
            isMap: false
            leftBracket: { @33
            rightBracket: } @34
            staticType: Set<dynamic>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dynamic@-1
                    staticType: null
                    token: dynamic @25
                  type: dynamic
              leftBracket: < @24
              rightBracket: > @32
      static const vInterface @43
        type: Set<int>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @56
            isMap: false
            leftBracket: { @67
            rightBracket: } @68
            staticType: Set<int>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @63
                  type: int
              leftBracket: < @62
              rightBracket: > @66
      static const vInterfaceWithTypeArguments @77
        type: Set<List<String>>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @107
            isMap: false
            leftBracket: { @127
            rightBracket: } @128
            staticType: Set<List<String>>
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::List
                    staticType: null
                    token: List @114
                  type: List<String>
                  typeArguments: TypeArgumentList
                    arguments
                      NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @119
                        type: String
                    leftBracket: < @118
                    rightBracket: > @125
              leftBracket: < @113
              rightBracket: > @126
    accessors
      synthetic static get vDynamic1 @-1
        returnType: Set<dynamic>
      synthetic static get vInterface @-1
        returnType: Set<int>
      synthetic static get vInterfaceWithTypeArguments @-1
        returnType: Set<List<String>>
''');
  }

  test_const_topLevel_untypedList() async {
    var library = await checkLibrary(r'''
const v = const [1, 2, 3];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: List<int>
        constantInitializer
          ListLiteral
            constKeyword: const @10
            elements
              IntegerLiteral
                literal: 1 @17
                staticType: int
              IntegerLiteral
                literal: 2 @20
                staticType: int
              IntegerLiteral
                literal: 3 @23
                staticType: int
            leftBracket: [ @16
            rightBracket: ] @24
            staticType: List<int>
    accessors
      synthetic static get v @-1
        returnType: List<int>
''');
  }

  test_const_topLevel_untypedMap() async {
    var library = await checkLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: Map<int, String>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @10
            elements
              SetOrMapLiteral
                key: IntegerLiteral
                  literal: 0 @17
                  staticType: int
                value: SimpleStringLiteral
                  literal: 'aaa' @20
              SetOrMapLiteral
                key: IntegerLiteral
                  literal: 1 @27
                  staticType: int
                value: SimpleStringLiteral
                  literal: 'bbb' @30
              SetOrMapLiteral
                key: IntegerLiteral
                  literal: 2 @37
                  staticType: int
                value: SimpleStringLiteral
                  literal: 'ccc' @40
            isMap: true
            leftBracket: { @16
            rightBracket: } @45
            staticType: Map<int, String>
    accessors
      synthetic static get v @-1
        returnType: Map<int, String>
''');
  }

  test_const_topLevel_untypedSet() async {
    var library = await checkLibrary(r'''
const v = const {0, 1, 2};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: Set<int>
        constantInitializer
          SetOrMapLiteral
            constKeyword: const @10
            elements
              IntegerLiteral
                literal: 0 @17
                staticType: int
              IntegerLiteral
                literal: 1 @20
                staticType: int
              IntegerLiteral
                literal: 2 @23
                staticType: int
            isMap: false
            leftBracket: { @16
            rightBracket: } @24
            staticType: Set<int>
    accessors
      synthetic static get v @-1
        returnType: Set<int>
''');
  }

  test_const_typeLiteral() async {
    var library = await checkLibrary(r'''
const v = List<int>;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const v @6
        type: Type
        constantInitializer
          TypeLiteral
            staticType: Type
            type: NamedType
              name: SimpleIdentifier
                staticElement: dart:core::@class::List
                staticType: List<int>
                token: List @10
              type: List<int>
              typeArguments: TypeArgumentList
                arguments
                  NamedType
                    name: SimpleIdentifier
                      staticElement: dart:core::@class::int
                      staticType: null
                      token: int @15
                    type: int
                leftBracket: < @14
                rightBracket: > @18
    accessors
      synthetic static get v @-1
        returnType: Type
''');
  }

  test_constExpr_pushReference_enum_field() async {
    var library = await checkLibrary('''
enum E {a, b, c}
final vValue = E.a;
final vValues = E.values;
final vIndex = E.a.index;
''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @8
            type: E
          static const b @11
            type: E
          static const c @14
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
          synthetic static get c @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static final vValue @23
        type: E
      static final vValues @43
        type: List<E>
      static final vIndex @69
        type: int
    accessors
      synthetic static get vValue @-1
        returnType: E
      synthetic static get vValues @-1
        returnType: List<E>
      synthetic static get vIndex @-1
        returnType: int
''');
  }

  test_constExpr_pushReference_enum_method() async {
    var library = await checkLibrary('''
enum E {a}
final vToString = E.a.toString();
''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @8
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static final vToString @17
        type: String
    accessors
      synthetic static get vToString @-1
        returnType: String
''');
  }

  test_constExpr_pushReference_field_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = b;
  static const b = null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const a @25
            type: dynamic
            constantInitializer
              SimpleIdentifier
                staticElement: self::@class::C::@getter::b
                staticType: dynamic
                token: b @29
          static const b @47
            type: dynamic
            constantInitializer
              NullLiteral
                literal: null @51
                staticType: Null
        constructors
          synthetic @-1
        accessors
          synthetic static get a @-1
            returnType: dynamic
          synthetic static get b @-1
            returnType: dynamic
''');
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = m;
  static m() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const a @25
            type: dynamic Function()
            constantInitializer
              SimpleIdentifier
                staticElement: self::@class::C::@method::m
                staticType: dynamic Function()
                token: m @29
        constructors
          synthetic @-1
        accessors
          synthetic static get a @-1
            returnType: dynamic Function()
        methods
          static m @41
            returnType: dynamic
''');
  }

  test_constructor_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @34
            documentationComment: /**\n   * Docs\n   */
''');
  }

  test_constructor_initializers_assertInvocation() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
            parameters
              requiredPositional x @24
                type: int
            constantInitializers
              AssertInitializer
                assertKeyword: assert @29
                condition: BinaryExpression
                  leftOperand: SimpleIdentifier
                    staticElement: x@24
                    staticType: int
                    token: x @36
                  operator: >= @38
                  rightOperand: IntegerLiteral
                    literal: 42 @41
                    staticType: int
                  staticElement: dart:core::@class::num::@method::>=
                  staticInvokeType: bool Function(num)
                  staticType: bool
                leftParenthesis: ( @35
                rightParenthesis: ) @43
''');
  }

  test_constructor_initializers_assertInvocation_message() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42, 'foo');
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
            parameters
              requiredPositional x @24
                type: int
            constantInitializers
              AssertInitializer
                assertKeyword: assert @29
                condition: BinaryExpression
                  leftOperand: SimpleIdentifier
                    staticElement: x@24
                    staticType: int
                    token: x @36
                  operator: >= @38
                  rightOperand: IntegerLiteral
                    literal: 42 @41
                    staticType: int
                  staticElement: dart:core::@class::num::@method::>=
                  staticInvokeType: bool Function(num)
                  staticType: bool
                leftParenthesis: ( @35
                message: SimpleStringLiteral
                  literal: 'foo' @45
                rightParenthesis: ) @50
''');
  }

  test_constructor_initializers_field() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = 42;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            constantInitializers
              ConstructorFieldInitializer
                equals: = @37
                expression: IntegerLiteral
                  literal: 42 @39
                  staticType: int
                fieldName: SimpleIdentifier
                  staticElement: self::@class::C::@field::x
                  staticType: null
                  token: x @35
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_constructor_initializers_field_notConst() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = foo();
}
int foo() => 42;
''', allowErrors: true);
    // It is OK to keep non-constant initializers.
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            constantInitializers
              ConstructorFieldInitializer
                equals: = @37
                expression: MethodInvocation
                  argumentList: ArgumentList
                    leftParenthesis: ( @42
                    rightParenthesis: ) @43
                  methodName: SimpleIdentifier
                    staticElement: self::@function::foo
                    staticType: int Function()
                    token: foo @39
                  staticInvokeType: int Function()
                  staticType: int
                fieldName: SimpleIdentifier
                  staticElement: self::@class::C::@field::x
                  staticType: null
                  token: x @35
        accessors
          synthetic get x @-1
            returnType: dynamic
    functions
      foo @52
        returnType: int
''');
  }

  test_constructor_initializers_field_optionalPositionalParameter() async {
    var library = await checkLibrary('''
class A {
  final int _f;
  const A([int f = 0]) : _f = f;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          final _f @22
            type: int
        constructors
          const @34
            parameters
              optionalPositional f @41
                type: int
                constantInitializer
                  IntegerLiteral
                    literal: 0 @45
                    staticType: int
            constantInitializers
              ConstructorFieldInitializer
                equals: = @54
                expression: SimpleIdentifier
                  staticElement: self::@class::A::@constructor::•::@parameter::f
                  staticType: int
                  token: f @56
                fieldName: SimpleIdentifier
                  staticElement: self::@class::A::@field::_f
                  staticType: null
                  token: _f @51
        accessors
          synthetic get _f @-1
            returnType: int
''');
  }

  test_constructor_initializers_field_withParameter() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C(int p) : x = 1 + p;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            parameters
              requiredPositional p @35
                type: int
            constantInitializers
              ConstructorFieldInitializer
                equals: = @42
                expression: BinaryExpression
                  leftOperand: IntegerLiteral
                    literal: 1 @44
                    staticType: int
                  operator: + @46
                  rightOperand: SimpleIdentifier
                    staticElement: p@35
                    staticType: int
                    token: p @48
                  staticElement: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
                fieldName: SimpleIdentifier
                  staticElement: self::@class::C::@field::x
                  staticType: null
                  token: x @40
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_constructor_initializers_genericFunctionType() async {
    var library = await checkLibrary('''
class A<T> {
  const A();
}
class B {
  const B(dynamic x);
  const B.f()
   : this(A<Function()>());
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class B @34
        constructors
          const @46
            parameters
              requiredPositional x @56
                type: dynamic
          const f @70
            periodOffset: 69
            nameEnd: 71
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    InstanceCreationExpression
                      argumentList: ArgumentList
                        leftParenthesis: ( @97
                        rightParenthesis: ) @98
                      constructorName: ConstructorName
                        staticElement: ConstructorMember
                          base: self::@class::A::@constructor::•
                          substitution: {T: dynamic Function()}
                        type: NamedType
                          name: SimpleIdentifier
                            staticElement: self::@class::A
                            staticType: null
                            token: A @84
                          type: A<dynamic Function()>
                          typeArguments: TypeArgumentList
                            arguments
                              GenericFunctionType
                                declaredElement: GenericFunctionTypeElement
                                  parameters
                                  returnType: dynamic
                                  type: dynamic Function()
                                functionKeyword: Function @86
                                parameters: FormalParameterList
                                  leftParenthesis: ( @94
                                  rightParenthesis: ) @95
                                type: dynamic Function()
                            leftBracket: < @85
                            rightBracket: > @96
                      staticType: A<dynamic Function()>
                  leftParenthesis: ( @83
                  rightParenthesis: ) @99
                staticElement: self::@class::B::@constructor::•
                thisKeyword: this @79
            redirectedConstructor: self::@class::B::@constructor::•
''');
  }

  test_constructor_initializers_superInvocation_argumentContextType() async {
    var library = await checkLibrary('''
class A {
  const A(List<String> values);
}
class B extends A {
  const B() : super(const []);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional values @33
                type: List<String>
      class B @50
        supertype: A
        constructors
          const @72
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    ListLiteral
                      constKeyword: const @84
                      leftBracket: [ @90
                      rightBracket: ] @91
                      staticType: List<String>
                  leftParenthesis: ( @83
                  rightParenthesis: ) @92
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @78
''');
  }

  test_constructor_initializers_superInvocation_named() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const aaa @20
            periodOffset: 19
            nameEnd: 23
            parameters
              requiredPositional p @28
                type: int
      class C @40
        supertype: A
        constructors
          const @62
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 42 @78
                      staticType: int
                  leftParenthesis: ( @77
                  rightParenthesis: ) @80
                constructorName: SimpleIdentifier
                  staticElement: self::@class::A::@constructor::aaa
                  staticType: null
                  token: aaa @74
                period: . @73
                staticElement: self::@class::A::@constructor::aaa
                superKeyword: super @68
''');
  }

  test_constructor_initializers_superInvocation_named_underscore() async {
    var library = await checkLibrary('''
class A {
  const A._();
}
class B extends A {
  const B() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const _ @20
            periodOffset: 19
            nameEnd: 21
      class B @33
        supertype: A
        constructors
          const @55
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @68
                  rightParenthesis: ) @69
                constructorName: SimpleIdentifier
                  staticElement: self::@class::A::@constructor::_
                  staticType: null
                  token: _ @67
                period: . @66
                staticElement: self::@class::A::@constructor::_
                superKeyword: super @61
''');
  }

  test_constructor_initializers_superInvocation_namedExpression() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(a, {int b});
}
class C extends A {
  const C() : super.aaa(1, b: 2);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const aaa @20
            periodOffset: 19
            nameEnd: 23
            parameters
              requiredPositional a @24
                type: dynamic
              optionalNamed b @32
                type: int
      class C @45
        supertype: A
        constructors
          const @67
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 1 @83
                      staticType: int
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          staticElement: self::@class::A::@constructor::aaa::@parameter::b
                          staticType: null
                          token: b @86
                      expression: IntegerLiteral
                        literal: 2 @89
                        staticType: int
                  leftParenthesis: ( @82
                  rightParenthesis: ) @90
                constructorName: SimpleIdentifier
                  staticElement: self::@class::A::@constructor::aaa
                  staticType: null
                  token: aaa @79
                period: . @78
                staticElement: self::@class::A::@constructor::aaa
                superKeyword: super @73
''');
  }

  test_constructor_initializers_superInvocation_unnamed() async {
    var library = await checkLibrary('''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional p @24
                type: int
      class C @36
        supertype: A
        constructors
          const ccc @60
            periodOffset: 59
            nameEnd: 63
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 42 @74
                      staticType: int
                  leftParenthesis: ( @73
                  rightParenthesis: ) @76
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @68
''');
  }

  test_constructor_initializers_thisInvocation_argumentContextType() async {
    var library = await checkLibrary('''
class A {
  const A(List<String> values);
  const A.empty() : this(const []);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional values @33
                type: List<String>
          const empty @52
            periodOffset: 51
            nameEnd: 57
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    ListLiteral
                      constKeyword: const @67
                      leftBracket: [ @73
                      rightBracket: ] @74
                      staticType: List<String>
                  leftParenthesis: ( @66
                  rightParenthesis: ) @75
                staticElement: self::@class::A::@constructor::•
                thisKeyword: this @62
            redirectedConstructor: self::@class::A::@constructor::•
''');
  }

  test_constructor_initializers_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 1 @35
                      staticType: int
                    SimpleStringLiteral
                      literal: 'bbb' @38
                  leftParenthesis: ( @34
                  rightParenthesis: ) @43
                constructorName: SimpleIdentifier
                  staticElement: self::@class::C::@constructor::named
                  staticType: null
                  token: named @29
                period: . @28
                staticElement: self::@class::C::@constructor::named
                thisKeyword: this @24
            redirectedConstructor: self::@class::C::@constructor::named
          const named @56
            periodOffset: 55
            nameEnd: 61
            parameters
              requiredPositional a @66
                type: int
              requiredPositional b @76
                type: String
''');
  }

  test_constructor_initializers_thisInvocation_namedExpression() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, b: 2);
  const C.named(a, {int b});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 1 @35
                      staticType: int
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          staticElement: self::@class::C::@constructor::named::@parameter::b
                          staticType: null
                          token: b @38
                      expression: IntegerLiteral
                        literal: 2 @41
                        staticType: int
                  leftParenthesis: ( @34
                  rightParenthesis: ) @42
                constructorName: SimpleIdentifier
                  staticElement: self::@class::C::@constructor::named
                  staticType: null
                  token: named @29
                period: . @28
                staticElement: self::@class::C::@constructor::named
                thisKeyword: this @24
            redirectedConstructor: self::@class::C::@constructor::named
          const named @55
            periodOffset: 54
            nameEnd: 60
            parameters
              requiredPositional a @61
                type: dynamic
              optionalNamed b @69
                type: int
''');
  }

  test_constructor_initializers_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const named @20
            periodOffset: 19
            nameEnd: 25
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 1 @35
                      staticType: int
                    SimpleStringLiteral
                      literal: 'bbb' @38
                  leftParenthesis: ( @34
                  rightParenthesis: ) @43
                staticElement: self::@class::C::@constructor::•
                thisKeyword: this @30
            redirectedConstructor: self::@class::C::@constructor::•
          const @54
            parameters
              requiredPositional a @60
                type: int
              requiredPositional b @70
                type: String
''');
  }

  test_constructor_redirected_factory_named() async {
    var library = await checkLibrary('''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          factory @20
            redirectedConstructor: self::@class::D::@constructor::named
          _ @39
            periodOffset: 38
            nameEnd: 40
      class D @52
        supertype: C
        constructors
          named @70
            periodOffset: 69
            nameEnd: 75
''');
  }

  test_constructor_redirected_factory_named_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          factory @26
            redirectedConstructor: ConstructorMember
              base: self::@class::D::@constructor::named
              substitution: {T: U, U: T}
          _ @51
            periodOffset: 50
            nameEnd: 52
      class D @64
        typeParameters
          covariant T @66
            defaultType: dynamic
          covariant U @69
            defaultType: dynamic
        supertype: C<U, T>
        constructors
          named @94
            periodOffset: 93
            nameEnd: 99
''');
  }

  test_constructor_redirected_factory_named_generic_viaTypeAlias() async {
    var library = await checkLibrary('''
typedef A<T, U> = C<T, U>;
class B<T, U> {
  factory B() = A<U, T>.named;
  B._();
}
class C<T, U> extends A<U, T> {
  C.named() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @33
        typeParameters
          covariant T @35
            defaultType: dynamic
          covariant U @38
            defaultType: dynamic
        constructors
          factory @53
            redirectedConstructor: ConstructorMember
              base: self::@class::C::@constructor::named
              substitution: {T: U, U: T}
          _ @78
            periodOffset: 77
            nameEnd: 79
      class C @91
        typeParameters
          covariant T @93
            defaultType: dynamic
          covariant U @96
            defaultType: dynamic
        supertype: C<U, T>
          aliasElement: self::@typeAlias::A
          aliasArguments
            U
            T
        constructors
          named @121
            periodOffset: 120
            nameEnd: 126
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
          covariant U @13
            defaultType: dynamic
        aliasedType: C<T, U>
''');
  }

  test_constructor_redirected_factory_named_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class C @25
        constructors
          factory @39
            redirectedConstructor: foo.dart::@class::D::@constructor::named
          _ @58
            periodOffset: 57
            nameEnd: 59
''');
  }

  test_constructor_redirected_factory_named_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class C @25
        typeParameters
          covariant T @27
            defaultType: dynamic
          covariant U @30
            defaultType: dynamic
        constructors
          factory @45
            redirectedConstructor: ConstructorMember
              base: foo.dart::@class::D::@constructor::named
              substitution: {T: U, U: T}
          _ @70
            periodOffset: 69
            nameEnd: 71
''');
  }

  test_constructor_redirected_factory_named_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    classes
      class C @32
        constructors
          factory @46
            redirectedConstructor: foo.dart::@class::D::@constructor::named
          _ @69
            periodOffset: 68
            nameEnd: 70
''');
  }

  test_constructor_redirected_factory_named_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    classes
      class C @32
        typeParameters
          covariant T @34
            defaultType: dynamic
          covariant U @37
            defaultType: dynamic
        constructors
          factory @52
            redirectedConstructor: ConstructorMember
              base: foo.dart::@class::D::@constructor::named
              substitution: {T: U, U: T}
          _ @81
            periodOffset: 80
            nameEnd: 82
''');
  }

  test_constructor_redirected_factory_named_unresolved_class() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant E @8
            defaultType: dynamic
        constructors
          factory @23
''');
  }

  test_constructor_redirected_factory_named_unresolved_constructor() async {
    var library = await checkLibrary('''
class D {}
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class D @6
        constructors
          synthetic @-1
      class C @17
        typeParameters
          covariant E @19
            defaultType: dynamic
        constructors
          factory @34
''');
  }

  test_constructor_redirected_factory_unnamed() async {
    var library = await checkLibrary('''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          factory @20
            redirectedConstructor: self::@class::D::@constructor::•
          _ @33
            periodOffset: 32
            nameEnd: 34
      class D @46
        supertype: C
        constructors
          @62
''');
  }

  test_constructor_redirected_factory_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          factory @26
            redirectedConstructor: ConstructorMember
              base: self::@class::D::@constructor::•
              substitution: {T: U, U: T}
          _ @45
            periodOffset: 44
            nameEnd: 46
      class D @58
        typeParameters
          covariant T @60
            defaultType: dynamic
          covariant U @63
            defaultType: dynamic
        supertype: C<U, T>
        constructors
          @86
''');
  }

  test_constructor_redirected_factory_unnamed_generic_viaTypeAlias() async {
    var library = await checkLibrary('''
typedef A<T, U> = C<T, U>;
class B<T, U> {
  factory B() = A<U, T>;
  B_();
}
class C<T, U> extends B<U, T> {
  C() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @33
        typeParameters
          covariant T @35
            defaultType: dynamic
          covariant U @38
            defaultType: dynamic
        constructors
          factory @53
            redirectedConstructor: ConstructorMember
              base: self::@class::C::@constructor::•
              substitution: {T: U, U: T}
        methods
          abstract B_ @70
            returnType: dynamic
      class C @84
        typeParameters
          covariant T @86
            defaultType: dynamic
          covariant U @89
            defaultType: dynamic
        supertype: B<U, T>
        constructors
          @112
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
          covariant U @13
            defaultType: dynamic
        aliasedType: C<T, U>
''');
  }

  test_constructor_redirected_factory_unnamed_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class C @25
        constructors
          factory @39
            redirectedConstructor: foo.dart::@class::D::@constructor::•
          _ @52
            periodOffset: 51
            nameEnd: 53
''');
  }

  test_constructor_redirected_factory_unnamed_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class C @25
        typeParameters
          covariant T @27
            defaultType: dynamic
          covariant U @30
            defaultType: dynamic
        constructors
          factory @45
            redirectedConstructor: ConstructorMember
              base: foo.dart::@class::D::@constructor::•
              substitution: {T: U, U: T}
          _ @64
            periodOffset: 63
            nameEnd: 65
''');
  }

  test_constructor_redirected_factory_unnamed_imported_viaTypeAlias() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
typedef A = B;
class B extends C {
  B() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = A;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class C @25
        constructors
          factory @39
            redirectedConstructor: foo.dart::@class::B::@constructor::•
          _ @52
            periodOffset: 51
            nameEnd: 53
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    classes
      class C @32
        constructors
          factory @46
            redirectedConstructor: foo.dart::@class::D::@constructor::•
          _ @63
            periodOffset: 62
            nameEnd: 64
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    classes
      class C @32
        typeParameters
          covariant T @34
            defaultType: dynamic
          covariant U @37
            defaultType: dynamic
        constructors
          factory @52
            redirectedConstructor: ConstructorMember
              base: foo.dart::@class::D::@constructor::•
              substitution: {T: U, U: T}
          _ @75
            periodOffset: 74
            nameEnd: 76
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed_viaTypeAlias() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
typedef A = B;
class B extends C {
  B() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.A;
  C._();
}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    classes
      class C @32
        constructors
          factory @46
            redirectedConstructor: foo.dart::@class::B::@constructor::•
          _ @63
            periodOffset: 62
            nameEnd: 64
''');
  }

  test_constructor_redirected_factory_unnamed_unresolved() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant E @8
            defaultType: dynamic
        constructors
          factory @23
''');
  }

  test_constructor_redirected_factory_unnamed_viaTypeAlias() async {
    var library = await checkLibrary('''
typedef A = C;
class B {
  factory B() = A;
  B._();
}
class C extends B {
  C() : super._();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @21
        constructors
          factory @35
            redirectedConstructor: self::@class::C::@constructor::•
          _ @48
            periodOffset: 47
            nameEnd: 49
      class C @61
        supertype: B
        constructors
          @77
    typeAliases
      A @8
        aliasedType: C
''');
  }

  test_constructor_redirected_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  const C.named();
  const C() : this.named();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const named @20
            periodOffset: 19
            nameEnd: 25
          const @37
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @53
                  rightParenthesis: ) @54
                constructorName: SimpleIdentifier
                  staticElement: self::@class::C::@constructor::named
                  staticType: null
                  token: named @48
                period: . @47
                staticElement: self::@class::C::@constructor::named
                thisKeyword: this @43
            redirectedConstructor: self::@class::C::@constructor::named
''');
  }

  test_constructor_redirected_thisInvocation_named_generic() async {
    var library = await checkLibrary('''
class C<T> {
  const C.named();
  const C() : this.named();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const named @23
            periodOffset: 22
            nameEnd: 28
          const @40
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @56
                  rightParenthesis: ) @57
                constructorName: SimpleIdentifier
                  staticElement: self::@class::C::@constructor::named
                  staticType: null
                  token: named @51
                period: . @50
                staticElement: self::@class::C::@constructor::named
                thisKeyword: this @46
            redirectedConstructor: self::@class::C::@constructor::named
''');
  }

  test_constructor_redirected_thisInvocation_named_notConst() async {
    var library = await checkLibrary('''
class C {
  C.named();
  C() : this.named();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          named @14
            periodOffset: 13
            nameEnd: 19
          @25
            redirectedConstructor: self::@class::C::@constructor::named
''');
  }

  test_constructor_redirected_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  const C();
  const C.named() : this();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          const @18
          const named @33
            periodOffset: 32
            nameEnd: 38
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @47
                  rightParenthesis: ) @48
                staticElement: self::@class::C::@constructor::•
                thisKeyword: this @43
            redirectedConstructor: self::@class::C::@constructor::•
''');
  }

  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T> {
  const C();
  const C.named() : this();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
          const named @36
            periodOffset: 35
            nameEnd: 41
            constantInitializers
              RedirectingConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @50
                  rightParenthesis: ) @51
                staticElement: self::@class::C::@constructor::•
                thisKeyword: this @46
            redirectedConstructor: self::@class::C::@constructor::•
''');
  }

  test_constructor_redirected_thisInvocation_unnamed_notConst() async {
    var library = await checkLibrary('''
class C {
  C();
  C.named() : this();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @12
          named @21
            periodOffset: 20
            nameEnd: 26
            redirectedConstructor: self::@class::C::@constructor::•
''');
  }

  test_constructor_withCycles_const() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          const @29
            constantInitializers
              ConstructorFieldInitializer
                equals: = @37
                expression: InstanceCreationExpression
                  argumentList: ArgumentList
                    leftParenthesis: ( @46
                    rightParenthesis: ) @47
                  constructorName: ConstructorName
                    staticElement: self::@class::D::@constructor::•
                    type: NamedType
                      name: SimpleIdentifier
                        staticElement: self::@class::D
                        staticType: null
                        token: D @45
                      type: D
                  keyword: const @39
                  staticType: D
                fieldName: SimpleIdentifier
                  staticElement: self::@class::C::@field::x
                  staticType: null
                  token: x @35
        accessors
          synthetic get x @-1
            returnType: dynamic
      class D @58
        fields
          final x @70
            type: dynamic
        constructors
          const @81
            constantInitializers
              ConstructorFieldInitializer
                equals: = @89
                expression: InstanceCreationExpression
                  argumentList: ArgumentList
                    leftParenthesis: ( @98
                    rightParenthesis: ) @99
                  constructorName: ConstructorName
                    staticElement: self::@class::C::@constructor::•
                    type: NamedType
                      name: SimpleIdentifier
                        staticElement: self::@class::C
                        staticType: null
                        token: C @97
                      type: C
                  keyword: const @91
                  staticType: C
                fieldName: SimpleIdentifier
                  staticElement: self::@class::D::@field::x
                  staticType: null
                  token: x @87
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_constructor_withCycles_nonConst() async {
    var library = await checkLibrary('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: dynamic
        constructors
          @23
        accessors
          synthetic get x @-1
            returnType: dynamic
      class D @50
        fields
          final x @62
            type: dynamic
        constructors
          @67
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_defaultValue_eliminateTypeParameters() async {
    var library = await checkLibrary('''
class A<T> {
  const X({List<T> a = const []});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          abstract X @21
            parameters
              optionalNamed a @32
                type: List<T>
                constantInitializer
                  ListLiteral
                    constKeyword: const @36
                    leftBracket: [ @42
                    rightBracket: ] @43
                    staticType: List<Never>
            returnType: dynamic
''');
  }

  test_defaultValue_eliminateTypeParameters_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class A<T> {
  const X({List<T> a = const []});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          abstract X @21
            parameters
              optionalNamed a @32
                type: List<T*>*
                constantInitializer
                  ListLiteral
                    constKeyword: const @36
                    leftBracket: [ @42
                    rightBracket: ] @43
                    staticType: List<Null*>*
            returnType: dynamic
''');
  }

  test_defaultValue_genericFunction() async {
    var library = await checkLibrary('''
typedef void F<T>(T v);

void defaultF<T>(T v) {}

class X {
  final F f;
  const X({this.f: defaultF});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class X @57
        fields
          final f @71
            type: void Function(dynamic)
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
        constructors
          const @82
            parameters
              optionalNamed final this.f @90
                type: void Function(dynamic)
                  aliasElement: self::@typeAlias::F
                  aliasArguments
                    dynamic
                constantInitializer
                  FunctionReference
                    function: SimpleIdentifier
                      staticElement: self::@function::defaultF
                      staticType: void Function<T>(T)
                      token: defaultF @93
                    staticType: void Function(dynamic)
                    typeArgumentTypes
                      dynamic
        accessors
          synthetic get f @-1
            returnType: void Function(dynamic)
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
    typeAliases
      functionTypeAliasBased F @13
        typeParameters
          contravariant T @15
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional v @20
              type: T
          returnType: void
    functions
      defaultF @30
        typeParameters
          covariant T @39
        parameters
          requiredPositional v @44
            type: T
        returnType: void
''');
  }

  test_defaultValue_genericFunctionType() async {
    var library = await checkLibrary('''
class A<T> {
  const A();
}
class B {
  void foo({a: const A<Function()>()}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class B @34
        constructors
          synthetic @-1
        methods
          foo @45
            parameters
              optionalNamed a @50
                type: dynamic
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @72
                      rightParenthesis: ) @73
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::A::@constructor::•
                        substitution: {T: dynamic Function()}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::A
                          staticType: null
                          token: A @59
                        type: A<dynamic Function()>
                        typeArguments: TypeArgumentList
                          arguments
                            GenericFunctionType
                              declaredElement: GenericFunctionTypeElement
                                parameters
                                returnType: dynamic
                                type: dynamic Function()
                              functionKeyword: Function @61
                              parameters: FormalParameterList
                                leftParenthesis: ( @69
                                rightParenthesis: ) @70
                              type: dynamic Function()
                          leftBracket: < @60
                          rightBracket: > @71
                    keyword: const @53
                    staticType: A<dynamic Function()>
            returnType: void
''');
  }

  test_defaultValue_inFunctionTypedFormalParameter() async {
    var library = await checkLibrary('''
void f( g({a: 0 is int}) ) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional g @8
            type: dynamic Function({dynamic a})
            parameters
              optionalNamed a @11
                type: dynamic
                constantInitializer
                  IsExpression
                    expression: IntegerLiteral
                      literal: 0 @14
                      staticType: int
                    isOperator: is @16
                    staticType: bool
                    type: NamedType
                      name: SimpleIdentifier
                        staticElement: dart:core::@class::int
                        staticType: null
                        token: int @19
                      type: int
        returnType: void
''');
  }

  test_defaultValue_methodMember_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
void f([Comparator<T> compare = Comparable.compare]) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          optionalPositional compare @22
            type: int* Function(dynamic, dynamic)*
              aliasElement: dart:core::@typeAlias::Comparator
              aliasArguments
                dynamic
            constantInitializer
              PrefixedIdentifier
                identifier: SimpleIdentifier
                  staticElement: MethodMember
                    base: dart:core::@class::Comparable::@method::compare
                    substitution: {}
                  staticType: int* Function(Comparable<dynamic>*, Comparable<dynamic>*)*
                  token: compare @43
                period: . @42
                prefix: SimpleIdentifier
                  staticElement: dart:core::@class::Comparable
                  staticType: null
                  token: Comparable @32
                staticElement: MethodMember
                  base: dart:core::@class::Comparable::@method::compare
                  substitution: {}
                staticType: int* Function(Comparable<dynamic>*, Comparable<dynamic>*)*
        returnType: void
''');
  }

  test_defaultValue_refersToExtension_method_inside() async {
    var library = await checkLibrary('''
class A {}
extension E on A {
  static void f() {}
  static void g([Object p = f]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    extensions
      E @21
        extendedType: A
        methods
          static f @44
            returnType: void
          static g @65
            parameters
              optionalPositional p @75
                type: Object
                constantInitializer
                  SimpleIdentifier
                    staticElement: self::@extension::E::@method::f
                    staticType: void Function()
                    token: f @79
            returnType: void
''');
  }

  test_defaultValue_refersToGenericClass() async {
    var library = await checkLibrary('''
class B<T1, T2> {
  const B();
}
class C {
  void foo([B<int, double> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T1 @8
            defaultType: dynamic
          covariant T2 @12
            defaultType: dynamic
        constructors
          const @26
      class C @39
        constructors
          synthetic @-1
        methods
          foo @50
            parameters
              optionalPositional b @70
                type: B<int, double>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @81
                      rightParenthesis: ) @82
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T1: int, T2: double}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @80
                        type: B<int, double>
                    keyword: const @74
                    staticType: B<int, double>
            returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_constructor() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const B()]);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class C @34
        typeParameters
          covariant T @36
            defaultType: dynamic
        constructors
          const @49
            parameters
              optionalPositional b @57
                type: B<T>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @68
                      rightParenthesis: ) @69
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Never}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @67
                        type: B<Never>
                    keyword: const @61
                    staticType: B<Never>
''');
  }

  test_defaultValue_refersToGenericClass_constructor2() async {
    var library = await checkLibrary('''
abstract class A<T> {}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const B()]);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant T @17
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @29
        typeParameters
          covariant T @31
            defaultType: dynamic
        interfaces
          A<T>
        constructors
          const @60
      class C @73
        typeParameters
          covariant T @75
            defaultType: dynamic
        interfaces
          A<Iterable<T>>
        constructors
          const @114
            parameters
              optionalPositional a @122
                type: A<T>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @133
                      rightParenthesis: ) @134
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Never}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @132
                        type: B<Never>
                    keyword: const @126
                    staticType: B<Never>
''');
  }

  test_defaultValue_refersToGenericClass_constructor2_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
abstract class A<T> {}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const B()]);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant T @17
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @29
        typeParameters
          covariant T @31
            defaultType: dynamic
        interfaces
          A<T*>*
        constructors
          const @60
      class C @73
        typeParameters
          covariant T @75
            defaultType: dynamic
        interfaces
          A<Iterable<T*>*>*
        constructors
          const @114
            parameters
              optionalPositional a @122
                type: A<T*>*
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @133
                      rightParenthesis: ) @134
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Null*}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @132
                        type: B<Null*>*
                    keyword: const @126
                    staticType: B<Null*>*
''');
  }

  test_defaultValue_refersToGenericClass_constructor_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const B()]);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class C @34
        typeParameters
          covariant T @36
            defaultType: dynamic
        constructors
          const @49
            parameters
              optionalPositional b @57
                type: B<T*>*
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @68
                      rightParenthesis: ) @69
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Null*}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @67
                        type: B<Null*>*
                    keyword: const @61
                    staticType: B<Null*>*
''');
  }

  test_defaultValue_refersToGenericClass_functionG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const B()]) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    functions
      foo @33
        typeParameters
          covariant T @37
        parameters
          optionalPositional b @46
            type: B<T>
            constantInitializer
              InstanceCreationExpression
                argumentList: ArgumentList
                  leftParenthesis: ( @57
                  rightParenthesis: ) @58
                constructorName: ConstructorName
                  staticElement: ConstructorMember
                    base: self::@class::B::@constructor::•
                    substitution: {T: Never}
                  type: NamedType
                    name: SimpleIdentifier
                      staticElement: self::@class::B
                      staticType: null
                      token: B @56
                    type: B<Never>
                keyword: const @50
                staticType: B<Never>
        returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class C @34
        constructors
          synthetic @-1
        methods
          foo @45
            typeParameters
              covariant T @49
            parameters
              optionalPositional b @58
                type: B<T>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @69
                      rightParenthesis: ) @70
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Never}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @68
                        type: B<Never>
                    keyword: const @62
                    staticType: B<Never>
            returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG_classG() async {
    var library = await checkLibrary('''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T1 @8
            defaultType: dynamic
          covariant T2 @12
            defaultType: dynamic
        constructors
          const @26
      class C @39
        typeParameters
          covariant E1 @41
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          foo @54
            typeParameters
              covariant E2 @58
            parameters
              optionalPositional b @73
                type: B<E1, E2>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @84
                      rightParenthesis: ) @85
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T1: Never, T2: Never}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @83
                        type: B<Never, Never>
                    keyword: const @77
                    staticType: B<Never, Never>
            returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodNG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class C @34
        typeParameters
          covariant T @36
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          foo @48
            parameters
              optionalPositional b @58
                type: B<T>
                constantInitializer
                  InstanceCreationExpression
                    argumentList: ArgumentList
                      leftParenthesis: ( @69
                      rightParenthesis: ) @70
                    constructorName: ConstructorName
                      staticElement: ConstructorMember
                        base: self::@class::B::@constructor::•
                        substitution: {T: Never}
                      type: NamedType
                        name: SimpleIdentifier
                          staticElement: self::@class::B
                          staticType: null
                          token: B @68
                        type: B<Never>
                    keyword: const @62
                    staticType: B<Never>
            returnType: void
''');
  }

  test_duplicateDeclaration_class() async {
    var library = await checkLibrary(r'''
class A {}
class A {
  var x;
}
class A {
  var y = 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class A @17
        fields
          x @27
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
      class A @38
        fields
          y @48
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get y @-1
            returnType: int
          synthetic set y @-1
            parameters
              requiredPositional _y @-1
                type: int
            returnType: void
''');
  }

  test_duplicateDeclaration_classTypeAlias() async {
    var library = await checkLibrary(r'''
class A {}
class B {}
class X = A with M;
class X = B with M;
mixin M {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @17
        constructors
          synthetic @-1
      class alias X @28
        supertype: A
        mixins
          M
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
      class alias X @48
        supertype: B
        mixins
          M
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::B::@constructor::•
                superKeyword: super @0
    mixins
      mixin M @68
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_duplicateDeclaration_enum() async {
    var library = await checkLibrary(r'''
enum E {a, b}
enum E {c, d, e}
''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @8
            type: E
          static const b @11
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
      enum E @19
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const c @22
            type: E
          static const d @25
            type: E
          static const e @28
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get c @-1
            returnType: E
          synthetic static get d @-1
            returnType: E
          synthetic static get e @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_duplicateDeclaration_extension() async {
    var library = await checkLibrary(r'''
class A {}
extension E on A {}
extension E on A {
  static var x;
}
extension E on A {
  static var y = 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    extensions
      E @21
        extendedType: A
      E @41
        extendedType: A
        fields
          static x @63
            type: dynamic
        accessors
          synthetic static get x @-1
            returnType: dynamic
          synthetic static set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
      E @78
        extendedType: A
        fields
          static y @100
            type: int
        accessors
          synthetic static get y @-1
            returnType: int
          synthetic static set y @-1
            parameters
              requiredPositional _y @-1
                type: int
            returnType: void
''');
  }

  test_duplicateDeclaration_function() async {
    var library = await checkLibrary(r'''
void f() {}
void f(int a) {}
void f([int b, double c]) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        returnType: void
      f @17
        parameters
          requiredPositional a @23
            type: int
        returnType: void
      f @34
        parameters
          optionalPositional b @41
            type: int
          optionalPositional c @51
            type: double
        returnType: void
''');
  }

  test_duplicateDeclaration_functionTypeAlias() async {
    var library = await checkLibrary(r'''
typedef void F();
typedef void F(int a);
typedef void F([int b, double c]);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
      functionTypeAliasBased F @31
        aliasedType: void Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @37
              type: int
          returnType: void
      functionTypeAliasBased F @54
        aliasedType: void Function([int, double])
        aliasedElement: GenericFunctionTypeElement
          parameters
            optionalPositional b @61
              type: int
            optionalPositional c @71
              type: double
          returnType: void
''');
  }

  test_duplicateDeclaration_mixin() async {
    var library = await checkLibrary(r'''
mixin A {}
mixin A {
  var x;
}
mixin A {
  var y = 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin A @6
        superclassConstraints
          Object
        constructors
          synthetic @-1
      mixin A @17
        superclassConstraints
          Object
        fields
          x @27
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
      mixin A @38
        superclassConstraints
          Object
        fields
          y @48
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get y @-1
            returnType: int
          synthetic set y @-1
            parameters
              requiredPositional _y @-1
                type: int
            returnType: void
''');
  }

  test_duplicateDeclaration_topLevelVariable() async {
    var library = await checkLibrary(r'''
bool x;
var x;
var x = 1;
var x = 2.3;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @5
        type: bool
      static x @12
        type: dynamic
      static x @19
        type: int
      static x @30
        type: double
    accessors
      synthetic static get x @-1
        returnType: bool
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: bool
        returnType: void
      synthetic static get x @-1
        returnType: dynamic
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: dynamic
        returnType: void
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
      synthetic static get x @-1
        returnType: double
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: double
        returnType: void
''');
  }

  test_enum_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @65
        documentationComment: /**\n * Docs\n */
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @69
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_enum_value_documented() async {
    var library = await checkLibrary('''
enum E {
  /**
   * aaa
   */
  a,
  /// bbb
  b
}''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @32
            documentationComment: /**\n   * aaa\n   */
            type: E
          static const b @47
            documentationComment: /// bbb
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_enum_value_documented_withMetadata() async {
    var library = await checkLibrary('''
enum E {
  /**
   * aaa
   */
  @annotation
  a,
  /// bbb
  @annotation
  b,
}

const int annotation = 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @46
            documentationComment: /**\n   * aaa\n   */
            metadata
              Annotation
                atSign: @ @32
                element: self::@getter::annotation
                name: SimpleIdentifier
                  staticElement: self::@getter::annotation
                  staticType: null
                  token: annotation @33
            type: E
          static const b @75
            documentationComment: /// bbb
            metadata
              Annotation
                atSign: @ @61
                element: self::@getter::annotation
                name: SimpleIdentifier
                  staticElement: self::@getter::annotation
                  staticType: null
                  token: annotation @62
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static const annotation @91
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @104
            staticType: int
    accessors
      synthetic static get annotation @-1
        returnType: int
''');
  }

  test_enum_values() async {
    var library = await checkLibrary('enum E { v1, v2 }');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v1 @9
            type: E
          static const v2 @13
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v1 @-1
            returnType: E
          synthetic static get v2 @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_enums() async {
    var library = await checkLibrary('enum E1 { v1 } enum E2 { v2 }');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E1 @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E1>
          static const v1 @10
            type: E1
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E1>
          synthetic static get v1 @-1
            returnType: E1
        methods
          synthetic toString @-1
            returnType: String
      enum E2 @20
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E2>
          static const v2 @25
            type: E2
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E2>
          synthetic static get v2 @-1
            returnType: E2
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_error_extendsEnum() async {
    var library = await checkLibrary('''
enum E {a, b, c}

class M {}

class A extends E {
  foo() {}
}

class B implements E, M {
  foo() {}
}

class C extends Object with E, M {
  foo() {}
}

class D = Object with M, E;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class M @24
        constructors
          synthetic @-1
      class A @36
        constructors
          synthetic @-1
        methods
          foo @52
            returnType: dynamic
      class B @70
        interfaces
          M
        constructors
          synthetic @-1
        methods
          foo @92
            returnType: dynamic
      class C @110
        supertype: Object
        mixins
          M
        constructors
          synthetic @-1
        methods
          foo @141
            returnType: dynamic
      class alias D @159
        supertype: Object
        mixins
          M
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
                superKeyword: super @0
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @8
            type: E
          static const b @11
            type: E
          static const c @14
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
          synthetic static get c @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_executable_parameter_type_typedef() async {
    var library = await checkLibrary(r'''
typedef F(int p);
main(F f) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional p @14
              type: int
          returnType: dynamic
    functions
      main @18
        parameters
          requiredPositional f @25
            type: dynamic Function(int)
              aliasElement: self::@typeAlias::F
        returnType: dynamic
''');
  }

  test_export_class() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    C: a.dart;C
''',
        withExportScope: true);
  }

  test_export_class_type_alias() async {
    addLibrarySource('/a.dart', r'''
class C = _D with _E;
class _D {}
class _E {}
''');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    C: a.dart;C
''',
        withExportScope: true);
  }

  test_export_configurations_useDefault() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(
        library,
        r'''
library
  exports
    foo.dart
  definingUnit
  exportScope
    A: foo.dart;A
''',
        withExportScope: true);
    expect(library.exports[0].exportedLibrary!.source.shortName, 'foo.dart');
  }

  test_export_configurations_useFirst() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(
        library,
        r'''
library
  exports
    foo_io.dart
  definingUnit
  exportScope
    A: foo_io.dart;A
''',
        withExportScope: true);
    expect(library.exports[0].exportedLibrary!.source.shortName, 'foo_io.dart');
  }

  test_export_configurations_useSecond() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(
        library,
        r'''
library
  exports
    foo_html.dart
  definingUnit
  exportScope
    A: foo_html.dart;A
''',
        withExportScope: true);
    ExportElement export = library.exports[0];
    expect(export.exportedLibrary!.source.shortName, 'foo_html.dart');
  }

  test_export_function() async {
    addLibrarySource('/a.dart', 'f() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    f: a.dart;f
''',
        withExportScope: true);
  }

  test_export_getter() async {
    addLibrarySource('/a.dart', 'get f() => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_export_hide() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream, Future;');
    checkElementText(
        library,
        r'''
library
  exports
    dart:async
      combinators
        hide: Stream, Future
  definingUnit
  exportScope
    Completer: dart:async;Completer
    FutureOr: dart:async;FutureOr
    StreamIterator: dart:async;dart:async/stream.dart;StreamIterator
    StreamSubscription: dart:async;dart:async/stream.dart;StreamSubscription
    StreamTransformer: dart:async;dart:async/stream.dart;StreamTransformer
    Timer: dart:async;Timer
''',
        withExportScope: true);
  }

  test_export_multiple_combinators() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream show Future;');
    checkElementText(
        library,
        r'''
library
  exports
    dart:async
      combinators
        hide: Stream
        show: Future
  definingUnit
  exportScope
    Future: dart:async;Future
''',
        withExportScope: true);
  }

  test_export_setter() async {
    addLibrarySource('/a.dart', 'void set f(value) {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    f=: a.dart;f=
''',
        withExportScope: true);
  }

  test_export_show() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" show Future, Stream;');
    checkElementText(
        library,
        r'''
library
  exports
    dart:async
      combinators
        show: Future, Stream
  definingUnit
  exportScope
    Future: dart:async;Future
    Stream: dart:async;dart:async/stream.dart;Stream
''',
        withExportScope: true);
  }

  test_export_show_getter_setter() async {
    addLibrarySource('/a.dart', '''
get f => null;
void set f(value) {}
''');
    var library = await checkLibrary('export "a.dart" show f;');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
      combinators
        show: f
  definingUnit
  exportScope
    f: a.dart;f?
    f=: a.dart;f=
''',
        withExportScope: true);
  }

  test_export_typedef() async {
    addLibrarySource('/a.dart', 'typedef F();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    F: a.dart;F
''',
        withExportScope: true);
  }

  test_export_uri() async {
    var library = await checkLibrary('''
export 'foo.dart';
''');
    expect(library.exports[0].uri, 'foo.dart');
  }

  test_export_variable() async {
    addLibrarySource('/a.dart', 'var x;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    x: a.dart;x?
    x=: a.dart;x=
''',
        withExportScope: true);
  }

  test_export_variable_const() async {
    addLibrarySource('/a.dart', 'const x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    x: a.dart;x?
''',
        withExportScope: true);
  }

  test_export_variable_final() async {
    addLibrarySource('/a.dart', 'final x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
  definingUnit
  exportScope
    x: a.dart;x?
''',
        withExportScope: true);
  }

  test_exportImport_configurations_useDefault() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    bar.dart
  definingUnit
    classes
      class B @25
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_exportImport_configurations_useFirst() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'true',
      'dart.library.html': 'false',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    bar.dart
  definingUnit
    classes
      class B @25
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_exportImport_configurations_useSecond() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    bar.dart
  definingUnit
    classes
      class B @25
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_exports() async {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    var library = await checkLibrary('export "a.dart"; export "b.dart";');
    checkElementText(
        library,
        r'''
library
  exports
    a.dart
    b.dart
  definingUnit
  exportScope
''',
        withExportScope: true);
  }

  test_expr_invalid_typeParameter_asPrefix() async {
    var library = await checkLibrary('''
class C<T> {
  final f = T.k;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          final f @21
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: dynamic
''');
  }

  test_extension_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// bbbb
/// cc
extension E on int {}''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      E @34
        documentationComment: /// aaa\n/// bbbb\n/// cc
        extendedType: int
''');
  }

  test_extension_field_inferredType_const() async {
    var library = await checkLibrary('''
extension E on int {
  static const x = 0;
}''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      E @10
        extendedType: int
        fields
          static const x @36
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @40
                staticType: int
        accessors
          synthetic static get x @-1
            returnType: int
''');
  }

  test_field_abstract() async {
    var library = await checkLibrary('''
abstract class C {
  abstract int i;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        fields
          abstract i @34
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic abstract get i @-1
            returnType: int
          synthetic abstract set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
''');
  }

  test_field_covariant() async {
    var library = await checkLibrary('''
class C {
  covariant int x;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          covariant x @26
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional covariant _x @-1
                type: int
            returnType: void
''');
  }

  test_field_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @38
            documentationComment: /**\n   * Docs\n   */
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_field_external() async {
    var library = await checkLibrary('''
abstract class C {
  external int i;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class C @15
        fields
          external i @34
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get i @-1
            returnType: int
          synthetic set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
''');
  }

  test_field_final_hasInitializer_hasConstConstructor() async {
    var library = await checkLibrary('''
class C {
  final x = 42;
  const C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: int
            constantInitializer
              IntegerLiteral
                literal: 42 @22
                staticType: int
        constructors
          const @34
        accessors
          synthetic get x @-1
            returnType: int
''');
  }

  test_field_final_hasInitializer_hasConstConstructor_genericFunctionType() async {
    var library = await checkLibrary('''
class A<T> {
  const A();
}
class B {
  final f = const A<int Function(double a)>();
  const B();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class B @34
        fields
          final f @46
            type: A<int Function(double)>
            constantInitializer
              InstanceCreationExpression
                argumentList: ArgumentList
                  leftParenthesis: ( @81
                  rightParenthesis: ) @82
                constructorName: ConstructorName
                  staticElement: ConstructorMember
                    base: self::@class::A::@constructor::•
                    substitution: {T: int Function(double)}
                  type: NamedType
                    name: SimpleIdentifier
                      staticElement: self::@class::A
                      staticType: null
                      token: A @56
                    type: A<int Function(double)>
                    typeArguments: TypeArgumentList
                      arguments
                        GenericFunctionType
                          declaredElement: GenericFunctionTypeElement
                            parameters
                              a
                                kind: required positional
                                type: double
                            returnType: int
                            type: int Function(double)
                          functionKeyword: Function @62
                          parameters: FormalParameterList
                            leftParenthesis: ( @70
                            parameters
                              SimpleFormalParameter
                                declaredElement: a@78
                                declaredElementType: double
                                identifier: SimpleIdentifier
                                  staticElement: a@78
                                  staticType: null
                                  token: a @78
                                type: NamedType
                                  name: SimpleIdentifier
                                    staticElement: dart:core::@class::double
                                    staticType: null
                                    token: double @71
                                  type: double
                            rightParenthesis: ) @79
                          returnType: NamedType
                            name: SimpleIdentifier
                              staticElement: dart:core::@class::int
                              staticType: null
                              token: int @58
                            type: int
                          type: int Function(double)
                      leftBracket: < @57
                      rightBracket: > @80
                keyword: const @50
                staticType: A<int Function(double)>
        constructors
          const @93
        accessors
          synthetic get f @-1
            returnType: A<int Function(double)>
''');
  }

  test_field_final_hasInitializer_noConstConstructor() async {
    var library = await checkLibrary('''
class C {
  final x = 42;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
''');
  }

  test_field_formal_param_inferred_type_implicit() async {
    var library = await checkLibrary('class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        fields
          v @24
            type: int
        constructors
          @27
            parameters
              requiredPositional final this.v @34
                type: int
        accessors
          synthetic get v @-1
            returnType: int
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int
            returnType: void
      abstract class D @55
        fields
          synthetic v @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get v @67
            returnType: int
''');
  }

  test_field_inferred_type_nonStatic_explicit_initialized() async {
    var library = await checkLibrary('class C { num v = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          v @14
            type: num
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: num
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: num
            returnType: void
''');
  }

  test_field_inferred_type_nonStatic_implicit_initialized() async {
    var library = await checkLibrary('class C { var v = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          v @14
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: int
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int
            returnType: void
''');
  }

  test_field_inferred_type_nonStatic_implicit_uninitialized() async {
    var library = await checkLibrary(
        'class C extends D { var v; } abstract class D { int get v; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        fields
          v @24
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: int
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int
            returnType: void
      abstract class D @44
        fields
          synthetic v @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get v @56
            returnType: int
''');
  }

  test_field_inferred_type_nonStatic_inherited_resolveInitializer() async {
    var library = await checkLibrary(r'''
const a = 0;
abstract class A {
  const A();
  List<int> get f;
}
class B extends A {
  const B();
  final f = [a];
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @28
        fields
          synthetic f @-1
            type: List<int>
        constructors
          const @40
        accessors
          abstract get f @61
            returnType: List<int>
      class B @72
        supertype: A
        fields
          final f @107
            type: List<int>
            constantInitializer
              ListLiteral
                elements
                  SimpleIdentifier
                    staticElement: self::@getter::a
                    staticType: int
                    token: a @112
                leftBracket: [ @111
                rightBracket: ] @113
                staticType: List<int>
        constructors
          const @94
        accessors
          synthetic get f @-1
            returnType: List<int>
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_field_inferred_type_static_implicit_initialized() async {
    var library = await checkLibrary('class C { static var v = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static v @21
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get v @-1
            returnType: int
          synthetic static set v @-1
            parameters
              requiredPositional _v @-1
                type: int
            returnType: void
''');
  }

  test_field_propagatedType_const_noDep() async {
    var library = await checkLibrary('''
class C {
  static const x = 0;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static const x @25
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @29
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get x @-1
            returnType: int
''');
  }

  test_field_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class C @23
        fields
          final b @35
            type: double
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: double
''');
  }

  test_field_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library = await checkLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
library
  name: lib
  nameOffset: 8
  definingUnit
    classes
      class C @34
        fields
          final b @46
            type: double
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: double
  parts
    a.dart
      topLevelVariables
        static final a @19
          type: int
      accessors
        synthetic static get a @-1
          returnType: int
''');
  }

  test_field_propagatedType_final_noDep_instance() async {
    var library = await checkLibrary('''
class C {
  final x = 0;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @18
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
''');
  }

  test_field_propagatedType_final_noDep_static() async {
    var library = await checkLibrary('''
class C {
  static final x = 0;
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static final x @25
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get x @-1
            returnType: int
''');
  }

  test_field_static_final_untyped() async {
    var library = await checkLibrary('class C { static final x = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static final x @23
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get x @-1
            returnType: int
''');
  }

  test_field_type_inferred_Never() async {
    var library = await checkLibrary(r'''
class C {
  var a = throw 42;
}
''');

    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          a @16
            type: Never
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: Never
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: Never
            returnType: void
''');
  }

  test_field_type_inferred_nonNullify() async {
    addSource('/a.dart', '''
// @dart = 2.7
var a = 0;
''');

    var library = await checkLibrary(r'''
import 'a.dart';
class C {
  var b = a;
}
''');

    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class C @23
        fields
          b @33
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: int
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: int
            returnType: void
''');
  }

  test_field_typed() async {
    var library = await checkLibrary('class C { int x = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_field_untyped() async {
    var library = await checkLibrary('class C { var x = 0; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @14
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_finalField_hasConstConstructor() async {
    var library = await checkLibrary(r'''
class C1  {
  final List<int> f1 = const [];
  const C1();
}
class C2  {
  final List<int> f2 = const [];
  C2();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C1 @6
        fields
          final f1 @30
            type: List<int>
            constantInitializer
              ListLiteral
                constKeyword: const @35
                leftBracket: [ @41
                rightBracket: ] @42
                staticType: List<int>
        constructors
          const @53
        accessors
          synthetic get f1 @-1
            returnType: List<int>
      class C2 @67
        fields
          final f2 @91
            type: List<int>
        constructors
          @108
        accessors
          synthetic get f2 @-1
            returnType: List<int>
''');
  }

  test_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Future f() async {}
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    functions
      f @28 async
        returnType: Future<dynamic>
''');
  }

  test_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Stream f() async* {}
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    functions
      f @28 async*
        returnType: Stream<dynamic>
''');
  }

  test_function_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @60
        documentationComment: /**\n * Docs\n */
        returnType: dynamic
''');
  }

  test_function_entry_point() async {
    var library = await checkLibrary('main() {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      main @0
        returnType: dynamic
''');
  }

  test_function_entry_point_in_export() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_function_entry_point_in_export_hidden() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart" hide main;');
    checkElementText(library, r'''
library
  exports
    a.dart
      combinators
        hide: main
  definingUnit
''');
  }

  test_function_entry_point_in_part() async {
    addSource('/a.dart', 'part of my.lib; main() {}');
    var library = await checkLibrary('library my.lib; part "a.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
  parts
    a.dart
      functions
        main @16
          returnType: dynamic
''');
  }

  test_function_external() async {
    var library = await checkLibrary('external f();');
    checkElementText(library, r'''
library
  definingUnit
    functions
      external f @9
        returnType: dynamic
''');
  }

  test_function_hasImplicitReturnType_false() async {
    var library = await checkLibrary('''
int f() => 0;
''');
    var f = library.definingCompilationUnit.functions.single;
    expect(f.hasImplicitReturnType, isFalse);
  }

  test_function_hasImplicitReturnType_true() async {
    var library = await checkLibrary('''
f() => 0;
''');
    var f = library.definingCompilationUnit.functions.single;
    expect(f.hasImplicitReturnType, isTrue);
  }

  test_function_parameter_const() async {
    var library = await checkLibrary('''
void f(const x) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional x @13
            type: dynamic
        returnType: void
''');
  }

  test_function_parameter_fieldFormal() async {
    var library = await checkLibrary('''
void f(int this.a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional final this.a @16
            type: int
        returnType: void
''');
  }

  test_function_parameter_fieldFormal_default() async {
    var library = await checkLibrary('''
void f({int this.a: 42}) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          optionalNamed final this.a @17
            type: int
            constantInitializer
              IntegerLiteral
                literal: 42 @20
                staticType: int
        returnType: void
''');
  }

  test_function_parameter_fieldFormal_functionTyped() async {
    var library = await checkLibrary('''
void f(int this.a(int b)) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional final this.a @16
            type: int Function(int)
            parameters
              requiredPositional b @22
                type: int
        returnType: void
''');
  }

  test_function_parameter_final() async {
    var library = await checkLibrary('f(final x) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional final x @8
            type: dynamic
        returnType: dynamic
''');
  }

  test_function_parameter_kind_named() async {
    var library = await checkLibrary('f({x}) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          optionalNamed x @3
            type: dynamic
        returnType: dynamic
''');
  }

  test_function_parameter_kind_positional() async {
    var library = await checkLibrary('f([x]) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          optionalPositional x @3
            type: dynamic
        returnType: dynamic
''');
  }

  test_function_parameter_kind_required() async {
    var library = await checkLibrary('f(x) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional x @2
            type: dynamic
        returnType: dynamic
''');
  }

  test_function_parameter_parameters() async {
    var library = await checkLibrary('f(g(x, y)) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional g @2
            type: dynamic Function(dynamic, dynamic)
            parameters
              requiredPositional x @4
                type: dynamic
              requiredPositional y @7
                type: dynamic
        returnType: dynamic
''');
  }

  test_function_parameter_return_type() async {
    var library = await checkLibrary('f(int g()) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional g @6
            type: int Function()
        returnType: dynamic
''');
  }

  test_function_parameter_return_type_void() async {
    var library = await checkLibrary('f(void g()) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional g @7
            type: void Function()
        returnType: dynamic
''');
  }

  test_function_parameter_type() async {
    var library = await checkLibrary('f(int i) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional i @6
            type: int
        returnType: dynamic
''');
  }

  test_function_parameters() async {
    var library = await checkLibrary('f(x, y) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        parameters
          requiredPositional x @2
            type: dynamic
          requiredPositional y @5
            type: dynamic
        returnType: dynamic
''');
  }

  test_function_return_type() async {
    var library = await checkLibrary('int f() => null;');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @4
        returnType: int
''');
  }

  test_function_return_type_implicit() async {
    var library = await checkLibrary('f() => null;');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        returnType: dynamic
''');
  }

  test_function_return_type_void() async {
    var library = await checkLibrary('void f() {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        returnType: void
''');
  }

  test_function_type_parameter() async {
    var library = await checkLibrary('T f<T, U>(U u) => null;');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @2
        typeParameters
          covariant T @4
          covariant U @7
        parameters
          requiredPositional u @12
            type: U
        returnType: T
''');
  }

  test_function_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('void f<T, U>(T x(U u)) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
          covariant U @10
        parameters
          requiredPositional x @15
            type: T Function(U)
            parameters
              requiredPositional u @19
                type: U
        returnType: void
''');
  }

  test_function_typed_parameter_implicit() async {
    var library = await checkLibrary('f(g()) => null;');
    expect(
        library
            .definingCompilationUnit.functions[0].parameters[0].hasImplicitType,
        isFalse);
  }

  test_functions() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        returnType: dynamic
      g @7
        returnType: dynamic
''');
  }

  test_functionTypeAlias_enclosingElements() async {
    var library = await checkLibrary(r'''
typedef void F<T>(int a);
''');
    var unit = library.definingCompilationUnit;

    var F = unit.typeAliases[0];
    expect(F.name, 'F');

    var T = F.typeParameters[0];
    expect(T.name, 'T');
    expect(T.enclosingElement, same(F));

    var function = F.aliasedElement as GenericFunctionTypeElement;
    expect(function.enclosingElement, same(F));

    var a = function.parameters[0];
    expect(a.name, 'a');
    expect(a.enclosingElement, same(function));
  }

  test_functionTypeAlias_type_element() async {
    var library = await checkLibrary(r'''
typedef T F<T>();
F<int> a;
''');
    var unit = library.definingCompilationUnit;
    var type = unit.topLevelVariables[0].type as FunctionType;

    expect(type.alias!.element, same(unit.typeAliases[0]));
    _assertTypeStrings(type.alias!.typeArguments, ['int']);
  }

  test_functionTypeAlias_typeParameters_variance_contravariant() async {
    var library = await checkLibrary(r'''
typedef void F<T>(T a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        typeParameters
          contravariant T @15
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @20
              type: T
          returnType: void
''');
  }

  test_functionTypeAlias_typeParameters_variance_contravariant2() async {
    var library = await checkLibrary(r'''
typedef void F1<T>(T a);
typedef F1<T> F2<T>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F1 @13
        typeParameters
          contravariant T @16
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @21
              type: T
          returnType: void
      functionTypeAliasBased F2 @39
        typeParameters
          contravariant T @42
            defaultType: dynamic
        aliasedType: void Function(T) Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void Function(T)
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_functionTypeAlias_typeParameters_variance_contravariant3() async {
    var library = await checkLibrary(r'''
typedef F1<T> F2<T>();
typedef void F1<T>(T a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F2 @14
        typeParameters
          contravariant T @17
            defaultType: dynamic
        aliasedType: void Function(T) Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void Function(T)
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
      functionTypeAliasBased F1 @36
        typeParameters
          contravariant T @39
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @44
              type: T
          returnType: void
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant() async {
    var library = await checkLibrary(r'''
typedef T F<T>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          covariant T @12
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant2() async {
    var library = await checkLibrary(r'''
typedef List<T> F<T>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @16
        typeParameters
          covariant T @18
            defaultType: dynamic
        aliasedType: List<T> Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: List<T>
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant3() async {
    var library = await checkLibrary(r'''
typedef T F1<T>();
typedef F1<T> F2<T>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F1 @10
        typeParameters
          covariant T @13
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
      functionTypeAliasBased F2 @33
        typeParameters
          covariant T @36
            defaultType: dynamic
        aliasedType: T Function() Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T Function()
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant4() async {
    var library = await checkLibrary(r'''
typedef void F1<T>(T a);
typedef void F2<T>(F1<T> a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F1 @13
        typeParameters
          contravariant T @16
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @21
              type: T
          returnType: void
      functionTypeAliasBased F2 @38
        typeParameters
          covariant T @41
            defaultType: dynamic
        aliasedType: void Function(void Function(T))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @50
              type: void Function(T)
                aliasElement: self::@typeAlias::F1
                aliasArguments
                  T
          returnType: void
''');
  }

  test_functionTypeAlias_typeParameters_variance_invariant() async {
    var library = await checkLibrary(r'''
typedef T F<T>(T a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          invariant T @12
            defaultType: dynamic
        aliasedType: T Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @17
              type: T
          returnType: T
''');
  }

  test_functionTypeAlias_typeParameters_variance_invariant2() async {
    var library = await checkLibrary(r'''
typedef T F1<T>();
typedef F1<T> F2<T>(T a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F1 @10
        typeParameters
          covariant T @13
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
      functionTypeAliasBased F2 @33
        typeParameters
          invariant T @36
            defaultType: dynamic
        aliasedType: T Function() Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @41
              type: T
          returnType: T Function()
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_functionTypeAlias_typeParameters_variance_unrelated() async {
    var library = await checkLibrary(r'''
typedef void F<T>(int a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        typeParameters
          unrelated T @15
            defaultType: dynamic
        aliasedType: void Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @22
              type: int
          returnType: void
''');
  }

  test_futureOr() async {
    var library = await checkLibrary('import "dart:async"; FutureOr<int> x;');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static x @35
        type: FutureOr<int>
    accessors
      synthetic static get x @-1
        returnType: FutureOr<int>
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: FutureOr<int>
        returnType: void
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    _assertTypeStr(variables[0].type, 'FutureOr<int>');
  }

  test_futureOr_const() async {
    var library =
        await checkLibrary('import "dart:async"; const x = FutureOr;');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static const x @27
        type: Type
        constantInitializer
          SimpleIdentifier
            staticElement: dart:async::@class::FutureOr
            staticType: Type
            token: FutureOr @31
    accessors
      synthetic static get x @-1
        returnType: Type
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    var x = variables[0] as ConstTopLevelVariableElementImpl;
    _assertTypeStr(x.type, 'Type');
    expect(x.constantInitializer.toString(), 'FutureOr');
  }

  test_futureOr_inferred() async {
    var library = await checkLibrary('''
import "dart:async";
FutureOr<int> f() => null;
var x = f();
var y = x.then((z) => z.asDouble());
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static x @52
        type: FutureOr<int>
      static y @65
        type: dynamic
    accessors
      synthetic static get x @-1
        returnType: FutureOr<int>
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: FutureOr<int>
        returnType: void
      synthetic static get y @-1
        returnType: dynamic
      synthetic static set y @-1
        parameters
          requiredPositional _y @-1
            type: dynamic
        returnType: void
    functions
      f @35
        returnType: FutureOr<int>
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(2));
    var x = variables[0];
    expect(x.name, 'x');
    var y = variables[1];
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'FutureOr<int>');
    _assertTypeStr(y.type, 'dynamic');
  }

  test_generic_function_type_nullability_none() async {
    var library = await checkLibrary('''
void Function() f;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static f @16
        type: void Function()
    accessors
      synthetic static get f @-1
        returnType: void Function()
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: void Function()
        returnType: void
''');
  }

  test_generic_function_type_nullability_question() async {
    var library = await checkLibrary('''
void Function()? f;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static f @17
        type: void Function()?
    accessors
      synthetic static get f @-1
        returnType: void Function()?
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: void Function()?
        returnType: void
''');
  }

  test_generic_function_type_nullability_star() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
void Function() f;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static f @16
        type: void Function()*
    accessors
      synthetic static get f @-1
        returnType: void Function()*
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: void Function()*
        returnType: void
''');
  }

  test_generic_gClass_gMethodStatic() async {
    var library = await checkLibrary('''
class C<T, U> {
  static void m<V, W>(V v, W w) {
    void f<X, Y>(V v, W w, X x, Y y) {
    }
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          static m @30
            typeParameters
              covariant V @32
              covariant W @35
            parameters
              requiredPositional v @40
                type: V
              requiredPositional w @45
                type: W
            returnType: void
''');
  }

  test_genericFunction_asFunctionReturnType() async {
    var library = await checkLibrary(r'''
int Function(int a, String b) f() => null;
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @30
        returnType: int Function(int, String)
''');
  }

  test_genericFunction_asFunctionTypedParameterReturnType() async {
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p(num c)) => null;
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional p @37
            type: int Function(int, String) Function(num)
            parameters
              requiredPositional c @43
                type: num
        returnType: void
''');
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    var library = await checkLibrary(r'''
typedef F = void Function(String a) Function(int b);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        aliasedType: void Function(String) Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional b @49
              type: int
          returnType: void Function(String)
''');
  }

  test_genericFunction_asMethodReturnType() async {
    var library = await checkLibrary(r'''
class C {
  int Function(int a, String b) m() => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          m @42
            returnType: int Function(int, String)
''');
  }

  test_genericFunction_asParameterType() async {
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p) => null;
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional p @37
            type: int Function(int, String)
        returnType: void
''');
  }

  test_genericFunction_asTopLevelVariableType() async {
    var library = await checkLibrary(r'''
int Function(int a, String b) v;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @30
        type: int Function(int, String)
    accessors
      synthetic static get v @-1
        returnType: int Function(int, String)
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int Function(int, String)
        returnType: void
''');
  }

  test_genericFunction_asTypeArgument_ofAnnotation_class() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

@A<int Function(String a)>()
class B {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class B @64
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @55
              rightParenthesis: ) @56
            atSign: @ @29
            element: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int Function(String)}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @30
            typeArguments: TypeArgumentList
              arguments
                GenericFunctionType
                  declaredElement: GenericFunctionTypeElement
                    parameters
                      a
                        kind: required positional
                        type: String
                    returnType: int
                    type: int Function(String)
                  functionKeyword: Function @36
                  parameters: FormalParameterList
                    leftParenthesis: ( @44
                    parameters
                      SimpleFormalParameter
                        declaredElement: a@52
                        declaredElementType: String
                        identifier: SimpleIdentifier
                          staticElement: a@52
                          staticType: null
                          token: a @52
                        type: NamedType
                          name: SimpleIdentifier
                            staticElement: dart:core::@class::String
                            staticType: null
                            token: String @45
                          type: String
                    rightParenthesis: ) @53
                  returnType: NamedType
                    name: SimpleIdentifier
                      staticElement: dart:core::@class::int
                      staticType: null
                      token: int @32
                    type: int
                  type: int Function(String)
              leftBracket: < @31
              rightBracket: > @54
        constructors
          synthetic @-1
''');
  }

  test_genericFunction_asTypeArgument_ofAnnotation_topLevelVariable() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

@A<int Function(String a)>()
var v = 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static v @62
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @55
              rightParenthesis: ) @56
            atSign: @ @29
            element: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int Function(String)}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @30
            typeArguments: TypeArgumentList
              arguments
                GenericFunctionType
                  declaredElement: GenericFunctionTypeElement
                    parameters
                      a
                        kind: required positional
                        type: String
                    returnType: int
                    type: int Function(String)
                  functionKeyword: Function @36
                  parameters: FormalParameterList
                    leftParenthesis: ( @44
                    parameters
                      SimpleFormalParameter
                        declaredElement: a@52
                        declaredElementType: String
                        identifier: SimpleIdentifier
                          staticElement: a@52
                          staticType: null
                          token: a @52
                        type: NamedType
                          name: SimpleIdentifier
                            staticElement: dart:core::@class::String
                            staticType: null
                            token: String @45
                          type: String
                    rightParenthesis: ) @53
                  returnType: NamedType
                    name: SimpleIdentifier
                      staticElement: dart:core::@class::int
                      staticType: null
                      token: int @32
                    type: int
                  type: int Function(String)
              leftBracket: < @31
              rightBracket: > @54
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_genericFunction_asTypeArgument_parameters_optionalNamed() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function({int? a})>();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static const v @35
        type: A<String Function({int? a})>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @67
              rightParenthesis: ) @68
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::•
                substitution: {T: String Function({int? a})}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @39
                type: A<String Function({int? a})>
                typeArguments: TypeArgumentList
                  arguments
                    GenericFunctionType
                      declaredElement: GenericFunctionTypeElement
                        parameters
                          a
                            kind: optional named
                            type: int?
                        returnType: String
                        type: String Function({int? a})
                      functionKeyword: Function @48
                      parameters: FormalParameterList
                        leftParenthesis: ( @56
                        parameters
                          DefaultFormalParameter
                            declaredElement: a@63
                            declaredElementType: int?
                            identifier: SimpleIdentifier
                              staticElement: a@63
                              staticType: null
                              token: a @63
                            parameter: SimpleFormalParameter
                              declaredElement: a@63
                              declaredElementType: int?
                              identifier: SimpleIdentifier
                                staticElement: a@63
                                staticType: null
                                token: a @63
                              type: NamedType
                                name: SimpleIdentifier
                                  staticElement: dart:core::@class::int
                                  staticType: null
                                  token: int @58
                                type: int?
                        rightParenthesis: ) @65
                      returnType: NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @41
                        type: String
                      type: String Function({int? a})
                  leftBracket: < @40
                  rightBracket: > @66
            staticType: A<String Function({int? a})>
    accessors
      synthetic static get v @-1
        returnType: A<String Function({int? a})>
''');
  }

  test_genericFunction_asTypeArgument_parameters_optionalPositional() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function([int? a])>();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static const v @35
        type: A<String Function([int?])>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @67
              rightParenthesis: ) @68
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::•
                substitution: {T: String Function([int?])}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @39
                type: A<String Function([int?])>
                typeArguments: TypeArgumentList
                  arguments
                    GenericFunctionType
                      declaredElement: GenericFunctionTypeElement
                        parameters
                          a
                            kind: optional positional
                            type: int?
                        returnType: String
                        type: String Function([int?])
                      functionKeyword: Function @48
                      parameters: FormalParameterList
                        leftParenthesis: ( @56
                        parameters
                          DefaultFormalParameter
                            declaredElement: a@63
                            declaredElementType: int?
                            identifier: SimpleIdentifier
                              staticElement: a@63
                              staticType: null
                              token: a @63
                            parameter: SimpleFormalParameter
                              declaredElement: a@63
                              declaredElementType: int?
                              identifier: SimpleIdentifier
                                staticElement: a@63
                                staticType: null
                                token: a @63
                              type: NamedType
                                name: SimpleIdentifier
                                  staticElement: dart:core::@class::int
                                  staticType: null
                                  token: int @58
                                type: int?
                        rightParenthesis: ) @65
                      returnType: NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @41
                        type: String
                      type: String Function([int?])
                  leftBracket: < @40
                  rightBracket: > @66
            staticType: A<String Function([int?])>
    accessors
      synthetic static get v @-1
        returnType: A<String Function([int?])>
''');
  }

  test_genericFunction_asTypeArgument_parameters_requiredNamed() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function({required int a})>();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static const v @35
        type: A<String Function({required int a})>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @75
              rightParenthesis: ) @76
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::•
                substitution: {T: String Function({required int a})}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @39
                type: A<String Function({required int a})>
                typeArguments: TypeArgumentList
                  arguments
                    GenericFunctionType
                      declaredElement: GenericFunctionTypeElement
                        parameters
                          a
                            kind: required named
                            type: int
                        returnType: String
                        type: String Function({required int a})
                      functionKeyword: Function @48
                      parameters: FormalParameterList
                        leftParenthesis: ( @56
                        parameters
                          DefaultFormalParameter
                            declaredElement: a@71
                            declaredElementType: int
                            identifier: SimpleIdentifier
                              staticElement: a@71
                              staticType: null
                              token: a @71
                            parameter: SimpleFormalParameter
                              declaredElement: a@71
                              declaredElementType: int
                              identifier: SimpleIdentifier
                                staticElement: a@71
                                staticType: null
                                token: a @71
                              requiredKeyword: required @58
                              type: NamedType
                                name: SimpleIdentifier
                                  staticElement: dart:core::@class::int
                                  staticType: null
                                  token: int @67
                                type: int
                        rightParenthesis: ) @73
                      returnType: NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @41
                        type: String
                      type: String Function({required int a})
                  leftBracket: < @40
                  rightBracket: > @74
            staticType: A<String Function({required int a})>
    accessors
      synthetic static get v @-1
        returnType: A<String Function({required int a})>
''');
  }

  test_genericFunction_asTypeArgument_parameters_requiredPositional() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function(int a)>();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static const v @35
        type: A<String Function(int)>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @64
              rightParenthesis: ) @65
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::•
                substitution: {T: String Function(int)}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @39
                type: A<String Function(int)>
                typeArguments: TypeArgumentList
                  arguments
                    GenericFunctionType
                      declaredElement: GenericFunctionTypeElement
                        parameters
                          a
                            kind: required positional
                            type: int
                        returnType: String
                        type: String Function(int)
                      functionKeyword: Function @48
                      parameters: FormalParameterList
                        leftParenthesis: ( @56
                        parameters
                          SimpleFormalParameter
                            declaredElement: a@61
                            declaredElementType: int
                            identifier: SimpleIdentifier
                              staticElement: a@61
                              staticType: null
                              token: a @61
                            type: NamedType
                              name: SimpleIdentifier
                                staticElement: dart:core::@class::int
                                staticType: null
                                token: int @57
                              type: int
                        rightParenthesis: ) @62
                      returnType: NamedType
                        name: SimpleIdentifier
                          staticElement: dart:core::@class::String
                          staticType: null
                          token: String @41
                        type: String
                      type: String Function(int)
                  leftBracket: < @40
                  rightBracket: > @63
            staticType: A<String Function(int)>
    accessors
      synthetic static get v @-1
        returnType: A<String Function(int)>
''');
  }

  test_genericFunction_boundOf_typeParameter_ofMixin() async {
    var library = await checkLibrary(r'''
mixin B<X extends void Function()> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin B @6
        typeParameters
          covariant X @8
            bound: void Function()
            defaultType: void Function()
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_genericFunction_typeArgument_ofSuperclass_ofClassAlias() async {
    var library = await checkLibrary(r'''
class A<T> {}
mixin M {}
class B = A<void Function()> with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
      class alias B @31
        supertype: A<void Function()>
        mixins
          M
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
    mixins
      mixin M @20
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_genericFunction_typeParameter_asTypedefArgument() async {
    var library = await checkLibrary(r'''
typedef F1 = Function<V1>(F2<V1>);
typedef F2<V2> = V2 Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F1 @8
        aliasedType: dynamic Function<V1>(V1 Function())
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant V1 @22
          parameters
            requiredPositional @-1
              type: V1 Function()
                aliasElement: self::@typeAlias::F2
                aliasArguments
                  V1
          returnType: dynamic
      F2 @43
        typeParameters
          covariant V2 @46
            defaultType: dynamic
        aliasedType: V2 Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: V2
''');
  }

  test_genericTypeAlias_enclosingElements() async {
    var library = await checkLibrary(r'''
typedef F<T> = void Function<U>(int a);
''');
    var unit = library.definingCompilationUnit;

    var F = unit.typeAliases[0];
    expect(F.name, 'F');

    var T = F.typeParameters[0];
    expect(T.name, 'T');
    expect(T.enclosingElement, same(F));

    var function = F.aliasedElement as GenericFunctionTypeElement;
    expect(function.enclosingElement, same(F));

    var U = function.typeParameters[0];
    expect(U.name, 'U');
    expect(U.enclosingElement, same(function));

    var a = function.parameters[0];
    expect(a.name, 'a');
    expect(a.enclosingElement, same(function));
  }

  test_genericTypeAlias_recursive() async {
    var library = await checkLibrary('''
typedef F<X extends F> = Function(F);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        typeParameters
          unrelated X @10
            bound: dynamic
            defaultType: dynamic
        aliasedType: dynamic Function(dynamic)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: dynamic
          returnType: dynamic
''');
  }

  test_getter_async() async {
    var library = await checkLibrary(r'''
Future<int> get foo async => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: Future<int>
    accessors
      get foo @16 async
        returnType: Future<int>
''');
  }

  test_getter_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Stream<int> get foo async* {}
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: Stream<int>
    accessors
      get foo @37 async*
        returnType: Stream<int>
''');
  }

  test_getter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: dynamic
    accessors
      get x @64
        documentationComment: /**\n * Docs\n */
        returnType: dynamic
''');
  }

  test_getter_external() async {
    var library = await checkLibrary('external int get x;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      external get x @17
        returnType: int
''');
  }

  test_getter_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        fields
          synthetic f @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get f @24
            returnType: int
      abstract class D @52
        fields
          synthetic f @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get f @64
            returnType: int
''');
  }

  test_getter_syncStar() async {
    var library = await checkLibrary(r'''
Iterator<int> get foo sync* {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: Iterator<int>
    accessors
      get foo @18 sync*
        returnType: Iterator<int>
''');
  }

  test_getters() async {
    var library = await checkLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
      synthetic static y @-1
        type: dynamic
    accessors
      get x @8
        returnType: int
      get y @23
        returnType: dynamic
''');
  }

  test_implicitConstructor_named_const() async {
    var library = await checkLibrary('''
class C {
  final Object x;
  const C.named(this.x);
}
const x = C.named(42);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          final x @25
            type: Object
        constructors
          const named @38
            periodOffset: 37
            nameEnd: 43
            parameters
              requiredPositional final this.x @49
                type: Object
        accessors
          synthetic get x @-1
            returnType: Object
    topLevelVariables
      static const x @61
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                IntegerLiteral
                  literal: 42 @73
                  staticType: int
              leftParenthesis: ( @72
              rightParenthesis: ) @75
            constructorName: ConstructorName
              name: SimpleIdentifier
                staticElement: self::@class::C::@constructor::named
                staticType: null
                token: named @67
              period: . @66
              staticElement: self::@class::C::@constructor::named
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @65
                type: C
            staticType: C
    accessors
      synthetic static get x @-1
        returnType: C
''');
  }

  test_implicitTopLevelVariable_getterFirst() async {
    var library =
        await checkLibrary('int get x => 0; void set x(int value) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      get x @8
        returnType: int
      set x @25
        parameters
          requiredPositional value @31
            type: int
        returnType: void
''');
  }

  test_implicitTopLevelVariable_setterFirst() async {
    var library =
        await checkLibrary('void set x(int value) {} int get x => 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      set x @9
        parameters
          requiredPositional value @15
            type: int
        returnType: void
      get x @33
        returnType: int
''');
  }

  test_import_configurations_useDefault() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
    classes
      class B @104
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    foo_io.dart
  definingUnit
    classes
      class B @104
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_configurations_useFirst_eqTrue() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    foo_io.dart
  definingUnit
    classes
      class B @124
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_configurations_useSecond() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    foo_html.dart
  definingUnit
    classes
      class B @104
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_import_configurations_useSecond_eqTrue() async {
    declaredVariables = DeclaredVariables.fromMap({
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  imports
    foo_html.dart
  definingUnit
    classes
      class B @124
        supertype: A
        constructors
          synthetic @-1
''');
    var typeA = library.definingCompilationUnit.getType('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_import_dartCore_explicit() async {
    var library = await checkLibrary('''
import 'dart:core';
import 'dart:math';
''');
    checkElementText(library, r'''
library
  imports
    dart:core
    dart:math
  definingUnit
''');
  }

  test_import_dartCore_implicit() async {
    var library = await checkLibrary('''
import 'dart:math';
''');
    checkElementText(library, r'''
library
  imports
    dart:math
  definingUnit
''');
  }

  test_import_deferred() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', 'f() {}');
    var library = await checkLibrary('''
import 'a.dart' deferred as p;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart deferred as p @28
  definingUnit
''');
  }

  test_import_export() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import 'dart:async' as i1;
export 'dart:math';
import 'dart:async' as i2;
export 'dart:math';
import 'dart:async' as i3;
export 'dart:math';
''');
    checkElementText(library, r'''
library
  imports
    dart:async as i1 @23
    dart:async as i2 @70
    dart:async as i3 @117
  exports
    dart:math
    dart:math
    dart:math
  definingUnit
''');
  }

  test_import_hide() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
      combinators
        hide: Stream, Completer
  definingUnit
    topLevelVariables
      static f @51
        type: Future<dynamic>
    accessors
      synthetic static get f @-1
        returnType: Future<dynamic>
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: Future<dynamic>
        returnType: void
''');
  }

  test_import_invalidUri_metadata() async {
    var library = await checkLibrary('''
@foo
import 'ht:';
''');
    checkElementText(library, r'''
library
  metadata
    Annotation
      atSign: @ @0
      element: <null>
      name: SimpleIdentifier
        staticElement: <null>
        staticType: null
        token: foo @1
  imports
    <unresolved>
      metadata
        Annotation
          atSign: @ @0
          element: <null>
          name: SimpleIdentifier
            staticElement: <null>
            staticType: null
            token: foo @1
  definingUnit
''');
  }

  test_import_multiple_combinators() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" hide Stream show Future;
Future f;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
      combinators
        hide: Stream
        show: Future
  definingUnit
    topLevelVariables
      static f @52
        type: Future<dynamic>
    accessors
      synthetic static get f @-1
        returnType: Future<dynamic>
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: Future<dynamic>
        returnType: void
''');
  }

  test_import_prefixed() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    var library = await checkLibrary('import "a.dart" as a; a.C c;');

    expect(library.imports[0].prefix!.nameOffset, 19);
    expect(library.imports[0].prefix!.nameLength, 1);

    checkElementText(library, r'''
library
  imports
    a.dart as a @19
  definingUnit
    topLevelVariables
      static c @26
        type: C
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
''');
  }

  test_import_self() async {
    var library = await checkLibrary('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    expect(library.imports, hasLength(2));
    expect(library.imports[0].importedLibrary!.location, library.location);
    expect(library.imports[1].importedLibrary!.isDartCore, true);
    checkElementText(library, r'''
library
  imports
    test.dart as p @22
  definingUnit
    classes
      class C @31
        constructors
          synthetic @-1
      class D @42
        supertype: C
        constructors
          synthetic @-1
''');
  }

  test_import_short_absolute() async {
    testFile = '/my/project/bin/test.dart';
    // Note: "/a.dart" resolves differently on Windows vs. Posix.
    var destinationPath = convertPath('/a.dart');
    addLibrarySource(destinationPath, 'class C {}');
    var library = await checkLibrary('import "/a.dart"; C c;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @20
        type: C
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
''');
  }

  test_import_show() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" show Future, Stream;
Future f;
Stream s;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
      combinators
        show: Future, Stream
  definingUnit
    topLevelVariables
      static f @48
        type: Future<dynamic>
      static s @58
        type: Stream<dynamic>
    accessors
      synthetic static get f @-1
        returnType: Future<dynamic>
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: Future<dynamic>
        returnType: void
      synthetic static get s @-1
        returnType: Stream<dynamic>
      synthetic static set s @-1
        parameters
          requiredPositional _s @-1
            type: Stream<dynamic>
        returnType: void
''');
  }

  test_import_show_offsetEnd() async {
    var library = await checkLibrary('''
import "dart:math" show e, pi;
''');
    var import = library.imports[0];
    var combinator = import.combinators[0] as ShowElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_uri() async {
    var library = await checkLibrary('''
import 'foo.dart';
''');
    expect(library.imports[0].uri, 'foo.dart');
  }

  test_imports() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    addLibrarySource('/b.dart', 'library b; class D {}');
    var library =
        await checkLibrary('import "a.dart"; import "b.dart"; C c; D d;');
    checkElementText(library, r'''
library
  imports
    a.dart
    b.dart
  definingUnit
    topLevelVariables
      static c @36
        type: C
      static d @41
        type: D
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get d @-1
        returnType: D
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: D
        returnType: void
''');
  }

  test_infer_generic_typedef_complex() async {
    var library = await checkLibrary('''
typedef F<T> = D<T,U> Function<U>();
class C<V> {
  const C(F<V> f);
}
class D<T,U> {}
D<int,U> f<U>() => null;
const x = const C(f);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @43
        typeParameters
          covariant V @45
            defaultType: dynamic
        constructors
          const @58
            parameters
              requiredPositional f @65
                type: D<V, U> Function<U>()
                  aliasElement: self::@typeAlias::F
                  aliasArguments
                    V
      class D @77
        typeParameters
          covariant T @79
            defaultType: dynamic
          covariant U @81
            defaultType: dynamic
        constructors
          synthetic @-1
    typeAliases
      F @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: D<T, U> Function<U>()
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant U @31
          returnType: D<T, U>
    topLevelVariables
      static const x @118
        type: C<int>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                SimpleIdentifier
                  staticElement: self::@function::f
                  staticType: D<int, U> Function<U>()
                  token: f @130
              leftParenthesis: ( @129
              rightParenthesis: ) @131
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::•
                substitution: {V: int}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @128
                type: C<int>
            keyword: const @122
            staticType: C<int>
    accessors
      synthetic static get x @-1
        returnType: C<int>
    functions
      f @96
        typeParameters
          covariant U @98
        returnType: D<int, U>
''');
  }

  test_infer_generic_typedef_simple() async {
    var library = await checkLibrary('''
typedef F = D<T> Function<T>();
class C {
  const C(F f);
}
class D<T> {}
D<T> f<T>() => null;
const x = const C(f);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @38
        constructors
          const @50
            parameters
              requiredPositional f @54
                type: D<T> Function<T>()
                  aliasElement: self::@typeAlias::F
      class D @66
        typeParameters
          covariant T @68
            defaultType: dynamic
        constructors
          synthetic @-1
    typeAliases
      F @8
        aliasedType: D<T> Function<T>()
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant T @26
          returnType: D<T>
    topLevelVariables
      static const x @101
        type: C
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              arguments
                SimpleIdentifier
                  staticElement: self::@function::f
                  staticType: D<T> Function<T>()
                  token: f @113
              leftParenthesis: ( @112
              rightParenthesis: ) @114
            constructorName: ConstructorName
              staticElement: self::@class::C::@constructor::•
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::C
                  staticType: null
                  token: C @111
                type: C
            keyword: const @105
            staticType: C
    accessors
      synthetic static get x @-1
        returnType: C
    functions
      f @79
        typeParameters
          covariant T @81
        returnType: D<T>
''');
  }

  test_infer_instanceCreation_fromArguments() async {
    var library = await checkLibrary('''
class A {}

class B extends A {}

class S<T extends A> {
  S(T _);
}

var s = new S(new B());
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @18
        supertype: A
        constructors
          synthetic @-1
      class S @40
        typeParameters
          covariant T @42
            bound: A
            defaultType: A
        constructors
          @59
            parameters
              requiredPositional _ @63
                type: T
    topLevelVariables
      static s @74
        type: S<B>
    accessors
      synthetic static get s @-1
        returnType: S<B>
      synthetic static set s @-1
        parameters
          requiredPositional _s @-1
            type: S<B>
        returnType: void
''');
  }

  test_infer_property_set() async {
    var library = await checkLibrary('''
class A {
  B b;
}
class B {
  C get c => null;
  void set c(C value) {}
}
class C {}
class D extends C {}
var a = new A();
var x = a.b.c ??= new D();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          b @14
            type: B
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: B
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: B
            returnType: void
      class B @25
        fields
          synthetic c @-1
            type: C
        constructors
          synthetic @-1
        accessors
          get c @37
            returnType: C
          set c @59
            parameters
              requiredPositional value @63
                type: C
            returnType: void
      class C @81
        constructors
          synthetic @-1
      class D @92
        supertype: C
        constructors
          synthetic @-1
    topLevelVariables
      static a @111
        type: A
      static x @128
        type: C
    accessors
      synthetic static get a @-1
        returnType: A
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: A
        returnType: void
      synthetic static get x @-1
        returnType: C
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: C
        returnType: void
''');
  }

  test_inference_issue_32394() async {
    // Test the type inference involved in dartbug.com/32394
    var library = await checkLibrary('''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: Iterable<String>
      static y @40
        type: List<int>
      static z @53
        type: List<String>
    accessors
      synthetic static get x @-1
        returnType: Iterable<String>
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: Iterable<String>
        returnType: void
      synthetic static get y @-1
        returnType: List<int>
      synthetic static set y @-1
        parameters
          requiredPositional _y @-1
            type: List<int>
        returnType: void
      synthetic static get z @-1
        returnType: List<String>
      synthetic static set z @-1
        parameters
          requiredPositional _z @-1
            type: List<String>
        returnType: void
''');
  }

  test_inference_map() async {
    var library = await checkLibrary('''
class C {
  int p;
}
var x = <C>[];
var y = x.map((c) => c.p);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          p @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get p @-1
            returnType: int
          synthetic set p @-1
            parameters
              requiredPositional _p @-1
                type: int
            returnType: void
    topLevelVariables
      static x @25
        type: List<C>
      static y @40
        type: Iterable<int>
    accessors
      synthetic static get x @-1
        returnType: List<C>
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: List<C>
        returnType: void
      synthetic static get y @-1
        returnType: Iterable<int>
      synthetic static set y @-1
        parameters
          requiredPositional _y @-1
            type: Iterable<int>
        returnType: void
''');
  }

  test_inferred_function_type_for_variable_in_generic_function() async {
    // In the code below, `x` has an inferred type of `() => int`, with 2
    // (unused) type parameters from the enclosing top level function.
    var library = await checkLibrary('''
f<U, V>() {
  var x = () => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        typeParameters
          covariant U @2
          covariant V @5
        returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_constructor() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  final x;
  C() : x = (() => () => 0);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant U @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        fields
          final x @24
            type: dynamic
        constructors
          @29
        accessors
          synthetic get x @-1
            returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_getter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  get x => () => () => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant U @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @22
            returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_in_generic_method() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters from the enclosing class
    // and method.
    var library = await checkLibrary('''
class C<T> {
  f<U, V>() {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          f @15
            typeParameters
              covariant U @17
              covariant V @20
            returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_setter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  void set x(value) {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant U @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @27
            parameters
              requiredPositional value @29
                type: dynamic
            returnType: void
''');
  }

  test_inferred_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters.
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => () => 0);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        typeParameters
          covariant T @2
        returnType: dynamic
''');
  }

  test_inferred_generic_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => <W, X, Y, Z>() => 0` has an inferred
    // return type of `() => int`, with 7 (unused) type parameters.
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => /*<W, X, Y, Z>*/() => 0);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        typeParameters
          covariant T @2
        returnType: dynamic
''');
  }

  test_inferred_type_functionExpressionInvocation_oppositeOrder() async {
    var library = await checkLibrary('''
class A {
  static final foo = bar(1.2);
  static final bar = baz();

  static int Function(double) baz() => (throw 0);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          static final foo @25
            type: int
          static final bar @56
            type: int Function(double)
        constructors
          synthetic @-1
        accessors
          synthetic static get foo @-1
            returnType: int
          synthetic static get bar @-1
            returnType: int Function(double)
        methods
          static baz @100
            returnType: int Function(double)
''');
  }

  test_inferred_type_initializer_cycle() async {
    var library = await checkLibrary(r'''
var a = b + 1;
var b = c + 2;
var c = a + 3;
var d = 4;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        typeInferenceError: dependencyCycle
        type: dynamic
      static b @19
        typeInferenceError: dependencyCycle
        type: dynamic
      static c @34
        typeInferenceError: dependencyCycle
        type: dynamic
      static d @49
        type: int
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: dynamic
        returnType: void
      synthetic static get b @-1
        returnType: dynamic
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: dynamic
        returnType: void
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
      synthetic static get d @-1
        returnType: int
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: int
        returnType: void
''');
  }

  test_inferred_type_is_typedef() async {
    var library = await checkLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @31
        supertype: D
        fields
          v @49
            type: int Function(String)
              aliasElement: self::@typeAlias::F
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: int Function(String)
              aliasElement: self::@typeAlias::F
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int Function(String)
                  aliasElement: self::@typeAlias::F
            returnType: void
      abstract class D @69
        fields
          synthetic v @-1
            type: int Function(String)
              aliasElement: self::@typeAlias::F
        constructors
          synthetic @-1
        accessors
          abstract get v @79
            returnType: int Function(String)
              aliasElement: self::@typeAlias::F
    typeAliases
      functionTypeAliasBased F @12
        aliasedType: int Function(String)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional s @21
              type: String
          returnType: int
''');
  }

  test_inferred_type_nullability_class_ref_none() async {
    addSource('/a.dart', 'int f() => 0;');
    var library = await checkLibrary('''
import 'a.dart';
var x = f();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_inferred_type_nullability_class_ref_question() async {
    addSource('/a.dart', 'int? f() => 0;');
    var library = await checkLibrary('''
import 'a.dart';
var x = f();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int?
    accessors
      synthetic static get x @-1
        returnType: int?
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int?
        returnType: void
''');
  }

  test_inferred_type_nullability_function_type_none() async {
    addSource('/a.dart', 'void Function() f() => () {};');
    var library = await checkLibrary('''
import 'a.dart';
var x = f();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: void Function()
    accessors
      synthetic static get x @-1
        returnType: void Function()
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: void Function()
        returnType: void
''');
  }

  test_inferred_type_nullability_function_type_question() async {
    addSource('/a.dart', 'void Function()? f() => () {};');
    var library = await checkLibrary('''
import 'a.dart';
var x = f();
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: void Function()?
    accessors
      synthetic static get x @-1
        returnType: void Function()?
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: void Function()?
        returnType: void
''');
  }

  test_inferred_type_refers_to_bound_type_param() async {
    var library = await checkLibrary('''
class C<T> extends D<int, T> {
  var v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        supertype: D<int, T>
        fields
          v @37
            type: Map<T, int>
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: Map<T, int>
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: Map<T, int>
            returnType: void
      abstract class D @57
        typeParameters
          covariant U @59
            defaultType: dynamic
          covariant V @62
            defaultType: dynamic
        fields
          synthetic v @-1
            type: Map<V, U>
        constructors
          synthetic @-1
        accessors
          abstract get v @83
            returnType: Map<V, U>
''');
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    var library = await checkLibrary('''
typedef void F(int g(String s));
h(F f) => null;
var v = h((y) {});
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        aliasedType: void Function(int Function(String))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional g @19
              type: int Function(String)
              parameters
                requiredPositional s @28
                  type: String
          returnType: void
    topLevelVariables
      static v @53
        type: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: dynamic
        returnType: void
    functions
      h @33
        parameters
          requiredPositional f @37
            type: void Function(int Function(String))
              aliasElement: self::@typeAlias::F
        returnType: dynamic
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> extends D<U, int> {
  void f(int x, g) {}
}
abstract class D<V, W> {
  void f(int x, W g(V s));
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        supertype: D<U, int>
        constructors
          synthetic @-1
        methods
          f @41
            parameters
              requiredPositional x @47
                type: int
              requiredPositional g @50
                type: int Function(U)
            returnType: void
      abstract class D @73
        typeParameters
          covariant V @75
            defaultType: dynamic
          covariant W @78
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          abstract f @90
            parameters
              requiredPositional x @96
                type: int
              requiredPositional g @101
                type: W Function(V)
                parameters
                  requiredPositional s @105
                    type: V
            returnType: void
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    addLibrarySource('/a.dart', '''
import 'b.dart';
abstract class D extends E {}
''');
    addLibrarySource('/b.dart', '''
abstract class E {
  void f(int x, int g(String s));
}
''');
    var library = await checkLibrary('''
import 'a.dart';
class C extends D {
  void f(int x, g) {}
}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class C @23
        supertype: D
        constructors
          synthetic @-1
        methods
          f @44
            parameters
              requiredPositional x @50
                type: int
              requiredPositional g @53
                type: int Function(String)
            returnType: void
''');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        constructors
          synthetic @-1
        methods
          f @25
            parameters
              requiredPositional x @31
                type: int
              requiredPositional g @34
                type: int Function(String)
            returnType: void
      abstract class D @57
        constructors
          synthetic @-1
        methods
          abstract f @66
            parameters
              requiredPositional x @72
                type: int
              requiredPositional g @79
                type: int Function(String)
                parameters
                  requiredPositional s @88
                    type: String
            returnType: void
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param() async {
    var library = await checkLibrary('''
f(void g(int x, void h())) => null;
var v = f((x, y) {});
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @40
        type: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: dynamic
        returnType: void
    functions
      f @0
        parameters
          requiredPositional g @7
            type: void Function(int, void Function())
            parameters
              requiredPositional x @13
                type: int
              requiredPositional h @21
                type: void Function()
        returnType: dynamic
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    var library = await checkLibrary('''
f({void g(int x, void h())}) => null;
var v = f(g: (x, y) {});
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @42
        type: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: dynamic
        returnType: void
    functions
      f @0
        parameters
          optionalNamed g @8
            type: void Function(int, void Function())
            parameters
              requiredPositional x @14
                type: int
              requiredPositional h @22
                type: void Function()
        returnType: dynamic
''');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        fields
          synthetic f @-1
            type: int Function(String)
        constructors
          synthetic @-1
        accessors
          set f @29
            parameters
              requiredPositional g @31
                type: int Function(String)
            returnType: void
      abstract class D @54
        fields
          synthetic f @-1
            type: int Function(String)
        constructors
          synthetic @-1
        accessors
          abstract set f @67
            parameters
              requiredPositional g @73
                type: int Function(String)
                parameters
                  requiredPositional s @82
                    type: String
            returnType: void
''');
  }

  test_inferredType_definedInSdkLibraryPart() async {
    addSource('/a.dart', r'''
import 'dart:async';
class A {
  m(Stream p) {}
}
''');
    LibraryElement library = await checkLibrary(r'''
import 'a.dart';
class B extends A {
  m(p) {}
}
  ''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class B @23
        supertype: A
        constructors
          synthetic @-1
        methods
          m @39
            parameters
              requiredPositional p @41
                type: Stream<dynamic>
            returnType: dynamic
''');
    ClassElement b = library.definingCompilationUnit.classes[0];
    ParameterElement p = b.methods[0].parameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    Element streamElement = p.type.element!;
    if (streamElement is ClassElement) {
      expect(streamElement.source, isNot(streamElement.library.source));
    }
  }

  test_inferredType_implicitCreation() async {
    var library = await checkLibrary(r'''
class A {
  A();
  A.named();
}
var a1 = A();
var a2 = A.named();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          @12
          named @21
            periodOffset: 20
            nameEnd: 26
    topLevelVariables
      static a1 @36
        type: A
      static a2 @50
        type: A
    accessors
      synthetic static get a1 @-1
        returnType: A
      synthetic static set a1 @-1
        parameters
          requiredPositional _a1 @-1
            type: A
        returnType: void
      synthetic static get a2 @-1
        returnType: A
      synthetic static set a2 @-1
        parameters
          requiredPositional _a2 @-1
            type: A
        returnType: void
''');
  }

  test_inferredType_implicitCreation_prefixed() async {
    addLibrarySource('/foo.dart', '''
class A {
  A();
  A.named();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
var a1 = foo.A();
var a2 = foo.A.named();
''');
    checkElementText(library, r'''
library
  imports
    foo.dart as foo @21
  definingUnit
    topLevelVariables
      static a1 @30
        type: A
      static a2 @48
        type: A
    accessors
      synthetic static get a1 @-1
        returnType: A
      synthetic static set a1 @-1
        parameters
          requiredPositional _a1 @-1
            type: A
        returnType: void
      synthetic static get a2 @-1
        returnType: A
      synthetic static set a2 @-1
        parameters
          requiredPositional _a2 @-1
            type: A
        returnType: void
''');
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    // AnalysisContext does not set the enclosing element for the synthetic
    // FunctionElement created for the [f, g] type argument.
    var library = await checkLibrary('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = [f, g];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @71
        type: List<Object Function(int Function(String))>
    accessors
      synthetic static get v @-1
        returnType: List<Object Function(int Function(String))>
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: List<Object Function(int Function(String))>
        returnType: void
    functions
      f @4
        parameters
          requiredPositional x @10
            type: int Function(String)
            parameters
              requiredPositional y @19
                type: String
        returnType: int
      g @39
        parameters
          requiredPositional x @45
            type: int Function(String)
            parameters
              requiredPositional y @54
                type: String
        returnType: String
''');
  }

  test_inheritance_errors() async {
    var library = await checkLibrary('''
abstract class A {
  int m();
}

abstract class B {
  String m();
}

abstract class C implements A, B {}

abstract class D extends C {
  var f;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        constructors
          synthetic @-1
        methods
          abstract m @25
            returnType: int
      abstract class B @48
        constructors
          synthetic @-1
        methods
          abstract m @61
            returnType: String
      abstract class C @84
        interfaces
          A
          B
        constructors
          synthetic @-1
      abstract class D @121
        supertype: C
        fields
          f @141
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: dynamic
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: dynamic
            returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('var v = () => 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: int Function()
    accessors
      synthetic static get v @-1
        returnType: int Function()
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int Function()
        returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await checkLibrary('var v = (f) async => await f;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: Future<dynamic> Function(dynamic)
    accessors
      synthetic static get v @-1
        returnType: Future<dynamic> Function(dynamic)
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: Future<dynamic> Function(dynamic)
        returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<Future<Future<int>>> f) async => await f;
''');
    // The analyzer type system over-flattens - see dartbug.com/31887
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static v @25
        type: Future<int> Function(Future<Future<Future<int>>>)
    accessors
      synthetic static get v @-1
        returnType: Future<int> Function(Future<Future<Future<int>>>)
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: Future<int> Function(Future<Future<Future<int>>>)
        returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<int> f) async => await f;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static v @25
        type: Future<int> Function(Future<int>)
    accessors
      synthetic static get v @-1
        returnType: Future<int> Function(Future<int>)
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: Future<int> Function(Future<int>)
        returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future f) async => await f;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static v @25
        type: Future<dynamic> Function(Future<dynamic>)
    accessors
      synthetic static get v @-1
        returnType: Future<dynamic> Function(Future<dynamic>)
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: Future<dynamic> Function(Future<dynamic>)
        returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_field() async {
    var library = await checkLibrary('''
class C {
  var v = () => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          v @16
            type: int Function()
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: int Function()
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int Function()
            returnType: void
''');
  }

  test_initializer_executable_with_return_type_from_closure_local() async {
    var library = await checkLibrary('''
void f() {
  int u = 0;
  var v = () => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        returnType: void
''');
  }

  test_instanceInference_operator_equal_legacy_from_legacy() async {
    featureSet = FeatureSets.language_2_9;
    addLibrarySource('/legacy.dart', r'''
// @dart = 2.7
class LegacyDefault {
  bool operator==(other) => false;
}
class LegacyObject {
  bool operator==(Object other) => false;
}
class LegacyInt {
  bool operator==(int other) => false;
}
''');
    var library = await checkLibrary(r'''
import 'legacy.dart';
class X1 extends LegacyDefault  {
  bool operator==(other) => false;
}
class X2 extends LegacyObject {
  bool operator==(other) => false;
}
class X3 extends LegacyInt {
  bool operator==(other) => false;
}
''');
    checkElementText(library, r'''
library
  imports
    legacy.dart
  definingUnit
    classes
      class X1 @28
        supertype: LegacyDefault*
        constructors
          synthetic @-1
        methods
          == @71
            parameters
              requiredPositional other @74
                type: dynamic
            returnType: bool*
      class X2 @99
        supertype: LegacyObject*
        constructors
          synthetic @-1
        methods
          == @140
            parameters
              requiredPositional other @143
                type: Object*
            returnType: bool*
      class X3 @168
        supertype: LegacyInt*
        constructors
          synthetic @-1
        methods
          == @206
            parameters
              requiredPositional other @209
                type: int*
            returnType: bool*
''');
  }

  test_instanceInference_operator_equal_legacy_from_legacy_nullSafe() async {
    addLibrarySource('/legacy.dart', r'''
// @dart = 2.7
class LegacyDefault {
  bool operator==(other) => false;
}
class LegacyObject {
  bool operator==(Object other) => false;
}
class LegacyInt {
  bool operator==(int other) => false;
}
''');
    addLibrarySource('/nullSafe.dart', r'''
class NullSafeDefault {
  bool operator==(other) => false;
}
class NullSafeObject {
  bool operator==(Object other) => false;
}
class NullSafeInt {
  bool operator==(int other) => false;
}
''');
    var library = await checkLibrary(r'''
// @dart = 2.7
import 'legacy.dart';
import 'nullSafe.dart';
class X1 extends LegacyDefault implements NullSafeDefault {
  bool operator==(other) => false;
}
class X2 extends LegacyObject implements NullSafeObject {
  bool operator==(other) => false;
}
class X3 extends LegacyInt implements NullSafeInt {
  bool operator==(other) => false;
}
''');
    checkElementText(library, r'''
library
  imports
    legacy.dart
    nullSafe.dart
  definingUnit
    classes
      class X1 @67
        supertype: LegacyDefault*
        interfaces
          NullSafeDefault*
        constructors
          synthetic @-1
        methods
          == @136
            parameters
              requiredPositional other @139
                type: dynamic
            returnType: bool*
      class X2 @164
        supertype: LegacyObject*
        interfaces
          NullSafeObject*
        constructors
          synthetic @-1
        methods
          == @231
            parameters
              requiredPositional other @234
                type: Object*
            returnType: bool*
      class X3 @259
        supertype: LegacyInt*
        interfaces
          NullSafeInt*
        constructors
          synthetic @-1
        methods
          == @320
            parameters
              requiredPositional other @323
                type: int*
            returnType: bool*
''');
  }

  test_instanceInference_operator_equal_nullSafe_from_nullSafe() async {
    addLibrarySource('/nullSafe.dart', r'''
class NullSafeDefault {
  bool operator==(other) => false;
}
class NullSafeObject {
  bool operator==(Object other) => false;
}
class NullSafeInt {
  bool operator==(int other) => false;
}
''');
    var library = await checkLibrary(r'''
import 'nullSafe.dart';
class X1 extends NullSafeDefault {
  bool operator==(other) => false;
}
class X2 extends NullSafeObject {
  bool operator==(other) => false;
}
class X3 extends NullSafeInt {
  bool operator==(other) => false;
}
''');
    checkElementText(library, r'''
library
  imports
    nullSafe.dart
  definingUnit
    classes
      class X1 @30
        supertype: NullSafeDefault
        constructors
          synthetic @-1
        methods
          == @74
            parameters
              requiredPositional other @77
                type: Object
            returnType: bool
      class X2 @102
        supertype: NullSafeObject
        constructors
          synthetic @-1
        methods
          == @145
            parameters
              requiredPositional other @148
                type: Object
            returnType: bool
      class X3 @173
        supertype: NullSafeInt
        constructors
          synthetic @-1
        methods
          == @213
            parameters
              requiredPositional other @216
                type: int
            returnType: bool
''');
  }

  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    var library = await checkLibrary('''
class C<S extends num, T extends C<S, T>> {}
C c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant S @8
            bound: num
            defaultType: num
          covariant T @23
            bound: C<S, T>
            defaultType: C<num, dynamic>
        constructors
          synthetic @-1
    topLevelVariables
      static c @47
        type: C<num, C<num, dynamic>>
    accessors
      synthetic static get c @-1
        returnType: C<num, C<num, dynamic>>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<num, C<num, dynamic>>
        returnType: void
''');
  }

  test_instantiateToBounds_boundRefersToItself() async {
    var library = await checkLibrary('''
class C<T extends C<T>> {}
C c;
var c2 = new C();
class B {
  var c3 = new C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
      class B @56
        fields
          c3 @66
            type: C<C<Object?>>
        constructors
          synthetic @-1
        accessors
          synthetic get c3 @-1
            returnType: C<C<Object?>>
          synthetic set c3 @-1
            parameters
              requiredPositional _c3 @-1
                type: C<C<Object?>>
            returnType: void
    topLevelVariables
      static c @29
        type: C<C<dynamic>>
      static c2 @36
        type: C<C<Object?>>
    accessors
      synthetic static get c @-1
        returnType: C<C<dynamic>>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<C<dynamic>>
        returnType: void
      synthetic static get c2 @-1
        returnType: C<C<Object?>>
      synthetic static set c2 @-1
        parameters
          requiredPositional _c2 @-1
            type: C<C<Object?>>
        returnType: void
''');
  }

  test_instantiateToBounds_boundRefersToItself_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class C<T extends C<T>> {}
C c;
var c2 = new C();
class B {
  var c3 = new C();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: C<T*>*
            defaultType: C<dynamic>*
        constructors
          synthetic @-1
      class B @56
        fields
          c3 @66
            type: C<C<dynamic>*>*
        constructors
          synthetic @-1
        accessors
          synthetic get c3 @-1
            returnType: C<C<dynamic>*>*
          synthetic set c3 @-1
            parameters
              requiredPositional _c3 @-1
                type: C<C<dynamic>*>*
            returnType: void
    topLevelVariables
      static c @29
        type: C<C<dynamic>*>*
      static c2 @36
        type: C<C<dynamic>*>*
    accessors
      synthetic static get c @-1
        returnType: C<C<dynamic>*>*
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<C<dynamic>*>*
        returnType: void
      synthetic static get c2 @-1
        returnType: C<C<dynamic>*>*
      synthetic static set c2 @-1
        parameters
          requiredPositional _c2 @-1
            type: C<C<dynamic>*>*
        returnType: void
''');
  }

  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    var library = await checkLibrary('''
class C<T extends C<T, U>, U extends num> {}
C c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @6
        typeParameters
          covariant T @8
            bound: C<T, U>
            defaultType: C<dynamic, num>
          covariant U @27
            bound: num
            defaultType: num
        constructors
          synthetic @-1
    topLevelVariables
      static c @47
        type: C<C<dynamic, num>, num>
    accessors
      synthetic static get c @-1
        returnType: C<C<dynamic, num>, num>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<C<dynamic, num>, num>
        returnType: void
''');
  }

  test_instantiateToBounds_functionTypeAlias_reexported() async {
    addLibrarySource('/a.dart', r'''
class O {}
typedef T F<T extends O>(T p);
''');
    addLibrarySource('/b.dart', r'''
export 'a.dart' show F;
''');
    var library = await checkLibrary('''
import 'b.dart';
class C {
  F f() => null;
}
''');
    checkElementText(library, r'''
library
  imports
    b.dart
  definingUnit
    classes
      class C @23
        constructors
          synthetic @-1
        methods
          f @31
            returnType: O Function(O)
              aliasElement: a.dart::@typeAlias::F
              aliasArguments
                O
''');
  }

  test_instantiateToBounds_functionTypeAlias_simple() async {
    var library = await checkLibrary('''
typedef F<T extends num>(T p);
F f;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        typeParameters
          contravariant T @10
            bound: num
            defaultType: num
        aliasedType: dynamic Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional p @27
              type: T
          returnType: dynamic
    topLevelVariables
      static f @33
        type: dynamic Function(num)
          aliasElement: self::@typeAlias::F
          aliasArguments
            num
    accessors
      synthetic static get f @-1
        returnType: dynamic Function(num)
          aliasElement: self::@typeAlias::F
          aliasArguments
            num
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function(num)
              aliasElement: self::@typeAlias::F
              aliasArguments
                num
        returnType: void
''');
  }

  test_instantiateToBounds_genericFunctionAsBound() async {
    var library = await checkLibrary('''
class A<T> {}
class B<T extends int Function(), U extends A<T>> {}
B b;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
      notSimplyBounded class B @20
        typeParameters
          covariant T @22
            bound: int Function()
            defaultType: int Function()
          covariant U @48
            bound: A<T>
            defaultType: A<int Function()>
        constructors
          synthetic @-1
    topLevelVariables
      static b @69
        type: B<int Function(), A<int Function()>>
    accessors
      synthetic static get b @-1
        returnType: B<int Function(), A<int Function()>>
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: B<int Function(), A<int Function()>>
        returnType: void
''');
  }

  test_instantiateToBounds_genericTypeAlias_simple() async {
    var library = await checkLibrary('''
typedef F<T extends num> = S Function<S>(T p);
F f;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          contravariant T @10
            bound: num
            defaultType: num
        aliasedType: S Function<S>(T)
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant S @38
          parameters
            requiredPositional p @43
              type: T
          returnType: S
    topLevelVariables
      static f @49
        type: S Function<S>(num)
          aliasElement: self::@typeAlias::F
          aliasArguments
            num
    accessors
      synthetic static get f @-1
        returnType: S Function<S>(num)
          aliasElement: self::@typeAlias::F
          aliasArguments
            num
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: S Function<S>(num)
              aliasElement: self::@typeAlias::F
              aliasArguments
                num
        returnType: void
''');
  }

  test_instantiateToBounds_issue38498() async {
    var library = await checkLibrary('''
class A<R extends B> {
  final values = <B>[];
}
class B<T extends num> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant R @8
            bound: B<num>
            defaultType: B<num>
        fields
          final values @31
            type: List<B<num>>
        constructors
          synthetic @-1
        accessors
          synthetic get values @-1
            returnType: List<B<num>>
      class B @55
        typeParameters
          covariant T @57
            bound: num
            defaultType: num
        constructors
          synthetic @-1
''');
  }

  test_instantiateToBounds_simple() async {
    var library = await checkLibrary('''
class C<T extends num> {}
C c;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: num
            defaultType: num
        constructors
          synthetic @-1
    topLevelVariables
      static c @28
        type: C<num>
    accessors
      synthetic static get c @-1
        returnType: C<num>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<num>
        returnType: void
''');
  }

  test_invalid_annotation_prefixed_constructor() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await checkLibrary('''
import "a.dart" as a;
@a.A.named
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart as a @19
  definingUnit
    classes
      class C @39
        metadata
          Annotation
            atSign: @ @22
            constructorName: SimpleIdentifier
              staticElement: package:test/a.dart::@class::A::@constructor::named
              staticType: null
              token: named @27
            element: package:test/a.dart::@class::A::@constructor::named
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/a.dart::@class::A
                staticType: null
                token: A @25
              period: . @24
              prefix: SimpleIdentifier
                staticElement: self::@prefix::a
                staticType: null
                token: a @23
              staticElement: package:test/a.dart::@class::A
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_invalid_annotation_unprefixed_constructor() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/a.dart', r'''
class A {
  const A.named();
}
''');
    var library = await checkLibrary('''
import "a.dart";
@A.named
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class C @32
        metadata
          Annotation
            atSign: @ @17
            element: package:test/a.dart::@class::A::@constructor::named
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/a.dart::@class::A::@constructor::named
                staticType: null
                token: named @20
              period: . @19
              prefix: SimpleIdentifier
                staticElement: package:test/a.dart::@class::A
                staticType: null
                token: A @18
              staticElement: package:test/a.dart::@class::A::@constructor::named
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_invalid_importPrefix_asTypeArgument() async {
    var library = await checkLibrary('''
import 'dart:async' as ppp;
class C {
  List<ppp> v;
}
''');
    checkElementText(library, r'''
library
  imports
    dart:async as ppp @23
  definingUnit
    classes
      class C @34
        fields
          v @50
            type: List<dynamic>
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: List<dynamic>
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: List<dynamic>
            returnType: void
''');
  }

  test_invalid_nameConflict_imported() async {
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
    b.dart
  definingUnit
    functions
      foo @34
        parameters
          optionalPositional p @39
            type: dynamic
            constantInitializer
              SimpleIdentifier
                staticElement: <null>
                staticType: dynamic
                token: V @43
        returnType: dynamic
''');
  }

  test_invalid_nameConflict_imported_exported() async {
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    addLibrarySource('/c.dart', r'''
export 'a.dart';
export 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
library
  imports
    c.dart
  definingUnit
    functions
      foo @17
        parameters
          optionalPositional p @22
            type: dynamic
            constantInitializer
              SimpleIdentifier
                staticElement: a.dart::@function::V
                staticType: dynamic Function()
                token: V @26
        returnType: dynamic
''');
  }

  test_invalid_nameConflict_local() async {
    var library = await checkLibrary('''
foo([p = V]) {}
V() {}
var V;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static V @27
        type: dynamic
    accessors
      synthetic static get V @-1
        returnType: dynamic
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: dynamic
        returnType: void
    functions
      foo @0
        parameters
          optionalPositional p @5
            type: dynamic
            constantInitializer
              SimpleIdentifier
                staticElement: self::@getter::V
                staticType: dynamic
                token: V @9
        returnType: dynamic
      V @16
        returnType: dynamic
''');
  }

  test_invalid_setterParameter_fieldFormalParameter() async {
    var library = await checkLibrary('''
class C {
  int foo;
  void set bar(this.foo) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          foo @16
            type: int
          synthetic bar @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
            returnType: void
          set bar @32
            parameters
              requiredPositional final this.foo @41
                type: dynamic
            returnType: void
''');
  }

  test_invalid_setterParameter_fieldFormalParameter_self() async {
    var library = await checkLibrary('''
class C {
  set x(this.x) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @16
            parameters
              requiredPositional final this.x @23
                type: dynamic
            returnType: void
''');
  }

  test_invalidUris() async {
    var library = await checkLibrary(r'''
import ':[invaliduri]';
import ':[invaliduri]:foo.dart';
import 'a1.dart';
import ':[invaliduri]';
import ':[invaliduri]:foo.dart';

export ':[invaliduri]';
export ':[invaliduri]:foo.dart';
export 'a2.dart';
export ':[invaliduri]';
export ':[invaliduri]:foo.dart';

part ':[invaliduri]';
part 'a3.dart';
part ':[invaliduri]';
''');
    checkElementText(library, r'''
library
  imports
    <unresolved>
    <unresolved>
    a1.dart
    <unresolved>
    <unresolved>
  exports
    <unresolved>
    <unresolved>
    a2.dart
    <unresolved>
    <unresolved>
  definingUnit
  parts
    a3.dart
''');
  }

  test_library() async {
    var library = await checkLibrary('');
    checkElementText(library, r'''
library
  definingUnit
''');
  }

  test_library_documented_lines() async {
    var library = await checkLibrary('''
/// aaa
/// bbb
library test;
''');
    checkElementText(library, r'''
library
  name: test
  nameOffset: 24
  documentationComment: /// aaa\n/// bbb
  definingUnit
''');
  }

  test_library_documented_stars() async {
    var library = await checkLibrary('''
/**
 * aaa
 * bbb
 */
library test;''');
    checkElementText(library, r'''
library
  name: test
  nameOffset: 30
  documentationComment: /**\n * aaa\n * bbb\n */
  definingUnit
''');
  }

  test_library_name_with_spaces() async {
    var library = await checkLibrary('library foo . bar ;');
    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  definingUnit
''');
  }

  test_library_named() async {
    var library = await checkLibrary('library foo.bar;');
    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  definingUnit
''');
  }

  test_localFunctions() async {
    var library = await checkLibrary(r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        returnType: dynamic
''');
  }

  test_localFunctions_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @12
''');
  }

  test_localFunctions_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          m @12
            returnType: dynamic
''');
  }

  test_localFunctions_inTopLevelGetter() async {
    var library = await checkLibrary(r'''
get g {
  f() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static g @-1
        type: dynamic
    accessors
      get g @4
        returnType: dynamic
''');
  }

  test_localLabels_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          @12
''');
  }

  test_localLabels_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          m @12
            returnType: dynamic
''');
  }

  test_localLabels_inTopLevelFunction() async {
    var library = await checkLibrary(r'''
main() {
  aaa: while (true) {}
  bbb: switch (42) {
    ccc: case 0:
      break;
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    functions
      main @0
        returnType: dynamic
''');
  }

  test_main_class() async {
    var library = await checkLibrary('class main {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class main @6
        constructors
          synthetic @-1
''');
  }

  test_main_class_alias() async {
    var library =
        await checkLibrary('class main = C with D; class C {} class D {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias main @6
        supertype: C
        mixins
          D
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::C::@constructor::•
                superKeyword: super @0
      class C @29
        constructors
          synthetic @-1
      class D @40
        constructors
          synthetic @-1
''');
  }

  test_main_class_alias_via_export() async {
    addLibrarySource('/a.dart', 'class main = C with D; class C {} class D {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_main_class_via_export() async {
    addLibrarySource('/a.dart', 'class main {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_main_getter() async {
    var library = await checkLibrary('get main => null;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static main @-1
        type: dynamic
    accessors
      get main @4
        returnType: dynamic
''');
  }

  test_main_getter_via_export() async {
    addLibrarySource('/a.dart', 'get main => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_main_typedef() async {
    var library = await checkLibrary('typedef main();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased main @8
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_main_typedef_via_export() async {
    addLibrarySource('/a.dart', 'typedef main();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_main_variable() async {
    var library = await checkLibrary('var main;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static main @4
        type: dynamic
    accessors
      synthetic static get main @-1
        returnType: dynamic
      synthetic static set main @-1
        parameters
          requiredPositional _main @-1
            type: dynamic
        returnType: void
''');
  }

  test_main_variable_via_export() async {
    addLibrarySource('/a.dart', 'var main;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  exports
    a.dart
  definingUnit
''');
  }

  test_member_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Future f() async {}
}
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    classes
      class C @27
        constructors
          synthetic @-1
        methods
          f @40 async
            returnType: Future<dynamic>
''');
  }

  test_member_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Stream f() async* {}
}
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    classes
      class C @27
        constructors
          synthetic @-1
        methods
          f @40 async*
            returnType: Stream<dynamic>
''');
  }

  test_member_function_syncStar() async {
    var library = await checkLibrary(r'''
class C {
  Iterable<int> f() sync* {
    yield 42;
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @26 sync*
            returnType: Iterable<int>
''');
  }

  test_metadata_class_field_first() async {
    var library = await checkLibrary(r'''
const a = 0;
class C {
  @a
  int x = 0;
}
''');
    // Check metadata without asking any other properties.
    var x = _elementOfDefiningUnit(library, ['@class', 'C', '@field', 'x'])
        as FieldElement;
    expect(x.metadata, hasLength(1));
    // Check details.
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @19
        fields
          x @34
            metadata
              Annotation
                atSign: @ @25
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @26
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_class_scope() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
class C<@foo T> {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @27
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @34
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @29
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @30
        fields
          static const foo @54
            type: int
            constantInitializer
              IntegerLiteral
                literal: 1 @60
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get foo @-1
            returnType: int
        methods
          bar @77
            metadata
              Annotation
                atSign: @ @65
                element: self::@class::C::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@class::C::@getter::foo
                  staticType: null
                  token: foo @66
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_classDeclaration() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
@a
@b
class C {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @44
        metadata
          Annotation
            atSign: @ @32
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @33
          Annotation
            atSign: @ @35
            element: self::@getter::b
            name: SimpleIdentifier
              staticElement: self::@getter::b
              staticType: null
              token: b @36
        constructors
          synthetic @-1
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static const b @22
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @26
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get b @-1
        returnType: dynamic
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await checkLibrary(
        'const a = null; @a class C = D with E; class D {} class E {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @25
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @45
        constructors
          synthetic @-1
      class E @56
        constructors
          synthetic @-1
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_constructor_call_named() async {
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
class A {
  const A.named(int _);
}
@A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const named @20
            periodOffset: 19
            nameEnd: 25
            parameters
              requiredPositional _ @30
                type: int
      class C @54
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @45
                  staticType: int
              leftParenthesis: ( @44
              rightParenthesis: ) @46
            atSign: @ @36
            element: self::@class::A::@constructor::named
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@class::A::@constructor::named
                staticType: null
                token: named @39
              period: . @38
              prefix: SimpleIdentifier
                staticElement: self::@class::A
                staticType: null
                token: A @37
              staticElement: self::@class::A::@constructor::named
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_generic_inference() async {
    var library = await checkLibrary('''
class A<T> {
  const A.named(T _);
}

@A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const named @23
            periodOffset: 22
            nameEnd: 28
            parameters
              requiredPositional _ @31
                type: T
      class C @56
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @47
                  staticType: int
              leftParenthesis: ( @46
              rightParenthesis: ) @48
            atSign: @ @38
            element: ConstructorMember
              base: self::@class::A::@constructor::named
              substitution: {T: int}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: ConstructorMember
                  base: self::@class::A::@constructor::named
                  substitution: {T: int}
                staticType: null
                token: named @41
              period: . @40
              prefix: SimpleIdentifier
                staticElement: self::@class::A
                staticType: null
                token: A @39
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::named
                substitution: {T: int}
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments() async {
    var library = await checkLibrary('''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const named @23
            periodOffset: 22
            nameEnd: 28
      class C @57
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @48
              rightParenthesis: ) @49
            atSign: @ @35
            constructorName: SimpleIdentifier
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::named
                substitution: {T: int}
              staticType: null
              token: named @43
            element: ConstructorMember
              base: self::@class::A::@constructor::named
              substitution: {T: int}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @36
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @38
                  type: int
              leftBracket: < @37
              rightBracket: > @41
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_generic_typeArguments_disabledGenericMetadata() async {
    var library = await checkLibrary('''
class A<T> {
  const A.named();
}

@A<int>.named()
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const named @23
            periodOffset: 22
            nameEnd: 28
      class C @57
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @48
              rightParenthesis: ) @49
            atSign: @ @35
            constructorName: SimpleIdentifier
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::named
                substitution: {T: int}
              staticType: null
              token: named @43
            element: ConstructorMember
              base: self::@class::A::@constructor::named
              substitution: {T: int}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @36
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @38
                  type: int
              leftBracket: < @37
              rightBracket: > @41
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_prefixed() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/foo.dart', '''
class A {
  const A.named(int _);
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
@foo.A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @48
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @39
                  staticType: int
              leftParenthesis: ( @38
              rightParenthesis: ) @40
            atSign: @ @26
            constructorName: SimpleIdentifier
              staticElement: package:test/foo.dart::@class::A::@constructor::named
              staticType: null
              token: named @33
            element: package:test/foo.dart::@class::A::@constructor::named
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_prefixed_generic_inference() async {
    addLibrarySource('/home/test/lib/foo.dart', '''
class A<T> {
  const A.named(T _);
}
''');
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
import "foo.dart" as foo;
@foo.A.named(0)
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @48
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @39
                  staticType: int
              leftParenthesis: ( @38
              rightParenthesis: ) @40
            atSign: @ @26
            constructorName: SimpleIdentifier
              staticElement: ConstructorMember
                base: package:test/foo.dart::@class::A::@constructor::named
                substitution: {T: int}
              staticType: null
              token: named @33
            element: ConstructorMember
              base: package:test/foo.dart::@class::A::@constructor::named
              substitution: {T: int}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_prefixed_generic_typeArguments() async {
    addLibrarySource('/home/test/lib/foo.dart', '''
class A<T> {
  const A.named();
}
''');
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
import "foo.dart" as foo;
@foo.A<int>.named()
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @52
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @43
              rightParenthesis: ) @44
            atSign: @ @26
            constructorName: SimpleIdentifier
              staticElement: ConstructorMember
                base: package:test/foo.dart::@class::A::@constructor::named
                substitution: {T: int}
              staticType: null
              token: named @38
            element: ConstructorMember
              base: package:test/foo.dart::@class::A::@constructor::named
              substitution: {T: int}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @33
                  type: int
              leftBracket: < @32
              rightBracket: > @36
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_named_synthetic_ofClassAlias_generic() async {
    var library = await checkLibrary('''
class A {
  const A.named();
}

mixin B {}

class C<T> = A with B;

@C.named()
class D {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const named @20
            periodOffset: 19
            nameEnd: 25
      class alias C @50
        typeParameters
          covariant T @52
            defaultType: dynamic
        supertype: A
        mixins
          B
        constructors
          synthetic const named @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                constructorName: SimpleIdentifier
                  staticElement: self::@class::A::@constructor::named
                  staticType: null
                  token: named @-1
                period: . @0
                staticElement: self::@class::A::@constructor::named
                superKeyword: super @0
      class D @85
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @76
              rightParenthesis: ) @77
            atSign: @ @68
            element: ConstructorMember
              base: self::@class::C::@constructor::named
              substitution: {T: dynamic}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: ConstructorMember
                  base: self::@class::C::@constructor::named
                  substitution: {T: dynamic}
                staticType: null
                token: named @71
              period: . @70
              prefix: SimpleIdentifier
                staticElement: self::@class::C
                staticType: null
                token: C @69
              staticElement: ConstructorMember
                base: self::@class::C::@constructor::named
                substitution: {T: dynamic}
              staticType: null
        constructors
          synthetic @-1
    mixins
      mixin B @38
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed() async {
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
class A {
  const A(int _);
}
@A(0)
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional _ @24
                type: int
      class C @42
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @33
                  staticType: int
              leftParenthesis: ( @32
              rightParenthesis: ) @34
            atSign: @ @30
            element: self::@class::A::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @31
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_generic_inference() async {
    var library = await checkLibrary('''
class A<T> {
  const A(T _);
}

@A(0)
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
            parameters
              requiredPositional _ @25
                type: T
      class C @44
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @35
                  staticType: int
              leftParenthesis: ( @34
              rightParenthesis: ) @36
            atSign: @ @32
            element: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @33
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_generic_typeArguments() async {
    var library = await checkLibrary('''
class A<T> {
  const A();
}

@A<int>()
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
      class C @45
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @36
              rightParenthesis: ) @37
            atSign: @ @29
            element: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int}
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @30
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @32
                  type: int
              leftBracket: < @31
              rightBracket: > @35
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/foo.dart', 'class A { const A(_); }');
    var library =
        await checkLibrary('import "foo.dart" as foo; @foo.A(0) class C {}');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @42
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @33
                  staticType: int
              leftParenthesis: ( @32
              rightParenthesis: ) @34
            atSign: @ @26
            element: package:test/foo.dart::@class::A::@constructor::•
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_prefixed_generic_inference() async {
    addLibrarySource('/home/test/lib/foo.dart', '''
class A<T> {
  const A(T _);
}
''');
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
import "foo.dart" as foo;
@foo.A(0)
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @42
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 0 @33
                  staticType: int
              leftParenthesis: ( @32
              rightParenthesis: ) @34
            atSign: @ @26
            element: ConstructorMember
              base: package:test/foo.dart::@class::A::@constructor::•
              substitution: {T: int}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_prefixed_generic_typeArguments() async {
    addLibrarySource('/home/test/lib/foo.dart', '''
class A<T> {
  const A();
}
''');
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
import "foo.dart" as foo;
@foo.A<int>()
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @46
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @37
              rightParenthesis: ) @38
            atSign: @ @26
            element: ConstructorMember
              base: package:test/foo.dart::@class::A::@constructor::•
              substitution: {T: int}
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@class::A
                staticType: null
                token: A @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@class::A
              staticType: null
            typeArguments: TypeArgumentList
              arguments
                NamedType
                  name: SimpleIdentifier
                    staticElement: dart:core::@class::int
                    staticType: null
                    token: int @33
                  type: int
              leftBracket: < @32
              rightBracket: > @36
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_unnamed_synthetic_ofClassAlias_generic() async {
    var library = await checkLibrary('''
class A {
  const A();
}

mixin B {}

class C<T> = A with B;

@C()
class D {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
      class alias C @44
        typeParameters
          covariant T @46
            defaultType: dynamic
        supertype: A
        mixins
          B
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
      class D @73
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @64
              rightParenthesis: ) @65
            atSign: @ @62
            element: ConstructorMember
              base: self::@class::C::@constructor::•
              substitution: {T: dynamic}
            name: SimpleIdentifier
              staticElement: self::@class::C
              staticType: null
              token: C @63
        constructors
          synthetic @-1
    mixins
      mixin B @32
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library =
        await checkLibrary('class A { const A(x); } @A(null) class C {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @16
            parameters
              requiredPositional x @18
                type: dynamic
      class C @39
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                NullLiteral
                  literal: null @27
                  staticType: Null
              leftParenthesis: ( @26
              rightParenthesis: ) @31
            atSign: @ @24
            element: self::@class::A::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @25
        constructors
          synthetic @-1
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library =
        await checkLibrary('const a = null; class C { @a C.named(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        constructors
          named @31
            metadata
              Annotation
                atSign: @ @26
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @27
            periodOffset: 30
            nameEnd: 36
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await checkLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        constructors
          @29
            metadata
              Annotation
                atSign: @ @26
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @27
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_enumConstantDeclaration() async {
    var library = await checkLibrary('const a = 42; enum E { @a v }');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @19
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @26
            metadata
              Annotation
                atSign: @ @23
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @24
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 42 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_enumConstantDeclaration_instanceCreation() async {
    var library = await checkLibrary('''
class A {
  final dynamic value;
  const A(this.value);
}

enum E {
  @A(100) a,
  b,
  @A(300) c,
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          final value @26
            type: dynamic
        constructors
          const @41
            parameters
              requiredPositional final this.value @48
                type: dynamic
        accessors
          synthetic get value @-1
            returnType: dynamic
    enums
      enum E @64
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @78
            metadata
              Annotation
                arguments: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 100 @73
                      staticType: int
                  leftParenthesis: ( @72
                  rightParenthesis: ) @76
                atSign: @ @70
                element: self::@class::A::@constructor::•
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @71
            type: E
          static const b @83
            type: E
          static const c @96
            metadata
              Annotation
                arguments: ArgumentList
                  arguments
                    IntegerLiteral
                      literal: 300 @91
                      staticType: int
                  leftParenthesis: ( @90
                  rightParenthesis: ) @94
                atSign: @ @88
                element: self::@class::A::@constructor::•
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @89
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
          synthetic static get c @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_metadata_enumDeclaration() async {
    var library = await checkLibrary('const a = 42; @a enum E { v }');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @22
        metadata
          Annotation
            atSign: @ @14
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @15
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @26
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 42 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_exportDirective() async {
    addLibrarySource('/foo.dart', '');
    var library = await checkLibrary('@a export "foo.dart"; const a = null;');
    checkElementText(library, r'''
library
  metadata
    Annotation
      atSign: @ @0
      element: self::@getter::a
      name: SimpleIdentifier
        staticElement: self::@getter::a
        staticType: null
        token: a @1
  exports
    foo.dart
      metadata
        Annotation
          atSign: @ @0
          element: self::@getter::a
          name: SimpleIdentifier
            staticElement: self::@getter::a
            staticType: null
            token: a @1
  definingUnit
    topLevelVariables
      static const a @28
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @32
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_extension_scope() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
extension E<@foo T> on int {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      E @31
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @38
            metadata
              Annotation
                atSign: @ @33
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @34
        extendedType: int
        fields
          static const foo @65
            type: int
            constantInitializer
              IntegerLiteral
                literal: 1 @71
                staticType: int
        accessors
          synthetic static get foo @-1
            returnType: int
        methods
          bar @88
            metadata
              Annotation
                atSign: @ @76
                element: self::@extension::E::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@extension::E::@getter::foo
                  staticType: null
                  token: foo @77
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_extensionDeclaration() async {
    var library = await checkLibrary(r'''
const a = null;
class A {}
@a
@Object()
extension E on A {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        constructors
          synthetic @-1
    extensions
      E @50
        metadata
          Annotation
            atSign: @ @27
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @28
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @37
              rightParenthesis: ) @38
            atSign: @ @30
            element: dart:core::@class::Object::@constructor::•
            name: SimpleIdentifier
              staticElement: dart:core::@class::Object
              staticType: null
              token: Object @31
        extendedType: A
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await checkLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        fields
          x @33
            metadata
              Annotation
                atSign: @ @26
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @27
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_fieldFormalParameter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  var x;
  C(@a this.x);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        fields
          x @32
            type: dynamic
        constructors
          @37
            parameters
              requiredPositional final this.x @47
                type: dynamic
                metadata
                  Annotation
                    atSign: @ @39
                    element: self::@getter::a
                    name: SimpleIdentifier
                      staticElement: self::@getter::a
                      staticType: null
                      token: a @40
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await checkLibrary(
        'const a = null; class C { var x; C([@a this.x = null]); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        fields
          x @30
            type: dynamic
        constructors
          @33
            parameters
              optionalPositional final this.x @44
                type: dynamic
                metadata
                  Annotation
                    atSign: @ @36
                    element: self::@getter::a
                    name: SimpleIdentifier
                      staticElement: self::@getter::a
                      staticType: null
                      token: a @37
                constantInitializer
                  NullLiteral
                    literal: null @48
                    staticType: Null
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_function() async {
    var library = await checkLibrary('''
const a = null;
@a
f() {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @19
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await checkLibrary('const a = null; @a get f => null;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      synthetic static f @-1
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      get f @23
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        returnType: dynamic
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await checkLibrary('const a = null; @a set f(value) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      synthetic static f @-1
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      set f @23
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        parameters
          requiredPositional value @25
            type: dynamic
        returnType: void
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await checkLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @27
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a g()) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @16
        parameters
          requiredPositional g @21
            type: dynamic Function()
            metadata
              Annotation
                atSign: @ @18
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @19
        returnType: dynamic
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a g() = null]) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @16
        parameters
          optionalPositional g @22
            type: dynamic Function()
            metadata
              Annotation
                atSign: @ @19
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @20
            constantInitializer
              NullLiteral
                literal: null @28
                staticType: null
        returnType: dynamic
''');
  }

  test_metadata_genericTypeAlias() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
@a
@b
typedef F = void Function();''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @46
        metadata
          Annotation
            atSign: @ @32
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @33
          Annotation
            atSign: @ @35
            element: self::@getter::b
            name: SimpleIdentifier
              staticElement: self::@getter::b
              staticType: null
              token: b @36
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static const b @22
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @26
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get b @-1
        returnType: dynamic
''');
  }

  test_metadata_importDirective() async {
    var library = await checkLibrary('''
@a
import "dart:math";
const a = 0;
''');
    checkElementText(library, r'''
library
  metadata
    Annotation
      atSign: @ @0
      element: self::@getter::a
      name: SimpleIdentifier
        staticElement: self::@getter::a
        staticType: null
        token: a @1
  imports
    dart:math
      metadata
        Annotation
          atSign: @ @0
          element: self::@getter::a
          name: SimpleIdentifier
            staticElement: self::@getter::a
            staticType: null
            token: a @1
  definingUnit
    topLevelVariables
      static const a @29
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @33
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_importDirective_hasShow() async {
    var library = await checkLibrary(r'''
@a
import "dart:math" show Random;

const a = 0;
''');
    checkElementText(library, r'''
library
  metadata
    Annotation
      atSign: @ @0
      element: self::@getter::a
      name: SimpleIdentifier
        staticElement: self::@getter::a
        staticType: null
        token: a @1
  imports
    dart:math
      metadata
        Annotation
          atSign: @ @0
          element: self::@getter::a
          name: SimpleIdentifier
            staticElement: self::@getter::a
            staticType: null
            token: a @1
      combinators
        show: Random
  definingUnit
    topLevelVariables
      static const a @42
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @46
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_inAliasedElement_formalParameter() async {
    var library = await checkLibrary('''
const a = 42;
typedef F = void Function(@a int first)
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @22
        aliasedType: void Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional first @47
              type: int
              metadata
                Annotation
                  atSign: @ @40
                  element: self::@getter::a
                  name: SimpleIdentifier
                    staticElement: self::@getter::a
                    staticType: null
                    token: a @41
          returnType: void
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 42 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_inAliasedElement_formalParameter2() async {
    var library = await checkLibrary('''
const a = 42;
typedef F = void Function(int foo(@a int bar))
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @22
        aliasedType: void Function(int Function(int))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional foo @44
              type: int Function(int)
              parameters
                requiredPositional bar @55
                  type: int
                  metadata
                    Annotation
                      atSign: @ @48
                      element: self::@getter::a
                      name: SimpleIdentifier
                        staticElement: self::@getter::a
                        staticType: null
                        token: a @49
          returnType: void
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 42 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_inAliasedElement_typeParameter() async {
    var library = await checkLibrary('''
const a = 42;
typedef F = void Function<@a T>(int first)
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @22
        aliasedType: void Function<T>(int)
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant T @43
              metadata
                Annotation
                  atSign: @ @40
                  element: self::@getter::a
                  name: SimpleIdentifier
                    staticElement: self::@getter::a
                    staticType: null
                    token: a @41
          parameters
            requiredPositional first @50
              type: int
          returnType: void
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 42 @10
            staticType: int
    accessors
      synthetic static get a @-1
        returnType: int
''');
  }

  test_metadata_invalid_classDeclaration() async {
    var library = await checkLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @21
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                IntegerLiteral
                  literal: 42 @11
                  staticType: int
              leftParenthesis: ( @10
              rightParenthesis: ) @13
            atSign: @ @8
            element: self::@function::f
            name: SimpleIdentifier
              staticElement: self::@function::f
              staticType: null
              token: f @9
        constructors
          synthetic @-1
    functions
      f @0
        parameters
          requiredPositional _ @2
            type: dynamic
        returnType: dynamic
''');
  }

  test_metadata_libraryDirective() async {
    var library = await checkLibrary('@a library L; const a = null;');
    checkElementText(library, r'''
library
  name: L
  nameOffset: 11
  metadata
    Annotation
      atSign: @ @0
      element: self::@getter::a
      name: SimpleIdentifier
        staticElement: self::@getter::a
        staticType: null
        token: a @1
  definingUnit
    topLevelVariables
      static const a @20
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @24
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library =
        await checkLibrary('const a = null; class C { @a get m => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        fields
          synthetic m @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get m @33
            metadata
              Annotation
                atSign: @ @26
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @27
            returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_methodDeclaration_method() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
class C {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @38
        constructors
          synthetic @-1
        methods
          m @54
            metadata
              Annotation
                atSign: @ @44
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @45
              Annotation
                atSign: @ @49
                element: self::@getter::b
                name: SimpleIdentifier
                  staticElement: self::@getter::b
                  staticType: null
                  token: b @50
            returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static const b @22
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @26
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get b @-1
        returnType: dynamic
''');
  }

  test_metadata_methodDeclaration_method_mixin() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
mixin M {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @38
        superclassConstraints
          Object
        constructors
          synthetic @-1
        methods
          m @54
            metadata
              Annotation
                atSign: @ @44
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @45
              Annotation
                atSign: @ @49
                element: self::@getter::b
                name: SimpleIdentifier
                  staticElement: self::@getter::b
                  staticType: null
                  token: b @50
            returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static const b @22
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @26
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get b @-1
        returnType: dynamic
''');
  }

  test_metadata_methodDeclaration_setter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  @a
  set m(value) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        fields
          synthetic m @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set m @37
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @29
            parameters
              requiredPositional value @39
                type: dynamic
            returnType: void
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_mixin_scope() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
mixin M<@foo T> {
  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @27
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @34
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @29
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @30
        superclassConstraints
          Object
        fields
          static const foo @54
            type: int
            constantInitializer
              IntegerLiteral
                literal: 1 @60
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get foo @-1
            returnType: int
        methods
          bar @77
            metadata
              Annotation
                atSign: @ @65
                element: self::@mixin::M::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@mixin::M::@getter::foo
                  staticType: null
                  token: foo @66
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_mixinDeclaration() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
@a
@b
mixin M {}''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @44
        metadata
          Annotation
            atSign: @ @32
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @33
          Annotation
            atSign: @ @35
            element: self::@getter::b
            name: SimpleIdentifier
              staticElement: self::@getter::b
              staticType: null
              token: b @36
        superclassConstraints
          Object
        constructors
          synthetic @-1
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static const b @22
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @26
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get b @-1
        returnType: dynamic
''');
  }

  test_metadata_offsets_onClass() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
class A<@foo T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @27
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @34
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @29
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @30
        constructors
          synthetic @-1
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onClassConstructor() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {
  @foo
  A(@foo int a);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        constructors
          @35
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
            parameters
              requiredPositional a @46
                type: int
                metadata
                  Annotation
                    atSign: @ @37
                    element: self::@getter::foo
                    name: SimpleIdentifier
                      staticElement: self::@getter::foo
                      staticType: null
                      token: foo @38
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onClassGetter() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {
  @foo
  int get getter => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        fields
          synthetic getter @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get getter @43
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
            returnType: int
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onClassMethod() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {
  @foo
  void method<@foo T>(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        constructors
          synthetic @-1
        methods
          method @40
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
            typeParameters
              covariant T @52
                metadata
                  Annotation
                    atSign: @ @47
                    element: self::@getter::foo
                    name: SimpleIdentifier
                      staticElement: self::@getter::foo
                      staticType: null
                      token: foo @48
            parameters
              requiredPositional a @64
                type: int
                metadata
                  Annotation
                    atSign: @ @55
                    element: self::@getter::foo
                    name: SimpleIdentifier
                      staticElement: self::@getter::foo
                      staticType: null
                      token: foo @56
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onClassSetter() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {
  @foo
  set setter(@foo int a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        fields
          synthetic setter @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set setter @39
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
            parameters
              requiredPositional a @55
                type: int
                metadata
                  Annotation
                    atSign: @ @46
                    element: self::@getter::foo
                    name: SimpleIdentifier
                      staticElement: self::@getter::foo
                      staticType: null
                      token: foo @47
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onClassTypeAlias() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {}
mixin M {}

@foo
class B<@foo T> = A with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        constructors
          synthetic @-1
      class alias B @50
        metadata
          Annotation
            atSign: @ @39
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @40
        typeParameters
          covariant T @57
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @52
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @53
        supertype: A
        mixins
          M
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
    mixins
      mixin M @33
        superclassConstraints
          Object
        constructors
          synthetic @-1
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onEnum() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
enum E {
  @foo e1,
  e2,
  @foo e3,
}
''');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @26
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const e1 @37
            metadata
              Annotation
                atSign: @ @32
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @33
            type: E
          static const e2 @43
            type: E
          static const e3 @54
            metadata
              Annotation
                atSign: @ @49
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @50
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get e1 @-1
            returnType: E
          synthetic static get e2 @-1
            returnType: E
          synthetic static get e3 @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onExtension() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
extension E<@foo T> on List<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      E @31
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @38
            metadata
              Annotation
                atSign: @ @33
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @34
        extendedType: List<T>
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onFieldDeclaration() async {
    var library = await checkLibrary(r'''
const foo = 0;

class A {
  @foo
  static isStatic = 1;

  @foo
  static const isStaticConst = 2;

  @foo
  var isInstance = 3;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @22
        fields
          static isStatic @42
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
            type: int
          static const isStaticConst @79
            metadata
              Annotation
                atSign: @ @59
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @60
            type: int
            constantInitializer
              IntegerLiteral
                literal: 2 @95
                staticType: int
          isInstance @112
            metadata
              Annotation
                atSign: @ @101
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @102
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get isStatic @-1
            returnType: int
          synthetic static set isStatic @-1
            parameters
              requiredPositional _isStatic @-1
                type: int
            returnType: void
          synthetic static get isStaticConst @-1
            returnType: int
          synthetic get isInstance @-1
            returnType: int
          synthetic set isInstance @-1
            parameters
              requiredPositional _isInstance @-1
                type: int
            returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onLibrary() async {
    var library = await checkLibrary('''
/// Some documentation.
@foo
library my.lib;

const foo = 0;
''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 37
  documentationComment: /// Some documentation.
  metadata
    Annotation
      atSign: @ @24
      element: self::@getter::foo
      name: SimpleIdentifier
        staticElement: self::@getter::foo
        staticType: null
        token: foo @25
  definingUnit
    topLevelVariables
      static const foo @52
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @58
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onMixin() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
mixin A<@foo T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin A @27
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @34
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @29
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @30
        superclassConstraints
          Object
        constructors
          synthetic @-1
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onTypeAlias_classic() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
typedef void F<@foo T>(@foo int a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @34
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          unrelated T @41
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @36
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @37
        aliasedType: void Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @53
              type: int
              metadata
                Annotation
                  atSign: @ @44
                  element: self::@getter::foo
                  name: SimpleIdentifier
                    staticElement: self::@getter::foo
                    staticType: null
                    token: foo @45
          returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onTypeAlias_genericFunctionType() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
typedef A<@foo T> = void Function<@foo U>(@foo int a);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @29
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          unrelated T @36
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @31
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @32
        aliasedType: void Function<U>(int)
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant U @60
              metadata
                Annotation
                  atSign: @ @55
                  element: self::@getter::foo
                  name: SimpleIdentifier
                    staticElement: self::@getter::foo
                    staticType: null
                    token: foo @56
          parameters
            requiredPositional a @72
              type: int
              metadata
                Annotation
                  atSign: @ @63
                  element: self::@getter::foo
                  name: SimpleIdentifier
                    staticElement: self::@getter::foo
                    staticType: null
                    token: foo @64
          returnType: void
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
''');
  }

  test_metadata_offsets_onUnit() async {
    addSource('/a.dart', '''
part of my.lib;
''');

    addSource('/b.dart', '''
part of my.lib;
''');

    var library = await checkLibrary('''
library my.lib;

@foo
part 'a.dart';

@foo
part 'b.dart';

const foo = 0;
''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
    topLevelVariables
      static const foo @65
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @71
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
  parts
    a.dart
      metadata
        Annotation
          atSign: @ @17
          element: self::@getter::foo
          name: SimpleIdentifier
            staticElement: self::@getter::foo
            staticType: null
            token: foo @18
    b.dart
      metadata
        Annotation
          atSign: @ @38
          element: self::@getter::foo
          name: SimpleIdentifier
            staticElement: self::@getter::foo
            staticType: null
            token: foo @39
''');
  }

  test_metadata_offsets_onUnitFunction() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
void f<@foo T>({@foo int? a = 42}) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
    functions
      f @26
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        typeParameters
          covariant T @33
            metadata
              Annotation
                atSign: @ @28
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @29
        parameters
          optionalNamed a @47
            type: int?
            metadata
              Annotation
                atSign: @ @37
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @38
            constantInitializer
              IntegerLiteral
                literal: 42 @51
                staticType: int
        returnType: void
''');
  }

  test_metadata_offsets_onUnitGetter() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
int get getter => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
      synthetic static getter @-1
        type: int
    accessors
      synthetic static get foo @-1
        returnType: int
      get getter @29
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        returnType: int
''');
  }

  test_metadata_offsets_onUnitSetter() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
set setter(@foo int a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
      synthetic static setter @-1
        type: int
    accessors
      synthetic static get foo @-1
        returnType: int
      set setter @25
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        parameters
          requiredPositional a @41
            type: int
            metadata
              Annotation
                atSign: @ @32
                element: self::@getter::foo
                name: SimpleIdentifier
                  staticElement: self::@getter::foo
                  staticType: null
                  token: foo @33
        returnType: void
''');
  }

  test_metadata_offsets_onUnitVariable() async {
    var library = await checkLibrary(r'''
const foo = 0;

@foo
var isNotConst = 1;

@foo
const isConst = 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const foo @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @12
            staticType: int
      static isNotConst @25
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @17
        type: int
      static const isConst @53
        metadata
          Annotation
            atSign: @ @42
            element: self::@getter::foo
            name: SimpleIdentifier
              staticElement: self::@getter::foo
              staticType: null
              token: foo @43
        type: int
        constantInitializer
          IntegerLiteral
            literal: 2 @63
            staticType: int
    accessors
      synthetic static get foo @-1
        returnType: int
      synthetic static get isNotConst @-1
        returnType: int
      synthetic static set isNotConst @-1
        parameters
          requiredPositional _isNotConst @-1
            type: int
        returnType: void
      synthetic static get isConst @-1
        returnType: int
''');
  }

  test_metadata_partDirective() async {
    addSource('/foo.dart', 'part of L;');
    var library = await checkLibrary('''
library L;
@a
part 'foo.dart';
const a = null;''');
    checkElementText(library, r'''
library
  name: L
  nameOffset: 8
  definingUnit
    topLevelVariables
      static const a @37
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @41
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
  parts
    foo.dart
      metadata
        Annotation
          atSign: @ @11
          element: self::@getter::a
          name: SimpleIdentifier
            staticElement: self::@getter::a
            staticType: null
            token: a @12
''');
  }

  test_metadata_partDirective2() async {
    addSource('/a.dart', r'''
part of 'test.dart';
''');
    addSource('/b.dart', r'''
part of 'test.dart';
''');
    var library = await checkLibrary('''
part 'a.dart';
part 'b.dart';
''');

    // The difference with the test above is that we ask the part first.
    // There was a bug that we were not loading library directives.
    expect(library.parts[0].metadata, isEmpty);
  }

  test_metadata_prefixed_variable() async {
    addLibrarySource('/a.dart', 'const b = null;');
    var library = await checkLibrary('import "a.dart" as a; @a.b class C {}');
    checkElementText(library, r'''
library
  imports
    a.dart as a @19
  definingUnit
    classes
      class C @33
        metadata
          Annotation
            atSign: @ @22
            element: a.dart::@getter::b
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: a.dart::@getter::b
                staticType: null
                token: b @25
              period: . @24
              prefix: SimpleIdentifier
                staticElement: self::@prefix::a
                staticType: null
                token: a @23
              staticElement: a.dart::@getter::b
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_simpleFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a x) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @16
        parameters
          requiredPositional x @21
            type: dynamic
            metadata
              Annotation
                atSign: @ @18
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @19
        returnType: dynamic
''');
  }

  test_metadata_simpleFormalParameter_method() async {
    var library = await checkLibrary('''
const a = null;

class C {
  m(@a x) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @23
        constructors
          synthetic @-1
        methods
          m @29
            parameters
              requiredPositional x @34
                type: dynamic
                metadata
                  Annotation
                    atSign: @ @31
                    element: self::@getter::a
                    name: SimpleIdentifier
                      staticElement: self::@getter::a
                      staticType: null
                      token: a @32
            returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_simpleFormalParameter_unit_setter() async {
    var library = await checkLibrary('''
const a = null;

set foo(@a int x) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      synthetic static foo @-1
        type: int
    accessors
      synthetic static get a @-1
        returnType: dynamic
      set foo @21
        parameters
          requiredPositional x @32
            type: int
            metadata
              Annotation
                atSign: @ @25
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @26
        returnType: void
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a x = null]) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @16
        parameters
          optionalPositional x @22
            type: dynamic
            metadata
              Annotation
                atSign: @ @19
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @20
            constantInitializer
              NullLiteral
                literal: null @26
                staticType: Null
        returnType: dynamic
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await checkLibrary('const a = null; @a int v;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
      static v @23
        metadata
          Annotation
            atSign: @ @16
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @17
        type: int
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await checkLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @22
        typeParameters
          covariant T @27
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @24
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @25
        constructors
          synthetic @-1
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    var library = await checkLibrary('''
const a = null;
class C<@a T> = D with E;
class D {}
class E {}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class alias C @22
        typeParameters
          covariant T @27
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @24
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @25
        supertype: D
        mixins
          E
        constructors
          synthetic @-1
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::D::@constructor::•
                superKeyword: super @0
      class D @48
        constructors
          synthetic @-1
      class E @59
        constructors
          synthetic @-1
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await checkLibrary('const a = null; f<@a T>() {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
    functions
      f @16
        typeParameters
          covariant T @21
            metadata
              Annotation
                atSign: @ @18
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @19
        returnType: dynamic
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await checkLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @24
        typeParameters
          unrelated T @29
            defaultType: dynamic
            metadata
              Annotation
                atSign: @ @26
                element: self::@getter::a
                name: SimpleIdentifier
                  staticElement: self::@getter::a
                  staticType: null
                  token: a @27
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
    topLevelVariables
      static const a @6
        type: dynamic
        constantInitializer
          NullLiteral
            literal: null @10
            staticType: Null
    accessors
      synthetic static get a @-1
        returnType: dynamic
''');
  }

  test_metadata_unit_topLevelVariable_first() async {
    var library = await checkLibrary(r'''
const a = 0;
@a
int x = 0;
''');
    // Check metadata without asking any other properties.
    var x = _elementOfDefiningUnit(library, ['@variable', 'x'])
        as TopLevelVariableElement;
    expect(x.metadata, hasLength(1));
    // Check details.
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const a @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
      static x @20
        metadata
          Annotation
            atSign: @ @13
            element: self::@getter::a
            name: SimpleIdentifier
              staticElement: self::@getter::a
              staticType: null
              token: a @14
        type: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_metadata_value_class_staticField() async {
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
class A {
  static const x = 0;
}
@A.x
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          static const x @25
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @29
                staticType: int
        constructors
          synthetic @-1
        accessors
          synthetic static get x @-1
            returnType: int
      class C @45
        metadata
          Annotation
            atSign: @ @34
            element: self::@class::A::@getter::x
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@class::A::@getter::x
                staticType: null
                token: x @37
              period: . @36
              prefix: SimpleIdentifier
                staticElement: self::@class::A
                staticType: null
                token: A @35
              staticElement: self::@class::A::@getter::x
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_metadata_value_enum_constant() async {
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
enum E {a, b, c}
@E.b
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @28
        metadata
          Annotation
            atSign: @ @17
            element: self::@enum::E::@getter::b
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@enum::E::@getter::b
                staticType: null
                token: b @20
              period: . @19
              prefix: SimpleIdentifier
                staticElement: self::@enum::E
                staticType: null
                token: E @18
              staticElement: self::@enum::E::@getter::b
              staticType: null
        constructors
          synthetic @-1
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const a @8
            type: E
          static const b @11
            type: E
          static const c @14
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get a @-1
            returnType: E
          synthetic static get b @-1
            returnType: E
          synthetic static get c @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
''');
  }

  test_metadata_value_extension_staticField() async {
    testFile = convertPath('/home/test/lib/test.dart');
    var library = await checkLibrary('''
extension E on int {
  static const x = 0;
}
@E.x
class C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @56
        metadata
          Annotation
            atSign: @ @45
            element: self::@extension::E::@getter::x
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: self::@extension::E::@getter::x
                staticType: null
                token: x @48
              period: . @47
              prefix: SimpleIdentifier
                staticElement: self::@extension::E
                staticType: null
                token: E @46
              staticElement: self::@extension::E::@getter::x
              staticType: null
        constructors
          synthetic @-1
    extensions
      E @10
        extendedType: int
        fields
          static const x @36
            type: int
            constantInitializer
              IntegerLiteral
                literal: 0 @40
                staticType: int
        accessors
          synthetic static get x @-1
            returnType: int
''');
  }

  test_metadata_value_prefix_extension_staticField() async {
    testFile = convertPath('/home/test/lib/test.dart');
    addLibrarySource('/home/test/lib/foo.dart', '''
extension E on int {
  static const x = 0;
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
@foo.E.x
class C {}
''');
    checkElementText(library, r'''
library
  imports
    package:test/foo.dart as foo @21
  definingUnit
    classes
      class C @41
        metadata
          Annotation
            atSign: @ @26
            constructorName: SimpleIdentifier
              staticElement: package:test/foo.dart::@extension::E::@getter::x
              staticType: null
              token: x @33
            element: package:test/foo.dart::@extension::E::@getter::x
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: package:test/foo.dart::@extension::E
                staticType: null
                token: E @31
              period: . @30
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @27
              staticElement: package:test/foo.dart::@extension::E
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_method_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @34
            documentationComment: /**\n   * Docs\n   */
            returnType: dynamic
''');
  }

  test_method_hasImplicitReturnType_false() async {
    var library = await checkLibrary('''
class C {
  int m() => 0;
}
''');
    var c = library.definingCompilationUnit.classes.single;
    var m = c.methods.single;
    expect(m.hasImplicitReturnType, isFalse);
  }

  test_method_hasImplicitReturnType_true() async {
    var library = await checkLibrary('''
class C {
  m() => 0;
}
''');
    var c = library.definingCompilationUnit.classes.single;
    var m = c.methods.single;
    expect(m.hasImplicitReturnType, isTrue);
  }

  test_method_inferred_type_nonStatic_implicit_param() async {
    var library = await checkLibrary('class C extends D { void f(value) {} }'
        ' abstract class D { void f(int value); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        constructors
          synthetic @-1
        methods
          f @25
            parameters
              requiredPositional value @27
                type: int
            returnType: void
      abstract class D @54
        constructors
          synthetic @-1
        methods
          abstract f @63
            parameters
              requiredPositional value @69
                type: int
            returnType: void
''');
  }

  test_method_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary('''
class C extends D {
  f() => null;
}
abstract class D {
  int f();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        constructors
          synthetic @-1
        methods
          f @22
            returnType: int
      abstract class D @52
        constructors
          synthetic @-1
        methods
          abstract f @62
            returnType: int
''');
  }

  test_method_type_parameter() async {
    var library = await checkLibrary('class C { T f<T, U>(U u) => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @12
            typeParameters
              covariant T @14
              covariant U @17
            parameters
              requiredPositional u @22
                type: U
            returnType: T
''');
  }

  test_method_type_parameter_in_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> {
  V f<V, W>(T t, U u, W w) => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          f @20
            typeParameters
              covariant V @22
              covariant W @25
            parameters
              requiredPositional t @30
                type: T
              requiredPositional u @35
                type: U
              requiredPositional w @40
                type: W
            returnType: V
''');
  }

  test_method_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('class C { void f<T, U>(T x(U u)) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @15
            typeParameters
              covariant T @17
              covariant U @20
            parameters
              requiredPositional x @25
                type: T Function(U)
                parameters
                  requiredPositional u @29
                    type: U
            returnType: void
''');
  }

  test_methodInvocation_implicitCall() async {
    var library = await checkLibrary(r'''
class A {
  double call() => 0.0;
}
class B {
  A a;
}
var c = new B().a();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          call @19
            returnType: double
      class B @42
        fields
          a @50
            type: A
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: A
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: A
            returnType: void
    topLevelVariables
      static c @59
        type: double
    accessors
      synthetic static get c @-1
        returnType: double
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: double
        returnType: void
''');
  }

  test_mixin() async {
    var library = await checkLibrary(r'''
class A {}
class B {}
class C {}
class D {}

mixin M<T extends num, U> on A, B implements C, D {
  T f;
  U get g => 0;
  set s(int v) {}
  int m(double v) => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @17
        constructors
          synthetic @-1
      class C @28
        constructors
          synthetic @-1
      class D @39
        constructors
          synthetic @-1
    mixins
      mixin M @51
        typeParameters
          covariant T @53
            bound: num
            defaultType: num
          covariant U @68
            defaultType: dynamic
        superclassConstraints
          A
          B
        interfaces
          C
          D
        fields
          f @101
            type: T
          synthetic g @-1
            type: U
          synthetic s @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: T
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: T
            returnType: void
          get g @112
            returnType: U
          set s @126
            parameters
              requiredPositional v @132
                type: int
            returnType: void
        methods
          m @144
            parameters
              requiredPositional v @153
                type: double
            returnType: int
''');
  }

  test_mixin_field_inferredType_final() async {
    var library = await checkLibrary('''
mixin M {
  final x = 0;
}''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        superclassConstraints
          Object
        fields
          final x @18
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
''');
  }

  test_mixin_first() async {
    var library = await checkLibrary(r'''
mixin M {}
''');

    // We intentionally ask `mixins` directly, to check that we can ask them
    // separately, without asking classes.
    var mixins = library.definingCompilationUnit.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0].name, 'M');
  }

  test_mixin_implicitObjectSuperclassConstraint() async {
    var library = await checkLibrary(r'''
mixin M {}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_mixin_inference_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary(r'''
class A<T> {}
mixin M<U> on A<U> {}
class B extends A<int> with M {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @42
        supertype: A<int*>*
        mixins
          M<int*>*
        constructors
          synthetic @-1
    mixins
      mixin M @20
        typeParameters
          covariant U @22
            defaultType: dynamic
        superclassConstraints
          A<U*>*
        constructors
          synthetic @-1
''');
  }

  test_mixin_inference_nullSafety() async {
    var library = await checkLibrary(r'''
class A<T> {}
mixin M<U> on A<U> {}
class B extends A<int> with M {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @42
        supertype: A<int>
        mixins
          M<int>
        constructors
          synthetic @-1
    mixins
      mixin M @20
        typeParameters
          covariant U @22
            defaultType: dynamic
        superclassConstraints
          A<U>
        constructors
          synthetic @-1
''');
  }

  test_mixin_inference_nullSafety2() async {
    addLibrarySource('/a.dart', r'''
class A<T> {}

mixin B<T> on A<T> {}
mixin C<T> on A<T> {}
''');
    var library = await checkLibrary(r'''
// @dart=2.8
import 'a.dart';

class D extends A<int> with B<int>, C {}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class D @37
        supertype: A<int*>*
        mixins
          B<int*>*
          C<int*>*
        constructors
          synthetic @-1
''');
  }

  test_mixin_inference_nullSafety_mixed_inOrder() async {
    addLibrarySource('/a.dart', r'''
class A<T> {}
mixin M<U> on A<U> {}
''');
    var library = await checkLibrary(r'''
// @dart = 2.8
import 'a.dart';
class B extends A<int> with M {}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    classes
      class B @38
        supertype: A<int*>*
        mixins
          M<int*>*
        constructors
          synthetic @-1
''');
  }

  @FailingTest(reason: 'Out-of-order inference is not specified yet')
  test_mixin_inference_nullSafety_mixed_outOfOrder() async {
    addLibrarySource('/a.dart', r'''
// @dart = 2.8
class A<T> {}
mixin M<U> on A<U> {}
''');
    var library = await checkLibrary(r'''
import 'a.dart';

class B extends A<int> with M {}
''');
    checkElementText(library, r'''
import 'a.dart';
class B extends A<int> with M<int> {
  synthetic B();
}
''');
  }

  test_mixin_method_namedAsConstraint() async {
    var library = await checkLibrary(r'''
class A {}
mixin B on A {
  void A() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    mixins
      mixin B @17
        superclassConstraints
          A
        constructors
          synthetic @-1
        methods
          A @33
            returnType: void
''');
  }

  test_mixin_typeParameters_variance_contravariant() async {
    var library = await checkLibrary('mixin M<in T> {}');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        typeParameters
          contravariant T @11
            defaultType: dynamic
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_mixin_typeParameters_variance_covariant() async {
    var library = await checkLibrary('mixin M<out T> {}');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        typeParameters
          covariant T @12
            defaultType: dynamic
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_mixin_typeParameters_variance_invariant() async {
    var library = await checkLibrary('mixin M<inout T> {}');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        typeParameters
          invariant T @14
            defaultType: dynamic
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_mixin_typeParameters_variance_multiple() async {
    var library = await checkLibrary('mixin M<inout T, in U, out V> {}');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        typeParameters
          invariant T @14
            defaultType: dynamic
          contravariant U @20
            defaultType: dynamic
          covariant V @27
            defaultType: dynamic
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_nameConflict_exportedAndLocal() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  imports
    c.dart
  definingUnit
    topLevelVariables
      static v @19
        type: C
    accessors
      synthetic static get v @-1
        returnType: C
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: C
        returnType: void
''');
  }

  test_nameConflict_exportedAndLocal_exported() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    addLibrarySource('/d.dart', 'export "c.dart";');
    var library = await checkLibrary('''
import 'd.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  imports
    d.dart
  definingUnit
    topLevelVariables
      static v @19
        type: C
    accessors
      synthetic static get v @-1
        returnType: C
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: C
        returnType: void
''');
  }

  test_nameConflict_exportedAndParted() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', '''
part of lib;
class C {}
''');
    addLibrarySource('/c.dart', '''
library lib;
export 'a.dart';
part 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
library
  imports
    c.dart
  definingUnit
    topLevelVariables
      static v @19
        type: C
    accessors
      synthetic static get v @-1
        returnType: C
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: C
        returnType: void
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    addLibrarySource('/a.dart', 'class A {}');
    addLibrarySource('/b.dart', 'export "/a.dart";');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
A v = null;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
    b.dart
  definingUnit
    topLevelVariables
      static v @36
        type: A
    accessors
      synthetic static get v @-1
        returnType: A
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: A
        returnType: void
''');
  }

  test_nameOffset_class_constructor() async {
    var library = await checkLibrary(r'''
class A {
  A();
  A.named();
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          @12
          named @21
            periodOffset: 20
            nameEnd: 26
''');
  }

  test_nameOffset_class_constructor_parameter() async {
    var library = await checkLibrary(r'''
class A {
  A(int a);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          @12
            parameters
              requiredPositional a @18
                type: int
''');
  }

  test_nameOffset_class_field() async {
    var library = await checkLibrary(r'''
class A {
  int foo = 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          foo @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get foo @-1
            returnType: int
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
            returnType: void
''');
  }

  test_nameOffset_class_getter() async {
    var library = await checkLibrary(r'''
class A {
  int get foo => 0;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          synthetic foo @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get foo @20
            returnType: int
''');
  }

  test_nameOffset_class_method() async {
    var library = await checkLibrary(r'''
class A {
  void foo<T>(int a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          foo @17
            typeParameters
              covariant T @21
            parameters
              requiredPositional a @28
                type: int
            returnType: void
''');
  }

  test_nameOffset_class_setter() async {
    var library = await checkLibrary(r'''
class A {
  set foo(int x) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          synthetic foo @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set foo @16
            parameters
              requiredPositional x @24
                type: int
            returnType: void
''');
  }

  test_nameOffset_class_typeParameter() async {
    var library = await checkLibrary(r'''
class A<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
''');
  }

  test_nameOffset_extension_typeParameter() async {
    var library = await checkLibrary(r'''
extension E<T> on int {}
''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      E @10
        typeParameters
          covariant T @12
        extendedType: int
''');
  }

  test_nameOffset_function_functionTypedFormal_parameter() async {
    var library = await checkLibrary(r'''
void f(void f<U>(int a)) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional f @12
            type: void Function<U>(int)
            typeParameters
              covariant U @14
            parameters
              requiredPositional a @21
                type: int
        returnType: void
''');
  }

  test_nameOffset_function_functionTypedFormal_parameter2() async {
    var library = await checkLibrary(r'''
void f({required void f<U>(int a)}) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredName f @22
            type: void Function<U>(int)
            typeParameters
              covariant U @24
            parameters
              requiredPositional a @31
                type: int
        returnType: void
''');
  }

  test_nameOffset_function_typeParameter() async {
    var library = await checkLibrary(r'''
void f<T>() {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
        returnType: void
''');
  }

  test_nameOffset_functionTypeAlias_typeParameter() async {
    var library = await checkLibrary(r'''
typedef void F<T>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        typeParameters
          unrelated T @15
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_nameOffset_genericTypeAlias_typeParameter() async {
    var library = await checkLibrary(r'''
typedef F<T> = void Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          unrelated T @10
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_nameOffset_mixin_typeParameter() async {
    var library = await checkLibrary(r'''
mixin M<T> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    mixins
      mixin M @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_nameOffset_unit_getter() async {
    var library = await checkLibrary(r'''
int get foo => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: int
    accessors
      get foo @8
        returnType: int
''');
  }

  test_nested_generic_functions_in_generic_class_with_function_typed_params() async {
    var library = await checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          g @23
            typeParameters
              covariant V @25
              covariant W @28
            returnType: void
''');
  }

  test_nested_generic_functions_in_generic_class_with_local_variables() async {
    var library = await checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          g @23
            typeParameters
              covariant V @25
              covariant W @28
            returnType: void
''');
  }

  test_nested_generic_functions_with_function_typed_param() async {
    var library = await checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
          covariant U @10
        returnType: void
''');
  }

  test_nested_generic_functions_with_local_variables() async {
    var library = await checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
          covariant U @10
        returnType: void
''');
  }

  test_new_typedef_function_notSimplyBounded_functionType_returnType() async {
    var library = await checkLibrary('''
typedef F = G Function();
typedef G = F Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
      notSimplyBounded G @34
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_new_typedef_function_notSimplyBounded_functionType_returnType_viaInterfaceType() async {
    var library = await checkLibrary('''
typedef F = List<F> Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        aliasedType: List<dynamic> Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: List<dynamic>
''');
  }

  test_new_typedef_function_notSimplyBounded_self() async {
    var library = await checkLibrary('''
typedef F<T extends F> = void Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        typeParameters
          unrelated T @10
            bound: dynamic
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_new_typedef_function_notSimplyBounded_simple_no_bounds() async {
    var library = await checkLibrary('''
typedef F<T> = void Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          unrelated T @10
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_new_typedef_function_notSimplyBounded_simple_non_generic() async {
    var library = await checkLibrary('''
typedef F = void Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_new_typedef_nonFunction_notSimplyBounded_self() async {
    var library = await checkLibrary('''
typedef F<T extends F> = List<int>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        typeParameters
          unrelated T @10
            bound: dynamic
            defaultType: dynamic
        aliasedType: List<int>
''');
  }

  test_new_typedef_nonFunction_notSimplyBounded_viaInterfaceType() async {
    var library = await checkLibrary('''
typedef F = List<F>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        aliasedType: List<dynamic>
''');
  }

  test_nonSynthetic_class_field() async {
    var library = await checkLibrary(r'''
class C {
  int foo = 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        fields
          foo @16
            type: int
            nonSynthetic: self::@class::C::@field::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@class::C
        accessors
          synthetic get foo @-1
            returnType: int
            nonSynthetic: self::@class::C::@field::foo
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
                nonSynthetic: self::@class::C::@field::foo
            returnType: void
            nonSynthetic: self::@class::C::@field::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_class_getter() async {
    var library = await checkLibrary(r'''
class C {
  int get foo => 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@class::C::@getter::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@class::C
        accessors
          get foo @20
            returnType: int
            nonSynthetic: self::@class::C::@getter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_class_setter() async {
    var library = await checkLibrary(r'''
class C {
  set foo(int value) {}
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@class::C::@setter::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@class::C
        accessors
          set foo @16
            parameters
              requiredPositional value @24
                type: int
                nonSynthetic: value@24
            returnType: void
            nonSynthetic: self::@class::C::@setter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_enum() async {
    var library = await checkLibrary(r'''
enum E {
  a, b
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
            nonSynthetic: self::@enum::E
          synthetic static const values @-1
            type: List<E>
            nonSynthetic: self::@enum::E
          static const a @11
            type: E
            nonSynthetic: self::@enum::E::@constant::a
          static const b @14
            type: E
            nonSynthetic: self::@enum::E::@constant::b
        accessors
          synthetic get index @-1
            returnType: int
            nonSynthetic: self::@enum::E
          synthetic static get values @-1
            returnType: List<E>
            nonSynthetic: self::@enum::E
          synthetic static get a @-1
            returnType: E
            nonSynthetic: self::@enum::E::@constant::a
          synthetic static get b @-1
            returnType: E
            nonSynthetic: self::@enum::E::@constant::b
        methods
          synthetic toString @-1
            returnType: String
            nonSynthetic: self::@enum::E
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_extension_getter() async {
    var library = await checkLibrary(r'''
extension E on int {
  int get foo => 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    extensions
      E @10
        extendedType: int
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@extension::E::@getter::foo
        accessors
          get foo @31
            returnType: int
            nonSynthetic: self::@extension::E::@getter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_extension_setter() async {
    var library = await checkLibrary(r'''
extension E on int {
  set foo(int value) {}
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    extensions
      E @10
        extendedType: int
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@extension::E::@setter::foo
        accessors
          set foo @27
            parameters
              requiredPositional value @35
                type: int
                nonSynthetic: value@35
            returnType: void
            nonSynthetic: self::@extension::E::@setter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_mixin_field() async {
    var library = await checkLibrary(r'''
mixin M {
  int foo = 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    mixins
      mixin M @6
        superclassConstraints
          Object
        fields
          foo @16
            type: int
            nonSynthetic: self::@mixin::M::@field::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@mixin::M
        accessors
          synthetic get foo @-1
            returnType: int
            nonSynthetic: self::@mixin::M::@field::foo
          synthetic set foo @-1
            parameters
              requiredPositional _foo @-1
                type: int
                nonSynthetic: self::@mixin::M::@field::foo
            returnType: void
            nonSynthetic: self::@mixin::M::@field::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_mixin_getter() async {
    var library = await checkLibrary(r'''
mixin M {
  int get foo => 0;
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    mixins
      mixin M @6
        superclassConstraints
          Object
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@mixin::M::@getter::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@mixin::M
        accessors
          get foo @20
            returnType: int
            nonSynthetic: self::@mixin::M::@getter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_mixin_setter() async {
    var library = await checkLibrary(r'''
mixin M {
  set foo(int value) {}
}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    mixins
      mixin M @6
        superclassConstraints
          Object
        fields
          synthetic foo @-1
            type: int
            nonSynthetic: self::@mixin::M::@setter::foo
        constructors
          synthetic @-1
            nonSynthetic: self::@mixin::M
        accessors
          set foo @16
            parameters
              requiredPositional value @24
                type: int
                nonSynthetic: value@24
            returnType: void
            nonSynthetic: self::@mixin::M::@setter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_unit_getter() async {
    var library = await checkLibrary(r'''
int get foo => 0;
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: int
        nonSynthetic: self::@getter::foo
    accessors
      get foo @8
        returnType: int
        nonSynthetic: self::@getter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_unit_getterSetter() async {
    var library = await checkLibrary(r'''
int get foo => 0;
set foo(int value) {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: int
        nonSynthetic: self::@getter::foo
    accessors
      get foo @8
        returnType: int
        nonSynthetic: self::@getter::foo
      set foo @22
        parameters
          requiredPositional value @30
            type: int
            nonSynthetic: value@30
        returnType: void
        nonSynthetic: self::@setter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_unit_setter() async {
    var library = await checkLibrary(r'''
set foo(int value) {}
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      synthetic static foo @-1
        type: int
        nonSynthetic: self::@setter::foo
    accessors
      set foo @4
        parameters
          requiredPositional value @12
            type: int
            nonSynthetic: value@12
        returnType: void
        nonSynthetic: self::@setter::foo
''',
        withNonSynthetic: true);
  }

  test_nonSynthetic_unit_variable() async {
    var library = await checkLibrary(r'''
int foo = 0;
''');
    checkElementText(
        library,
        r'''
library
  definingUnit
    topLevelVariables
      static foo @4
        type: int
        nonSynthetic: self::@variable::foo
    accessors
      synthetic static get foo @-1
        returnType: int
        nonSynthetic: self::@variable::foo
      synthetic static set foo @-1
        parameters
          requiredPositional _foo @-1
            type: int
            nonSynthetic: self::@variable::foo
        returnType: void
        nonSynthetic: self::@variable::foo
''',
        withNonSynthetic: true);
  }

  test_old_typedef_notSimplyBounded_self() async {
    var library = await checkLibrary('''
typedef void F<T extends F>();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @13
        typeParameters
          unrelated T @15
            bound: dynamic
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_old_typedef_notSimplyBounded_simple_because_non_generic() async {
    var library = await checkLibrary('''
typedef void F();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_old_typedef_notSimplyBounded_simple_no_bounds() async {
    var library = await checkLibrary('typedef void F<T>();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        typeParameters
          unrelated T @15
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_operator() async {
    var library =
        await checkLibrary('class C { C operator+(C other) => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          + @20
            parameters
              requiredPositional other @24
                type: C
            returnType: C
''');
  }

  test_operator_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator==(Object other) => false;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          == @25
            parameters
              requiredPositional other @35
                type: Object
            returnType: bool
''');
  }

  test_operator_external() async {
    var library =
        await checkLibrary('class C { external C operator+(C other); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          external + @29
            parameters
              requiredPositional other @33
                type: C
            returnType: C
''');
  }

  test_operator_greater_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator>=(C other) => false;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          >= @25
            parameters
              requiredPositional other @30
                type: C
            returnType: bool
''');
  }

  test_operator_index() async {
    var library =
        await checkLibrary('class C { bool operator[](int i) => null; }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          [] @23
            parameters
              requiredPositional i @30
                type: int
            returnType: bool
''');
  }

  test_operator_index_set() async {
    var library = await checkLibrary('''
class C {
  void operator[]=(int i, bool v) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          []= @25
            parameters
              requiredPositional i @33
                type: int
              requiredPositional v @41
                type: bool
            returnType: void
''');
  }

  test_operator_less_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator<=(C other) => false;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          <= @25
            parameters
              requiredPositional other @30
                type: C
            returnType: bool
''');
  }

  test_parameter() async {
    var library = await checkLibrary('void main(int p) {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      main @5
        parameters
          requiredPositional p @14
            type: int
        returnType: void
''');
  }

  test_parameter_covariant_explicit_named() async {
    var library = await checkLibrary('''
class A {
  void m({covariant A a}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              optionalNamed covariant a @32
                type: A
            returnType: void
''');
  }

  test_parameter_covariant_explicit_positional() async {
    var library = await checkLibrary('''
class A {
  void m([covariant A a]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              optionalPositional covariant a @32
                type: A
            returnType: void
''');
  }

  test_parameter_covariant_explicit_required() async {
    var library = await checkLibrary('''
class A {
  void m(covariant A a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              requiredPositional covariant a @31
                type: A
            returnType: void
''');
  }

  test_parameter_covariant_inherited() async {
    var library = await checkLibrary(r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          f @20
            parameters
              requiredPositional covariant t @34
                type: T
            returnType: void
      class B @48
        typeParameters
          covariant T @50
            defaultType: dynamic
        supertype: A<T>
        constructors
          synthetic @-1
        methods
          f @75
            parameters
              requiredPositional covariant t @79
                type: T
            returnType: void
''');
  }

  test_parameter_covariant_inherited_named() async {
    var library = await checkLibrary('''
class A {
  void m({covariant A a}) {}
}
class B extends A {
  void m({B a}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              optionalNamed covariant a @32
                type: A
            returnType: void
      class B @47
        supertype: A
        constructors
          synthetic @-1
        methods
          m @68
            parameters
              optionalNamed covariant a @73
                type: B
            returnType: void
''');
  }

  test_parameter_parameters() async {
    var library = await checkLibrary('class C { f(g(x, y)) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @10
            parameters
              requiredPositional g @12
                type: dynamic Function(dynamic, dynamic)
                parameters
                  requiredPositional x @14
                    type: dynamic
                  requiredPositional y @17
                    type: dynamic
            returnType: dynamic
''');
  }

  test_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('class C<A, B> { f(A g(B x)) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant A @8
            defaultType: dynamic
          covariant B @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          f @16
            parameters
              requiredPositional g @20
                type: A Function(B)
                parameters
                  requiredPositional x @24
                    type: B
            returnType: dynamic
''');
  }

  test_parameter_return_type() async {
    var library = await checkLibrary('class C { f(int g()) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @10
            parameters
              requiredPositional g @16
                type: int Function()
            returnType: dynamic
''');
  }

  test_parameter_return_type_void() async {
    var library = await checkLibrary('class C { f(void g()) {} }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          f @10
            parameters
              requiredPositional g @17
                type: void Function()
            returnType: dynamic
''');
  }

  test_parameter_typeParameters() async {
    var library = await checkLibrary(r'''
void f(T a<T, U>(U u)) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        parameters
          requiredPositional a @9
            type: T Function<T, U>(U)
            typeParameters
              covariant T @11
              covariant U @14
            parameters
              requiredPositional u @19
                type: U
        returnType: void
''');
  }

  test_parameterTypeNotInferred_constructor() async {
    // Strong mode doesn't do type inference on constructor parameters, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  C.positional([x = 1]);
  C.named({x: 1});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          positional @14
            periodOffset: 13
            nameEnd: 24
            parameters
              optionalPositional x @26
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @30
                    staticType: int
          named @39
            periodOffset: 38
            nameEnd: 44
            parameters
              optionalNamed x @46
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @49
                    staticType: int
''');
  }

  test_parameterTypeNotInferred_initializingFormal() async {
    // Strong mode doesn't do type inference on initializing formals, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  var x;
  C.positional([this.x = 1]);
  C.named({this.x: 1});
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          x @16
            type: dynamic
        constructors
          positional @23
            periodOffset: 22
            nameEnd: 33
            parameters
              optionalPositional final this.x @40
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @44
                    staticType: int
          named @53
            periodOffset: 52
            nameEnd: 58
            parameters
              optionalNamed final this.x @65
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @68
                    staticType: int
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_parameterTypeNotInferred_staticMethod() async {
    // Strong mode doesn't do type inference on parameters of static methods,
    // so it's ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  static void positional([x = 1]) {}
  static void named({x: 1}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
        methods
          static positional @24
            parameters
              optionalPositional x @36
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @40
                    staticType: int
            returnType: void
          static named @61
            parameters
              optionalNamed x @68
                type: dynamic
                constantInitializer
                  IntegerLiteral
                    literal: 1 @71
                    staticType: int
            returnType: void
''');
  }

  test_parameterTypeNotInferred_topLevelFunction() async {
    // Strong mode doesn't do type inference on parameters of top level
    // functions, so it's ok that we don't store inferred type info for them in
    // summaries.
    var library = await checkLibrary('''
void positional([x = 1]) {}
void named({x: 1}) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      positional @5
        parameters
          optionalPositional x @17
            type: dynamic
            constantInitializer
              IntegerLiteral
                literal: 1 @21
                staticType: int
        returnType: void
      named @33
        parameters
          optionalNamed x @40
            type: dynamic
            constantInitializer
              IntegerLiteral
                literal: 1 @43
                staticType: int
        returnType: void
''');
  }

  test_part_emptyUri() async {
    var library = await checkLibrary(r'''
part '';
class B extends A {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class B @15
        constructors
          synthetic @-1
  parts

      classes
        class B @15
          constructors
            synthetic @-1
''');
  }

  test_part_uri() async {
    var library = await checkLibrary('''
part 'foo.dart';
''');
    expect(library.parts[0].uri, 'foo.dart');
  }

  test_parts() async {
    addSource('/a.dart', 'part of my.lib;');
    addSource('/b.dart', 'part of my.lib;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
  parts
    a.dart
    b.dart
''');
  }

  test_parts_invalidUri() async {
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary('library my.lib; part "foo/";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
  parts
    foo/
''');
  }

  test_parts_invalidUri_nullStringValue() async {
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary(r'''
library my.lib;
part "${foo}/bar.dart";
''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
''');
  }

  test_propagated_type_refers_to_closure() async {
    var library = await checkLibrary('''
void f() {
  var x = () => 0;
  var y = x;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        returnType: void
''');
  }

  test_setter_covariant() async {
    var library =
        await checkLibrary('class C { void set x(covariant int value); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @19
            parameters
              requiredPositional covariant value @35
                type: int
            returnType: void
''');
  }

  test_setter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: dynamic
    accessors
      set x @69
        documentationComment: /**\n * Docs\n */
        parameters
          requiredPositional value @71
            type: dynamic
        returnType: void
''');
  }

  test_setter_external() async {
    var library = await checkLibrary('external void set x(int value);');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      external set x @18
        parameters
          requiredPositional value @24
            type: int
        returnType: void
''');
  }

  test_setter_inferred_type_conflictingInheritance() async {
    var library = await checkLibrary('''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(p) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          t @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get t @-1
            returnType: int
          synthetic set t @-1
            parameters
              requiredPositional _t @-1
                type: int
            returnType: void
      class B @27
        supertype: A
        fields
          t @50
            type: double
        constructors
          synthetic @-1
        accessors
          synthetic get t @-1
            returnType: double
          synthetic set t @-1
            parameters
              requiredPositional _t @-1
                type: double
            returnType: void
      class C @61
        supertype: A
        interfaces
          B
        constructors
          synthetic @-1
      class D @96
        supertype: C
        fields
          synthetic t @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set t @121
            parameters
              requiredPositional p @123
                type: dynamic
            returnType: void
''');
  }

  test_setter_inferred_type_nonStatic_implicit_param() async {
    var library =
        await checkLibrary('class C extends D { void set f(value) {} }'
            ' abstract class D { void set f(int value); }');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        supertype: D
        fields
          synthetic f @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set f @29
            parameters
              requiredPositional value @31
                type: int
            returnType: void
      abstract class D @58
        fields
          synthetic f @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set f @71
            parameters
              requiredPositional value @77
                type: int
            returnType: void
''');
  }

  test_setter_inferred_type_static_implicit_return() async {
    var library = await checkLibrary('''
class C {
  static set f(int value) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic static f @-1
            type: int
        constructors
          synthetic @-1
        accessors
          static set f @23
            parameters
              requiredPositional value @29
                type: int
            returnType: void
''');
  }

  test_setter_inferred_type_top_level_implicit_return() async {
    var library = await checkLibrary('set f(int value) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static f @-1
        type: int
    accessors
      set f @4
        parameters
          requiredPositional value @10
            type: int
        returnType: void
''');
  }

  test_setters() async {
    var library =
        await checkLibrary('void set x(int value) {} set y(value) {}');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
      synthetic static y @-1
        type: dynamic
    accessors
      set x @9
        parameters
          requiredPositional value @15
            type: int
        returnType: void
      set y @29
        parameters
          requiredPositional value @31
            type: dynamic
        returnType: void
''');
  }

  test_syntheticFunctionType_genericClosure() async {
    var library = await checkLibrary('''
final v = f() ? <T>(T t) => 0 : <T>(T t) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final v @6
        type: int Function<T>(T)
    accessors
      synthetic static get v @-1
        returnType: int Function<T>(T)
    functions
      f @52
        returnType: bool
''');
  }

  test_syntheticFunctionType_genericClosure_inGenericFunction() async {
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  final v = b ? <V>(T t, U u, V v) => 0 : <V>(T t, U u, V v) => 1;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
          covariant U @10
        parameters
          requiredPositional b @18
            type: bool
        returnType: void
''');
  }

  test_syntheticFunctionType_inGenericClass() async {
    var library = await checkLibrary('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        fields
          v @22
            type: int Function(T, U)
        constructors
          synthetic @-1
        accessors
          synthetic get v @-1
            returnType: int Function(T, U)
          synthetic set v @-1
            parameters
              requiredPositional _v @-1
                type: int Function(T, U)
            returnType: void
    functions
      f @74
        returnType: bool
''');
  }

  test_syntheticFunctionType_inGenericFunction() async {
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  var v = b ? (T t, U u) => 0 : (T t, U u) => 1;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @5
        typeParameters
          covariant T @7
          covariant U @10
        parameters
          requiredPositional b @18
            type: bool
        returnType: void
''');
  }

  test_syntheticFunctionType_noArguments() async {
    var library = await checkLibrary('''
final v = f() ? () => 0 : () => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final v @6
        type: int Function()
    accessors
      synthetic static get v @-1
        returnType: int Function()
    functions
      f @40
        returnType: bool
''');
  }

  test_syntheticFunctionType_withArguments() async {
    var library = await checkLibrary('''
final v = f() ? (int x, String y) => 0 : (int x, String y) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final v @6
        type: int Function(int, String)
    accessors
      synthetic static get v @-1
        returnType: int Function(int, String)
    functions
      f @70
        returnType: bool
''');
  }

  test_top_level_variable_external() async {
    var library = await checkLibrary('''
external int i;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static i @13
        type: int
    accessors
      synthetic static get i @-1
        returnType: int
      synthetic static set i @-1
        parameters
          requiredPositional _i @-1
            type: int
        returnType: void
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await checkLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static m @22
        type: Map<dynamic, dynamic>
    accessors
      synthetic static get m @-1
        returnType: Map<dynamic, dynamic>
      synthetic static set m @-1
        parameters
          requiredPositional _m @-1
            type: Map<dynamic, dynamic>
        returnType: void
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await checkLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static m @18
        type: Map<dynamic, int>
    accessors
      synthetic static get m @-1
        returnType: Map<dynamic, int>
      synthetic static set m @-1
        parameters
          requiredPositional _m @-1
            type: Map<dynamic, int>
        returnType: void
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await checkLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static m @21
        type: Map<String, dynamic>
    accessors
      synthetic static get m @-1
        returnType: Map<String, dynamic>
      synthetic static set m @-1
        parameters
          requiredPositional _m @-1
            type: Map<String, dynamic>
        returnType: void
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await checkLibrary('Map<String, int> m;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static m @17
        type: Map<String, int>
    accessors
      synthetic static get m @-1
        returnType: Map<String, int>
      synthetic static set m @-1
        parameters
          requiredPositional _m @-1
            type: Map<String, int>
        returnType: void
''');
  }

  test_type_arguments_implicit() async {
    var library = await checkLibrary('Map m;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static m @4
        type: Map<dynamic, dynamic>
    accessors
      synthetic static get m @-1
        returnType: Map<dynamic, dynamic>
      synthetic static set m @-1
        parameters
          requiredPositional _m @-1
            type: Map<dynamic, dynamic>
        returnType: void
''');
  }

  test_type_dynamic() async {
    var library = await checkLibrary('dynamic d;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static d @8
        type: dynamic
    accessors
      synthetic static get d @-1
        returnType: dynamic
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: dynamic
        returnType: void
''');
  }

  test_type_inference_assignmentExpression_references_onTopLevelVariable() async {
    var library = await checkLibrary('''
var a = () {
  b += 0;
  return 0;
};
var b = 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: int Function()
      static b @42
        type: int
    accessors
      synthetic static get a @-1
        returnType: int Function()
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: int Function()
        returnType: void
      synthetic static get b @-1
        returnType: int
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: int
        returnType: void
''');
  }

  test_type_inference_based_on_loadLibrary() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary('''
import 'a.dart' deferred as a;
var x = a.loadLibrary;
''');
    checkElementText(library, r'''
library
  imports
    a.dart deferred as a @28
  definingUnit
    topLevelVariables
      static x @35
        type: Future<dynamic> Function()
    accessors
      synthetic static get x @-1
        returnType: Future<dynamic> Function()
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: Future<dynamic> Function()
        returnType: void
''');
  }

  test_type_inference_closure_with_function_typed_parameter() async {
    var library = await checkLibrary('''
var x = (int f(String x)) => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: int Function(int Function(String))
    accessors
      synthetic static get x @-1
        returnType: int Function(int Function(String))
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int Function(int Function(String))
        returnType: void
''');
  }

  test_type_inference_closure_with_function_typed_parameter_new() async {
    var library = await checkLibrary('''
var x = (int Function(String) f) => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: int Function(int Function(String))
    accessors
      synthetic static get x @-1
        returnType: int Function(int Function(String))
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int Function(int Function(String))
        returnType: void
''');
  }

  test_type_inference_depends_on_exported_variable() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'var x = 0;');
    var library = await checkLibrary('''
import 'a.dart';
var y = x;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static y @21
        type: int
    accessors
      synthetic static get y @-1
        returnType: int
      synthetic static set y @-1
        parameters
          requiredPositional _y @-1
            type: int
        returnType: void
''');
  }

  test_type_inference_field_depends_onFieldFormal() async {
    var library = await checkLibrary('''
class A<T> {
  T value;

  A(this.value);
}

class B {
  var a = new A('');
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          value @17
            type: T
        constructors
          @27
            parameters
              requiredPositional final this.value @34
                type: T
        accessors
          synthetic get value @-1
            returnType: T
          synthetic set value @-1
            parameters
              requiredPositional _value @-1
                type: T
            returnType: void
      class B @51
        fields
          a @61
            type: A<String>
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: A<String>
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: A<String>
            returnType: void
''');
  }

  test_type_inference_field_depends_onFieldFormal_withMixinApp() async {
    var library = await checkLibrary('''
class A<T> {
  T value;

  A(this.value);
}

class B<T> = A<T> with M;

class C {
  var a = new B(42);
}

mixin M {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          value @17
            type: T
        constructors
          @27
            parameters
              requiredPositional final this.value @34
                type: T
        accessors
          synthetic get value @-1
            returnType: T
          synthetic set value @-1
            parameters
              requiredPositional _value @-1
                type: T
            returnType: void
      class alias B @51
        typeParameters
          covariant T @53
            defaultType: dynamic
        supertype: A<T>
        mixins
          M
        constructors
          synthetic @-1
            parameters
              requiredPositional final value @-1
                type: T
            constantInitializers
              SuperConstructorInvocation
                argumentList: ArgumentList
                  arguments
                    SimpleIdentifier
                      staticElement: value@-1
                      staticType: T
                      token: value @-1
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: self::@class::A::@constructor::•
                superKeyword: super @0
      class C @78
        fields
          a @88
            type: B<int>
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: B<int>
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: B<int>
            returnType: void
    mixins
      mixin M @112
        superclassConstraints
          Object
        constructors
          synthetic @-1
''');
  }

  test_type_inference_fieldFormal_depends_onField() async {
    var library = await checkLibrary('''
class A<T> {
  var f = 0;
  A(this.f);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          f @19
            type: int
        constructors
          @28
            parameters
              requiredPositional final this.f @35
                type: int
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
''');
  }

  test_type_inference_instanceCreation_notGeneric() async {
    var library = await checkLibrary('''
class A {
  A(_);
}
var a = A(() => b);
var b = A(() => a);
''');
    // There is no cycle with `a` and `b`, because `A` is not generic,
    // so the type of `new A(...)` does not depend on its arguments.
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          @12
            parameters
              requiredPositional _ @14
                type: dynamic
    topLevelVariables
      static a @24
        type: A
      static b @44
        type: A
    accessors
      synthetic static get a @-1
        returnType: A
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: A
        returnType: void
      synthetic static get b @-1
        returnType: A
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: A
        returnType: void
''');
  }

  test_type_inference_multiplyDefinedElement() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'class C {}');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
var v = C;
''');
    checkElementText(library, r'''
library
  imports
    a.dart
    b.dart
  definingUnit
    topLevelVariables
      static v @38
        type: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: dynamic
        returnType: void
''');
  }

  test_type_inference_nested_function() async {
    var library = await checkLibrary('''
var x = (t) => (u) => t + u;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: dynamic Function(dynamic) Function(dynamic)
    accessors
      synthetic static get x @-1
        returnType: dynamic Function(dynamic) Function(dynamic)
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: dynamic Function(dynamic) Function(dynamic)
        returnType: void
''');
  }

  test_type_inference_nested_function_with_parameter_types() async {
    var library = await checkLibrary('''
var x = (int t) => (int u) => t + u;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: int Function(int) Function(int)
    accessors
      synthetic static get x @-1
        returnType: int Function(int) Function(int)
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int Function(int) Function(int)
        returnType: void
''');
  }

  test_type_inference_of_closure_with_default_value() async {
    var library = await checkLibrary('''
var x = ([y: 0]) => y;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: dynamic Function([dynamic])
    accessors
      synthetic static get x @-1
        returnType: dynamic Function([dynamic])
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: dynamic Function([dynamic])
        returnType: void
''');
  }

  test_type_inference_topVariable_depends_onFieldFormal() async {
    var library = await checkLibrary('''
class A {}

class B extends A {}

class C<T extends A> {
  final T f;
  const C(this.f);
}

final b = B();
final c = C(b);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
      class B @18
        supertype: A
        constructors
          synthetic @-1
      class C @40
        typeParameters
          covariant T @42
            bound: A
            defaultType: A
        fields
          final f @67
            type: T
        constructors
          const @78
            parameters
              requiredPositional final this.f @85
                type: T
        accessors
          synthetic get f @-1
            returnType: T
    topLevelVariables
      static final b @98
        type: B
      static final c @113
        type: C<B>
    accessors
      synthetic static get b @-1
        returnType: B
      synthetic static get c @-1
        returnType: C<B>
''');
  }

  test_type_inference_using_extension_getter() async {
    var library = await checkLibrary('''
extension on String {
  int get foo => 0;
}
var v = 'a'.foo;
''');
    checkElementText(library, r'''
library
  definingUnit
    extensions
      @-1
        extendedType: String
        fields
          synthetic foo @-1
            type: int
        accessors
          get foo @32
            returnType: int
    topLevelVariables
      static v @48
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_type_invalid_topLevelVariableElement_asType() async {
    var library = await checkLibrary('''
class C<T extends V> {}
typedef V F(V p);
V f(V p) {}
V V2 = null;
int V = 0;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            bound: dynamic
            defaultType: dynamic
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased F @34
        aliasedType: dynamic Function(dynamic)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional p @38
              type: dynamic
          returnType: dynamic
    topLevelVariables
      static V2 @56
        type: dynamic
      static V @71
        type: int
    accessors
      synthetic static get V2 @-1
        returnType: dynamic
      synthetic static set V2 @-1
        parameters
          requiredPositional _V2 @-1
            type: dynamic
        returnType: void
      synthetic static get V @-1
        returnType: int
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: int
        returnType: void
    functions
      f @44
        parameters
          requiredPositional p @48
            type: dynamic
        returnType: dynamic
''');
  }

  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    var library = await checkLibrary('''
var V;
static List<V> V2;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static V @4
        type: dynamic
      static V2 @22
        type: List<dynamic>
    accessors
      synthetic static get V @-1
        returnType: dynamic
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: dynamic
        returnType: void
      synthetic static get V2 @-1
        returnType: List<dynamic>
      synthetic static set V2 @-1
        parameters
          requiredPositional _V2 @-1
            type: List<dynamic>
        returnType: void
''');
  }

  test_type_invalid_typeParameter_asPrefix() async {
    var library = await checkLibrary('''
class C<T> {
  m(T.K p) {}
}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @15
            parameters
              requiredPositional p @21
                type: dynamic
            returnType: dynamic
''');
  }

  test_type_invalid_unresolvedPrefix() async {
    var library = await checkLibrary('''
p.C v;
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: dynamic
    accessors
      synthetic static get v @-1
        returnType: dynamic
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: dynamic
        returnType: void
''');
  }

  test_type_never_disableNnbd() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('Never d;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static d @6
        type: Null*
    accessors
      synthetic static get d @-1
        returnType: Null*
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: Null*
        returnType: void
''');
  }

  test_type_never_enableNnbd() async {
    var library = await checkLibrary('Never d;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static d @6
        type: Never
    accessors
      synthetic static get d @-1
        returnType: Never
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: Never
        returnType: void
''');
  }

  test_type_param_ref_nullability_none() async {
    var library = await checkLibrary('''
class C<T> {
  T t;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          t @17
            type: T
        constructors
          synthetic @-1
        accessors
          synthetic get t @-1
            returnType: T
          synthetic set t @-1
            parameters
              requiredPositional _t @-1
                type: T
            returnType: void
''');
  }

  test_type_param_ref_nullability_question() async {
    var library = await checkLibrary('''
class C<T> {
  T? t;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          t @18
            type: T?
        constructors
          synthetic @-1
        accessors
          synthetic get t @-1
            returnType: T?
          synthetic set t @-1
            parameters
              requiredPositional _t @-1
                type: T?
            returnType: void
''');
  }

  test_type_param_ref_nullability_star() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('''
class C<T> {
  T t;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        fields
          t @17
            type: T*
        constructors
          synthetic @-1
        accessors
          synthetic get t @-1
            returnType: T*
          synthetic set t @-1
            parameters
              requiredPositional _t @-1
                type: T*
            returnType: void
''');
  }

  test_type_reference_lib_to_lib() async {
    var library = await checkLibrary('''
class C {}
enum E { v }
typedef F();
C c;
E e;
F f;''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    enums
      enum E @16
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @20
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    typeAliases
      functionTypeAliasBased F @32
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
    topLevelVariables
      static c @39
        type: C
      static e @44
        type: E
      static f @49
        type: dynamic Function()
          aliasElement: self::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: self::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: self::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_lib_to_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library =
        await checkLibrary('library l; part "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  definingUnit
    topLevelVariables
      static c @28
        type: C
      static e @33
        type: E
      static f @38
        type: dynamic Function()
          aliasElement: self::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: self::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: self::@typeAlias::F
        returnType: void
  parts
    a.dart
      classes
        class C @17
          constructors
            synthetic @-1
      enums
        enum E @27
          interfaces
            Enum
          fields
            synthetic final index @-1
              type: int
            synthetic static const values @-1
              type: List<E>
            static const v @31
              type: E
          accessors
            synthetic get index @-1
              returnType: int
            synthetic static get values @-1
              returnType: List<E>
            synthetic static get v @-1
              returnType: E
          methods
            synthetic toString @-1
              returnType: String
      typeAliases
        functionTypeAliasBased F @43
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
''');
  }

  test_type_reference_part_to_lib() async {
    addSource('/a.dart', 'part of l; C c; E e; F f;');
    var library = await checkLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  definingUnit
    classes
      class C @32
        constructors
          synthetic @-1
    enums
      enum E @42
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @46
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    typeAliases
      functionTypeAliasBased F @58
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
  parts
    a.dart
      topLevelVariables
        static c @13
          type: C
        static e @18
          type: E
        static f @23
          type: dynamic Function()
            aliasElement: self::@typeAlias::F
      accessors
        synthetic static get c @-1
          returnType: C
        synthetic static set c @-1
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          returnType: E
        synthetic static set e @-1
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          returnType: dynamic Function()
            aliasElement: self::@typeAlias::F
        synthetic static set f @-1
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                aliasElement: self::@typeAlias::F
          returnType: void
''');
  }

  test_type_reference_part_to_other_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    addSource('/b.dart', 'part of l; C c; E e; F f;');
    var library =
        await checkLibrary('library l; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  definingUnit
  parts
    a.dart
      classes
        class C @17
          constructors
            synthetic @-1
      enums
        enum E @27
          interfaces
            Enum
          fields
            synthetic final index @-1
              type: int
            synthetic static const values @-1
              type: List<E>
            static const v @31
              type: E
          accessors
            synthetic get index @-1
              returnType: int
            synthetic static get values @-1
              returnType: List<E>
            synthetic static get v @-1
              returnType: E
          methods
            synthetic toString @-1
              returnType: String
      typeAliases
        functionTypeAliasBased F @43
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
    b.dart
      topLevelVariables
        static c @13
          type: C
        static e @18
          type: E
        static f @23
          type: dynamic Function()
            aliasElement: self::@typeAlias::F
      accessors
        synthetic static get c @-1
          returnType: C
        synthetic static set c @-1
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          returnType: E
        synthetic static set e @-1
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          returnType: dynamic Function()
            aliasElement: self::@typeAlias::F
        synthetic static set f @-1
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                aliasElement: self::@typeAlias::F
          returnType: void
''');
  }

  test_type_reference_part_to_part() async {
    addSource('/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    var library = await checkLibrary('library l; part "a.dart";');
    checkElementText(library, r'''
library
  name: l
  nameOffset: 8
  definingUnit
  parts
    a.dart
      classes
        class C @17
          constructors
            synthetic @-1
      enums
        enum E @27
          interfaces
            Enum
          fields
            synthetic final index @-1
              type: int
            synthetic static const values @-1
              type: List<E>
            static const v @31
              type: E
          accessors
            synthetic get index @-1
              returnType: int
            synthetic static get values @-1
              returnType: List<E>
            synthetic static get v @-1
              returnType: E
          methods
            synthetic toString @-1
              returnType: String
      typeAliases
        functionTypeAliasBased F @43
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
      topLevelVariables
        static c @50
          type: C
        static e @55
          type: E
        static f @60
          type: dynamic Function()
            aliasElement: self::@typeAlias::F
      accessors
        synthetic static get c @-1
          returnType: C
        synthetic static set c @-1
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get e @-1
          returnType: E
        synthetic static set e @-1
          parameters
            requiredPositional _e @-1
              type: E
          returnType: void
        synthetic static get f @-1
          returnType: dynamic Function()
            aliasElement: self::@typeAlias::F
        synthetic static set f @-1
          parameters
            requiredPositional _f @-1
              type: dynamic Function()
                aliasElement: self::@typeAlias::F
          returnType: void
''');
  }

  test_type_reference_to_class() async {
    var library = await checkLibrary('class C {} C c;');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        constructors
          synthetic @-1
    topLevelVariables
      static c @13
        type: C
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
''');
  }

  test_type_reference_to_class_with_type_arguments() async {
    var library = await checkLibrary('class C<T, U> {} C<int, String> c;');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
    topLevelVariables
      static c @32
        type: C<int, String>
    accessors
      synthetic static get c @-1
        returnType: C<int, String>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<int, String>
        returnType: void
''');
  }

  test_type_reference_to_class_with_type_arguments_implicit() async {
    var library = await checkLibrary('class C<T, U> {} C c;');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
          covariant U @11
            defaultType: dynamic
        constructors
          synthetic @-1
    topLevelVariables
      static c @19
        type: C<dynamic, dynamic>
    accessors
      synthetic static get c @-1
        returnType: C<dynamic, dynamic>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<dynamic, dynamic>
        returnType: void
''');
  }

  test_type_reference_to_enum() async {
    var library = await checkLibrary('enum E { v } E e;');
    checkElementText(library, r'''
library
  definingUnit
    enums
      enum E @5
        interfaces
          Enum
        fields
          synthetic final index @-1
            type: int
          synthetic static const values @-1
            type: List<E>
          static const v @9
            type: E
        accessors
          synthetic get index @-1
            returnType: int
          synthetic static get values @-1
            returnType: List<E>
          synthetic static get v @-1
            returnType: E
        methods
          synthetic toString @-1
            returnType: String
    topLevelVariables
      static e @15
        type: E
    accessors
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
''');
  }

  test_type_reference_to_import() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @19
        type: C
      static e @24
        type: E
      static f @29
        type: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: a.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @19
        type: C
      static e @24
        type: E
      static f @29
        type: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: b.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_export_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'export "c.dart";');
    addLibrarySource('/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @19
        type: C
      static e @24
        type: E
      static f @29
        type: dynamic Function()
          aliasElement: c.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: c.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: c.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_export_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'export "../c/c.dart";');
    addLibrarySource('/a/c/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @21
        type: C
      static e @26
        type: E
      static f @31
        type: dynamic Function()
          aliasElement: c.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: c.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: c.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @21
        type: C
      static e @26
        type: E
      static f @31
        type: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: b.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_part() async {
    addLibrarySource('/a.dart', 'library l; part "b.dart";');
    addSource('/b.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @19
        type: C
      static e @24
        type: E
      static f @29
        type: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: a.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_part2() async {
    addLibrarySource('/a.dart', 'library l; part "p1.dart"; part "p2.dart";');
    addSource('/p1.dart', 'part of l; class C1 {}');
    addSource('/p2.dart', 'part of l; class C2 {}');
    var library = await checkLibrary('import "a.dart"; C1 c1; C2 c2;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c1 @20
        type: C1
      static c2 @27
        type: C2
    accessors
      synthetic static get c1 @-1
        returnType: C1
      synthetic static set c1 @-1
        parameters
          requiredPositional _c1 @-1
            type: C1
        returnType: void
      synthetic static get c2 @-1
        returnType: C2
      synthetic static set c2 @-1
        parameters
          requiredPositional _c2 @-1
            type: C2
        returnType: void
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    addLibrarySource('/a/b.dart', 'library l; part "c.dart";');
    addSource('/a/c.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/b.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    b.dart
  definingUnit
    topLevelVariables
      static c @21
        type: C
      static e @26
        type: E
      static f @31
        type: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: b.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: b.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_import_relative() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static c @19
        type: C
      static e @24
        type: E
      static f @29
        type: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get e @-1
        returnType: E
      synthetic static set e @-1
        parameters
          requiredPositional _e @-1
            type: E
        returnType: void
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: a.dart::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: a.dart::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_typedef() async {
    var library = await checkLibrary('typedef F(); F f;');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
    topLevelVariables
      static f @15
        type: dynamic Function()
          aliasElement: self::@typeAlias::F
    accessors
      synthetic static get f @-1
        returnType: dynamic Function()
          aliasElement: self::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function()
              aliasElement: self::@typeAlias::F
        returnType: void
''');
  }

  test_type_reference_to_typedef_with_type_arguments() async {
    var library =
        await checkLibrary('typedef U F<T, U>(T t); F<int, String> f;');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          contravariant T @12
            defaultType: dynamic
          covariant U @15
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @20
              type: T
          returnType: U
    topLevelVariables
      static f @39
        type: String Function(int)
          aliasElement: self::@typeAlias::F
          aliasArguments
            int
            String
    accessors
      synthetic static get f @-1
        returnType: String Function(int)
          aliasElement: self::@typeAlias::F
          aliasArguments
            int
            String
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: String Function(int)
              aliasElement: self::@typeAlias::F
              aliasArguments
                int
                String
        returnType: void
''');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    var library = await checkLibrary('typedef U F<T, U>(T t); F f;');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          contravariant T @12
            defaultType: dynamic
          covariant U @15
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @20
              type: T
          returnType: U
    topLevelVariables
      static f @26
        type: dynamic Function(dynamic)
          aliasElement: self::@typeAlias::F
          aliasArguments
            dynamic
            dynamic
    accessors
      synthetic static get f @-1
        returnType: dynamic Function(dynamic)
          aliasElement: self::@typeAlias::F
          aliasArguments
            dynamic
            dynamic
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: dynamic Function(dynamic)
              aliasElement: self::@typeAlias::F
              aliasArguments
                dynamic
                dynamic
        returnType: void
''');
  }

  test_type_unresolved() async {
    var library = await checkLibrary('C c;', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static c @2
        type: dynamic
    accessors
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await checkLibrary('import "dart:core" as core; core.C c;',
        allowErrors: true);
    checkElementText(library, r'''
library
  imports
    dart:core as core @22
  definingUnit
    topLevelVariables
      static c @35
        type: dynamic
    accessors
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
''');
  }

  test_typeAlias_parameter_typeParameters() async {
    var library = await checkLibrary(r'''
typedef void F(T a<T, U>(U u));
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        aliasedType: void Function(T Function<T, U>(U))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional a @17
              type: T Function<T, U>(U)
              typeParameters
                covariant T @19
                covariant U @22
              parameters
                requiredPositional u @27
                  type: U
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_function_contravariant() async {
    var library = await checkLibrary(r'''
typedef F<T> = void Function(T);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          contravariant T @10
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_function_contravariant2() async {
    var library = await checkLibrary(r'''
typedef F1<T> = void Function(T);
typedef F2<T> = F1<T> Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F1 @8
        typeParameters
          contravariant T @11
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: void
      F2 @42
        typeParameters
          contravariant T @45
            defaultType: dynamic
        aliasedType: void Function(T) Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void Function(T)
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant() async {
    var library = await checkLibrary(r'''
typedef F<T> = T Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant2() async {
    var library = await checkLibrary(r'''
typedef F<T> = List<T> Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: List<T> Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: List<T>
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant3() async {
    var library = await checkLibrary(r'''
typedef F1<T> = T Function();
typedef F2<T> = F1<T> Function();
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F1 @8
        typeParameters
          covariant T @11
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
      F2 @38
        typeParameters
          covariant T @41
            defaultType: dynamic
        aliasedType: T Function() Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T Function()
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant4() async {
    var library = await checkLibrary(r'''
typedef F1<T> = void Function(T);
typedef F2<T> = void Function(F1<T>);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F1 @8
        typeParameters
          contravariant T @11
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: void
      F2 @42
        typeParameters
          covariant T @45
            defaultType: dynamic
        aliasedType: void Function(void Function(T))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: void Function(T)
                aliasElement: self::@typeAlias::F1
                aliasArguments
                  T
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_function_invalid() async {
    var library = await checkLibrary(r'''
class A {}
typedef F<T> = void Function(A<int>);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    typeAliases
      F @19
        typeParameters
          unrelated T @21
            defaultType: dynamic
        aliasedType: void Function(A)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: A
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_function_invalid2() async {
    var library = await checkLibrary(r'''
typedef F = void Function();
typedef G<T> = void Function(F<int>);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
      G @37
        typeParameters
          unrelated T @39
            defaultType: dynamic
        aliasedType: void Function(void Function())
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: void Function()
                aliasElement: self::@typeAlias::F
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_function_invariant() async {
    var library = await checkLibrary(r'''
typedef F<T> = T Function(T);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          invariant T @10
            defaultType: dynamic
        aliasedType: T Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: T
''');
  }

  test_typeAlias_typeParameters_variance_function_invariant2() async {
    var library = await checkLibrary(r'''
typedef F1<T> = T Function();
typedef F2<T> = F1<T> Function(T);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F1 @8
        typeParameters
          covariant T @11
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
      F2 @38
        typeParameters
          invariant T @41
            defaultType: dynamic
        aliasedType: T Function() Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: T Function()
            aliasElement: self::@typeAlias::F1
            aliasArguments
              T
''');
  }

  test_typeAlias_typeParameters_variance_function_unrelated() async {
    var library = await checkLibrary(r'''
typedef F<T> = void Function(int);
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          unrelated T @10
            defaultType: dynamic
        aliasedType: void Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: int
          returnType: void
''');
  }

  test_typeAlias_typeParameters_variance_interface_contravariant() async {
    var library = await checkLibrary(r'''
typedef A<T> = List<void Function(T)>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          contravariant T @10
            defaultType: dynamic
        aliasedType: List<void Function(T)>
''');
  }

  test_typeAlias_typeParameters_variance_interface_contravariant2() async {
    var library = await checkLibrary(r'''
typedef A<T> = void Function(T);
typedef B<T> = List<A<T>>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          contravariant T @10
            defaultType: dynamic
        aliasedType: void Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: T
          returnType: void
      B @41
        typeParameters
          contravariant T @43
            defaultType: dynamic
        aliasedType: List<void Function(T)>
''');
  }

  test_typeAlias_typeParameters_variance_interface_covariant() async {
    var library = await checkLibrary(r'''
typedef A<T> = List<T>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: List<T>
''');
  }

  test_typeAlias_typeParameters_variance_interface_covariant2() async {
    var library = await checkLibrary(r'''
typedef A<T> = Map<int, T>;
typedef B<T> = List<A<T>>;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: Map<int, T>
      B @36
        typeParameters
          covariant T @38
            defaultType: dynamic
        aliasedType: List<Map<int, T>>
''');
  }

  test_typedef_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @68
        documentationComment: /**\n * Docs\n */
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_typedef_generic() async {
    var library = await checkLibrary(
        'typedef F<T> = int Function<S>(List<S> list, num Function<A>(A), T);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        typeParameters
          contravariant T @10
            defaultType: dynamic
        aliasedType: int Function<S>(List<S>, num Function<A>(A), T)
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant S @28
          parameters
            requiredPositional list @39
              type: List<S>
            requiredPositional @-1
              type: num Function<A>(A)
            requiredPositional @-1
              type: T
          returnType: int
''');
  }

  test_typedef_generic_asFieldType() async {
    var library = await checkLibrary(r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  Foo<int> f;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @43
        fields
          f @58
            type: int Function<T>(T)
              aliasElement: self::@typeAlias::Foo
              aliasArguments
                int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int Function<T>(T)
              aliasElement: self::@typeAlias::Foo
              aliasArguments
                int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int Function<T>(T)
                  aliasElement: self::@typeAlias::Foo
                  aliasArguments
                    int
            returnType: void
    typeAliases
      Foo @8
        typeParameters
          covariant S @12
            defaultType: dynamic
        aliasedType: S Function<T>(T)
        aliasedElement: GenericFunctionTypeElement
          typeParameters
            covariant T @28
          parameters
            requiredPositional x @33
              type: T
          returnType: S
''');
  }

  test_typedef_generic_invalid() async {
    var library = await checkLibrary('''
typedef F = int;
F f;
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      F @8
        aliasedType: int
    topLevelVariables
      static f @19
        type: int
          aliasElement: self::@typeAlias::F
    accessors
      synthetic static get f @-1
        returnType: int
          aliasElement: self::@typeAlias::F
      synthetic static set f @-1
        parameters
          requiredPositional _f @-1
            type: int
              aliasElement: self::@typeAlias::F
        returnType: void
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type dynamic is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_dynamic() async {
    var library = await checkLibrary(r'''
typedef A = dynamic;
void f(A a) {}
''');

    checkElementText(library, r'''
typedef A = dynamic;
void f(dynamic<aliasElement: self::@typeAlias::A> a) {}
''');
  }

  test_typedef_nonFunction_aliasElement_functionType() async {
    var library = await checkLibrary(r'''
typedef A1 = void Function();
typedef A2<R> = R Function();
void f1(A1 a) {}
void f2(A2<int> a) {}
''');

    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A1 @8
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
      A2 @38
        typeParameters
          covariant R @41
            defaultType: dynamic
        aliasedType: R Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: R
    functions
      f1 @65
        parameters
          requiredPositional a @71
            type: void Function()
              aliasElement: self::@typeAlias::A1
        returnType: void
      f2 @82
        parameters
          requiredPositional a @93
            type: int Function()
              aliasElement: self::@typeAlias::A2
              aliasArguments
                int
        returnType: void
''');
  }

  test_typedef_nonFunction_aliasElement_interfaceType() async {
    var library = await checkLibrary(r'''
typedef A1 = List<int>;
typedef A2<T, U> = Map<T, U>;
void f1(A1 a) {}
void f2(A2<int, String> a) {}
''');

    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A1 @8
        aliasedType: List<int>
      A2 @32
        typeParameters
          covariant T @35
            defaultType: dynamic
          covariant U @38
            defaultType: dynamic
        aliasedType: Map<T, U>
    functions
      f1 @59
        parameters
          requiredPositional a @65
            type: List<int>
              aliasElement: self::@typeAlias::A1
        returnType: void
      f2 @76
        parameters
          requiredPositional a @95
            type: Map<int, String>
              aliasElement: self::@typeAlias::A2
              aliasArguments
                int
                String
        returnType: void
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type Never is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_never() async {
    var library = await checkLibrary(r'''
typedef A1 = Never;
typedef A2<T> = Never?;
void f1(A1 a) {}
void f2(A2<int> a) {}
''');

    checkElementText(library, r'''
typedef A1 = Never;
typedef A2<T> = Never?;
void f1(Never<aliasElement: self::@typeAlias::A1> a) {}
void f2(Never?<aliasElement: self::@typeAlias::A2, aliasArguments: [int]> a) {}
''');
  }

  test_typedef_nonFunction_aliasElement_typeParameterType() async {
    var library = await checkLibrary(r'''
typedef A<T> = T;
void f<U>(A<U> a) {}
''');

    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T
    functions
      f @23
        typeParameters
          covariant U @25
        parameters
          requiredPositional a @33
            type: U
              aliasElement: self::@typeAlias::A
              aliasArguments
                U
        returnType: void
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type void is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_void() async {
    var library = await checkLibrary(r'''
typedef A = void;
void f(A a) {}
''');

    checkElementText(library, r'''
typedef A = void;
void f(void<aliasElement: self::@typeAlias::A> a) {}
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_none() async {
    var library = await checkLibrary(r'''
typedef X<T> = A<int, T>;
class A<T, U> {}
class B implements X<String> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @32
        typeParameters
          covariant T @34
            defaultType: dynamic
          covariant U @37
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @49
        interfaces
          A<int, String>
            aliasElement: self::@typeAlias::X
            aliasArguments
              String
        constructors
          synthetic @-1
    typeAliases
      X @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: A<int, T>
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_question() async {
    var library = await checkLibrary(r'''
typedef X<T> = A<T>?;
class A<T> {}
class B {}
class C {}
class D implements B, X<int>, C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @28
        typeParameters
          covariant T @30
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @42
        constructors
          synthetic @-1
      class C @53
        constructors
          synthetic @-1
      class D @64
        interfaces
          B
          C
        constructors
          synthetic @-1
    typeAliases
      X @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: A<T>?
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_question2() async {
    var library = await checkLibrary(r'''
typedef X<T> = A<T?>;
class A<T> {}
class B {}
class C {}
class D implements B, X<int>, C {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @28
        typeParameters
          covariant T @30
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @42
        constructors
          synthetic @-1
      class C @53
        constructors
          synthetic @-1
      class D @64
        interfaces
          B
          A<int?>
            aliasElement: self::@typeAlias::X
            aliasArguments
              int
          C
        constructors
          synthetic @-1
    typeAliases
      X @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: A<T?>
''');
  }

  test_typedef_nonFunction_asInterfaceType_Never_none() async {
    var library = await checkLibrary(r'''
typedef X = Never;
class A implements X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @25
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Never
''');
  }

  test_typedef_nonFunction_asInterfaceType_Null_none() async {
    var library = await checkLibrary(r'''
typedef X = Null;
class A implements X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Null
''');
  }

  test_typedef_nonFunction_asInterfaceType_typeParameterType() async {
    var library = await checkLibrary(r'''
typedef X<T> = T;
class A {}
class B {}
class C<U> implements A, X<U>, B {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        constructors
          synthetic @-1
      class B @35
        constructors
          synthetic @-1
      class C @46
        typeParameters
          covariant U @48
            defaultType: dynamic
        interfaces
          A
          B
        constructors
          synthetic @-1
    typeAliases
      X @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T
''');
  }

  test_typedef_nonFunction_asInterfaceType_void() async {
    var library = await checkLibrary(r'''
typedef X = void;
class A {}
class B {}
class C implements A, X, B {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        constructors
          synthetic @-1
      class B @35
        constructors
          synthetic @-1
      class C @46
        interfaces
          A
          B
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: void
''');
  }

  test_typedef_nonFunction_asMixinType_none() async {
    var library = await checkLibrary(r'''
typedef X = A<int>;
class A<T> {}
class B with X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @26
        typeParameters
          covariant T @28
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @40
        supertype: Object
        mixins
          A<int>
            aliasElement: self::@typeAlias::X
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int>
''');
  }

  test_typedef_nonFunction_asMixinType_question() async {
    var library = await checkLibrary(r'''
typedef X = A<int>?;
class A<T> {}
mixin M1 {}
mixin M2 {}
class B with M1, X, M2 {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @27
        typeParameters
          covariant T @29
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @65
        supertype: Object
        mixins
          M1
          M2
        constructors
          synthetic @-1
    mixins
      mixin M1 @41
        superclassConstraints
          Object
        constructors
          synthetic @-1
      mixin M2 @53
        superclassConstraints
          Object
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int>?
''');
  }

  test_typedef_nonFunction_asMixinType_question2() async {
    var library = await checkLibrary(r'''
typedef X = A<int?>;
class A<T> {}
mixin M1 {}
mixin M2 {}
class B with M1, X, M2 {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @27
        typeParameters
          covariant T @29
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @65
        supertype: Object
        mixins
          M1
          A<int?>
            aliasElement: self::@typeAlias::X
          M2
        constructors
          synthetic @-1
    mixins
      mixin M1 @41
        superclassConstraints
          Object
        constructors
          synthetic @-1
      mixin M2 @53
        superclassConstraints
          Object
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int?>
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_Never_none() async {
    var library = await checkLibrary(r'''
typedef X = Never;
class A extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @25
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Never
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_none() async {
    var library = await checkLibrary(r'''
typedef X = A<int>;
class A<T> {}
class B extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @26
        typeParameters
          covariant T @28
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @40
        supertype: A<int>
          aliasElement: self::@typeAlias::X
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int>
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_none_viaTypeParameter() async {
    var library = await checkLibrary(r'''
typedef X<T> = T;
class A<T> {}
class B extends X<A<int>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        typeParameters
          covariant T @26
            defaultType: dynamic
        constructors
          synthetic @-1
      class B @38
        supertype: A<int>
          aliasElement: self::@typeAlias::X
          aliasArguments
            A<int>
        constructors
          synthetic @-1
    typeAliases
      X @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_Null_none() async {
    var library = await checkLibrary(r'''
typedef X = Null;
class A extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Null
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_question() async {
    var library = await checkLibrary(r'''
typedef X = A<int>?;
class A<T> {}
class D extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @27
        typeParameters
          covariant T @29
            defaultType: dynamic
        constructors
          synthetic @-1
      class D @41
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int>?
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_question2() async {
    var library = await checkLibrary(r'''
typedef X = A<int?>;
class A<T> {}
class D extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @27
        typeParameters
          covariant T @29
            defaultType: dynamic
        constructors
          synthetic @-1
      class D @41
        supertype: A<int?>
          aliasElement: self::@typeAlias::X
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: A<int?>
''');
  }

  test_typedef_nonFunction_asSuperType_Never_none() async {
    var library = await checkLibrary(r'''
typedef X = Never;
class A extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @25
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Never
''');
  }

  test_typedef_nonFunction_asSuperType_Null_none() async {
    var library = await checkLibrary(r'''
typedef X = Null;
class A extends X {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @24
        constructors
          synthetic @-1
    typeAliases
      X @8
        aliasedType: Null
''');
  }

  test_typedef_nonFunction_using_dynamic() async {
    var library = await checkLibrary(r'''
typedef A = dynamic;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: dynamic
    functions
      f @26
        parameters
          requiredPositional a @30
            type: dynamic
        returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_disabled() async {
    featureSet = FeatureSets.language_2_12;
    var library = await checkLibrary(r'''
typedef A = int;
void f(A a) {}
''');

    var alias = library.definingCompilationUnit.typeAliases[0];
    _assertTypeStr(alias.aliasedType, 'dynamic Function()');

    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: dynamic Function()
    functions
      f @22
        parameters
          requiredPositional a @26
            type: dynamic Function()
              aliasElement: self::@typeAlias::A
        returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_noTypeParameters() async {
    var library = await checkLibrary(r'''
typedef A = int;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: int
    functions
      f @22
        parameters
          requiredPositional a @26
            type: int
              aliasElement: self::@typeAlias::A
        returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_noTypeParameters_legacy() async {
    newFile('/a.dart', content: r'''
typedef A = List<int>;
''');
    var library = await checkLibrary(r'''
// @dart = 2.9
import 'a.dart';
void f(A a) {}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    functions
      f @37
        parameters
          requiredPositional a @41
            type: List<int*>*
              aliasElement: a.dart::@typeAlias::A
        returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_noTypeParameters_question() async {
    var library = await checkLibrary(r'''
typedef A = int?;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: int?
    functions
      f @23
        parameters
          requiredPositional a @27
            type: int?
              aliasElement: self::@typeAlias::A
        returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_withTypeParameters() async {
    var library = await checkLibrary(r'''
typedef A<T> = Map<int, T>;
void f(A<String> a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: Map<int, T>
    functions
      f @33
        parameters
          requiredPositional a @45
            type: Map<int, String>
              aliasElement: self::@typeAlias::A
              aliasArguments
                String
        returnType: void
''');
  }

  test_typedef_nonFunction_using_Never_none() async {
    var library = await checkLibrary(r'''
typedef A = Never;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: Never
    functions
      f @24
        parameters
          requiredPositional a @28
            type: Never
        returnType: void
''');
  }

  test_typedef_nonFunction_using_Never_question() async {
    var library = await checkLibrary(r'''
typedef A = Never?;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: Never?
    functions
      f @25
        parameters
          requiredPositional a @29
            type: Never?
        returnType: void
''');
  }

  test_typedef_nonFunction_using_typeParameter_none() async {
    var library = await checkLibrary(r'''
typedef A<T> = T;
void f1(A a) {}
void f2(A<int> a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T
    functions
      f1 @23
        parameters
          requiredPositional a @28
            type: dynamic
        returnType: void
      f2 @39
        parameters
          requiredPositional a @49
            type: int
              aliasElement: self::@typeAlias::A
              aliasArguments
                int
        returnType: void
''');
  }

  test_typedef_nonFunction_using_typeParameter_question() async {
    var library = await checkLibrary(r'''
typedef A<T> = T?;
void f1(A a) {}
void f2(A<int> a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        typeParameters
          covariant T @10
            defaultType: dynamic
        aliasedType: T?
    functions
      f1 @24
        parameters
          requiredPositional a @29
            type: dynamic
        returnType: void
      f2 @40
        parameters
          requiredPositional a @50
            type: int?
              aliasElement: self::@typeAlias::A
              aliasArguments
                int
        returnType: void
''');
  }

  test_typedef_nonFunction_using_void() async {
    var library = await checkLibrary(r'''
typedef A = void;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      A @8
        aliasedType: void
    functions
      f @23
        parameters
          requiredPositional a @27
            type: void
        returnType: void
''');
  }

  test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_included() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await checkLibrary('''
typedef F = void Function(C c);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @38
        typeParameters
          covariant T @40
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
    typeAliases
      notSimplyBounded F @8
        aliasedType: void Function(C<C<dynamic>>)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional c @28
              type: C<C<dynamic>>
          returnType: void
''');
  }

  test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_omitted() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await checkLibrary('''
typedef F = void Function(C);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @36
        typeParameters
          covariant T @38
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
    typeAliases
      notSimplyBounded F @8
        aliasedType: void Function(C<C<dynamic>>)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional @-1
              type: C<C<dynamic>>
          returnType: void
''');
  }

  test_typedef_notSimplyBounded_dependency_via_param_type_old_style() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await checkLibrary('''
typedef void F(C c);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @27
        typeParameters
          covariant T @29
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased notSimplyBounded F @13
        aliasedType: void Function(C<C<dynamic>>)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional c @17
              type: C<C<dynamic>>
          returnType: void
''');
  }

  test_typedef_notSimplyBounded_dependency_via_return_type_new_style() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await checkLibrary('''
typedef F = C Function();
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @32
        typeParameters
          covariant T @34
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
    typeAliases
      notSimplyBounded F @8
        aliasedType: C<C<dynamic>> Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: C<C<dynamic>>
''');
  }

  test_typedef_notSimplyBounded_dependency_via_return_type_old_style() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await checkLibrary('''
typedef C F();
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      notSimplyBounded class C @21
        typeParameters
          covariant T @23
            bound: C<T>
            defaultType: C<dynamic>
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased notSimplyBounded F @10
        aliasedType: C<C<dynamic>> Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: C<C<dynamic>>
''');
  }

  test_typedef_parameter_hasImplicitType() async {
    var library = await checkLibrary(r'''
typedef void F(int a, b, [int c, d]);
''');
    var F = library.definingCompilationUnit.typeAliases.single;
    var function = F.aliasedElement as GenericFunctionTypeElement;
    // TODO(scheglov) Use better textual presentation with all information.
    expect(function.parameters[0].hasImplicitType, false);
    expect(function.parameters[1].hasImplicitType, true);
    expect(function.parameters[2].hasImplicitType, false);
    expect(function.parameters[3].hasImplicitType, true);
  }

  test_typedef_parameter_parameters() async {
    var library = await checkLibrary('typedef F(g(x, y));');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function(dynamic Function(dynamic, dynamic))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional g @10
              type: dynamic Function(dynamic, dynamic)
              parameters
                requiredPositional x @12
                  type: dynamic
                requiredPositional y @15
                  type: dynamic
          returnType: dynamic
''');
  }

  test_typedef_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('typedef F<A, B>(A g(B x));');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        typeParameters
          contravariant A @10
            defaultType: dynamic
          covariant B @13
            defaultType: dynamic
        aliasedType: dynamic Function(A Function(B))
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional g @18
              type: A Function(B)
              parameters
                requiredPositional x @22
                  type: B
          returnType: dynamic
''');
  }

  test_typedef_parameter_return_type() async {
    var library = await checkLibrary('typedef F(int g());');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function(int Function())
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional g @14
              type: int Function()
          returnType: dynamic
''');
  }

  test_typedef_parameter_type() async {
    var library = await checkLibrary('typedef F(int i);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function(int)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional i @14
              type: int
          returnType: dynamic
''');
  }

  test_typedef_parameter_type_generic() async {
    var library = await checkLibrary('typedef F<T>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        typeParameters
          contravariant T @10
            defaultType: dynamic
        aliasedType: dynamic Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @15
              type: T
          returnType: dynamic
''');
  }

  test_typedef_parameters() async {
    var library = await checkLibrary('typedef F(x, y);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function(dynamic, dynamic)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional x @10
              type: dynamic
            requiredPositional y @13
              type: dynamic
          returnType: dynamic
''');
  }

  test_typedef_parameters_named() async {
    var library = await checkLibrary('typedef F({y, z, x});');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function({dynamic x, dynamic y, dynamic z})
        aliasedElement: GenericFunctionTypeElement
          parameters
            optionalNamed y @11
              type: dynamic
            optionalNamed z @14
              type: dynamic
            optionalNamed x @17
              type: dynamic
          returnType: dynamic
''');
  }

  test_typedef_return_type() async {
    var library = await checkLibrary('typedef int F();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @12
        aliasedType: int Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: int
''');
  }

  test_typedef_return_type_generic() async {
    var library = await checkLibrary('typedef T F<T>();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          covariant T @12
            defaultType: dynamic
        aliasedType: T Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: T
''');
  }

  test_typedef_return_type_implicit() async {
    var library = await checkLibrary('typedef F();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @8
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_typedef_return_type_void() async {
    var library = await checkLibrary('typedef void F();');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @13
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_typedef_type_parameters() async {
    var library = await checkLibrary('typedef U F<T, U>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          contravariant T @12
            defaultType: dynamic
          covariant U @15
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @20
              type: T
          returnType: U
''');
  }

  test_typedef_type_parameters_bound() async {
    var library = await checkLibrary(
        'typedef U F<T extends Object, U extends D>(T t); class D {}');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class D @55
        constructors
          synthetic @-1
    typeAliases
      functionTypeAliasBased F @10
        typeParameters
          contravariant T @12
            bound: Object
            defaultType: Object
          covariant U @30
            bound: D
            defaultType: D
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @45
              type: T
          returnType: U
''');
  }

  test_typedef_type_parameters_bound_recursive() async {
    var library = await checkLibrary('typedef void F<T extends F>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @13
        typeParameters
          unrelated T @15
            bound: dynamic
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_typedef_type_parameters_bound_recursive2() async {
    var library = await checkLibrary('typedef void F<T extends List<F>>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @13
        typeParameters
          unrelated T @15
            bound: List<dynamic>
            defaultType: dynamic
        aliasedType: void Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: void
''');
  }

  test_typedef_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @10
        typeParameters
          contravariant T @12
            bound: List<U>
            defaultType: List<Never>
          covariant U @31
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @36
              type: T
          returnType: U
''');
  }

  test_typedef_type_parameters_f_bound_complex_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @10
        typeParameters
          contravariant T @12
            bound: List<U*>*
            defaultType: List<Null*>*
          covariant U @31
            defaultType: dynamic
        aliasedType: U* Function(T*)*
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @36
              type: T*
          returnType: U*
''');
  }

  test_typedef_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @10
        typeParameters
          contravariant T @12
            bound: U
            defaultType: Never
          covariant U @25
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @30
              type: T
          returnType: U
''');
  }

  test_typedef_type_parameters_f_bound_simple_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library = await checkLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      functionTypeAliasBased notSimplyBounded F @10
        typeParameters
          contravariant T @12
            bound: U*
            defaultType: Null*
          covariant U @25
            defaultType: dynamic
        aliasedType: U* Function(T*)*
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @30
              type: T*
          returnType: U*
''');
  }

  test_typedef_type_parameters_f_bound_simple_new_syntax() async {
    var library =
        await checkLibrary('typedef F<T extends U, U> = U Function(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        typeParameters
          contravariant T @10
            bound: U
            defaultType: Never
          covariant U @23
            defaultType: dynamic
        aliasedType: U Function(T)
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @41
              type: T
          returnType: U
''');
  }

  test_typedef_type_parameters_f_bound_simple_new_syntax_legacy() async {
    featureSet = FeatureSets.language_2_9;
    var library =
        await checkLibrary('typedef F<T extends U, U> = U Function(T t);');
    checkElementText(library, r'''
library
  definingUnit
    typeAliases
      notSimplyBounded F @8
        typeParameters
          contravariant T @10
            bound: U*
            defaultType: Null*
          covariant U @23
            defaultType: dynamic
        aliasedType: U* Function(T*)*
        aliasedElement: GenericFunctionTypeElement
          parameters
            requiredPositional t @41
              type: T*
          returnType: U*
''');
  }

  test_typedefs() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
library
  definingUnit
    functions
      f @0
        returnType: dynamic
      g @7
        returnType: dynamic
''');
  }

  test_unit_implicitVariable_getterFirst() async {
    var library = await checkLibrary('''
int get x => 0;
void set x(int value) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      get x @8
        returnType: int
      set x @25
        parameters
          requiredPositional value @31
            type: int
        returnType: void
''');
  }

  test_unit_implicitVariable_setterFirst() async {
    var library = await checkLibrary('''
void set x(int value) {}
int get x => 0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      set x @9
        parameters
          requiredPositional value @15
            type: int
        returnType: void
      get x @33
        returnType: int
''');
  }

  test_unit_variable_final_withSetter() async {
    var library = await checkLibrary(r'''
final int foo = 0;
set foo(int newValue) {}
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final foo @10
        type: int
    accessors
      synthetic static get foo @-1
        returnType: int
      set foo @23
        parameters
          requiredPositional newValue @31
            type: int
        returnType: void
''');
  }

  test_unresolved_annotation_instanceCreation_argument_super() async {
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(super)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional _ @20
                type: dynamic
      class C @43
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                SuperExpression
                  staticType: dynamic
                  superKeyword: super @30
              leftParenthesis: ( @29
              rightParenthesis: ) @35
            atSign: @ @27
            element: self::@class::A::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @28
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_instanceCreation_argument_this() async {
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(this)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          const @18
            parameters
              requiredPositional _ @20
                type: dynamic
      class C @42
        metadata
          Annotation
            arguments: ArgumentList
              arguments
                ThisExpression
                  staticType: dynamic
                  thisKeyword: this @30
              leftParenthesis: ( @29
              rightParenthesis: ) @34
            atSign: @ @27
            element: self::@class::A::@constructor::•
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A @28
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @17
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @8
              rightParenthesis: ) @9
            atSign: @ @0
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @5
              period: . @4
              prefix: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: foo @1
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library =
        await checkLibrary('@String.foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @20
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @11
              rightParenthesis: ) @12
            atSign: @ @0
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: foo @8
              period: . @7
              prefix: SimpleIdentifier
                staticElement: dart:core::@class::String
                staticType: null
                token: String @1
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await checkLibrary('@foo.bar class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @15
        metadata
          Annotation
            atSign: @ @0
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @5
              period: . @4
              prefix: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: foo @1
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar class C {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  imports
    dart:async as foo @23
  definingUnit
    classes
      class C @43
        metadata
          Annotation
            atSign: @ @28
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @33
              period: . @32
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @29
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library =
        await checkLibrary('@foo.bar.baz() class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @21
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @12
              rightParenthesis: ) @13
            atSign: @ @0
            constructorName: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: baz @9
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @5
              period: . @4
              prefix: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: foo @1
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar.baz() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  imports
    dart:async as foo @23
  definingUnit
    classes
      class C @49
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @40
              rightParenthesis: ) @41
            atSign: @ @28
            constructorName: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: baz @37
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @33
              period: . @32
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @29
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.Future.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  imports
    dart:async as foo @23
  definingUnit
    classes
      class C @52
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @43
              rightParenthesis: ) @44
            atSign: @ @28
            constructorName: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: bar @40
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: dart:async::@class::Future
                staticType: null
                token: Future @33
              period: . @32
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @29
              staticElement: dart:async::@class::Future
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @17
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @8
              rightParenthesis: ) @9
            atSign: @ @0
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @5
              period: . @4
              prefix: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: foo @1
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
library
  imports
    dart:async as foo @23
  definingUnit
    classes
      class C @45
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @36
              rightParenthesis: ) @37
            atSign: @ @28
            element: <null>
            name: PrefixedIdentifier
              identifier: SimpleIdentifier
                staticElement: <null>
                staticType: null
                token: bar @33
              period: . @32
              prefix: SimpleIdentifier
                staticElement: self::@prefix::foo
                staticType: null
                token: foo @29
              staticElement: <null>
              staticType: null
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await checkLibrary('@foo class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @11
        metadata
          Annotation
            atSign: @ @0
            element: <null>
            name: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: foo @1
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_simpleIdentifier_multiplyDefined() async {
    addLibrarySource('/a.dart', 'const v = 0;');
    addLibrarySource('/b.dart', 'const v = 0;');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';

@v
class C {}
''');
    checkElementText(library, r'''
library
  imports
    a.dart
    b.dart
  definingUnit
    classes
      class C @44
        metadata
          Annotation
            atSign: @ @35
            element: <null>
            name: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: v @36
        constructors
          synthetic @-1
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await checkLibrary('@foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @13
        metadata
          Annotation
            arguments: ArgumentList
              leftParenthesis: ( @4
              rightParenthesis: ) @5
            atSign: @ @0
            element: <null>
            name: SimpleIdentifier
              staticElement: <null>
              staticType: null
              token: foo @1
        constructors
          synthetic @-1
''');
  }

  test_unresolved_export() async {
    var library = await checkLibrary("export 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
library
  exports
    foo.dart
  definingUnit
''');
  }

  test_unresolved_import() async {
    var library = await checkLibrary("import 'foo.dart';", allowErrors: true);
    var importedLibrary = library.imports[0].importedLibrary!;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
library
  imports
    foo.dart
  definingUnit
''');
  }

  test_unresolved_part() async {
    var library = await checkLibrary("part 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
library
  definingUnit
  parts
    foo.dart
''');
  }

  test_unused_type_parameter() async {
    var library = await checkLibrary('''
class C<T> {
  void f() {}
}
C<int> c;
var v = c.f;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          f @20
            returnType: void
    topLevelVariables
      static c @36
        type: C<int>
      static v @43
        type: void Function()
    accessors
      synthetic static get c @-1
        returnType: C<int>
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C<int>
        returnType: void
      synthetic static get v @-1
        returnType: void Function()
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: void Function()
        returnType: void
''');
  }

  test_variable() async {
    var library = await checkLibrary('int x = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_variable_const() async {
    var library = await checkLibrary('const int i = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const i @10
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @14
            staticType: int
    accessors
      synthetic static get i @-1
        returnType: int
''');
  }

  test_variable_const_late() async {
    var library = await checkLibrary('late const int i = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static late const i @15
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @19
            staticType: int
    accessors
      synthetic static get i @-1
        returnType: int
''');
  }

  test_variable_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @64
        documentationComment: /**\n * Docs\n */
        type: dynamic
    accessors
      synthetic static get x @-1
        returnType: dynamic
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: dynamic
        returnType: void
''');
  }

  test_variable_final() async {
    var library = await checkLibrary('final int x = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final x @10
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
''');
  }

  test_variable_getterInLib_setterInPart() async {
    addSource('/a.dart', '''
part of my.lib;
void set x(int _) {}
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
int get x => 42;''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      get x @39
        returnType: int
  parts
    a.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        set x @25
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
''');
  }

  test_variable_getterInPart_setterInLib() async {
    addSource('/a.dart', '''
part of my.lib;
int get x => 42;
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
void set x(int _) {}
''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
    topLevelVariables
      synthetic static x @-1
        type: int
    accessors
      set x @40
        parameters
          requiredPositional _ @46
            type: int
        returnType: void
  parts
    a.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        get x @24
          returnType: int
''');
  }

  test_variable_getterInPart_setterInPart() async {
    addSource('/a.dart', 'part of my.lib; int get x => 42;');
    addSource('/b.dart', 'part of my.lib; void set x(int _) {}');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
  parts
    a.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        get x @24
          returnType: int
    b.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        set x @25
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
''');
  }

  test_variable_implicit() async {
    var library = await checkLibrary('int get x => 0;');

    // We intentionally don't check the text, because we want to test
    // requesting individual elements, not all accessors/variables at once.
    var getter = _elementOfDefiningUnit(library, ['@getter', 'x'])
        as PropertyAccessorElementImpl;
    var variable = getter.variable as TopLevelVariableElementImpl;
    expect(variable, isNotNull);
    expect(variable.isFinal, isFalse);
    expect(variable.getter, same(getter));
    _assertTypeStr(variable.type, 'int');
    expect(variable, same(_elementOfDefiningUnit(library, ['@variable', 'x'])));
  }

  test_variable_implicit_type() async {
    var library = await checkLibrary('var x;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static x @4
        type: dynamic
    accessors
      synthetic static get x @-1
        returnType: dynamic
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: dynamic
        returnType: void
''');
  }

  test_variable_inferred_type_implicit_initialized() async {
    var library = await checkLibrary('var v = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_variable_initializer() async {
    var library = await checkLibrary('int v = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_variable_initializer_final() async {
    var library = await checkLibrary('final int v = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final v @10
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_variable_initializer_final_untyped() async {
    var library = await checkLibrary('final v = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final v @6
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
''');
  }

  test_variable_initializer_staticMethod_ofExtension() async {
    var library = await checkLibrary('''
class A {}
extension E on A {
  static int f() => 0;
}
var x = E.f();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    extensions
      E @21
        extendedType: A
        methods
          static f @43
            returnType: int
    topLevelVariables
      static x @59
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_variable_initializer_untyped() async {
    var library = await checkLibrary('var v = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_variable_late() async {
    var library = await checkLibrary('late int x = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static late x @9
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_variable_late_final() async {
    var library = await checkLibrary('late final int x;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static late final x @15
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_variable_late_final_initialized() async {
    var library = await checkLibrary('late final int x = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static late final x @15
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
''');
  }

  test_variable_propagatedType_const_noDep() async {
    var library = await checkLibrary('const i = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static const i @6
        type: int
        constantInitializer
          IntegerLiteral
            literal: 0 @10
            staticType: int
    accessors
      synthetic static get i @-1
        returnType: int
''');
  }

  test_variable_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('import "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static final b @23
        type: double
    accessors
      synthetic static get b @-1
        returnType: double
''');
  }

  test_variable_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library =
        await checkLibrary('library lib; part "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library
  name: lib
  nameOffset: 8
  definingUnit
    topLevelVariables
      static final b @34
        type: double
    accessors
      synthetic static get b @-1
        returnType: double
  parts
    a.dart
      topLevelVariables
        static final a @19
          type: int
      accessors
        synthetic static get a @-1
          returnType: int
''');
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await checkLibrary('final i = 0;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static final i @6
        type: int
    accessors
      synthetic static get i @-1
        returnType: int
''');
  }

  test_variable_propagatedType_implicit_dep() async {
    // The propagated type is defined in a library that is not imported.
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'import "a.dart"; C f() => null;');
    var library = await checkLibrary('import "b.dart"; final x = f();');
    checkElementText(library, r'''
library
  imports
    b.dart
  definingUnit
    topLevelVariables
      static final x @23
        type: C
    accessors
      synthetic static get x @-1
        returnType: C
''');
  }

  test_variable_setterInPart_getterInPart() async {
    addSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    addSource('/b.dart', 'part of my.lib; int get x => 42;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  definingUnit
  parts
    a.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        set x @25
          parameters
            requiredPositional _ @31
              type: int
          returnType: void
    b.dart
      topLevelVariables
        synthetic static x @-1
          type: int
      accessors
        get x @24
          returnType: int
''');
  }

  test_variable_type_inferred_Never() async {
    var library = await checkLibrary(r'''
var a = throw 42;
''');

    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: Never
    accessors
      synthetic static get a @-1
        returnType: Never
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: Never
        returnType: void
''');
  }

  test_variable_type_inferred_noInitializer() async {
    var library = await checkLibrary(r'''
var a;
''');

    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: dynamic
        returnType: void
''');
  }

  test_variable_type_inferred_nonNullify() async {
    addSource('/a.dart', '''
// @dart = 2.7
var a = 0;
''');

    var library = await checkLibrary(r'''
import 'a.dart';
var b = a;
''');

    checkElementText(library, r'''
library
  imports
    a.dart
  definingUnit
    topLevelVariables
      static b @21
        type: int
    accessors
      synthetic static get b @-1
        returnType: int
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: int
        returnType: void
''');
  }

  test_variableInitializer_contextType_after_astRewrite() async {
    var library = await checkLibrary(r'''
class A<T> {
  const A();
}
const A<int> a = A();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          const @21
    topLevelVariables
      static const a @41
        type: A<int>
        constantInitializer
          InstanceCreationExpression
            argumentList: ArgumentList
              leftParenthesis: ( @46
              rightParenthesis: ) @47
            constructorName: ConstructorName
              staticElement: ConstructorMember
                base: self::@class::A::@constructor::•
                substitution: {T: int}
              type: NamedType
                name: SimpleIdentifier
                  staticElement: self::@class::A
                  staticType: null
                  token: A @45
                type: A<int>
            staticType: A<int>
    accessors
      synthetic static get a @-1
        returnType: A<int>
''');
  }

  test_variables() async {
    var library = await checkLibrary('int i; int j;');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static i @4
        type: int
      static j @11
        type: int
    accessors
      synthetic static get i @-1
        returnType: int
      synthetic static set i @-1
        parameters
          requiredPositional _i @-1
            type: int
        returnType: void
      synthetic static get j @-1
        returnType: int
      synthetic static set j @-1
        parameters
          requiredPositional _j @-1
            type: int
        returnType: void
''');
  }

  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: true);
    expect(typeStr, expected);
  }

  void _assertTypeStrings(List<DartType> types, List<String> expected) {
    var typeStringList = types.map((e) {
      return e.getDisplayString(withNullability: true);
    }).toList();
    expect(typeStringList, expected);
  }

  Element _elementOfDefiningUnit(
      LibraryElementImpl library, List<String> names) {
    var unit = library.definingCompilationUnit as CompilationUnitElementImpl;
    var reference = unit.reference!;
    names.forEach((name) => reference = reference.getChild(name));

    var element = reference.element;
    if (element != null) {
      return element;
    }

    var elementFactory = library.linkedData!.elementFactory;
    return elementFactory.elementOfReference(reference)!;
  }
}
