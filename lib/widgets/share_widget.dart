import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_dynamic_links_platform_interface/src/social_meta_tag_parameters.dart';

class ShareWidget extends StatefulWidget {
  const ShareWidget(
      {Key? key,
      required this.child,
      required this.socialMetaTagParameters,
      required this.id})
      : super(key: key);

  final SocialMetaTagParameters socialMetaTagParameters;
  final String id;
  static MaterialPageRoute getRoute(
      {required Widget child,
      required SocialMetaTagParameters socialMetaTagParameters,
      required String id}) {
    return MaterialPageRoute(
      builder: (_) => ShareWidget(
          child: child,
          id: id,
          socialMetaTagParameters: socialMetaTagParameters),
    );
  }

  final Widget child;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<ShareWidget> {
  final GlobalKey _globalKey = GlobalKey();
  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }

  Future<void> _capturePng() async {
    try {
      isLoading.value = true;

      // Ensure widget is rendered
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture the widget as an image
      final boundary = _globalKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to capture image');
      }

      // Get proper directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          "tweet_share_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File('${directory.path}/$fileName');

      // Write image to file
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Create share message without dynamic link
      final message = "*${widget.socialMetaTagParameters.title}*\n"
          "${widget.socialMetaTagParameters.description ?? ''}\n"
          "Shared from Trusty App";

      // Share file and text
      await Utility.shareFile([file.path], text: message);
    } catch (e) {
      print('Error sharing tweet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share. Please try again.')));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).textTheme.bodyLarge?.color,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Share'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: MediaQuery.of(context).size.width,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: AbsorbPointer(
                  child: widget.child,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, child) {
                  return CustomFlatButton(
                    label: loading ? "Preparing..." : "Share",
                    onPressed: loading ? null : _capturePng,
                    isLoading: isLoading,
                    labelStyle: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
