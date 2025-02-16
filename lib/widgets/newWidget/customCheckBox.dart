import 'package:flutter/material.dart';

class CustomCheckBox extends StatefulWidget {
  final bool? isChecked;
  final bool? visibleSwitch;
  final bool enabled;
  const CustomCheckBox({
    Key? key,
    this.isChecked,
    this.visibleSwitch,
    this.enabled = true,
  }) : super(key: key);

  @override
  _CustomCheckBoxState createState() => _CustomCheckBoxState();
}

class _CustomCheckBoxState extends State<CustomCheckBox> {
  ValueNotifier<bool> isChecked = ValueNotifier(false);
  ValueNotifier<bool> visibleSwitch = ValueNotifier(false);
  @override
  void initState() {
    isChecked.value = widget.isChecked ?? false;
    visibleSwitch.value = widget.visibleSwitch ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isChecked != null
        ? ValueListenableBuilder<bool>(
            valueListenable: isChecked,
            builder: (context, value, child) {
              return Checkbox(
                value: value,
                onChanged: widget.enabled
                    ? (val) {
                        isChecked.value = val!;
                      }
                    : null, // Will disable the checkbox when enabled is false
              );
            },
          )
        : widget.visibleSwitch == null
            ? const SizedBox(
                height: 10,
                width: 10,
              )
            : ValueListenableBuilder(
                valueListenable: visibleSwitch,
                builder: (context, bool value, child) {
                  return Switch(
                    onChanged: widget.enabled
                        ? (val) {
                            visibleSwitch.value = val;
                          }
                        : null, // Will disable the switch when enabled is false
                    value: value,
                  );
                },
              );
  }
}
