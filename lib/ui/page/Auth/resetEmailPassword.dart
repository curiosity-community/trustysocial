import 'package:flutter/material.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var state = Provider.of<AuthState>(context, listen: false);
    // Autofill with the current email if available
    _emailController.text = state.user?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const NotifyText(
            title: 'Reset your password',
            subTitle:
                'Enter your email address to receive a password reset link.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _submitButton(context),
        ],
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
              'Send Reset Link',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    var state = Provider.of<AuthState>(context, listen: false);
    if (_emailController.text.isNotEmpty) {
      state.sendPasswordResetEmail(_emailController.text, context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
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
          'Reset Password',
          context: context,
          style: const TextStyle(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _body(context),
    );
  }
}
