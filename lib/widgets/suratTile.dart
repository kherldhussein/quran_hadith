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
    Key? key,
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
  }) : super(key: key);

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
          elevation: _isHovered ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius!),
          ),
          color: theme.colorScheme.surface,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: _navigateToSurah,
            onHover: (hovering) {
              setState(() {
                _isHovered = hovering;
              });
            },
            hoverColor: theme.colorScheme.primary.withOpacity(0.05),
            onLongPress: () => _showSurahInfo(context),
            borderRadius: BorderRadius.circular(widget.radius!),
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            child: Container(
              // height: 80,
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Surah Number Circle
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
                            _formatSurahNumber(widget.suratNo ?? 0),
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
                              ? kAccentColor.withOpacity(0.05)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isFavorite!
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorite!
                                ? kAccentColor
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
                  const SizedBox(height: 16),
                  AutoSizeText(
                    widget.englishName ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                          widget.englishTrans?.toUpperCase() ?? '',
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
                  const SizedBox(height: 2),
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
