import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/anim/particle_canvas.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/widgets/suratTile.dart';

class QPage extends StatefulWidget {
  @override
  _QPageState createState() => _QPageState();
}

class _QPageState extends State<QPage> with AutomaticKeepAliveClientMixin {
  bool isPLaying = false;
  bool isLoaded = false;
  bool isLoading = false;
  var list;
  AudioPlayer? audioPlayer;
  var currentPlaying;
  bool turnF = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var quranAPI = Provider.of<QuranAPI>(context);
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    final isSmall = isDisplayVerySmallDesktop(context);
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
                    builder: (context,AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                            child: ParticleCanvas(
                                height: size.height, width: size.width - 150));
                      } else {
                        return GridView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 40.0),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isSmall ? 3 : 4,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: snapshot.data.surahs.length,
                          itemBuilder: (context, index) {
                            return SuratTile(
                              colorO: kAccentColor,
                              isFavorite: true,
                              onFavorite: () {
                                setState(() {
                                  Provider.of<OnFavorite>(context,
                                      listen: false)
                                      .addFavorite(true);
                                  turnF = true;
                                  SpUtil.setFavorite(true);
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
                  children: [
                    ListTile(
                      title: Text(
                        'LAST READ',
                        style: TextStyle(color: kAccentColor),
                      ),
                      // hoverColor: Colors.green,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      subtitle: Column(
                        children: [Text("AL FATIHA"), Text('Ayah no. 3')],
                      ),
                      trailing: IconButton(
                        icon: FaIcon(FontAwesomeIcons.book),
                        onPressed: () {},
                      ),
                    ),
                    Divider(height: 65, endIndent: 35, indent: 35),
                    ListTile(
                      title: Text(
                        'LAST LISTENED',
                        style: TextStyle(color: kAccentColor),
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      subtitle: Column(
                        children: [Text('AL FATIHA'), Text('Ayah no. 3')],
                      ),
                      trailing: IconButton(
                        icon: FaIcon(FontAwesomeIcons.headphonesAlt),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      // height: 100,
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AYAH OF THE DAY',
                              style: TextStyle(color: Color(0xffdae1e7))),
                          SizedBox(height: 10),
                          Text(
                            'Indeed, We have revealed to you, [O Muhammad], the Book in truth so you '
                                'may judge between the people by that which God has shown you ...',
                            style: TextStyle(
                                color: Color(0xffdae1e7), letterSpacing: 2),
                          ),
                          Divider(
                            height: 20,
                            endIndent: 30,
                            indent: 30,
                            color: Color(0xffdae1e7),
                          ),
                          InkWell(
                            onTap: () => Get.dialog(
                              AlertDialog(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
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
                                          fontWeight: FontWeight.w200,
                                          fontSize: 20,
                                        ),
                                      ),
                                      subtitle: Text('Sūrah 4: an-Nisā’ [105]'),
                                    ),
                                  ),
                                ),
                              ),
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
}
