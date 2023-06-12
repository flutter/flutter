// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Field extends Field {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final Code assignment;
  @override
  final bool static;
  @override
  final String name;
  @override
  final Reference type;
  @override
  final FieldModifier modifier;

  factory _$Field([void Function(FieldBuilder) updates]) =>
      (new FieldBuilder()..update(updates)).build() as _$Field;

  _$Field._(
      {this.annotations,
      this.docs,
      this.assignment,
      this.static,
      this.name,
      this.type,
      this.modifier})
      : super._() {
    if (annotations == null) {
      throw new BuiltValueNullFieldError('Field', 'annotations');
    }
    if (docs == null) {
      throw new BuiltValueNullFieldError('Field', 'docs');
    }
    if (static == null) {
      throw new BuiltValueNullFieldError('Field', 'static');
    }
    if (name == null) {
      throw new BuiltValueNullFieldError('Field', 'name');
    }
    if (modifier == null) {
      throw new BuiltValueNullFieldError('Field', 'modifier');
    }
  }

  @override
  Field rebuild(void Function(FieldBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$FieldBuilder toBuilder() => new _$FieldBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Field &&
        annotations == other.annotations &&
        docs == other.docs &&
        assignment == other.assignment &&
        static == other.static &&
        name == other.name &&
        type == other.type &&
        modifier == other.modifier;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, annotations.hashCode), docs.hashCode),
                        assignment.hashCode),
                    static.hashCode),
                name.hashCode),
            type.hashCode),
        modifier.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Field')
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('assignment', assignment)
          ..add('static', static)
          ..add('name', name)
          ..add('type', type)
          ..add('modifier', modifier))
        .toString();
  }
}

class _$FieldBuilder extends FieldBuilder {
  _$Field _$v;

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
  Code get assignment {
    _$this;
    return super.assignment;
  }

  @override
  set assignment(Code assignment) {
    _$this;
    super.assignment = assignment;
  }

  @override
  bool get static {
    _$this;
    return super.static;
  }

  @override
  set static(bool static) {
    _$this;
    super.static = static;
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
  Reference get type {
    _$this;
    return super.type;
  }

  @override
  set type(Reference type) {
    _$this;
    super.type = type;
  }

  @override
  FieldModifier get modifier {
    _$this;
    return super.modifier;
  }

  @override
  set modifier(FieldModifier modifier) {
    _$this;
    super.modifier = modifier;
  }

  _$FieldBuilder() : super._();

  FieldBuilder get _$this {
    if (_$v != null) {
      super.annotations = _$v.annotations?.toBuilder();
      super.docs = _$v.docs?.toBuilder();
      super.assignment = _$v.assignment;
      super.static = _$v.static;
      super.name = _$v.name;
      super.type = _$v.type;
      super.modifier = _$v.modifier;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Field other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Field;
  }

  @override
  void update(void Function(FieldBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Field build() {
    _$Field _$result;
    try {
      _$result = _$v ??
          new _$Field._(
              annotations: annotations.build(),
              docs: docs.build(),
              assignment: assignment,
              static: static,
              name: name,
              type: type,
              modifier: modifier);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Field', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
