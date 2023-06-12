// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constructor.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Constructor extends Constructor {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final BuiltList<Parameter> optionalParameters;
  @override
  final BuiltList<Parameter> requiredParameters;
  @override
  final BuiltList<Code> initializers;
  @override
  final Code body;
  @override
  final bool external;
  @override
  final bool constant;
  @override
  final bool factory;
  @override
  final bool lambda;
  @override
  final String name;
  @override
  final Reference redirect;

  factory _$Constructor([void Function(ConstructorBuilder) updates]) =>
      (new ConstructorBuilder()..update(updates)).build() as _$Constructor;

  _$Constructor._(
      {this.annotations,
      this.docs,
      this.optionalParameters,
      this.requiredParameters,
      this.initializers,
      this.body,
      this.external,
      this.constant,
      this.factory,
      this.lambda,
      this.name,
      this.redirect})
      : super._() {
    if (annotations == null) {
      throw new BuiltValueNullFieldError('Constructor', 'annotations');
    }
    if (docs == null) {
      throw new BuiltValueNullFieldError('Constructor', 'docs');
    }
    if (optionalParameters == null) {
      throw new BuiltValueNullFieldError('Constructor', 'optionalParameters');
    }
    if (requiredParameters == null) {
      throw new BuiltValueNullFieldError('Constructor', 'requiredParameters');
    }
    if (initializers == null) {
      throw new BuiltValueNullFieldError('Constructor', 'initializers');
    }
    if (external == null) {
      throw new BuiltValueNullFieldError('Constructor', 'external');
    }
    if (constant == null) {
      throw new BuiltValueNullFieldError('Constructor', 'constant');
    }
    if (factory == null) {
      throw new BuiltValueNullFieldError('Constructor', 'factory');
    }
  }

  @override
  Constructor rebuild(void Function(ConstructorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$ConstructorBuilder toBuilder() => new _$ConstructorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Constructor &&
        annotations == other.annotations &&
        docs == other.docs &&
        optionalParameters == other.optionalParameters &&
        requiredParameters == other.requiredParameters &&
        initializers == other.initializers &&
        body == other.body &&
        external == other.external &&
        constant == other.constant &&
        factory == other.factory &&
        lambda == other.lambda &&
        name == other.name &&
        redirect == other.redirect;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc($jc(0, annotations.hashCode),
                                                docs.hashCode),
                                            optionalParameters.hashCode),
                                        requiredParameters.hashCode),
                                    initializers.hashCode),
                                body.hashCode),
                            external.hashCode),
                        constant.hashCode),
                    factory.hashCode),
                lambda.hashCode),
            name.hashCode),
        redirect.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Constructor')
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('optionalParameters', optionalParameters)
          ..add('requiredParameters', requiredParameters)
          ..add('initializers', initializers)
          ..add('body', body)
          ..add('external', external)
          ..add('constant', constant)
          ..add('factory', factory)
          ..add('lambda', lambda)
          ..add('name', name)
          ..add('redirect', redirect))
        .toString();
  }
}

class _$ConstructorBuilder extends ConstructorBuilder {
  _$Constructor _$v;

  @override
  ListBuilder<Expression> get annotations {
    _$this;
    return super.annotations ??= new ListBuilder<Expression>();
  }

  @override
  set annotations(ListBuilder<Expression> annotations) {
    _$this;
    super.annotations = annotations;
  }

  @override
  ListBuilder<String> get docs {
    _$this;
    return super.docs ??= new ListBuilder<String>();
  }

  @override
  set docs(ListBuilder<String> docs) {
    _$this;
    super.docs = docs;
  }

  @override
  ListBuilder<Parameter> get optionalParameters {
    _$this;
    return super.optionalParameters ??= new ListBuilder<Parameter>();
  }

  @override
  set optionalParameters(ListBuilder<Parameter> optionalParameters) {
    _$this;
    super.optionalParameters = optionalParameters;
  }

  @override
  ListBuilder<Parameter> get requiredParameters {
    _$this;
    return super.requiredParameters ??= new ListBuilder<Parameter>();
  }

  @override
  set requiredParameters(ListBuilder<Parameter> requiredParameters) {
    _$this;
    super.requiredParameters = requiredParameters;
  }

  @override
  ListBuilder<Code> get initializers {
    _$this;
    return super.initializers ??= new ListBuilder<Code>();
  }

  @override
  set initializers(ListBuilder<Code> initializers) {
    _$this;
    super.initializers = initializers;
  }

  @override
  Code get body {
    _$this;
    return super.body;
  }

  @override
  set body(Code body) {
    _$this;
    super.body = body;
  }

  @override
  bool get external {
    _$this;
    return super.external;
  }

  @override
  set external(bool external) {
    _$this;
    super.external = external;
  }

  @override
  bool get constant {
    _$this;
    return super.constant;
  }

  @override
  set constant(bool constant) {
    _$this;
    super.constant = constant;
  }

  @override
  bool get factory {
    _$this;
    return super.factory;
  }

  @override
  set factory(bool factory) {
    _$this;
    super.factory = factory;
  }

  @override
  bool get lambda {
    _$this;
    return super.lambda;
  }

  @override
  set lambda(bool lambda) {
    _$this;
    super.lambda = lambda;
  }

  @override
  String get name {
    _$this;
    return super.name;
  }

  @override
  set name(String name) {
    _$this;
    super.name = name;
  }

  @override
  Reference get redirect {
    _$this;
    return super.redirect;
  }

  @override
  set redirect(Reference redirect) {
    _$this;
    super.redirect = redirect;
  }

  _$ConstructorBuilder() : super._();

  ConstructorBuilder get _$this {
    if (_$v != null) {
      super.annotations = _$v.annotations?.toBuilder();
      super.docs = _$v.docs?.toBuilder();
      super.optionalParameters = _$v.optionalParameters?.toBuilder();
      super.requiredParameters = _$v.requiredParameters?.toBuilder();
      super.initializers = _$v.initializers?.toBuilder();
      super.body = _$v.body;
      super.external = _$v.external;
      super.constant = _$v.constant;
      super.factory = _$v.factory;
      super.lambda = _$v.lambda;
      super.name = _$v.name;
      super.redirect = _$v.redirect;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Constructor other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Constructor;
  }

  @override
  void update(void Function(ConstructorBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Constructor build() {
    _$Constructor _$result;
    try {
      _$result = _$v ??
          new _$Constructor._(
              annotations: annotations.build(),
              docs: docs.build(),
              optionalParameters: optionalParameters.build(),
              requiredParameters: requiredParameters.build(),
              initializers: initializers.build(),
              body: body,
              external: external,
              constant: constant,
              factory: factory,
              lambda: lambda,
              name: name,
              redirect: redirect);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();
        _$failedField = 'optionalParameters';
        optionalParameters.build();
        _$failedField = 'requiredParameters';
        requiredParameters.build();
        _$failedField = 'initializers';
        initializers.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Constructor', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
