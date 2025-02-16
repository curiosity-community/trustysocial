import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Trusty/helper/constant.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:flutter/foundation.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/Auth/widget/googleLoginButton.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/customLoader.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class Signup extends StatefulWidget {
  final VoidCallback? loginCallback;

  const Signup({Key? key, this.loginCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  late TextEditingController _referenceCodeController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmController;
  late CustomLoader loader;
  bool _isTapped = false;
  final _formKey = GlobalKey<FormState>();
  bool _hasRequestedWaitlist = false;

  @override
  void initState() {
    loader = CustomLoader();
    _referenceCodeController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    _referenceCodeController.addListener(() {
      setState(() {}); // Trigger rebuild when referral code changes
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _referenceCodeController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int generateIncrementalInteger() {
    // Get the current date and time
    DateTime now = DateTime.now();

    // Create a seed by combining the current year, month, day, hour, minute, and second
    int seed = int.parse(
        '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}');

    // Ensure that the generated number is above 100,000 and incrementally grows
    int randomNumber = seed % 90000 + 10000;

    return randomNumber;
  }

  Future<void> _sendSlackNotification(String email) async {
    const slackWebhookUrl = 'https://hooks.slack.com/services/XXXX/XXXX/XXXXXX';

    // Email validation regex
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    // Check if the email is empty
    if (email.isEmpty) {
      Utility.customSnackBar(
          context, 'Email is required to send a notification');
      return;
    }

    // Validate the email format
    if (!emailRegex.hasMatch(email)) {
      Utility.customSnackBar(context, 'Please enter a valid email address');
      return;
    }

    try {
      // Send POST request to Slack webhook URL
      final response = await http.post(
        Uri.parse(slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"text":"Waiting: $email"}',
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        int generatedNumber = generateIncrementalInteger();
        Utility.customSnackBar(
          context,
          'You are in the $generatedNumber th rank among those waiting.',
        );
      } else {
        // Handle cases where the response status code indicates failure
        Utility.customSnackBar(
          context,
          'Failed to send notification to Slack. Error code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Handle errors such as network issues or unexpected exceptions
      Utility.customSnackBar(
        context,
        'An error occurred while sending the notification: $e',
      );
    }
  }

  Widget _body(BuildContext context) {
    return Container(
      height: context.height,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _entryField('Referral Code',
                controller: _referenceCodeController, isReference: true),
            if (_referenceCodeController
                .text.isEmpty) // Only show if referral code is empty
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    if (_hasRequestedWaitlist) {
                      Utility.customSnackBar(
                          context, 'We have received your request. Thank you!');
                      return;
                    }
                    if (_emailController.text.isNotEmpty) {
                      _sendSlackNotification(_emailController.text).then((_) {
                        setState(() {
                          _hasRequestedWaitlist = true;
                        });
                      });
                    } else {
                      Utility.customSnackBar(context,
                          'Please enter your email to join the waitlist');
                    }
                  },
                  child: Text(
                    _hasRequestedWaitlist
                        ? "Request received!"
                        : _emailController.text.isNotEmpty &&
                                RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(_emailController.text)
                            ? "Please enter a referral code or join the waitlist"
                            : "Don't have a referral code?",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            _entryField('Name', controller: _nameController),
            _entryField('Enter email',
                controller: _emailController, isEmail: true),
            _entryField('Enter password',
                controller: _passwordController, isPassword: true),
            _entryField('Confirm password',
                controller: _confirmController, isPassword: true),
            _submitButton(context),
            // const Divider(height: 30),
            // const SizedBox(height: 30),
            // GoogleLoginButton(
            //   loginCallback: widget.loginCallback,
            //   loader: loader,
            // ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _entryField(String hint,
      {required TextEditingController controller,
      bool isPassword = false,
      bool isEmail = false,
      bool isReference = false}) {
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
                  : isReference
                      ? const Icon(Icons.code, color: Colors.black)
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

  Widget _submitButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        if (_referenceCodeController.text.isEmpty) {
          // Handle referral code request
          if (_hasRequestedWaitlist) {
            Utility.customSnackBar(
                context, 'We have received your request. Thank you!');
            return;
          }
          if (_emailController.text.isNotEmpty) {
            _sendSlackNotification(_emailController.text).then((_) {
              setState(() {
                _hasRequestedWaitlist = true;
              });
            });
          } else {
            Utility.customSnackBar(
                context, 'Please enter your email to join the waitlist');
          }
        } else {
          // Handle signup
          _submitForm(context);
        }
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            _referenceCodeController.text.isEmpty
                ? 'Request a referral code'
                : 'Sign Up',
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

  Future<Map?> _getMasterRefferalCodeFromFirebaseConfig() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values
      await remoteConfig
          .setDefaults({'master_referral_code': '{"code": "DEFAULT_CODE"}'});

      // Production settings:
      // - 12 hour minimum fetch interval to reduce API calls
      // - 5 second timeout for fetch operations
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      await remoteConfig.fetchAndActivate();
      var data = remoteConfig.getString('master_referral_code');

      if (data.isNotEmpty) {
        return jsonDecode(data) as Map;
      }
      return null;
    } catch (e) {
      cprint("Error fetching remote config",
          errorIn: "_getMasterRefferalCodeFromFirebaseConfig");
      return null;
    }
  }

  Future<bool> _validateReferralCode(
      String referralCode, BuildContext context) async {
    try {
      String masterCode = '';
      final config = await _getMasterRefferalCodeFromFirebaseConfig();
      if (config != null) {
        masterCode = config['code'];
      }
      if (kDebugMode) {
        print("Master Refferal Code: $masterCode");
      }

      if (masterCode == referralCode) {
        return true;
      }

      // 2. Normal referans kodları kontrolü
      final event = await kDatabase.child('referralCodes').once();
      final snapshot = event.snapshot;

      if (snapshot.value != null) {
        var codes = snapshot.value as Map<dynamic, dynamic>;

        // Geçerli bir referans kodu ara
        var validCode = codes.entries.firstWhere(
          (entry) =>
              entry.value['code'] == referralCode &&
              !entry.value.containsKey('usedBy'),
          orElse: () => MapEntry('', null),
        );

        if (validCode.value != null) {
          return true;
        }
      }

      return false;
    } catch (error) {
      print("Error validating referral code: $error");
      Utility.customSnackBar(context, 'Error validating referral code');
      return false;
    }
  }

  void _submitForm(BuildContext context) async {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (_referenceCodeController.text.isEmpty) {
      Utility.customSnackBar(context, 'Please enter referral code.');
      return;
    }

    // Referans kodu kontrolünü burada yap
    bool isValidCode =
        await _validateReferralCode(_referenceCodeController.text, context);
    if (!isValidCode) {
      Utility.customSnackBar(context, 'Invalid referral code');
      return;
    }

    // Diğer validasyonlar...
    if (_nameController.text.isEmpty) {
      Utility.customSnackBar(context, 'Please enter name');
      return;
    }
    if (_nameController.text.length > 27) {
      Utility.customSnackBar(context, 'Name length cannot exceed 27 character');
      return;
    }
    if (_emailController.text.isEmpty) {
      Utility.customSnackBar(context, 'Please enter an email');
      return;
    }
    if (!emailRegex.hasMatch(_emailController.text)) {
      Utility.customSnackBar(context, 'Please enter a valid email address');
      return;
    }
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      Utility.customSnackBar(context, 'Please fill the form carefully');
      return;
    } else if (_passwordController.text != _confirmController.text) {
      Utility.customSnackBar(
          context, 'Password and confirm password did not match');
      return;
    }

    loader.showLoader(context);
    var state = Provider.of<AuthState>(context, listen: false);
    //Random random = Random();
    //int randomNumber = random.nextInt(8);

    UserModel user = UserModel(
      email: _emailController.text.toLowerCase(),
      bio: 'A trusted person in the Trusty app',
      // contact:  _mobileController.text,
      displayName: _nameController.text,
      dob: DateTime(1990, DateTime.now().month, DateTime.now().day + 3)
          .toString(),
      location: 'Somewhere in universe',
      profilePic:
          'https://firebasestorage.googleapis.com/v0/b/trusty-4db3d.firebasestorage.app/o/user%2Fprofile%2Fdefault%2Fdefault_avatar.jpg?alt=media',
      // profilePic:
      //     'https://eu.ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text)}&size=250',
      //profilePic: Constants.dummyProfilePicList[randomNumber],
      isVerified: false,
    );

    state
        .signUp(
      user,
      password: _passwordController.text,
      referralCode: _referenceCodeController.text,
      context: context,
    )
        .then((status) {
      print(status);
    }).whenComplete(() {
      loader.hideLoader();
      if (state.authStatus == AuthStatus.LOGGED_IN) {
        Navigator.pop(context);
        if (widget.loginCallback != null) widget.loginCallback!();
      }
    });
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
            'Sign Up',
            context: context,
            style: const TextStyle(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/signup_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.2),
              child: SingleChildScrollView(child: _body(context)),
            ),
          ],
        ),
      ),
    );
  }
}
