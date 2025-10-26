import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

void showShareDialog({required BuildContext context, text}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SocialShare(text: text),
  );
}

class SocialShare extends StatelessWidget {
  final String? text;

  const SocialShare({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    String message =
        'Assalam\'alaikum! Read and Listen to $text From \nQur’ān Hadith. Get it from the Snap Store https://snapcraft.io/quran-hadith';
    return AlertDialog(
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.circleXmark),
          onPressed: Get.back,
          splashRadius: 10,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
      ],
      title: const Text('Recommend Qur’ān Hadith'),
      content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Text(
                'Qur’ān Hadith is an Online Quran and Hadith application with a fashion interface, smooth performance, and more features to sharpen your focus on what you are reading or listening to.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              Text(
                '━═══◎ Share ◎═══━',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF59E1B),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      tooltip: 'Mail',
                      icon: const Icon(Icons.mail, color: Colors.white),
                      onPressed: () => launchURL(
                          'mailto:?subject=Qur’ān Hadith App&body=$message'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff294C8C),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      tooltip: 'Facebook',
                      icon: const Icon(FontAwesomeIcons.facebookF,
                          color: Colors.white),
                      onPressed: () => launchURL(
                          'https://www.facebook.com/sharer/sharer.php?t=Assalam\'alaikum&quote=Read and Listen to $text&ref=fbshare&u=https://snapcraft.io/quran-hadith'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff67C15E),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      tooltip: 'WhatsApp',
                      icon: const Icon(FontAwesomeIcons.whatsapp,
                          color: Colors.white),
                      onPressed: () =>
                          launchURL('https://wa.me/?text=$message'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffA2A2A2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                        tooltip:
                            MaterialLocalizations.of(context).copyButtonLabel,
                        icon: const Icon(FontAwesomeIcons.link,
                            color: Colors.white),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Clipboard.setData(ClipboardData(text: message)).then(
                            (value) => Get.snackbar(
                              "copied!",
                              'Link copied',
                              messageText: const Row(
                                children: [
                                  FaIcon(Icons.verified_user),
                                  Text('Link copied'),
                                ],
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              )
            ],
          )),
    );
  }
}

Future launchURL(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await canLaunchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}
