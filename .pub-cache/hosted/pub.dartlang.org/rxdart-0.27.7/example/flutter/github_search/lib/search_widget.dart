import 'package:flutter/material.dart';

import 'empty_result_widget.dart';
import 'github_api.dart';
import 'search_bloc.dart';
import 'search_error_widget.dart';
import 'search_intro_widget.dart';
import 'search_loading_widget.dart';
import 'search_result_widget.dart';
import 'search_state.dart';

// The View in a Stream-based architecture takes two arguments: The State Stream
// and the onTextChanged callback. In our case, the onTextChanged callback will
// emit the latest String to a Stream<String> whenever it is called.
//
// The State will use the Stream<String> to send new search requests to the
// GithubApi.
class SearchScreen extends StatefulWidget {
  final GithubApi api;

  const SearchScreen({Key? key, required this.api}) : super(key: key);

  @override
  SearchScreenState createState() {
    return SearchScreenState();
  }
}

class SearchScreenState extends State<SearchScreen> {
  late final SearchBloc bloc;

  @override
  void initState() {
    super.initState();

    bloc = SearchBloc(widget.api);
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SearchState>(
      stream: bloc.state,
      initialData: SearchNoTerm(),
      builder: (BuildContext context, AsyncSnapshot<SearchState> snapshot) {
        final state = snapshot.requireData;

        return Scaffold(
          body: Stack(
            children: <Widget>[
              Flex(direction: Axis.vertical, children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 4.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search Github...',
                    ),
                    style: const TextStyle(
                      fontSize: 36.0,
                      fontFamily: 'Hind',
                      decoration: TextDecoration.none,
                    ),
                    onChanged: bloc.onTextChanged.add,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildChild(state),
                  ),
                )
              ])
            ],
          ),
        );
      },
    );
  }

  Widget _buildChild(SearchState state) {
    if (state is SearchNoTerm) {
      return const SearchIntro();
    } else if (state is SearchEmpty) {
      return const EmptyWidget();
    } else if (state is SearchLoading) {
      return const LoadingWidget();
    } else if (state is SearchError) {
      return const SearchErrorWidget();
    } else if (state is SearchPopulated) {
      return SearchResultWidget(items: state.result.items);
    }

    throw Exception('${state.runtimeType} is not supported');
  }
}
