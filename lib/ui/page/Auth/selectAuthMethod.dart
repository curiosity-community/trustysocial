import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/ui/page/Auth/signup.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';
import '../homePage.dart';
import 'signin.dart';
import 'package:video_player/video_player.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late VideoPlayerController _controller;
  bool _isButtonTapped = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/welcome_video.mov')
      ..initialize().then((_) {
        if (mounted) {
          _controller.play();
          _controller.setLooping(true);
          setState(() {});
        }
      }).catchError((error) {
        print('Video loading error: $error');
        print('Error stack trace: ${StackTrace.current}');
        if (mounted) {
          setState(() {
            _videoError = true;
          });
        }
        // Video yüklenemediğinde analytics'e hata gönder
        // TODO: Implement analytics
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _submitButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isButtonTapped = true; // Button is pressed
        });
      },
      onTapUp: (_) {
        setState(() {
          _isButtonTapped = false; // Button is released
        });
        var state = Provider.of<AuthState>(context, listen: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Signup(loginCallback: state.getCurrentUser),
          ),
        );
      },
      onTapCancel: () {
        setState(() {
          _isButtonTapped = false; // Reset if the tap is canceled
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isButtonTapped
              ? const LinearGradient(
                  colors: [Colors.orangeAccent, Colors.pinkAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (_isButtonTapped ? Colors.pinkAccent : Colors.blueAccent)
                  .withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              height: 100,
              child: Image.asset('assets/images/icon-480.png'),
            ),
            const TitleText(
              'Thirsty to Trust.',
              textAlign: TextAlign.center,
              fontSize: 25,
              color: Colors.white,
            ),
            const Spacer(),
            const TitleText(
              'See what\'s happening in the world right now.',
              fontSize: 25,
              color: Colors.white,
            ),
            const SizedBox(
              height: 10,
            ),
            _submitButton(),
            const Spacer(),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const TitleText(
                  'Have an account already?',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                InkWell(
                  onTap: () {
                    var state = Provider.of<AuthState>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignIn(loginCallback: state.getCurrentUser),
                      ),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: TitleText(
                      'Click Here to Log in',
                      fontSize: 14,
                      color: TwitterColor.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 60)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AuthState>(context, listen: false);
    return Scaffold(
      body: state.authStatus == AuthStatus.NOT_LOGGED_IN ||
              state.authStatus == AuthStatus.NOT_DETERMINED
          ? Stack(
              children: [
                SizedBox.expand(
                  child: !_videoError && _controller.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : Image.asset(
                          'assets/images/signup_background.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
                _body(),
              ],
            )
          : const HomePage(),
    );
  }
}
