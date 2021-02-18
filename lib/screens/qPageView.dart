import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/screens/home_screen.dart';
import 'package:quran_hadith/widgets/social_share.dart' as share;
import 'package:quran_hadith/widgets/suratTile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class QPageView extends StatefulWidget {
  final List<Ayah>? ayahList;
  final String? suratName;
  final String? suratEnglishName;
  final String? englishMeaning;
  final int? suratNo;
  final VoidCallback? openContainer;
  final Surah? surah;
  final Ayah? aya;
  final bool? isFavorite;

  const QPageView(
      {Key? key,
      this.ayahList,
      this.surah,
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

class _QPageViewState extends State<QPageView> {
  var controller;
  late AudioPlayer _audio;
  late Surah surah;
  bool _isPLaying = false;
  bool isLoaded = false;
  bool isLoading = false;
  var list;
  String? _url;
  var currentPlaying;
  AudioPlayer _audioPlayer = AudioPlayer();
  final quranApi = QuranAPI();

  @override
  void initState() {
    _audio = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);

    ///  to hide only status bar:
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    controller = AutoScrollController(axis: Axis.vertical);
    if (SchedulerBinding.instance!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        if (widget.surah!.readVerseCount > 0) {
          controller.scrollToIndex(
            widget.surah!.readVerseCount,
            preferPosition: AutoScrollPosition.middle,
          );
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplaySmallDesktop(context);
    var quranAPI = Provider.of<QuranAPI>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          widget.suratName!,
          style: TextStyle(
              fontFamily: 'Quran',
              color: Colors.black54,
              fontSize: 30,
              letterSpacing: 3,
              fontWeight: FontWeight.w200),
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.home,
                color: Theme.of(context).buttonColor),
            splashRadius: 10,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Get.to(HomeScreen()),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
        child: Container(
          constraints: BoxConstraints(minHeight: 0, minWidth: 0),
          decoration: BoxDecoration(
            color: Color(0xffeef2f5),
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
                            margin: EdgeInsets.fromLTRB(20, 1, 15, 10),
                            width: 350,
                            child: FutureBuilder(
                                future: quranAPI.getSuratList(),
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  if (!snapshot.hasData) return Container();
                                  return ListView.builder(
                                    // separatorBuilder: (_, index) => Divider(),
                                    itemCount: snapshot.data.surahs.length,
                                    controller: controller,
                                    itemBuilder: (context, index) {
                                      return SuratTile(
                                        colorO: Color(0xffe0f5f0),
                                        radius: 8,
                                        colorI: Color(0xff01AC68),
                                        ayahList:
                                            snapshot.data.surahs[index].ayahs,
                                        suratNo:
                                            snapshot.data.surahs[index].number,
                                        icon: FontAwesomeIcons.heart,
                                        onFavorite: SurahsList().starSurah(
                                            snapshot.data.surahs[index].number),
                                        isFavorite: false,
                                        revelationType: snapshot
                                            .data.surahs[index].revelationType,
                                        englishTrans: snapshot
                                            .data
                                            .surahs[index]
                                            .englishNameTranslation,
                                        englishName: snapshot
                                            .data.surahs[index].englishName,
                                        name: snapshot.data.surahs[index].name,
                                      );
                                    },
                                  );
                                }),
                          ),
                    Container(
                      constraints: BoxConstraints(minHeight: 0, minWidth: 0),
                      // padding: EdgeInsets.symmetric(vertical: 0),
                      height: MediaQuery.of(context).size.height,
                      // margin: EdgeInsets.symmetric(horizontal: 0),
                      width: 850,
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

  Future<void> _playAyah(Ayah aya) async {
    String? ayaNum;
    if (_audioPlayer.state == AudioPlayerState.PLAYING) {
      await _audioPlayer.stop();
    }
    quranApi.getAyaAudio(ayaNo: aya.number);
    await _audioPlayer
        .play('https://cdn.alquran.cloud/media/audio/$ayaNum/ar.alafasy/1')
        .then((void _) {
      print('Ayah ${surah.ayahs} is playing');
    });
  }

  void _showSnackBarOnCopyFailure(Object exception) {
    Get.snackbar('Failed to copy ', exception as String);
  }

  Widget qTile(int index, context) {
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
              widget.ayahList![index].text!.replaceFirst(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
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
            Divider(
              height: 64,
              endIndent: 32,
              indent: 32,
            ),
            Row(
              children: [
                IconButton(
                    icon: Icon(
                      FontAwesomeIcons.heart,
                      color: Theme.of(context).buttonColor,
                    ),
                    onPressed: () {}),
                IconButton(
                    icon: Icon(
                      FontAwesomeIcons.shareAlt,
                      color: Theme.of(context).buttonColor,
                    ),
                    onPressed: () => share.showShareDialog(
                        context: context, text: widget.ayahList![index].text)),
                StreamBuilder(
                    stream: _audio.onPlayerStateChanged,
                    builder: (_, AsyncSnapshot<AudioPlayerState> audioState) {
                      return StreamBuilder(
                          stream: _audio.onDurationChanged,
                          builder: (_, AsyncSnapshot<Duration> totalDuration) {
                            return StreamBuilder(
                                stream: _audio.onAudioPositionChanged,
                                builder: (_, AsyncSnapshot<Duration> progress) {
                                  return audioState?.data !=
                                          AudioPlayerState.PLAYING
                                      ? IconButton(
                                          color: Theme.of(context).buttonColor,
                                          icon: FaIcon(
                                              FontAwesomeIcons.playCircle),
                                          onPressed: audioState?.data !=
                                                  AudioPlayerState.PLAYING
                                              ? () => _playAyah(widget.aya!)
                                              : null,
                                        )
                                      : IconButton(
                                          color: Theme.of(context).buttonColor,
                                          icon: FaIcon(
                                              FontAwesomeIcons.pauseCircle),
                                          onPressed: () async =>
                                              await _audio.pause(),
                                        );
                                });
                          });
                    }),
                IconButton(
                    icon: Icon(
                      FontAwesomeIcons.copy,
                      color: Theme.of(context).buttonColor,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.ayahList![index].text),
                      )
                          .then(
                            (value) => Get.snackbar(
                                'Copied', 'Ayah Copied To Clipboard'),
                          )
                          .catchError(_showSnackBarOnCopyFailure);
                    }),
              ],
            )
            // FutureBuilder(
            //     // future: quranApi.getAyaAudio(ayaNo: widget.aya.number),
            //     builder: (context, snapshot) {
            //       return ;
            //     })
          ],
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

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }
}
