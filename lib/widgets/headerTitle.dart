import 'package:flutter/material.dart';

class HeaderText extends StatelessWidget {
  final double? size;

  const HeaderText({Key? key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          RichText(
            text: TextSpan(
              text: 'Qur’ān ',
              style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: size,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3),
              children: <TextSpan>[
                TextSpan(
                    text: 'Hadith',
                    style: TextStyle(
                        fontSize: size,
                        color: Colors.black12,
                        fontFamily: 'Quattrocento',
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
