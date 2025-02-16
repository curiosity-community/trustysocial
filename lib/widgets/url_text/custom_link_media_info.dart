import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/shared_prefrence_helper.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/link_media_info.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/url_text/link_preview.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:Trusty/widgets/youtube_player_dialog.dart';

class CustomLinkMediaInfo extends StatelessWidget {
  const CustomLinkMediaInfo({Key? key, this.url, this.text}) : super(key: key);
  final String? url;
  final String? text;

  String? getUrl() {
    if (text == null) {
      return null;
    }
    RegExp reg = RegExp(
        r"(https?|http)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]*");
    Iterable<Match> _matches = reg.allMatches(text!);
    if (_matches.isNotEmpty) {
      return _matches.first.group(0);
    }
    return null;
  }

  Future<Either<Exception, LinkMediaInfo>> fetchLinkMediaInfoFromApi(
      String url) async {
    try {
      // Encode the URL before making the request
      final encodedUrl = Uri.encodeComponent(url);
      var response = await http.Client()
          .get(Uri.parse("https://noembed.com/embed?url=$encodedUrl"))
          .then((result) => result.body)
          .then(json.decode);

      // Check if response is error or empty before parsing
      if (response == null || response is String || response['error'] != null) {
        return Left(Exception('Invalid response'));
      }

      return Right(LinkMediaInfo.fromJson(response));
    } catch (error) {
      print("Link preview error: $error");
      return Left(Exception('Failed to fetch preview'));
    }
  }

  Future<Either<String, LinkMediaInfo>> fetchLinkMediaInfo(String url) async {
    final pref = SharedPreferenceHelper();
    var map = await pref.getLinkMediaInfo(url);

    /// If url metadata is not available in local storage
    /// then fetch url from api
    if (map == null) {
      var response = await fetchLinkMediaInfoFromApi(url);

      return response.fold((l) => const Left("Not found"), (r) async {
        await pref.saveLinkMediaInfo(url, r);
        return Right(r);
      });
    }

    /// If meta is available in local storage then no need to call api
    else {
      if (map.title == null) {
        return const Left("Not found");
      }
      return Right(map);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    try {
      var uri = url ?? getUrl();
      debugPrint('Processing URL: $uri');
      if (uri == null) {
        return const SizedBox();
      }
      // Log before firebase operations
      debugPrint('About to handle URL preview: $uri');

      /// Only Youtube thumbnail is displayed in `CustomLinkMediaInfo` widget
      /// Other url preview is displayed on `LinkPreview` widget.
      /// `LinkPreview` uses [flutter_link_preview] package to fetch url metadata.
      /// It is seen that `flutter_link_preview` package is unable to fetch youtube metadata
      if (uri.contains("youtu")) {
        String? videoId;
        if (uri.contains("youtube.com")) {
          videoId = Uri.parse(uri).queryParameters['v'];
        } else if (uri.contains("youtu.be")) {
          videoId = uri.split('/').last;
        }
        if (videoId != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://img.youtube.com/vi/$videoId/0.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.play_circle_fill,
                      size: 50, color: Colors.white.withOpacity(0.8)),
                ),
              ).ripple(() {
                showDialog(
                  context: context,
                  builder: (_) => YoutubePlayerDialog(videoId: videoId!),
                );
              }),
            ],
          );
        }
      }
      return LinkPreviewer(url: uri);
    } catch (e, stack) {
      debugPrint('Error in CustomLinkMediaInfo: $e');
      debugPrint('Stack trace: $stack');
      return const SizedBox(); // Fail gracefully
    }
  }
}
