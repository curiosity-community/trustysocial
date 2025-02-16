import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerDialog extends StatefulWidget {
  final String videoId;
  const YoutubePlayerDialog({Key? key, required this.videoId})
      : super(key: key);

  @override
  State<YoutubePlayerDialog> createState() => _YoutubePlayerDialogState();
}

class _YoutubePlayerDialogState extends State<YoutubePlayerDialog> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
        enableCaption: false,
        hideThumbnail: true,
      ),
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          left: false,
          right: false,
          child: Stack(
            children: [
              Center(
                child: YoutubePlayerBuilder(
                  onEnterFullScreen: () {
                    if (!_isFullScreen) _toggleFullScreen();
                  },
                  onExitFullScreen: () {
                    if (_isFullScreen) _toggleFullScreen();
                  },
                  player: YoutubePlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    showVideoProgressIndicator: true,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.red,
                    ),
                    bottomActions: [
                      CurrentPosition(),
                      const SizedBox(width: 10),
                      ProgressBar(isExpanded: true),
                      const SizedBox(width: 10),
                      RemainingDuration(),
                      FullScreenButton(),
                    ],
                  ),
                  builder: (context, player) => FittedBox(
                    fit: BoxFit.contain,
                    child: player,
                  ),
                ),
              ),
              if (!_isFullScreen)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
