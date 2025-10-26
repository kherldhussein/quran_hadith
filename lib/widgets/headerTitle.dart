import 'package:flutter/material.dart';

class HeaderText extends StatelessWidget {
  final double? size;

  const HeaderText({super.key, this.size});

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
                  fontFamily: 'Poppins',
                  fontSize: size,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3),
              children: <TextSpan>[
                TextSpan(
                    text: 'Hadith',
                    style: TextStyle(
                        fontSize: size,
                        color: Colors.black26,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
