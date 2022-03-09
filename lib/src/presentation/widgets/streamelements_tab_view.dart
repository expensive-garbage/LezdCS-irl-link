import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:irllink/src/domain/entities/se_activity.dart';
import 'package:irllink/src/domain/entities/se_song.dart';
import 'package:irllink/src/presentation/controllers/streamelements_view_controller.dart';

class StreamelementsTabView extends GetView<StreamelementsViewController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.theme.primaryColor,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TabBar(
              controller: controller.tabController,
              isScrollable: true,
              labelColor: Colors.purple,
              unselectedLabelColor: context.theme.textTheme.bodyText1!.color,
              indicatorColor: Colors.purple,
              indicatorWeight: 0.000001,
              tabs: [Text("Notifications"), Text("Song Requests")],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: context.theme.primaryColor,
        ),
        child: TabBarView(
          controller: controller.tabController,
          children: [
            _activities(),
            _songRequests(context),
          ],
        ),
      ),
    );
  }

  Widget _activities() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _activitiesSettings(),
              Wrap(
                children: [
                  Icon(Icons.pause),
                  Icon(Icons.play_arrow_outlined),
                  Icon(Icons.notifications_on_outlined),
                  Icon(Icons.restart_alt),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              controller: controller.activitiesScrollController,
              itemCount: controller.activities.length,
              itemBuilder: (BuildContext context, int index) {
                SeActivity activity = controller
                    .activities[controller.activities.length - 1 - index];
                return Container(
                  padding:
                      EdgeInsets.only(left: 3, right: 3, top: 5, bottom: 5),
                  decoration: BoxDecoration(
                    color: activity.colorsForEnum()[0],
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                  margin: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 8, right: 8),
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: activity.colorsForEnum()[1],
                              shape: BoxShape.circle,
                            ),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: activity.username,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: activity.textFromEnum()),
                            ]),
                          ),
                        ],
                      ),
                      Icon(Icons.restart_alt),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _songRequests(BuildContext context) {
    return Obx(
      () => Container(
        margin: EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  children: [
                    Icon(Icons.skip_previous),
                    Icon(Icons.pause), //Icon(Icons.play_arrow_outlined),
                    InkWell(
                      onTap: () {
                        controller.nextSong();
                      },
                      child: Icon(Icons.skip_next),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    controller.resetQueue();
                  },
                  child: Icon(Icons.delete),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
            ),
            Text(
              'Now Playing',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
            ),
            controller.songRequestQueue.length > 0
                ? RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: controller.songRequestQueue.first.channel,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: " - ",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          ),
                        ),
                        TextSpan(
                          text: controller.songRequestQueue.first.title,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          ),
                        )
                      ],
                    ),
                  )
                : Text("No song request in queue."),
            Padding(
              padding: EdgeInsets.only(bottom: 15),
            ),
            RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(children: [
                TextSpan(
                  text: "Queue ",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
                TextSpan(
                  text: "(" +
                      controller.songRequestQueue.length.toString() +
                      " videos)",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                controller: controller.songRequestScrollController,
                itemCount: controller.songRequestQueue.length,
                itemBuilder: (BuildContext context, int index) {
                  SeSong song = controller.songRequestQueue[index];
                  return Container(
                    padding:
                        EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    margin: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: song.channel,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: " - "),
                                    TextSpan(
                                      text: song.title,
                                    )
                                  ],
                                ),
                              ),
                              RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(children: [
                                  TextSpan(text: "Duration: "),
                                  //todo : display duration in minutes format. ex: 123 -> 2:03
                                  TextSpan(
                                    text: song.duration,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            controller.removeSong(song);
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activitiesSettings() {
    return PopupMenuButton(
      offset: Offset(30, 30),
      child: Icon(Icons.settings),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Followers',
            ),
            value: true,
            onChanged: (bool? value) {},
          ),
        ),
        PopupMenuItem(
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Subscribers',
            ),
            value: true,
            onChanged: (bool? value) {},
          ),
        ),
        PopupMenuItem(
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Donations',
            ),
            value: true,
            onChanged: (bool? value) {},
          ),
        ),
        PopupMenuItem(
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Bits',
            ),
            value: true,
            onChanged: (bool? value) {},
          ),
        ),
        PopupMenuItem(
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Raids',
            ),
            value: true,
            onChanged: (bool? value) {},
          ),
        ),
      ],
    );
  }
}
