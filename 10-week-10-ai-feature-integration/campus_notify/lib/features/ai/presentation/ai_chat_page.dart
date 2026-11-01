import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_chat_provider.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus AI'),
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.key),
            tooltip: 'Atur API key',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privasi: Jangan kirim NIK, password, atau data sensitif.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.messages.isEmpty
                ? const Center(child: Text('Mulai chat dengan Gemini AI.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (_, index) {
                      final message = state.messages[index];
                      return Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          color: message.fromUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(message.text),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !state.loading,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pertanyaan...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: state.loading ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Kirim',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final question = _input.text;
    _input.clear();
    ref.read(aiChatProvider.notifier).send(question);
  }

  Future<void> _showSettings() async {
    final controller = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Gemini API key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Masukkan API key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (key == null || key.trim().isEmpty) return;
    await ref.read(aiServiceProvider).saveApiKey(key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key tersimpan di secure storage.'),
      ),
    );
  }
}
