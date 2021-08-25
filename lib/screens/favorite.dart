import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/suratTile.dart';

class Favorite extends StatefulWidget {
  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    final isSmall = isDisplayVerySmallDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.color,
      body: Container(
        constraints: BoxConstraints(minWidth: 0),
        color: theme.appBarTheme.color,
        child: Container(
          width: isSmall ? size.width - 300 : size.width,
          constraints: BoxConstraints(minWidth: 0),
          decoration: BoxDecoration(
            color: Get.theme.brightness == Brightness.light
                ? Color(0xffeef2f5)
                : kDarkPrimaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              // topRight: Radius.circular(30),
            ),
          ),
          child: ListView(
            children: [
              Container(
                height: size.height / 2,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    // topRight: Radius.circular(30),
                  ),
                ),
                child: FutureBuilder(
                    future: null,
                    builder: (context,AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Lottie.asset('assets/anim/pulse.json'),
                        );
                      }
                      return ListView.builder(
                          itemCount: snapshot.data.length!,
                          itemBuilder: (context, index) {
                            return SuratTile(
                              colorO: kAccentColor,
                              isFavorite: true,
                              colorI: Color(0xffe0f5f0),
                              radius: 20,
                              ayahList: snapshot.data!.ayahList,
                              suratNo: snapshot.data!.suratIndex,
                              icon: FontAwesomeIcons.heart,
                              revelationType: snapshot.data!.suratRevelation,
                              englishTrans: snapshot.data.englishTrans,
                              englishName: snapshot.data.suratEnName,
                              name: snapshot.data.suratName,
                            );
                          });
                    }),
              ),
              FutureBuilder(
                  future: null,
                  builder: (context, snapshot) {
                    return Container(
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        ),
                      ),
                    );
                  }
              )
            ],
          ),
        ),
      ),
    );
  }
}
