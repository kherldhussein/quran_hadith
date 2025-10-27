import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/anim/animated.dart';
import 'package:quran_hadith/screens/hadith_book_page.dart';

class HadithBookTile extends StatefulWidget {
  final VoidCallback? onFavorite;
  final int? bookIndex;
  final Color? colorI;
  final double? radius;
  final String? name;
  final String? slug;
  final int? total;
  final bool? isFavorite;
  final int itemCount;

  const HadithBookTile({
    super.key,
    this.name,
    this.slug,
    this.total,
    this.colorI,
    this.radius = 12,
    this.bookIndex,
    this.onFavorite,
    this.isFavorite = false,
    this.itemCount = 9,
  });

  @override
  HadithBookTileState createState() => HadithBookTileState();
}

class HadithBookTileState extends State<HadithBookTile> {
  bool _isHovered = false;

  void _navigateToBook() {
    Get.to(() => HadithBookPage(
          bookSlug: widget.slug ?? '',
          bookName: widget.name,
        ));
  }

  void _showBookInfo(BuildContext context) {
    showPopover(
      width: 280,
      height: 240,
      context: context,
      backgroundColor: Get.theme.brightness == Brightness.light
          ? Colors.white
          : Get.theme.colorScheme.surface,
      direction: PopoverDirection.top,
      radius: 16,
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      bodyBuilder: (context) => _BuildBookInfo(
        name: widget.name,
        slug: widget.slug,
        total: widget.total,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: WidgetAnimator(
        Card(
          elevation: _isHovered ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius!),
          ),
          color: theme.colorScheme.surface,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: _navigateToBook,
            onHover: (hovering) {
              setState(() {
                _isHovered = hovering;
              });
            },
            hoverColor: theme.colorScheme.primary.withOpacity(0.05),
            onLongPress: () => _showBookInfo(context),
            borderRadius: BorderRadius.circular(widget.radius!),
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 12, left: 16, right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius!),
                border: _isHovered
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Book Number Circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.colorI ?? theme.colorScheme.primary,
                              (widget.colorI ?? theme.colorScheme.primary)
                                  .withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _formatBookNumber(widget.bookIndex ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ),

                      // Favorite Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isFavorite!
                              ? const Color(0xFFFF6B6B).withOpacity(0.05)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isFavorite!
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorite!
                                ? const Color(0xFFFF6B6B)
                                : Theme.of(context).canvasColor,
                            size: 26,
                          ),
                          onPressed: widget.onFavorite,
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AutoSizeText(
                    widget.name ?? 'Unknown Book',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AutoSizeText(
                        '•',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 20,
                        ),
                      ),
                      Expanded(
                        child: AutoSizeText(
                          '${widget.total ?? 0} hadiths'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatBookNumber(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['۰', '۱', '۲', '۳', '٤', '٥', '٦', '۷', '۸', '۹'];
    String input = number.toString();
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }
}

class _BuildBookInfo extends StatelessWidget {
  final String? name;
  final String? slug;
  final int? total;

  const _BuildBookInfo({
    this.name,
    this.slug,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Name', value: name ?? '-'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Total', value: '${total ?? 0} hadiths'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Slug', value: slug ?? '-'),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: theme.dividerColor.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            '📌 Tap to open | Long press for info',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
