import 'package:flutter/material.dart';
import 'package:gallery/studies/reply/model/email_store.dart';
import 'package:provider/provider.dart';

class ComposePage extends StatelessWidget {
  const ComposePage({super.key});

  @override
  Widget build(BuildContext context) {
    var senderEmail = 'flutterfan@gmail.com';
    String subject = '';
    String? recipient = 'Recipient';
    String recipientAvatar = 'reply/avatars/avatar_0.jpg';

    final emailStore = Provider.of<EmailStore>(context);

    if (emailStore.selectedEmailId >= 0) {
      final currentEmail = emailStore.currentEmail;
      subject = currentEmail.subject;
      recipient = currentEmail.sender;
      recipientAvatar = currentEmail.avatar;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          height: double.infinity,
          child: Material(
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SubjectRow(
                    subject: subject,
                  ),
                  const _SectionDivider(),
                  _SenderAddressRow(
                    senderEmail: senderEmail,
                  ),
                  const _SectionDivider(),
                  _RecipientsRow(
                    recipients: recipient,
                    avatar: recipientAvatar,
                  ),
                  const _SectionDivider(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      minLines: 6,
                      maxLines: 20,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'New Message...',
                      ),
                      autofocus: false,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatefulWidget {
  const _SubjectRow({required this.subject});

  final String subject;

  @override
  _SubjectRowState createState() => _SubjectRowState();
}

class _SubjectRowState extends State<_SubjectRow> {
  TextEditingController? _subjectController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.subject);
  }

  @override
  void dispose() {
    _subjectController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey('ReplyExit'),
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _subjectController,
              maxLines: 1,
              autofocus: false,
              style: theme.textTheme.titleLarge,
              decoration: InputDecoration.collapsed(
                hintText: 'Subject',
                hintStyle: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: IconButton(
              icon: ImageIcon(
                const AssetImage(
                  'reply/icons/twotone_send.png',
                  package: 'flutter_gallery_assets',
                ),
                color: colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderAddressRow extends StatefulWidget {
  const _SenderAddressRow({required this.senderEmail});

  final String senderEmail;

  @override
  __SenderAddressRowState createState() => __SenderAddressRowState();
}

class __SenderAddressRowState extends State<_SenderAddressRow> {
  late String senderEmail;

  @override
  void initState() {
    super.initState();
    senderEmail = widget.senderEmail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final accounts = [
      'flutterfan@gmail.com',
      'materialfan@gmail.com',
    ];

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (email) {
        setState(() {
          senderEmail = email;
        });
      },
      itemBuilder: (context) => <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          value: accounts[0],
          child: Text(
            accounts[0],
            style: textTheme.bodyMedium,
          ),
        ),
        PopupMenuItem<String>(
          value: accounts[1],
          child: Text(
            accounts[1],
            style: textTheme.bodyMedium,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 16,
          right: 10,
          bottom: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                senderEmail,
                style: textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientsRow extends StatelessWidget {
  const _RecipientsRow({
    required this.recipients,
    required this.avatar,
  });

  final String recipients;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              children: [
                Chip(
                  backgroundColor:
                      Theme.of(context).chipTheme.secondarySelectedColor,
                  padding: EdgeInsets.zero,
                  avatar: CircleAvatar(
                    backgroundImage: AssetImage(
                      avatar,
                      package: 'flutter_gallery_assets',
                    ),
                  ),
                  label: Text(
                    recipients,
                  ),
                ),
              ],
            ),
          ),
          InkResponse(
            customBorder: const CircleBorder(),
            onTap: () {},
            radius: 24,
            child: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      thickness: 1.1,
      indent: 10,
      endIndent: 10,
    );
  }
}
