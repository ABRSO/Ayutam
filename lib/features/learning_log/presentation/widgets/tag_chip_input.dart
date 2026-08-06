import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/tag.dart';

/// Chip list + autocomplete field for session tags.
class TagChipInput extends ConsumerStatefulWidget {
  const TagChipInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  ConsumerState<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends ConsumerState<TagChipInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<Tag>> _options(TextEditingValue value) async {
    final prefix = value.text.trim();
    if (prefix.isEmpty) return const [];
    return ref.read(tagServiceProvider).autocomplete(prefix);
  }

  void _addTag(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    final normalized = Tag.normalize(name);
    final exists = widget.tags.any((t) => Tag.normalize(t) == normalized);
    if (exists) {
      _textController.clear();
      return;
    }
    widget.onChanged([...widget.tags, name]);
    _textController.clear();
  }

  void _removeAt(int index) {
    final next = List<String>.from(widget.tags)..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tags', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.tags.length; i++)
                InputChip(
                  label: Text(widget.tags[i]),
                  onDeleted: widget.enabled ? () => _removeAt(i) : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        RawAutocomplete<Tag>(
          textEditingController: _textController,
          focusNode: _focusNode,
          displayStringForOption: (t) => t.name,
          optionsBuilder: _options,
          onSelected: (tag) => _addTag(tag.name),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Add a tag',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              onSubmitted: (value) {
                _addTag(value);
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 320,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final tag = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(tag.name),
                        onTap: () => onSelected(tag),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
