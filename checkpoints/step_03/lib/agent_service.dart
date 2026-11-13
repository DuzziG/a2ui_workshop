// lib/agent_service.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';

class AgentService {
  // The renderer: it applies A2UI messages and remembers every surface.
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [basicCatalog()]);

  Future<String> send(String prompt) async {
    // Pretend to think for a second.
    await Future.delayed(const Duration(seconds: 1));
    return 'You said "$prompt". Soon I will answer with real UI!';
  }

  void dispose() => processor.dispose();
}
