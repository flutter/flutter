import 'package:flutter/material.dart';

/// Flutter code sample for [RefreshIndicator.noSpinner].

void main() => runApp(const RefreshIndicatorExampleApp());

class RefreshIndicatorExampleApp extends StatelessWidget {
  const RefreshIndicatorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RefreshIndicatorExample(),
    );
  }
}

class RefreshIndicatorExample extends StatelessWidget {
  const RefreshIndicatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RefreshIndicator.noSpinner Sample'),
      ),
      body: RefreshIndicator.noSpinner(
        // Callback function used by the app to listen to the
        // status of the RefreshIndicator pull-down action.
        onStatusChange: (RefreshIndicatorStatus? status) {
          print('RefreshIndicatorStatus was updated to: $status');

          // Do something when the status changes
        },
        onRefresh: () async {
          print('RefreshIndicator was called!');

          // Replace this delay with the code to be executed during refresh
          // and return asynchronous code
          return Future<void>.delayed(const Duration(seconds: 3));
        },

        // This check is used to customize listening to scroll notifications
        // from the widget's children.
        //
        // By default this is set to `notification.depth == 0`, which ensures
        // the only the scroll notifications from the first scroll view are listened to.
        //
        // Here setting `notification.depth == 1` triggers the refresh indicator
        // when overscrolling the nested scroll view.
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 1;
        },

        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 100,
                alignment: Alignment.center,
                color: Colors.pink[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Pull down here',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text("RefreshIndicator won't trigger"),
                  ],
                ),
              ),
              Container(
                color: Colors.green[100],
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 25,
                  itemBuilder: (BuildContext context, int index) {
                    return const ListTile(
                      title: Text('Pull down here'),
                      subtitle: Text('RefreshIndicator will trigger'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
