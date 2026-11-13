// lib/home_page.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'agent_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _promptController = TextEditingController();
  final _agent = AgentService();
  final List<SurfaceModel<ComponentImplementation>> _surfaces = [];
  String _reply = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Whenever the processor creates or deletes a surface, update the screen.
    _agent.processor.model.onSurfaceCreated.subscribe((surface) => setState(() => _surfaces.add(surface)));
    _agent.processor.model.onSurfaceDeleted.subscribe((id) => setState(() => _surfaces.removeWhere((s) => s.id == id)));
  }

  // Sends what the user typed to the agent.
  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    _promptController.clear();
    await _run(() => _agent.send(prompt));
  }

  // Runs one request to the agent and shows its reply.
  Future<void> _run(Future<String> Function() request) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _reply = '';
    });

    final reply = await request();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _reply = reply;
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _agent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(backgroundColor: colors.inversePrimary, title: Text(widget.title)),
      body: _buildChat(context),
    );
  }

  // The chat: the surfaces, the agent's reply and the prompt box.
  Widget _buildChat(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 1. The surfaces: newest at the bottom, like a chat.
        Expanded(
          child: _surfaces.isEmpty
              ? const Center(child: Text('Nothing here yet. Ask for something!'))
              : ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final surface in _surfaces.reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: A2uiSurface(key: ObjectKey(surface), surface: surface),
                      ),
                  ],
                ),
        ),
        // 2. The agent's text reply, and a progress bar while it works.
        if (_isLoading) const LinearProgressIndicator(),
        if (_reply.isNotEmpty)
          Container(
            width: double.infinity,
            color: colors.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: Text(_reply),
          ),
        // 3. The prompt box.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(hintText: 'Ask for something...', border: OutlineInputBorder()),
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                IconButton.filled(onPressed: _isLoading ? null : _sendPrompt, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
