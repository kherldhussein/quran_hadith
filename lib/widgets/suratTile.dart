
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/anim/animated.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/widgets/suratInfo.dart';

class SuratTile extends StatefulWidget {
  final int? suratNo;
  final List<Ayah>? ayahList;
  final String? englishName;
  final String? englishTrans;
  final String? name;
  final String? revelationType;
  final IconData? icon;
  final Color? colorI;
  final Color? colorO;
  final VoidCallback? onFavorite;
  final double? radius;
  final bool? isFavorite;

  const SuratTile({
    Key? key,
    this.ayahList,
    this.onFavorite,
    this.suratNo,
    this.isFavorite,
    this.englishName,
    this.englishTrans,
    this.name,
    this.icon,
    this.revelationType,
    this.colorI,
    this.colorO,
    this.radius,
  }) : super(key: key);

  @override
  _SuratTileState createState() => _SuratTileState();
}

class _SuratTileState extends State<SuratTile> {
  Surah? surah;

  bool isLoaded = false;
  bool isLoading = false;
  var list;
  var currentPlaying;
  final quranApi = QuranAPI();

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
            borderRadius: BorderRadius.circular(widget.radius!)),
        child: ListTile(
          onTap: () {
            Get.to(QPageView(
              ayahList: widget.ayahList,
              suratName: widget.name,
              isFavorite: widget.isFavorite,
              suratEnglishName: widget.englishName,
              englishMeaning: widget.englishTrans,
              suratNo: widget.suratNo,
            ));
          },
          onLongPress: () {
            showPopover(
                context: context,
                backgroundColor: Theme.of(context).cardColor,
                bodyBuilder: (context) => SurahInformation(
                  surahNumber: widget.suratNo,
                  ayahs: widget.ayahList!.length,
                  englishName: widget.englishName,
                  arabicName: widget.name,
                  revelationType: widget.revelationType,
                ));
          },
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: AutoSizeText(
                  locale.languageCode == 'ar'
                      ? replaceArabicNumber(widget.suratNo.toString())
                      : replaceArabicNumber(widget.suratNo.toString()),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.colorO, fontFamily: 'Amiri'),
                ),
                backgroundColor: widget.colorI,
              ),
              IconButton(
                icon: Icon(widget.icon,
                    color:
                    widget.isFavorite! ? Colors.green : Colors.lightGreen),
                onPressed: widget.onFavorite,
              )
            ],
          ),
          enableFeedback: true,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                widget.englishName!,
                style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              AutoSizeText(
                widget.englishTrans!,
                style: TextStyle(
                    color: Color(0xffdae1e7), fontWeight: FontWeight.w300),
              ),
            ],
          ),
          // trailing: AutoSizeText(widget.name),
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
}
