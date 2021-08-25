import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:popover/popover.dart';
import 'package:quran_hadith/controller/search.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/search/ayah.dart';
import 'package:quran_hadith/screens/about.dart';
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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int repeated = 0;
  List<Aya> ayahs = [];
  List<Widget> screens = [QPage(), HPage(), Favorite(), Settings()];
  bool load = false;

  // final _api = Get.find<QuranAPI>();

  void initData() async {
    Search search = Search();
    await search.loadSurah();
  }

  @override
  void initState() {
    super.initState();
    _isExtended = ValueNotifier<bool>(true);
  }

  final searchController = TextEditingController();
  late ValueNotifier<bool> _isExtended;

  //eef2f5
  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    final isSmallX = isDisplaySmallDesktop(context);
    double height = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final searchFocusNode = FocusNode();
    final _searchBox = Padding(
      padding: const EdgeInsets.fromLTRB(30, 5, 10, 5),
      child: TextField(
        maxLines: 1,
        focusNode: searchFocusNode,
        controller: searchController,
        style: const TextStyle(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(right: 15),
          filled: true,
          focusColor: Color(0xffeef2f5),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Color(0xffeef2f5)),
          ),
          suffixIcon: IconButton(
            splashRadius: 1,
            icon: const Icon(FontAwesomeIcons.search, color: Colors.black),
            onPressed: () {
              // showSearch(context: context, delegate: SearchWidget());
            },
          ),
          hintStyle: const TextStyle(fontWeight: FontWeight.w700),
          hintText: 'Search',
          fillColor: Colors.grey[200]!.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Color(0xffeef2f5)),
          ),
        ),
      ),
    );
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: HeaderText(size: isSmallX ? 20 : 30),
          actions: [
            SizedBox(
                child: isSmall
                    ? AnimSearchBar(
                        width: isSmall ? 200 : 400,color: Get.theme.brightness == Brightness.light
                    ? Color(0xffeef2f5)
                    : kDarkPrimaryColor,
                        textController: searchController,
                        onSuffixTap: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                      )
                    : _searchBox,
                width: isSmall ? 100 : 350),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  RoundCustomButton(children: [
                    Center(child: Text('Listen To Beautiful Recitation'))
                  ], icon: FontAwesomeIcons.headphonesAlt),
                  SizedBox(width: isSmall ? 7 : 10),
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
            isSmall
                ? Container()
                : Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: height * 0.01, horizontal: isSmall ? 15 : 20),
                    child: InkWell(
                      onTap: () {
                        showPopover(
                          context: context,
                          backgroundColor: theme.cardColor,
                          bodyBuilder: (BuildContext context) => ListItems(
                            children: [
                              MItems(
                                  text: 'Donate on Patreon',
                                  pressed: () {
                                    launch(
                                        "https://www.patreon.com/join/kherld/checkout?ru=undefined");
                                    Get.back();
                                  }),
                              MItems(
                                  text: 'Bug Report',
                                  pressed: () {
                                    launch(
                                        "https://github.com/kherld-hussein/quran_hadith/issues/");
                                    Get.back();
                                  }),
                              MItems(
                                  text: 'Feature Request',
                                  pressed: () {
                                    launch(
                                        "https://github.com/kherld-hussein/quran_hadith/issues/");
                                    Get.back();
                                  }),
                              MItems(
                                  text: 'About',
                                  pressed: () {
                                    Get.back();
                                    showDialog(
                                        context: context,
                                        builder: (context) => About());
                                  })
                            ],
                          ),
                        );
                      },
                      hoverColor: theme.appBarTheme.backgroundColor,
                      splashColor: theme.appBarTheme.backgroundColor,
                      highlightColor: theme.appBarTheme.backgroundColor,
                      child: Container(
                        constraints: BoxConstraints(minWidth: 0, minHeight: 0),
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 10 : 20,
                            vertical: isSmall ? 7 : 10),
                        decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius:
                              BorderRadius.circular(isSmall ? 17 : 20),
                        ),
                        child: Text('Support',
                            style: TextStyle(color: kLightPrimaryColor)),
                      ),
                    ),
                  )
          ],
          leading: Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 5.0),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: kAccentColor,
              child: Hero(
                tag: "Logo",
                child: ImageIcon(
                  AssetImage('assets/images/logo.png'),
                ),
              ),
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
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
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
                                  icon: FaIcon(FontAwesomeIcons.bookReader),
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
                                  icon: FaIcon(FontAwesomeIcons.cog),
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
                                icon: FaIcon(FontAwesomeIcons.signOutAlt),
                                onPressed: () =>
                                //todo: get dialog
                                    SystemNavigator.pop(animated: true),
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
      ),
    );
  }
}
