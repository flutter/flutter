// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redux.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppState extends AppState {
  @override
  final bool isFetchingPlanets;
  @override
  final String errorFetchingPlanets;
  @override
  final PlanetPageModel planetPage;

  factory _$AppState([void Function(AppStateBuilder) updates]) =>
      (new AppStateBuilder()..update(updates))._build();

  _$AppState._(
      {this.isFetchingPlanets, this.errorFetchingPlanets, this.planetPage})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        isFetchingPlanets, r'AppState', 'isFetchingPlanets');
    BuiltValueNullFieldError.checkNotNull(
        planetPage, r'AppState', 'planetPage');
  }

  @override
  AppState rebuild(void Function(AppStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppStateBuilder toBuilder() => new AppStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppState &&
        isFetchingPlanets == other.isFetchingPlanets &&
        errorFetchingPlanets == other.errorFetchingPlanets &&
        planetPage == other.planetPage;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, isFetchingPlanets.hashCode), errorFetchingPlanets.hashCode),
        planetPage.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppState')
          ..add('isFetchingPlanets', isFetchingPlanets)
          ..add('errorFetchingPlanets', errorFetchingPlanets)
          ..add('planetPage', planetPage))
        .toString();
  }
}

class AppStateBuilder implements Builder<AppState, AppStateBuilder> {
  _$AppState _$v;

  bool _isFetchingPlanets;
  bool get isFetchingPlanets => _$this._isFetchingPlanets;
  set isFetchingPlanets(bool isFetchingPlanets) =>
      _$this._isFetchingPlanets = isFetchingPlanets;

  String _errorFetchingPlanets;
  String get errorFetchingPlanets => _$this._errorFetchingPlanets;
  set errorFetchingPlanets(String errorFetchingPlanets) =>
      _$this._errorFetchingPlanets = errorFetchingPlanets;

  PlanetPageModelBuilder _planetPage;
  PlanetPageModelBuilder get planetPage =>
      _$this._planetPage ??= new PlanetPageModelBuilder();
  set planetPage(PlanetPageModelBuilder planetPage) =>
      _$this._planetPage = planetPage;

  AppStateBuilder();

  AppStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _isFetchingPlanets = $v.isFetchingPlanets;
      _errorFetchingPlanets = $v.errorFetchingPlanets;
      _planetPage = $v.planetPage.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppState other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AppState;
  }

  @override
  void update(void Function(AppStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  AppState build() => _build();

  _$AppState _build() {
    _$AppState _$result;
    try {
      _$result = _$v ??
          new _$AppState._(
              isFetchingPlanets: BuiltValueNullFieldError.checkNotNull(
                  isFetchingPlanets, r'AppState', 'isFetchingPlanets'),
              errorFetchingPlanets: errorFetchingPlanets,
              planetPage: planetPage.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'planetPage';
        planetPage.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'AppState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
