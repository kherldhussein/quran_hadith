import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/social_share.dart' as share;
import 'package:quran_hadith/widgets/suratTile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../controller/audio_controller.dart';

class QPageView extends StatefulWidget {
  final List<Ayah>? ayahList;
  final String? suratName;
  final String? suratEnglishName;
  final String? englishMeaning;
  final int? suratNo;
  final int? itemCount;
  final VoidCallback? openContainer;

  // final Surah surah;
  final Ayah? aya;
  final bool? isFavorite;

  const QPageView(
      {Key? key,
      this.ayahList,
      this.itemCount,
      this.suratName,
      this.aya,
      this.isFavorite,
      this.openContainer,
      this.suratEnglishName,
      this.englishMeaning,
      this.suratNo})
      : super(key: key);

  @override
  _QPageViewState createState() => _QPageViewState();
}

class _QPageViewState extends State<QPageView> with AutomaticKeepAliveClientMixin {
  AutoScrollController controller = AutoScrollController();
  late final AudioController _audioController;
  Surah? surah;
  bool isLoaded = false;
  bool isLoading = false;
  var list;
  final quranApi = QuranAPI();

  @override
  void initState() {
    super.initState();
    _audioController = AudioController(widget.aya?.number.toString());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSmall = isDisplaySmallDesktop(context);
    final isLarge = context.isLargeTablet;
    var quranAPI = Provider.of<QuranAPI>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor!.withOpacity(.5),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          widget.suratName!,
          style: TextStyle(
            fontWeight: FontWeight.w200,
            color: Colors.black54,
            fontFamily: 'Amiri',
            letterSpacing: 3,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.house),
            splashRadius: 10,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: Get.back,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
        child: Container(
          constraints: BoxConstraints(minHeight: 0, minWidth: 0),
          decoration: BoxDecoration(
            color: Get.theme.brightness == Brightness.light
                ? Color(0xffeef2f5)
                : kDarkPrimaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ListView(
            controller: controller,
            scrollDirection: Axis.vertical,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    isSmall
                        ? Container()
                        : Container(
                            constraints:
                                BoxConstraints(minHeight: 0, minWidth: 0),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            height: isSmall
                                ? 10
                                : MediaQuery.of(context).size.height,
                            margin: EdgeInsets.fromLTRB(
                              isLarge ? 20 : 10,
                              1,
                              isLarge ? 15 : 10,
                              10,
                            ),
                            width: isLarge ? 350 : 250,
                            child: FutureBuilder(
                                future: quranAPI.getSuratList(),
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  if (!snapshot.hasData) {
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey.withOpacity(.5),
                                      highlightColor: Colors.grey[100]!,
                                      child: ListView.separated(
                                        itemCount: 114,
                                        itemBuilder: (context, index) {
                                          return Card(
                                            child: Container(height: 100),
                                          );
                                        },
                                        separatorBuilder:
                                            (BuildContext context, int index) {
                                          return SizedBox(height: 10);
                                        },
                                      ),
                                    );
                                  } else {
                                    return ListView.builder(
                                      itemCount: widget.itemCount,
                                      itemBuilder: (context, index) {
                                        return SuratTile(
                                          radius: 8,
                                          ayahList:
                                              snapshot.data.surahs[index].ayahs,
                                          suratNo: snapshot
                                              .data.surahs[index].number,
                                          icon: FontAwesomeIcons.heart,
                                          onFavorite: () {
                                            // setFavorite(snapshot
                                            //     .data.surahs[index].number);
                                          },
                                          isFavorite: false,
                                          revelationType: snapshot.data
                                              .surahs[index].revelationType,
                                          englishTrans: snapshot
                                              .data
                                              .surahs[index]
                                              .englishNameTranslation,
                                          englishName: snapshot
                                              .data.surahs[index].englishName,
                                          name:
                                              snapshot.data.surahs[index].name,
                                        );
                                      },
                                    );
                                  }
                                }),
                          ),
                    Container(
                      constraints: BoxConstraints(minHeight: 0, minWidth: 0),
                      height: MediaQuery.of(context).size.height,
                      width: isLarge ? 850 : 700,
                      child: ListView.custom(
                        childrenDelegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return AutoScrollTag(
                                key: ValueKey(index),
                                controller: controller,
                                index: index,
                                child: qTile(index, context));
                          },
                          childCount: widget.ayahList!.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget qTile(int index, context) {
    // final isLarge = context.isLargeTablet;
    var quranAPI = Provider.of<QuranAPI>(context);
    Locale locale = Localizations.localeOf(context);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        title: AutoSizeText(
          locale.languageCode == 'ar'
              ? replaceArabicNumber(
                  "${widget.suratNo}:${widget.ayahList![index].number.toString()}")
              : replaceArabicNumber(
                  "${widget.suratNo}:${widget.ayahList![index].number.toString()}"),
          style: TextStyle(
            color: Color(0xff01AC68),
            height: 2.5,
            fontFamily: 'Amiri',
          ),
        ),
        subtitle: Column(
          children: [
            AutoSizeText(
              widget.ayahList![index].text!.replaceAll(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِِِ',
                  '\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
              textAlign: TextAlign.right,
              style: TextStyle(
                height: 2.7,
                fontWeight: FontWeight.normal,
                fontSize: 30,
                fontFamily: 'Amiri',
              ),
              textDirection: TextDirection.rtl,
            ),
            Divider(height: 64, endIndent: 32, indent: 32),
            Row(
              children: [
                FutureBuilder(
                    future: favorite(widget.ayahList![index].number),
                    builder: (context, snapshot) {
                      return IconButton(
                        icon: Icon(
                          snapshot.data == true
                              ? FontAwesomeIcons.heart
                              : FontAwesomeIcons.solidHeart,
                          color: snapshot.data == true
                              ? kAccentColor
                              : Theme.of(context).canvasColor,
                        ),
                        onPressed: () {
                          // setFavorite(widget.ayahList![index].number)
                        },
                      );
                    }),
                IconButton(
                    icon: Icon(FontAwesomeIcons.shareNodes),
                    onPressed: () => share.showShareDialog(
                        context: context, text: widget.ayahList![index].text)),
                IconButton(
                    icon: Icon(FontAwesomeIcons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.ayahList![index].text!),
                      );
                    }),
              ],
            ),
            FutureBuilder(
                future: quranAPI.getSuratAudio(),
                builder: (context, snapshot) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<ButtonState>(
                        valueListenable: _audioController.buttonNotifier,
                        builder: (_, value, __) {
                          switch (value) {
                            case ButtonState.loading:
                              return Container(
                                margin: const EdgeInsets.all(8.0),
                                width: 32.0,
                                height: 32.0,
                                child: const CircularProgressIndicator(),
                              );
                            case ButtonState.paused:
                              return IconButton(
                                icon: const Icon(Icons.play_arrow),
                                iconSize: 32.0,
                                onPressed: _audioController.play,
                              );
                            case ButtonState.playing:
                              return IconButton(
                                icon: const Icon(Icons.pause),
                                iconSize: 32.0,
                                onPressed: _audioController.pause,
                              );
                          }
                        },
                      ),
                      IconButton(
                        key: const Key('play_button'),
                        onPressed: () {},
                        icon: const Icon(FontAwesomeIcons.circlePlay),
                      ),
                      Visibility(
                        visible: true,
                        child: IconButton(
                          key: const Key('pause_button'),
                          onPressed: null,
                          icon: const Icon(FontAwesomeIcons.pause),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: IconButton(
                          key: const Key('stop_button'),
                          onPressed: null,
                          icon: const Icon(FontAwesomeIcons.circleStop),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: IconButton(
                            onPressed: () {},
                            icon: const Icon(FontAwesomeIcons.volumeHigh)
                            // : const Icon(FontAwesomeIcons.headset),
                            ),
                      ),
                    ],
                  );
                }),
            Offstage(child: Slider(onChanged: (v) {}, value: 0.0, label: '')),
          ],
        ),
        trailing: Image.asset('assets/images/design_1.png'),
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

favorite(index) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  if (sp.getStringList('favorite')!.contains('$index')) {
    return true;
  } else {
    return false;
  }
}
