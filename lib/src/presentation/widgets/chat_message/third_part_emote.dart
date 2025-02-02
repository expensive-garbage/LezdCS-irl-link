import 'package:flutter/material.dart';
import 'package:irllink/src/domain/entities/emote.dart';

class ThirdPartEmote extends StatelessWidget {

  final Emote emote;

  const ThirdPartEmote({required this.emote});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: NetworkImage(emote.url1x),
    );
  }
}
