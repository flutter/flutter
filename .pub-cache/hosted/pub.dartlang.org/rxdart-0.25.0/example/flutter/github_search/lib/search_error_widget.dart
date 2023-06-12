import 'package:flutter/material.dart';

class SearchErrorWidget extends StatelessWidget {
  const SearchErrorWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: FractionalOffset.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, color: Colors.red[300], size: 80.0),
          Container(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              "Rate limit exceeded",
              style: TextStyle(
                color: Colors.red[300],
              ),
            ),
          )
        ],
      ),
    );
  }
}
