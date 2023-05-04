import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
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
    var favorite = Provider.of<OnFavorite>(context, listen: false);
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    final isSmall = isDisplayVerySmallDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: Container(
        constraints: BoxConstraints(minWidth: 0),
        color: theme.appBarTheme.backgroundColor,
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    // topRight: Radius.circular(30),
                  ),
                ),
                child: FutureBuilder(
                    future: favorite.getFavorites(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 50),
                          ),
                        );
                      }
                      return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isSmall ? 4 : 5,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: snapshot.data.surahs.length,
                          itemBuilder: (context, index) {
                            return SuratTile(
                              colorO: kAccentColor,
                              isFavorite: favorite.isFavorite,
                              colorI: Color(0xffe0f5f0),
                              onFavorite: () {
                                setState(() {
                                  favorite.removeFavorite(
                                    snapshot.data.surahs[index].name,
                                  );
                                  favorite.addIsFavorite(false);
                                });
                              },
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
                          });
                    }),
              ),
              FutureBuilder(
                future: null,
                builder: (context, snapshot) {
                  return Container(
                    child: Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 20,
                        ),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
