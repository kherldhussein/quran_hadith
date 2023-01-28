import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/headerTitle.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.transparent,
        child: Center(
          child: Card(
            color: Get.theme.brightness == Brightness.light
                ? Color(0xffdae1e7)
                : Theme.of(context).cardColor,
            elevation: 20,
            child: Container(
              height: 500,
              width: 500,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: AboutView(),
            ),
          ),
        ),
      ),
    );
  }
}

class AboutView extends StatefulWidget {
  @override
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView>
    with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[
    Tab(text: "Qur’ān Hadith"),
    Tab(text: "Author"),
    Tab(text: "Licenses")
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.circleXmark),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 10,
          )
        ],
        backgroundColor: Get.theme.brightness == Brightness.light
            ? Color(0xffdae1e7)
            : Theme.of(context).cardColor,
        title: Text(
          "About Qur’ān Hadith",
          style: TextStyle(fontFamily: 'ReemKufi'),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          isScrollable: true,
          tabs: tabs,
          controller: _tabController,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            child: Scrollbar(
              child: ListView(
                padding: EdgeInsets.all(10),
                children: [
                  SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/Logo.png',
                          color: Color(0xff06291d),
                          scale: 7,
                        ),
                        HeaderText(size: isSmall ? 30 : 40),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                      'Version: 1.${DateTime.now().year}.${DateTime.now().month + 12}',
                      style: theme.headline5),
                  SizedBox(height: 20),
                  Text(
                    'Qur’ān Hadith is an Online Quran and Hadith application with fashion interface, smooth performance and more features '
                    'to sharpens your focus on what you are reading or listening.\n\nPlease see the changelog file for recent improvements and the issue tracker for short-term plans.',
                    style: theme.headline6,
                  )
                ],
              ),
            ),
          ),
          Container(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: isSmall ? 10 : 20.0,
                      left: isSmall ? 10 : 20,
                      right: isSmall ? 10 : 20),
                  child: Container(
                    child: SingleChildScrollView(
                      scrollDirection:
                          isSmall ? Axis.horizontal : Axis.vertical,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text("Name")),
                          Chip(label: Text("E-mail")),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Card(
                  child: ListTile(
                    title: Text(
                      'Kherld Hussein ',
                      style: TextStyle(
                          fontSize: isSmall ? 10 : 24,
                          fontFamily: 'Quattrocento'),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 10 : 20,
                        vertical: isSmall ? 10 : 20),
                    trailing: InkWell(
                      radius: 0,
                      splashColor: Theme.of(context).cardColor,
                      hoverColor: Theme.of(context).cardColor,
                      highlightColor: Theme.of(context).cardColor,
                      child: Text(
                        'kherld11@gmail.com',
                        style: theme.headline6!.copyWith(
                            fontSize: isSmall ? 10 : 20,
                            decoration: TextDecoration.underline,
                            fontFamily: 'Quattrocento',
                            color: kLinkC),
                      ),
                      onTap: () =>
                          launchUrl(Uri.parse('mailto:kherld11@gmail.com')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Scrollbar(
              thumbVisibility: true,
              controller: ScrollController(),
              child: ListView(
                padding: EdgeInsets.all(10),
                children: [
                  Text(
                    "Qur’ān Hadith is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by "
                    "the Free Software Foundation, either version 3 of the License, or (at your option) any later version. \n\nQur’ān Hadith is distributed in the hope that it will be useful In Sha Allah, "
                    "You should have received a copy of the GNU General Public License along with this program. \nIf not, see",
                    style: theme.headline6,
                  ),
                  InkWell(
                    splashColor: Theme.of(context).scaffoldBackgroundColor,
                    hoverColor: Theme.of(context).scaffoldBackgroundColor,
                    highlightColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Text(
                      "http://www.gnu.org/licenses/",
                      style: theme.headline6!.copyWith(color: kLinkC),
                    ),
                    onTap: () =>
                        launchUrl(Uri.parse('http://www.gnu.org/licenses/')),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
