import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/screens/about.dart' as about;
import 'package:quran_hadith/screens/favorite.dart';
import 'package:quran_hadith/screens/hPage.dart';
import 'package:quran_hadith/screens/qPage.dart';
import 'package:quran_hadith/screens/settings.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/custom_button.dart';
import 'package:quran_hadith/widgets/headerTitle.dart';
import 'package:quran_hadith/widgets/menu_list_items.dart';
import 'package:quran_hadith/widgets/qh_nav.dart';
import 'package:quran_hadith/widgets/shared_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/quranAPI.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> screens = [QPage(), HPage(), Favorite(), Settings()];
  late ValueNotifier<bool> _isExtended = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _isExtended = ValueNotifier<bool>(true);
    // _playerState = player.state;
    // player.getDuration().then(
    //       (value) => setState(() {
    //         _duration = value;
    //       }),
    //     );
    // player.getCurrentPosition().then(
    //       (value) => setState(() {
    //         _position = value;
    //       }),
    //     );
    // _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  late SurahList _searchResults = [] as SurahList;
  final searchController = TextEditingController();
  List<AudioPlayer> audioPlayers = [];

  bool _isSearching = false;

  void _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    final keyword = searchController.text;

    try {
      final searchResults = await QuranAPI().getSearch(keyWord: keyword);

      setState(() {
        _searchResults = searchResults;
      });
    } catch (e) {
      print('Error: $e');
    }

    setState(() {
      _isSearching = false;
    });
  }

  //eef2f5
  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    final isSmallX = isDisplaySmallDesktop(context);
    // var quranAPI = Provider.of<QuranAPI>(context);
    double height = MediaQuery.of(context).size.height;
    final searchFocusNode = FocusNode();
    final _searchBox = Padding(
      padding: const EdgeInsets.fromLTRB(5, 7, 20, 7),
      child: TextField(
        maxLines: 1,
        focusNode: searchFocusNode,
        controller: searchController,
        style: const TextStyle(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(right: 15),
          filled: true,
          focusColor: Theme.of(context).canvasColor,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Theme.of(context).canvasColor),
          ),
          suffixIcon: IconButton(
            splashRadius: 1,
            icon: const FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: Colors.black,
            ),
            onPressed: () {
              // QuranSearchDelegate(_performSearch);
              showSearch(
                  context: context,
                  delegate: QuranSearchDelegate(_performSearch));
            },
          ),
          hintStyle: const TextStyle(fontWeight: FontWeight.w300),
          hintText: '    Search',
          fillColor: Theme.of(context).appBarTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Theme.of(context).canvasColor),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: HeaderText(size: isSmallX ? 20 : 30),
        actions: [
          SizedBox(
              child: isSmall
                  ? AnimSearchBar(
                      width: isSmall ? 200 : 400,
                      color: Theme.of(context).canvasColor,
                      textController: searchController,
                      onSuffixTap: () {
                        setState(() {
                          searchController.clear();
                        });
                      },
                      onSubmitted: (String) {
                        QuranSearchDelegate(_performSearch);
                      },
                    )
                  : _searchBox,
              width: isSmall ? 100 : 350),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                RoundCustomButton(
                  children: [
                    Center(child: Text('Listen To Beautiful Recitation')),
                  ],
                  icon: FontAwesomeIcons.headphonesSimple,
                ),
                RoundCustomButton(
                  children: [
                    Container(
                      height: height / 4,
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(height: 38),
                            FaIcon(FontAwesomeIcons.bell, size: 50),
                            Text('No Notifications'),
                          ],
                        ),
                      ),
                    )
                  ],
                  icon: FontAwesomeIcons.bell,
                )
              ],
            ),
          ),
          SizedBox(width: isSmall ? 100 : 145),
          isSmall
              ? Container()
              : RoundCustomButton2(
                  children: [
                    MItems(
                        text: 'Donate on Patreon',
                        pressed: () {
                          launchUrl(Uri.parse(
                              "https://www.patreon.com/join/kherld/checkout?ru=undefined"));
                          Get.back();
                        }),
                    MItems(
                        text: 'Bug Report',
                        pressed: () {
                          launchUrl(Uri.parse(
                              'https://github.com/kherld-hussein/quran_hadith/issues/'));
                          Get.back();
                        }),
                    MItems(
                        text: 'Feature Request',
                        pressed: () {
                          launchUrl(Uri.parse(
                              'https://github.com/kherld-hussein/quran_hadith/issues/'));
                          Get.back();
                        }),
                    MItems(
                        text: 'About',
                        pressed: () {
                          Get.back();
                          about.showAboutDialog();
                        })
                  ],
                  icon: FontAwesomeIcons.a,
                ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 5.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Get.theme.brightness == Brightness.light
                ? kAccentColor
                : kDarkSecondaryColor,
            child: ImageIcon(AssetImage('assets/images/Logo.png')),
          ),
        ),
      ),
      body: Row(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            return Container(
              child: SingleChildScrollView(
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: ValueListenableBuilder<bool>(
                        valueListenable: _isExtended,
                        builder: (context, value, child) {
                          return NavigationRail(
                            destinations: [
                              NavigationRailDestination(
                                icon: FaIcon(FontAwesomeIcons.bookOpen),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 0 : 24),
                                  child: SizedBox.shrink(),
                                ),
                              ),
                              NavigationRailDestination(
                                icon: FaIcon(FontAwesomeIcons.bookOpenReader),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 0 : 24),
                                  child: SizedBox.shrink(),
                                ),
                              ),
                              NavigationRailDestination(
                                icon: FaIcon(FontAwesomeIcons.heart),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 0 : 24),
                                  child: SizedBox.shrink(),
                                ),
                              ),
                              NavigationRailDestination(
                                icon: FaIcon(FontAwesomeIcons.gear),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 0 : 20),
                                  child: SizedBox.shrink(),
                                ),
                              ),
                            ],
                            selectedIndex: _selectedIndex,
                            onDestinationSelected: (int index) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            labelType: NavigationRailLabelType.all,
                            trailing: IconButton(
                              tooltip: 'Exit',
                              icon: FaIcon(FontAwesomeIcons.rightFromBracket),
                              onPressed: () {
                                SystemSound.play(SystemSoundType.alert);
                                Get.dialog(
                                  AlertDialog(
                                    title:
                                        Text('Are you sure you want to exit?'),
                                    content: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () => SystemNavigator.pop(
                                            animated: true,
                                          ),
                                          child: Text('Exit'),
                                        ),
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('Cancel'),
                                        )
                                      ],
                                    ),
                                    icon: FaIcon(
                                        FontAwesomeIcons.solidCircleQuestion),
                                  ),
                                  name: 'Exit Dialog',
                                );
                              },
                            ),
                          );
                        }),
                  ),
                ),
              ),
            );
          }),
          Expanded(
            child: SharedAxisTransitionSwitcher(
              child: QhNav(child: screens[_selectedIndex]),
            ),
          )
        ],
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();
  }
}

class QuranSearchDelegate extends SearchDelegate {
  final Function performSearch;

  QuranSearchDelegate(this.performSearch);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      title: Text('result.keyword'),
      subtitle: Text('Surah: ${'result.surah'}'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = getSuggestions(query);
    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final suggestion = suggestionList[index];

        return ListTile(
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }

  List<String> getSuggestions(String query) {
    // Implement your logic to fetch and filter suggestions based on the query
    // For example, you can search through a list of suggestions or make an API request

    // Dummy implementation - returning hardcoded suggestions
    final dummySuggestions = [
      'Surah Al-Fatiha',
      'Surah Al-Baqarah',
      'Surah Al-Imran',
      'Surah An-Nisa',
      'Surah Al-Maidah',
      'Surah Al-Anam',
      'Surah Al-Araf',
      'Surah Al-Anfal',
    ];

    return dummySuggestions
        .where((suggestion) =>
            suggestion.toLowerCase().startsWith(query.toLowerCase()))
        .toList();
  }
}
