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

  /// Neighbor snapshot for Previous/Next until the live list reloads.
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

  void _invalidateAfterChange() {
    ref.invalidate(learningLogListProvider);
    ref.invalidate(learningLogEntryProvider(_sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final liveEntries = ref.watch(learningLogListProvider).value?.entries;
    final neighborEntries = (liveEntries != null && liveEntries.isNotEmpty)
        ? liveEntries
        : widget.entries;
    final entryAsync = ref.watch(learningLogEntryProvider(_sessionId));

    return entryAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: Center(child: Text('$e')),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: const Center(child: Text('Session not found.')),
          );
        }
        return SessionDetailPane(
          entry: entry,
          entries: neighborEntries,
          embedded: false,
          onDeleted: () {
            if (context.mounted) Navigator.of(context).pop();
          },
          onChanged: _invalidateAfterChange,
          onNavigateTo: (id) => setState(() => _sessionId = id),
        );
      },
    );
  }
}
