import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/anim/animated.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/widgets/suratInfo.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import '../theme/app_theme.dart';

class SuratTile extends StatefulWidget {
  final VoidCallback? onFavorite;
  final String? revelationType;
  final List<Ayah>? ayahList;
  final String? englishTrans;
  final String? englishName;
  final bool? isFavorite;
  final IconData? icon;
  final int? itemCount;
  final double? radius;
  final Color? colorI;
  final int? suratNo;
  final String? name;

  const SuratTile({
    super.key,
    this.name,
    this.icon,
    this.colorI,
    this.radius = 12,
    this.suratNo,
    this.ayahList,
    this.onFavorite,
    this.itemCount,
    this.englishName,
    this.englishTrans,
    this.revelationType,
    this.isFavorite = false,
  });

  @override
  _SuratTileState createState() => _SuratTileState();
}

class _SuratTileState extends State<SuratTile> {
  bool _isHovered = false;

  void _navigateToSurah() {
    if (widget.suratNo != null && (widget.ayahList?.isNotEmpty ?? false)) {
      SpUtil.setLastRead(
        surah: widget.suratNo!,
        ayah: widget.ayahList!.first.number ?? 1,
      );
    }

    Get.to(() => QPageView(
          suratName: widget.name,
          suratNo: widget.suratNo,
          ayahList: widget.ayahList,
          isFavorite: widget.isFavorite,
          englishMeaning: widget.englishTrans,
          suratEnglishName: widget.englishName,
        ));
  }

  void _showSurahInfo(BuildContext context) {
    showPopover(
      width: 280,
      height: 280,
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
      bodyBuilder: (context) => SurahInformation(
        revelationType: widget.revelationType,
        englishName: widget.englishName,
        ayahs: widget.ayahList!.length,
        surahNumber: widget.suratNo,
        arabicName: widget.name,
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
          elevation: _isHovered ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.08),
          child: InkWell(
            onTap: _navigateToSurah,
            onHover: (hovering) {
              setState(() {
                _isHovered = hovering;
              });
            },
            hoverColor: theme.colorScheme.primary.withOpacity(0.03),
            onLongPress: () => _showSurahInfo(context),
            borderRadius: BorderRadius.circular(16),
            splashColor: theme.colorScheme.primary.withOpacity(0.08),
            highlightColor: theme.colorScheme.primary.withOpacity(0.03),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: _isHovered
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _formatSurahNumber(widget.suratNo ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          widget.isFavorite!
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: widget.isFavorite!
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          size: 22,
                        ),
                        onPressed: widget.onFavorite,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isFavorite!
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          hoverColor: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AutoSizeText(
                    widget.englishName ?? '',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    widget.englishTrans ?? '',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSurahNumber(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['۰', '۱', '۲', '۳', '٤', '٥', '٦', '۷', '۸', '۹'];
    String input = number.toString();
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }
}
