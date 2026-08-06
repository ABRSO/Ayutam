import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/learning_log_models.dart';
import 'session_detail_pane.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    this.entries = const [],
  });

  final String sessionId;
  final List<LearningLogEntry> entries;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
  }

  LearningLogEntry? _fromList(String id) {
    for (final entry in widget.entries) {
      if (entry.session.id == id) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fromList = _fromList(_sessionId);

    if (fromList != null) {
      return SessionDetailPane(
        entry: fromList,
        entries: widget.entries,
        embedded: false,
        onDeleted: () {
          if (context.mounted) Navigator.of(context).pop();
        },
        onChanged: () => ref.invalidate(learningLogEntriesProvider),
        onNavigateTo: (id) => setState(() => _sessionId = id),
      );
    }

    return FutureBuilder(
      future: ref.read(learningLogServiceProvider).getEntry(_sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final entry = snapshot.data;
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: const Center(child: Text('Session not found.')),
          );
        }
        return SessionDetailPane(
          entry: entry,
          entries: widget.entries,
          embedded: false,
          onDeleted: () {
            if (context.mounted) Navigator.of(context).pop();
          },
          onChanged: () => ref.invalidate(learningLogEntriesProvider),
          onNavigateTo: (id) => setState(() => _sessionId = id),
        );
      },
    );
  }
}
