// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Extension extends Extension {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final Reference on;
  @override
  final BuiltList<Reference> types;
  @override
  final BuiltList<Method> methods;
  @override
  final BuiltList<Field> fields;
  @override
  final String name;

  factory _$Extension([void Function(ExtensionBuilder) updates]) =>
      (new ExtensionBuilder()..update(updates)).build() as _$Extension;

  _$Extension._(
      {this.annotations,
      this.docs,
      this.on,
      this.types,
      this.methods,
      this.fields,
      this.name})
      : super._() {
    if (annotations == null) {
      throw new BuiltValueNullFieldError('Extension', 'annotations');
    }
    if (docs == null) {
      throw new BuiltValueNullFieldError('Extension', 'docs');
    }
    if (types == null) {
      throw new BuiltValueNullFieldError('Extension', 'types');
    }
    if (methods == null) {
      throw new BuiltValueNullFieldError('Extension', 'methods');
    }
    if (fields == null) {
      throw new BuiltValueNullFieldError('Extension', 'fields');
    }
  }

  @override
  Extension rebuild(void Function(ExtensionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$ExtensionBuilder toBuilder() => new _$ExtensionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Extension &&
        annotations == other.annotations &&
        docs == other.docs &&
        on == other.on &&
        types == other.types &&
        methods == other.methods &&
        fields == other.fields &&
        name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, annotations.hashCode), docs.hashCode),
                        on.hashCode),
                    types.hashCode),
                methods.hashCode),
            fields.hashCode),
        name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Extension')
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('on', on)
          ..add('types', types)
          ..add('methods', methods)
          ..add('fields', fields)
          ..add('name', name))
        .toString();
  }
}

class _$ExtensionBuilder extends ExtensionBuilder {
  _$Extension _$v;

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
  Reference get on {
    _$this;
    return super.on;
  }

  @override
  set on(Reference on) {
    _$this;
    super.on = on;
  }

  @override
  ListBuilder<Reference> get types {
    _$this;
    return super.types ??= new ListBuilder<Reference>();
  }

  @override
  set types(ListBuilder<Reference> types) {
    _$this;
    super.types = types;
  }

  @override
  ListBuilder<Method> get methods {
    _$this;
    return super.methods ??= new ListBuilder<Method>();
  }

  @override
  set methods(ListBuilder<Method> methods) {
    _$this;
    super.methods = methods;
  }

  @override
  ListBuilder<Field> get fields {
    _$this;
    return super.fields ??= new ListBuilder<Field>();
  }

  @override
  set fields(ListBuilder<Field> fields) {
    _$this;
    super.fields = fields;
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

  _$ExtensionBuilder() : super._();

  ExtensionBuilder get _$this {
    if (_$v != null) {
      super.annotations = _$v.annotations?.toBuilder();
      super.docs = _$v.docs?.toBuilder();
      super.on = _$v.on;
      super.types = _$v.types?.toBuilder();
      super.methods = _$v.methods?.toBuilder();
      super.fields = _$v.fields?.toBuilder();
      super.name = _$v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Extension other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Extension;
  }

  @override
  void update(void Function(ExtensionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Extension build() {
    _$Extension _$result;
    try {
      _$result = _$v ??
          new _$Extension._(
              annotations: annotations.build(),
              docs: docs.build(),
              on: on,
              types: types.build(),
              methods: methods.build(),
              fields: fields.build(),
              name: name);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();

        _$failedField = 'types';
        types.build();
        _$failedField = 'methods';
        methods.build();
        _$failedField = 'fields';
        fields.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Extension', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
