import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/social_share.dart' as share;
import 'package:quran_hadith/widgets/suratTile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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

class _QPageViewState extends State<QPageView> {
  // PlayerState? _audioPlayerState;
  // PlayerState _playerState = PlayerState.STOPPED;
  AutoScrollController controller = AutoScrollController();
  Surah? surah;
  bool isLoaded = false;
  bool isLoading = false;
  var list;
  final quranApi = QuranAPI();

  @override
  void initState() {
    _initAudioPlayer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplaySmallDesktop(context);
    var quranAPI = Provider.of<QuranAPI>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
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
                            margin: EdgeInsets.fromLTRB(20, 1, 15, 10),
                            width: 350,
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
                                      // controller: controller,
                                      itemBuilder: (context, index) {
                                        return SuratTile(
                                          colorO: Color(0xffe0f5f0),
                                          radius: 8,
                                          colorI: Color(0xff01AC68),
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

  // setFavorite(int? index) async {
  //   SharedPreferences sp = await SharedPreferences.getInstance();
  //   if (sp.getStringList('FAVORITE')!.contains('$index')) {
  //     // add to favorite
  //     String newValue = '$index';
  //     List<String> oldFavorite = sp.getStringList('FAVORITE')!;
  //     oldFavorite.add(newValue);
  //     List<String> favorite = oldFavorite;
  //     sp.setStringList('FAVORITE', favorite);
  //     setState(() {});
  //   } else {
  //     // remove from favorite
  //     String newValue = '$index';
  //     List<String> oldFavorite = sp.getStringList('FAVORITE')!;
  //     oldFavorite.remove(newValue);
  //     List<String> favorite = oldFavorite;
  //     sp.setStringList('FAVORITE', favorite);
  //     setState(() {});
  //   }
  // }

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
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيم',
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
                              ? Theme.of(context).primaryColor
                              : Colors.greenAccent,
                        ),
                        onPressed: () {
                          // setFavorite(widget.ayahList![index].number)
                        },
                      );
                    }),
                IconButton(
                    icon: Icon(
                      FontAwesomeIcons.shareNodes,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => share.showShareDialog(
                        context: context, text: widget.ayahList![index].text)),
                IconButton(
                    icon: Icon(
                      FontAwesomeIcons.copy,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.ayahList![index].text!),
                      );
                    }),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('play_button'),
                  onPressed: () {
                    // _isPlaying ? null : _play(widget.ayahList![index].number!);
                  },
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
            ),
            Visibility(
              visible: true,
              child: Slider(onChanged: (v) {}, value: 0.0, label: ''),
            ),
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

  void _initAudioPlayer() {
    // _audioPlayer = AudioPlayer();

    // _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
    //   setState(() => _duration = duration);
    //
    //   if (Theme.of(context).platform == TargetPlatform.iOS) {
    //     // optional: listen for notification updates in the background
    //     _audioPlayer.notificationService.startHeadlessService();
    //
    //     // set at least title to see the notification bar on ios.
    //     _audioPlayer.notificationService.setNotification(
    //       title: 'Qur’ān Hadith',
    //       artist: 'Hani Rifai',
    //       albumTitle: 'Qur’ān',
    //       imageUrl: 'URL',
    //       forwardSkipInterval: const Duration(seconds: 30),
    //       backwardSkipInterval: const Duration(seconds: 30),
    //       duration: duration,
    //       enableNextTrackButton: true,
    //       enablePreviousTrackButton: true,
    //     );
    //   }
    // });

    // _positionSubscription =
    //     _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
    //           _position = p;
    //         }));

    // _playerCompleteSubscription =
    //     _audioPlayer.onPlayerCompletion.listen((event) {
    //   _onComplete();
    //   setState(() {
    //     _position = _duration;
    //   });
    // });

    // _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
    //   setState(() {
    //     _playerState = PlayerState.STOPPED;
    //     _duration = const Duration();
    //     _position = const Duration();
    //   });
    // });
    //
    // _playerControlCommandSubscription =
    //     _audioPlayer.notificationService.onPlayerCommand.listen((command) {});
    //
    // _audioPlayer.onPlayerStateChanged.listen((state) {
    //   if (mounted) {
    //     setState(() {
    //       _audioPlayerState = state;
    //     });
    //   }
    // });
    //
    // _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
    //   if (mounted) {
    //     setState(() => _audioPlayerState = state);
    //   }
    // });
    //
    // _playingRouteState = PlayingRoute.SPEAKERS;
  }

// Future<int> _play(int ayaNo) async {
//   final playPosition = (_position != null &&
//           _duration != null &&
//           _position!.inMilliseconds > 0 &&
//           _position!.inMilliseconds < _duration!.inMilliseconds)
//       ? _position
//       : null;
//   // final result = await _audioPlayer.play(
//   //     'https://cdn.alquran.cloud/media/audio/ayah/Hani Rifai/$ayaNo',
//   //     position: playPosition);
//   // if (result == 1) {
//   //   setState(() => _playerState = PlayerState.PLAYING);
//   }
// بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ يَٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُوا۟ رَبَّكُمُ ٱلَّذِى خَلَقَكُم مِّن نَّفْسٍۢ وَٰحِدَةٍۢ وَخَلَقَ مِنْهَا زَوْجَهَا وَبَثَّ مِنْهُمَا رِجَالًۭا كَثِيرًۭا وَنِسَآءًۭ ۚ وَٱتَّقُوا۟ ٱللَّهَ ٱلَّذِى تَسَآءَلُونَ بِهِۦ وَٱلْأَرْحَامَ ۚ إِنَّ ٱللَّهَ كَانَ عَلَيْكُمْ رَقِيبًۭا
//     _audioPlayer.setPlaybackRate();

// return result;
// }

// Future<int> _pause() async {
//   final result = await _audioPlayer.pause();
//   if (result == 1) {
//     setState(() => _playerState = PlayerState.PAUSED);
//   }
//   return result;
// }

// Future<int> _earpieceOrSpeakersToggle() async {
//   final result = await _audioPlayer.earpieceOrSpeakersToggle();
//   if (result == 1) {
//     setState(() => _playingRouteState = _playingRouteState.toggle());
//   }
//   return result;
// }

// Future<int> _stop() async {
//   final result = await _audioPlayer.stop();
//   if (result == 1) {
//     setState(() {
//       _playerState = PlayerState.STOPPED;
//       _position = const Duration();
//     });
//   }
//   return result;
// }

// void _onComplete() {
//   setState(() => _playerState = PlayerState.STOPPED);
// }
}

favorite(index) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  if (sp.getStringList('FAVORITE')!.contains('$index')) {
    return true;
  } else {
    return false;
  }
}
