import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxiuser/functions/functions.dart';
import 'package:tagxiuser/pages/NavigatorPages/about.dart';
import 'package:tagxiuser/pages/NavigatorPages/editprofile.dart';
import 'package:tagxiuser/pages/NavigatorPages/faq.dart';
import 'package:tagxiuser/pages/NavigatorPages/favourite.dart';
import 'package:tagxiuser/pages/NavigatorPages/history.dart';
import 'package:tagxiuser/pages/NavigatorPages/makecomplaint.dart';
import 'package:tagxiuser/pages/NavigatorPages/referral.dart';
import 'package:tagxiuser/pages/NavigatorPages/selectlanguage.dart';
import 'package:tagxiuser/pages/NavigatorPages/sos.dart';
import 'package:tagxiuser/pages/NavigatorPages/walletpage.dart';
import 'package:tagxiuser/pages/onTripPage/map_page.dart';
import 'package:tagxiuser/styles/styles.dart';
import 'package:tagxiuser/translations/translation.dart';

import '../NavigatorPages/notification.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key? key}) : super(key: key);
  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  themefun() async {
    if (isDarkTheme) {
      isDarkTheme = false;

      page = Colors.white;
      textColor = Colors.black;
      buttonColor = theme;
      loaderColor = theme;
      buttonText = const Color(0xffFFFFFF);
    } else {
      isDarkTheme = true;
      page = Colors.black;
      textColor = Colors.white;
      buttonColor = Colors.white;
      loaderColor = Colors.white;
      buttonText = Colors.black;
    }
    // await getDetailsOfDevice();
    if (isDarkTheme == true) {
      rootBundle.loadString('assets/dark.json').then((value) {
        mapStyle = value;
      });
    } else {
      rootBundle.loadString('assets/map_style_black.json').then((value) {
        mapStyle = value;
      });
    }

    pref.setBool('isDarkTheme', isDarkTheme);
    valueNotifierHome.incrementNotifier();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          return SizedBox(
            width: media.width * 0.8,
            child: Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Drawer(
                  backgroundColor: page,
                  child: SizedBox(
                    width: media.width * 0.7,
                    child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: media.width * 0.05 +
                                  MediaQuery.of(context).padding.top,
                            ),
                            SizedBox(
                              width: media.width * 0.7,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    height: media.width * 0.2,
                                    width: media.width * 0.2,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                            image: NetworkImage(
                                                userDetails['profile_picture']),
                                            fit: BoxFit.cover)),
                                  ),
                                  SizedBox(
                                    width: media.width * 0.025,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: media.width * 0.45,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.3,
                                              child: Text(
                                                userDetails['name'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * eighteen,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                maxLines: 1,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const EditProfile()));
                                                if (val != null) {
                                                  if (val) {
                                                    setState(() {});
                                                  }
                                                }
                                              },
                                              child: Icon(
                                                Icons.edit,
                                                size: media.width * eighteen,
                                                color: textColor,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.01,
                                      ),
                                      SizedBox(
                                        width: media.width * 0.45,
                                        child: Text(
                                          userDetails['email'],
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * fourteen,
                                              color: textColor),
                                          maxLines: 1,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(top: media.width * 0.05),
                              width: media.width * 0.7,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      themefun();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.025),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isDarkTheme
                                                    ? Icons
                                                        .brightness_4_outlined
                                                    : Icons
                                                        .brightness_3_rounded,
                                                size: media.width * 0.075,
                                                color: textColor,
                                              ),
                                              SizedBox(
                                                width: media.width * 0.025,
                                              ),
                                              SizedBox(
                                                width: media.width * 0.35,
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_select_theme'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Switch(
                                            value: isDarkTheme,
                                            onChanged: (toggle) async {
                                              themefun();
                                            }),
                                      ],
                                    ),
                                  ),

                                  //notification
                                  ValueListenableBuilder(
                                      valueListenable:
                                          valueNotifierNotification.value,
                                      builder: (context, value, child) {
                                        return InkWell(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const NotificationPage()));
                                            setState(() {
                                              userDetails[
                                                  'notifications_count'] = 0;
                                            });
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.025),
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/notification.png',
                                                      fit: BoxFit.contain,
                                                      width:
                                                          media.width * 0.075,
                                                      color: textColor,
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          media.width * 0.025,
                                                    ),
                                                    SizedBox(
                                                      width: media.width * 0.49,
                                                      child: Text(
                                                        languages[choosenLanguage]
                                                                [
                                                                'text_notification']
                                                            .toString(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: GoogleFonts
                                                            .roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                color:
                                                                    textColor),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              (userDetails[
                                                          'notifications_count'] ==
                                                      0)
                                                  ? Container()
                                                  : Container(
                                                      height: 20,
                                                      width: 20,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: buttonColor,
                                                      ),
                                                      child: Text(
                                                        userDetails[
                                                                'notifications_count']
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    buttonText),
                                                      ),
                                                    )
                                            ],
                                          ),
                                        );
                                      }),
                                  //history
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const History()));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/history.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_enable_history'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //wallet page
                                  if (userDetails[
                                          'show_wallet_feature_on_mobile_app'] ==
                                      "1")
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const WalletPage()));
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/walletIcon.png',
                                              fit: BoxFit.contain,
                                              width: media.width * 0.075,
                                              color: textColor,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.025,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.55,
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_enable_wallet'],
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * sixteen,
                                                    color: textColor),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),

                                  //referral page
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ReferralPage()));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/referral.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_enable_referal'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //favorite
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Favorite()));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.favorite_border,
                                            size: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_favourites'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //faq
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Faq()));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/faq.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_faq'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //sos
                                  InkWell(
                                    onTap: () async {
                                      var nav = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Sos()));
                                      if (nav) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/sos.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_sos'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //select language
                                  InkWell(
                                    onTap: () async {
                                      var nav = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SelectLanguage()));
                                      if (nav) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/changeLanguage.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_change_language'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  //make complaints
                                  InkWell(
                                    onTap: () async {
                                      var nav = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MakeComplaint(
                                                    fromPage: 0,
                                                  )));
                                      if (nav) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/makecomplaint.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_make_complaints'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  //about
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const About()));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_about'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //delete account
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        deleteAccount = true;
                                      });
                                      valueNotifierHome.incrementNotifier();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_forever,
                                            size: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_delete_account'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  //logout
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        logout = true;
                                      });
                                      valueNotifierHome.incrementNotifier();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/logout.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.55,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_logout'],
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ]),
                    ),
                  )),
            ),
          );
        });
  }
}
