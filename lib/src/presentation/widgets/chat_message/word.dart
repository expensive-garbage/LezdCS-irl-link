import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class Word extends StatelessWidget {
  final String word;
  final bool isAction;
  final double textSize;
  final String color;

  const Word({
    required this.word,
    required this.isAction,
    required this.textSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    bool isWordLink = Uri.tryParse(word)?.hasAbsolutePath ?? false;
    return !isWordLink
        ? Text(
            word + " ",
            style: TextStyle(
              color: isAction
                  ? Color(int.parse(color.replaceAll('#', '0xff')))
                  : Theme.of(Get.context!).textTheme.bodyLarge!.color,
              fontSize: textSize,
              fontStyle: isAction ? FontStyle.italic : FontStyle.normal,
            ),
          )
        : RichText(
            text: TextSpan(
              text: word + " ",
              style: TextStyle(
                color: Colors.lightBlue,
                decoration: TextDecoration.underline,
                fontSize: textSize,
                fontStyle: isAction ? FontStyle.italic : FontStyle.normal,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (isWordLink) {
                    launchUrl(
                      Uri.parse(word),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
            ),
          );
  }
}
