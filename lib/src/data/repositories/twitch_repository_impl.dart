import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:irllink/src/core/params/twitch_auth_params.dart';
import 'package:irllink/src/core/resources/data_state.dart';
import 'package:irllink/src/core/utils/constants.dart';
import 'package:irllink/src/data/entities/emote_dto.dart';
import 'package:irllink/src/data/entities/twitch_badge_dto.dart';
import 'package:irllink/src/data/entities/twitch_credentials_dto.dart';
import 'package:irllink/src/data/entities/twitch_decoded_idtoken_dto.dart';
import 'package:irllink/src/data/entities/twitch_stream_infos_dto.dart';
import 'package:irllink/src/data/entities/twitch_user_dto.dart';
import 'package:irllink/src/domain/entities/chat/twitch_chat_message.dart';
import 'package:irllink/src/domain/entities/emote.dart';
import 'package:irllink/src/domain/entities/twitch_badge.dart';
import 'package:irllink/src/domain/entities/twitch_credentials.dart';
import 'package:irllink/src/domain/entities/twitch_poll.dart';
import 'package:irllink/src/domain/entities/twitch_prediction.dart';
import 'package:irllink/src/domain/entities/twitch_stream_infos.dart';
import 'package:irllink/src/domain/repositories/twitch_repository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:quiver/iterables.dart';

import '../entities/twitch_poll_dto.dart';
import '../entities/twitch_prediction_dto.dart';

class TwitchRepositoryImpl extends TwitchRepository {
  @override
  Future<DataState<TwitchCredentials>> getTwitchOauth(
      TwitchAuthParams params) async {
    try {
      final url = Uri.https(kTwitchAuthUrlBase, kTwitchAuthUrlPath, {
        'client_id': params.clientId,
        'redirect_uri': params.redirectUri,
        'response_type': params.responseType,
        'scope': params.scopes,
        'force_verify': params.forceVerify,
        'claims': params.claims
      });

      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme: kRedirectScheme,
        preferEphemeral: false,
      );

      final accessToken = Uri.parse(result).queryParameters['access_token'];
      final idToken = Uri.parse(result).queryParameters['id_token'];
      final refreshToken = Uri.parse(result).queryParameters['refresh_token'];
      final expiresIn = Uri.parse(result).queryParameters['expires_in'];

      dynamic tokenInfos = await this.validateToken(accessToken!);
      final String scopes = tokenInfos['scopes'].join(' ');

      Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken!);

      TwitchDecodedIdTokenDTO decodedIdToken = TwitchDecodedIdTokenDTO(
        preferredUsername: decodedToken['preferred_username'],
        profilePicture: decodedToken['picture'] ?? "",
      );

      TwitchUserDTO twitchUser = TwitchUserDTO(
        profileImageUrl: '',
        id: '',
        broadcasterType: '',
        login: '',
        description: '',
        viewCount: '',
        displayName: '',
      );

      await this
          .getTwitchUser(null, accessToken)
          .then((value) => twitchUser = value.data!);

      final twitchData = TwitchCredentialsDTO(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken!,
        expiresIn: expiresIn!,
        decodedIdToken: decodedIdToken,
        twitchUser: twitchUser,
        scopes: scopes,
      );

      //save the twitch credentials on the smartphone
      this.setTwitchOnLocal(twitchData);

      return DataSuccess(twitchData);
    } catch (e) {
      return DataFailed("Unable to retrieve Twitch Data from Auth");
    }
  }

  @override
  Future<DataState<TwitchCredentials>> refreshAccessToken(
    TwitchCredentials twitchData,
  ) async {
    Response response;
    var dio = Dio();
    try {
      response = await dio.get(
        'https://www.irllink.com/twitch/app/refresh-token',
        queryParameters: {'refresh_token': twitchData.refreshToken},
      );

      TwitchCredentials newTwitchData = TwitchCredentials(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        idToken: twitchData.idToken,
        decodedIdToken: twitchData.decodedIdToken,
        expiresIn: twitchData.expiresIn,
        twitchUser: twitchData.twitchUser,
        scopes: twitchData.scopes,
      );
      this.setTwitchOnLocal(newTwitchData);

      await this.validateToken(newTwitchData.accessToken);

      return DataSuccess(newTwitchData);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Refresh encountered issues");
    }
  }

  Future<dynamic> validateToken(String accessToken) async {
    try {
      Response response;
      var dio = Dio();
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get('https://id.twitch.tv/oauth2/validate');
      return response.data;
    } on DioError catch (e) {
      print(e.response);
      return "error";
    }
  }

  @override
  Future<DataState<String>> logout(String accessToken) async {
    final box = GetStorage();
    box.remove('twitchData');
    Response response;
    var dio = Dio();
    try {
      response = await dio.post(
        'https://id.twitch.tv/oauth2/revoke',
        queryParameters: {
          'client_id': kTwitchAuthClientId,
          'token': accessToken
        },
      );
      return DataSuccess(response.toString());
    } on DioError catch (e) {
      debugPrint(e.toString());
    }
    return DataSuccess('Logged out successfuly');
  }

  @override
  Future<DataState<TwitchCredentials>> getTwitchFromLocal() async {
    final box = GetStorage();
    var twitchDataString = box.read('twitchData');
    if (twitchDataString != null) {
      Map<String, dynamic> twitchDataJson = jsonDecode(twitchDataString);

      TwitchCredentials twitchData =
          TwitchCredentialsDTO.fromJson(twitchDataJson);

      TwitchAuthParams params = TwitchAuthParams();

      List paramsScopesList = params.scopes.split(' ');
      paramsScopesList.sort((a, b) {
        return a.compareTo(b);
      });
      String paramsScopesOrdered = paramsScopesList.join(' ');

      List savedScopesList = twitchData.scopes.split(' ');
      savedScopesList.sort((a, b) {
        return a.compareTo(b);
      });
      String savedScopesOrdered = savedScopesList.join(' ');

      if (savedScopesOrdered != paramsScopesOrdered) {
        return DataFailed("Scopes have been updated, please login again");
      }

      //refresh the access token to be sure the token is going to be valid after starting the app
      await this
          .refreshAccessToken(twitchData)
          .then((value) => twitchData = value.data!);

      return DataSuccess(twitchData);
    } else {
      return DataFailed("No Twitch Data in local storage");
    }
  }

  @override
  Future<void> setTwitchOnLocal(TwitchCredentials twitchData) async {
    final box = GetStorage();
    String jsonTwitchData = jsonEncode(twitchData);
    box.write('twitchData', jsonTwitchData);
  }

  @override
  Future<DataState<TwitchUserDTO>> getTwitchUser(
      String? username, String accessToken) async {
    Response response;
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";

      if (username != null) {
        response = await dio.get(
          'https://api.twitch.tv/helix/users',
          queryParameters: {'login': username},
        );
      } else {
        //if no username then it get the user linked to the accessToken
        response = await dio.get(
          'https://api.twitch.tv/helix/users',
        );
      }

      TwitchUserDTO twitchUser =
          TwitchUserDTO.fromJson(response.data['data'][0]);

      return DataSuccess(twitchUser);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving user infos");
    }
  }

  @override
  Future<DataState<List<TwitchUserDTO>>> getTwitchUsers(
      List ids, String accessToken) async {
    Response response;
    var dio = Dio();
    List<TwitchUserDTO> twitchUsers = <TwitchUserDTO>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";

      var chunks = partition(ids, 100);

      for (var chunk in chunks) {
        await Future.delayed(const Duration(seconds: 5), () async {
          response = await dio.get(
            'https://api.twitch.tv/helix/users',
            queryParameters: {'id': chunk},
          );

          response.data['data'].forEach(
            (user) => {
              twitchUsers.add(TwitchUserDTO.fromJson(user)),
            },
          );
        });
      }

      return DataSuccess(twitchUsers);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving users infos");
    }
  }

  @override
  Future<DataState<List<TwitchBadge>>> getTwitchGlobalBadges(
      String accessToken) async {
    Response response;
    var dio = Dio();
    List<TwitchBadge> badges = <TwitchBadge>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response =
          await dio.get('https://api.twitch.tv/helix/chat/badges/global');

      response.data['data'].forEach(
        (set) => set['versions'].forEach((version) =>
            badges.add(TwitchBadgeDTO.fromJson(set['set_id'], version))),
      );

      return DataSuccess(badges);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving Twitch global badges");
    }
  }

  @override
  Future<DataState<List<TwitchBadge>>> getTwitchChannelBadges(
      String accessToken, String broadcasterId) async {
    Response response;
    var dio = Dio();
    List<TwitchBadge> badges = <TwitchBadge>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
          'https://api.twitch.tv/helix/chat/badges?broadcaster_id=$broadcasterId');

      response.data['data'].forEach(
        (set) => set['versions'].forEach((version) =>
            badges.add(TwitchBadgeDTO.fromJson(set['set_id'], version))),
      );

      return DataSuccess(badges);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving Twitch broadcaster channel badges");
    }
  }

  @override
  Future<DataState<List<Emote>>> getTwitchEmotes(String accessToken) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response =
          await dio.get('https://api.twitch.tv/helix/chat/emotes/global');

      response.data['data'].forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJson(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving global emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getTwitchChannelEmotes(
    String accessToken,
    String broadcasterId,
  ) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
        'https://api.twitch.tv/helix/chat/emotes',
        queryParameters: {'broadcaster_id': broadcasterId},
      );

      response.data['data'].forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJson(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving channel emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getTwitchSetsEmotes(
    String accessToken,
    List<String> setId,
  ) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];

    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";

      var chunks = partition(setId, 25);

      for (var chunk in chunks) {
        await Future.delayed(const Duration(seconds: 5), () async {
          response = await dio.get(
            "https://api.twitch.tv/helix/chat/emotes/set",
            queryParameters: {'emote_set_id': chunk},
          );
          response.data['data'].forEach(
            (emote) => emotes.add(
              EmoteDTO.fromJson(emote),
            ),
          );
        });
      }

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving sets emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getTwitchCheerEmotes(
      String accessToken, String broadcasterId) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
        'https://api.twitch.tv/helix/bits/cheermotes',
        queryParameters: {'broadcaster_id': broadcasterId},
      );

      response.data['data'].forEach(
        (prefix) => prefix['tiers'].forEach(
          (emote) => emotes.add(
            EmoteDTO.fromJsonCheerEmotes(emote, prefix['prefix']),
          ),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving channel cheer emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getFrankerfacezEmotes(
      String broadcasterId) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      response = await dio.get(
        'https://api.frankerfacez.com/v1/room/id/$broadcasterId',
      );

      response.data['sets'][response.data['sets'].keys.toList()[0]]['emoticons']
          .forEach((emote) => {
                emotes.add(
                  EmoteDTO.fromJsonFrankerfacez(emote),
                ),
              });

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving FFZ global emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getBttvChannelEmotes(
      String broadcasterId) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      response = await dio.get(
        'https://api.betterttv.net/3/cached/users/twitch/$broadcasterId',
      );

      response.data['channelEmotes'].forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJsonBttv(emote),
        ),
      );

      response.data['sharedEmotes'].forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJsonBttv(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving FFZ channel emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> get7TvGlobalEmotes() async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      response = await dio.get(
        'https://api.7tv.app/v2/emotes/global',
      );

      response.data.forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJson7Tv(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving 7Tv global emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> get7TvChannelEmotes(
      String broadcasterId) async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      response = await dio.get(
        'https://api.7tv.app/v2/users/$broadcasterId/emotes',
      );

      response.data.forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJson7Tv(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving 7Tv channel emotes");
    }
  }

  @override
  Future<DataState<List<Emote>>> getBttvGlobalEmotes() async {
    Response response;
    var dio = Dio();
    List<Emote> emotes = <Emote>[];
    try {
      response = await dio.get(
        'https://api.betterttv.net/3/cached/emotes/global',
      );

      response.data.forEach(
        (emote) => emotes.add(
          EmoteDTO.fromJsonBttv(emote),
        ),
      );

      return DataSuccess(emotes);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error retrieving BTTV Global emotes");
    }
  }

  @override
  Future<DataState<TwitchStreamInfos>> getStreamInfo(
      String accessToken, String broadcasterId) async {
    Response response;
    Response response2;
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
        'https://api.twitch.tv/helix/channels',
        queryParameters: {'broadcaster_id': broadcasterId},
      );

      response2 = await dio.get(
        'https://api.twitch.tv/helix/streams',
        queryParameters: {'user_id': broadcasterId},
      );

      dynamic reponse3;
      await setChatSettings(accessToken, broadcasterId, null)
          .then((value) => reponse3 = value.data!.data);

      TwitchStreamInfosDto twitchStreamInfosDto = TwitchStreamInfosDto.fromJson(
          response.data['data'][0], response2.data, reponse3['data'][0]);

      return DataSuccess(twitchStreamInfosDto);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error Getting Stream Infos");
    }
  }

  @override
  Future<DataState<Response<dynamic>>> setChatSettings(String accessToken,
      String broadcasterId, TwitchStreamInfos? twitchStreamInfos) async {
    Response response;
    Map<String, bool> settings = {};
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";

      if (twitchStreamInfos != null) {
        settings = {
          'emote_mode': twitchStreamInfos.isEmoteMode!,
          'follower_mode': twitchStreamInfos.isFollowerMode!,
          'slow_mode': twitchStreamInfos.isSlowMode!,
          'subscriber_mode': twitchStreamInfos.isSubscriberMode!,
        };
      }

      response = await dio.patch('https://api.twitch.tv/helix/chat/settings',
          queryParameters: {
            'broadcaster_id': broadcasterId,
            'moderator_id': broadcasterId
          },
          data: jsonEncode(settings));

      return DataSuccess(response);
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error editing Stream chat settings");
    }
  }

  @override
  Future<DataState<void>> setStreamTitle(
      String accessToken, String broadcasterId, String title) async {
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      Map titleMap = {"title": title};
      await dio.patch('https://api.twitch.tv/helix/channels',
          queryParameters: {
            'broadcaster_id': broadcasterId,
            'moderator_id': broadcasterId
          },
          data: jsonEncode(titleMap));
      return DataSuccess("");
    } on DioError catch (e) {
      debugPrint(e.toString());
      return DataFailed("Error editing Stream chat settings");
    }
  }

  @override
  Future<DataState<TwitchPoll>> getPoll(
      String accessToken, String broadcasterId) async {
    Response response;
    var dio = Dio();
    TwitchPoll? poll;
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
          'https://api.twitch.tv/helix/polls?broadcaster_id=$broadcasterId');

      if (response.data['data'] == null || response.data['data'].isEmpty) {
        return DataFailed("There is no poll");
      } else {
        poll = TwitchPollDTO.fromJson(response.data['data'][0]);
        if (poll.status == PollStatus.ACTIVE ||
            poll.status == PollStatus.COMPLETED ||
            poll.status == PollStatus.TERMINATED) {
          return DataSuccess(poll);
        }
        return DataFailed("No poll to show");
      }
    } on DioError catch (e) {
      print(e.response);
      return DataFailed("Error retrieving Twitch Poll");
    }
  }

  @override
  Future<DataState<TwitchPoll>> endPoll(String accessToken,
      String broadcasterId, String pollId, String status) async {
    var dio = Dio();
    Response response;
    TwitchPoll? poll;

    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";

      Map body = {
        "broadcaster_id": broadcasterId,
        "id": pollId,
        "status": status
      };

      response = await dio.patch(
        'https://api.twitch.tv/helix/polls',
        data: jsonEncode(body),
      );

      poll = TwitchPollDTO.fromJson(response.data['data'][0]);

      return DataSuccess(poll);
    } on DioError catch (e) {
      print(e.response);
      return DataFailed("Error ending poll");
    }
  }

  @override
  Future<DataState<TwitchPrediction>> getPrediction(
      String accessToken, String broadcasterId) async {
    Response response;
    var dio = Dio();
    TwitchPrediction? prediction;
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      response = await dio.get(
          'https://api.twitch.tv/helix/predictions?broadcaster_id=$broadcasterId');

      if (response.data['data'] == null || response.data['data'].isEmpty) {
        return DataFailed("There is no prediction");
      } else {
        prediction = TwitchPredictionDTO.fromJson(response.data['data'][0]);
        if (prediction.status == PredictionStatus.RESOLVED ||
            prediction.status == PredictionStatus.ACTIVE ||
            prediction.status == PredictionStatus.LOCKED) {
          return DataSuccess(prediction);
        }
        return DataFailed("No prediction to show");
      }
    } on DioError catch (e) {
      print(e.response);
      return DataFailed("Error retrieving Twitch Prediction");
    }
  }

  @override
  Future<DataState<TwitchPoll>> createPoll(
      String accessToken, String broadcasterId, TwitchPoll newPoll) async {
    // Response response;
    var dio = Dio();
    // TwitchPrediction? prediction;
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      // response = await dio.post(
      //     'https://api.twitch.tv/helix/predictions?broadcaster_id=$broadcasterId');

      return DataSuccess(newPoll);
    } on DioError catch (e) {
      print(e.response);
      return DataFailed("Error retrieving Twitch Prediction");
    }
  }

  @override
  Future<void> banUser(
    String accessToken,
    String broadcasterId,
    TwitchChatMessage message,
    int? duration,
  ) async {
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      Map body = {
        "data": {
          "user_id": message.authorId,
        },
      };
      if (duration != null) {
        body['data']['duration'] = duration.toString();
      }

      await dio.post(
        'https://api.twitch.tv/helix/moderation/bans',
        queryParameters: {
          'broadcaster_id': broadcasterId,
          'moderator_id': broadcasterId,
        },
        data: jsonEncode(body),
      );
    } on DioError catch (e) {
      debugPrint(e.response.toString());
    }
  }

  @override
  Future<void> deleteMessage(
    String accessToken,
    String broadcasterId,
    TwitchChatMessage message,
  ) async {
    var dio = Dio();
    try {
      dio.options.headers['Client-Id'] = kTwitchAuthClientId;
      dio.options.headers["authorization"] = "Bearer $accessToken";
      await dio.delete(
        'https://api.twitch.tv/helix/moderation/chat',
        queryParameters: {
          'broadcaster_id': broadcasterId,
          'moderator_id': broadcasterId,
          'message_id': message.messageId,
        },
      );
    } on DioError catch (e) {
      debugPrint(e.response.toString());
    }
  }
}
