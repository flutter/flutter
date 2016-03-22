import 'package:flutter/material.dart';

typedef Widget GalleryDemoBuilder();

class GalleryItem extends StatelessWidget {
  GalleryItem({ this.title, this.icon, this.builder });

  final String title;
  final IconData icon;
  final GalleryDemoBuilder builder;

  @override
  Widget build(BuildContext context) {
    Widget leading = icon == null ? new Container() : new Icon(icon: icon);

    return new TwoLevelListItem(
      leading: leading,
      title: new Text(title),
      onTap: () {
        if (builder != null) {
          Navigator.push(context, new MaterialPageRoute<Null>(
            builder: (BuildContext context) => builder()
          ));
        }
      }
    );
  }
}
