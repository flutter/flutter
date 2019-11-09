import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

/// Callers can lookup localized strings with an instance of StockStrings returned
/// by `StockStrings.of(context)`.
///
/// Applications need to include `StockStrings.delegate()` in their app's
/// localizationDelegates list, and the locales they support in the app's
/// supportedLocales list. For example:
///
/// ```
/// import 'i18n/stock_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: StockStrings.localizationsDelegates,
///   supportedLocales: StockStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: 0.16.0
///   intl_translation: 0.17.7
///
///   # rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the StockStrings.supportedLocales
/// property.
class StockStrings {
  StockStrings(Locale locale) : _localeName = locale.toString();

  final String _localeName;

  static Future<StockStrings> load(Locale locale) {
    return initializeMessages(locale.toString())
      .then<StockStrings>((void _) => StockStrings(locale));
  }

  static StockStrings of(BuildContext context) {
    return Localizations.of<StockStrings>(context, StockStrings);
  }

  static const LocalizationsDelegate<StockStrings> delegate = _StockStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es', 'ES'),
    Locale('en', 'US'),
  ];

  String title() {
    return Intl.message(
      r'Stocks',
      locale: _localeName,
      name: 'title',
      desc: r'Title for the Stocks application',
      args: <Object>[]
    );
  }

  String market() {
    return Intl.message(
      r'MARKET',
      locale: _localeName,
      name: 'market',
      desc: r'Label for the Market tab',
      args: <Object>[]
    );
  }

  String portfolio() {
    return Intl.message(
      r'PORTFOLIO',
      locale: _localeName,
      name: 'portfolio',
      desc: r'Label for the Portfolio tab',
      args: <Object>[]
    );
  }

}

class _StockStringsDelegate extends LocalizationsDelegate<StockStrings> {
  const _StockStringsDelegate();

  @override
  Future<StockStrings> load(Locale locale) => StockStrings.load(locale);

  @override
  bool isSupported(Locale locale) => <String>['es', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_StockStringsDelegate old) => false;
}
