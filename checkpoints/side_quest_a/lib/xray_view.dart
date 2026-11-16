// lib/xray_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Shows Gemini's raw reply, with every A2UI block pretty-printed.
class XrayView extends StatelessWidget {
  const XrayView({super.key, required this.reply});
  final String reply;

  @override
  Widget build(BuildContext context) {
    final text = reply.isEmpty ? 'No reply yet. Ask Gemini for something!' : _prettify(reply);
    return ColoredBox(
      color: const Color(0xFF1E1E2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A header with a copy button.
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text("X-ray: Gemini's last reply", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                ),
              ],
            ),
          ),
          // The reply itself, scrollable and selectable.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4, color: Color(0xFFA6E3A1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Indents the JSON inside every <a2ui-json> block, so it's easy to read.
  static String _prettify(String reply) => reply.replaceAllMapped(
    RegExp(r'<a2ui-json>(.*?)</a2ui-json>', dotAll: true),
    (match) {
      try {
        final json = const JsonEncoder.withIndent('  ').convert(jsonDecode(match[1]!));
        return '<a2ui-json>\n$json\n</a2ui-json>';
      } on FormatException {
        return match[0]!; // Not valid JSON: show it as it is.
      }
    },
  );
}
