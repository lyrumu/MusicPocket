import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final String confirmText;

  const TextInputDialog({
    super.key,
    required this.title,
    this.initialValue,
    this.hintText = '',
    required this.confirmText,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? initialValue,
    String hintText = '',
    required String confirmText,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        confirmText: confirmText,
      ),
    );
  }
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  void _confirm() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }
}
