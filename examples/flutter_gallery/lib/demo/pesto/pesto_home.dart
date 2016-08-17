// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

import 'pesto_data.dart';

const String _kUserName = 'Jonathan';
const String _kUserEmail = 'jonathan@example.com';
const String _kUserImage = 'packages/flutter_gallery_assets/pesto/avatar.jpg';
const String _kSmallLogoImage = 'packages/flutter_gallery_assets/pesto/logo_small.png';
const String _kMediumLogoImage = 'packages/flutter_gallery_assets/pesto/logo_medium.png';
const double _kAppBarHeight = 128.0;
const double _kRecipePageMaxWidth = 500.0;

final Set<Recipe> _favoriteRecipes = new Set<Recipe>();

final ThemeData _kTheme = new ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.teal,
  accentColor: Colors.redAccent[200]
);

class PestoHome extends StatelessWidget {
  static final GlobalKey<ScrollableState> scrollableKey = new GlobalKey<ScrollableState>();

  @override
  Widget build(BuildContext context) {
    return new RecipeGridPage(recipes: kPestoRecipes, scrollableKey: scrollableKey);
  }
}

class PestoFavorites extends StatelessWidget {
  static final GlobalKey<ScrollableState> scrollableKey = new GlobalKey<ScrollableState>();

  @override
  Widget build(BuildContext context) {
    return new RecipeGridPage(recipes: _favoriteRecipes.toList(), scrollableKey: scrollableKey);
  }
}

class PestoStyle extends TextStyle {
  const PestoStyle({
    double fontSize: 12.0,
    FontWeight fontWeight,
    Color color: Colors.black87,
    double height
  }) : super(
    inherit: false,
    color: color,
    fontFamily: 'Raleway',
    fontSize: fontSize,
    fontWeight: fontWeight,
    textBaseline: TextBaseline.alphabetic,
    height: height
  );
}

// Displays a grid of recipe cards.
class RecipeGridPage extends StatefulWidget {
  RecipeGridPage({ Key key, this.recipes, this.scrollableKey }) : super(key: key);

  final List<Recipe> recipes;
  final GlobalKey<ScrollableState> scrollableKey;

  @override
  _RecipeGridPageState createState() => new _RecipeGridPageState();
}

class _RecipeGridPageState extends State<RecipeGridPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextStyle favoritesMessageStyle = const PestoStyle(fontSize: 16.0);
  final TextStyle userStyle = const PestoStyle(fontWeight: FontWeight.bold);
  final TextStyle emailStyle = const PestoStyle(color: Colors.black54);

  bool showFavorites = false;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Theme(
      data: _kTheme,
      child: new Scaffold(
        key: scaffoldKey,
        scrollableKey: config.scrollableKey,
        appBarBehavior: AppBarBehavior.under,
        appBar: buildAppBar(context, statusBarHeight),
        drawer: buildDrawer(context),
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.edit),
          onPressed: () { }
        ),
        body: buildBody(context, statusBarHeight)
      )
    );
  }

  Widget buildAppBar(BuildContext context, double statusBarHeight) {
    return new AppBar(
      expandedHeight: _kAppBarHeight,
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            scaffoldKey.currentState.showSnackBar(new SnackBar(
              content: new Text('Not supported.')
            ));
          }
        )
      ],
      flexibleSpace: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;
          final double appBarHeight = size.height - statusBarHeight;
          final String logo = appBarHeight >= 70.0 ? _kMediumLogoImage : _kSmallLogoImage;
          // Extra padding. Calculated to give about 16px on the bottom for the
          // `small` logo at its native size, and 30px for the `medium`.
          final double extraPadding = min(0.19 * appBarHeight + 5.4, 40.0);
          return new Padding(
            padding: new EdgeInsets.only(
              top: statusBarHeight + 0.5 * extraPadding,
              bottom: extraPadding
            ),
            child: new Center(
              child: new Image.asset(logo, fit: ImageFit.scaleDown)
            )
          );
        }
      )
    );
  }

  Widget buildDrawer(BuildContext context) {
    return new Drawer(
      child: new Block(
        children: <Widget>[
          new DrawerHeader(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Container(
                  decoration: new BoxDecoration(
                    border: new Border.all(color: _kTheme.primaryColor, width: 2.0),
                    shape: BoxShape.circle
                  ),
                  width: 72.0,
                  height: 72.0,
                  padding: const EdgeInsets.all(2.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: new ClipOval(
                    child: new Image.asset(_kUserImage, fit: ImageFit.contain)
                  )
                ),
                new Text(_kUserName, style: userStyle),
                new Text(_kUserEmail, style: emailStyle)
              ]
            )
          ),
          new DrawerItem(
            child: new Text('Home'),
            selected: !showFavorites,
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/pesto'));
            }
          ),
          new DrawerItem(
            child: new Text('Favorites'),
            selected: showFavorites,
            onPressed: () {
              if (showFavorites)
                Navigator.pop(context);
              else
                showFavoritesPage(context);
            }
          ),
          new Divider(),
          new DrawerItem(
            child: new Text('Return to Gallery'),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            }
          ),
        ]
      )
    );
  }

  Widget buildBody(BuildContext context, double statusBarHeight) {
    final EdgeInsets padding = new EdgeInsets.fromLTRB(8.0, 8.0 + _kAppBarHeight + statusBarHeight, 8.0, 8.0);

    if (config.recipes.isEmpty) {
      return new Padding(
        padding: padding,
        child: new Text('Save your favorite recipes to see them here.', style: favoritesMessageStyle)
      );
    }

    return new ScrollableGrid(
      scrollableKey: config.scrollableKey,
      delegate: new MaxTileWidthGridDelegate(
        maxTileWidth: _kRecipePageMaxWidth,
        rowSpacing: 8.0,
        columnSpacing: 8.0,
        padding: padding
      ),
      children: config.recipes.map((Recipe recipe) {
        return new RecipeCard(
          recipe: recipe,
          onTap: () { showRecipePage(context, recipe); }
        );
      })
    );
  }

  void showFavoritesPage(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      settings: const RouteSettings(name: "/pesto/favorites"),
      builder: (BuildContext context) => new PestoFavorites()
    ));
  }

  void showRecipePage(BuildContext context, Recipe recipe) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      settings: const RouteSettings(name: "/pesto/recipe"),
      builder: (BuildContext context) {
        return new Theme(
          data: _kTheme,
          child: new RecipePage(recipe: recipe)
        );
      }
    ));
  }
}

// A card with the recipe's image, author, and title.
class RecipeCard extends StatelessWidget {
  final TextStyle titleStyle = const PestoStyle(fontSize: 24.0, fontWeight: FontWeight.w600);
  final TextStyle authorStyle = const PestoStyle(fontWeight: FontWeight.w500, color: Colors.black54);

  RecipeCard({ Key key, this.recipe, this.onTap }) : super(key: key);

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: onTap,
      child: new Card(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Hero(
              tag: recipe.imagePath,
              child: new Image.asset(recipe.imagePath, fit: ImageFit.contain)
            ),
            new Flexible(
              child: new Row(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new Image.asset(
                      recipe.ingredientsImagePath,
                      width: 48.0,
                      height: 48.0
                    )
                  ),
                  new Flexible(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Text(recipe.name, style: titleStyle, softWrap: false, overflow: TextOverflow.ellipsis),
                        new Text(recipe.author, style: authorStyle),
                      ]
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}

// Displays one recipe. Includes the recipe sheet with a background image.
class RecipePage extends StatefulWidget {
  RecipePage({ Key key, this.recipe }) : super(key: key);

  final Recipe recipe;

  @override
  _RecipePageState createState() => new _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScrollableState> _scrollableKey = new GlobalKey<ScrollableState>();
  final TextStyle menuItemStyle = new PestoStyle(fontSize: 15.0, color: Colors.black54, height: 24.0/15.0);

  double _getAppBarHeight(BuildContext context) => MediaQuery.of(context).size.height * 0.3;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      scrollableKey: _scrollableKey,
      appBarBehavior: AppBarBehavior.scroll,
      appBar: new AppBar(
        expandedHeight: _getAppBarHeight(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back'
        ),
        actions: <Widget>[
          new PopupMenuButton<String>(
            onSelected: (String item) {},
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              _buildMenuItem(Icons.share, 'Tweet recipe'),
              _buildMenuItem(Icons.email, 'Email recipe'),
              _buildMenuItem(Icons.message, 'Message recipe'),
              _buildMenuItem(Icons.people, 'Share on Facebook'),
            ]
          )
        ],
        // This empty space keeps the app bar from moving until the screen is
        // scrolled at least _getAppBarHeight().
        flexibleSpace: new Container()
      ),
      body: _buildContainer(context)
    );
  }

  // The full page content with the recipe's image behind it. This
  // adjusts based on the size of the screen. If the recipe sheet touches
  // the edge of the screen, use a slightly different layout.
  Widget _buildContainer(BuildContext context) {
    final bool isFavorite = _favoriteRecipes.contains(config.recipe);
    final Size screenSize = MediaQuery.of(context).size;
    final bool fullWidth = (screenSize.width < _kRecipePageMaxWidth);
    final double appBarHeight = _getAppBarHeight(context);
    const double fabHalfSize = 28.0;  // TODO(mpcomplete): needs to adapt to screen size
    return new Stack(
      children: <Widget>[
        new Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          height: appBarHeight + fabHalfSize,
          child: new Hero(
            tag: config.recipe.imagePath,
            child: new Image.asset(
              config.recipe.imagePath,
              fit: fullWidth ? ImageFit.fitWidth : ImageFit.cover
            )
          )
        ),
        new ClampOverscrolls(
          value: true,
          child: new ScrollableViewport(
            scrollableKey: _scrollableKey,
            child: new RepaintBoundary(
              child: new Padding(
                padding: new EdgeInsets.only(top: appBarHeight),
                child: new Stack(
                  children: <Widget>[
                    new Padding(
                      padding: new EdgeInsets.only(top: fabHalfSize),
                      child: new SizedBox(
                        width: fullWidth ? null : _kRecipePageMaxWidth,
                        child: new RecipeSheet(recipe: config.recipe)
                      )
                    ),
                    new Positioned(
                      right: 16.0,
                      child: new FloatingActionButton(
                        child: new Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        onPressed: _toggleFavorite
                      )
                    )
                  ]
                )
              )
            )
          )
        )
      ]
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String label) {
    return new PopupMenuItem<String>(
      child: new Row(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: new Icon(icon, color: Colors.black54)
          ),
          new Text(label, style: menuItemStyle)
        ]
      )
    );
  }

  void _toggleFavorite() {
    setState(() {
      if (_favoriteRecipes.contains(config.recipe))
        _favoriteRecipes.remove(config.recipe);
      else
        _favoriteRecipes.add(config.recipe);
    });
  }
}

/// Displays the recipe's name and instructions.
class RecipeSheet extends StatelessWidget {
  final TextStyle titleStyle = const PestoStyle(fontSize: 34.0);
  final TextStyle descriptionStyle = const PestoStyle(fontSize: 15.0, color: Colors.black54, height: 24.0/15.0);
  final TextStyle itemStyle = const PestoStyle(fontSize: 15.0, height: 24.0/15.0);
  final TextStyle itemAmountStyle = new PestoStyle(fontSize: 15.0, color: _kTheme.primaryColor, height: 24.0/15.0);
  final TextStyle headingStyle = const PestoStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);

  RecipeSheet({ Key key, this.recipe }) : super(key: key);

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        child: new Table(
          columnWidths: <int, TableColumnWidth>{
            0: const FixedColumnWidth(64.0)
          },
          children: <TableRow>[
            new TableRow(
              children: <Widget>[
                new TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: new Image.asset(
                    recipe.ingredientsImagePath,
                    width: 32.0,
                    height: 32.0,
                    alignment: FractionalOffset.centerLeft,
                    fit: ImageFit.scaleDown
                  )
                ),
                new TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: new Text(recipe.name, style: titleStyle)
                ),
              ]
            ),
            new TableRow(
              children: <Widget>[
                new SizedBox(),
                new Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: new Text(recipe.description, style: descriptionStyle)
                ),
              ]
            ),
            new TableRow(
              children: <Widget>[
                new SizedBox(),
                new Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 4.0),
                  child: new Text('Ingredients', style: headingStyle)
                ),
              ]
            ),
          ]..addAll(recipe.ingredients.map(
            (RecipeIngredient ingredient) {
              return _buildItemRow(ingredient.amount, ingredient.description);
            }
          ))..add(
            new TableRow(
              children: <Widget>[
                new SizedBox(),
                new Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 4.0),
                  child: new Text('Steps', style: headingStyle)
                ),
              ]
            )
          )..addAll(recipe.steps.map(
            (RecipeStep step) {
              return _buildItemRow(step.duration ?? '', step.description);
            }
          ))
        )
      )
    );
  }

  TableRow _buildItemRow(String left, String right) {
    return new TableRow(
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: new Text(left, style: itemAmountStyle)
        ),
        new Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: new Text(right, style: itemStyle)
        )
      ]
    );
  }
}
