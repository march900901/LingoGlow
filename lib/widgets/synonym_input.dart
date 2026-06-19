import 'package:flutter/material.dart';

class SynonymInput extends StatefulWidget {
  final List<String> initialTags;
  final String label;
  final String hint;
  final Function(List<String>) onChanged;
  final Color accentColor;

  const SynonymInput({
    Key? key,
    required this.initialTags,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.accentColor = const Color(0xFF9966FF),
  }) : super(key: key);

  @override
  State<SynonymInput> createState() => _SynonymInputState();
}

class _SynonymInputState extends State<SynonymInput> {
  final List<String> _tags = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initialTags);
  }

  void _addTag(String tag) {
    final cleaned = tag.trim().toLowerCase();
    if (cleaned.isNotEmpty && !_tags.contains(cleaned)) {
      setState(() {
        _tags.add(cleaned);
      });
      widget.onChanged(_tags);
    }
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return InputChip(
                      label: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      backgroundColor: widget.accentColor.withOpacity(0.2),
                      side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
                      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                onSubmitted: (value) {
                  _addTag(value);
                  _focusNode.requestFocus();
                },
                onChanged: (value) {
                  if (value.endsWith(',') || value.endsWith(' ') || value.endsWith('，')) {
                    final cleanValue = value.substring(0, value.length - 1);
                    _addTag(cleanValue);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
