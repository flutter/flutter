import 'package:flutter/material.dart';
import 'package:github_search/github_api.dart';
import 'package:github_search/search_widget.dart';

void main() {
  runApp(SearchApp(api: GithubApi()));
}

class SearchApp extends StatefulWidget {
  final GithubApi api;

  SearchApp({Key key, this.api}) : super(key: key);

  @override
  _RxDartGithubSearchAppState createState() => _RxDartGithubSearchAppState();
}

class _RxDartGithubSearchAppState extends State<SearchApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RxDart Github Search',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
      ),
      home: SearchScreen(api: widget.api),
    );
  }
}
