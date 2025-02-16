import 'package:flutter/material.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var state = Provider.of<AuthState>(context, listen: false);

    // Ensure userModel is used here
    if (state.userModel != null &&
        state.userModel!.hasChangedUsername == false) {
      _usernameController.text = state.userModel!.userName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    var state = Provider.of<AuthState>(context);

    if (state.userModel == null) {
      return const Center(
        child: NotifyText(
          title: 'Error',
          subTitle: 'Unable to load user data. Please try again.',
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: !state.userModel!.hasChangedUsername!
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const NotifyText(
                  title: 'Change your username',
                  subTitle:
                      'You can update your username only once. Make sure it\'s what you want.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    // Automatically add '@' if it's not already there
                    if (!value.startsWith('@')) {
                      _usernameController.text =
                          '@' + value.replaceAll(RegExp(r'[^a-zA-Z]'), '');
                      _usernameController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _usernameController.text.length),
                      );
                    }

                    // Show a warning if there are invalid characters
                    if (!RegExp(r'^@[a-zA-Z]*$').hasMatch(value)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Only allowed: Latin characters, no spaces')),
                      );
                      // Remove invalid characters
                      _usernameController.text = '@' +
                          _usernameController.text
                              .substring(1)
                              .replaceAll(RegExp(r'[^a-zA-Z]'), '');
                      _usernameController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _usernameController.text.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                _submitButton(context),
              ],
            )
          : const Center(
              child: NotifyText(
                title: 'Username Change Unavailable',
                subTitle:
                    'You have already changed your username once and cannot change it again.',
              ),
            ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: Wrap(
        children: <Widget>[
          MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: Colors.blueAccent,
            onPressed: _submit,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: const TitleText(
              'Update Username',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    var state = Provider.of<AuthState>(context, listen: false);

    // Ensure the username starts with an '@'
    if (!_usernameController.text.startsWith('@')) {
      _usernameController.text = '@' + _usernameController.text;
    }

    if (_usernameController.text.isNotEmpty) {
      // Check if the username contains only valid characters after '@'
      if (!RegExp(r'^@[a-zA-Z]+$').hasMatch(_usernameController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Only allowed: Latin characters, no spaces, and must start with @')),
        );
        return;
      }

      // Check if the user has already changed their username
      if (state.userModel != null && !state.userModel!.hasChangedUsername!) {
        // Check if the new username is already taken
        bool isUsernameTaken =
            await state.isUsernameTaken(_usernameController.text);
        if (isUsernameTaken) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username is already taken')),
          );
          return;
        }

        // Update the username and set hasChangedUsername to true
        state.updateUsername(_usernameController.text).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username updated successfully')),
          );
          setState(() {}); // Rebuild to show the updated state
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update username: $error')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can only change your username once')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid username')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        title: customText(
          'Change Username',
          context: context,
          style: const TextStyle(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _body(context),
    );
  }
}
