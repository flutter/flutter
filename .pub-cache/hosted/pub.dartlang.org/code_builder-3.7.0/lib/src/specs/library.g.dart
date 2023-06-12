// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Library extends Library {
  @override
  final BuiltList<Directive> directives;
  @override
  final BuiltList<Spec> body;

  factory _$Library([void Function(LibraryBuilder) updates]) =>
      (new LibraryBuilder()..update(updates)).build() as _$Library;

  _$Library._({this.directives, this.body}) : super._() {
    if (directives == null) {
      throw new BuiltValueNullFieldError('Library', 'directives');
    }
    if (body == null) {
      throw new BuiltValueNullFieldError('Library', 'body');
    }
  }

  @override
  Library rebuild(void Function(LibraryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$LibraryBuilder toBuilder() => new _$LibraryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Library &&
        directives == other.directives &&
        body == other.body;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, directives.hashCode), body.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Library')
          ..add('directives', directives)
          ..add('body', body))
        .toString();
  }
}

class _$LibraryBuilder extends LibraryBuilder {
  _$Library _$v;

  @override
  ListBuilder<Directive> get directives {
    _$this;
    return super.directives ??= new ListBuilder<Directive>();
  }

  @override
  set directives(ListBuilder<Directive> directives) {
    _$this;
    super.directives = directives;
  }

  @override
  ListBuilder<Spec> get body {
    _$this;
    return super.body ??= new ListBuilder<Spec>();
  }

  @override
  set body(ListBuilder<Spec> body) {
    _$this;
    super.body = body;
  }

  _$LibraryBuilder() : super._();

  LibraryBuilder get _$this {
    if (_$v != null) {
      super.directives = _$v.directives?.toBuilder();
      super.body = _$v.body?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Library other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Library;
  }

  @override
  void update(void Function(LibraryBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Library build() {
    _$Library _$result;
    try {
      _$result = _$v ??
          new _$Library._(directives: directives.build(), body: body.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'directives';
        directives.build();
        _$failedField = 'body';
        body.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Library', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
