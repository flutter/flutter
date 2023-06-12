import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import 'redux.dart';
import 'star_wars_api.dart';

/// This handler will take care of async api interactions
/// and updating the store afterwards.
class _PlanetHandler {
  _PlanetHandler(this._store, this._starWarsApi);

  final Store<AppState, ReduxAction> _store;
  final StarWarsApi _starWarsApi;

  /// This will load all planets and will dispatch all necessary actions
  /// on the redux store.
  Future<void> fetchAndDispatch([String url]) async {
    _store.dispatch(FetchPlanetPageActionStart());
    try {
      final page = await _starWarsApi.getPlanets(url);
      _store.dispatch(FetchPlanetPageActionSuccess(page));
    } catch (e, stack) {
      print('errpr $e $stack');
      _store.dispatch(FetchPlanetPageActionError('Error loading Planets'));
    }
  }
}

/// This example will load, show and let you navigate through all star wars
/// planets.
///
/// It will demonstrate on how to use [Provider] and [useReducer]
class PlanetScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final api = useMemoized(() => StarWarsApi());

    final store = useReducer<AppState, ReduxAction>(
      reducer,
      initialState: AppState(),
      initialAction: null,
    );

    final planetHandler = useMemoized(
      () {
        /// Create planet handler and load the first page.
        /// The first page will only be loaded once, after the handler was created
        return _PlanetHandler(store, api)..fetchAndDispatch();
      },
      [store, api],
    );

    return MultiProvider(
      providers: [
        Provider.value(value: planetHandler),
        Provider.value(value: store.state),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Star Wars Planets',
          ),
        ),
        body: const _PlanetScreenBody(),
      ),
    );
  }
}

class _PlanetScreenBody extends HookWidget {
  const _PlanetScreenBody();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    if (state.isFetchingPlanets) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.planetPage.results.isEmpty) {
      return const Center(child: Text('No planets found'));
    } else if (state.errorFetchingPlanets != null) {
      return Center(
        child: _Error(
          errorMsg: state.errorFetchingPlanets,
        ),
      );
    } else {
      return _PlanetList();
    }
  }
}

class _Error extends StatelessWidget {
  const _Error({Key key, this.errorMsg}) : super(key: key);

  final String errorMsg;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (errorMsg != null) Text(errorMsg),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.redAccent),
          ),
          onPressed: () async {
            await Provider.of<_PlanetHandler>(
              context,
              listen: false,
            ).fetchAndDispatch();
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _LoadPageButton extends HookWidget {
  const _LoadPageButton({this.next = true})
      : assert(next != null, 'next cannot be null');

  final bool next;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return ElevatedButton(
      onPressed: () async {
        final url = next ? state.planetPage.next : state.planetPage.previous;
        await Provider.of<_PlanetHandler>(context, listen: false)
            .fetchAndDispatch(url);
      },
      child: next ? const Text('Next Page') : const Text('Prev Page'),
    );
  }
}

class _PlanetList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return ListView.builder(
      itemCount: 1 + state.planetPage.results.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PlanetListHeader();
        }

        final planet = state.planetPage.results[index - 1];
        return ListTile(title: Text(planet.name));
      },
    );
  }
}

class _PlanetListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    MainAxisAlignment buttonAlignment;
    if (state.planetPage.previous == null) {
      buttonAlignment = MainAxisAlignment.end;
    } else if (state.planetPage.next == null) {
      buttonAlignment = MainAxisAlignment.start;
    } else {
      buttonAlignment = MainAxisAlignment.spaceBetween;
    }

    return Row(
      mainAxisAlignment: buttonAlignment,
      children: <Widget>[
        if (state.planetPage.previous != null)
          const _LoadPageButton(next: false),
        if (state.planetPage.next != null) const _LoadPageButton()
      ],
    );
  }
}
