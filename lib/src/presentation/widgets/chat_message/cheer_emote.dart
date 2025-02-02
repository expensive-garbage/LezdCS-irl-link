import 'package:flutter/material.dart';
import 'package:irllink/src/domain/entities/emote.dart';

class CheerEmote extends StatelessWidget {
  final Emote cheerEmote;
  final double textSize;

  const CheerEmote({
    required this.cheerEmote,
    required this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Image(
          image: NetworkImage(cheerEmote.url1x),
        ),
        Text(
          cheerEmote.id + ' ',
          style: TextStyle(
            color: Color(int.parse(cheerEmote.color!.replaceAll('#', '0xff'))),
            fontSize: textSize,
          ),
        ),
      ],
    );
  }
}
