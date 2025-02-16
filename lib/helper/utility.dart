// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Trusty/state/authState.dart';
import 'package:provider/provider.dart';

import '../widgets/newWidget/customLoader.dart';

final kAnalytics = FirebaseAnalytics.instance;
final DatabaseReference kDatabase = FirebaseDatabase.instance.ref();
final kScreenLoader = CustomLoader();
void cprint(dynamic data,
    {String? errorIn, String? event, String label = 'Log'}) {
  /// Print logs only in development mode
  if (kDebugMode) {
    if (errorIn != null) {
      print(
          '****************************** error ******************************');
      developer.log('[Error]',
          time: DateTime.now(), error: data, name: errorIn);
      print(
          '****************************** error ******************************');
    } else if (data != null) {
      developer.log(data, time: DateTime.now(), name: label);
    }
    if (event != null) {
      Utility.logEvent(event, parameter: {});
    }
  }
}

class Utility {
  static String getPostTime2(String? date) {
    if (date == null || date.isEmpty) {
      return '';
    }
    var dt = DateTime.parse(date).toLocal();
    var dat =
        DateFormat.jm().format(dt) + ' - ' + DateFormat("dd MMM yy").format(dt);
    return dat;
  }

  static String getDob(String? date) {
    if (date == null || date.isEmpty) {
      return '';
    }
    var dt = DateTime.parse(date).toLocal();
    var dat = DateFormat.yMMMd().format(dt);
    return dat;
  }

  static String getJoiningDate(String? date) {
    if (date == null || date.isEmpty) {
      return '';
    }
    var dt = DateTime.parse(date).toLocal();
    var dat = DateFormat("MMMM yyyy").format(dt);
    return 'Joined $dat';
  }

  static String getChatTime(String? date) {
    if (date == null || date.isEmpty) {
      return '';
    }
    String msg = '';
    var dt = DateTime.parse(date).toLocal();

    if (DateTime.now().toLocal().isBefore(dt)) {
      return DateFormat.jm().format(DateTime.parse(date).toLocal()).toString();
    }

    var dur = DateTime.now().toLocal().difference(dt);
    if (dur.inDays > 365) {
      msg = DateFormat.yMMMd().format(dt);
    } else if (dur.inDays > 30) {
      msg = DateFormat.yMMMd().format(dt);
    } else if (dur.inDays > 0) {
      msg = '${dur.inDays} d';
      return dur.inDays == 1 ? '1d' : DateFormat.MMMd().format(dt);
    } else if (dur.inHours > 0) {
      msg = '${dur.inHours} h';
    } else if (dur.inMinutes > 0) {
      msg = '${dur.inMinutes} m';
    } else if (dur.inSeconds > 0) {
      msg = '${dur.inSeconds} s';
    } else {
      msg = 'now';
    }
    return msg;
  }

  static String getPollTime(String date) {
    int hr, mm;
    String msg = 'Poll ended';
    var endDate = DateTime.parse(date);
    if (DateTime.now().isAfter(endDate)) {
      return msg;
    }
    msg = 'Poll ended in';
    var dur = endDate.difference(DateTime.now());
    hr = dur.inHours - dur.inDays * 24;
    mm = dur.inMinutes - (dur.inHours * 60);
    if (dur.inDays > 0) {
      msg = ' ' + dur.inDays.toString() + (dur.inDays > 1 ? ' Days ' : ' Day');
    }
    if (hr > 0) {
      msg += ' ' + hr.toString() + ' hour';
    }
    if (mm > 0) {
      msg += ' ' + mm.toString() + ' min';
    }
    return (dur.inDays).toString() +
        ' Days ' +
        ' ' +
        hr.toString() +
        ' Hours ' +
        mm.toString() +
        ' min';
  }

  static String? getSocialLinks(String? url) {
    if (url != null && url.isNotEmpty) {
      url = url.contains("https://www") || url.contains("http://www")
          ? url
          : url.contains("www") &&
                  (!url.contains('https') && !url.contains('http'))
              ? 'https://' + url
              : 'https://www.' + url;
    } else {
      return null;
    }
    cprint('Launching URL : $url');
    return url;
  }

  static launchURL(String url) async {
    if (url == "") {
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      cprint('Could not launch $url');
    }
  }

  static void logEvent(String event, {Map<String, String>? parameter}) {
    kReleaseMode
        ? kAnalytics.logEvent(name: event, parameters: parameter)
        : print("[EVENT]: $event");
  }

  static void debugLog(String log, {dynamic param = ""}) {
    final String time = DateFormat("mm:ss:mmm").format(DateTime.now());
    print("[$time][Log]: $log, $param");
  }

  static void share(String message, {String? subject}) {
    Share.share(message, subject: subject);
  }

  static List<String> getHashTags(String text) {
    RegExp reg = RegExp(r"([#])\w+"); // Only match hashtags
    Iterable<Match> _matches = reg.allMatches(text);
    List<String> resultMatches = <String>[];
    for (Match match in _matches) {
      if (match.group(0)!.isNotEmpty) {
        var tag = match.group(0);
        resultMatches.add(tag!);
      }
    }
    return resultMatches;
  }

  static String getUserName({
    required String id,
    required String name,
  }) {
    // Replace all non-English characters with their English equivalents
    name = name
        .replaceAll(RegExp(r'[Çç]'), 'c')
        .replaceAll(RegExp(r'[Öö]'), 'o')
        .replaceAll(RegExp(r'[Ğğ]'), 'g')
        .replaceAll(RegExp(r'[Şş]'), 's')
        .replaceAll(RegExp(r'[İı]'), 'i')
        .replaceAll(RegExp(r'[Üü]'), 'u')
        .replaceAll(RegExp(r'[Ââ]'), 'a')
        .replaceAll(RegExp(r'[Êê]'), 'e')
        .replaceAll(RegExp(r'[Ôô]'), 'o')
        .replaceAll(RegExp(r'[Ûû]'), 'u')
        // Replace remaining non-English characters with an empty string
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');

    // Convert to lowercase
    name = name.toLowerCase();
    if (name.contains(' ')) {
      name = name.split(' ')[0];
    }
    if (name.length > 15) {
      name = name.substring(0, 15);
    }
    id = id.substring(0, 4).toLowerCase();
    String userName = '@$name$id';
    return userName;
  }

  static bool validateCredentials(
      BuildContext context, String? email, String? password) {
    if (email == null || email.isEmpty) {
      customSnackBar(context, 'Please enter email id');
      return false;
    } else if (password == null || password.isEmpty) {
      customSnackBar(context, 'Please enter password');
      return false;
    } else if (password.length < 8) {
      customSnackBar(context, 'Password must me 8 character long');
      return false;
    }

    var status = validateEmail(email);
    if (!status) {
      customSnackBar(context, 'Please enter valid email id');
      return false;
    }
    return true;
  }

  static customSnackBar(
    BuildContext context,
    String msg, {
    double height = 30,
    Color? backgroundColor,
  }) {
    final bgColor = backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      backgroundColor: bgColor,
      content: Text(
        msg,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static bool validateEmail(String email) {
    String p = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

    RegExp regExp = RegExp(p);

    var status = regExp.hasMatch(email);
    return status;
  }

  static Future<Uri> createLinkToShare(BuildContext context, String id,
      {required SocialMetaTagParameters socialMetaTagParameters}) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://trusty.page.link',
      link: Uri.parse('https://twitter.com/$id'),
      androidParameters: AndroidParameters(
        packageName: 'tech.curiosity.tech',
        minimumVersion: 0,
      ),
      socialMetaTagParameters: socialMetaTagParameters,
    );
    Uri url;
    final ShortDynamicLink shortLink =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    url = shortLink.shortUrl;
    return url;
  }

  static createLinkAndShare(BuildContext context, String id,
      {required SocialMetaTagParameters socialMetaTagParameters}) async {
    var url = await createLinkToShare(context, id,
        socialMetaTagParameters: socialMetaTagParameters);

    share(url.toString(), subject: "Tweet");
  }

  static Future<void> shareFile(List<String> paths, {String? text}) async {
    try {
      await Share.shareXFiles(paths.map((path) => XFile(path)).toList(),
          text: text, sharePositionOrigin: Rect.fromLTWH(0, 0, 10, 10));
    } catch (e) {
      print('Error sharing: $e');
      throw Exception('Failed to share file');
    }
  }

  static void copyToClipBoard({
    required BuildContext context,
    required String text,
    required String message,
  }) {
    var data = ClipboardData(text: text);
    Clipboard.setData(data);
    customSnackBar(context, message);
  }

  static Locale getLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  static String getEventDateTime(String date) {
    final eventDate = DateTime.parse(date);
    return DateFormat('MMM d, y').format(eventDate);
  }

  static String getEventTime(String date) {
    final eventDate = DateTime.parse(date);
    return DateFormat('h:mm a').format(eventDate);
  }

  static void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "This action cannot be reversed. All your data including tweets, messages and media will be permanently deleted.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Yes, I understand",
                  style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _showFinalConfirmDialog(context); // Changed to private method
              },
            ),
          ],
        );
      },
    );
  }

  // Changed to private method since it's only used within showDeleteAccountDialog
  static void _showFinalConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Final Confirmation"),
          content: const Text(
            "Please confirm that you understand this action is irreversible",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Yes, delete my account permanently",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                var state = Provider.of<AuthState>(context, listen: false);
                state.deleteAccount(context);
              },
            ),
          ],
        );
      },
    );
  }
}
