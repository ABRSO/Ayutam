import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/constants/app_constants.dart';

/// Markdown note field with Edit / Preview toggle.
///
/// Remote images are never loaded ([imageBuilder] returns an empty box).
class MarkdownNoteEditor extends StatefulWidget {
  const MarkdownNoteEditor({
    super.key,
    required this.controller,
    this.minLines = 4,
    this.maxLines = 12,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.label = 'Note',
  });

  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final String label;

  @override
  State<MarkdownNoteEditor> createState() => _MarkdownNoteEditorState();
}

class _MarkdownNoteEditorState extends State<MarkdownNoteEditor> {
  var _preview = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final length = widget.controller.text.characters.length;
    final overSoft = length > AppConstants.noteSoftCharHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label, style: theme.textTheme.titleSmall),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Edit'),
                  icon: Icon(Icons.edit_outlined, size: 18),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Preview'),
                  icon: Icon(Icons.visibility_outlined, size: 18),
                ),
              ],
              selected: {_preview},
              onSelectionChanged: (s) => setState(() => _preview = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_preview)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: widget.controller.text.trim().isEmpty
                  ? Text(
                      'Nothing to preview yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : MarkdownBody(
                      data: widget.controller.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme),
                      imageBuilder: (uri, title, alt) =>
                          const SizedBox.shrink(),
                      onTapLink: (text, href, title) {},
                    ),
            ),
          )
        else
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            onChanged: (v) {
              setState(() {});
              widget.onChanged?.call(v);
            },
            onEditingComplete: widget.onEditingComplete,
            decoration: InputDecoration(
              hintText: 'Write a markdown note…',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              helperText: overSoft
                  ? 'Soft hint: over ${AppConstants.noteSoftCharHint} characters '
                        '($length)'
                  : '$length characters',
              helperStyle: overSoft
                  ? TextStyle(color: theme.colorScheme.tertiary)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Read-only markdown body used on detail panes (no remote images).
class MarkdownNotePreview extends StatelessWidget {
  const MarkdownNotePreview({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = markdown.trim();
    if (trimmed.isEmpty) {
      return Text(
        'No note added',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return MarkdownBody(
      data: markdown,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme),
      imageBuilder: (uri, title, alt) => const SizedBox.shrink(),
      onTapLink: (text, href, title) {},
    );
  }
}
