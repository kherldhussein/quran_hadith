import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../layout/adaptive.dart';
import '../theme/app_theme.dart';
import '../widgets/headerTitle.dart';

void showAboutDialog() {
  Get.dialog(
    About(),
    name: 'About QH',
    barrierDismissible: false,
    transitionCurve: Curves.easeInOutCirc,
  );
}

/// todo: Implement native Linux tab - Scroll from the bottom
class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      backgroundColor: Theme.of(context).canvasColor,
      content: Container(height: 560, width: 560, child: AboutView()),
    );
  }
}

class AboutView extends StatefulWidget {
  @override
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> with TickerProviderStateMixin {
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.circleXmark),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 10,
          )
        ],
        backgroundColor: Theme.of(context).canvasColor,
        title: Text("About Qur’ān Hadith"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          tabs: tabs,
          isScrollable: true,
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          splashBorderRadius: BorderRadius.circular(20),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
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
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qur’ān Hadith', style: theme.headlineSmall),
                        SizedBox(height: 8),
                        Text(
                          'Version: 1.0.0 (build 1)',
                          style: theme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: theme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Qur’ān Hadith helps you read, listen and search the Qur’ān and browse Hadith collections with a clean, desktop-friendly experience. Supports offline favorites, resume reading/listening, and adaptive theming.',
                          style: theme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _LinkButton(
                      icon: FontAwesomeIcons.github,
                      label: 'Source Code',
                      onTap: () => launchUrl(Uri.parse(
                          'https://github.com/kherld-hussein/quran_hadith')),
                    ),
                    _LinkButton(
                      icon: FontAwesomeIcons.bug,
                      label: 'Report a Bug',
                      onTap: () => launchUrl(Uri.parse(
                          'https://github.com/kherld-hussein/quran_hadith/issues/')),
                    ),
                    _LinkButton(
                      icon: FontAwesomeIcons.lightbulb,
                      label: 'Request Feature',
                      onTap: () => launchUrl(Uri.parse(
                          'https://github.com/kherld-hussein/quran_hadith/issues/')),
                    ),
                    _LinkButton(
                      icon: FontAwesomeIcons.heart,
                      label: 'Support',
                      onTap: () => launchUrl(Uri.parse(
                          'https://www.patreon.com/join/kherld/checkout?ru=undefined')),
                    ),
                  ],
                ),
              ],
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
                    right: isSmall ? 10 : 20,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text("Name")),
                      Chip(label: Text("E-mail")),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                ListTile(
                  title: Text(
                    'Khalid Hussein',
                    style: TextStyle(fontSize: isSmall ? 10 : 24),
                  ),
                  contentPadding: EdgeInsets.only(top: 20),
                  trailing: GestureDetector(
                    child: Text(
                      'kherld11@gmail.com',
                      style: theme.titleMedium!.copyWith(
                        decoration: TextDecoration.underline,
                        fontSize: isSmall ? 10 : 20,
                        color: kLinkC,
                      ),
                    ),
                    onTap: () =>
                        launchUrl(Uri.parse('mailto:kherld11@gmail.com')),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                Text(
                  "Qur’ān Hadith is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by "
                  "the Free Software Foundation, either version 3 of the License, or (at your option) any later version. \n\nQur’ān Hadith is distributed in the hope that it will be useful In Sha Allah, "
                  "You should have received a copy of the GNU General Public License along with this program. \nIf not, see",
                  style: theme.titleLarge,
                ),
                InkWell(
                  splashColor: Theme.of(context).scaffoldBackgroundColor,
                  hoverColor: Theme.of(context).scaffoldBackgroundColor,
                  highlightColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Text(
                    "http://www.gnu.org/licenses/",
                    style: theme.titleLarge!.copyWith(color: kLinkC),
                  ),
                  onTap: () =>
                      launchUrl(Uri.parse('http://www.gnu.org/licenses/')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 16),
            SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
