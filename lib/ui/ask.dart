import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/open_db.dart';
import '../sources/groq.dart';
import '../sources/net.dart';
import 'widgets.dart';

const defaultAskModel = 'openai/gpt-oss-120b';

/// Groq key: per-profile key from Settings first, else the build-time .env key.
Future<String?> groqKeyFor(String profileId) async => cleanKey(await storage.read(key: 'groq_$profileId')) ?? envKey();

/// The assistant explains; it never decides, and sees public data only.
class AskScreen extends StatefulWidget {
  final Session session;
  const AskScreen({super.key, required this.session});
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _q = TextEditingController();
  final _scroll = ScrollController();
  final _chat = <(bool, String)>[]; // (fromUser, text)
  bool _web = false, _busy = false;
  final _net = Net();

  static const _starters = [
    'Explain sell rule 4, tax harvesting, in simple words',
    'Why is selling before 12 months more expensive?',
    'What is XIRR and why does it differ from simple return?',
    'Direct vs regular mutual fund plans: what is the difference?',
  ];

  @override
  void dispose() {
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final raw = (preset ?? _q.text).trim();
    if (raw.isEmpty || _busy) return;
    final key = await groqKeyFor(widget.session.profile.id);
    if (!mounted) return;
    if (key == null) {
      snack(context, 'Add your Groq API key in Settings first.');
      return;
    }
    final s = scrubQuestion(raw);
    if (s.removed.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Personal numbers removed'),
          content: Text('The assistant only gets public information. These will not be sent:\n\n'
              '${s.removed.map((r) => '• $r').join('\n')}\n\nWhat will be sent:\n"${s.text}"'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send without them')),
          ],
        ),
      );
      if (ok != true) return;
    }
    final model = await widget.session.db.setting('groq_ask_model') ?? defaultAskModel;
    setState(() {
      _chat.add((true, s.text));
      _busy = true;
      _q.clear();
    });
    try {
      final a = await ask(_net, key, model, s.text, webSearch: _web);
      setState(() => _chat.add((false, '${a.text}${a.searches > 0 ? '\n\n(${a.searches} web search${a.searches == 1 ? '' : 'es'})' : ''}')));
    } catch (e) {
      setState(() => _chat.add((false, 'Could not get an answer: ${e.toString().replaceFirst('groq: ', '')}')));
    } finally {
      if (mounted) setState(() => _busy = false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ask')),
      body: Column(children: [
        Expanded(
          child: ListView(controller: _scroll, padding: const EdgeInsets.all(12), children: [
            if (_chat.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, color: cs.primary),
                      const SizedBox(width: 8),
                      const Text('An explainer, not an adviser', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Ask about rules, tax, funds or public company news. It never sees your holdings or amounts, '
                      'never tells you to buy or sell, and cites sources when it searches the web.',
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              for (final s in _starters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                ),
            ],
            for (final (me, text) in _chat)
              Align(
                alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: me ? cs.primaryContainer : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: text));
                      snack(context, 'Copied');
                    },
                    child: Text(text, style: const TextStyle(height: 1.4)),
                  ),
                ),
              ),
            if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(children: [
              Row(children: [
                FilterChip(
                  avatar: const Icon(Icons.travel_explore, size: 18),
                  label: const Text('Search the web'),
                  selected: _web,
                  onSelected: (v) => setState(() => _web = v),
                ),
                const Spacer(),
                Text('Not investment advice', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Ask about tax, rules, funds, news…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(tooltip: 'Send', onPressed: _busy ? null : _send, icon: const Icon(Icons.arrow_upward)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
