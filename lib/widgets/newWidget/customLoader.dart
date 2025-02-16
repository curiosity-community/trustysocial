import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader {
  static CustomLoader? _customLoader;

  CustomLoader._createObject();

  factory CustomLoader() {
    if (_customLoader != null) {
      return _customLoader!;
    } else {
      _customLoader = CustomLoader._createObject();
      return _customLoader!;
    }
  }

  OverlayState? _overlayState;
  OverlayEntry? _overlayEntry;

  _buildLoader() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: buildLoader(context));
      },
    );
  }

  showLoader(context) {
    _overlayState = Overlay.of(context);
    _buildLoader();
    _overlayState!.insert(_overlayEntry!);
  }

  hideLoader() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } catch (e) {
      print("Exception:: $e");
    }
  }

  buildLoader(BuildContext context, {Color? backgroundColor}) {
    backgroundColor ??= Theme.of(context).scaffoldBackgroundColor;
    var height = 150.0;
    return CustomScreenLoader(
      height: height,
      width: height,
      backgroundColor: backgroundColor,
    );
  }
}

class CustomScreenLoader extends StatelessWidget {
  final Color backgroundColor;
  final double height;
  final double width;
  const CustomScreenLoader(
      {Key? key,
      this.backgroundColor = const Color(0xfff8f8f8),
      this.height = 30,
      this.width = 30})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        height: height,
        width: height,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(50),
          decoration: const BoxDecoration(
              //color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Lottie.asset(
                'assets/animations/loading.json', // Path to your Lottie animation file
                height: 300, // Adjust height as needed
                width: 300, // Adjust width as needed
              ),
              Image.asset(
                'assets/images/trusty-icon.png',
                height: 30,
                width: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}
