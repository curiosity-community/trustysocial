import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:image_picker/image_picker.dart';

class ComposeBottomIconWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Function(File) onImageIconSelected;
  const ComposeBottomIconWidget(
      {Key? key,
      required this.textEditingController,
      required this.onImageIconSelected})
      : super(key: key);

  @override
  _ComposeBottomIconWidgetState createState() =>
      _ComposeBottomIconWidgetState();
}

class _ComposeBottomIconWidgetState extends State<ComposeBottomIconWidget> {
  bool reachToWarning = false;
  bool reachToOver = false;
  late Color wordCountColor;
  String tweet = '';

  @override
  void initState() {
    wordCountColor = Colors.blue;
    widget.textEditingController.addListener(updateUI);
    super.initState();
  }

  void updateUI() {
    setState(() {
      tweet = widget.textEditingController.text;
      if (widget.textEditingController.text.isNotEmpty) {
        if (widget.textEditingController.text.length > 259 &&
            widget.textEditingController.text.length < 280) {
          wordCountColor = Colors.orange;
        } else if (widget.textEditingController.text.length >= 280) {
          wordCountColor = Theme.of(context).colorScheme.error;
        } else {
          wordCountColor = Colors.blue;
        }
      }
    });
  }

  Widget _bottomIconWidget() {
    return Container(
      width: double.infinity,
      height: 95,
      decoration: BoxDecoration(
        //border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          IconButton(
              onPressed: () {
                setImage(ImageSource.gallery);
              },
              icon: customIcon(context,
                  icon: AppIcon.image,
                  isTwitterIcon: true,
                  iconColor: AppColor.primary)),
          IconButton(
              onPressed: () {
                setImage(ImageSource.camera);
              },
              icon: customIcon(context,
                  icon: AppIcon.camera,
                  isTwitterIcon: true,
                  iconColor: AppColor.primary)),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 30),
                child: /*tweet != null &&*/ tweet.length > 289
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: customText(
                          '${280 - tweet.length}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            value: getTweetLimit(),
                            backgroundColor: Colors.grey,
                            valueColor:
                              AlwaysStoppedAnimation<Color>(wordCountColor),
                              strokeWidth: 4
                          ),
                          tweet.length > 259
                              ? customText('${280 - tweet.length}',
                                  style: TextStyle(color: wordCountColor, fontSize: 14))
                              : customText('',
                                  style: TextStyle(color: wordCountColor))
                        ],
                      )),
          ))
        ],
      ),
    );
  }

  void setImage(ImageSource source) {
    ImagePicker()
        .pickImage(source: source, imageQuality: 20)
        .then((XFile? file) {
      setState(() {
        // _image = file;
        widget.onImageIconSelected(File(file!.path));
      });
    });
  }

  double getTweetLimit() {
    if (tweet.isEmpty) {
      return 0.0;
    }
    if (tweet.length > 280) {
      return 1.0;
    }
    var length = tweet.length;
    var val = length * 100 / 28000.0;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _bottomIconWidget(),
    );
  }
}
