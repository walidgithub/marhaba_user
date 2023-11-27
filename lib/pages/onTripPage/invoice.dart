import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/cashfreepage.dart';
import '../NavigatorPages/flutterWavePage.dart';
import '../NavigatorPages/mercadopago.dart';
import '../NavigatorPages/paystackpayment.dart';
import '../NavigatorPages/razorpaypage.dart';
import '../NavigatorPages/selectwallet.dart';
import '../NavigatorPages/walletpage.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import 'booking_confirmation.dart';
import 'map_page.dart';
import 'review_page.dart';

class Invoice extends StatefulWidget {
  const Invoice({Key? key}) : super(key: key);

  @override
  State<Invoice> createState() => _InvoiceState();
}

class _InvoiceState extends State<Invoice> {
  bool _choosePayment = false;
  bool _isLoading = false;
  bool _choosePaymentMethod = false;
  String _error = '';
  String myPaymentMethod = '';

  @override
  void initState() {
    myMarkers.clear();
    promoCode = '';
    payingVia = 0;
    timing = null;
    promoStatus = null;
    super.initState();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              return Stack(
                children: [
                  if (userRequestData.isNotEmpty)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                          media.width * 0.05,
                          MediaQuery.of(context).padding.top +
                              media.width * 0.05,
                          media.width * 0.05,
                          media.width * 0.05),
                      height: media.height * 1,
                      width: media.width * 1,
                      color: page,
                      //invoice details
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    languages[choosenLanguage]
                                        ['text_tripsummary'],
                                    style: GoogleFonts.roboto(
                                        color: textColor,
                                        fontSize: media.width * sixteen,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: media.height * 0.04,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: media.width * 0.13,
                                        width: media.width * 0.13,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    userRequestData[
                                                                'driverDetail']
                                                            ['data']
                                                        ['profile_picture']),
                                                fit: BoxFit.cover)),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.05,
                                      ),
                                      Text(
                                        userRequestData['driverDetail']['data']
                                            ['name'],
                                        style: GoogleFonts.roboto(
                                          fontSize: media.width * eighteen,
                                          color: textColor,
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.05,
                                  ),
                                  SizedBox(
                                    width: media.width * 0.72,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_reference'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: const Color(
                                                          0xff898989)),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                Text(
                                                  userRequestData[
                                                      'request_number'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor),
                                                )
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_rideType'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: const Color(
                                                          0xff898989)),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                Text(
                                                  (userRequestData[
                                                              'is_rental'] ==
                                                          false)
                                                      ? languages[
                                                              choosenLanguage]
                                                          ['text_regular']
                                                      : languages[
                                                              choosenLanguage]
                                                          ['text_rental'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: media.height * 0.02,
                                        ),
                                        Container(
                                          height: 2,
                                          color: const Color(0xffAAAAAA),
                                        ),
                                        SizedBox(
                                          height: media.height * 0.02,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_distance'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: const Color(
                                                          0xff898989)),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                Text(
                                                  userRequestData[
                                                          'total_distance'] +
                                                      ' ' +
                                                      userRequestData['unit'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor),
                                                )
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_duration'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: const Color(
                                                          0xff898989)),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                Text(
                                                  '${userRequestData['total_time']} mins',
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: textColor),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.height * 0.05,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info, color: textColor),
                                      SizedBox(
                                        width: media.width * 0.04,
                                      ),
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_tripfare'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * fourteen,
                                            color: textColor),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.05,
                                  ),
                                  (userRequestData['is_rental'] == true)
                                      ? Container(
                                          padding: EdgeInsets.only(
                                              bottom: media.width * 0.05),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_ride_type'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    color: textColor),
                                              ),
                                              Text(
                                                userRequestData[
                                                    'rental_package_name'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    color: textColor),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_baseprice'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        '${userRequestData['requestBill']['data']['requested_currency_symbol']} ${userRequestData['requestBill']['data']['base_price']}',
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),

                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_distprice'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['distance_price']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_timeprice'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['time_price']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  (userRequestData['requestBill']['data']
                                              ['cancellation_fee'] !=
                                          0)
                                      ? SizedBox(
                                          height: media.height * 0.02,
                                        )
                                      : Container(),
                                  (userRequestData['requestBill']['data']
                                              ['cancellation_fee'] !=
                                          0)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_cancelfee'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: textColor),
                                            ),
                                            Text(
                                              userRequestData['requestBill']
                                                          ['data'][
                                                      'requested_currency_symbol'] +
                                                  ' ' +
                                                  userRequestData['requestBill']
                                                              ['data']
                                                          ['cancellation_fee']
                                                      .toString(),
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: textColor),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                  (userRequestData['requestBill']['data']
                                              ['airport_surge_fee'] !=
                                          0)
                                      ? SizedBox(
                                          height: media.height * 0.02,
                                        )
                                      : Container(),
                                  (userRequestData['requestBill']['data']
                                              ['airport_surge_fee'] !=
                                          0)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_surge_fee'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: textColor),
                                            ),
                                            Text(
                                              userRequestData['requestBill']
                                                          ['data'][
                                                      'requested_currency_symbol'] +
                                                  ' ' +
                                                  userRequestData['requestBill']
                                                              ['data']
                                                          ['airport_surge_fee']
                                                      .toString(),
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: textColor),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                                ['text_waiting_time_1'] +
                                            ' (' +
                                            userRequestData['requestBill']
                                                    ['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                        ['data']
                                                    ['waiting_charge_per_min']
                                                .toString() +
                                            ' x ' +
                                            userRequestData['requestBill']
                                                        ['data']
                                                    ['calculated_waiting_time']
                                                .toString() +
                                            ' mins' +
                                            ')',
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['waiting_charge']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_convfee'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['admin_commision']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  (userRequestData['requestBill']['data']
                                              ['promo_discount'] !=
                                          null)
                                      ? SizedBox(
                                          height: media.height * 0.02,
                                        )
                                      : Container(),
                                  (userRequestData['requestBill']['data']
                                              ['promo_discount'] !=
                                          null)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_discount'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: Colors.red),
                                            ),
                                            Text(
                                              userRequestData['requestBill']
                                                          ['data'][
                                                      'requested_currency_symbol'] +
                                                  ' ' +
                                                  userRequestData['requestBill']
                                                              ['data']
                                                          ['promo_discount']
                                                      .toString(),
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  color: Colors.red),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_taxes'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['service_tax']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Container(
                                    height: 1.5,
                                    color: const Color(0xffE0E0E0),
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_totalfare'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['total_amount']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twelve,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  Container(
                                    height: 1.5,
                                    color: const Color(0xffE0E0E0),
                                  ),
                                  // SizedBox(height: media.height*0.02,),
                                  SizedBox(
                                    height: media.height * 0.05,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        (userRequestData['payment_opt'] == '1')
                                            ? languages[choosenLanguage]
                                                ['text_cash']
                                            : (userRequestData['payment_opt'] ==
                                                    '2')
                                                ? languages[choosenLanguage]
                                                    ['text_wallet']
                                                : languages[choosenLanguage]
                                                    ['text_card'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * sixteen,
                                            color: buttonColor),
                                      ),
                                      Text(
                                        userRequestData['requestBill']['data']
                                                ['requested_currency_symbol'] +
                                            ' ' +
                                            userRequestData['requestBill']
                                                    ['data']['total_amount']
                                                .toString(),
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * twentysix,
                                            color: textColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Button(
                              onTap: () async {
                                if (userRequestData['is_paid'] == 0 &&
                                    userRequestData['payment_opt'] != '2') {
                                  setState(() {
                                    myPaymentMethod =
                                        userRequestData['payment_opt'] == '0'
                                            ? 'card'
                                            : userRequestData['payment_opt'] ==
                                                    '1'
                                                ? 'cash'
                                                : '';
                                    _choosePaymentMethod = true;
                                  });
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Review()));
                                }
                              },
                              text: (userRequestData['is_paid'] == 0)
                                  ? languages[choosenLanguage]
                                      ['text_choose_payment']
                                  : languages[choosenLanguage]['text_confirm']),
                          if (userRequestData['is_paid'] == 0 &&
                              userRequestData['payment_opt'] == '0')
                            Column(
                              children: [
                                SizedBox(
                                  height: media.width * 0.025,
                                ),
                                Button(
                                    onTap: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var val = await getWalletHistory();
                                      if (val == 'logout') {
                                        navigateLogout();
                                      }
                                      setState(() {
                                        _isLoading = false;
                                        _choosePayment = true;
                                      });
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_pay'])
                              ],
                            ),
                        ],
                      ),
                    ),
                  //choose payment method
                  (_choosePayment == true)
                      ? Positioned(
                          child: Container(
                          height: media.height * 1,
                          width: media.width * 1,
                          color: Colors.transparent.withOpacity(0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: media.width * 0.8,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _choosePayment = false;
                                        });
                                      },
                                      child: Container(
                                        height: media.height * 0.05,
                                        width: media.height * 0.05,
                                        decoration: BoxDecoration(
                                          color: page,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.cancel,
                                            color: buttonColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: media.width * 0.025),
                              Container(
                                padding: EdgeInsets.all(media.width * 0.05),
                                width: media.width * 0.8,
                                height: media.height * 0.6,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: page),
                                child: Column(
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.7,
                                        child: Text(
                                          languages[choosenLanguage]
                                              ['text_choose_payment'],
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * eighteen,
                                              fontWeight: FontWeight.w600),
                                        )),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: [
                                            (walletBalance['stripe'] == true)
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    alignment: Alignment.center,
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = double.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    2));
                                                        var val = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            SelectWallet(
                                                                              from: '1',
                                                                            )));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.25,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/stripe-icon.png'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                            (walletBalance['paystack'] == true)
                                                ? Container(
                                                    alignment: Alignment.center,
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = int.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    0));
                                                        var val = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            PayStackPage(
                                                                              from: '1',
                                                                            )));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.25,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/paystack-icon.png'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                            (walletBalance['flutter_wave'] ==
                                                    true)
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    alignment: Alignment.center,
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = double.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    2));
                                                        var val = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            FlutterWavePage(
                                                                              from: '1',
                                                                            )));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.25,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/flutterwave-icon.png'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                            (walletBalance['razor_pay'] == true)
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    alignment: Alignment.center,
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = int.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    0));
                                                        var val = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    RazorPayPage(
                                                                        from:
                                                                            '1')));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.25,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/razorpay-icon.jpeg'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                            (walletBalance['mercadopago'] ==
                                                    true)
                                                ? Container(
                                                    alignment: Alignment.center,
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = int.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    0));
                                                        var val = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            MercadoPago(
                                                                              from: '1',
                                                                            )));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.35,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/mercadopago.png'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                            (walletBalance['cash_free'] == true)
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: media.width *
                                                            0.025),
                                                    alignment: Alignment.center,
                                                    width: media.width * 0.7,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        addMoney = double.parse(
                                                            userRequestData['requestBill']
                                                                        ['data']
                                                                    [
                                                                    'total_amount']
                                                                .toStringAsFixed(
                                                                    2));
                                                        var val = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            CashFreePage(
                                                                              from: '1',
                                                                            )));
                                                        if (val != null) {
                                                          if (val) {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _choosePayment =
                                                                  false;
                                                            });
                                                            var val =
                                                                await getUserDetails();
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width:
                                                            media.width * 0.25,
                                                        height:
                                                            media.width * 0.125,
                                                        decoration: const BoxDecoration(
                                                            image: DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/cashfree-icon.jpeg'),
                                                                fit: BoxFit
                                                                    .contain)),
                                                      ),
                                                    ))
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ))
                      : Container(),

                  //choose payment method
                  (_choosePaymentMethod == true)
                      ? Positioned(
                          top: 0,
                          child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: SizedBox(
                                  height: media.height * 1,
                                  width: media.width * 1,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: media.width * 0.9,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _choosePaymentMethod =
                                                        false;
                                                  });
                                                },
                                                child: Container(
                                                  height: media.width * 0.1,
                                                  width: media.width * 0.1,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: page),
                                                  child: Icon(
                                                    Icons.cancel_outlined,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        Container(
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                              color: page,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    languages[choosenLanguage]
                                                        ['text_paymentmethod'],
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            twenty,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textColor),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        media.height * 0.015,
                                                  ),
                                                  Text(
                                                    languages[choosenLanguage][
                                                        'text_choose_paynoworlater'],
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            twelve,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textColor),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        media.height * 0.015,
                                                  ),
                                                  Column(
                                                    children:
                                                        userRequestData[
                                                                'payment_type']
                                                            .toString()
                                                            .split(',')
                                                            .toList()
                                                            .asMap()
                                                            .map((i, value) {
                                                              return MapEntry(
                                                                  i,
                                                                  (userRequestData['payment_type']
                                                                              .toString()
                                                                              .split(',')
                                                                              .toList()[i] !=
                                                                          'wallet')
                                                                      ? InkWell(
                                                                          onTap:
                                                                              () {
                                                                            setState(() {
                                                                              payingVia = i;
                                                                              myPaymentMethod = userRequestData['payment_type'].toString().split(',').toList()[i].toString();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                EdgeInsets.all(media.width * 0.02),
                                                                            width:
                                                                                media.width * 0.9,
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Row(
                                                                                  children: [
                                                                                    SizedBox(
                                                                                      width: media.width * 0.06,
                                                                                      child: (userRequestData['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                          ? Image.asset(
                                                                                              'assets/images/cash.png',
                                                                                              fit: BoxFit.contain,
                                                                                            )
                                                                                          : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                              ? Image.asset(
                                                                                                  'assets/images/wallet.png',
                                                                                                  fit: BoxFit.contain,
                                                                                                )
                                                                                              : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                  ? Image.asset(
                                                                                                      'assets/images/card.png',
                                                                                                      fit: BoxFit.contain,
                                                                                                    )
                                                                                                  : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                      ? Image.asset(
                                                                                                          'assets/images/upi.png',
                                                                                                          fit: BoxFit.contain,
                                                                                                        )
                                                                                                      : Container(),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.05,
                                                                                    ),
                                                                                    Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          userRequestData['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: textColor),
                                                                                        ),
                                                                                        Text(
                                                                                          (userRequestData['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                              ? languages[choosenLanguage]['text_paycash']
                                                                                              : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                  ? languages[choosenLanguage]['text_paywallet']
                                                                                                  : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                      ? languages[choosenLanguage]['text_paycard']
                                                                                                      : (userRequestData['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                          ? languages[choosenLanguage]['text_payupi']
                                                                                                          : '',
                                                                                          style: GoogleFonts.roboto(fontSize: media.width * ten, color: textColor),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                    Expanded(
                                                                                        child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Container(
                                                                                          height: media.width * 0.05,
                                                                                          width: media.width * 0.05,
                                                                                          decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: textColor, width: 1.2)),
                                                                                          alignment: Alignment.center,
                                                                                          child: (myPaymentMethod == userRequestData['payment_type'].toString().split(',').toList()[i].toString()) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)) : Container(),
                                                                                        )
                                                                                      ],
                                                                                    ))
                                                                                  ],
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Container());
                                                            })
                                                            .values
                                                            .toList(),
                                                  ),
                                                  SizedBox(
                                                    height: media.height * 0.02,
                                                  ),
                                                  if (_error != '')
                                                    Container(
                                                      alignment:
                                                          Alignment.center,
                                                      padding: EdgeInsets.only(
                                                          bottom: media.height *
                                                              0.02),
                                                      child: Text(
                                                        _error,
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    Colors.red),
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  Button(
                                                      onTap: () async {
                                                        if ((myPaymentMethod ==
                                                                    'cash' &&
                                                                userRequestData[
                                                                        'payment_opt'] !=
                                                                    '1') ||
                                                            (myPaymentMethod ==
                                                                    'card' &&
                                                                userRequestData[
                                                                        'payment_opt'] !=
                                                                    '0')) {
                                                          if (myPaymentMethod !=
                                                              '') {
                                                            setState(() {
                                                              _isLoading = true;
                                                              _error = '';
                                                            });
                                                            var val =
                                                                await paymentMethod(
                                                                    myPaymentMethod);
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            } else if (val ==
                                                                'success') {
                                                              if (myPaymentMethod ==
                                                                  'card') {
                                                                if (walletBalance
                                                                    .isEmpty) {
                                                                  var val =
                                                                      await getWalletHistory();
                                                                  if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                }
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                  _choosePayment =
                                                                      true;
                                                                  _choosePaymentMethod =
                                                                      false;
                                                                });
                                                              } else {
                                                                _choosePaymentMethod =
                                                                    false;
                                                              }
                                                            } else {
                                                              _error = val
                                                                  .toString();
                                                            }

                                                            setState(() {
                                                              myPaymentMethod =
                                                                  '';
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        } else {
                                                          setState(() {
                                                            _choosePaymentMethod =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_confirm']),
                                                ]))
                                      ]))))
                      : Container(),

                  if (_isLoading == true) const Positioned(child: Loading())
                ],
              );
            }),
      ),
    );
  }
}
