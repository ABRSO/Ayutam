import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../domain/tag.dart';

/// Lets parents flush typed-but-not-committed tag text (e.g. before Save/Apply).
class TagChipInputController extends ChangeNotifier {
  _TagChipInputState? _state;
  List<String> _cachedTags = const [];
  String _cachedPending = '';

  void _attach(_TagChipInputState state) {
    _state = state;
    _cachedTags = List<String>.from(state.widget.tags);
    _cachedPending = '';
  }

  void _detach(_TagChipInputState state) {
    if (identical(_state, state)) {
      // Child disposes before parent; keep text so parent can still flush.
      _cachedTags = List<String>.from(state.widget.tags);
      _cachedPending = state._textController.text;
      _state = null;
    }
  }

  void _cacheTags(List<String> tags) {
    _cachedTags = List<String>.from(tags);
  }

  /// Commits any text still in the field as a chip (no-op if empty/duplicate).
  /// Returns the effective tag list after commit. When [notify] is false, skips
  /// [TagChipInput.onChanged] (safe to call from [State.dispose]).
  List<String> commitPending({bool notify = true}) {
    if (_state != null) {
      final next = _state!.commitPending(notify: notify);
      _cachedTags = List<String>.from(next);
      _cachedPending = '';
      return next;
    }
    final name = _cachedPending.trim();
    _cachedPending = '';
    if (name.isEmpty) {
      return List<String>.from(_cachedTags);
    }
    final normalized = Tag.normalize(name);
    if (_cachedTags.any((t) => Tag.normalize(t) == normalized)) {
      return List<String>.from(_cachedTags);
    }
    final next = [..._cachedTags, name];
    _cachedTags = next;
    return next;
  }
}

/// Chip list + autocomplete field for session tags.
///
/// Typed text becomes a chip on Enter/Done, autocomplete pick, focus loss, or
/// [TagChipInputController.commitPending] — not only on Enter.
class TagChipInput extends ConsumerStatefulWidget {
  const TagChipInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.controller,
    this.enabled = true,
    this.hintText = 'Add a tag',
    this.helperText = 'Press Done to add, or Save will add typed tags',
    this.showLabel = true,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final TagChipInputController? controller;
  final bool enabled;
  final String hintText;
  final String? helperText;
  final bool showLabel;

  @override
  ConsumerState<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends ConsumerState<TagChipInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant TagChipInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    } else {
      widget.controller?._cacheTags(widget.tags);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      commitPending();
    }
  }

  /// Commits field text into the chip list.
  List<String> commitPending({bool notify = true}) {
    final name = _textController.text.trim();
    if (name.isEmpty) {
      return List<String>.from(widget.tags);
    }
    final normalized = Tag.normalize(name);
    final exists = widget.tags.any((t) => Tag.normalize(t) == normalized);
    if (exists) {
      _textController.clear();
      return List<String>.from(widget.tags);
    }
    final next = [...widget.tags, name];
    _textController.clear();
    widget.controller?._cacheTags(next);
    if (notify) {
      widget.onChanged(next);
    }
    return next;
  }

  Future<Iterable<Tag>> _options(TextEditingValue value) async {
    // Empty prefix lists existing tags so users can pick without remembering names.
    return ref.read(tagServiceProvider).autocomplete(value.text.trim());
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
    final next = [...widget.tags, name];
    widget.controller?._cacheTags(next);
    widget.onChanged(next);
    _textController.clear();
  }

  void _removeAt(int index) {
    final next = List<String>.from(widget.tags)..removeAt(index);
    widget.controller?._cacheTags(next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabel) ...[
          Text('Tags', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
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
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_outline),
              ),
              onSubmitted: (value) {
                _addTag(value);
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            if (options.isEmpty) {
              return const SizedBox.shrink();
            }
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
