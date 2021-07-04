import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:blackhole/APIs/api.dart';

bool fetched = false;
List preferredLanguage =
    Hive.box('settings').get('preferredLanguage') ?? ['Hindi'];
Map data = Hive.box('cache').get('homepage', defaultValue: {});
final lists = [
  "recent",
  "new_trending",
  "charts",
  "new_albums",
  "top_playlists",
  // "city_mod",
  // "artist_recos"
];

class SaavnHomePage extends StatefulWidget {
  @override
  _SaavnHomePageState createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage> {
  List recentList = Hive.box('recentlyPlayed').get('recentSongs') ?? [];

  getHomePageData() async {
    Map recievedData = await SaavnAPI().fetchHomePageData();
    if (recievedData != null || recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
    }
    setState(() {});
  }

  getSubTitle(Map item) {
    final type = item['type'];
    if (type == 'playlist') {
      return item['subtitle'] ?? '';
    } else if (type == 'radio_station') {
      return "Artist Radio";
    } else if (type == "song") {
      return item["artist"];
    } else {
      final artists = item['more_info']['artistMap']['artists']
          .map((artist) => artist['name'])
          .toList();
      return artists.join(', ');
    }
  }

  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  String formatString(String text) {
    return text
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"")
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (!fetched) {
      getHomePageData();
      fetched = true;
    }
    return ListView.builder(
        physics: BouncingScrollPhysics(), //NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        scrollDirection: Axis.vertical,
        itemCount: data.isEmpty ? 1 : lists.length,
        itemBuilder: (context, idx) {
          if (idx == 0) {
            return (recentList.isEmpty ||
                    !Hive.box('settings').get('showRecent', defaultValue: true))
                ? SizedBox()
                : Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                            child: Text(
                              'Last Session',
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          itemCount: recentList.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              child: SizedBox(
                                width: 150,
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        errorWidget: (context, _, __) => Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        imageUrl: recentList[index]["image"]
                                            .replaceAll('http:', 'https:'),
                                        placeholder: (context, url) => Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${recentList[index]["title"]}',
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${recentList[index]["artist"]}',
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .textTheme
                                              .caption
                                              .color),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => PlayScreen(
                                      data: {
                                        'response': recentList,
                                        'index': index,
                                        'offline': false,
                                      },
                                      fromMiniplayer: false,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
          }
          return Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                    child: Text(
                      '${capitalize(formatString(data['modules'][lists[idx]]["title"]))}',
                      style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              data[lists[idx]] == null
                  ? SizedBox(
                      height: 200,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 150,
                            child: Column(
                              children: [
                                Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image(
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                ),
                                Text(
                                  'Loading ...',
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  // style: TextStyle(
                                  //     color: Theme.of(context).accentColor),
                                ),
                                Text(
                                  'Please Wait',
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption
                                          .color),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        itemCount: data[lists[idx]].length,
                        itemBuilder: (context, index) {
                          final item = data[lists[idx]][index];
                          return GestureDetector(
                            // TODO: don't draw for radio station
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                children: [
                                  Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      errorWidget: (context, _, __) => Image(
                                        image: AssetImage('assets/cover.jpg'),
                                      ),
                                      imageUrl: item["image"]
                                          .replaceAll('http:', 'https:'),
                                      placeholder: (context, url) => Image(
                                        image: (item["type"] == 'playlist' ||
                                                item["type"] == 'album')
                                            ? AssetImage('assets/album.png')
                                            : item["type"] == 'artist'
                                                ? AssetImage(
                                                    'assets/artist.png')
                                                : AssetImage(
                                                    'assets/cover.jpg'),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${capitalize(formatString(item["title"]))}',
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    // maxLines: 2,
                                    // style: TextStyle(
                                    //     color: Theme.of(context).accentColor),
                                  ),
                                  lists[idx] != 'charts'
                                      ? Text(
                                          capitalize(
                                              formatString(getSubTitle(item))),
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .color),
                                        )
                                      : SizedBox(),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) =>
                                      item["type"] == "song"
                                          ? PlayScreen(
                                              data: {
                                                'response': [item],
                                                'index': 0,
                                                'offline': false,
                                              },
                                              fromMiniplayer: false,
                                            )
                                          : SongsListPage(
                                              listItem: item,
                                            ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ],
          );
        });
  }
}
