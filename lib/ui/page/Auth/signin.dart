import 'package:flutter/material.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/Auth/widget/googleLoginButton.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/customLoader.dart';
import 'package:provider/provider.dart';

class SignIn extends StatefulWidget {
  final VoidCallback? loginCallback;

  const SignIn({Key? key, this.loginCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late CustomLoader loader;
  bool _isTapped = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    loader = CustomLoader();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double availableHeight = screenHeight - keyboardHeight;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                height: keyboardHeight > 0
                    ? availableHeight * 0.35
                    : availableHeight * 0.35),
            _entryField('Enter email', controller: _emailController),
            _entryField('Enter password',
                controller: _passwordController, isPassword: true),
            _emailLoginButton(context),
            const SizedBox(height: 20),
            _labelButton('Forget password?', onPressed: () {
              Navigator.of(context).pushNamed('/ForgetPasswordPage');
            }),
            // const Divider(
            //   height: 30,
            // ),
            // const SizedBox(
            //   height: 30,
            // ),
            // GoogleLoginButton(
            //   loginCallback: widget.loginCallback!,
            //   loader: loader,
            // ),
            SizedBox(height: keyboardHeight > 0 ? 20 : availableHeight * 0.2),
          ],
        ),
      ),
    );
  }

  Widget _entryField(String hint,
      {required TextEditingController controller,
      bool isPassword = false,
      bool isEmail = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(
          color: Colors.black,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
        ),
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: isEmail
              ? const Icon(Icons.email, color: Colors.black)
              : isPassword
                  ? const Icon(Icons.lock, color: Colors.black)
                  : const Icon(Icons.person, color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _labelButton(String title, {Function? onPressed}) {
    return TextButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        }
      },
      child: Text(
        title,
        style: TextStyle(
            color: TwitterColor.dodgeBlue, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emailLoginButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true; // Button is pressed
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false; // Button is released
        });
        _emailLogin(); // Perform the login action
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false; // Reset if the tap is canceled
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 35),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isTapped
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
              color: (_isTapped ? Colors.orangeAccent : Colors.blueAccent)
                  .withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Submit',
            style: const TextStyle(
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

  void _emailLogin() {
    var state = Provider.of<AuthState>(context, listen: false);
    if (state.isbusy) {
      return;
    }
    loader.showLoader(context);
    var isValid = Utility.validateCredentials(
        context, _emailController.text, _passwordController.text);
    if (isValid) {
      state
          .signIn(_emailController.text, _passwordController.text,
              context: context)
          .then((status) {
        if (state.user != null) {
          loader.hideLoader();
          Navigator.pop(context);
          widget.loginCallback!();
        } else {
          cprint('Unable to login', errorIn: '_emailLoginButton');
          loader.hideLoader();
        }
      });
    } else {
      loader.hideLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: customText(
            'Sign In',
            context: context,
            style: const TextStyle(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/signup_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Existing content with semi-transparent background
            Container(
              // color: Colors.black
              //     .withOpacity(0.2), // Adds overlay to improve text readability
              child: SingleChildScrollView(child: _body(context)),
            ),
          ],
        ),
      ),
    );
  }
}
