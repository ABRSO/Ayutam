import 'package:flutter/material.dart';

import '../domain/learning_log_models.dart';
import 'learning_log_format.dart';

class LearningLogCard extends StatelessWidget {
  const LearningLogCard({
    super.key,
    required this.entry,
    this.selected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final LearningLogEntry entry;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = entryAccent(entry);
    final session = entry.session;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
          : null,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.displayTitle,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            sessionSourceIcon(session),
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Session actions',
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  onEdit?.call();
                                case 'delete':
                                  onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.skillName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatSessionDate(session.startAtUtc)} · '
                        '${formatSessionTimeRange(session)} · '
                        '${durationLabel(session.activeSeconds)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in entry.tags.take(6))
                              Chip(
                                label: Text(tag.name),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        notePreviewLine(entry),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: entry.hasNote
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
