import 'package:flutter/material.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/newWidget/customCheckBox.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';

class SettingRowWidget extends StatelessWidget {
  const SettingRowWidget(
    this.title, {
    Key? key,
    this.navigateTo,
    this.subtitle,
    this.textColor = Colors.black,
    this.onPressed,
    this.vPadding = 0,
    this.showDivider = true,
    this.visibleSwitch,
    this.enabled = true,
    this.showCheckBox,
  }) : super(key: key);
  final bool showDivider;
  final bool? showCheckBox, visibleSwitch;
  final bool enabled;
  final String? navigateTo;
  final String? subtitle, title;
  final Color textColor;
  final Function? onPressed;
  final double vPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
            contentPadding:
                EdgeInsets.symmetric(vertical: vPadding, horizontal: 18),
            onTap: () {
              if (onPressed != null) {
                onPressed!();
                return;
              }
              if (navigateTo == null) {
                return;
              }
              Navigator.pushNamed(context, '/$navigateTo');
            },
            title: title == null
                ? null
                : UrlText(
                    text: title ?? '',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium!.color),
                  ),
            subtitle: subtitle == null
                ? null
                : UrlText(
                    text: subtitle!,
                    style: TextStyle(
                        color: TwitterColor.paleSky,
                        fontWeight: FontWeight.w400),
                  ),
            trailing: CustomCheckBox(
              isChecked: showCheckBox,
              visibleSwitch: visibleSwitch,
              enabled: enabled,
            )),
        //!showDivider ? const SizedBox() : const Divider(),
      ],
    );
  }
}
