import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:irllink/routes/app_routes.dart';
import 'package:irllink/src/presentation/controllers/home_view_controller.dart';
import 'package:irllink/src/presentation/events/settings_events.dart';

import '../../domain/entities/twitch_user.dart';

class SettingsViewController extends GetxController {
  SettingsViewController({required this.settingsEvents});

  final SettingsEvents settingsEvents;

  late TextEditingController alternateChannelChatController;
  late TextEditingController obsWebsocketUrlFieldController;
  late TextEditingController obsWebsocketPasswordFieldController;
  late TextEditingController streamElementsFieldController;
  late TextEditingController addBrowserTitleController;
  late TextEditingController addBrowserUrlController;
  late TextEditingController addHiddenUsernameController;

  final addBrowserUrlKey = GlobalKey<FormState>();
  final addBrowserTitleKey = GlobalKey<FormState>();
  final addHiddenUserKey = GlobalKey<FormState>();

  late RxList<String> usernamesHiddenUsers;

  RxBool obsWebsocketPasswordShow = false.obs;
  RxBool obsWebsocketUrlShow = false.obs;
  RxBool seJwtShow = false.obs;

  RxList ttsLanguages = [].obs;
  RxList ttsVoices = [].obs;
  late TextEditingController addTtsIgnoredUsersController;
  late TextEditingController addTtsIgnoredPrefixsController;
  late TextEditingController addTtsAllowedPrefixsController;
  Rx<Color> nothingJustToRefreshDialog = Colors.grey.obs;

  late HomeViewController homeViewController;

  @override
  void onInit() {
    homeViewController = Get.find<HomeViewController>();

    alternateChannelChatController = TextEditingController();
    obsWebsocketUrlFieldController = TextEditingController();
    streamElementsFieldController = TextEditingController();
    obsWebsocketPasswordFieldController = TextEditingController();
    addBrowserTitleController = TextEditingController();
    addBrowserUrlController = TextEditingController();
    addHiddenUsernameController = TextEditingController();
    addTtsIgnoredUsersController = TextEditingController();
    addTtsIgnoredPrefixsController = TextEditingController();
    addTtsAllowedPrefixsController = TextEditingController();

    usernamesHiddenUsers = <String>[].obs;
    getTtsLanguages();
    getTtsVoices();
    super.onInit();
  }

  @override
  void onReady() {
    if (homeViewController.twitchData != null) {
      alternateChannelChatController.text =
          homeViewController.settings.value.alternateChannelName!;
      obsWebsocketUrlFieldController.text =
          homeViewController.settings.value.obsWebsocketUrl!;
      obsWebsocketPasswordFieldController.text =
          homeViewController.settings.value.obsWebsocketPassword!;
      streamElementsFieldController.text =
          homeViewController.settings.value.streamElementsAccessToken!;

      getUsernames();
    }

    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void logout() {
    settingsEvents
        .logout(accessToken: homeViewController.twitchData!.accessToken)
        .then(
          (value) => Get.offAllNamed(Routes.LOGIN),
        );
  }

  void login() {
    Get.offAllNamed(Routes.LOGIN);
  }

  void removeHiddenUser(userId) {
    List hiddenUsersIds = homeViewController.settings.value.hiddenUsersIds!;
    hiddenUsersIds.remove(userId);
    homeViewController.settings.value = homeViewController.settings.value
        .copyWith(hiddenUsersIds: hiddenUsersIds);
    saveSettings();
    homeViewController.settings.refresh();
  }

  void addBrowserTab() {
    bool isValid = false;
    isValid = addBrowserTitleKey.currentState!.validate();
    isValid = addBrowserUrlKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    String title = addBrowserTitleController.text;
    String url = addBrowserUrlController.text;
    Map<String, String> tab = {'title': title, 'url': url};
    List browserTabs =
        homeViewController.settings.value.browserTabs! == const []
            ? []
            : homeViewController.settings.value.browserTabs!;
    browserTabs.add(tab);
    homeViewController.settings.value =
        homeViewController.settings.value.copyWith(browserTabs: browserTabs);
    saveSettings();
    homeViewController.settings.refresh();
    Get.back();
  }

  void editBrowserTab(elem) {
    bool isValid = false;
    isValid = addBrowserTitleKey.currentState!.validate();
    isValid = addBrowserUrlKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    String title = addBrowserTitleController.text;
    String url = addBrowserUrlController.text;
    elem["title"] = title;
    elem["url"] = url;
    List browserTabs =
        homeViewController.settings.value.browserTabs! == const []
            ? []
            : homeViewController.settings.value.browserTabs!;
    homeViewController.settings.value =
        homeViewController.settings.value.copyWith(browserTabs: browserTabs);
    saveSettings();
    homeViewController.settings.refresh();
    Get.back();
  }

  void removeBrowserTab(tab) {
    List tabs = homeViewController.settings.value.browserTabs!;
    tabs.remove(tab);
    homeViewController.settings.value =
        homeViewController.settings.value.copyWith(browserTabs: tabs);
    saveSettings();
    homeViewController.settings.refresh();
  }

  void saveSettings() {
    settingsEvents.setSettings(settings: homeViewController.settings.value);
  }

  Future getUsernames() async {
    List<TwitchUser> users = [];

    await settingsEvents
        .getTwitchUsers(
            ids: homeViewController.settings.value.hiddenUsersIds!,
            accessToken: homeViewController.twitchData!.accessToken)
        .then((value) => users = value.data!);

    users.forEach((user) => usernamesHiddenUsers.add(user.displayName));
  }

  void getTtsLanguages() {
    FlutterTts flutterTts = FlutterTts();
    flutterTts.getLanguages.then((value) => {
          ttsLanguages.value = value,
          ttsLanguages.sort((a, b) => a.compareTo(b))
        });
  }

  void getTtsVoices() {
    FlutterTts flutterTts = FlutterTts();
    flutterTts.getVoices.then((value) => {
          ttsVoices.value = value,
          ttsVoices.sort((a, b) => a['name'].compareTo(b['name']))
        });
  }

  void purchase() async {
    final ProductDetails productDetails = homeViewController.products[0];
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
