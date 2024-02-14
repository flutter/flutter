import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN sharedZAxisTransitionDemo

class SharedZAxisTransitionDemo extends StatelessWidget {
  const SharedZAxisTransitionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return _createHomeRoute();
      },
    );
  }

  Route _createHomeRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) {
        final localizations = GalleryLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Column(
              children: [
                Text(localizations.demoSharedZAxisTitle),
                Text(
                  '(${localizations.demoSharedZAxisDemoInstructions})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push<void>(_createSettingsRoute());
                },
              ),
            ],
          ),
          body: const _RecipePage(),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          fillColor: Colors.transparent,
          transitionType: SharedAxisTransitionType.scaled,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }

  Route _createSettingsRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _SettingsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          fillColor: Colors.transparent,
          transitionType: SharedAxisTransitionType.scaled,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;

    final settingsList = <_SettingsInfo>[
      _SettingsInfo(
        Icons.person,
        localizations.demoSharedZAxisProfileSettingLabel,
      ),
      _SettingsInfo(
        Icons.notifications,
        localizations.demoSharedZAxisNotificationSettingLabel,
      ),
      _SettingsInfo(
        Icons.security,
        localizations.demoSharedZAxisPrivacySettingLabel,
      ),
      _SettingsInfo(
        Icons.help,
        localizations.demoSharedZAxisHelpSettingLabel,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.demoSharedZAxisSettingsPageTitle,
        ),
      ),
      body: ListView(
        children: [
          for (var setting in settingsList) _SettingsTile(setting),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(this.settingData);
  final _SettingsInfo settingData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(settingData.settingIcon),
          title: Text(settingData.settingsLabel),
        ),
        const Divider(thickness: 2),
      ],
    );
  }
}

class _SettingsInfo {
  const _SettingsInfo(this.settingIcon, this.settingsLabel);

  final IconData settingIcon;
  final String settingsLabel;
}

class _RecipePage extends StatelessWidget {
  const _RecipePage();

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;

    final savedRecipes = <_RecipeInfo>[
      _RecipeInfo(
        localizations.demoSharedZAxisBurgerRecipeTitle,
        localizations.demoSharedZAxisBurgerRecipeDescription,
        'crane/destinations/eat_2.jpg',
      ),
      _RecipeInfo(
        localizations.demoSharedZAxisSandwichRecipeTitle,
        localizations.demoSharedZAxisSandwichRecipeDescription,
        'crane/destinations/eat_3.jpg',
      ),
      _RecipeInfo(
        localizations.demoSharedZAxisDessertRecipeTitle,
        localizations.demoSharedZAxisDessertRecipeDescription,
        'crane/destinations/eat_4.jpg',
      ),
      _RecipeInfo(
        localizations.demoSharedZAxisShrimpPlateRecipeTitle,
        localizations.demoSharedZAxisShrimpPlateRecipeDescription,
        'crane/destinations/eat_6.jpg',
      ),
      _RecipeInfo(
        localizations.demoSharedZAxisCrabPlateRecipeTitle,
        localizations.demoSharedZAxisCrabPlateRecipeDescription,
        'crane/destinations/eat_8.jpg',
      ),
      _RecipeInfo(
        localizations.demoSharedZAxisBeefSandwichRecipeTitle,
        localizations.demoSharedZAxisBeefSandwichRecipeDescription,
        'crane/destinations/eat_10.jpg',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8.0),
          child: Text(localizations.demoSharedZAxisSavedRecipesListTitle),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (var recipe in savedRecipes)
                _RecipeTile(recipe, savedRecipes.indexOf(recipe))
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeInfo {
  const _RecipeInfo(this.recipeName, this.recipeDescription, this.recipeImage);

  final String recipeName;
  final String recipeDescription;
  final String recipeImage;
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile(this._recipe, this._index);
  final _RecipeInfo _recipe;
  final int _index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 70,
          width: 100,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: Image.asset(
              _recipe.recipeImage,
              package: 'flutter_gallery_assets',
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              ListTile(
                title: Text(_recipe.recipeName),
                subtitle: Text(_recipe.recipeDescription),
                trailing: Text('0${_index + 1}'),
              ),
              const Divider(thickness: 2),
            ],
          ),
        ),
      ],
    );
  }
}

// END sharedZAxisTransitionDemo
