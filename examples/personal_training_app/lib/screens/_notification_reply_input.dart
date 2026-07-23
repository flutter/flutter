import 'package:flutter/material.dart';

class NotificationReplyInput extends StatefulWidget {
  final String notificationId;
  final Future<void> Function(String) onReply;
  const NotificationReplyInput({
    super.key,
    required this.notificationId,
    required this.onReply,
  });

  @override
  State<NotificationReplyInput> createState() => _NotificationReplyInputState();
}

class _NotificationReplyInputState extends State<NotificationReplyInput> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Reply...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            onSubmitted: (val) async {
              if (val.trim().isNotEmpty && !_sending) {
                setState(() => _sending = true);
                await widget.onReply(val);
                _controller.clear();
                setState(() => _sending = false);
              }
            },
          ),
        ),
        IconButton(
          icon: _sending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.send),
          onPressed: _sending || _controller.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _sending = true);
                  await widget.onReply(_controller.text.trim());
                  _controller.clear();
                  setState(() => _sending = false);
                },
        ),
      ],
    );
  }
}
