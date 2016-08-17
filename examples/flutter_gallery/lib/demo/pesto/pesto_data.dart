// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

final List<Recipe> kPestoRecipes = <Recipe>[
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
