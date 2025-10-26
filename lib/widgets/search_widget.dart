import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/widgets/suratTile.dart';

class SearchWidget extends SearchDelegate<SurahList> {
  final Future<QuranAPI> quran;

  SearchWidget(this.quran);

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        splashRadius: 10,
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        icon: const FaIcon(FontAwesomeIcons.xmark),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      splashRadius: 10,
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        /// Take control back to previous page
        // this.close(context,context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    var quranAPI = Provider.of<QuranAPI>(context);
    return FutureBuilder(
        future: quranAPI.getSearch(keyWord: query),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) return Container();
          return ListView.builder(
              itemCount: snapshot.data.surahs.length,
              itemBuilder: (context, index) {
                return SuratTile(
                  isFavorite: true,
                  colorI: const Color(0xffe0f5f0),
                  radius: 20,
                  ayahList: snapshot.data.surahs[index].ayahs,
                  suratNo: snapshot.data.surahs[index].number,
                  icon: FontAwesomeIcons.heart,
                  revelationType: snapshot.data.surahs[index].revelationType,
                  englishTrans:
                      snapshot.data.surahs[index].englishNameTranslation,
                  englishName: snapshot.data.surahs[index].englishName,
                  name: snapshot.data.surahs[index].name,
                );
              });
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
        future: quran,
        builder: (context, AsyncSnapshot<QuranAPI> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('Nothing was found'));
          }
          return ListView(
              // children: snapshot.data,
              );
        });
  }
}
