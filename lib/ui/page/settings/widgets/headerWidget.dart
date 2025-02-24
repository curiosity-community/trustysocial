import 'package:flutter/material.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';

class HeaderWidget extends StatelessWidget {
  final String? title;
  final bool secondHeader;
  const HeaderWidget(this.title, {Key? key, this.secondHeader = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: secondHeader
          ? const EdgeInsets.only(left: 18, right: 18, bottom: 10, top: 15)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceDim,
      alignment: Alignment.centerLeft,
      child: UrlText(
        text: title ?? '',
        style: const TextStyle(
            fontSize: 20,
            color: AppColor.darkGrey,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
