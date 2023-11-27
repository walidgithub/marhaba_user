import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxiuser/functions/functions.dart';
import 'package:tagxiuser/pages/NavigatorPages/walletpage.dart';
import 'package:tagxiuser/pages/loadingPage/loading.dart';
import 'package:tagxiuser/pages/login/login.dart';
import 'package:tagxiuser/pages/noInternet/nointernet.dart';
import 'package:tagxiuser/styles/styles.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tagxiuser/translations/translation.dart';
import 'package:tagxiuser/widgets/widgets.dart';

// ignore: must_be_immutable
class SelectWallet extends StatefulWidget {
  dynamic from;
  SelectWallet({this.from, Key? key}) : super(key: key);

  @override
  State<SelectWallet> createState() => _SelectWalletState();
}

CardEditController cardController = CardEditController();

class _SelectWalletState extends State<SelectWallet> {
  bool _isLoading = false;
  bool _success = false;
  bool _failed = false;

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  @override
  void initState() {
    if (walletBalance['stripe_environment'] == 'test') {
      Stripe.publishableKey = walletBalance['stripe_test_publishable_key'];
    } else {
      Stripe.publishableKey = walletBalance['stripe_live_publishable_key'];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierBook.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(media.width * 0.05,
                          media.width * 0.05, media.width * 0.05, 0),
                      height: media.height * 1,
                      width: media.width * 1,
                      color: page,
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          Stack(
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.only(bottom: media.width * 0.05),
                                width: media.width * 0.9,
                                alignment: Alignment.center,
                                child: Text(
                                  languages[choosenLanguage]['text_addmoney'],
                                  style: GoogleFonts.roboto(
                                      color: textColor,
                                      fontSize: media.width * sixteen,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: textColor,
                                      )))
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                //card design
                                CardField(
                                  controller: cardController,
                                  onCardChanged: (card) {
                                    setState(() {});
                                  },
                                  cursorColor: topBar,
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                        color: (isDarkTheme == true)
                                            ? topBar
                                            : hintColor),
                                  ),
                                  style: TextStyle(
                                      color: isDarkTheme == true
                                          ? topBar
                                          : textColor),
                                ),
                                SizedBox(
                                  height: media.width * 0.1,
                                ),

                                //pay money button
                                Button(
                                    width: media.width * 0.5,
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var val =
                                          await getStripePayment(addMoney);
                                      if (val == 'success') {
                                        dynamic val2;
                                        try {
                                          val2 = await Stripe.instance
                                              .confirmPayment(
                                            paymentIntentClientSecret:
                                                stripeToken['client_token'],
                                            data: PaymentMethodParams.card(
                                              paymentMethodData:
                                                  PaymentMethodData(
                                                billingDetails: BillingDetails(
                                                    name: userDetails['name'],
                                                    phone:
                                                        userDetails['mobile']),
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          setState(() {
                                            _failed = true;
                                            _isLoading = false;
                                          });
                                        }
                                        if (val2.status ==
                                            PaymentIntentsStatus.Succeeded) {
                                          dynamic val3;
                                          if (widget.from == '1') {
                                            val3 =
                                                await payMoneyStripe(val2.id);
                                            if (val3 == 'logout') {
                                              navigateLogout();
                                            }
                                          } else {
                                            val3 = await addMoneyStripe(
                                                addMoney, val2.id);
                                          }
                                          if (val3 == 'success') {
                                            setState(() {
                                              _success = true;
                                            });
                                          } else if (val3 == 'logout') {
                                            navigateLogout();
                                          } else {
                                            setState(() {
                                              _failed = true;
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            _failed = true;
                                          });
                                        }
                                      } else if (val == 'logout') {
                                        navigateLogout();
                                      } else {
                                        setState(() {
                                          _failed = true;
                                        });
                                      }
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    text: 'Pay')
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    //failure error
                    (_failed == true)
                        ? Positioned(
                            top: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: page),
                                    child: Column(
                                      children: [
                                        Text(
                                          languages[choosenLanguage]
                                              ['text_somethingwentwrong'],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * sixteen,
                                              color: textColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        Button(
                                            onTap: () async {
                                              setState(() {
                                                _failed = false;
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_ok'])
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                        : Container(),

                    //success popup
                    (_success == true)
                        ? Positioned(
                            top: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              // color: Colors.transparent.withOpacity(0.6),
                              color: (isDarkTheme == true)
                                  ? textColor.withOpacity(0.2)
                                  : Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        // border: Border.all(color: topBar),
                                        color: page),
                                    child: Column(
                                      children: [
                                        Text(
                                          languages[choosenLanguage]
                                              ['text_paymentsuccess'],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * sixteen,
                                              color: textColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        Button(
                                            onTap: () async {
                                              setState(() {
                                                _success = false;

                                                Navigator.pop(context, true);
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_ok'])
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                        : Container(),

                    //no internet
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(
                              onTap: () {
                                setState(() {
                                  internetTrue();
                                  _isLoading = true;
                                });
                              },
                            ))
                        : Container(),

                    //loader
                    (_isLoading == true)
                        ? const Positioned(top: 0, child: Loading())
                        : Container()
                  ],
                ),
              );
            }),
      ),
    );
  }
}
