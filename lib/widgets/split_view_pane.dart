import 'package:flutter/material.dart';

/// A split view widget with adjustable divider for desktop
class SplitViewPane extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;

  const SplitViewPane({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialRatio = 0.5,
    this.minRatio = 0.3,
    this.maxRatio = 0.7,
  });

  @override
  State<SplitViewPane> createState() => _SplitViewPaneState();
}

class _SplitViewPaneState extends State<SplitViewPane> {
  late double _ratio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double leftWidth = width * _ratio;
        final double rightWidth = width * (1 - _ratio);

        return Row(
          children: [
            // Left pane
            SizedBox(
              width: leftWidth,
              child: widget.leftChild,
            ),

            // Divider
            GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  final double delta = details.delta.dx / width;
                  _ratio = (_ratio + delta).clamp(widget.minRatio, widget.maxRatio);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 8,
                  color: _isDragging
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right pane
            SizedBox(
              width: rightWidth - 8,
              child: widget.rightChild,
            ),
          ],
        );
      },
    );
  }
}
