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


const String _kSmallLogoImage = 'pesto/logo_small.png';
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
    double fontSize: 12.0,
    FontWeight fontWeight,
    Color color: Colors.black87,
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
              content: const Text('Not supported.'),
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
              content: const Text('Not supported.'),
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
  final TextStyle titleStyle = const PestoStyle(fontSize: 24.0, fontWeight: FontWeight.w600);
  final TextStyle authorStyle = const PestoStyle(fontWeight: FontWeight.w500, color: Colors.black54);

  const RecipeCard({ Key key, this.recipe, this.onTap }) : super(key: key);

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
              tag: 'packages/$_kGalleryAssetsPackage/${recipe.imagePath}',
              child: new Image.asset(
                recipe.imagePath,
                package: recipe.imagePackage,
                fit: BoxFit.contain,
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
                  background: const DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: const LinearGradient(
                        begin: const Alignment(0.0, -1.0),
                        end: const Alignment(0.0, -0.2),
                        colors: const<Color>[const Color(0x60000000), const Color(0x00000000)],
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
              0: const FixedColumnWidth(64.0)
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

const List<Recipe> kPestoRecipes = const <Recipe>[
  const Recipe(
    name: 'Pesto Bruschetta',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'pesto/quick.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Bask in greens this season by trying this delightful take on traditional bruschetta. Top with a dollop of homemade pesto, and season with freshly ground sea salt and pepper.',
    imagePath: 'pesto/image1.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '6 pieces', description: 'Mozzarella cheese'),
      const RecipeIngredient(amount: '6 pieces', description: 'Toasts'),
      const RecipeIngredient(amount: '⅔ cup', description: 'Homemade pesto'),
      const RecipeIngredient(amount: '1tbsp', description: 'Freshly ground pepper'),
      const RecipeIngredient(amount: '1 tsp', description: 'Salt'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(description: 'Put in oven'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Rustic purple mash',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'pesto/veggie.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Abundant in color, and healthy, delicious goodness, cooking with these South American purple potatoes is a treat. Boil, mash, bake, or roast them. For taste cook with chicken stock, and a dash of extra virgin olive oil.',
    imagePath: 'pesto/image2.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '2 lbs', description: 'Purple potatoes, skin on'),
      const RecipeIngredient(amount: '1 tsp', description: 'Salt'),
      const RecipeIngredient(amount: '2 tsp', description: 'Lemon'),
      const RecipeIngredient(amount: '4 cups', description: 'Chicken stock'),
      const RecipeIngredient(amount: '1tbsp', description: 'Extra virgin olive oil')
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Bacon Sprouts',
    author: 'Ali Connors',
    ingredientsImagePath: 'pesto/main.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This beautiful sprouts recipe is the most glorious side dish on a cold winter’s night. Construct it with bacon or fake-on, but always make sure the sprouts are deliciously seasoned and appropriately sautéed.',
    imagePath: 'pesto/image3.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Oven Sausage',
    author: 'Sandra Adams',
    ingredientsImagePath: 'pesto/meat.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Robust cuts of portuguese sausage add layers of flavour. Bake or fry until sausages are slightly browned and with a crispy skin. Serve warm and with cuts of pineapple for a delightful mix of sweet and savory flavour. This is the perfect dish after a swim in the sea.',
    imagePath: 'pesto/image4.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1 1/2 lbs', description: 'Linguisa'),
      const RecipeIngredient(amount: '1 lbs', description: 'Pineapple or other fresh citrus fruit'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Chicken tostadas',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'pesto/spicy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Crisp flavours and a bit of spice make this roasted chicken dish an easy go to when cooking for large groups. Top with Baja sauce for an extra kick of spice.',
    imagePath: 'pesto/image5.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '4-6', description: 'Small corn tortillas'),
      const RecipeIngredient(amount: '½ cup', description: 'Chopped onion'),
      const RecipeIngredient(amount: '⅔', description: 'Cream'),
      const RecipeIngredient(amount: '3-4oz', description: 'Roasted, shredded chicken breast'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Coconut rice',
    author: 'Ali Connors',
    ingredientsImagePath: 'pesto/healthy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This dish is a terrific pairing to almost any main. Bonus- it’s quick, easy to make, and turns even the simplest of dishes into a delicacy. Sweet coconut cream will leave your mouth watering, with yummy caramelized flecks of rice adding an extra bit of taste. Fluff with fork before serving for best results.',
    imagePath: 'pesto/image6.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
    ],
  ),
  const Recipe(
    name: 'Gin basil cocktail',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'pesto/quick.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This mellow and herb filled blending of simple ingredients is easy enough to mix that a novice host will feel like a seasoned bartender. Top with crushed basil, shake or stir.',
    imagePath: 'pesto/image7.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '3 parts', description: 'Gin'),
      const RecipeIngredient(amount: '1 part', description: 'Fresh lemon juice'),
      const RecipeIngredient(amount: '½ part', description: 'Simple syrup'),
      const RecipeIngredient(amount: '5', description: 'Basil leaves, crushed'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Seared sesame fish',
    author: 'Ali Connors',
    ingredientsImagePath: 'pesto/fish.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Cuts of fish like this are perfect for simple searing with bright flavours. Try Sesame seeds on these fillets for crusty skin filled with crunch. For added flavour try dipping in a homemade ponzu sauce - delicious.',
    imagePath: 'pesto/image8.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Herb artichoke',
    author: 'Sandra Adams',
    ingredientsImagePath: 'pesto/healthy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'This tasty and healthy veggie is a favorite. Artichoke like this can be paired with a hearty main or works well as a small meal with some white wine on the side. Simple and fresh, all foodies love tasty artichoke.',
    imagePath: 'pesto/image9.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1', description: 'Small garlic clove, peeled'),
      const RecipeIngredient(amount: '2', description: 'Whole artichokes'),
      const RecipeIngredient(amount: '4 tbsp', description: 'Fresh lemon juice'),
      const RecipeIngredient(amount: '4 tbsp', description: 'Unsalted butter'),
      const RecipeIngredient(amount: '2 tbsp', description: 'Extra-virgin olive oil'),
      const RecipeIngredient(amount: '1⁄4 tsp', description: 'Freshly ground black pepper'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Pesto bruschetta',
    author: 'Trevor Hansen',
    ingredientsImagePath: 'pesto/veggie.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Life is good when you add amazingly warm bread, fresh pesto sauce, and roasted tomatoes to the table. This a classic starter to break out in a pinch. It’s easy to make and extra tasty.',
    imagePath: 'pesto/image10.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Garlic bok choy',
    author: 'Sandra Adams',
    ingredientsImagePath: 'pesto/spicy.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Great stir-fried bok choy starts at the market. For me, nothing says tasty like garlic and baby bok choy. Choose fresh, crisp greens. Once home, wash, chop, and then ready for the wok. No family style spread is complete without these greens.',
    imagePath: 'pesto/image11.jpg',
    imagePackage: _kGalleryAssetsPackage,
    ingredients: const<RecipeIngredient>[
      const RecipeIngredient(amount: '1/2 cup', description: 'Chick broth'),
      const RecipeIngredient(amount: '1 tbsp', description: 'Soy sauce'),
      const RecipeIngredient(amount: '¼ cup', description: 'Sliced garlic'),
      const RecipeIngredient(amount: '2-3 lbs', description: 'Bok choy'),
      const RecipeIngredient(amount: '2 tsp', description: 'Sesame oil'),
    ],
    steps: const<RecipeStep>[
      const RecipeStep(duration: '3 min', description: 'Stir'),
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Fresh Fettuccine',
    author: 'Ali Connors',
    ingredientsImagePath: 'pesto/main.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'Satisfy a need for rich, creamy homemade goodness with this classic. Creamy fettuccine alfredo will have you hitting the gym the next day, but it’s so good it’s worth it.',
    imagePath: 'pesto/image12.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
  const Recipe(
    name: 'Sicilian-Style sardines',
    author: 'Peter Carlsson',
    ingredientsImagePath: 'pesto/quick.png',
    ingredientsImagePackage: _kGalleryAssetsPackage,
    description: 'My go to way to eat sardines is with a splash of tangy lemon and fresh fennel drizzled on top. The best thing about this dish is the flavour it packs. Prepaid with wild caught sardines or canned.',
    imagePath: 'pesto/image13.jpg',
    imagePackage: _kGalleryAssetsPackage,
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
      const RecipeStep(duration: '45 min', description: 'Cook'),
    ],
  ),
];
