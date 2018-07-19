// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use:
// dart dev/tools/gen_localizations.dart --overwrite

// The TranslationBundle subclasses defined here encode all of the translations
// found in the flutter_localizations/lib/src/l10n/*.arb files.
//
// The [MaterialLocalizations] class uses the (generated)
// translationBundleForLocale() function to look up a const TranslationBundle
// instance for a locale.

// ignore_for_file: public_member_api_docs

import 'dart:ui' show Locale;

class TranslationBundle {
  const TranslationBundle(this.parent);
  final TranslationBundle parent;
  String get selectedRowCountTitleOne => parent?.selectedRowCountTitleOne;
  String get selectedRowCountTitleZero => parent?.selectedRowCountTitleZero;
  String get selectedRowCountTitleTwo => parent?.selectedRowCountTitleTwo;
  String get selectedRowCountTitleFew => parent?.selectedRowCountTitleFew;
  String get selectedRowCountTitleMany => parent?.selectedRowCountTitleMany;
  String get scriptCategory => parent?.scriptCategory;
  String get timeOfDayFormat => parent?.timeOfDayFormat;
  String get openAppDrawerTooltip => parent?.openAppDrawerTooltip;
  String get backButtonTooltip => parent?.backButtonTooltip;
  String get closeButtonTooltip => parent?.closeButtonTooltip;
  String get deleteButtonTooltip => parent?.deleteButtonTooltip;
  String get nextMonthTooltip => parent?.nextMonthTooltip;
  String get previousMonthTooltip => parent?.previousMonthTooltip;
  String get nextPageTooltip => parent?.nextPageTooltip;
  String get previousPageTooltip => parent?.previousPageTooltip;
  String get showMenuTooltip => parent?.showMenuTooltip;
  String get aboutListTileTitle => parent?.aboutListTileTitle;
  String get licensesPageTitle => parent?.licensesPageTitle;
  String get pageRowsInfoTitle => parent?.pageRowsInfoTitle;
  String get pageRowsInfoTitleApproximate => parent?.pageRowsInfoTitleApproximate;
  String get rowsPerPageTitle => parent?.rowsPerPageTitle;
  String get tabLabel => parent?.tabLabel;
  String get selectedRowCountTitleOther => parent?.selectedRowCountTitleOther;
  String get cancelButtonLabel => parent?.cancelButtonLabel;
  String get closeButtonLabel => parent?.closeButtonLabel;
  String get continueButtonLabel => parent?.continueButtonLabel;
  String get copyButtonLabel => parent?.copyButtonLabel;
  String get cutButtonLabel => parent?.cutButtonLabel;
  String get okButtonLabel => parent?.okButtonLabel;
  String get pasteButtonLabel => parent?.pasteButtonLabel;
  String get selectAllButtonLabel => parent?.selectAllButtonLabel;
  String get viewLicensesButtonLabel => parent?.viewLicensesButtonLabel;
  String get anteMeridiemAbbreviation => parent?.anteMeridiemAbbreviation;
  String get postMeridiemAbbreviation => parent?.postMeridiemAbbreviation;
  String get timePickerHourModeAnnouncement => parent?.timePickerHourModeAnnouncement;
  String get timePickerMinuteModeAnnouncement => parent?.timePickerMinuteModeAnnouncement;
  String get signedInLabel => parent?.signedInLabel;
  String get hideAccountsLabel => parent?.hideAccountsLabel;
  String get showAccountsLabel => parent?.showAccountsLabel;
  String get modalBarrierDismissLabel => parent?.modalBarrierDismissLabel;
  String get drawerLabel => parent?.drawerLabel;
  String get popupMenuLabel => parent?.popupMenuLabel;
  String get dialogLabel => parent?.dialogLabel;
  String get alertDialogLabel => parent?.alertDialogLabel;
  String get searchFieldLabel => parent?.searchFieldLabel;
}

// ignore: camel_case_types
class _Bundle_ar extends TranslationBundle {
  const _Bundle_ar() : super(null);
  @override String get selectedRowCountTitleOne => r'تم اختيار عنصر واحد';
  @override String get selectedRowCountTitleZero => r'لم يتم اختيار أي عنصر';
  @override String get selectedRowCountTitleTwo => r'تم اختيار عنصرين ($selectedRowCount)';
  @override String get selectedRowCountTitleFew => r'تم اختيار $selectedRowCount عنصر';
  @override String get selectedRowCountTitleMany => r'تم اختيار $selectedRowCount عنصرًا';
  @override String get scriptCategory => r'tall';
  @override String get timeOfDayFormat => r'h:mm a';
  @override String get openAppDrawerTooltip => r'فتح قائمة التنقل';
  @override String get backButtonTooltip => r'رجوع';
  @override String get closeButtonTooltip => r'إغلاق';
  @override String get deleteButtonTooltip => r'حذف';
  @override String get nextMonthTooltip => r'الشهر التالي';
  @override String get previousMonthTooltip => r'الشهر السابق';
  @override String get nextPageTooltip => r'الصفحة التالية';
  @override String get previousPageTooltip => r'الصفحة السابقة';
  @override String get showMenuTooltip => r'عرض القائمة';
  @override String get aboutListTileTitle => r'حول "$applicationName"';
  @override String get licensesPageTitle => r'التراخيص';
  @override String get pageRowsInfoTitle => r'من $firstRow إلى $lastRow من إجمالي $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'من $firstRow إلى $lastRow من إجمالي $rowCount تقريبًا';
  @override String get rowsPerPageTitle => r'عدد الصفوف في الصفحة:';
  @override String get tabLabel => r'علامة التبويب $tabIndex من $tabCount';
  @override String get selectedRowCountTitleOther => r'تم اختيار $selectedRowCount عنصر';
  @override String get cancelButtonLabel => r'إلغاء';
  @override String get closeButtonLabel => r'إغلاق';
  @override String get continueButtonLabel => r'متابعة';
  @override String get copyButtonLabel => r'نسخ';
  @override String get cutButtonLabel => r'قص';
  @override String get okButtonLabel => r'حسنًا';
  @override String get pasteButtonLabel => r'لصق';
  @override String get selectAllButtonLabel => r'اختيار الكل';
  @override String get viewLicensesButtonLabel => r'الاطّلاع على التراخيص';
  @override String get anteMeridiemAbbreviation => r'ص';
  @override String get postMeridiemAbbreviation => r'م';
  @override String get timePickerHourModeAnnouncement => r'اختيار الساعات';
  @override String get timePickerMinuteModeAnnouncement => r'اختيار الدقائق';
  @override String get signedInLabel => r'تم تسجيل الدخول';
  @override String get hideAccountsLabel => r'إخفاء الحسابات';
  @override String get showAccountsLabel => r'إظهار الحسابات';
  @override String get modalBarrierDismissLabel => r'رفض';
  @override String get drawerLabel => r'قائمة تنقل';
  @override String get popupMenuLabel => r'قائمة منبثقة';
  @override String get dialogLabel => r'مربع حوار';
  @override String get alertDialogLabel => r'مربع حوار التنبيه';
  @override String get searchFieldLabel => r'بحث';
}

// ignore: camel_case_types
class _Bundle_bg extends TranslationBundle {
  const _Bundle_bg() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Отваряне на менюто за навигация';
  @override String get backButtonTooltip => r'Назад';
  @override String get closeButtonTooltip => r'Затваряне';
  @override String get deleteButtonTooltip => r'Изтриване';
  @override String get nextMonthTooltip => r'Следващият месец';
  @override String get previousMonthTooltip => r'Предишният месец';
  @override String get nextPageTooltip => r'Следващата страница';
  @override String get previousPageTooltip => r'Предишната страница';
  @override String get showMenuTooltip => r'Показване на менюто';
  @override String get aboutListTileTitle => r'Всичко за $applicationName';
  @override String get licensesPageTitle => r'Лицензи';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow от $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow от около $rowCount';
  @override String get rowsPerPageTitle => r'Редове на страница:';
  @override String get tabLabel => r'Раздел $tabIndex от $tabCount';
  @override String get selectedRowCountTitleOne => r'Избран е 1 елемент';
  @override String get selectedRowCountTitleOther => r'Избрани са $selectedRowCount елемента';
  @override String get cancelButtonLabel => r'ОТКАЗ';
  @override String get closeButtonLabel => r'ЗАТВАРЯНЕ';
  @override String get continueButtonLabel => r'НАПРЕД';
  @override String get copyButtonLabel => r'КОПИРАНЕ';
  @override String get cutButtonLabel => r'ИЗРЯЗВАНЕ';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'ПОСТАВЯНЕ';
  @override String get selectAllButtonLabel => r'ИЗБИРАНЕ НА ВСИЧКО';
  @override String get viewLicensesButtonLabel => r'ПРЕГЛЕД НА ЛИЦЕНЗИТЕ';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Избиране на часове';
  @override String get timePickerMinuteModeAnnouncement => r'Избиране на минути';
  @override String get modalBarrierDismissLabel => r'Отхвърляне';
  @override String get signedInLabel => r'В профила си сте';
  @override String get hideAccountsLabel => r'Скриване на профилите';
  @override String get showAccountsLabel => r'Показване на профилите';
  @override String get drawerLabel => r'Меню за навигация';
  @override String get popupMenuLabel => r'Изскачащо меню';
  @override String get dialogLabel => r'Диалогов прозорец';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_bs extends TranslationBundle {
  const _Bundle_bs() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Odabrane su $selectedRowCount stavke';
  @override String get openAppDrawerTooltip => r'Otvaranje izbornika za navigaciju';
  @override String get backButtonTooltip => r'Natrag';
  @override String get closeButtonTooltip => r'Zatvaranje';
  @override String get deleteButtonTooltip => r'Brisanje';
  @override String get nextMonthTooltip => r'Sljedeći mjesec';
  @override String get previousMonthTooltip => r'Prethodni mjesec';
  @override String get nextPageTooltip => r'Sljedeća stranica';
  @override String get previousPageTooltip => r'Prethodna stranica';
  @override String get showMenuTooltip => r'Prikaz izbornika';
  @override String get aboutListTileTitle => r'O aplikaciji $applicationName';
  @override String get licensesPageTitle => r'Licence';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow od $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow od otprilike $rowCount';
  @override String get rowsPerPageTitle => r'Redaka po stranici:';
  @override String get tabLabel => r'Kartica $tabIndex od $tabCount';
  @override String get selectedRowCountTitleOne => r'Odabrana je jedna stavka';
  @override String get selectedRowCountTitleOther => r'Odabrano je $selectedRowCount stavki';
  @override String get cancelButtonLabel => r'ODUSTANI';
  @override String get closeButtonLabel => r'ZATVORI';
  @override String get continueButtonLabel => r'NASTAVI';
  @override String get copyButtonLabel => r'KOPIRAJ';
  @override String get cutButtonLabel => r'IZREŽI';
  @override String get okButtonLabel => r'U REDU';
  @override String get pasteButtonLabel => r'ZALIJEPI';
  @override String get selectAllButtonLabel => r'ODABERI SVE';
  @override String get viewLicensesButtonLabel => r'PRIKAŽI LICENCE';
  @override String get anteMeridiemAbbreviation => r'prijepodne';
  @override String get postMeridiemAbbreviation => r'popodne';
  @override String get timePickerHourModeAnnouncement => r'Odaberite sate';
  @override String get timePickerMinuteModeAnnouncement => r'Odaberite minute';
  @override String get modalBarrierDismissLabel => r'Odbaci';
  @override String get signedInLabel => r'Prijavljeni korisnik';
  @override String get hideAccountsLabel => r'Sakrijte račune';
  @override String get showAccountsLabel => r'Prikažite račune';
  @override String get drawerLabel => r'Navigacijski izbornik';
  @override String get popupMenuLabel => r'Skočni izbornik';
  @override String get dialogLabel => r'Dijalog';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_ca extends TranslationBundle {
  const _Bundle_ca() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Obre el menú de navegació';
  @override String get backButtonTooltip => r'Enrere';
  @override String get closeButtonTooltip => r'Tanca';
  @override String get deleteButtonTooltip => r'Suprimeix';
  @override String get nextMonthTooltip => r'Mes següent';
  @override String get previousMonthTooltip => r'Mes anterior';
  @override String get nextPageTooltip => r'Pàgina següent';
  @override String get previousPageTooltip => r'Pàgina anterior';
  @override String get showMenuTooltip => r'Mostra el menú';
  @override String get aboutListTileTitle => r'Sobre $applicationName';
  @override String get licensesPageTitle => r'Llicències';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow d' "'" r'aproximadament $rowCount';
  @override String get rowsPerPageTitle => r'Files per pàgina:';
  @override String get tabLabel => r'Pestanya $tabIndex de $tabCount';
  @override String get selectedRowCountTitleOne => r'S' "'" r'ha seleccionat 1 element';
  @override String get selectedRowCountTitleOther => r'S' "'" r'han seleccionat $selectedRowCount elements';
  @override String get cancelButtonLabel => r'CANCEL·LA';
  @override String get closeButtonLabel => r'TANCA';
  @override String get continueButtonLabel => r'CONTINUA';
  @override String get copyButtonLabel => r'COPIA';
  @override String get cutButtonLabel => r'RETALLA';
  @override String get okButtonLabel => r'D' "'" r'ACORD';
  @override String get pasteButtonLabel => r'ENGANXA';
  @override String get selectAllButtonLabel => r'SELECCIONA-HO TOT';
  @override String get viewLicensesButtonLabel => r'MOSTRA LES LLICÈNCIES';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Selecciona les hores';
  @override String get timePickerMinuteModeAnnouncement => r'Selecciona els minuts';
  @override String get modalBarrierDismissLabel => r'Ignora';
  @override String get signedInLabel => r'Sessió iniciada';
  @override String get hideAccountsLabel => r'Amaga els comptes';
  @override String get showAccountsLabel => r'Mostra els comptes';
  @override String get drawerLabel => r'Menú de navegació';
  @override String get popupMenuLabel => r'Menú emergent';
  @override String get dialogLabel => r'Diàleg';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_cs extends TranslationBundle {
  const _Bundle_cs() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Jsou vybrány $selectedRowCount položky';
  @override String get selectedRowCountTitleMany => r'Je vybráno $selectedRowCount položky';
  @override String get openAppDrawerTooltip => r'Otevřít navigační nabídku';
  @override String get backButtonTooltip => r'Zpět';
  @override String get closeButtonTooltip => r'Zavřít';
  @override String get deleteButtonTooltip => r'Smazat';
  @override String get nextMonthTooltip => r'Další měsíc';
  @override String get previousMonthTooltip => r'Předchozí měsíc';
  @override String get nextPageTooltip => r'Další stránka';
  @override String get previousPageTooltip => r'Předchozí stránka';
  @override String get showMenuTooltip => r'Zobrazit nabídku';
  @override String get aboutListTileTitle => r'O aplikaci $applicationName';
  @override String get licensesPageTitle => r'Licence';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow z $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow z asi $rowCount';
  @override String get rowsPerPageTitle => r'Počet řádků na stránku:';
  @override String get tabLabel => r'Karta $tabIndex z $tabCount';
  @override String get selectedRowCountTitleOne => r'Je vybrána 1 položka';
  @override String get selectedRowCountTitleOther => r'Je vybráno $selectedRowCount položek';
  @override String get cancelButtonLabel => r'ZRUŠIT';
  @override String get closeButtonLabel => r'ZAVŘÍT';
  @override String get continueButtonLabel => r'POKRAČOVAT';
  @override String get copyButtonLabel => r'KOPÍROVAT';
  @override String get cutButtonLabel => r'VYJMOUT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'VLOŽIT';
  @override String get selectAllButtonLabel => r'VYBRAT VŠE';
  @override String get viewLicensesButtonLabel => r'ZOBRAZIT LICENCE';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Vyberte hodiny';
  @override String get timePickerMinuteModeAnnouncement => r'Vyberte minuty';
  @override String get modalBarrierDismissLabel => r'Zavřít';
  @override String get signedInLabel => r'Uživatel přihlášen';
  @override String get hideAccountsLabel => r'Skrýt účty';
  @override String get showAccountsLabel => r'Zobrazit účty';
  @override String get drawerLabel => r'Navigační nabídka';
  @override String get popupMenuLabel => r'Vyskakovací nabídka';
  @override String get dialogLabel => r'Dialogové okno';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_da extends TranslationBundle {
  const _Bundle_da() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Åbn navigationsmenuen';
  @override String get backButtonTooltip => r'Tilbage';
  @override String get closeButtonTooltip => r'Luk';
  @override String get deleteButtonTooltip => r'Slet';
  @override String get nextMonthTooltip => r'Næste måned';
  @override String get previousMonthTooltip => r'Forrige måned';
  @override String get nextPageTooltip => r'Næste side';
  @override String get previousPageTooltip => r'Forrige side';
  @override String get showMenuTooltip => r'Vis menu';
  @override String get aboutListTileTitle => r'Om $applicationName';
  @override String get licensesPageTitle => r'Licenser';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow af $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow af ca. $rowCount';
  @override String get rowsPerPageTitle => r'Rækker pr. side:';
  @override String get tabLabel => r'Fane $tabIndex af $tabCount';
  @override String get selectedRowCountTitleOne => r'1 element er valgt';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount elementer er valgt';
  @override String get cancelButtonLabel => r'ANNULLER';
  @override String get closeButtonLabel => r'LUK';
  @override String get continueButtonLabel => r'FORTSÆT';
  @override String get copyButtonLabel => r'KOPIÉR';
  @override String get cutButtonLabel => r'KLIP';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'SÆT IND';
  @override String get selectAllButtonLabel => r'VÆLG ALLE';
  @override String get viewLicensesButtonLabel => r'SE LICENSER';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Vælg timer';
  @override String get timePickerMinuteModeAnnouncement => r'Vælg minutter';
  @override String get modalBarrierDismissLabel => r'Afvis';
  @override String get signedInLabel => r'Logget ind';
  @override String get hideAccountsLabel => r'Skjul konti';
  @override String get showAccountsLabel => r'Vis konti';
  @override String get drawerLabel => r'Navigationsmenu';
  @override String get popupMenuLabel => r'Pop op-menu';
  @override String get dialogLabel => r'Dialogboks';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_de extends TranslationBundle {
  const _Bundle_de() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Navigationsmenü öffnen';
  @override String get backButtonTooltip => r'Zurück';
  @override String get closeButtonTooltip => r'Schließen';
  @override String get deleteButtonTooltip => r'Löschen';
  @override String get nextMonthTooltip => r'Nächster Monat';
  @override String get previousMonthTooltip => r'Vorheriger Monat';
  @override String get nextPageTooltip => r'Nächste Seite';
  @override String get previousPageTooltip => r'Vorherige Seite';
  @override String get showMenuTooltip => r'Menü anzeigen';
  @override String get aboutListTileTitle => r'Über $applicationName';
  @override String get licensesPageTitle => r'Lizenzen';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow von $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow von etwa $rowCount';
  @override String get rowsPerPageTitle => r'Zeilen pro Seite:';
  @override String get tabLabel => r'Tab $tabIndex von $tabCount';
  @override String get selectedRowCountTitleZero => r'Keine Objekte ausgewählt';
  @override String get selectedRowCountTitleOne => r'1 Element ausgewählt';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount Elemente ausgewählt';
  @override String get cancelButtonLabel => r'ABBRECHEN';
  @override String get closeButtonLabel => r'SCHLIEẞEN';
  @override String get continueButtonLabel => r'WEITER';
  @override String get copyButtonLabel => r'KOPIEREN';
  @override String get cutButtonLabel => r'AUSSCHNEIDEN';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'EINFÜGEN';
  @override String get selectAllButtonLabel => r'ALLE AUSWÄHLEN';
  @override String get viewLicensesButtonLabel => r'LIZENZEN ANZEIGEN';
  @override String get anteMeridiemAbbreviation => r'VORM.';
  @override String get postMeridiemAbbreviation => r'NACHM.';
  @override String get timePickerHourModeAnnouncement => r'Stunden auswählen';
  @override String get timePickerMinuteModeAnnouncement => r'Minuten auswählen';
  @override String get signedInLabel => r'Angemeldet';
  @override String get hideAccountsLabel => r'Konten ausblenden';
  @override String get showAccountsLabel => r'Konten anzeigen';
  @override String get modalBarrierDismissLabel => r'Schließen';
  @override String get drawerLabel => r'Navigationsmenü';
  @override String get popupMenuLabel => r'Pop-up-Menü';
  @override String get dialogLabel => r'Dialogfeld';
  @override String get alertDialogLabel => r'Aufmerksam';
  @override String get searchFieldLabel => r'Suchen';
}

// ignore: camel_case_types
class _Bundle_el extends TranslationBundle {
  const _Bundle_el() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Άνοιγμα μενού πλοήγησης';
  @override String get backButtonTooltip => r'Πίσω';
  @override String get closeButtonTooltip => r'Κλείσιμο';
  @override String get deleteButtonTooltip => r'Διαγραφή';
  @override String get nextMonthTooltip => r'Επόμενος μήνας';
  @override String get previousMonthTooltip => r'Προηγούμενος μήνας';
  @override String get nextPageTooltip => r'Επόμενη σελίδα';
  @override String get previousPageTooltip => r'Προηγούμενη σελίδα';
  @override String get showMenuTooltip => r'Εμφάνιση μενού';
  @override String get aboutListTileTitle => r'Σχετικά με την εφαρμογή $applicationName';
  @override String get licensesPageTitle => r'Άδειες';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow από $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow από περίπου $rowCount';
  @override String get rowsPerPageTitle => r'Σειρές ανά σελίδα:';
  @override String get tabLabel => r'Καρτέλα $tabIndex από $tabCount';
  @override String get selectedRowCountTitleOne => r'Επιλέχθηκε 1 στοιχείο';
  @override String get selectedRowCountTitleOther => r'Επιλέχθηκαν $selectedRowCount στοιχεία';
  @override String get cancelButtonLabel => r'ΑΚΥΡΩΣΗ';
  @override String get closeButtonLabel => r'ΚΛΕΙΣΙΜΟ';
  @override String get continueButtonLabel => r'ΣΥΝΕΧΕΙΑ';
  @override String get copyButtonLabel => r'ΑΝΤΙΓΡΑΦΗ';
  @override String get cutButtonLabel => r'ΑΠΟΚΟΠΗ';
  @override String get okButtonLabel => r'ΟΚ';
  @override String get pasteButtonLabel => r'ΕΠΙΚΟΛΛΗΣΗ';
  @override String get selectAllButtonLabel => r'ΕΠΙΛΟΓΗ ΟΛΩΝ';
  @override String get viewLicensesButtonLabel => r'ΠΡΟΒΟΛΗ ΑΔΕΙΩΝ';
  @override String get anteMeridiemAbbreviation => r'π.μ.';
  @override String get postMeridiemAbbreviation => r'μ.μ.';
  @override String get timePickerHourModeAnnouncement => r'Επιλογή ωρών';
  @override String get timePickerMinuteModeAnnouncement => r'Επιλογή λεπτών';
  @override String get modalBarrierDismissLabel => r'Παράβλεψη';
  @override String get signedInLabel => r'Σε σύνδεση';
  @override String get hideAccountsLabel => r'Απόκρυψη λογαριασμών';
  @override String get showAccountsLabel => r'Εμφάνιση λογαριασμών';
  @override String get drawerLabel => r'Μενού πλοήγησης';
  @override String get popupMenuLabel => r'Αναδυόμενο μενού';
  @override String get dialogLabel => r'Παράθυρο διαλόγου';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_en extends TranslationBundle {
  const _Bundle_en() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'h:mm a';
  @override String get openAppDrawerTooltip => r'Open navigation menu';
  @override String get backButtonTooltip => r'Back';
  @override String get closeButtonTooltip => r'Close';
  @override String get deleteButtonTooltip => r'Delete';
  @override String get nextMonthTooltip => r'Next month';
  @override String get previousMonthTooltip => r'Previous month';
  @override String get nextPageTooltip => r'Next page';
  @override String get previousPageTooltip => r'Previous page';
  @override String get showMenuTooltip => r'Show menu';
  @override String get aboutListTileTitle => r'About $applicationName';
  @override String get licensesPageTitle => r'Licenses';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow of $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow of about $rowCount';
  @override String get rowsPerPageTitle => r'Rows per page:';
  @override String get tabLabel => r'Tab $tabIndex of $tabCount';
  @override String get selectedRowCountTitleZero => r'No items selected';
  @override String get selectedRowCountTitleOne => r'1 item selected';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount items selected';
  @override String get cancelButtonLabel => r'CANCEL';
  @override String get closeButtonLabel => r'CLOSE';
  @override String get continueButtonLabel => r'CONTINUE';
  @override String get copyButtonLabel => r'COPY';
  @override String get cutButtonLabel => r'CUT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'PASTE';
  @override String get selectAllButtonLabel => r'SELECT ALL';
  @override String get viewLicensesButtonLabel => r'VIEW LICENSES';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Select hours';
  @override String get timePickerMinuteModeAnnouncement => r'Select minutes';
  @override String get modalBarrierDismissLabel => r'Dismiss';
  @override String get signedInLabel => r'Signed in';
  @override String get hideAccountsLabel => r'Hide accounts';
  @override String get showAccountsLabel => r'Show accounts';
  @override String get drawerLabel => r'Navigation menu';
  @override String get popupMenuLabel => r'Popup menu';
  @override String get dialogLabel => r'Dialog';
  @override String get alertDialogLabel => r'Alert';
  @override String get searchFieldLabel => r'Search';
}

// ignore: camel_case_types
class _Bundle_es extends TranslationBundle {
  const _Bundle_es() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'H:mm';
  @override String get openAppDrawerTooltip => r'Abrir el menú de navegación';
  @override String get backButtonTooltip => r'Atrás';
  @override String get closeButtonTooltip => r'Cerrar';
  @override String get deleteButtonTooltip => r'Eliminar';
  @override String get nextMonthTooltip => r'Mes siguiente';
  @override String get previousMonthTooltip => r'Mes anterior';
  @override String get nextPageTooltip => r'Página siguiente';
  @override String get previousPageTooltip => r'Página anterior';
  @override String get showMenuTooltip => r'Mostrar menú';
  @override String get aboutListTileTitle => r'Sobre $applicationName';
  @override String get licensesPageTitle => r'Licencias';
  @override String get pageRowsInfoTitle => r'$firstRow‑$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow‑$lastRow de aproximadamente $rowCount';
  @override String get rowsPerPageTitle => r'Filas por página:';
  @override String get tabLabel => r'Pestaña $tabIndex de $tabCount';
  @override String get selectedRowCountTitleZero => r'No se han seleccionado elementos';
  @override String get selectedRowCountTitleOne => r'1 elemento seleccionado';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount elementos seleccionados';
  @override String get cancelButtonLabel => r'CANCELAR';
  @override String get closeButtonLabel => r'CERRAR';
  @override String get continueButtonLabel => r'CONTINUAR';
  @override String get copyButtonLabel => r'COPIAR';
  @override String get cutButtonLabel => r'CORTAR';
  @override String get okButtonLabel => r'ACEPTAR';
  @override String get pasteButtonLabel => r'PEGAR';
  @override String get selectAllButtonLabel => r'SELECCIONAR TODO';
  @override String get viewLicensesButtonLabel => r'VER LICENCIAS';
  @override String get anteMeridiemAbbreviation => r'A.M.';
  @override String get postMeridiemAbbreviation => r'P.M.';
  @override String get timePickerHourModeAnnouncement => r'Seleccionar horas';
  @override String get timePickerMinuteModeAnnouncement => r'Seleccionar minutos';
  @override String get signedInLabel => r'Sesión iniciada';
  @override String get hideAccountsLabel => r'Ocultar cuentas';
  @override String get showAccountsLabel => r'Mostrar cuentas';
  @override String get modalBarrierDismissLabel => r'Ignorar';
  @override String get drawerLabel => r'Menú de navegación';
  @override String get popupMenuLabel => r'Menú emergente';
  @override String get dialogLabel => r'Cuadro de diálogo';
  @override String get alertDialogLabel => r'Alerta';
  @override String get searchFieldLabel => r'Buscar';
}

// ignore: camel_case_types
class _Bundle_et extends TranslationBundle {
  const _Bundle_et() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Ava navigeerimismenüü';
  @override String get backButtonTooltip => r'Tagasi';
  @override String get closeButtonTooltip => r'Sule';
  @override String get deleteButtonTooltip => r'Kustuta';
  @override String get nextMonthTooltip => r'Järgmine kuu';
  @override String get previousMonthTooltip => r'Eelmine kuu';
  @override String get nextPageTooltip => r'Järgmine leht';
  @override String get previousPageTooltip => r'Eelmine leht';
  @override String get showMenuTooltip => r'Kuva menüü';
  @override String get aboutListTileTitle => r'Teave rakenduse $applicationName kohta';
  @override String get licensesPageTitle => r'Litsentsid';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow $rowCount-st';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow umbes $rowCount-st';
  @override String get rowsPerPageTitle => r'Ridu lehe kohta:';
  @override String get tabLabel => r'$tabIndex. vahekaart $tabCount-st';
  @override String get selectedRowCountTitleOne => r'Valitud on 1 üksus';
  @override String get selectedRowCountTitleOther => r'Valitud on $selectedRowCount üksust';
  @override String get cancelButtonLabel => r'TÜHISTA';
  @override String get closeButtonLabel => r'SULE';
  @override String get continueButtonLabel => r'JÄTKA';
  @override String get copyButtonLabel => r'KOPEERI';
  @override String get cutButtonLabel => r'LÕIKA';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'KLEEBI';
  @override String get selectAllButtonLabel => r'VALI KÕIK';
  @override String get viewLicensesButtonLabel => r'KUVA LITSENTSID';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Tundide valimine';
  @override String get timePickerMinuteModeAnnouncement => r'Minutite valimine';
  @override String get modalBarrierDismissLabel => r'Loobu';
  @override String get signedInLabel => r'Sisse logitud';
  @override String get hideAccountsLabel => r'Peida kontod';
  @override String get showAccountsLabel => r'Kuva kontod';
  @override String get drawerLabel => r'Navigeerimismenüü';
  @override String get popupMenuLabel => r'Hüpikmenüü';
  @override String get dialogLabel => r'Dialoog';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_fa extends TranslationBundle {
  const _Bundle_fa() : super(null);
  @override String get scriptCategory => r'tall';
  @override String get timeOfDayFormat => r'H:mm';
  @override String get selectedRowCountTitleOne => r'۱ مورد انتخاب شد';
  @override String get openAppDrawerTooltip => r'باز کردن منوی پیمایش';
  @override String get backButtonTooltip => r'برگشت';
  @override String get closeButtonTooltip => r'بستن';
  @override String get deleteButtonTooltip => r'حذف';
  @override String get nextMonthTooltip => r'ماه بعد';
  @override String get previousMonthTooltip => r'ماه قبل';
  @override String get nextPageTooltip => r'صفحه بعد';
  @override String get previousPageTooltip => r'صفحه قبل';
  @override String get showMenuTooltip => r'نمایش منو';
  @override String get aboutListTileTitle => r'درباره $applicationName';
  @override String get licensesPageTitle => r'مجوزها';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow از $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow از حدود $rowCount';
  @override String get rowsPerPageTitle => r'ردیف در هر صفحه:';
  @override String get tabLabel => r'برگه $tabIndex از $tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount مورد انتخاب شدند';
  @override String get cancelButtonLabel => r'لغو';
  @override String get closeButtonLabel => r'بستن';
  @override String get continueButtonLabel => r'ادامه';
  @override String get copyButtonLabel => r'کپی';
  @override String get cutButtonLabel => r'برش';
  @override String get okButtonLabel => r'تأیید';
  @override String get pasteButtonLabel => r'جای‌گذاری';
  @override String get selectAllButtonLabel => r'انتخاب همه';
  @override String get viewLicensesButtonLabel => r'مشاهده مجوزها';
  @override String get anteMeridiemAbbreviation => r'ق.ظ.';
  @override String get postMeridiemAbbreviation => r'ب.ظ.';
  @override String get timePickerHourModeAnnouncement => r'انتخاب ساعت';
  @override String get timePickerMinuteModeAnnouncement => r'انتخاب دقیقه';
  @override String get signedInLabel => r'واردشده به سیستم';
  @override String get hideAccountsLabel => r'پنهان کردن حساب‌ها';
  @override String get showAccountsLabel => r'نشان دادن حساب‌ها';
  @override String get modalBarrierDismissLabel => r'نپذیرفتن';
  @override String get drawerLabel => r'منوی پیمایش';
  @override String get popupMenuLabel => r'منوی بازشو';
  @override String get dialogLabel => r'کادر گفتگو';
  @override String get alertDialogLabel => r'هشدار';
  @override String get searchFieldLabel => r'جستجو کردن';
}

// ignore: camel_case_types
class _Bundle_fi extends TranslationBundle {
  const _Bundle_fi() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Avaa navigointivalikko';
  @override String get backButtonTooltip => r'Takaisin';
  @override String get closeButtonTooltip => r'Sulje';
  @override String get deleteButtonTooltip => r'Poista';
  @override String get nextMonthTooltip => r'Seuraava kuukausi';
  @override String get previousMonthTooltip => r'Edellinen kuukausi';
  @override String get nextPageTooltip => r'Seuraava sivu';
  @override String get previousPageTooltip => r'Edellinen sivu';
  @override String get showMenuTooltip => r'Näytä valikko';
  @override String get aboutListTileTitle => r'Tietoja sovelluksesta $applicationName';
  @override String get licensesPageTitle => r'Lisenssit';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow/$rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow/~$rowCount';
  @override String get rowsPerPageTitle => r'Riviä/sivu:';
  @override String get tabLabel => r'Välilehti $tabIndex/$tabCount';
  @override String get selectedRowCountTitleOne => r'1 kohde valittu';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount kohdetta valittu';
  @override String get cancelButtonLabel => r'PERUUTA';
  @override String get closeButtonLabel => r'SULJE';
  @override String get continueButtonLabel => r'JATKA';
  @override String get copyButtonLabel => r'COPY';
  @override String get cutButtonLabel => r'LEIKKAA';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'LIITÄ';
  @override String get selectAllButtonLabel => r'VALITSE KAIKKI';
  @override String get viewLicensesButtonLabel => r'NÄYTÄ KÄYTTÖOIKEUDET';
  @override String get anteMeridiemAbbreviation => r'ap';
  @override String get postMeridiemAbbreviation => r'ip';
  @override String get timePickerHourModeAnnouncement => r'Valitse tunnit';
  @override String get timePickerMinuteModeAnnouncement => r'Valitse minuutit';
  @override String get modalBarrierDismissLabel => r'Ohita';
  @override String get signedInLabel => r'Kirjautunut sisään';
  @override String get hideAccountsLabel => r'Piilota tilit';
  @override String get showAccountsLabel => r'Näytä tilit';
  @override String get drawerLabel => r'Navigointivalikko';
  @override String get popupMenuLabel => r'Ponnahdusvalikko';
  @override String get dialogLabel => r'Valintaikkuna';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_fil extends TranslationBundle {
  const _Bundle_fil() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Buksan ang menu ng navigation';
  @override String get backButtonTooltip => r'Bumalik';
  @override String get closeButtonTooltip => r'Isara';
  @override String get deleteButtonTooltip => r'I-delete';
  @override String get nextMonthTooltip => r'Susunod na buwan';
  @override String get previousMonthTooltip => r'Nakaraang buwan';
  @override String get nextPageTooltip => r'Susunod na page';
  @override String get previousPageTooltip => r'Nakaraang page';
  @override String get showMenuTooltip => r'Ipakita ang menu';
  @override String get aboutListTileTitle => r'Tungkol sa $applicationName';
  @override String get licensesPageTitle => r'Mga Lisensya';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow ng $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow ng humigit kumulang $rowCount';
  @override String get rowsPerPageTitle => r'Mga row bawat page:';
  @override String get tabLabel => r'Tab $tabIndex ng $tabCount';
  @override String get selectedRowCountTitleOne => r'1 item ang napili';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount na item ang napili';
  @override String get cancelButtonLabel => r'KANSELAHIN';
  @override String get closeButtonLabel => r'ISARA';
  @override String get continueButtonLabel => r'MAGPATULOY';
  @override String get copyButtonLabel => r'KOPYAHIN';
  @override String get cutButtonLabel => r'I-CUT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'I-PASTE';
  @override String get selectAllButtonLabel => r'PILIIN LAHAT';
  @override String get viewLicensesButtonLabel => r'TINGNAN ANG MGA LISENSYA';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Pumili ng mga oras';
  @override String get timePickerMinuteModeAnnouncement => r'Pumili ng mga minuto';
  @override String get modalBarrierDismissLabel => r'I-dismiss';
  @override String get signedInLabel => r'Naka-sign in';
  @override String get hideAccountsLabel => r'Itago ang mga account';
  @override String get showAccountsLabel => r'Ipakita ang mga account';
  @override String get drawerLabel => r'Menu ng navigation';
  @override String get popupMenuLabel => r'Popup na menu';
  @override String get dialogLabel => r'Dialog';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_fr extends TranslationBundle {
  const _Bundle_fr() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Ouvrir le menu de navigation';
  @override String get backButtonTooltip => r'Retour';
  @override String get closeButtonTooltip => r'Fermer';
  @override String get deleteButtonTooltip => r'Supprimer';
  @override String get nextMonthTooltip => r'Mois suivant';
  @override String get previousMonthTooltip => r'Mois précédent';
  @override String get nextPageTooltip => r'Page suivante';
  @override String get previousPageTooltip => r'Page précédente';
  @override String get showMenuTooltip => r'Afficher le menu';
  @override String get aboutListTileTitle => r'À propos de $applicationName';
  @override String get licensesPageTitle => r'Licences';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow sur $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow sur environ $rowCount';
  @override String get rowsPerPageTitle => r'Lignes par page :';
  @override String get tabLabel => r'Onglet $tabIndex sur $tabCount';
  @override String get selectedRowCountTitleZero => r'Aucun élément sélectionné';
  @override String get selectedRowCountTitleOne => r'1 élément sélectionné';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount éléments sélectionnés';
  @override String get cancelButtonLabel => r'ANNULER';
  @override String get closeButtonLabel => r'FERMER';
  @override String get continueButtonLabel => r'CONTINUER';
  @override String get copyButtonLabel => r'COPIER';
  @override String get cutButtonLabel => r'COUPER';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'COLLER';
  @override String get selectAllButtonLabel => r'TOUT SÉLECTIONNER';
  @override String get viewLicensesButtonLabel => r'AFFICHER LES LICENCES';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Sélectionner une heure';
  @override String get timePickerMinuteModeAnnouncement => r'Sélectionner des minutes';
  @override String get signedInLabel => r'Connecté';
  @override String get hideAccountsLabel => r'Masquer les comptes';
  @override String get showAccountsLabel => r'Afficher les comptes';
  @override String get modalBarrierDismissLabel => r'Ignorer';
  @override String get drawerLabel => r'Menu de navigation';
  @override String get popupMenuLabel => r'Menu contextuel';
  @override String get dialogLabel => r'Boîte de dialogue';
  @override String get alertDialogLabel => r'Alerte';
  @override String get searchFieldLabel => r'Chercher';
}

// ignore: camel_case_types
class _Bundle_gsw extends TranslationBundle {
  const _Bundle_gsw() : super(null);
  @override String get tabLabel => r'Tab $tabIndex von $tabCount';
  @override String get showAccountsLabel => r'Konten anzeigen';
  @override String get hideAccountsLabel => r'Konten ausblenden';
  @override String get signedInLabel => r'Angemeldet';
  @override String get timePickerMinuteModeAnnouncement => r'Minuten auswählen';
  @override String get timePickerHourModeAnnouncement => r'Stunden auswählen';
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Navigationsmenü öffnen';
  @override String get backButtonTooltip => r'Zurück';
  @override String get closeButtonTooltip => r'Schließen';
  @override String get deleteButtonTooltip => r'Löschen';
  @override String get nextMonthTooltip => r'Nächster Monat';
  @override String get previousMonthTooltip => r'Vorheriger Monat';
  @override String get nextPageTooltip => r'Nächste Seite';
  @override String get previousPageTooltip => r'Vorherige Seite';
  @override String get showMenuTooltip => r'Menü anzeigen';
  @override String get aboutListTileTitle => r'Über $applicationName';
  @override String get licensesPageTitle => r'Lizenzen';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow von $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow von etwa $rowCount';
  @override String get rowsPerPageTitle => r'Zeilen pro Seite:';
  @override String get selectedRowCountTitleOne => r'1 Element ausgewählt';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount Elemente ausgewählt';
  @override String get cancelButtonLabel => r'ABBRECHEN';
  @override String get closeButtonLabel => r'SCHLIEẞEN';
  @override String get continueButtonLabel => r'WEITER';
  @override String get copyButtonLabel => r'KOPIEREN';
  @override String get cutButtonLabel => r'AUSSCHNEIDEN';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'EINFÜGEN';
  @override String get selectAllButtonLabel => r'ALLE AUSWÄHLEN';
  @override String get viewLicensesButtonLabel => r'LIZENZEN ANZEIGEN';
  @override String get anteMeridiemAbbreviation => r'VORM.';
  @override String get postMeridiemAbbreviation => r'NACHM.';
  @override String get modalBarrierDismissLabel => r'Schließen';
  @override String get drawerLabel => r'Navigationsmenü';
  @override String get popupMenuLabel => r'Pop-up-Menü';
  @override String get dialogLabel => r'Dialogfeld';
  @override String get alertDialogLabel => r'Aufmerksam';
  @override String get searchFieldLabel => r'Suchen';
}

// ignore: camel_case_types
class _Bundle_he extends TranslationBundle {
  const _Bundle_he() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'H:mm';
  @override String get selectedRowCountTitleOne => r'פריט אחד נבחר';
  @override String get selectedRowCountTitleTwo => r'$selectedRowCount פריטים נבחרו';
  @override String get selectedRowCountTitleMany => r'$selectedRowCount פריטים נבחרו';
  @override String get openAppDrawerTooltip => r'פתיחה של תפריט הניווט';
  @override String get backButtonTooltip => r'הקודם';
  @override String get closeButtonTooltip => r'סגירה';
  @override String get deleteButtonTooltip => r'מחיקה';
  @override String get nextMonthTooltip => r'החודש הבא';
  @override String get previousMonthTooltip => r'החודש הקודם';
  @override String get nextPageTooltip => r'הדף הבא';
  @override String get previousPageTooltip => r'הדף הקודם';
  @override String get showMenuTooltip => r'הצגת התפריט';
  @override String get aboutListTileTitle => r'מידע על $applicationName';
  @override String get licensesPageTitle => r'רישיונות';
  @override String get pageRowsInfoTitle => r'$lastRow–$firstRow מתוך $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$lastRow–$firstRow מתוך כ-$rowCount';
  @override String get rowsPerPageTitle => r'שורות בכל דף:';
  @override String get tabLabel => r'כרטיסייה $tabIndex מתוך $tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount פריטים נבחרו';
  @override String get cancelButtonLabel => r'ביטול';
  @override String get closeButtonLabel => r'סגירה';
  @override String get continueButtonLabel => r'המשך';
  @override String get copyButtonLabel => r'העתקה';
  @override String get cutButtonLabel => r'גזירה';
  @override String get okButtonLabel => r'אישור';
  @override String get pasteButtonLabel => r'הדבקה';
  @override String get selectAllButtonLabel => r'בחירת הכול';
  @override String get viewLicensesButtonLabel => r'הצגת הרישיונות';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'בחירת שעות';
  @override String get timePickerMinuteModeAnnouncement => r'בחירת דקות';
  @override String get signedInLabel => r'מחובר';
  @override String get hideAccountsLabel => r'הסתרת החשבונות';
  @override String get showAccountsLabel => r'הצגת החשבונות';
  @override String get modalBarrierDismissLabel => r'סגירה';
  @override String get drawerLabel => r'תפריט ניווט';
  @override String get popupMenuLabel => r'תפריט קופץ';
  @override String get dialogLabel => r'תיבת דו-שיח';
  @override String get alertDialogLabel => r'עֵרָנִי';
  @override String get searchFieldLabel => r'לחפש';
}

// ignore: camel_case_types
class _Bundle_hi extends TranslationBundle {
  const _Bundle_hi() : super(null);
  @override String get scriptCategory => r'dense';
  @override String get timeOfDayFormat => r'ah:mm';
  @override String get openAppDrawerTooltip => r'नेविगेशन मेन्यू खोलें';
  @override String get backButtonTooltip => r'वापस जाएं';
  @override String get closeButtonTooltip => r'बंद करें';
  @override String get deleteButtonTooltip => r'मिटाएं';
  @override String get nextMonthTooltip => r'अगला महीना';
  @override String get previousMonthTooltip => r'पिछला महीना';
  @override String get nextPageTooltip => r'अगला पेज';
  @override String get previousPageTooltip => r'पिछला पेज';
  @override String get showMenuTooltip => r'मेन्यू दिखाएं';
  @override String get aboutListTileTitle => r'$applicationName के बारे में जानकारी';
  @override String get licensesPageTitle => r'लाइसेंस';
  @override String get pageRowsInfoTitle => r'$rowCount का $firstRow–$lastRow';
  @override String get pageRowsInfoTitleApproximate => r'$rowCount में से करीब $firstRow–$lastRow';
  @override String get rowsPerPageTitle => r'हर पेज में पंक्तियों की संख्या:';
  @override String get tabLabel => r'$tabCount का टैब $tabIndex';
  @override String get selectedRowCountTitleOne => r'1 चीज़ चुनी गई';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount चीज़ें चुनी गईं';
  @override String get cancelButtonLabel => r'रद्द करें';
  @override String get closeButtonLabel => r'बंद करें';
  @override String get continueButtonLabel => r'जारी रखें';
  @override String get copyButtonLabel => r'कॉपी करें';
  @override String get cutButtonLabel => r'कट करें';
  @override String get okButtonLabel => r'ठीक है';
  @override String get pasteButtonLabel => r'चिपकाएं';
  @override String get selectAllButtonLabel => r'सभी चुनें';
  @override String get viewLicensesButtonLabel => r'लाइसेंस देखें';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'घंटे के हिसाब से समय चुनें';
  @override String get timePickerMinuteModeAnnouncement => r'मिनट के हिसाब से समय चुनें';
  @override String get modalBarrierDismissLabel => r'खारिज करें';
  @override String get signedInLabel => r'साइन इन किया हुआ है';
  @override String get hideAccountsLabel => r'खाते छिपाएं';
  @override String get showAccountsLabel => r'खाते दिखाएं';
  @override String get drawerLabel => r'नेविगेशन मेन्यू';
  @override String get popupMenuLabel => r'पॉपअप मेन्यू';
  @override String get dialogLabel => r'संवाद';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_hr extends TranslationBundle {
  const _Bundle_hr() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Odabrane su $selectedRowCount stavke';
  @override String get openAppDrawerTooltip => r'Otvaranje izbornika za navigaciju';
  @override String get backButtonTooltip => r'Natrag';
  @override String get closeButtonTooltip => r'Zatvaranje';
  @override String get deleteButtonTooltip => r'Brisanje';
  @override String get nextMonthTooltip => r'Sljedeći mjesec';
  @override String get previousMonthTooltip => r'Prethodni mjesec';
  @override String get nextPageTooltip => r'Sljedeća stranica';
  @override String get previousPageTooltip => r'Prethodna stranica';
  @override String get showMenuTooltip => r'Prikaz izbornika';
  @override String get aboutListTileTitle => r'O aplikaciji $applicationName';
  @override String get licensesPageTitle => r'Licence';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow od $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow od otprilike $rowCount';
  @override String get rowsPerPageTitle => r'Redaka po stranici:';
  @override String get tabLabel => r'Kartica $tabIndex od $tabCount';
  @override String get selectedRowCountTitleOne => r'Odabrana je jedna stavka';
  @override String get selectedRowCountTitleOther => r'Odabrano je $selectedRowCount stavki';
  @override String get cancelButtonLabel => r'ODUSTANI';
  @override String get closeButtonLabel => r'ZATVORI';
  @override String get continueButtonLabel => r'NASTAVI';
  @override String get copyButtonLabel => r'KOPIRAJ';
  @override String get cutButtonLabel => r'IZREŽI';
  @override String get okButtonLabel => r'U REDU';
  @override String get pasteButtonLabel => r'ZALIJEPI';
  @override String get selectAllButtonLabel => r'ODABERI SVE';
  @override String get viewLicensesButtonLabel => r'PRIKAŽI LICENCE';
  @override String get anteMeridiemAbbreviation => r'prijepodne';
  @override String get postMeridiemAbbreviation => r'popodne';
  @override String get timePickerHourModeAnnouncement => r'Odaberite sate';
  @override String get timePickerMinuteModeAnnouncement => r'Odaberite minute';
  @override String get modalBarrierDismissLabel => r'Odbaci';
  @override String get signedInLabel => r'Prijavljeni korisnik';
  @override String get hideAccountsLabel => r'Sakrijte račune';
  @override String get showAccountsLabel => r'Prikažite račune';
  @override String get drawerLabel => r'Navigacijski izbornik';
  @override String get popupMenuLabel => r'Skočni izbornik';
  @override String get dialogLabel => r'Dijalog';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_hu extends TranslationBundle {
  const _Bundle_hu() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Navigációs menü megnyitása';
  @override String get backButtonTooltip => r'Vissza';
  @override String get closeButtonTooltip => r'Bezárás';
  @override String get deleteButtonTooltip => r'Törlés';
  @override String get nextMonthTooltip => r'Következő hónap';
  @override String get previousMonthTooltip => r'Előző hónap';
  @override String get nextPageTooltip => r'Következő oldal';
  @override String get previousPageTooltip => r'Előző oldal';
  @override String get showMenuTooltip => r'Menü megjelenítése';
  @override String get aboutListTileTitle => r'A(z) $applicationName névjegye';
  @override String get licensesPageTitle => r'Licencek';
  @override String get pageRowsInfoTitle => r'$rowCount/$firstRow–$lastRow.';
  @override String get pageRowsInfoTitleApproximate => r'Körülbelül $rowCount/$firstRow–$lastRow.';
  @override String get rowsPerPageTitle => r'Oldalankénti sorszám:';
  @override String get tabLabel => r'$tabCount/$tabIndex. lap';
  @override String get selectedRowCountTitleOne => r'1 elem kiválasztva';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount elem kiválasztva';
  @override String get cancelButtonLabel => r'MÉGSE';
  @override String get closeButtonLabel => r'BEZÁRÁS';
  @override String get continueButtonLabel => r'TOVÁBB';
  @override String get copyButtonLabel => r'MÁSOLÁS';
  @override String get cutButtonLabel => r'KIVÁGÁS';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'BEILLESZTÉS';
  @override String get selectAllButtonLabel => r'AZ ÖSSZES KIJELÖLÉSE';
  @override String get viewLicensesButtonLabel => r'LICENCEK MEGTEKINTÉSE';
  @override String get anteMeridiemAbbreviation => r'de.';
  @override String get postMeridiemAbbreviation => r'du.';
  @override String get timePickerHourModeAnnouncement => r'Óra kiválasztása';
  @override String get timePickerMinuteModeAnnouncement => r'Perc kiválasztása';
  @override String get modalBarrierDismissLabel => r'Elvetés';
  @override String get signedInLabel => r'Bejelentkezve';
  @override String get hideAccountsLabel => r'Fiókok elrejtése';
  @override String get showAccountsLabel => r'Fiókok megjelenítése';
  @override String get drawerLabel => r'Navigációs menü';
  @override String get popupMenuLabel => r'Előugró menü';
  @override String get dialogLabel => r'Párbeszédablak';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_id extends TranslationBundle {
  const _Bundle_id() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Buka menu navigasi';
  @override String get backButtonTooltip => r'Kembali';
  @override String get closeButtonTooltip => r'Tutup';
  @override String get deleteButtonTooltip => r'Hapus';
  @override String get nextMonthTooltip => r'Bulan berikutnya';
  @override String get previousMonthTooltip => r'Bulan sebelumnya';
  @override String get nextPageTooltip => r'Halaman berikutnya';
  @override String get previousPageTooltip => r'Halaman sebelumnya';
  @override String get showMenuTooltip => r'Tampilkan menu';
  @override String get aboutListTileTitle => r'Tentang $applicationName';
  @override String get licensesPageTitle => r'Lisensi';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow dari $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow dari kira-kira $rowCount';
  @override String get rowsPerPageTitle => r'Baris per halaman:';
  @override String get tabLabel => r'Tab $tabIndex dari $tabCount';
  @override String get selectedRowCountTitleOne => r'1 item dipilih';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount item dipilih';
  @override String get cancelButtonLabel => r'BATAL';
  @override String get closeButtonLabel => r'TUTUP';
  @override String get continueButtonLabel => r'LANJUTKAN';
  @override String get copyButtonLabel => r'SALIN';
  @override String get cutButtonLabel => r'POTONG';
  @override String get okButtonLabel => r'Oke';
  @override String get pasteButtonLabel => r'TEMPEL';
  @override String get selectAllButtonLabel => r'PILIH SEMUA';
  @override String get viewLicensesButtonLabel => r'LIHAT LISENSI';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Pilih jam';
  @override String get timePickerMinuteModeAnnouncement => r'Pilih menit';
  @override String get modalBarrierDismissLabel => r'Tutup';
  @override String get signedInLabel => r'Telah login';
  @override String get hideAccountsLabel => r'Sembunyikan akun';
  @override String get showAccountsLabel => r'Tampilkan akun';
  @override String get drawerLabel => r'Menu navigasi';
  @override String get popupMenuLabel => r'Menu pop-up';
  @override String get dialogLabel => r'Dialog';
  @override String get alertDialogLabel => r'Waspada';
  @override String get searchFieldLabel => r'Pencarian';
}

// ignore: camel_case_types
class _Bundle_it extends TranslationBundle {
  const _Bundle_it() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleOne => r'1 elemento selezionato';
  @override String get openAppDrawerTooltip => r'Apri il menu di navigazione';
  @override String get backButtonTooltip => r'Indietro';
  @override String get closeButtonTooltip => r'Chiudi';
  @override String get deleteButtonTooltip => r'Elimina';
  @override String get nextMonthTooltip => r'Mese successivo';
  @override String get previousMonthTooltip => r'Mese precedente';
  @override String get nextPageTooltip => r'Pagina successiva';
  @override String get previousPageTooltip => r'Pagina precedente';
  @override String get showMenuTooltip => r'Mostra il menu';
  @override String get aboutListTileTitle => r'Informazioni su $applicationName';
  @override String get licensesPageTitle => r'Licenze';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow di $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow di circa $rowCount';
  @override String get rowsPerPageTitle => r'Righe per pagina:';
  @override String get tabLabel => r'Scheda $tabIndex di $tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount elementi selezionati';
  @override String get cancelButtonLabel => r'ANNULLA';
  @override String get closeButtonLabel => r'CHIUDI';
  @override String get continueButtonLabel => r'CONTINUA';
  @override String get copyButtonLabel => r'COPIA';
  @override String get cutButtonLabel => r'TAGLIA';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'INCOLLA';
  @override String get selectAllButtonLabel => r'SELEZIONA TUTTO';
  @override String get viewLicensesButtonLabel => r'VISUALIZZA LICENZE';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Seleziona le ore';
  @override String get timePickerMinuteModeAnnouncement => r'Seleziona i minuti';
  @override String get signedInLabel => r'Connesso';
  @override String get hideAccountsLabel => r'Nascondi account';
  @override String get showAccountsLabel => r'Mostra account';
  @override String get modalBarrierDismissLabel => r'Ignora';
  @override String get drawerLabel => r'Menu di navigazione';
  @override String get popupMenuLabel => r'Menu popup';
  @override String get dialogLabel => r'Finestra di dialogo';
  @override String get alertDialogLabel => r'Mettere in guardia';
  @override String get searchFieldLabel => r'Ricerca';
}

// ignore: camel_case_types
class _Bundle_ja extends TranslationBundle {
  const _Bundle_ja() : super(null);
  @override String get scriptCategory => r'dense';
  @override String get timeOfDayFormat => r'H:mm';
  @override String get selectedRowCountTitleOne => r'1 件のアイテムを選択中';
  @override String get openAppDrawerTooltip => r'ナビゲーション メニューを開く';
  @override String get backButtonTooltip => r'戻る';
  @override String get closeButtonTooltip => r'閉じる';
  @override String get deleteButtonTooltip => r'削除';
  @override String get nextMonthTooltip => r'来月';
  @override String get previousMonthTooltip => r'前月';
  @override String get nextPageTooltip => r'次のページ';
  @override String get previousPageTooltip => r'前のページ';
  @override String get showMenuTooltip => r'メニューを表示';
  @override String get aboutListTileTitle => r'$applicationName について';
  @override String get licensesPageTitle => r'ライセンス';
  @override String get pageRowsInfoTitle => r'$firstRow - $lastRow 行（合計 $rowCount 行）';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow 行（合計約 $rowCount 行）';
  @override String get rowsPerPageTitle => r'ページあたりの行数:';
  @override String get tabLabel => r'タブ: $tabIndex/$tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount 件のアイテムを選択中';
  @override String get cancelButtonLabel => r'キャンセル';
  @override String get closeButtonLabel => r'閉じる';
  @override String get continueButtonLabel => r'続行';
  @override String get copyButtonLabel => r'コピー';
  @override String get cutButtonLabel => r'切り取り';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'貼り付け';
  @override String get selectAllButtonLabel => r'すべて選択';
  @override String get viewLicensesButtonLabel => r'ライセンスを表示';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'時間を選択';
  @override String get timePickerMinuteModeAnnouncement => r'分を選択';
  @override String get signedInLabel => r'ログイン中';
  @override String get hideAccountsLabel => r'アカウントを非表示';
  @override String get showAccountsLabel => r'アカウントを表示';
  @override String get modalBarrierDismissLabel => r'閉じる';
  @override String get drawerLabel => r'ナビゲーション メニュー';
  @override String get popupMenuLabel => r'ポップアップ メニュー';
  @override String get dialogLabel => r'ダイアログ';
  @override String get alertDialogLabel => r'アラート';
  @override String get searchFieldLabel => r'サーチ';
}

// ignore: camel_case_types
class _Bundle_ko extends TranslationBundle {
  const _Bundle_ko() : super(null);
  @override String get scriptCategory => r'dense';
  @override String get timeOfDayFormat => r'a h:mm';
  @override String get openAppDrawerTooltip => r'탐색 메뉴 열기';
  @override String get backButtonTooltip => r'뒤로';
  @override String get closeButtonTooltip => r'닫기';
  @override String get deleteButtonTooltip => r'삭제';
  @override String get nextMonthTooltip => r'다음 달';
  @override String get previousMonthTooltip => r'지난달';
  @override String get nextPageTooltip => r'다음 페이지';
  @override String get previousPageTooltip => r'이전 페이지';
  @override String get showMenuTooltip => r'메뉴 표시';
  @override String get aboutListTileTitle => r'$applicationName 정보';
  @override String get licensesPageTitle => r'라이선스';
  @override String get pageRowsInfoTitle => r'$rowCount행 중 $firstRow~$lastRow행';
  @override String get pageRowsInfoTitleApproximate => r'약 $rowCount행 중 $firstRow~$lastRow행';
  @override String get rowsPerPageTitle => r'페이지당 행 수:';
  @override String get tabLabel => r'탭 $tabCount개 중 $tabIndex번째';
  @override String get selectedRowCountTitleOne => r'항목 1개 선택됨';
  @override String get selectedRowCountTitleOther => r'항목 $selectedRowCount개 선택됨';
  @override String get cancelButtonLabel => r'취소';
  @override String get closeButtonLabel => r'닫기';
  @override String get continueButtonLabel => r'계속';
  @override String get copyButtonLabel => r'복사';
  @override String get cutButtonLabel => r'잘라내기';
  @override String get okButtonLabel => r'확인';
  @override String get pasteButtonLabel => r'붙여넣기';
  @override String get selectAllButtonLabel => r'전체 선택';
  @override String get viewLicensesButtonLabel => r'라이선스 보기';
  @override String get anteMeridiemAbbreviation => r'오전';
  @override String get postMeridiemAbbreviation => r'오후';
  @override String get timePickerHourModeAnnouncement => r'시간 선택';
  @override String get timePickerMinuteModeAnnouncement => r'분 선택';
  @override String get signedInLabel => r'로그인됨';
  @override String get hideAccountsLabel => r'계정 숨기기';
  @override String get showAccountsLabel => r'계정 표시';
  @override String get modalBarrierDismissLabel => r'닫기';
  @override String get drawerLabel => r'탐색 메뉴';
  @override String get popupMenuLabel => r'팝업 메뉴';
  @override String get dialogLabel => r'대화상자';
  @override String get alertDialogLabel => r'경보';
  @override String get searchFieldLabel => r'수색';
}

// ignore: camel_case_types
class _Bundle_lt extends TranslationBundle {
  const _Bundle_lt() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Pasirinkti $selectedRowCount elementai';
  @override String get selectedRowCountTitleMany => r'Pasirinkta $selectedRowCount elemento';
  @override String get openAppDrawerTooltip => r'Atidaryti naršymo meniu';
  @override String get backButtonTooltip => r'Atgal';
  @override String get closeButtonTooltip => r'Uždaryti';
  @override String get deleteButtonTooltip => r'Ištrinti';
  @override String get nextMonthTooltip => r'Kitas mėnuo';
  @override String get previousMonthTooltip => r'Ankstesnis mėnuo';
  @override String get nextPageTooltip => r'Kitas puslapis';
  @override String get previousPageTooltip => r'Ankstesnis puslapis';
  @override String get showMenuTooltip => r'Rodyti meniu';
  @override String get aboutListTileTitle => r'Apie „$applicationName“';
  @override String get licensesPageTitle => r'Licencijos';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow iš $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow iš maždaug $rowCount';
  @override String get rowsPerPageTitle => r'Eilučių puslapyje:';
  @override String get tabLabel => r'$tabIndex skirtukas iš $tabCount';
  @override String get selectedRowCountTitleOne => r'Pasirinktas 1 elementas';
  @override String get selectedRowCountTitleOther => r'Pasirinkta $selectedRowCount elementų';
  @override String get cancelButtonLabel => r'ATŠAUKTI';
  @override String get closeButtonLabel => r'UŽDARYTI';
  @override String get continueButtonLabel => r'TĘSTI';
  @override String get copyButtonLabel => r'KOPIJUOTI';
  @override String get cutButtonLabel => r'IŠKIRPTI';
  @override String get okButtonLabel => r'GERAI';
  @override String get pasteButtonLabel => r'ĮKLIJUOTI';
  @override String get selectAllButtonLabel => r'PASIRINKTI VISKĄ';
  @override String get viewLicensesButtonLabel => r'PERŽIŪRĖTI LICENCIJAS';
  @override String get anteMeridiemAbbreviation => r'priešpiet';
  @override String get postMeridiemAbbreviation => r'popiet';
  @override String get timePickerHourModeAnnouncement => r'Pasirinkite valandas';
  @override String get timePickerMinuteModeAnnouncement => r'Pasirinkite minutes';
  @override String get modalBarrierDismissLabel => r'Atsisakyti';
  @override String get signedInLabel => r'Prisijungta';
  @override String get hideAccountsLabel => r'Slėpti paskyras';
  @override String get showAccountsLabel => r'Rodyti paskyras';
  @override String get drawerLabel => r'Naršymo meniu';
  @override String get popupMenuLabel => r'Iššokantysis meniu';
  @override String get dialogLabel => r'Dialogo langas';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_lv extends TranslationBundle {
  const _Bundle_lv() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Atvērt navigācijas izvēlni';
  @override String get backButtonTooltip => r'Atpakaļ';
  @override String get closeButtonTooltip => r'Aizvērt';
  @override String get deleteButtonTooltip => r'Dzēst';
  @override String get nextMonthTooltip => r'Nākamais mēnesis';
  @override String get previousMonthTooltip => r'Iepriekšējais mēnesis';
  @override String get nextPageTooltip => r'Nākamā lapa';
  @override String get previousPageTooltip => r'Iepriekšējā lapa';
  @override String get showMenuTooltip => r'Rādīt izvēlni';
  @override String get aboutListTileTitle => r'Par $applicationName';
  @override String get licensesPageTitle => r'Licences';
  @override String get pageRowsInfoTitle => r'$firstRow.–$lastRow. no $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow.–$lastRow. no aptuveni $rowCount';
  @override String get rowsPerPageTitle => r'Rindas lapā:';
  @override String get tabLabel => r'$tabIndex. cilne no $tabCount';
  @override String get selectedRowCountTitleZero => r'Nav atlasītu vienumu';
  @override String get selectedRowCountTitleOne => r'Atlasīts 1 vienums';
  @override String get selectedRowCountTitleOther => r'Atlasīti $selectedRowCount vienumi';
  @override String get cancelButtonLabel => r'ATCELT';
  @override String get closeButtonLabel => r'AIZVĒRT';
  @override String get continueButtonLabel => r'TURPINĀT';
  @override String get copyButtonLabel => r'KOPĒT';
  @override String get cutButtonLabel => r'IZGRIEZT';
  @override String get okButtonLabel => r'LABI';
  @override String get pasteButtonLabel => r'IELĪMĒT';
  @override String get selectAllButtonLabel => r'ATLASĪT VISU';
  @override String get viewLicensesButtonLabel => r'SKATĪT LICENCES';
  @override String get anteMeridiemAbbreviation => r'priekšpusdienā';
  @override String get postMeridiemAbbreviation => r'pēcpusdienā';
  @override String get timePickerHourModeAnnouncement => r'Atlasiet stundas';
  @override String get timePickerMinuteModeAnnouncement => r'Atlasiet minūtes';
  @override String get modalBarrierDismissLabel => r'Nerādīt';
  @override String get signedInLabel => r'Esat pierakstījies';
  @override String get hideAccountsLabel => r'Slēpt kontus';
  @override String get showAccountsLabel => r'Rādīt kontus';
  @override String get drawerLabel => r'Navigācijas izvēlne';
  @override String get popupMenuLabel => r'Uznirstošā izvēlne';
  @override String get dialogLabel => r'Dialoglodziņš';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_ms extends TranslationBundle {
  const _Bundle_ms() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'h:mm a';
  @override String get openAppDrawerTooltip => r'Buka menu navigasi';
  @override String get backButtonTooltip => r'Kembali';
  @override String get closeButtonTooltip => r'Tutup';
  @override String get deleteButtonTooltip => r'Padam';
  @override String get nextMonthTooltip => r'Bulan depan';
  @override String get previousMonthTooltip => r'Bulan sebelumnya';
  @override String get nextPageTooltip => r'Halaman seterusnya';
  @override String get previousPageTooltip => r'Halaman sebelumnya';
  @override String get showMenuTooltip => r'Tunjukkan menu';
  @override String get aboutListTileTitle => r'Perihal $applicationName';
  @override String get licensesPageTitle => r'Lesen';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow dari $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow dari kira-kira $rowCount';
  @override String get rowsPerPageTitle => r'Baris setiap halaman:';
  @override String get tabLabel => r'Tab $tabIndex dari $tabCount';
  @override String get selectedRowCountTitleZero => r'Tiada item dipilih';
  @override String get selectedRowCountTitleOne => r'1 item dipilih';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount item dipilih';
  @override String get cancelButtonLabel => r'BATAL';
  @override String get closeButtonLabel => r'TUTUP';
  @override String get continueButtonLabel => r'TERUSKAN';
  @override String get copyButtonLabel => r'SALIN';
  @override String get cutButtonLabel => r'POTONG';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'TAMPAL';
  @override String get selectAllButtonLabel => r'PILIH SEMUA';
  @override String get viewLicensesButtonLabel => r'LIHAT LESEN';
  @override String get anteMeridiemAbbreviation => r'PG';
  @override String get postMeridiemAbbreviation => r'PTG';
  @override String get timePickerHourModeAnnouncement => r'Pilih jam';
  @override String get timePickerMinuteModeAnnouncement => r'Pilih minit';
  @override String get modalBarrierDismissLabel => r'Tolak';
  @override String get signedInLabel => r'Dilog masuk';
  @override String get hideAccountsLabel => r'Sembunyikan akaun';
  @override String get showAccountsLabel => r'Tunjukkan akaun';
  @override String get drawerLabel => r'Menu navigasi';
  @override String get popupMenuLabel => r'Menu pop timbul';
  @override String get dialogLabel => r'Dialog';
  @override String get alertDialogLabel => r'Amaran';
  @override String get searchFieldLabel => r'Carian';
}

// ignore: camel_case_types
class _Bundle_nb extends TranslationBundle {
  const _Bundle_nb() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Åpne navigasjonsmenyen';
  @override String get backButtonTooltip => r'Tilbake';
  @override String get closeButtonTooltip => r'Lukk';
  @override String get deleteButtonTooltip => r'Slett';
  @override String get nextMonthTooltip => r'Neste måned';
  @override String get previousMonthTooltip => r'Forrige måned';
  @override String get nextPageTooltip => r'Neste side';
  @override String get previousPageTooltip => r'Forrige side';
  @override String get showMenuTooltip => r'Vis meny';
  @override String get aboutListTileTitle => r'Om $applicationName';
  @override String get licensesPageTitle => r'Lisenser';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow av $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow av omtrent $rowCount';
  @override String get rowsPerPageTitle => r'Rader per side:';
  @override String get tabLabel => r'Fane $tabIndex av $tabCount';
  @override String get selectedRowCountTitleOne => r'1 element er valgt';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount elementer er valgt';
  @override String get cancelButtonLabel => r'AVBRYT';
  @override String get closeButtonLabel => r'LUKK';
  @override String get continueButtonLabel => r'FORTSETT';
  @override String get copyButtonLabel => r'KOPIÉR';
  @override String get cutButtonLabel => r'KLIPP UT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'LIM INN';
  @override String get selectAllButtonLabel => r'VELG ALLE';
  @override String get viewLicensesButtonLabel => r'SE LISENSER';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Angi timer';
  @override String get timePickerMinuteModeAnnouncement => r'Angi minutter';
  @override String get modalBarrierDismissLabel => r'Avvis';
  @override String get signedInLabel => r'Pålogget';
  @override String get hideAccountsLabel => r'Skjul kontoer';
  @override String get showAccountsLabel => r'Vis kontoer';
  @override String get drawerLabel => r'Navigasjonsmeny';
  @override String get popupMenuLabel => r'Forgrunnsmeny';
  @override String get dialogLabel => r'Dialogboks';
  @override String get alertDialogLabel => r'Varsling';
  @override String get searchFieldLabel => r'Søke';
}

// ignore: camel_case_types
class _Bundle_nl extends TranslationBundle {
  const _Bundle_nl() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Navigatiemenu openen';
  @override String get backButtonTooltip => r'Terug';
  @override String get closeButtonTooltip => r'Sluiten';
  @override String get deleteButtonTooltip => r'Verwijderen';
  @override String get nextMonthTooltip => r'Volgende maand';
  @override String get previousMonthTooltip => r'Vorige maand';
  @override String get nextPageTooltip => r'Volgende pagina';
  @override String get previousPageTooltip => r'Vorige pagina';
  @override String get showMenuTooltip => r'Menu weergeven';
  @override String get aboutListTileTitle => r'Over $applicationName';
  @override String get licensesPageTitle => r'Licenties';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow van $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow van ongeveer $rowCount';
  @override String get rowsPerPageTitle => r'Rijen per pagina:';
  @override String get tabLabel => r'Tabblad $tabIndex van $tabCount';
  @override String get selectedRowCountTitleOne => r'1 item geselecteerd';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount items geselecteerd';
  @override String get cancelButtonLabel => r'ANNULEREN';
  @override String get closeButtonLabel => r'SLUITEN';
  @override String get continueButtonLabel => r'DOORGAAN';
  @override String get copyButtonLabel => r'KOPIËREN';
  @override String get cutButtonLabel => r'KNIPPEN';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'PLAKKEN';
  @override String get selectAllButtonLabel => r'ALLES SELECTEREN';
  @override String get viewLicensesButtonLabel => r'LICENTIES BEKIJKEN';
  @override String get anteMeridiemAbbreviation => r'am';
  @override String get postMeridiemAbbreviation => r'pm';
  @override String get timePickerHourModeAnnouncement => r'Uren selecteren';
  @override String get timePickerMinuteModeAnnouncement => r'Minuten selecteren';
  @override String get signedInLabel => r'Ingelogd';
  @override String get hideAccountsLabel => r'Accounts verbergen';
  @override String get showAccountsLabel => r'Accounts weergeven';
  @override String get modalBarrierDismissLabel => r'Sluiten';
  @override String get drawerLabel => r'Navigatiemenu';
  @override String get popupMenuLabel => r'Pop-upmenu';
  @override String get dialogLabel => r'Dialoogvenster';
  @override String get alertDialogLabel => r'Alarm';
  @override String get searchFieldLabel => r'Zoeken';
}

// ignore: camel_case_types
class _Bundle_pl extends TranslationBundle {
  const _Bundle_pl() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'$selectedRowCount wybrane elementy';
  @override String get selectedRowCountTitleMany => r'$selectedRowCount wybranych elementów';
  @override String get openAppDrawerTooltip => r'Otwórz menu nawigacyjne';
  @override String get backButtonTooltip => r'Wstecz';
  @override String get closeButtonTooltip => r'Zamknij';
  @override String get deleteButtonTooltip => r'Usuń';
  @override String get nextMonthTooltip => r'Następny miesiąc';
  @override String get previousMonthTooltip => r'Poprzedni miesiąc';
  @override String get nextPageTooltip => r'Następna strona';
  @override String get previousPageTooltip => r'Poprzednia strona';
  @override String get showMenuTooltip => r'Pokaż menu';
  @override String get aboutListTileTitle => r'$applicationName – informacje';
  @override String get licensesPageTitle => r'Licencje';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow z $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow z około $rowCount';
  @override String get rowsPerPageTitle => r'Wiersze na stronie:';
  @override String get tabLabel => r'Karta $tabIndex z $tabCount';
  @override String get selectedRowCountTitleOne => r'1 wybrany element';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount wybranego elementu';
  @override String get cancelButtonLabel => r'ANULUJ';
  @override String get closeButtonLabel => r'ZAMKNIJ';
  @override String get continueButtonLabel => r'DALEJ';
  @override String get copyButtonLabel => r'KOPIUJ';
  @override String get cutButtonLabel => r'WYTNIJ';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'WKLEJ';
  @override String get selectAllButtonLabel => r'ZAZNACZ WSZYSTKO';
  @override String get viewLicensesButtonLabel => r'WYŚWIETL LICENCJE';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Wybierz godziny';
  @override String get timePickerMinuteModeAnnouncement => r'Wybierz minuty';
  @override String get signedInLabel => r'Zalogowani użytkownicy';
  @override String get hideAccountsLabel => r'Ukryj konta';
  @override String get showAccountsLabel => r'Pokaż konta';
  @override String get modalBarrierDismissLabel => r'Zamknij';
  @override String get drawerLabel => r'Menu nawigacyjne';
  @override String get popupMenuLabel => r'Wyskakujące menu';
  @override String get dialogLabel => r'Okno dialogowe';
  @override String get alertDialogLabel => r'Alarm';
  @override String get searchFieldLabel => r'Szukaj';
}

// ignore: camel_case_types
class _Bundle_ps extends TranslationBundle {
  const _Bundle_ps() : super(null);
  @override String get scriptCategory => r'tall';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'د پرانیستی نیینګ مینو';
  @override String get backButtonTooltip => r'شاته';
  @override String get closeButtonTooltip => r'بنده';
  @override String get deleteButtonTooltip => r'';
  @override String get nextMonthTooltip => r'بله میاشت';
  @override String get previousMonthTooltip => r'تیره میاشت';
  @override String get nextPageTooltip => r'بله پاڼه';
  @override String get previousPageTooltip => r'مخکینی مخ';
  @override String get showMenuTooltip => r'غورنۍ ښودل';
  @override String get aboutListTileTitle => r'د $applicationName په اړه';
  @override String get licensesPageTitle => r'جوازونه';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow د $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow څخه $rowCount د';
  @override String get rowsPerPageTitle => r'د هرې پاڼې پاڼې:';
  @override String get tabLabel => r'$tabIndex د $tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount توکي غوره شوي';
  @override String get cancelButtonLabel => r'لغوه کول';
  @override String get closeButtonLabel => r'تړل';
  @override String get continueButtonLabel => r'منځپانګې';
  @override String get copyButtonLabel => r'کاپی';
  @override String get cutButtonLabel => r'کم کړئ';
  @override String get okButtonLabel => r'سمه ده';
  @override String get pasteButtonLabel => r'پیټ کړئ';
  @override String get selectAllButtonLabel => r'غوره کړئ';
  @override String get viewLicensesButtonLabel => r'لیدلس وګورئ';
  @override String get timePickerHourModeAnnouncement => r'وختونه وټاکئ';
  @override String get timePickerMinuteModeAnnouncement => r'منې غوره کړئ';
  @override String get signedInLabel => r'ننوتل';
  @override String get hideAccountsLabel => r'حسابونه پټ کړئ';
  @override String get showAccountsLabel => r'حسابونه ښکاره کړئ';
  @override String get modalBarrierDismissLabel => r'رد کړه';
  @override String get drawerLabel => r'د نیویگیشن مینو';
  @override String get popupMenuLabel => r'د پاپ اپ مینو';
  @override String get dialogLabel => r'خبرې اترې';
  @override String get alertDialogLabel => r'خبرتیا';
  @override String get searchFieldLabel => r'لټون';
}

// ignore: camel_case_types
class _Bundle_pt extends TranslationBundle {
  const _Bundle_pt() : super(null);
  @override String get anteMeridiemAbbreviation => r'Manhã';
  @override String get selectedRowCountTitleOne => r'1 item selecionado';
  @override String get postMeridiemAbbreviation => r'Tarde/noite';
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Abrir menu de navegação';
  @override String get backButtonTooltip => r'Voltar';
  @override String get closeButtonTooltip => r'Fechar';
  @override String get deleteButtonTooltip => r'Excluir';
  @override String get nextMonthTooltip => r'Próximo mês';
  @override String get previousMonthTooltip => r'Mês anterior';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get previousPageTooltip => r'Página anterior';
  @override String get showMenuTooltip => r'Mostrar menu';
  @override String get aboutListTileTitle => r'Sobre o app $applicationName';
  @override String get licensesPageTitle => r'Licenças';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow de aproximadamente $rowCount';
  @override String get rowsPerPageTitle => r'Linhas por página:';
  @override String get tabLabel => r'Guia $tabIndex de $tabCount';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount itens selecionados';
  @override String get cancelButtonLabel => r'CANCELAR';
  @override String get closeButtonLabel => r'FECHAR';
  @override String get continueButtonLabel => r'CONTINUAR';
  @override String get copyButtonLabel => r'COPIAR';
  @override String get cutButtonLabel => r'RECORTAR';
  @override String get okButtonLabel => r'Ok';
  @override String get pasteButtonLabel => r'COLAR';
  @override String get selectAllButtonLabel => r'SELECIONAR TUDO';
  @override String get viewLicensesButtonLabel => r'VER LICENÇAS';
  @override String get timePickerHourModeAnnouncement => r'Selecione as horas';
  @override String get timePickerMinuteModeAnnouncement => r'Selecione os minutos';
  @override String get signedInLabel => r'Conectado a';
  @override String get hideAccountsLabel => r'Ocultar contas';
  @override String get showAccountsLabel => r'Mostrar contas';
  @override String get modalBarrierDismissLabel => r'Dispensar';
  @override String get drawerLabel => r'Menu de navegação';
  @override String get popupMenuLabel => r'Menu pop-up';
  @override String get dialogLabel => r'Caixa de diálogo';
  @override String get alertDialogLabel => r'Alerta';
  @override String get searchFieldLabel => r'Pesquisa';
}

// ignore: camel_case_types
class _Bundle_ro extends TranslationBundle {
  const _Bundle_ro() : super(null);
  @override String get selectedRowCountTitleFew => r'$selectedRowCount articole selectate';
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Deschideți meniul de navigare';
  @override String get backButtonTooltip => r'Înapoi';
  @override String get closeButtonTooltip => r'Închideți';
  @override String get deleteButtonTooltip => r'Ștergeți';
  @override String get nextMonthTooltip => r'Luna viitoare';
  @override String get previousMonthTooltip => r'Luna trecută';
  @override String get nextPageTooltip => r'Pagina următoare';
  @override String get previousPageTooltip => r'Pagina anterioară';
  @override String get showMenuTooltip => r'Afișați meniul';
  @override String get aboutListTileTitle => r'Despre $applicationName';
  @override String get licensesPageTitle => r'Licențe';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow din $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow din aproximativ $rowCount';
  @override String get rowsPerPageTitle => r'Rânduri pe pagină:';
  @override String get tabLabel => r'Fila $tabIndex din $tabCount';
  @override String get selectedRowCountTitleZero => r'Nu există elemente selectate';
  @override String get selectedRowCountTitleOne => r'Un articol selectat';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount de articole selectate';
  @override String get cancelButtonLabel => r'ANULAȚI';
  @override String get closeButtonLabel => r'ÎNCHIDEȚI';
  @override String get continueButtonLabel => r'CONTINUAȚI';
  @override String get copyButtonLabel => r'COPIAȚI';
  @override String get cutButtonLabel => r'DECUPAȚI';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'INSERAȚI';
  @override String get selectAllButtonLabel => r'SELECTAȚI TOATE';
  @override String get viewLicensesButtonLabel => r'VEDEȚI LICENȚELE';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get timePickerHourModeAnnouncement => r'Selectați orele';
  @override String get timePickerMinuteModeAnnouncement => r'Selectați minutele';
  @override String get signedInLabel => r'V-ați conectat';
  @override String get hideAccountsLabel => r'Ascundeți conturile';
  @override String get showAccountsLabel => r'Afișați conturile';
  @override String get modalBarrierDismissLabel => r'Închideți';
  @override String get drawerLabel => r'Meniu de navigare';
  @override String get popupMenuLabel => r'Meniu pop-up';
  @override String get dialogLabel => r'Casetă de dialog';
  @override String get alertDialogLabel => r'Alerta';
  @override String get searchFieldLabel => r'Căutare';
}

// ignore: camel_case_types
class _Bundle_ru extends TranslationBundle {
  const _Bundle_ru() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'H:mm';
  @override String get selectedRowCountTitleFew => r'Выбрано $selectedRowCount объекта';
  @override String get selectedRowCountTitleMany => r'Выбрано $selectedRowCount объектов';
  @override String get openAppDrawerTooltip => r'Открыть меню навигации';
  @override String get backButtonTooltip => r'Назад';
  @override String get closeButtonTooltip => r'Закрыть';
  @override String get deleteButtonTooltip => r'Удалить';
  @override String get nextMonthTooltip => r'Следующий месяц';
  @override String get previousMonthTooltip => r'Предыдущий месяц';
  @override String get nextPageTooltip => r'Следующая страница';
  @override String get previousPageTooltip => r'Предыдущая страница';
  @override String get showMenuTooltip => r'Показать меню';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow из $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow из примерно $rowCount';
  @override String get rowsPerPageTitle => r'Строк на странице:';
  @override String get tabLabel => r'Вкладка $tabIndex из $tabCount';
  @override String get aboutListTileTitle => r'$applicationName: сведения';
  @override String get licensesPageTitle => r'Лицензии';
  @override String get selectedRowCountTitleZero => r'Строки не выбраны';
  @override String get selectedRowCountTitleOne => r'Выбран 1 объект';
  @override String get selectedRowCountTitleOther => r'Выбрано $selectedRowCount объекта';
  @override String get cancelButtonLabel => r'ОТМЕНА';
  @override String get closeButtonLabel => r'ЗАКРЫТЬ';
  @override String get continueButtonLabel => r'ПРОДОЛЖИТЬ';
  @override String get copyButtonLabel => r'КОПИРОВАТЬ';
  @override String get cutButtonLabel => r'ВЫРЕЗАТЬ';
  @override String get okButtonLabel => r'ОК';
  @override String get pasteButtonLabel => r'ВСТАВИТЬ';
  @override String get selectAllButtonLabel => r'ВЫБРАТЬ ВСЕ';
  @override String get viewLicensesButtonLabel => r'ЛИЦЕНЗИИ';
  @override String get anteMeridiemAbbreviation => r'АМ';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Выберите часы';
  @override String get timePickerMinuteModeAnnouncement => r'Выберите минуты';
  @override String get signedInLabel => r'Вход выполнен';
  @override String get hideAccountsLabel => r'Скрыть аккаунты';
  @override String get showAccountsLabel => r'Показать аккаунты';
  @override String get modalBarrierDismissLabel => r'Закрыть';
  @override String get drawerLabel => r'Меню навигации';
  @override String get popupMenuLabel => r'Всплывающее меню';
  @override String get dialogLabel => r'Диалоговое окно';
  @override String get alertDialogLabel => r'бдительный';
  @override String get searchFieldLabel => r'Поиск';
}

// ignore: camel_case_types
class _Bundle_sk extends TranslationBundle {
  const _Bundle_sk() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'$selectedRowCount vybraté položky';
  @override String get selectedRowCountTitleMany => r'$selectedRowCount items selected';
  @override String get openAppDrawerTooltip => r'Otvoriť navigačnú ponuku';
  @override String get backButtonTooltip => r'Späť';
  @override String get closeButtonTooltip => r'Zavrieť';
  @override String get deleteButtonTooltip => r'Odstrániť';
  @override String get nextMonthTooltip => r'Budúci mesiac';
  @override String get previousMonthTooltip => r'Predošlý mesiac';
  @override String get nextPageTooltip => r'Ďalšia strana';
  @override String get previousPageTooltip => r'Predchádzajúca stránka';
  @override String get showMenuTooltip => r'Zobraziť ponuku';
  @override String get aboutListTileTitle => r'$applicationName – informácie';
  @override String get licensesPageTitle => r'Licencie';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow z $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow z približne $rowCount';
  @override String get rowsPerPageTitle => r'Počet riadkov na stránku:';
  @override String get tabLabel => r'Karta $tabIndex z $tabCount';
  @override String get selectedRowCountTitleOne => r'1 vybratá položka';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount vybratých položiek';
  @override String get cancelButtonLabel => r'ZRUŠIŤ';
  @override String get closeButtonLabel => r'ZAVRIEŤ';
  @override String get continueButtonLabel => r'POKRAČOVAŤ';
  @override String get copyButtonLabel => r'KOPÍROVAŤ';
  @override String get cutButtonLabel => r'VYSTRIHNÚŤ';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'PRILEPIŤ';
  @override String get selectAllButtonLabel => r'VYBRAŤ VŠETKO';
  @override String get viewLicensesButtonLabel => r'ZOBRAZIŤ LICENCIE';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Vybrať hodiny';
  @override String get timePickerMinuteModeAnnouncement => r'Vybrať minúty';
  @override String get modalBarrierDismissLabel => r'Odmietnuť';
  @override String get signedInLabel => r'Prihlásili ste sa';
  @override String get hideAccountsLabel => r'Skryť účty';
  @override String get showAccountsLabel => r'Zobraziť účty';
  @override String get drawerLabel => r'Navigačná ponuka';
  @override String get popupMenuLabel => r'Kontextová ponuka';
  @override String get dialogLabel => r'Dialógové okno';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_sl extends TranslationBundle {
  const _Bundle_sl() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleTwo => r'Izbrana sta $selectedRowCount elementa';
  @override String get selectedRowCountTitleFew => r'Izbrani so $selectedRowCount elementi';
  @override String get openAppDrawerTooltip => r'Odpiranje menija za krmarjenje';
  @override String get backButtonTooltip => r'Nazaj';
  @override String get closeButtonTooltip => r'Zapiranje';
  @override String get deleteButtonTooltip => r'Brisanje';
  @override String get nextMonthTooltip => r'Naslednji mesec';
  @override String get previousMonthTooltip => r'Prejšnji mesec';
  @override String get nextPageTooltip => r'Naslednja stran';
  @override String get previousPageTooltip => r'Prejšnja stran';
  @override String get showMenuTooltip => r'Prikaz menija';
  @override String get aboutListTileTitle => r'O aplikaciji $applicationName';
  @override String get licensesPageTitle => r'Licence';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow od $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow od približno $rowCount';
  @override String get rowsPerPageTitle => r'Vrstice na stran:';
  @override String get tabLabel => r'Zavihek $tabIndex od $tabCount';
  @override String get selectedRowCountTitleOne => r'Izbran je 1 element';
  @override String get selectedRowCountTitleOther => r'Izbranih je $selectedRowCount elementov';
  @override String get cancelButtonLabel => r'PREKLIČI';
  @override String get closeButtonLabel => r'ZAPRI';
  @override String get continueButtonLabel => r'NAPREJ';
  @override String get copyButtonLabel => r'KOPIRAJ';
  @override String get cutButtonLabel => r'IZREŽI';
  @override String get okButtonLabel => r'V REDU';
  @override String get pasteButtonLabel => r'PRILEPI';
  @override String get selectAllButtonLabel => r'IZBERI VSE';
  @override String get viewLicensesButtonLabel => r'PRIKAŽI LICENCE';
  @override String get anteMeridiemAbbreviation => r'DOP.';
  @override String get postMeridiemAbbreviation => r'POP.';
  @override String get timePickerHourModeAnnouncement => r'Izberite ure';
  @override String get timePickerMinuteModeAnnouncement => r'Izberite minute';
  @override String get modalBarrierDismissLabel => r'Opusti';
  @override String get signedInLabel => r'Prijavljen';
  @override String get hideAccountsLabel => r'Skrivanje računov';
  @override String get showAccountsLabel => r'Prikaz računov';
  @override String get drawerLabel => r'Meni za krmarjenje';
  @override String get popupMenuLabel => r'Pojavni meni';
  @override String get dialogLabel => r'Pogovorno okno';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_sr extends TranslationBundle {
  const _Bundle_sr() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Изабране су $selectedRowCount ставке';
  @override String get openAppDrawerTooltip => r'Отворите мени за навигацију';
  @override String get backButtonTooltip => r'Назад';
  @override String get closeButtonTooltip => r'Затворите';
  @override String get deleteButtonTooltip => r'Избришите';
  @override String get nextMonthTooltip => r'Следећи месец';
  @override String get previousMonthTooltip => r'Претходни месец';
  @override String get nextPageTooltip => r'Следећа страница';
  @override String get previousPageTooltip => r'Претходна страница';
  @override String get showMenuTooltip => r'Прикажи мени';
  @override String get aboutListTileTitle => r'О апликацији $applicationName';
  @override String get licensesPageTitle => r'Лиценце';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow oд $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow oд приближно $rowCount';
  @override String get rowsPerPageTitle => r'Редова по страници:';
  @override String get tabLabel => r'$tabIndex. картица од $tabCount';
  @override String get selectedRowCountTitleOne => r'Изабрана је 1 ставка';
  @override String get selectedRowCountTitleOther => r'Изабрано је $selectedRowCount ставки';
  @override String get cancelButtonLabel => r'ОТКАЖИ';
  @override String get closeButtonLabel => r'ЗАТВОРИ';
  @override String get continueButtonLabel => r'НАСТАВИ';
  @override String get copyButtonLabel => r'КОПИРАЈ';
  @override String get cutButtonLabel => r'ИСЕЦИ';
  @override String get okButtonLabel => r'Потврди';
  @override String get pasteButtonLabel => r'НАЛЕПИ';
  @override String get selectAllButtonLabel => r'ИЗАБЕРИ СВЕ';
  @override String get viewLicensesButtonLabel => r'ПРИКАЖИ ЛИЦЕНЦЕ';
  @override String get anteMeridiemAbbreviation => r'пре подне';
  @override String get postMeridiemAbbreviation => r'по подне';
  @override String get timePickerHourModeAnnouncement => r'Изаберите сате';
  @override String get timePickerMinuteModeAnnouncement => r'Изаберите минуте';
  @override String get modalBarrierDismissLabel => r'Одбаци';
  @override String get signedInLabel => r'Пријављени сте';
  @override String get hideAccountsLabel => r'Сакриј налоге';
  @override String get showAccountsLabel => r'Прикажи налоге';
  @override String get drawerLabel => r'Мени за навигацију';
  @override String get popupMenuLabel => r'Искачући мени';
  @override String get dialogLabel => r'Дијалог';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_sv extends TranslationBundle {
  const _Bundle_sv() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Öppna navigeringsmenyn';
  @override String get backButtonTooltip => r'Tillbaka';
  @override String get closeButtonTooltip => r'Stäng';
  @override String get deleteButtonTooltip => r'Radera';
  @override String get nextMonthTooltip => r'Nästa månad';
  @override String get previousMonthTooltip => r'Föregående månad';
  @override String get nextPageTooltip => r'Nästa sida';
  @override String get previousPageTooltip => r'Föregående sida';
  @override String get showMenuTooltip => r'Visa meny';
  @override String get aboutListTileTitle => r'Om $applicationName';
  @override String get licensesPageTitle => r'Licenser';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow av $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow av ungefär $rowCount';
  @override String get rowsPerPageTitle => r'Rader per sida:';
  @override String get tabLabel => r'Flik $tabIndex av $tabCount';
  @override String get selectedRowCountTitleOne => r'1 objekt har markerats';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount objekt har markerats';
  @override String get cancelButtonLabel => r'AVBRYT';
  @override String get closeButtonLabel => r'STÄNG';
  @override String get continueButtonLabel => r'FORTSÄTT';
  @override String get copyButtonLabel => r'KOPIERA';
  @override String get cutButtonLabel => r'KLIPP UT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'KLISTRA IN';
  @override String get selectAllButtonLabel => r'MARKERA ALLA';
  @override String get viewLicensesButtonLabel => r'VISA LICENSER';
  @override String get anteMeridiemAbbreviation => r'FM';
  @override String get postMeridiemAbbreviation => r'EM';
  @override String get timePickerHourModeAnnouncement => r'Välj timmar';
  @override String get timePickerMinuteModeAnnouncement => r'Välj minuter';
  @override String get modalBarrierDismissLabel => r'Stäng';
  @override String get signedInLabel => r'Inloggad';
  @override String get hideAccountsLabel => r'Dölj konton';
  @override String get showAccountsLabel => r'Visa konton';
  @override String get drawerLabel => r'Navigeringsmeny';
  @override String get popupMenuLabel => r'Popup-meny';
  @override String get dialogLabel => r'Dialogruta';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_th extends TranslationBundle {
  const _Bundle_th() : super(null);
  @override String get scriptCategory => r'tall';
  @override String get timeOfDayFormat => r'ah:mm';
  @override String get openAppDrawerTooltip => r'เปิดเมนูการนำทาง';
  @override String get backButtonTooltip => r'กลับ';
  @override String get closeButtonTooltip => r'ปิด';
  @override String get deleteButtonTooltip => r'ลบ';
  @override String get nextMonthTooltip => r'เดือนหน้า';
  @override String get previousMonthTooltip => r'เดือนที่แล้ว';
  @override String get nextPageTooltip => r'หน้าถัดไป';
  @override String get previousPageTooltip => r'หน้าก่อน';
  @override String get showMenuTooltip => r'แสดงเมนู';
  @override String get aboutListTileTitle => r'เกี่ยวกับ $applicationName';
  @override String get licensesPageTitle => r'ใบอนุญาต';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow จาก $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow จากประมาณ $rowCount';
  @override String get rowsPerPageTitle => r'แถวต่อหน้า:';
  @override String get tabLabel => r'แท็บที่ $tabIndex จาก $tabCount';
  @override String get selectedRowCountTitleOne => r'เลือกแล้ว 1 รายการ';
  @override String get selectedRowCountTitleOther => r'เลือกแล้ว $selectedRowCount รายการ';
  @override String get cancelButtonLabel => r'ยกเลิก';
  @override String get closeButtonLabel => r'ปิด';
  @override String get continueButtonLabel => r'ต่อไป';
  @override String get copyButtonLabel => r'คัดลอก';
  @override String get cutButtonLabel => r'ตัด';
  @override String get okButtonLabel => r'ตกลง';
  @override String get pasteButtonLabel => r'วาง';
  @override String get selectAllButtonLabel => r'เลือกทั้งหมด';
  @override String get viewLicensesButtonLabel => r'ดูใบอนุญาต';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'เลือกชั่วโมง';
  @override String get timePickerMinuteModeAnnouncement => r'เลือกนาที';
  @override String get signedInLabel => r'ลงชื่อเข้าใช้';
  @override String get hideAccountsLabel => r'ซ่อนบัญชี';
  @override String get showAccountsLabel => r'แสดงบัญชี';
  @override String get modalBarrierDismissLabel => r'ปิด';
  @override String get drawerLabel => r'เมนูการนำทาง';
  @override String get popupMenuLabel => r'เมนูป๊อปอัป';
  @override String get dialogLabel => r'กล่องโต้ตอบ';
  @override String get alertDialogLabel => r'เตือนภัย';
  @override String get searchFieldLabel => r'ค้นหา';
}

// ignore: camel_case_types
class _Bundle_tl extends TranslationBundle {
  const _Bundle_tl() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Buksan ang menu ng navigation';
  @override String get backButtonTooltip => r'Bumalik';
  @override String get closeButtonTooltip => r'Isara';
  @override String get deleteButtonTooltip => r'I-delete';
  @override String get nextMonthTooltip => r'Susunod na buwan';
  @override String get previousMonthTooltip => r'Nakaraang buwan';
  @override String get nextPageTooltip => r'Susunod na page';
  @override String get previousPageTooltip => r'Nakaraang page';
  @override String get showMenuTooltip => r'Ipakita ang menu';
  @override String get aboutListTileTitle => r'Tungkol sa $applicationName';
  @override String get licensesPageTitle => r'Mga Lisensya';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow ng $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow ng humigit kumulang $rowCount';
  @override String get rowsPerPageTitle => r'Mga row bawat page:';
  @override String get tabLabel => r'Tab $tabIndex ng $tabCount';
  @override String get selectedRowCountTitleOne => r'1 item ang napili';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount na item ang napili';
  @override String get cancelButtonLabel => r'KANSELAHIN';
  @override String get closeButtonLabel => r'ISARA';
  @override String get continueButtonLabel => r'MAGPATULOY';
  @override String get copyButtonLabel => r'KOPYAHIN';
  @override String get cutButtonLabel => r'I-CUT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'I-PASTE';
  @override String get selectAllButtonLabel => r'PILIIN LAHAT';
  @override String get viewLicensesButtonLabel => r'TINGNAN ANG MGA LISENSYA';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'Pumili ng mga oras';
  @override String get timePickerMinuteModeAnnouncement => r'Pumili ng mga minuto';
  @override String get modalBarrierDismissLabel => r'I-dismiss';
  @override String get signedInLabel => r'Naka-sign in';
  @override String get hideAccountsLabel => r'Itago ang mga account';
  @override String get showAccountsLabel => r'Ipakita ang mga account';
  @override String get drawerLabel => r'Menu ng navigation';
  @override String get popupMenuLabel => r'Popup na menu';
  @override String get dialogLabel => r'Dialog';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_tr extends TranslationBundle {
  const _Bundle_tr() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Gezinme menüsünü aç';
  @override String get backButtonTooltip => r'Geri';
  @override String get closeButtonTooltip => r'Kapat';
  @override String get deleteButtonTooltip => r'Sil';
  @override String get nextMonthTooltip => r'Gelecek ay';
  @override String get previousMonthTooltip => r'Önceki ay';
  @override String get nextPageTooltip => r'Sonraki sayfa';
  @override String get previousPageTooltip => r'Önceki sayfa';
  @override String get showMenuTooltip => r'Menüyü göster';
  @override String get aboutListTileTitle => r'$applicationName Hakkında';
  @override String get licensesPageTitle => r'Lisanslar';
  @override String get pageRowsInfoTitle => r'$firstRow-$lastRow / $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow-$lastRow / $rowCount';
  @override String get rowsPerPageTitle => r'Sayfa başına satır sayısı:';
  @override String get tabLabel => r'Sekme $tabIndex / $tabCount';
  @override String get selectedRowCountTitleOne => r'1 öğe seçildi';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount öğe seçildi';
  @override String get cancelButtonLabel => r'İPTAL';
  @override String get closeButtonLabel => r'KAPAT';
  @override String get continueButtonLabel => r'DEVAM';
  @override String get copyButtonLabel => r'KOPYALA';
  @override String get cutButtonLabel => r'KES';
  @override String get okButtonLabel => r'Tamam';
  @override String get pasteButtonLabel => r'YAPIŞTIR';
  @override String get selectAllButtonLabel => r'TÜMÜNÜ SEÇ';
  @override String get viewLicensesButtonLabel => r'LİSANLARI GÖSTER';
  @override String get anteMeridiemAbbreviation => r'ÖÖ';
  @override String get postMeridiemAbbreviation => r'ÖS';
  @override String get timePickerHourModeAnnouncement => r'Saati seçin';
  @override String get timePickerMinuteModeAnnouncement => r'Dakikayı seçin';
  @override String get signedInLabel => r'Oturum açıldı';
  @override String get hideAccountsLabel => r'Hesapları gizle';
  @override String get showAccountsLabel => r'Hesapları göster';
  @override String get modalBarrierDismissLabel => r'Kapat';
  @override String get drawerLabel => r'Gezinme menüsü';
  @override String get popupMenuLabel => r'Popup menü';
  @override String get dialogLabel => r'İletişim kutusu';
  @override String get alertDialogLabel => r'Alarm';
  @override String get searchFieldLabel => r'Arama';
}

// ignore: camel_case_types
class _Bundle_uk extends TranslationBundle {
  const _Bundle_uk() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get selectedRowCountTitleFew => r'Вибрано $selectedRowCount елементи';
  @override String get selectedRowCountTitleMany => r'Вибрано $selectedRowCount елементів';
  @override String get openAppDrawerTooltip => r'Відкрити меню навігації';
  @override String get backButtonTooltip => r'Назад';
  @override String get closeButtonTooltip => r'Закрити';
  @override String get deleteButtonTooltip => r'Видалити';
  @override String get nextMonthTooltip => r'Наступний місяць';
  @override String get previousMonthTooltip => r'Попередній місяць';
  @override String get nextPageTooltip => r'Наступна сторінка';
  @override String get previousPageTooltip => r'Попередня сторінка';
  @override String get showMenuTooltip => r'Показати меню';
  @override String get aboutListTileTitle => r'Про додаток $applicationName';
  @override String get licensesPageTitle => r'Ліцензії';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow з $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow з приблизно $rowCount';
  @override String get rowsPerPageTitle => r'Рядків на сторінці:';
  @override String get tabLabel => r'Вкладка $tabIndex з $tabCount';
  @override String get selectedRowCountTitleOne => r'Вибрано 1 елемент';
  @override String get selectedRowCountTitleOther => r'Вибрано $selectedRowCount елемента';
  @override String get cancelButtonLabel => r'СКАСУВАТИ';
  @override String get closeButtonLabel => r'ЗАКРИТИ';
  @override String get continueButtonLabel => r'ПРОДОВЖИТИ';
  @override String get copyButtonLabel => r'КОПІЮВАТИ';
  @override String get cutButtonLabel => r'ВИРІЗАТИ';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'ВСТАВИТИ';
  @override String get selectAllButtonLabel => r'ВИБРАТИ ВСІ';
  @override String get viewLicensesButtonLabel => r'ПЕРЕГЛЯНУТИ ЛІЦЕНЗІЇ';
  @override String get anteMeridiemAbbreviation => r'дп';
  @override String get postMeridiemAbbreviation => r'пп';
  @override String get timePickerHourModeAnnouncement => r'Виберіть години';
  @override String get timePickerMinuteModeAnnouncement => r'Виберіть хвилини';
  @override String get modalBarrierDismissLabel => r'Усунути';
  @override String get signedInLabel => r'Ви ввійшли';
  @override String get hideAccountsLabel => r'Сховати облікові записи';
  @override String get showAccountsLabel => r'Показати облікові записи';
  @override String get drawerLabel => r'Меню навігації';
  @override String get popupMenuLabel => r'Спливаюче меню';
  @override String get dialogLabel => r'Вікно';
  @override String get alertDialogLabel => r'TBD';
  @override String get searchFieldLabel => r'TBD';
}

// ignore: camel_case_types
class _Bundle_ur extends TranslationBundle {
  const _Bundle_ur() : super(null);
  @override String get scriptCategory => r'tall';
  @override String get timeOfDayFormat => r'h:mm a';
  @override String get selectedRowCountTitleOne => r'1 آئٹم منتخب کیا گیا';
  @override String get openAppDrawerTooltip => r'نیویگیشن مینو کھولیں';
  @override String get backButtonTooltip => r'پیچھے';
  @override String get closeButtonTooltip => r'بند کریں';
  @override String get deleteButtonTooltip => r'حذف کریں';
  @override String get nextMonthTooltip => r'اگلا مہینہ';
  @override String get previousMonthTooltip => r'پچھلا مہینہ';
  @override String get nextPageTooltip => r'اگلا صفحہ';
  @override String get previousPageTooltip => r'گزشتہ صفحہ';
  @override String get showMenuTooltip => r'مینو دکھائیں';
  @override String get aboutListTileTitle => r'$applicationName کے بارے میں';
  @override String get licensesPageTitle => r'لائسنسز';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow از $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow $rowCount میں سے تقریباً';
  @override String get rowsPerPageTitle => r'قطاریں فی صفحہ:';
  @override String get tabLabel => r'$tabCount میں سے $tabIndex ٹیب';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount آئٹمز منتخب کیے گئے';
  @override String get cancelButtonLabel => r'منسوخ کریں';
  @override String get closeButtonLabel => r'بند کریں';
  @override String get continueButtonLabel => r'جاری رکھیں';
  @override String get copyButtonLabel => r'کاپی کریں';
  @override String get cutButtonLabel => r'کٹ کریں';
  @override String get okButtonLabel => r'ٹھیک ہے';
  @override String get pasteButtonLabel => r'پیسٹ کریں';
  @override String get selectAllButtonLabel => r'سبھی منتخب کریں';
  @override String get viewLicensesButtonLabel => r'لائسنسز دیکھیں';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get timePickerHourModeAnnouncement => r'گھنٹے منتخب کریں';
  @override String get timePickerMinuteModeAnnouncement => r'منٹ منتخب کریں';
  @override String get signedInLabel => r'سائن ان کردہ ہے';
  @override String get hideAccountsLabel => r'اکاؤنٹس چھپائیں';
  @override String get showAccountsLabel => r'اکاؤنٹس دکھائیں';
  @override String get modalBarrierDismissLabel => r'برخاست کریں';
  @override String get drawerLabel => r'نیویگیشن مینو';
  @override String get popupMenuLabel => r'پاپ اپ مینو';
  @override String get dialogLabel => r'ڈائلاگ';
  @override String get alertDialogLabel => r'انتباہ';
  @override String get searchFieldLabel => r'تلاش کریں';
}

// ignore: camel_case_types
class _Bundle_vi extends TranslationBundle {
  const _Bundle_vi() : super(null);
  @override String get scriptCategory => r'English-like';
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get openAppDrawerTooltip => r'Mở menu di chuyển';
  @override String get backButtonTooltip => r'Quay lại';
  @override String get closeButtonTooltip => r'Đóng';
  @override String get deleteButtonTooltip => r'Xóa';
  @override String get nextMonthTooltip => r'Tháng sau';
  @override String get previousMonthTooltip => r'Tháng trước';
  @override String get nextPageTooltip => r'Trang tiếp theo';
  @override String get previousPageTooltip => r'Trang trước';
  @override String get showMenuTooltip => r'Hiển thị menu';
  @override String get aboutListTileTitle => r'Giới thiệu về $applicationName';
  @override String get licensesPageTitle => r'Giấy phép';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow trong tổng số $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow trong tổng số khoảng $rowCount';
  @override String get rowsPerPageTitle => r'Số hàng mỗi trang:';
  @override String get tabLabel => r'Tab $tabIndex trong tổng số $tabCount';
  @override String get selectedRowCountTitleOne => r'Đã chọn 1 mục';
  @override String get selectedRowCountTitleOther => r'Đã chọn $selectedRowCount mục';
  @override String get cancelButtonLabel => r'HỦY';
  @override String get closeButtonLabel => r'ĐÓNG';
  @override String get continueButtonLabel => r'TIẾP TỤC';
  @override String get copyButtonLabel => r'SAO CHÉP';
  @override String get cutButtonLabel => r'CẮT';
  @override String get okButtonLabel => r'OK';
  @override String get pasteButtonLabel => r'DÁN';
  @override String get selectAllButtonLabel => r'CHỌN TẤT CẢ';
  @override String get viewLicensesButtonLabel => r'XEM GIẤY PHÉP';
  @override String get anteMeridiemAbbreviation => r'SÁNG';
  @override String get postMeridiemAbbreviation => r'CHIỀU';
  @override String get timePickerHourModeAnnouncement => r'Chọn giờ';
  @override String get timePickerMinuteModeAnnouncement => r'Chọn phút';
  @override String get modalBarrierDismissLabel => r'Bỏ qua';
  @override String get signedInLabel => r'Đã đăng nhập';
  @override String get hideAccountsLabel => r'Ẩn tài khoản';
  @override String get showAccountsLabel => r'Hiển thị tài khoản';
  @override String get drawerLabel => r'Menu di chuyển';
  @override String get popupMenuLabel => r'Menu bật lên';
  @override String get dialogLabel => r'Hộp thoại';
  @override String get alertDialogLabel => r'Hộp thoại';
  @override String get searchFieldLabel => r'Tìm kiếm';
}

// ignore: camel_case_types
class _Bundle_zh extends TranslationBundle {
  const _Bundle_zh() : super(null);
  @override String get scriptCategory => r'dense';
  @override String get timeOfDayFormat => r'ah:mm';
  @override String get selectedRowCountTitleOne => r'已选择 1 项内容';
  @override String get openAppDrawerTooltip => r'打开导航菜单';
  @override String get backButtonTooltip => r'返回';
  @override String get nextPageTooltip => r'下一页';
  @override String get previousPageTooltip => r'上一页';
  @override String get showMenuTooltip => r'显示菜单';
  @override String get aboutListTileTitle => r'关于$applicationName';
  @override String get licensesPageTitle => r'许可';
  @override String get pageRowsInfoTitle => r'第 $firstRow-$lastRow 行（共 $rowCount 行）';
  @override String get pageRowsInfoTitleApproximate => r'第 $firstRow-$lastRow 行（共约 $rowCount 行）';
  @override String get rowsPerPageTitle => r'每页行数：';
  @override String get tabLabel => r'第 $tabIndex 个标签，共 $tabCount 个';
  @override String get selectedRowCountTitleOther => r'已选择 $selectedRowCount 项内容';
  @override String get cancelButtonLabel => r'取消';
  @override String get continueButtonLabel => r'继续';
  @override String get closeButtonLabel => r'关闭';
  @override String get copyButtonLabel => r'复制';
  @override String get cutButtonLabel => r'剪切';
  @override String get okButtonLabel => r'确定';
  @override String get pasteButtonLabel => r'粘贴';
  @override String get selectAllButtonLabel => r'全选';
  @override String get viewLicensesButtonLabel => r'查看许可';
  @override String get closeButtonTooltip => r'关闭';
  @override String get deleteButtonTooltip => r'删除';
  @override String get nextMonthTooltip => r'下个月';
  @override String get previousMonthTooltip => r'上个月';
  @override String get anteMeridiemAbbreviation => r'上午';
  @override String get postMeridiemAbbreviation => r'下午';
  @override String get timePickerHourModeAnnouncement => r'选择小时';
  @override String get timePickerMinuteModeAnnouncement => r'选择分钟';
  @override String get signedInLabel => r'已登录';
  @override String get hideAccountsLabel => r'隐藏帐号';
  @override String get showAccountsLabel => r'显示帐号';
  @override String get modalBarrierDismissLabel => r'关闭';
  @override String get drawerLabel => r'导航菜单';
  @override String get popupMenuLabel => r'弹出菜单';
  @override String get dialogLabel => r'对话框';
  @override String get alertDialogLabel => r'警报';
  @override String get searchFieldLabel => r'搜索';
}

// ignore: camel_case_types
class _Bundle_de_CH extends TranslationBundle {
  const _Bundle_de_CH() : super(const _Bundle_de());
  @override String get closeButtonTooltip => r'Schliessen';
  @override String get modalBarrierDismissLabel => r'Schliessen';
}

// ignore: camel_case_types
class _Bundle_en_AU extends TranslationBundle {
  const _Bundle_en_AU() : super(const _Bundle_en());
  @override String get licensesPageTitle => r'Licences';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_CA extends TranslationBundle {
  const _Bundle_en_CA() : super(const _Bundle_en());
  @override String get licensesPageTitle => r'Licences';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_GB extends TranslationBundle {
  const _Bundle_en_GB() : super(const _Bundle_en());
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get licensesPageTitle => r'Licences';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_IE extends TranslationBundle {
  const _Bundle_en_IE() : super(const _Bundle_en());
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get licensesPageTitle => r'Licences';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_IN extends TranslationBundle {
  const _Bundle_en_IN() : super(const _Bundle_en());
  @override String get licensesPageTitle => r'Licences';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_SG extends TranslationBundle {
  const _Bundle_en_SG() : super(const _Bundle_en());
  @override String get licensesPageTitle => r'Licences';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_en_ZA extends TranslationBundle {
  const _Bundle_en_ZA() : super(const _Bundle_en());
  @override String get timeOfDayFormat => r'HH:mm';
  @override String get viewLicensesButtonLabel => r'VIEW LICENCES';
  @override String get licensesPageTitle => r'Licences';
  @override String get popupMenuLabel => r'Pop-up menu';
  @override String get dialogLabel => r'Dialogue';
}

// ignore: camel_case_types
class _Bundle_es_419 extends TranslationBundle {
  const _Bundle_es_419() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_AR extends TranslationBundle {
  const _Bundle_es_AR() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_BO extends TranslationBundle {
  const _Bundle_es_BO() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_CL extends TranslationBundle {
  const _Bundle_es_CL() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_CO extends TranslationBundle {
  const _Bundle_es_CO() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_CR extends TranslationBundle {
  const _Bundle_es_CR() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_DO extends TranslationBundle {
  const _Bundle_es_DO() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_EC extends TranslationBundle {
  const _Bundle_es_EC() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_GT extends TranslationBundle {
  const _Bundle_es_GT() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_HN extends TranslationBundle {
  const _Bundle_es_HN() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_MX extends TranslationBundle {
  const _Bundle_es_MX() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_NI extends TranslationBundle {
  const _Bundle_es_NI() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_PA extends TranslationBundle {
  const _Bundle_es_PA() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_PE extends TranslationBundle {
  const _Bundle_es_PE() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_PR extends TranslationBundle {
  const _Bundle_es_PR() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_PY extends TranslationBundle {
  const _Bundle_es_PY() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_SV extends TranslationBundle {
  const _Bundle_es_SV() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_US extends TranslationBundle {
  const _Bundle_es_US() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get timeOfDayFormat => r'h:mm a';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_UY extends TranslationBundle {
  const _Bundle_es_UY() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_es_VE extends TranslationBundle {
  const _Bundle_es_VE() : super(const _Bundle_es());
  @override String get modalBarrierDismissLabel => r'Descartar';
  @override String get signedInLabel => r'Cuenta con la que accediste';
  @override String get openAppDrawerTooltip => r'Abrir menú de navegación';
  @override String get deleteButtonTooltip => r'Borrar';
  @override String get nextMonthTooltip => r'Próximo mes';
  @override String get nextPageTooltip => r'Próxima página';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow–$lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow–$lastRow de aproximadamente $rowCount';
  @override String get selectedRowCountTitleOne => r'Se seleccionó 1 elemento';
  @override String get selectedRowCountTitleOther => r'Se seleccionaron $selectedRowCount elementos';
  @override String get anteMeridiemAbbreviation => r'a.m.';
  @override String get postMeridiemAbbreviation => r'p.m.';
  @override String get dialogLabel => r'Diálogo';
}

// ignore: camel_case_types
class _Bundle_fr_CA extends TranslationBundle {
  const _Bundle_fr_CA() : super(const _Bundle_fr());
  @override String get timeOfDayFormat => r'HH ' "'" r'h' "'" r' mm';
}

// ignore: camel_case_types
class _Bundle_pt_PT extends TranslationBundle {
  const _Bundle_pt_PT() : super(const _Bundle_pt());
  @override String get tabLabel => r'Separador $tabIndex de $tabCount';
  @override String get signedInLabel => r'Com sessão iniciada';
  @override String get timePickerMinuteModeAnnouncement => r'Selecionar minutos';
  @override String get timePickerHourModeAnnouncement => r'Selecionar horas';
  @override String get deleteButtonTooltip => r'Eliminar';
  @override String get nextMonthTooltip => r'Mês seguinte';
  @override String get nextPageTooltip => r'Página seguinte';
  @override String get aboutListTileTitle => r'Acerca de $applicationName';
  @override String get pageRowsInfoTitle => r'$firstRow a $lastRow de $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow a $lastRow de cerca de $rowCount';
  @override String get cutButtonLabel => r'CORTAR';
  @override String get okButtonLabel => r'OK';
  @override String get anteMeridiemAbbreviation => r'AM';
  @override String get postMeridiemAbbreviation => r'PM';
  @override String get modalBarrierDismissLabel => r'Ignorar';
}

// ignore: camel_case_types
class _Bundle_sr_Latn extends TranslationBundle {
  const _Bundle_sr_Latn() : super(const _Bundle_sr());
  @override String get selectedRowCountTitleFew => r'Izabrane su $selectedRowCount stavke';
  @override String get openAppDrawerTooltip => r'Otvorite meni za navigaciju';
  @override String get backButtonTooltip => r'Nazad';
  @override String get closeButtonTooltip => r'Zatvorite';
  @override String get deleteButtonTooltip => r'Izbrišite';
  @override String get nextMonthTooltip => r'Sledeći mesec';
  @override String get previousMonthTooltip => r'Prethodni mesec';
  @override String get nextPageTooltip => r'Sledeća stranica';
  @override String get previousPageTooltip => r'Prethodna stranica';
  @override String get showMenuTooltip => r'Prikaži meni';
  @override String get aboutListTileTitle => r'O aplikaciji $applicationName';
  @override String get licensesPageTitle => r'Licence';
  @override String get pageRowsInfoTitle => r'$firstRow – $lastRow od $rowCount';
  @override String get pageRowsInfoTitleApproximate => r'$firstRow – $lastRow od približno $rowCount';
  @override String get rowsPerPageTitle => r'Redova po stranici:';
  @override String get tabLabel => r'$tabIndex. kartica od $tabCount';
  @override String get selectedRowCountTitleOne => r'Izabrana je 1 stavka';
  @override String get selectedRowCountTitleOther => r'Izabrano je $selectedRowCount stavki';
  @override String get cancelButtonLabel => r'OTKAŽI';
  @override String get closeButtonLabel => r'ZATVORI';
  @override String get continueButtonLabel => r'NASTAVI';
  @override String get copyButtonLabel => r'KOPIRAJ';
  @override String get cutButtonLabel => r'ISECI';
  @override String get okButtonLabel => r'Potvrdi';
  @override String get pasteButtonLabel => r'NALEPI';
  @override String get selectAllButtonLabel => r'IZABERI SVE';
  @override String get viewLicensesButtonLabel => r'PRIKAŽI LICENCE';
  @override String get anteMeridiemAbbreviation => r'pre podne';
  @override String get postMeridiemAbbreviation => r'po podne';
  @override String get timePickerHourModeAnnouncement => r'Izaberite sate';
  @override String get timePickerMinuteModeAnnouncement => r'Izaberite minute';
  @override String get modalBarrierDismissLabel => r'Odbaci';
  @override String get signedInLabel => r'Prijavljeni ste';
  @override String get hideAccountsLabel => r'Sakrij naloge';
  @override String get showAccountsLabel => r'Prikaži naloge';
  @override String get drawerLabel => r'Meni za navigaciju';
  @override String get popupMenuLabel => r'Iskačući meni';
  @override String get dialogLabel => r'Dijalog';
}

// ignore: camel_case_types
class _Bundle_zh_HK extends TranslationBundle {
  const _Bundle_zh_HK() : super(const _Bundle_zh());
  @override String get tabLabel => r'第 $tabIndex 個分頁 (共 $tabCount 個)';
  @override String get showAccountsLabel => r'顯示帳戶';
  @override String get modalBarrierDismissLabel => r'關閉';
  @override String get hideAccountsLabel => r'隱藏帳戶';
  @override String get signedInLabel => r'已登入帳戶';
  @override String get openAppDrawerTooltip => r'開啟導覽選單';
  @override String get closeButtonTooltip => r'關閉';
  @override String get deleteButtonTooltip => r'刪除';
  @override String get nextMonthTooltip => r'下個月';
  @override String get previousMonthTooltip => r'上個月';
  @override String get nextPageTooltip => r'下一頁';
  @override String get previousPageTooltip => r'上一頁';
  @override String get showMenuTooltip => r'顯示選單';
  @override String get aboutListTileTitle => r'關於「$applicationName」';
  @override String get licensesPageTitle => r'授權';
  @override String get pageRowsInfoTitle => r'第 $firstRow - $lastRow 列 (總共 $rowCount 列)';
  @override String get pageRowsInfoTitleApproximate => r'第 $firstRow - $lastRow 列 (總共約 $rowCount 列)';
  @override String get rowsPerPageTitle => r'每頁列數：';
  @override String get selectedRowCountTitleOne => r'已選取 1 個項目';
  @override String get selectedRowCountTitleOther => r'已選取 $selectedRowCount 個項目';
  @override String get closeButtonLabel => r'關閉';
  @override String get continueButtonLabel => r'繼續';
  @override String get copyButtonLabel => r'複製';
  @override String get cutButtonLabel => r'剪下';
  @override String get okButtonLabel => r'確定';
  @override String get pasteButtonLabel => r'貼上';
  @override String get selectAllButtonLabel => r'全選';
  @override String get viewLicensesButtonLabel => r'查看授權';
  @override String get timePickerHourModeAnnouncement => r'選取小時數';
  @override String get timePickerMinuteModeAnnouncement => r'選取分鐘數';
  @override String get drawerLabel => r'導覽選單';
  @override String get popupMenuLabel => r'彈出式選單';
  @override String get dialogLabel => r'對話方塊';
}

// ignore: camel_case_types
class _Bundle_zh_TW extends TranslationBundle {
  const _Bundle_zh_TW() : super(const _Bundle_zh());
  @override String get tabLabel => r'第 $tabIndex 個分頁 (共 $tabCount 個)';
  @override String get showAccountsLabel => r'顯示帳戶';
  @override String get modalBarrierDismissLabel => r'關閉';
  @override String get hideAccountsLabel => r'隱藏帳戶';
  @override String get signedInLabel => r'已登入帳戶';
  @override String get openAppDrawerTooltip => r'開啟導覽選單';
  @override String get closeButtonTooltip => r'關閉';
  @override String get deleteButtonTooltip => r'刪除';
  @override String get nextMonthTooltip => r'下個月';
  @override String get previousMonthTooltip => r'上個月';
  @override String get nextPageTooltip => r'下一頁';
  @override String get previousPageTooltip => r'上一頁';
  @override String get showMenuTooltip => r'顯示選單';
  @override String get aboutListTileTitle => r'關於「$applicationName」';
  @override String get licensesPageTitle => r'授權';
  @override String get pageRowsInfoTitle => r'第 $firstRow - $lastRow 列 (總共 $rowCount 列)';
  @override String get pageRowsInfoTitleApproximate => r'第 $firstRow - $lastRow 列 (總共約 $rowCount 列)';
  @override String get rowsPerPageTitle => r'每頁列數：';
  @override String get selectedRowCountTitleOne => r'已選取 1 個項目';
  @override String get selectedRowCountTitleOther => r'已選取 $selectedRowCount 個項目';
  @override String get closeButtonLabel => r'關閉';
  @override String get continueButtonLabel => r'繼續';
  @override String get copyButtonLabel => r'複製';
  @override String get cutButtonLabel => r'剪下';
  @override String get okButtonLabel => r'確定';
  @override String get pasteButtonLabel => r'貼上';
  @override String get selectAllButtonLabel => r'全選';
  @override String get viewLicensesButtonLabel => r'查看授權';
  @override String get timePickerHourModeAnnouncement => r'選取小時數';
  @override String get timePickerMinuteModeAnnouncement => r'選取分鐘數';
  @override String get drawerLabel => r'導覽選單';
  @override String get popupMenuLabel => r'彈出式選單';
  @override String get dialogLabel => r'對話方塊';
}

TranslationBundle translationBundleForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return const _Bundle_ar();
    case 'bg':
      return const _Bundle_bg();
    case 'bs':
      return const _Bundle_bs();
    case 'ca':
      return const _Bundle_ca();
    case 'cs':
      return const _Bundle_cs();
    case 'da':
      return const _Bundle_da();
    case 'de': {
      switch (locale.toString()) {
        case 'de_CH':
          return const _Bundle_de_CH();
      }
      return const _Bundle_de();
    }
    case 'el':
      return const _Bundle_el();
    case 'en': {
      switch (locale.toString()) {
        case 'en_AU':
          return const _Bundle_en_AU();
        case 'en_CA':
          return const _Bundle_en_CA();
        case 'en_GB':
          return const _Bundle_en_GB();
        case 'en_IE':
          return const _Bundle_en_IE();
        case 'en_IN':
          return const _Bundle_en_IN();
        case 'en_SG':
          return const _Bundle_en_SG();
        case 'en_ZA':
          return const _Bundle_en_ZA();
      }
      return const _Bundle_en();
    }
    case 'es': {
      switch (locale.toString()) {
        case 'es_419':
          return const _Bundle_es_419();
        case 'es_AR':
          return const _Bundle_es_AR();
        case 'es_BO':
          return const _Bundle_es_BO();
        case 'es_CL':
          return const _Bundle_es_CL();
        case 'es_CO':
          return const _Bundle_es_CO();
        case 'es_CR':
          return const _Bundle_es_CR();
        case 'es_DO':
          return const _Bundle_es_DO();
        case 'es_EC':
          return const _Bundle_es_EC();
        case 'es_GT':
          return const _Bundle_es_GT();
        case 'es_HN':
          return const _Bundle_es_HN();
        case 'es_MX':
          return const _Bundle_es_MX();
        case 'es_NI':
          return const _Bundle_es_NI();
        case 'es_PA':
          return const _Bundle_es_PA();
        case 'es_PE':
          return const _Bundle_es_PE();
        case 'es_PR':
          return const _Bundle_es_PR();
        case 'es_PY':
          return const _Bundle_es_PY();
        case 'es_SV':
          return const _Bundle_es_SV();
        case 'es_US':
          return const _Bundle_es_US();
        case 'es_UY':
          return const _Bundle_es_UY();
        case 'es_VE':
          return const _Bundle_es_VE();
      }
      return const _Bundle_es();
    }
    case 'et':
      return const _Bundle_et();
    case 'fa':
      return const _Bundle_fa();
    case 'fi':
      return const _Bundle_fi();
    case 'fil':
      return const _Bundle_fil();
    case 'fr': {
      switch (locale.toString()) {
        case 'fr_CA':
          return const _Bundle_fr_CA();
      }
      return const _Bundle_fr();
    }
    case 'gsw':
      return const _Bundle_gsw();
    case 'he':
      return const _Bundle_he();
    case 'hi':
      return const _Bundle_hi();
    case 'hr':
      return const _Bundle_hr();
    case 'hu':
      return const _Bundle_hu();
    case 'id':
      return const _Bundle_id();
    case 'it':
      return const _Bundle_it();
    case 'ja':
      return const _Bundle_ja();
    case 'ko':
      return const _Bundle_ko();
    case 'lt':
      return const _Bundle_lt();
    case 'lv':
      return const _Bundle_lv();
    case 'ms':
      return const _Bundle_ms();
    case 'nb':
      return const _Bundle_nb();
    case 'nl':
      return const _Bundle_nl();
    case 'pl':
      return const _Bundle_pl();
    case 'ps':
      return const _Bundle_ps();
    case 'pt': {
      switch (locale.toString()) {
        case 'pt_PT':
          return const _Bundle_pt_PT();
      }
      return const _Bundle_pt();
    }
    case 'ro':
      return const _Bundle_ro();
    case 'ru':
      return const _Bundle_ru();
    case 'sk':
      return const _Bundle_sk();
    case 'sl':
      return const _Bundle_sl();
    case 'sr': {
      switch (locale.toString()) {
        case 'sr_Latn':
          return const _Bundle_sr_Latn();
      }
      return const _Bundle_sr();
    }
    case 'sv':
      return const _Bundle_sv();
    case 'th':
      return const _Bundle_th();
    case 'tl':
      return const _Bundle_tl();
    case 'tr':
      return const _Bundle_tr();
    case 'uk':
      return const _Bundle_uk();
    case 'ur':
      return const _Bundle_ur();
    case 'vi':
      return const _Bundle_vi();
    case 'zh': {
      switch (locale.toString()) {
        case 'zh_HK':
          return const _Bundle_zh_HK();
        case 'zh_TW':
          return const _Bundle_zh_TW();
      }
      return const _Bundle_zh();
    }
  }
  return const TranslationBundle(null);
}
