import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxiuser/functions/functions.dart';
import 'package:tagxiuser/pages/loadingPage/loading.dart';
import 'package:tagxiuser/pages/login/login.dart';
import 'package:tagxiuser/pages/noInternet/nointernet.dart';
import 'package:tagxiuser/styles/styles.dart';
import 'package:tagxiuser/translations/translation.dart';
import 'package:tagxiuser/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isLoading = true;
  bool _showToast = false;

  @override
  void initState() {
    _getReferral();
    super.initState();
  }

//get referral code
  _getReferral() async {
    var val = await getReferral();
    if (val == 'logout') {
      navigateLogout();
    }
    await getUrls();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  var android = '';
  var ios = '';
  String androidPackage = '';
  String iOSBundle = '';

  getUrls() async {
    var packageName =
        await FirebaseDatabase.instance.ref().child('user_package_name').get();
    if (packageName.value != null) {
      androidPackage = packageName.value.toString();
      android = 'https://play.google.com/store/apps/details?id=$androidPackage';
    }
    var bundleId =
        await FirebaseDatabase.instance.ref().child('user_bundle_id').get();
    if (bundleId.value != null) {
      iOSBundle = bundleId.value.toString();
      var response = await http
          .get(Uri.parse('http://itunes.apple.com/lookup?bundleId=$iOSBundle'));
      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['results'].isNotEmpty) {
          ios = jsonDecode(response.body)['results'][0]['trackViewUrl'];
        }
      }
    }
  }

//show toast for copied
  showToast() {
    setState(() {
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showToast = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.05),
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    child: (myReferralCode.isNotEmpty)
                        ? Column(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).padding.top),
                                    Stack(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                              bottom: media.width * 0.05),
                                          width: media.width * 1,
                                          alignment: Alignment.center,
                                          child: Text(
                                            languages[choosenLanguage]
                                                ['text_enable_referal'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * twenty,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                        ),
                                        Positioned(
                                            child: InkWell(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Icon(Icons.arrow_back,
                                                    color: textColor)))
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      height: media.height * 0.16,
                                      child: Image.asset(
                                        'assets/images/referralpage.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.1,
                                    ),
                                    Text(
                                      myReferralCode[
                                          'referral_comission_string'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * sixteen,
                                          color: textColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Container(
                                        width: media.width * 0.9,
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: borderLines, width: 1.2),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              myReferralCode['refferal_code'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    Clipboard.setData(ClipboardData(
                                                        text: myReferralCode[
                                                            'refferal_code']));
                                                  });
                                                  showToast();
                                                },
                                                child: Icon(
                                                  Icons.copy,
                                                  color: textColor,
                                                ))
                                          ],
                                        ))
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                    top: media.width * 0.05,
                                    bottom: media.width * 0.05),
                                child: Button(
                                    onTap: () async {
                                      if (android != '' && ios != '') {
                                        await Share.share(
                                            // ignore: prefer_interpolation_to_compose_strings
                                            languages[choosenLanguage]
                                                        ['text_invitation_1']
                                                    .toString()
                                                    .replaceAll(
                                                        '55', package.appName) +
                                                ' ' +
                                                myReferralCode[
                                                    'refferal_code'] +
                                                ' ' +
                                                languages[choosenLanguage]
                                                    ['text_invitation_2'] +
                                                ' \n\nandroid\n\n' +
                                                android +
                                                '\n\niOS\n\n' +
                                                ios);
                                      } else if (android != '') {
                                        await Share.share(
                                            // ignore: prefer_interpolation_to_compose_strings
                                            languages[choosenLanguage]
                                                        ['text_invitation_1']
                                                    .toString()
                                                    .replaceAll(
                                                        '55', package.appName) +
                                                ' ' +
                                                myReferralCode[
                                                    'refferal_code'] +
                                                ' ' +
                                                languages[choosenLanguage]
                                                    ['text_invitation_2'] +
                                                ' \n\nandroid\n\n' +
                                                android);
                                      } else if (ios != '') {
                                        await Share.share(
                                            // ignore: prefer_interpolation_to_compose_strings
                                            languages[choosenLanguage]
                                                        ['text_invitation_1']
                                                    .toString()
                                                    .replaceAll(
                                                        '55', package.appName) +
                                                ' ' +
                                                myReferralCode[
                                                    'refferal_code'] +
                                                ' ' +
                                                languages[choosenLanguage]
                                                    ['text_invitation_2'] +
                                                '\n\niOS\n\n' +
                                                ios);
                                      }
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_invite']),
                              )
                            ],
                          )
                        : Container(),
                  ),
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _isLoading = true;
                                getReferral();
                              });
                            },
                          ))
                      : Container(),

                  //loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),

                  //display toast
                  (_showToast == true)
                      ? Positioned(
                          bottom: media.height * 0.2,
                          child: Container(
                            padding: EdgeInsets.all(media.width * 0.025),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: (isDarkTheme == true)
                                    ? textColor.withOpacity(0.4)
                                    : Colors.transparent.withOpacity(0.6)),
                            child: Text(
                              languages[choosenLanguage]['text_code_copied'],
                              style: GoogleFonts.roboto(
                                  fontSize: media.width * twelve,
                                  color: Colors.white),
                            ),
                          ))
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
