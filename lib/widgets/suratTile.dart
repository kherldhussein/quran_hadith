import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/anim/animated.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/widgets/suratInfo.dart';

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
    this.radius,
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
  final quranApi = QuranAPI();
  bool isLoading = false;
  bool isLoaded = false;
  var currentPlaying;
  Surah? surah;
  var list;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    return WidgetAnimator(
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius!),
        ),
        child: Listener(
          onPointerDown: _onPopoverDown,
          child: ListTile(
            onTap: () {
              Get.to(() => QPageView(
                    suratName: widget.name,
                    suratNo: widget.suratNo,
                    ayahList: widget.ayahList,
                    isFavorite: widget.isFavorite,
                    englishMeaning: widget.englishTrans,
                    suratEnglishName: widget.englishName,
                  ));
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: AutoSizeText(
                    locale.languageCode == 'ar'
                        ? replaceArabicNumber(widget.suratNo.toString())
                        : replaceArabicNumber(widget.suratNo.toString()),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Get.theme.brightness == Brightness.light
                        ? kAccentColor
                        : kDarkSecondaryColor, fontFamily: 'Amiri'),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: widget.colorI,
                ),
                IconButton(
                  icon: Icon(
                    widget.icon,
                    color: widget.isFavorite!
                        ? kAccentColor
                        : Theme.of(context).canvasColor,
                  ),
                  splashRadius: 1,
                  splashColor: kAccentColor.withOpacity(.5),
                  onPressed: widget.onFavorite,
                )
              ],
            ),
            enableFeedback: true,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                AutoSizeText(
                  widget.englishName!,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                AutoSizeText(
                  widget.englishTrans!.toUpperCase(),
                  style: TextStyle(
                      color: Color(0xffdae1e7), fontWeight: FontWeight.w300),
                ),
              ],
            ),
            // trailing: AutoSizeText(widget.name),
          ),
        ),
      ),
    );
  }

  String replaceArabicNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['۰', '۱', '۲', '۳', '٤', '٥', '٦', '۷', '۸', '۹'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  /// Callback when mouse clicked on `Listener` wrapped widget.
  Future<void> _onPopoverDown(PointerDownEvent event) async {
    // Check if right mouse button clicked
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      showPopover(
        width: 230,
        height: 230,
        context: context,
        backgroundColor: Theme.of(context).canvasColor,
        bodyBuilder: (context) => SurahInformation(
          revelationType: widget.revelationType,
          englishName: widget.englishName,
          ayahs: widget.ayahList!.length,
          surahNumber: widget.suratNo,
          arabicName: widget.name,
        ),
      );
    }
  }
}
