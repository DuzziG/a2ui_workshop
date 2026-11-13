// lib/home_page.dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'agent_service.dart';
import 'xray_view.dart';

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
  bool _showXray = false;

  @override
  void initState() {
    super.initState();
    // Whenever the processor creates or deletes a surface, update the screen.
    _agent.processor.model.onSurfaceCreated.subscribe((surface) => setState(() => _surfaces.add(surface)));
    _agent.processor.model.onSurfaceDeleted.subscribe((id) => setState(() => _surfaces.removeWhere((s) => s.id == id)));
    // When a button inside a surface is pressed, send the action to the agent.
    _agent.processor.model.onAction.subscribe((action) => _run(() => _agent.sendAction(action)));
  }

  // Sends what the user typed to the agent.
  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    _promptController.clear();
    await _run(() => _agent.send(prompt));
  }

  // Lets the user pick a photo and sends it to the agent.
  Future<void> _sendPhoto() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    await _run(() => _agent.sendPhoto(bytes, photo.mimeType ?? 'image/jpeg'));
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
      appBar: AppBar(
        backgroundColor: colors.inversePrimary,
        title: Text(widget.title),
        actions: [
          // X-ray: show the raw reply Gemini wrote.
          IconButton(
            icon: Icon(_showXray ? Icons.code_off : Icons.code),
            onPressed: () => setState(() => _showXray = !_showXray),
          ),
        ],
      ),
      // X-ray off: just the chat. On a wide screen: the chat and the X-ray side by side.
      // On a narrow screen: the X-ray fills the screen.
      body: !_showXray
          ? _buildChat(context)
          : LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 800
                  ? Row(
                      children: [
                        Expanded(child: _buildChat(context)),
                        Expanded(child: XrayView(reply: _agent.lastRawReply)),
                      ],
                    )
                  : XrayView(reply: _agent.lastRawReply),
            ),
    );
  }

  // The chat: the surfaces, the agent's reply and the prompt box.
  Widget _buildChat(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 0. The companion surface stays pinned at the top.
        for (final surface in _surfaces.where((s) => s.id == 'companion'))
          A2uiSurface(key: ObjectKey(surface), surface: surface),
        // 1. The surfaces: newest at the bottom, like a chat.
        Expanded(
          child: _surfaces.isEmpty
              ? const Center(child: Text('Nothing here yet. Ask for something!'))
              : ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final surface in _surfaces.reversed.where((s) => s.id != 'companion'))
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
                IconButton(onPressed: _isLoading ? null : _sendPhoto, icon: const Icon(Icons.photo_camera)),
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
