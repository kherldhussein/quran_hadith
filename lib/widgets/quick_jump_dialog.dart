import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Dialog for quickly jumping to a specific ayah number
class QuickJumpDialog extends StatefulWidget {
  final int maxAyahNumber;
  final Function(int) onJumpToAyah;
  final int? currentAyah;

  const QuickJumpDialog({
    super.key,
    required this.maxAyahNumber,
    required this.onJumpToAyah,
    this.currentAyah,
  });

  @override
  State<QuickJumpDialog> createState() => _QuickJumpDialogState();
}

class _QuickJumpDialogState extends State<QuickJumpDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current ayah if available
    if (widget.currentAyah != null) {
      _controller.text = widget.currentAyah.toString();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndJump() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() => _errorText = 'Please enter an ayah number');
      return;
    }

    final ayahNumber = int.tryParse(text);

    if (ayahNumber == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }

    if (ayahNumber < 1 || ayahNumber > widget.maxAyahNumber) {
      setState(() => _errorText = 'Ayah must be between 1 and ${widget.maxAyahNumber}');
      return;
    }

    // Valid input - jump to ayah
    Navigator.of(context).pop();
    widget.onJumpToAyah(ayahNumber);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(FontAwesomeIcons.locationArrow,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text('Jump to Ayah'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter ayah number (1-${widget.maxAyahNumber})',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Ayah Number',
              hintText: 'e.g., 15',
              errorText: _errorText,
              prefixIcon: Icon(FontAwesomeIcons.hashtag, size: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _validateAndJump(),
          ),
          if (widget.currentAyah != null) ...[
            const SizedBox(height: 12),
            Text(
              'Currently at ayah ${widget.currentAyah}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _validateAndJump,
          icon: const Icon(FontAwesomeIcons.arrowRight, size: 14),
          label: const Text('Jump'),
        ),
      ],
    );
  }
}
