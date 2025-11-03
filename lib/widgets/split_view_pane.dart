import 'package:flutter/material.dart';

/// A split view widget with adjustable divider for desktop
class SplitViewPane extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final bool syncScroll;

  const SplitViewPane({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialRatio = 0.5,
    this.minRatio = 0.3,
    this.maxRatio = 0.7,
    this.syncScroll = true,
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
                  _ratio =
                      (_ratio + delta).clamp(widget.minRatio, widget.maxRatio);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _isDragging = true),
                onExit: (_) => setState(() => _isDragging = false),
                child: Container(
                  width: 8,
                  color: _isDragging
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        if (_isDragging)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Tooltip(
                              message:
                                  'Drag to resize • Left: ${(_ratio * 100).toStringAsFixed(0)}% • Right: ${((1 - _ratio) * 100).toStringAsFixed(0)}%',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(_ratio * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
