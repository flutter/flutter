import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import 'models.dart';

part 'redux.g.dart';

/// Actions base class
abstract class ReduxAction {}

/// Action that updates state to show that we are loading planets
class FetchPlanetPageActionStart extends ReduxAction {}

/// Action that updates state to show that we are loading planets
class FetchPlanetPageActionError extends ReduxAction {
  FetchPlanetPageActionError(this.errorMsg);

  /// Message that should be displayed in the UI
  final String errorMsg;
}

/// Action to set the planet page
class FetchPlanetPageActionSuccess extends ReduxAction {
  FetchPlanetPageActionSuccess(this.page);

  final PlanetPageModel page;
}

@immutable
abstract class AppState implements Built<AppState, AppStateBuilder> {
  factory AppState([void Function(AppStateBuilder) updates]) =>
      _$AppState((u) => u
        ..isFetchingPlanets = false
        ..update(updates));

  const AppState._();

  bool get isFetchingPlanets;

  @nullable
  String get errorFetchingPlanets;

  PlanetPageModel get planetPage;
}

AppState reducer<S extends AppState, A extends ReduxAction>(S state, A action) {
  final b = state.toBuilder();
  if (action is FetchPlanetPageActionStart) {
    b
      ..isFetchingPlanets = true
      ..planetPage = PlanetPageModelBuilder()
      ..errorFetchingPlanets = null;
  }

  if (action is FetchPlanetPageActionError) {
    b
      ..isFetchingPlanets = false
      ..errorFetchingPlanets = action.errorMsg;
  }

  if (action is FetchPlanetPageActionSuccess) {
    b
      ..isFetchingPlanets = false
      ..planetPage.replace(action.page);
  }

  return b.build();
}
