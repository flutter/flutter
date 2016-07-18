// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

const String _kUserName = 'Jonathan';
const String _kUserEmail = 'heyfromjonathan@gmail.com';
const String _kUserImage = 'packages/flutter_gallery_assets/pesto/avatar.jpg';
// Map of logo images keyed by the minimum height their container needs to be.
final Map<double, String> _kLogoImages = <double, String>{
  0.0: 'packages/flutter_gallery_assets/pesto/logo_small.png',
  70.0: 'packages/flutter_gallery_assets/pesto/logo_medium.png',
  170.0: 'packages/flutter_gallery_assets/pesto/logo_big.png',
};

final ThemeData _kTheme = new ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.teal,
  accentColor: Colors.redAccent[200]
);
const String _kFontFace = 'Raleway';
const double _kAppBarHeight = 128.0;
const double _kRecipePageMaxWidth = 500.0;

Set<Recipe> favoriteRecipes = new Set<Recipe>();

// Helper for common Pesto text style properties.
TextStyle _textStyle(double size, [FontWeight fontWeight]) {
  return new TextStyle(
    inherit: false,
    fontSize: size,
    fontWeight: fontWeight,
    fontFamily: 'Raleway',
    color: Colors.black87,
    textBaseline: TextBaseline.alphabetic
  );
}

class PestoDemo extends StatefulWidget {
  PestoDemo({ Key key, this.showFavorites: false }) : super(key: key);

  static const String routeName = '/pesto';

  final bool showFavorites;

  @override
  _PestoDemoState createState() => new _PestoDemoState();
}

class _PestoDemoState extends State<PestoDemo> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextStyle favoritesMessageStyle = _textStyle(16.0);
  final TextStyle userStyle = _textStyle(12.0, FontWeight.bold);
  final TextStyle emailStyle = _textStyle(12.0).copyWith(color: Colors.black54);

  @override
  Widget build(BuildContext context) {
    return new Theme(
      data: _kTheme,
      child: new Scaffold(
        key: _scaffoldKey,
        appBarBehavior: AppBarBehavior.under,
        appBar: _buildAppBar(context),
        drawer: _buildDrawer(context),
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.edit),
          onPressed: () { }
        ),
        body: _buildBody(context)
      )
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new AppBar(
      expandedHeight: _kAppBarHeight,
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            _scaffoldKey.currentState.showSnackBar(new SnackBar(
              content: new Text('Not supported.')
            ));
          }
        )
      ],
      flexibleSpace: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;
          double appBarHeight = size.height - statusBarHeight;
          double bestHeight = _kLogoImages.keys.lastWhere(
            (double height) => appBarHeight >= height
          );
          // Extra padding. Calculated to give about 16px on the bottom for the
          // `small` logo at its native size, and 30px for the `medium`.
          double extraPadding = min(0.19 * appBarHeight + 5.4, 40.0);
          return new Padding(
            padding: new EdgeInsets.only(
              top: statusBarHeight + 0.5 * extraPadding,
              bottom: extraPadding
            ),
            child: new Center(
              child: new Image(
                image: new AssetImage(_kLogoImages[bestHeight]),
                fit: ImageFit.scaleDown
              )
            )
          );
        }
      )
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
      child: new Block(
        children: <Widget>[
          new DrawerHeader(
            content: new Column(
              children: <Widget>[
                new Container(
                  decoration: new BoxDecoration(
                    border: new Border.all(color: _kTheme.primaryColor, width: 2.0),
                    shape: BoxShape.circle
                  ),
                  width: 72.0,
                  height: 72.0,
                  padding: const EdgeInsets.all(2.0),
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: new ClipOval(
                    child: new Image(
                      image: new AssetImage(_kUserImage),
                      fit: ImageFit.contain
                    )
                  )
                ),
                new Text(_kUserName, style: userStyle),
                new Text(_kUserEmail, style: emailStyle)
              ]
            )
          ),
          new DrawerItem(
            child: new Text('Home'),
            selected: !config.showFavorites,
            onPressed: () => Navigator.pushNamed(context, PestoDemo.routeName)
          ),
          new DrawerItem(
            child: new Text('Favorites'),
            selected: config.showFavorites,
            onPressed: () { _showFavorites(context); }
          ),
          new Divider(),
          new DrawerItem(
            child: new Text('Return to Gallery'),
            onPressed: () {
              Navigator.of(context)
                ..pop()  // Close the drawer.
                ..pop();  // Go back to the gallery.
            }
          ),
        ]
      )
    );
  }

  Widget _buildBody(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    List<Recipe> recipes = config.showFavorites ? favoriteRecipes.toList() : kRecipes;
    final EdgeInsets padding = new EdgeInsets.fromLTRB(8.0, 8.0 + _kAppBarHeight + statusBarHeight, 8.0, 8.0);

    if (config.showFavorites && recipes.isEmpty) {
      return new Padding(
        padding: padding,
        child: new Text('Save your favorite recipes to see them here.', style: favoritesMessageStyle)
      );
    }

    return new ScrollableGrid(
      delegate: new MaxTileWidthGridDelegate(
        maxTileWidth: 500.0,
        rowSpacing: 8.0,
        columnSpacing: 8.0,
        padding: padding
      ),
      children: recipes.map(
        (Recipe recipe) => new _RecipeCard(
          recipe: recipe,
          onTap: () { _showRecipe(context, recipe); }
        )
      )
    );
  }

  void _showFavorites(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new PestoDemo(showFavorites: true);
      }
    ));
  }

  void _showRecipe(BuildContext context, Recipe recipe) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Theme(
          data: _kTheme,
          child: new _RecipePage(recipe: recipe)
        );
      }
    ));
  }
}

/// A short recipe card to be displayed in a grid.
class _RecipeCard extends StatelessWidget {
  final TextStyle titleStyle = _textStyle(24.0, FontWeight.w600);
  final TextStyle authorStyle = _textStyle(12.0, FontWeight.w500).copyWith(color: Colors.black54);

  _RecipeCard({ Key key, this.recipe, this.onTap }) : super(key: key);

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: onTap,
      child: new Hero(
        tag: recipe.imagePath,
        child: new Card(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Image(
                image: new AssetImage(recipe.imagePath),
                fit: ImageFit.contain
              ),
              new Flexible(
                child: new Row(
                  children: <Widget>[
                    new Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: new Image(
                        image: new AssetImage(recipe.ingredientsImagePath),
                        width: 48.0,
                        height: 48.0
                      )
                    ),
                    new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Text(recipe.name, style: titleStyle),
                        new Text(recipe.author, style: authorStyle),
                      ]
                    )
                  ]
                )
              )
            ]
          )
        )
      )
    );
  }
}

/// A page displaying a single recipe. Includes the recipe sheet with a
/// background image.
class _RecipePage extends StatefulWidget {
  _RecipePage({ Key key, this.recipe }) : super(key: key);

  final Recipe recipe;

  @override
  _RecipePageState createState() => new _RecipePageState();
}

class _RecipePageState extends State<_RecipePage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextStyle menuItemStyle = _textStyle(15.0).copyWith(color: Colors.black54, height: 24.0/15.0);

  double _getAppBarHeight(BuildContext context) => MediaQuery.of(context).size.height * 0.3;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
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
    bool isFavorite = favoriteRecipes.contains(config.recipe);
    Size screenSize = MediaQuery.of(context).size;
    bool fullWidth = (screenSize.width < _kRecipePageMaxWidth);
    const double fabHalfSize = 28.0;  // TODO(mpcomplete): needs to adapt to screen size
    return new Hero(
      tag: config.recipe.imagePath,
      child: new DecoratedBox(
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(context).canvasColor,
          backgroundImage: new BackgroundImage(
            image: new AssetImage(config.recipe.imagePath),
            alignment: FractionalOffset.topCenter,
            fit: fullWidth ? ImageFit.fitWidth : ImageFit.cover
          )
        ),
        child: new Align(
          alignment: FractionalOffset.bottomCenter,
          child: new Block(
            children: <Widget>[
              new Padding(
                padding: new EdgeInsets.only(top: _getAppBarHeight(context)),
                child: new Stack(
                  children: <Widget>[
                    new Padding(
                      padding: new EdgeInsets.only(top: fabHalfSize),
                      child: new SizedBox(
                        width: fullWidth ? null : _kRecipePageMaxWidth,
                        child: new _RecipeSheet(recipe: config.recipe)
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
            ]
          )
        )
      )
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
      if (favoriteRecipes.contains(config.recipe))
        favoriteRecipes.remove(config.recipe);
      else
        favoriteRecipes.add(config.recipe);
    });
  }
}

/// The sheet with the recipe name and instructions.
class _RecipeSheet extends StatelessWidget {
  final TextStyle titleStyle = _textStyle(34.0);
  final TextStyle descriptionStyle = _textStyle(15.0).copyWith(color: Colors.black54, height: 24.0/15.0);
  final TextStyle itemStyle = _textStyle(15.0).copyWith(height: 24.0/15.0);
  final TextStyle itemAmountStyle = _textStyle(15.0).copyWith(color: _kTheme.primaryColor, height: 24.0/15.0);
  final TextStyle headingStyle = _textStyle(15.0).copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);

  _RecipeSheet({ Key key, this.recipe }) : super(key: key);

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
                  child: new Image(
                    image: new AssetImage(recipe.ingredientsImagePath),
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

// Data models for the UI.

class Recipe {
  const Recipe({
    this.name,
    this.author,
    this.description,
    this.imagePath,
    this.ingredientsImagePath,
    this.ingredients,
    this.steps
  });

  final String name;
  final String author;
  final String description;
  final String imagePath;
  final String ingredientsImagePath;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
}

class RecipeIngredient {
  const RecipeIngredient({this.amount, this.description});

  final String amount;
  final String description;
}

class RecipeStep {
  const RecipeStep({this.duration, this.description});

  final String duration;
  final String description;
}

final List<Recipe> kRecipes = <Recipe>[
  const Recipe(
    name: 'Pesto Bruchetta',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/quick.png',
    description: 'Bask in greens this season by trying this delightful take on traditional bruschetta. Top with a dollop of homemade pesto, and season with freshly ground sea salt and pepper.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image1.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '6 pieces', description: 'Mozzarella cheese'),
      const RecipeIngredient(amount: '6 pieces', description: 'Toasts'),
      const RecipeIngredient(amount: '⅔ cup', description: 'Homemade pesto'),
      const RecipeIngredient(amount: '1tbsp', description: 'Freshly ground pepper'),
      const RecipeIngredient(amount: '1 tsp', description: 'Salt'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(description: 'Put in oven'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Rustic purple mash',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/veggie.png',
    description: 'Abundant in color, and healthy, delicious goodness, cooking with these South American purple potatoes is a treat. Boil, mash, bake, or roast them. For taste cook with chicken stock, and a dash of extra virgin olive oil.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image2.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '2 lbs', description: 'Purple potatoes, skin on'),
      const RecipeIngredient(amount: '1 tsp', description: 'Salt'),
      const RecipeIngredient(amount: '2 tsp', description: 'Lemon'),
      const RecipeIngredient(amount: '4 cups', description: 'Chicken stock'),
      const RecipeIngredient(amount: '1tbsp', description: 'Extra virgin olive oil')
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Bacon Sprouts',
    author: 'Ali Connors',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/main.png',
    description: 'This beautiful sprouts recipe is the most glorious side dish on a cold winter’s night. Construct it with bacon or fake-on, but always make sure the sprouts are deliciously seasoned and appropriately sautéed.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image3.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '2 lbs', description: 'Brussel sprouts'),
      const RecipeIngredient(amount: '3 lbs', description: 'Bacon'),
      const RecipeIngredient(amount: '⅔ cup', description: 'Shaved parmesan cheese'),
      const RecipeIngredient(amount: '1tbsp', description: 'Extra virgin olive oil'),
      const RecipeIngredient(amount: '1 tsp', description: 'Lemon juice'),
      const RecipeIngredient(amount: '1/2 cup', description: 'Sun dried tomatoes'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Oven Sausage',
    author: 'Sandra Adams',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/meat.png',
    description: 'Robust cuts of portuguese sausage add layers of flavour. Bake or fry until sausages are slightly browned and with a crispy skin. Serve warm and with cuts of pineapple for a delightful mix of sweet and savory flavour. This is the perfect dish after a swim in the sea.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image4.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1 1/2 lbs', description: 'Linguisa'),
      const RecipeIngredient(amount: '1 lbs', description: 'Pineapple or other fresh citrus fruit'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Chicken tostadas',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/spicy.png',
    description: 'Crisp flavours and a bit of spice make this roasted chicken dish an easy go to when cooking for large groups. Top with Baja sauce for an extra kick of spice.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image5.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '4-6', description: 'Small corn tortillas'),
      const RecipeIngredient(amount: '½ cup', description: 'Chopped onion'),
      const RecipeIngredient(amount: '⅔', description: 'Cream'),
      const RecipeIngredient(amount: '3-4oz', description: 'Roasted, shredded chicken breast'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Coconut rice',
    author: 'Ali Connors',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/healthy.png',
    description: 'This dish is a terrific pairing to almost any main. Bonus- it’s quick, easy to make, and turns even the simplest of dishes into a delicacy. Sweet coconut cream will leave your mouth watering, with yummy caramelized  flecks of rice adding an extra bit of taste. Fluff with fork before serving for best results.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image6.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '2 cups', description: 'Jasmine rice'),
      const RecipeIngredient(amount: '1 1/2 cups', description: 'Water'),
      const RecipeIngredient(amount: '1 cup', description: 'Coconut milk'),
      const RecipeIngredient(amount: '1 1/2 tbsp', description: 'Sugar'),
      const RecipeIngredient(amount: '1tsp', description: 'Salt'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Gin basil cocktail',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/quick.png',
    description: 'This mellow and herb filled blending of simple ingredients is easy enough to mix that a novice host will feel like a seasoned bartender. Top with crushed basil, shake or stir.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image7.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '3 parts', description: 'Gin'),
      const RecipeIngredient(amount: '1 part', description: 'Fresh lemon juice'),
      const RecipeIngredient(amount: '½ part', description: 'Simple syrup'),
      const RecipeIngredient(amount: '5', description: 'Basil leaves, crushed'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Seared sesame fish',
    author: 'Ali Connors',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/fish.png',
    description: 'Cuts of fish like this are perfect for simple searing with bright flavours. Try Sesame seeds on these fillets for crusty skin filled with crunch. For added flavour try dipping in a homemade ponzu sauce - delicious.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image8.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1 ½ lbs', description: 'Thin fish fillets'),
      const RecipeIngredient(amount: '1 lb', description: 'Salt and black pepper to taste'),
      const RecipeIngredient(amount: '3/4 cup', description: 'Sesame seeds'),
      const RecipeIngredient(amount: '2tbsp', description: 'Sesame oil'),
      const RecipeIngredient(amount: '1tbsp', description: 'Lime juice'),
      const RecipeIngredient(amount: '2 tbsp', description: 'Soy sauce'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Herb artichoke',
    author: 'Sandra Adams',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/healthy.png',
    description: 'This tasty and healthy veggie is a favorite. Artichoke like this can be paired with a hearty main or works well as a small meal with some white wine on the side. Simple and fresh, all foodies love tasty artichoke.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image9.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1', description: 'Small garlic clove, peeled'),
      const RecipeIngredient(amount: '2', description: 'Whole  artichokes'),
      const RecipeIngredient(amount: '4 tbsp', description: 'Fresh lemon juice'),
      const RecipeIngredient(amount: '4 tbsp', description: 'Unsalted butter'),
      const RecipeIngredient(amount: '2 tbsp', description: 'Extra-virgin olive oil'),
      const RecipeIngredient(amount: '1⁄4 tsp', description: 'Freshly ground black pepper'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Pesto bruschetta',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/veggie.png',
    description: 'Life is good when you add amazingly warm bread, fresh pesto sauce, and roasted tomatoes to the table. This a  classic starter to break out in a pinch. It’s easy to make and extra tasty.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image10.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1 loaf', description: 'Sliced French bread'),
      const RecipeIngredient(amount: '½ cup', description: 'Cheese'),
      const RecipeIngredient(amount: '1 cup', description: 'Heirloom tomatoes'),
      const RecipeIngredient(amount: '1 cup', description: 'Fresh basil'),
      const RecipeIngredient(amount: '1 clove', description: 'Garlic '),
      const RecipeIngredient(amount: '½ tbsp', description: 'Olive oil'),
      const RecipeIngredient(amount: '3tsp', description: 'White wine vinegar'),
      const RecipeIngredient(amount: '¼ tsp', description: 'Sea salt'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Garlic bok choy',
    author: 'Sandra Adams',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/spicy.png',
    description: 'Great stir-fried bok choy starts at the market. For me, nothing says tasty like garlic and baby bok choy. Choose fresh, crisp greens. Once home, wash, chop, and then ready for the wok.  No family style spread is complete without these greens.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image11.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1/2 cup', description: 'Chick broth'),
      const RecipeIngredient(amount: '1 tbsp', description: 'Soy sauce'),
      const RecipeIngredient(amount: '¼ cup', description: 'Sliced garlic'),
      const RecipeIngredient(amount: '2-3 lbs', description: 'Bok choy'),
      const RecipeIngredient(amount: '2 tsp', description: 'Sesame oil'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Fresh Fettuccine',
    author: 'Ali Connors',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/main.png',
    description: 'Satisfy a need for rich, creamy homemade goodness with this classic. Creamy fettuccine alfredo will have you hitting the gym the next day, but it’s so good it’s worth it.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image12.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '¾ cup', description: 'Milk'),
      const RecipeIngredient(amount: '1 ½ tsp', description: 'Salt'),
      const RecipeIngredient(amount: '1 tbsp', description: 'Olive oil'),
      const RecipeIngredient(amount: '8oz', description: 'Fettuccine'),
      const RecipeIngredient(amount: '½ cup', description: 'Fresh basil'),
      const RecipeIngredient(amount: '½ cup', description: 'Fresh ground pepper'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
  const Recipe(
    name: 'Sicilian-Style sardines',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'packages/flutter_gallery_assets/pesto/quick.png',
    description: 'My go to way to eat sardines is with a splash of tangy lemon and fresh fennel drizzled on top. The best thing about this dish is the flavour it packs. Prepaid with wild caught sardines or canned.',
    imagePath: 'packages/flutter_gallery_assets/pesto/image13.jpg',
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1/4 cup', description: 'Dry white wine'),
      const RecipeIngredient(amount: '1', description: 'Finely chopped shallot'),
      const RecipeIngredient(amount: '2 tbsp', description: 'Fresh lemon juice'),
      const RecipeIngredient(amount: '1 tbsp', description: 'Fennel seeds, crushed'),
      const RecipeIngredient(amount: '4 tbsp', description: 'Extra virgin olive oil, to taste'),
      const RecipeIngredient(amount: '2 cans', description: 'Sardines in oil, drained'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook')
    ]
  ),
];
