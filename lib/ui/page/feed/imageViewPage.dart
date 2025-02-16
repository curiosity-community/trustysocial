import 'dart:ui';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/constant.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/widgets/cache_image.dart';
import 'package:Trusty/widgets/tweet/widgets/tweetIconsRow.dart';
import 'package:provider/provider.dart';

const kBackgroundBlack = Color(0xFF121212);

class ImageViewPge extends StatefulWidget {
  const ImageViewPge({Key? key}) : super(key: key);

  @override
  _ImageViewPgeState createState() => _ImageViewPgeState();
}

class _ImageViewPgeState extends State<ImageViewPge> {
  bool isToolAvailable = true;
  double _offset = 0;
  double _opacity = 1;

  late FocusNode _focusNode;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    super.initState();
  }

  Widget _body() {
    var state = Provider.of<FeedState>(context);

    if (state.tweetDetailModel.isEmpty ||
        state.tweetDetailModel.last.imagePath == null) {
      return const Center(
        child:
            Text('No image available', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Container(
            color: kBackgroundBlack
                .withOpacity(0.9), // Add semi-transparent background
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                // Add blur background image
                if (state.tweetDetailModel.isNotEmpty &&
                    state.tweetDetailModel.last.imagePath != null)
                  Positioned.fill(
                    child: CacheImage(
                      path: state.tweetDetailModel.last.imagePath!,
                      fit: BoxFit.cover,
                    ),
                  ),
                // Add blur effect
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: kBackgroundBlack.withOpacity(0.7),
                    ),
                  ),
                ),
                // Main image
                Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isToolAvailable = !isToolAvailable;
                      });
                    },
                    child: _imageFeed(state.tweetDetailModel.last.imagePath),
                  ),
                ),
              ],
            ),
          ),
        ),
        !isToolAvailable
            ? Container()
            : Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Wrap(
                        children: const <Widget>[
                          BackButton(
                            color: Colors.white,
                          ),
                        ],
                      )),
                )),
        !isToolAvailable
            ? Container()
            : Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TweetIconsRow(
                      model: state.tweetDetailModel!.last,
                      iconColor: Theme.of(context).colorScheme.onPrimary,
                      iconEnableColor: Theme.of(context).colorScheme.onPrimary,
                      scaffoldKey: GlobalKey<ScaffoldState>(),
                    ),
                    Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(
                          right: 10, left: 10, bottom: 30),
                      child: TextField(
                        controller: _textEditingController,
                        maxLines: null,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          fillColor: Colors.transparent,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(30.0),
                            ),
                            borderSide: BorderSide(
                              color: Colors.white,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(30.0),
                            ),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _submitButton();
                            },
                            icon: Icon(Icons.send,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          focusColor: Colors.black,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          hintText: 'Comment here..',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _imageFeed(String? _image) {
    return _image == null || _image.isEmpty
        ? const Center(
            child: Text(
              'No image available',
              style: TextStyle(color: Colors.white),
            ),
          )
        : Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 1,
              maxHeight: MediaQuery.of(context).size.height * 1,
            ),
            child: InteractiveViewer(
              child: CacheImage(
                path: _image,
                fit: BoxFit.contain,
              ),
            ),
          );
  }

  void _submitButton() {
    if (_textEditingController.text.isEmpty) {
      return;
    }
    if (_textEditingController.text.length > 280) {
      return;
    }
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    var user = authState.userModel;
    var profilePic = user!.profilePic;
    profilePic ??= Constants.dummyProfilePic;
    var name = authState.userModel!.displayName ??
        authState.userModel!.email!.split('@')[0];
    var pic = authState.userModel!.profilePic ?? Constants.dummyProfilePic;
    var tags = Utility.getHashTags(_textEditingController.text);

    UserModel commentedUser = UserModel(
        displayName: name,
        userName: authState.userModel!.userName,
        isVerified: authState.userModel!.isVerified,
        profilePic: pic,
        userId: authState.userId);

    var postId = state.tweetDetailModel!.last.key;

    FeedModel reply = FeedModel(
      description: _textEditingController.text,
      user: commentedUser,
      createdAt: DateTime.now().toUtc().toString(),
      tags: tags,
      userId: commentedUser.userId!,
      parentkey: postId,
    );
    state.addCommentToPost(reply);
    FocusScope.of(context).requestFocus(_focusNode);
    setState(() {
      _textEditingController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(_opacity.clamp(0, 1)),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Changed to horizontal
          setState(() {
            _offset += details.primaryDelta!;
            _offset = _offset.clamp(0, 400);
            _opacity = (400 - _offset) / 400;
          });
        },
        onHorizontalDragEnd: (details) {
          // Changed to horizontal
          if (_offset > 100) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _offset = 0;
              _opacity = 1;
            });
          }
        },
        child: Transform.translate(
          offset: Offset(_offset, 0), // Changed to X offset instead of Y
          child: Opacity(
            opacity: _opacity.clamp(0, 1),
            child: _body(),
          ),
        ),
      ),
    );
  }
}
