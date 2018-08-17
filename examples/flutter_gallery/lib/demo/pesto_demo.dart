// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PestoDemo extends StatelessWidget {
  const PestoDemo({ Key key }) : super(key: key);

  static const String routeName = '/pesto';

  @override
  Widget build(BuildContext context) => new PestoHome();
}


const String _kSmallLogoImage = 'logos/pesto/logo_small.png';
const String _kGalleryAssetsPackage = 'flutter_gallery_assets';
const double _kAppBarHeight = 128.0;
const double _kFabHalfSize = 28.0; // TODO(mpcomplete): needs to adapt to screen size
const double _kRecipePageMaxWidth = 500.0;

final Set<Recipe> _favoriteRecipes = new Set<Recipe>();

final ThemeData _kTheme = new ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.teal,
  accentColor: Colors.redAccent,
);

class PestoHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const RecipeGridPage(recipes: kPestoRecipes);
  }
}

class PestoFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new RecipeGridPage(recipes: _favoriteRecipes.toList());
  }
}

class PestoStyle extends TextStyle {
  const PestoStyle({
    double fontSize = 12.0,
    FontWeight fontWeight,
    Color color = Colors.black87,
    double letterSpacing,
    double height,
  }) : super(
    inherit: false,
    color: color,
    fontFamily: 'Raleway',
    fontSize: fontSize,
    fontWeight: fontWeight,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: letterSpacing,
    height: height,
  );
}

// Displays a grid of recipe cards.
class RecipeGridPage extends StatefulWidget {
  const RecipeGridPage({ Key key, this.recipes }) : super(key: key);

  final List<Recipe> recipes;

  @override
  _RecipeGridPageState createState() => new _RecipeGridPageState();
}

class _RecipeGridPageState extends State<RecipeGridPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Theme(
      data: _kTheme.copyWith(platform: Theme.of(context).platform),
      child: new Scaffold(
        key: scaffoldKey,
        floatingActionButton: new FloatingActionButton(
          child: const Icon(Icons.edit),
          onPressed: () {
            scaffoldKey.currentState.showSnackBar(const SnackBar(
              content: Text('Not supported.'),
            ));
          },
        ),
        body: new CustomScrollView(
          slivers: <Widget>[
            _buildAppBar(context, statusBarHeight),
            _buildBody(context, statusBarHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double statusBarHeight) {
    return new SliverAppBar(
      pinned: true,
      expandedHeight: _kAppBarHeight,
      actions: <Widget>[
        new IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            scaffoldKey.currentState.showSnackBar(const SnackBar(
              content: Text('Not supported.'),
            ));
          },
        ),
      ],
      flexibleSpace: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;
          final double appBarHeight = size.height - statusBarHeight;
          final double t = (appBarHeight - kToolbarHeight) / (_kAppBarHeight - kToolbarHeight);
          final double extraPadding = new Tween<double>(begin: 10.0, end: 24.0).lerp(t);
          final double logoHeight = appBarHeight - 1.5 * extraPadding;
          return new Padding(
            padding: new EdgeInsets.only(
              top: statusBarHeight + 0.5 * extraPadding,
              bottom: extraPadding,
            ),
            child: new Center(
              child: new PestoLogo(height: logoHeight, t: t.clamp(0.0, 1.0))
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, double statusBarHeight) {
    final EdgeInsets mediaPadding = MediaQuery.of(context).padding;
    final EdgeInsets padding = new EdgeInsets.only(
      top: 8.0,
      left: 8.0 + mediaPadding.left,
      right: 8.0 + mediaPadding.right,
      bottom: 8.0
    );
    return new SliverPadding(
      padding: padding,
      sliver: new SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: _kRecipePageMaxWidth,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final Recipe recipe = widget.recipes[index];
            return new RecipeCard(
              recipe: recipe,
              onTap: () { showRecipePage(context, recipe); },
            );
          },
          childCount: widget.recipes.length,
        ),
      ),
    );
  }

  void showFavoritesPage(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/pesto/favorites'),
      builder: (BuildContext context) => new PestoFavorites(),
    ));
  }

  void showRecipePage(BuildContext context, Recipe recipe) {
    Navigator.push(context, new MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/pesto/recipe'),
      builder: (BuildContext context) {
        return new Theme(
          data: _kTheme.copyWith(platform: Theme.of(context).platform),
          child: new RecipePage(recipe: recipe),
        );
      },
    ));
  }
}

class PestoLogo extends StatefulWidget {
  const PestoLogo({this.height, this.t});

  final double height;
  final double t;

  @override
  _PestoLogoState createState() => new _PestoLogoState();
}

class _PestoLogoState extends State<PestoLogo> {
  // Native sizes for logo and its image/text components.
  static const double kLogoHeight = 162.0;
  static const double kLogoWidth = 220.0;
  static const double kImageHeight = 108.0;
  static const double kTextHeight = 48.0;
  final TextStyle titleStyle = const PestoStyle(fontSize: kTextHeight, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3.0);
  final RectTween _textRectTween = new RectTween(
    begin: new Rect.fromLTWH(0.0, kLogoHeight, kLogoWidth, kTextHeight),
    end: new Rect.fromLTWH(0.0, kImageHeight, kLogoWidth, kTextHeight)
  );
  final Curve _textOpacity = const Interval(0.4, 1.0, curve: Curves.easeInOut);
  final RectTween _imageRectTween = new RectTween(
    begin: new Rect.fromLTWH(0.0, 0.0, kLogoWidth, kLogoHeight),
    end: new Rect.fromLTWH(0.0, 0.0, kLogoWidth, kImageHeight),
  );

  @override
  Widget build(BuildContext context) {
    return new Semantics(
      namesRoute: true,
      child: new Transform(
        transform: new Matrix4.identity()..scale(widget.height / kLogoHeight),
        alignment: Alignment.topCenter,
        child: new SizedBox(
          width: kLogoWidth,
          child: new Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              new Positioned.fromRect(
                rect: _imageRectTween.lerp(widget.t),
                child: new Image.asset(
                  _kSmallLogoImage,
                  package: _kGalleryAssetsPackage,
                  fit: BoxFit.contain,
                ),
              ),
              new Positioned.fromRect(
                rect: _textRectTween.lerp(widget.t),
                child: new Opacity(
                  opacity: _textOpacity.transform(widget.t),
                  child: new Text('PESTO', style: titleStyle, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A card with the recipe's image, author, and title.
class RecipeCard extends StatelessWidget {
  const RecipeCard({ Key key, this.recipe, this.onTap }) : super(key: key);

  final Recipe recipe;
  final VoidCallback onTap;

  TextStyle get titleStyle => const PestoStyle(fontSize: 24.0, fontWeight: FontWeight.w600);
  TextStyle get authorStyle => const PestoStyle(fontWeight: FontWeight.w500, color: Colors.black54);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: onTap,
      child: new Card(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Hero(
              tag: 'packages/$_kGalleryAssetsPackage/${recipe.imagePath}',
              child: AspectRatio(
                aspectRatio: 4.0 / 3.0,
                child: Image.asset(
                  recipe.imagePath,
                  package: recipe.imagePackage,
                  fit: BoxFit.cover,
                  semanticLabel: recipe.name,
                ),
              ),
            ),
            new Expanded(
              child: new Row(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new Image.asset(
                      recipe.ingredientsImagePath,
                      package: recipe.ingredientsImagePackage,
                      width: 48.0,
                      height: 48.0,
                    ),
                  ),
                  new Expanded(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Text(recipe.name, style: titleStyle, softWrap: false, overflow: TextOverflow.ellipsis),
                        new Text(recipe.author, style: authorStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Displays one recipe. Includes the recipe sheet with a background image.
class RecipePage extends StatefulWidget {
  const RecipePage({ Key key, this.recipe }) : super(key: key);

  final Recipe recipe;

  @override
  _RecipePageState createState() => new _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextStyle menuItemStyle = const PestoStyle(fontSize: 15.0, color: Colors.black54, height: 24.0/15.0);

  double _getAppBarHeight(BuildContext context) => MediaQuery.of(context).size.height * 0.3;

  @override
  Widget build(BuildContext context) {
    // The full page content with the recipe's image behind it. This
    // adjusts based on the size of the screen. If the recipe sheet touches
    // the edge of the screen, use a slightly different layout.
    final double appBarHeight = _getAppBarHeight(context);
    final Size screenSize = MediaQuery.of(context).size;
    final bool fullWidth = screenSize.width < _kRecipePageMaxWidth;
    final bool isFavorite = _favoriteRecipes.contains(widget.recipe);
    return new Scaffold(
      key: _scaffoldKey,
      body: new Stack(
        children: <Widget>[
          new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: appBarHeight + _kFabHalfSize,
            child: new Hero(
              tag: 'packages/$_kGalleryAssetsPackage/${widget.recipe.imagePath}',
              child: new Image.asset(
                widget.recipe.imagePath,
                package: widget.recipe.imagePackage,
                fit: fullWidth ? BoxFit.fitWidth : BoxFit.cover,
              ),
            ),
          ),
          new CustomScrollView(
            slivers: <Widget>[
              new SliverAppBar(
                expandedHeight: appBarHeight - _kFabHalfSize,
                backgroundColor: Colors.transparent,
                actions: <Widget>[
                  new PopupMenuButton<String>(
                    onSelected: (String item) {},
                    itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                      _buildMenuItem(Icons.share, 'Tweet recipe'),
                      _buildMenuItem(Icons.email, 'Email recipe'),
                      _buildMenuItem(Icons.message, 'Message recipe'),
                      _buildMenuItem(Icons.people, 'Share on Facebook'),
                    ],
                  ),
                ],
                flexibleSpace: const FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, -1.0),
                        end: Alignment(0.0, -0.2),
                        colors: <Color>[Color(0x60000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              new SliverToBoxAdapter(
                child: new Stack(
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.only(top: _kFabHalfSize),
                      width: fullWidth ? null : _kRecipePageMaxWidth,
                      child: new RecipeSheet(recipe: widget.recipe),
                    ),
                    new Positioned(
                      right: 16.0,
                      child: new FloatingActionButton(
                        child: new Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        onPressed: _toggleFavorite,
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ],
      ),
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
          new Text(label, style: menuItemStyle),
        ],
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      if (_favoriteRecipes.contains(widget.recipe))
        _favoriteRecipes.remove(widget.recipe);
      else
        _favoriteRecipes.add(widget.recipe);
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
      child: new SafeArea(
        top: false,
        bottom: false,
        child: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: new Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(64.0)
            },
            children: <TableRow>[
              new TableRow(
                children: <Widget>[
                  new TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: new Image.asset(
                      recipe.ingredientsImagePath,
                      package: recipe.ingredientsImagePackage,
                      width: 32.0,
                      height: 32.0,
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown
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
                  const SizedBox(),
                  new Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: new Text(recipe.description, style: descriptionStyle)
                  ),
                ]
              ),
              new TableRow(
                children: <Widget>[
                  const SizedBox(),
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
                  const SizedBox(),
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
            )),
          ),
        ),
      ),
    );
  }

  TableRow _buildItemRow(String left, String right) {
    return new TableRow(
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: new Text(left, style: itemAmountStyle),
        ),
        new Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: new Text(right, style: itemStyle),
        ),
      ],
    );
  }
}

class Recipe {
  const Recipe({
    this.name,
    this.author,
    this.description,
    this.imagePath,
    this.imagePackage,
    this.ingredientsImagePath,
    this.ingredientsImagePackage,
    this.ingredients,
    this.steps
  });

  final String name;
  final String author;
  final String description;
  final String imagePath;
  final String imagePackage;
  final String ingredientsImagePath;
  final String ingredientsImagePackage;
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

const List<Recipe> kPestoRecipes = <Recipe>[
  Recipe(
    name: 'Roasted Chicken',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'food/icons/main.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'The perfect dish to welcome your family and friends with on a crisp autumn night. Pair with roasted veggies to truly impress them.',
    imagePath: 'food/roasted_chicken.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '1 whole', description: 'Chicken'),
      RecipeIngredient(amount: '1/2 cup', description: 'Butter'),
      RecipeIngredient(amount: '1 tbsp', description: 'Onion powder'),
      RecipeIngredient(amount: '1 tbsp', description: 'Freshly ground pepper'),
      RecipeIngredient(amount: '1 tsp', description: 'Salt'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '1 min', description: 'Put in oven'),
      RecipeStep(duration: '1hr 45 min', description: 'Cook'),
    ],
  ),
  Recipe(
    name: 'Chopped Beet Leaves',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'food/icons/veggie.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This vegetable has more to offer than just its root. Beet greens can be tossed into a salad to add some variety or sauteed on its own with some oil and garlic.',
    imagePath: 'food/chopped_beet_leaves.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
       RecipeIngredient(amount: '3 cups', description: 'Beet greens'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '5 min', description: 'Chop'),
    ],
  ),
  Recipe(
    name: 'Pesto Pasta',
    author: 'Ali Connors',
    ingredientsImagePath: 'food/icons/main.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'With this pesto recipe, you can quickly whip up a meal to satisfy your savory needs. And if you\'re feeling festive, you can add bacon to taste.',
    imagePath: 'food/pesto_pasta.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '1/4 cup ', description: 'Pasta'),
      RecipeIngredient(amount: '2 cups', description: 'Fresh basil leaves'),
      RecipeIngredient(amount: '1/2 cup', description: 'Parmesan cheese'),
      RecipeIngredient(amount: '1/2 cup', description: 'Extra virgin olive oil'),
      RecipeIngredient(amount: '1/3 cup', description: 'Pine nuts'),
      RecipeIngredient(amount: '1/4 cup', description: 'Lemon juice'),
      RecipeIngredient(amount: '3 cloves', description: 'Garlic'),
      RecipeIngredient(amount: '1/4 tsp', description: 'Salt'),
      RecipeIngredient(amount: '1/8 tsp', description: 'Pepper'),
      RecipeIngredient(amount: '3 lbs', description: 'Bacon'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '15 min', description: 'Blend'),
    ],
  ),
  Recipe(
    name: 'Cherry Pie',
    author: 'Sandra Adams',
    ingredientsImagePath: 'food/icons/main.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Sometimes when you\'re craving some cheer in your life you can jumpstart your day with some cherry pie. Dessert for breakfast is perfectly acceptable.',
    imagePath: 'food/cherry_pie.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '1', description: 'Pie crust'),
      RecipeIngredient(amount: '4 cups', description: 'Fresh or frozen cherries'),
      RecipeIngredient(amount: '1 cup', description: 'Granulated sugar'),
      RecipeIngredient(amount: '4 tbsp', description: 'Cornstarch'),
      RecipeIngredient(amount: '1½ tbsp', description: 'Butter'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '15 min', description: 'Mix'),
      RecipeStep(duration: '1hr 30 min', description: 'Bake'),
    ],
  ),
  Recipe(
    name: 'Spinach Salad',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'food/icons/spicy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Everyone\'s favorite leafy green is back. Paired with fresh sliced onion, it\'s ready to tackle any dish, whether it be a salad or an egg scramble.',
    imagePath: 'food/spinach_onion_salad.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '4 cups', description: 'Spinach'),
      RecipeIngredient(amount: '1 cup', description: 'Sliced onion'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '5 min', description: 'Mix'),
    ],
  ),
  Recipe(
    name: 'Butternut Squash Soup',
    author: 'Ali Connors',
    ingredientsImagePath: 'food/icons/healthy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This creamy butternut squash soup will warm you on the chilliest of winter nights and bring a delightful pop of orange to the dinner table.',
    imagePath: 'food/butternut_squash_soup.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '1', description: 'Butternut squash'),
      RecipeIngredient(amount: '4 cups', description: 'Chicken stock'),
      RecipeIngredient(amount: '2', description: 'Potatoes'),
      RecipeIngredient(amount: '1', description: 'Onion'),
      RecipeIngredient(amount: '1', description: 'Carrot'),
      RecipeIngredient(amount: '1', description: 'Celery'),
      RecipeIngredient(amount: '1 tsp', description: 'Salt'),
      RecipeIngredient(amount: '1 tsp', description: 'Pepper'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '10 min', description: 'Prep vegetables'),
      RecipeStep(duration: '5 min', description: 'Stir'),
      RecipeStep(duration: '1 hr 10 min', description: 'Cook')
    ],
  ),
  Recipe(
    name: 'Spanakopita',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'food/icons/quick.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'You \'feta\' believe this is a crowd-pleaser! Flaky phyllo pastry surrounds a delicious mixture of spinach and cheeses to create the perfect appetizer.',
    imagePath: 'food/spanakopita.png',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: <RecipeIngredient>[
      RecipeIngredient(amount: '1 lb', description: 'Spinach'),
      RecipeIngredient(amount: '½ cup', description: 'Feta cheese'),
      RecipeIngredient(amount: '½ cup', description: 'Cottage cheese'),
      RecipeIngredient(amount: '2', description: 'Eggs'),
      RecipeIngredient(amount: '1', description: 'Onion'),
      RecipeIngredient(amount: '½ lb', description: 'Phyllo dough'),
    ],
    steps: <RecipeStep>[
      RecipeStep(duration: '5 min', description: 'Sauté vegetables'),
      RecipeStep(duration: '3 min', description: 'Stir vegetables and other filling ingredients'),
      RecipeStep(duration: '10 min', description: 'Fill phyllo squares half-full with filling and fold.'),
      RecipeStep(duration: '40 min', description: 'Bake')
    ],
  ),
];
