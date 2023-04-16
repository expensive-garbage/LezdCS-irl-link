import 'package:flutter/material.dart';
import 'package:irllink/src/presentation/controllers/settings_view_controller.dart';
import 'package:get/get.dart';

class Tts extends StatelessWidget {
  final SettingsViewController controller;

  const Tts({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            onPressed: () => Get.back(),
          ),
          actions: [],
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Text(
            "Text To Speech",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          centerTitle: false,
        ),
        body: Container(
          padding: EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 8),
          color: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Activate TTS",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  Switch(
                    value: controller.settings.value.ttsEnabled!,
                    onChanged: (value) {
                      controller.settings.value =
                          controller.settings.value.copyWith(ttsEnabled: value);
                      controller.saveSettings();
                    },
                    inactiveTrackColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                    activeTrackColor: Theme.of(context).colorScheme.tertiary,
                    activeColor: Colors.white,
                  ),
                ],
              ),
              //prefixs to ignore
              //prefixs to use TTS only
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Language",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  DropdownMenu(
                    initialSelection: controller.ttsLanguages.firstWhere(
                      (element) =>
                          element == controller.settings.value.language,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      contentPadding: EdgeInsets.only(left: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                    onSelected: (value) {
                      controller.settings.value =
                          controller.settings.value.copyWith(language: value);
                      controller.saveSettings();
                    },
                    dropdownMenuEntries: List.generate(
                      controller.ttsLanguages.length,
                      (index) => DropdownMenuEntry(
                        value: controller.ttsLanguages[index],
                        label: controller.ttsLanguages[index],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Voice",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  DropdownMenu(
                    initialSelection: controller.ttsVoices.firstWhere(
                      (element) =>
                          element["name"] ==
                          controller.settings.value.voice!["name"],
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      contentPadding: EdgeInsets.only(left: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                    onSelected: (value) {
                      Map<String, String> voice = {
                        "name": value["name"],
                        "locale": value["locale"],
                      };
                      controller.settings.value =
                          controller.settings.value.copyWith(voice: voice);
                      controller.saveSettings();
                    },
                    dropdownMenuEntries: List.generate(
                      controller.ttsVoices.length,
                      (index) => DropdownMenuEntry(
                        value: controller.ttsVoices[index],
                        label: controller.ttsVoices[index]["name"],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Volume",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  Slider(
                    value: controller.settings.value.volume!,
                    onChanged: (value) {
                      controller.settings.value =
                          controller.settings.value.copyWith(volume: value);
                      controller.saveSettings();
                    },
                    max: 1,
                    min: 0,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    inactiveColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Speech rate",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  Slider(
                    value: controller.settings.value.rate!,
                    onChanged: (value) {
                      controller.settings.value =
                          controller.settings.value.copyWith(rate: value);
                      controller.saveSettings();
                    },
                    max: 1,
                    min: 0,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    inactiveColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pitch",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 18,
                    ),
                  ),
                  Slider(
                    value: controller.settings.value.pitch!,
                    onChanged: (value) {
                      controller.settings.value =
                          controller.settings.value.copyWith(pitch: value);
                      controller.saveSettings();
                    },
                    max: 1,
                    min: 0,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    inactiveColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
