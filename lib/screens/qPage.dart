import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/anim/particle_canvas.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/widgets/suratTile.dart';
import 'package:rxdart/src/rx.dart' as rx;
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/favorite.dart';

class QPage extends StatefulWidget {
  const QPage({super.key});

  @override
  _QPageState createState() => _QPageState();
}

class _QPageState extends State<QPage> with AutomaticKeepAliveClientMixin {
  int index = 0;
  int surahIndex = 0;
  bool isPLaying = false;
  bool isLoaded = false;
  bool isLoading = false;
  var list;
  final audioPlayer = AudioPlayer();
  String? user = 'Ahmed';

  // List<String> surahList = SuratList().surahName;
  List<String> linkList = [];
  var currentPlaying;
  List<String> reciterList = [];

  // Map<String, String> map = AudioList().map;
  late Stream<DurationState> durationState;
  late TextEditingController name;

  @override
  void initState() {
    // map.forEach(
    //   (key, val) {
    //     reciterList.add(key);
    //     linkList.add(val);
    //   },
    // );
    initUser();
    name = TextEditingController();
    durationState =
        rx.Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      audioPlayer.positionStream,
      audioPlayer.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    );
    super.initState();
  }

  initUser() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      user = sp.getString('user')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var quranAPI = Provider.of<QuranAPI>(context);
    final fav = Provider.of<OnFavorite>(context, listen: false);
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    final isSmall = context.isLargeTablet;
    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: Container(
        constraints: BoxConstraints(minWidth: 0),
        color: theme.appBarTheme.backgroundColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(minWidth: 0),
                decoration: BoxDecoration(
                  color: Get.theme.brightness == Brightness.light
                      ? Color(0xffeef2f5)
                      : kDarkPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                width: isSmall ? size.width - 300 : size.width - 320,
                child: FutureBuilder(
                    future: quranAPI.getSuratList(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: ParticleCanvas(size.height, size.width - 150),
                        );
                      } else {
                        return GridView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 40.0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isSmall ? 4 : 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: snapshot.data.surahs.length,
                          itemBuilder: (context, index) {
                            return SuratTile(
                              colorO: kAccentColor,
                              itemCount: snapshot.data.surahs.length,
                              isFavorite: fav.isFavorite,
                              onFavorite: () {
                                setState(() {
                                  fav.addFavorite(
                                      snapshot.data.surahs[index].name);
                                  fav.addIsFavorite(true);
                                });
                              },
                              colorI: Color(0xffe0f5f0),
                              radius: 20,
                              ayahList: snapshot.data.surahs[index].ayahs,
                              suratNo: snapshot.data.surahs[index].number,
                              icon: FontAwesomeIcons.heart,
                              revelationType:
                                  snapshot.data.surahs[index].revelationType,
                              englishTrans: snapshot
                                  .data.surahs[index].englishNameTranslation,
                              englishName:
                                  snapshot.data.surahs[index].englishName,
                              name: snapshot.data.surahs[index].name,
                            );
                          },
                        );
                      }
                    }),
              ),
              Container(
                constraints: BoxConstraints(minWidth: 0),
                padding: EdgeInsets.symmetric(vertical: 20),
                height: size.height,
                color: theme.appBarTheme.backgroundColor,
                margin: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 20),
                width: isSmall ? 180 : 200,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salam,',
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),
                            Text(
                              user!,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        ClipOval(
                          child: Material(
                            color: kAccentColor.withOpacity(.05),
                            child: IconButton(
                              icon: FaIcon(FontAwesomeIcons.user),
                              onPressed: () {
                                Get.dialog(
                                  AlertDialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    title: Text('Edit profile'),
                                    content: Container(
                                      height: size.height / 3,
                                      width: size.width / 3,
                                      decoration: BoxDecoration(
                                        color:
                                            Color(0xFFFAFAFC).withOpacity(.1),
                                        border: Border.all(
                                            color: Colors.transparent),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              TextField(
                                                controller: name,
                                                decoration: InputDecoration(
                                                  labelText: 'Enter your Name',
                                                  helperText:
                                                      'Only first or last name',
                                                  hintText: user!,
                                                  prefix: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: FaIcon(
                                                        FontAwesomeIcons.user),
                                                  ),
                                                  prefixIcon: FaIcon(
                                                      FontAwesomeIcons
                                                          .asterisk),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                              SizedBox(height: 20),
                                              CupertinoButton(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 50),
                                                color: kAccentColor,
                                                onPressed: () async {
                                                  setState(() {
                                                    if (name.text.isNotEmpty) {
                                                      if (name.text.length <
                                                          12) {
                                                        SpUtil.setUser(name.text
                                                                .trim())
                                                            .then((value) =>
                                                                Get.back());
                                                      }
                                                    }
                                                  });
                                                },
                                                child: Text('Save'),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  name: 'profile dialog',
                                );
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                    Divider(height: 65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LAST READ',
                              style: TextStyle(
                                  color: kAccentColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "Al-Fatiah",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text('Ayah no. 3')
                          ],
                        ),
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.book),
                          onPressed: () {},
                          color: Theme.of(context).canvasColor,
                        )
                      ],
                    ),
                    Divider(height: 65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LAST LISTENED',
                              style: TextStyle(
                                  color: kAccentColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "Al-Ma'idah",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text('Ayah no. 3')
                          ],
                        ),
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.headphonesSimple),
                          onPressed: () {},
                          color: Theme.of(context).canvasColor,
                        )
                      ],
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AYAH OF THE DAY',
                            style: TextStyle(
                              color: Color(0xff017044),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Indeed, We have revealed to you, [O Muhammad], the Book in truth so you '
                            'may judge between the people by that which God has shown you ...',
                            style: TextStyle(color: Color(0xffdae1e7)),
                          ),
                          Divider(height: 20, color: kLightPrimaryColor),
                          InkWell(
                            onTap: () => Get.dialog(
                              AlertDialog(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                title: Text('AYAH OF THE DAY'),
                                content: Container(
                                  height: size.height / 2,
                                  width: size.width / 3,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFAFAFC).withOpacity(.1),
                                    border:
                                        Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15),
                                    ),
                                  ),
                                  child: Card(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(10),
                                      title: Text(
                                        '''
Indeed, We have revealed to you, [O Muhammad], the Book in truth so you may judge between the people by that which Allah has shown you. And do not be for the deceitful an advocate.''',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 20,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Sūrah 4: an-Nisā’ [105]',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w100,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              name: 'Ayah of Day dialog',
                            ),
                            child: Text('Read now',
                                style: TextStyle(color: Color(0xffdae1e7))),
                          ),
                        ],
                      ),
                    )
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

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

class DurationState {
  final Duration? progress;
  final Duration? buffered;
  final Duration? total;

  const DurationState({this.progress, this.buffered, this.total});
}
