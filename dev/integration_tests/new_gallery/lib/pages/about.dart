// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

void showAboutDialog({
  required BuildContext context,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return _AboutDialog();
    },
  );
}

Future<String> getVersionNumber() async {
  return '2.10.2+021002';
}

class _AboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyTextStyle =
        textTheme.bodyLarge!.apply(color: colorScheme.onPrimary);
    final localizations = GalleryLocalizations.of(context)!;

    const name = 'Flutter Gallery'; // Don't need to localize.
    const legalese = '© 2021 The Flutter team'; // Don't need to localize.
    final repoText = localizations.githubRepo(name);
    final seeSource = localizations.aboutDialogDescription(repoText);
    final repoLinkIndex = seeSource.indexOf(repoText);
    final repoLinkIndexEnd = repoLinkIndex + repoText.length;
    final seeSourceFirst = seeSource.substring(0, repoLinkIndex);
    final seeSourceSecond = seeSource.substring(repoLinkIndexEnd);

    return AlertDialog(
      backgroundColor: colorScheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
              future: getVersionNumber(),
              builder: (context, snapshot) => SelectableText(
                snapshot.hasData ? '$name ${snapshot.data}' : name,
                style: textTheme.headlineMedium!.apply(
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    style: bodyTextStyle,
                    text: seeSourceFirst,
                  ),
                  TextSpan(
                    style: bodyTextStyle.copyWith(
                      color: colorScheme.primary,
                    ),
                    text: repoText,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url =
                            Uri.parse('https://github.com/flutter/gallery/');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                  ),
                  TextSpan(
                    style: bodyTextStyle,
                    text: seeSourceSecond,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SelectableText(
              legalese,
              style: bodyTextStyle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Typography.material2018(
                    platform: Theme.of(context).platform,
                  ).black,
                  cardColor: Colors.white,
                ),
                child: const LicensePage(
                  applicationName: name,
                  applicationLegalese: legalese,
                ),
              ),
            ));
          },
          child: Text(
            MaterialLocalizations.of(context).viewLicensesButtonLabel,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
