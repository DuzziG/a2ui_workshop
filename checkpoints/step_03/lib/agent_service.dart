// lib/agent_service.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'api_key.dart';

class AgentService {
  // The renderer: it applies A2UI messages and remembers every surface.
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [basicCatalog()]);

  // Gemini, reached with your API key.
  final _gemini = Agent.forProvider(GoogleProvider(apiKey: geminiApiKey), chatModelName: 'gemini-3.6-flash');

  // The conversation so far. The system message tells Gemini how to behave.
  final List<ChatMessage> _history = [
    ChatMessage.system('You are a friendly assistant. Answer in one or two short sentences.'),
  ];

  Future<String> send(String prompt) async {
    try {
      final result = await _gemini.send(prompt, history: _history);
      _history.addAll(result.messages); // Remember this turn.
      return result.output;
    } catch (e) {
      return 'Error: $e';
    }
  }

  void dispose() => processor.dispose();
}
