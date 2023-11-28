import 'dart:convert';

import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tagxiuser/pages/NavigatorPages/editprofile.dart';
import 'package:tagxiuser/pages/NavigatorPages/history.dart';
import 'package:tagxiuser/pages/NavigatorPages/makecomplaint.dart';
import 'package:tagxiuser/pages/login/otp_page.dart';
import 'package:tagxiuser/pages/onTripPage/booking_confirmation.dart';
import 'package:tagxiuser/pages/login/get_started.dart';
import 'package:tagxiuser/pages/login/login.dart';
import 'package:tagxiuser/pages/onTripPage/map_page.dart';
import 'package:tagxiuser/pages/onTripPage/review_page.dart';
import 'package:tagxiuser/pages/referralcode/referral_code.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tagxiuser/styles/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;

//base url
String url =
    'https://taxi.hostk.com/'; //add '/' at the end of the url as 'https://yourwebsite.com/'
String mapkey = 'AIzaSyC9sBlFf7ThU407w6iYhW4i4HmGHP7dkLY';

List tripStops = [];

//check internet connection

checkInternetConnection() {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

getDetailsOfDevice() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (isDarkTheme == true) {
      rootBundle.loadString('assets/dark.json').then((value) {
        mapStyle = value;
      });
    } else {
      rootBundle.loadString('assets/map_style_black.json').then((value) {
        mapStyle = value;
      });
    }
    pref = await SharedPreferences.getInstance();
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

// dynamic timerLocation;
dynamic locationAllowed;

bool positionStreamStarted = false;
StreamSubscription<Position>? positionStream;

LocationSettings locationSettings = (platform == TargetPlatform.android)
    ? AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      )
    : AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 50,
      );

positionStreamData() {
  positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
    positionStream = null;
    positionStream?.cancel();
  }).listen((Position? position) {
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
    } else {
      positionStream!.cancel();
    }
  });
}

//validate email already exist

validateEmail() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile'),
        body: {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'Amharic', 'code': 'am'},
  {'name': 'Arabic', 'code': 'ar'},
  {'name': 'Basque', 'code': 'eu'},
  {'name': 'Bengali', 'code': 'bn'},
  {'name': 'English (UK)', 'code': 'en-GB'},
  {'name': 'Portuguese (Brazil)', 'code': 'pt-BR'},
  {'name': 'Bulgarian', 'code': 'bg'},
  {'name': 'Catalan', 'code': 'ca'},
  {'name': 'Cherokee', 'code': 'chr'},
  {'name': 'Croatian', 'code': 'hr'},
  {'name': 'Czech', 'code': 'cs'},
  {'name': 'Danish', 'code': 'da'},
  {'name': 'Dutch', 'code': 'nl'},
  {'name': 'English (US)', 'code': 'en'},
  {'name': 'Estonian', 'code': 'et'},
  {'name': 'Filipino', 'code': 'fil'},
  {'name': 'Finnish', 'code': 'fi'},
  {'name': 'French', 'code': 'fr'},
  {'name': 'German', 'code': 'de'},
  {'name': 'Greek', 'code': 'el'},
  {'name': 'Gujarati', 'code': 'gu'},
  {'name': 'Hebrew', 'code': 'iw'},
  {'name': 'Hindi', 'code': 'hi'},
  {'name': 'Hungarian', 'code': 'hu'},
  {'name': 'Icelandic', 'code': 'is'},
  {'name': 'Indonesian', 'code': 'id'},
  {'name': 'Italian', 'code': 'it'},
  {'name': 'Japanese', 'code': 'ja'},
  {'name': 'Kannada', 'code': 'kn'},
  {'name': 'Korean', 'code': 'ko'},
  {'name': 'Latvian', 'code': 'lv'},
  {'name': 'Lithuanian', 'code': 'lt'},
  {'name': 'Malay', 'code': 'ms'},
  {'name': 'Malayalam', 'code': 'ml'},
  {'name': 'Marathi', 'code': 'mr'},
  {'name': 'Norwegian', 'code': 'no'},
  {'name': 'Polish', 'code': 'pl'},
  {
    'name': 'Portuguese (Portugal)',
    'code': 'pt' //pt-PT
  },
  {'name': 'Romanian', 'code': 'ro'},
  {'name': 'Russian', 'code': 'ru'},
  {'name': 'Serbian', 'code': 'sr'},
  {
    'name': 'Chinese (PRC)',
    'code': 'zh' //zh-CN
  },
  {'name': 'Slovak', 'code': 'sk'},
  {'name': 'Slovenian', 'code': 'sl'},
  {'name': 'Spanish', 'code': 'es'},
  {'name': 'Swahili', 'code': 'sw'},
  {'name': 'Swedish', 'code': 'sv'},
  {'name': 'Tamil', 'code': 'ta'},
  {'name': 'Telugu', 'code': 'te'},
  {'name': 'Thai', 'code': 'th'},
  {'name': 'Chinese (Taiwan)', 'code': 'zh-TW'},
  {'name': 'Turkish', 'code': 'tr'},
  {'name': 'Urdu', 'code': 'ur'},
  {'name': 'Ukrainian', 'code': 'uk'},
  {'name': 'Vietnamese', 'code': 'vi'},
  {'name': 'Welsh', 'code': 'cy'},
];

//getting country code

List countries = [];
getCountryCode() async {
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data'];
      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

phoneAuth(String phone) async {
  try {
    credentials = null;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        credentials = credential;
        valueNotifierHome.incrementNotifier();
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          debugPrint('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verId = verificationId;
        resendTokenId = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

sendOTPtoEmail(String email) async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/send-mail-otp'), body: {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

emailVerify(String email, otpNumber) async {
  dynamic val;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/validate-email-otp'),
        body: {"email": email, "otp": otpNumber});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        val = 'success';
      } else {
        debugPrint(response.body);
        val = 'failed';
      }
    }
    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//get local bearer token
String lastNotification = '';

getLocalData() async {
  dynamic result;
  bearerToken.clear;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (pref.containsKey('lastNotification')) {
      lastNotification = pref.getString('lastNotification');
    }
    if (pref.containsKey('autoAddress')) {
      var val = pref.getString('autoAddress');
      storedAutoAddress = jsonDecode(val);
    }
    if (pref.containsKey('choosenLanguage')) {
      choosenLanguage = pref.getString('choosenLanguage');
      languageDirection = pref.getString('languageDirection');
      if (choosenLanguage.isNotEmpty) {
        if (pref.containsKey('Bearer')) {
          var tokens = pref.getString('Bearer');
          if (tokens != null) {
            bearerToken.add(BearerClass(type: 'Bearer', token: tokens));

            var responce = await getUserDetails();
            if (responce == true) {
              result = '3';
            } else if (responce == false) {
              result = '2';
            }
          } else {
            result = '2';
          }
        } else {
          result = '2';
        }
      } else {
        result = '1';
      }
    } else {
      result = '1';
    }
    if (pref.containsKey('isDarkTheme')) {
      isDarkTheme = pref.getBool('isDarkTheme');
      if (isDarkTheme == true) {
        page = Colors.black;
        textColor = Colors.white;
        buttonColor = Colors.white;
        loaderColor = Colors.white;
        buttonText = Colors.black;
      } else {
        page = Colors.white;
        textColor = Colors.black;
        buttonColor = theme;
        loaderColor = theme;
        buttonText = const Color(0xffFFFFFF);
      }
      if (isDarkTheme == true) {
        rootBundle.loadString('assets/dark.json').then((value) {
          mapStyle = value;
        });
      } else {
        rootBundle.loadString('assets/map_style_black.json').then((value) {
          mapStyle = value;
        });
      }
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//register user

List<BearerClass> bearerToken = <BearerClass>[];

registerUser() async {
  bearerToken.clear();
  dynamic result;
  try {
    var token = await FirebaseMessaging.instance.getToken();
    var fcm = token.toString();
    final response =
        http.MultipartRequest('POST', Uri.parse('${url}api/v1/user/register'));
    response.headers.addAll({'Content-Type': 'application/json'});
    if (proImageFile1 != null) {
      response.files.add(
          await http.MultipartFile.fromPath('profile_picture', proImageFile1));
    }
    response.fields.addAll({
      "name": name,
      "mobile": phnumber,
      "email": email,
      "device_token": fcm,
      "country": countries[phcode]['code'],
      "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
      'lang': choosenLanguage,
      'email_confirmed': (value == 0) ? '0' : '1'
    });

    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    if (respon.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);

      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      pref.setString('Bearer', bearerToken[0].token);
      await getlangid();
      await getUserDetails();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
      result = 'true';
    } else if (respon.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(respon.body);
      result = jsonDecode(respon.body)['message'];
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//update referral code

updateReferral() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/update/user/referral'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({"refferal_code": referralCode}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'true';
      } else {
        debugPrint(response.body);
        result = 'false';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//call firebase otp

otpCall() async {
  dynamic result;
  try {
    var otp = await FirebaseDatabase.instance.ref().child('call_FB_OTP').get();
    result = otp;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no Internet';
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

//request notification
List notificationHistory = [];
Map<String, dynamic> notificationHistoryPage = {};

getnotificationHistory() async {
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/get-notification'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      notificationHistory = jsonDecode(response.body)['data'];
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

getNotificationPages(id) async {
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/get-notification?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        notificationHistory.add(element);
      });
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

//delete notification
deleteNotification(id) async {
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/delete-notification/$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

sharewalletfun({mobile, role, amount}) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/wallet/transfer-money-from-wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bearerToken[0].token}',
        },
        body: jsonEncode({'mobile': mobile, 'role': role, 'amount': amount}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}
// verify user already exist

verifyUser(String number) async {
  dynamic val;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile-for-login'),
        body: (value == 0)
            ? {"mobile": number}
            : {"email": email, "otp": otpNumber});
    // print(value);
    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['success'];

      if (val == true) {
        var check = await userLogin();
        if (check == true) {
          var uCheck = await getUserDetails();
          val = uCheck;
        } else {
          val = check;
        }
      } else {
        val = false;
      }
    } else {
      debugPrint(response.body);
      val = jsonDecode(response.body)['message'];
    }

    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

bool navigateToPhone = false;

//user login
userLogin() async {
  bearerToken.clear();
  dynamic result;
  try {
    var token = await FirebaseMessaging.instance.getToken();
    var fcm = token;
    var response = await http.post(Uri.parse('${url}api/v1/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: (value == 0)
            ? jsonEncode({
                "mobile": phnumber,
                'device_token': fcm.toString(),
                "login_by":
                    (platform == TargetPlatform.android) ? 'android' : 'ios',
              })
            : jsonEncode({
                "email": email,
                "otp": otpNumber,
                'device_token': fcm.toString(),
                "login_by":
                    (platform == TargetPlatform.android) ? 'android' : 'ios',
              }));
    // print(value);
    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      await getlangid();
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

Map<String, dynamic> userDetails = {};
List favAddress = [];
dynamic _version;
bool updateAvailable = false;
dynamic package;

checkVersion() async {
  package = await PackageInfo.fromPlatform();
  try {
    if (platform == TargetPlatform.android) {
      _version = await FirebaseDatabase.instance
          .ref()
          .child('user_android_version')
          .get();
    } else {
      _version =
          await FirebaseDatabase.instance.ref().child('user_ios_version').get();
    }
    if (_version.value != null) {
      var version = _version.value.toString().split('.');
      var packages = package.version.toString().split('.');

      for (var i = 0; i < version.length || i < packages.length; i++) {
        if (i < version.length && i < packages.length) {
          if (int.parse(packages[i]) < int.parse(version[i])) {
            updateAvailable = true;
            valueNotifierHome.incrementNotifier();

            break;
          } else if (int.parse(packages[i]) > int.parse(version[i])) {
            updateAvailable = false;

            break;
          }
        } else if (i >= version.length && i < packages.length) {
          updateAvailable = false;

          break;
        } else if (i < version.length && i >= packages.length) {
          updateAvailable = true;
          valueNotifierHome.incrementNotifier();

          break;
        }
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}

//user current state
getUserDetails() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}'
      },
    );
    if (response.statusCode == 200) {
      userDetails =
          Map<String, dynamic>.from(jsonDecode(response.body)['data']);
      if (userDetails['notifications_count'] != 0 &&
          userDetails['notifications_count'] != null) {
        valueNotifierNotification.incrementNotifier();
      }
      favAddress = userDetails['favouriteLocations']['data'];
      sosData = userDetails['sos']['data'];
      if (userDetails['onTripRequest'] != null) {
        addressList.clear();
        tripStops =
            userDetails['onTripRequest']['data']['requestStops']['data'];
        userRequestData = userDetails['onTripRequest']['data'];
        addressList.add(AddressList(
            id: 'pickup',
            // type: 'pickup',
            address: userRequestData['pick_address'],
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            pickup: true));
        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 1).toString(),
                type: 'drop',
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                pickup: false));
          }
        } else if (userDetails['onTripRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              address: userRequestData['drop_address'],
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              pickup: false));
        }

        if (userRequestData['accepted_at'] != null) {
          getCurrentMessages();
        }
        if (userRequestData.isNotEmpty) {
          if (rideStreamUpdate == null ||
              rideStreamUpdate?.isPaused == true ||
              rideStreamStart == null ||
              rideStreamStart?.isPaused == true) {
            streamRide();
          }
        } else {
          if (rideStreamUpdate != null ||
              rideStreamUpdate?.isPaused == false ||
              rideStreamStart != null ||
              rideStreamStart?.isPaused == false) {
            rideStreamUpdate?.cancel();
            rideStreamUpdate = null;
            rideStreamStart?.cancel();
            rideStreamStart = null;
          }
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else if (userDetails['metaRequest'] != null) {
        addressList.clear();
        tripStops.clear();
        userRequestData = userDetails['metaRequest']['data'];
        tripStops = userDetails['metaRequest']['data']['requestStops']['data'];
        addressList.add(AddressList(
            id: 'pickup',
            address: userRequestData['pick_address'],
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            pickup: true));

        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 1).toString(),
                type: 'drop',
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                pickup: false));
          }
        } else if (userDetails['metaRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              address: userRequestData['drop_address'],
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              pickup: false));
        }

        if (requestStreamStart == null ||
            requestStreamStart?.isPaused == true ||
            requestStreamEnd == null ||
            requestStreamEnd?.isPaused == true) {
          streamRequest();
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else {
        chatList.clear();
        userRequestData = {};
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        rideStreamUpdate?.cancel();
        rideStreamStart?.cancel();
        requestStreamEnd = null;
        requestStreamStart = null;
        rideStreamUpdate = null;
        rideStreamStart = null;
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      }
      if (userDetails['active'] == false) {
        isActive = 'false';
      } else {
        isActive = 'true';
      }
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }

  return result;
}

class BearerClass {
  final String type;
  final String token;
  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

//sound
AudioCache audioPlayer = AudioCache();
AudioPlayer audioPlayers = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

geoCoding(double lat, double lng) async {
  dynamic result;
  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'));

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body);
      result = val['results'][0]['formatted_address'];
    } else {
      debugPrint(response.body);
      result = '';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//lang
getlangid() async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/user/update-my-lang'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
    }, body: {
      'lang': choosenLanguage,
    });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get address auto fill data

List storedAutoAddress = [];
List addAutoFill = [];

getAutoAddress(input, sessionToken, lat, lng) async {
  dynamic response;
  var countryCode = userDetails['country_code'];
  try {
    if (userDetails['enable_country_restrict_on_map'] == '1' &&
        userDetails['country_code'] != null) {
      response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&location=$lat%2C$lng&radius=2000&components=country:$countryCode&key=$mapkey&sessiontoken=$sessionToken'));
    } else {
      response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&key=$mapkey&sessiontoken=$sessionToken'));
    }
    if (response.statusCode == 200) {
      addAutoFill = jsonDecode(response.body)['predictions'];
      // ignore: avoid_function_literals_in_foreach_calls
      addAutoFill.forEach((element) {
        if (storedAutoAddress
            .where((e) =>
                e['description'].toString().toLowerCase() ==
                element['description'].toString().toLowerCase())
            .isEmpty) {
          storedAutoAddress.add(element);
        }
      });
      pref.setString('autoAddress', jsonEncode(storedAutoAddress).toString());
      valueNotifierHome.incrementNotifier();
    } else {
      debugPrint(response.body);
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//geocodeing location

geoCodingForLatLng(placeid) async {
  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeid&key=$mapkey'));

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['result']['geometry']['location'];
      center = LatLng(val['lat'], val['lng']);
    } else {
      debugPrint(response.body);
    }
    return center;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//pickup drop address list

class AddressList {
  String address;
  LatLng latlng;
  String? id;
  dynamic type;
  dynamic name;
  dynamic number;
  dynamic instructions;
  dynamic pickup;

  AddressList(
      {this.id,
      required this.address,
      required this.latlng,
      this.type,
      this.name,
      this.number,
      this.pickup,
      this.instructions});
}

//drop stops list
List<DropStops> dropStopList = <DropStops>[];

class DropStops {
  String order;
  double latitude;
  double longitude;

  String address;
  dynamic pickup;
  DropStops(
      {required this.order,
      required this.latitude,
      required this.longitude,
      required this.address,
      this.pickup});

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'for_pickup': pickup
      };
}
//get polylines

List<LatLng> polyList = [];
getPolylines() async {
  polyList.clear();
  String pickLat = '';
  String pickLng = '';
  String dropLat = '';
  String dropLng = '';
  for (var i = 1; i < addressList.length; i++) {
    pickLat = addressList[i - 1].latlng.latitude.toString();
    pickLng = addressList[i - 1].latlng.longitude.toString();
    dropLat = addressList[i].latlng.latitude.toString();
    dropLng = addressList[i].latlng.longitude.toString();

    try {
      var response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&transit_mode=bus&mode=driving&key=$mapkey'));
      if (response.statusCode == 200) {
        var steps = jsonDecode(response.body)['routes'][0]['overview_polyline']
            ['points'];
        decodeEncodedPolyline(steps);
      } else {
        debugPrint(response.body);
      }
    } catch (e) {
      if (e is SocketException) {
        internet = false;
      }
    }
  }
  return polyList;
}

getPolylineshistory({pickLat, pickLng, dropLat, dropLng}) async {
  polyList.clear();

  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&transit_mode=bus&mode=driving&key=$mapkey'));
    if (response.statusCode == 200) {
      var steps =
          jsonDecode(response.body)['routes'][0]['overview_polyline']['points'];
      decodeEncodedPolylineHistory(steps);
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return polyList;
}

//polyline decode

Set<Polyline> polylineHistory = {};

List<PointLatLng> decodeEncodedPolylineHistory(String encoded) {
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  polylineHistory.clear();

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    polyList.add(p);
  }

  polylineHistory.add(
    Polyline(
        polylineId: const PolylineId('1'),
        color: const Color(0xffFD9898),
        visible: true,
        width: 4,
        points: polyList),
  );
  valueNotifierBook.incrementNotifier();
  return poly;
}

Set<Polyline> polyline = {};

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  polyline.clear();

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    polyList.add(p);
  }

  polyline.add(
    Polyline(
        polylineId: const PolylineId('1'),
        color: const Color(0xffFD9898),
        visible: true,
        width: 4,
        points: polyList),
  );
  valueNotifierBook.incrementNotifier();
  return poly;
}

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      // ignore: unnecessary_null_comparison
      : assert(latitude != null),
        // ignore: unnecessary_null_comparison
        assert(longitude != null),
        // ignore: unnecessary_this, prefer_initializing_formals
        this.latitude = latitude,
        // ignore: unnecessary_this, prefer_initializing_formals
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}

List etaDetails = [];

//eta request

etaRequest() async {
  dynamic result;

  try {
    print('startttttttt');
    var response = await http.post(Uri.parse('${url}api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: (addressList
                    .where((element) => element.type == 'drop')
                    .isNotEmpty &&
                dropStopList.isEmpty)
            ? jsonEncode({
                'pick_lat': (userRequestData.isNotEmpty)
                    ? userRequestData['pick_lat']
                    : addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .latitude,
                'pick_lng': (userRequestData.isNotEmpty)
                    ? userRequestData['pick_lng']
                    : addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .longitude,
                'drop_lat': (userRequestData.isNotEmpty)
                    ? userRequestData['drop_lat']
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude,
                'drop_lng': (userRequestData.isNotEmpty)
                    ? userRequestData['drop_lng']
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude,
                'ride_type': 1,
              })
            : (dropStopList.isNotEmpty &&
                    addressList
                        .where((element) => element.type == 'drop')
                        .isNotEmpty)
                ? jsonEncode({
                    'pick_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lat']
                        : addressList
                            .firstWhere((e) => e.id == 'pickup')
                            .latlng
                            .latitude,
                    'pick_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lng']
                        : addressList
                            .firstWhere((e) => e.id == 'pickup')
                            .latlng
                            .longitude,
                    'drop_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['drop_lat']
                        : addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .latitude,
                    'drop_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['drop_lng']
                        : addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .longitude,
                    'stops': jsonEncode(dropStopList),
                    'ride_type': 1,
                  })
                : jsonEncode({
                    'pick_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lat']
                        : addressList
                            .firstWhere((e) => e.id == 'pickup')
                            .latlng
                            .latitude,
                    'pick_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lng']
                        : addressList
                            .firstWhere((e) => e.id == 'pickup')
                            .latlng
                            .longitude,
                    'ride_type': 1
                  }));

    if (response.statusCode == 200) {
      print('200000000000');
      etaDetails = jsonDecode(response.body)['data'];
      print(etaDetails);
      choosenVehicle =
          etaDetails.indexWhere((element) => element['is_default'] == true);
      result = true;
      valueNotifierBook.incrementNotifier();
      print('doneeeeee');
    } else if (response.statusCode == 401) {
      print('4011111111');
      result = 'logout';
    } else {
      print('else errorrrrrrr');
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] ==
          "service not available with this location") {
        serviceNotAvailable = true;
      }
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

etaRequestWithPromo() async {
  dynamic result;
  // etaDetails.clear();
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
          'ride_type': 1,
          'promo_code': promoCode
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//rental eta request

rentalEta() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/request/list-packages'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat': (userRequestData.isNotEmpty)
              ? userRequestData['pick_lat']
              : addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng': (userRequestData.isNotEmpty)
              ? userRequestData['pick_lng']
              : addressList
                  .firstWhere((e) => e.id == 'pickup')
                  .latlng
                  .longitude,
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      result = true;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

rentalRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/request/list-packages'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'ride_type': 1,
          'promo_code': promoCode
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//calculate distance

calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}

Map<String, dynamic> userRequestData = {};

//create request

createRequest() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body:
            (addressList.where((element) => element.type == 'drop').isNotEmpty)
                ? jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .longitude,
                    'drop_lat': addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude,
                    'drop_lng': addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude,
                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                    'ride_type': 1,
                    'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'card')
                        ? 0
                        : (etaDetails[choosenVehicle]['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'cash')
                            ? 1
                            : 2,
                    'pick_address':
                        addressList.firstWhere((e) => e.id == 'pickup').address,
                    'stops': jsonEncode(dropStopList),
                    'drop_address':
                        addressList.lastWhere((e) => e.type == 'drop').address,
                    'request_eta_amount': etaDetails[choosenVehicle]['total']
                  })
                : jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.id == 'pickup')
                        .latlng
                        .longitude,
                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                    'ride_type': 1,
                    'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'card')
                        ? 0
                        : (etaDetails[choosenVehicle]['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'cash')
                            ? 1
                            : 2,
                    'pick_address':
                        addressList.firstWhere((e) => e.id == 'pickup').address,
                    'request_eta_amount': etaDetails[choosenVehicle]['total']
                  }));

    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';

      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//create request with promo code

createRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
          'drop_lng':
              addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address':
              addressList.lastWhere((e) => e.type == 'drop').address,
          'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//create request

createRequestLater() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address':
              addressList.firstWhere((e) => e.type == 'drop').address,
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//create request with promo code

createRequestLaterPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address':
              addressList.firstWhere((e) => e.type == 'drop').address,
          'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

//create rental request

createRentalRequest() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';

      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

createRentalRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

createRentalRequestLater() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

createRentalRequestLaterPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
        }));
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

List<RequestCreate> createRequestList = <RequestCreate>[];

class RequestCreate {
  dynamic pickLat;
  dynamic pickLng;
  dynamic dropLat;
  dynamic dropLng;
  dynamic vehicleType;
  dynamic rideType;
  dynamic paymentOpt;
  dynamic pickAddress;
  dynamic dropAddress;
  dynamic promoCodeId;

  RequestCreate(
      {this.pickLat,
      this.pickLng,
      this.dropLat,
      this.dropLng,
      this.vehicleType,
      this.rideType,
      this.paymentOpt,
      this.pickAddress,
      this.dropAddress,
      this.promoCodeId});

  Map<String, dynamic> toJson() => {
        'pick_lat': pickLat,
        'pick_lng': pickLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'payment_opt': paymentOpt,
        'pick_address': pickAddress,
        'drop_address': dropAddress,
        'promocode_id': promoCodeId
      };
}

//user cancel request

cancelRequest() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': userRequestData['id']}));
    if (response.statusCode == 200) {
      userCancelled = true;
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'cancelled_by_user': true});
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

cancelLaterRequest(val) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': val}));
    if (response.statusCode == 200) {
      result = 'true';
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

//user cancel request with reason

cancelRequestWithReason(reason) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'request_id': userRequestData['id'], 'reason': reason}));
    if (response.statusCode == 200) {
      cancelRequestByUser = true;
      FirebaseDatabase.instance
          .ref('requests/${userRequestData['id']}')
          .update({'cancelled_by_user': true});
      userRequestData = {};
      if (rideStreamUpdate?.isPaused == false ||
          rideStreamStart?.isPaused == false) {
        rideStreamUpdate?.cancel();
        rideStreamUpdate = null;
        rideStreamStart?.cancel();
        rideStreamStart = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

//making call to user

makingPhoneCall(phnumber) async {
  var mobileCall = 'tel:$phnumber';
  if (await canLaunchUrlString(mobileCall)) {
    await launchUrlString(mobileCall);
  } else {
    throw 'Could not launch $mobileCall';
  }
}

//cancellation reason
List cancelReasonsList = [];
cancelReason(reason) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/cancallation/reasons?arrived=$reason'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      cancelReasonsList = jsonDecode(response.body)['data'];
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

List<CancelReasonJson> cancelJson = <CancelReasonJson>[];

class CancelReasonJson {
  dynamic requestId;
  dynamic reason;

  CancelReasonJson({this.requestId, this.reason});

  Map<String, dynamic> toJson() {
    return {'request_id': requestId, 'reason': reason};
  }
}

//add user rating

userRating() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/rating'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'request_id': userRequestData['id'],
          'rating': review,
          'comment': feedback
        }));
    if (response.statusCode == 200) {
      await getUserDetails();
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//class for realtime database driver data

class NearByDriver {
  double bearing;
  String g;
  String id;
  List l;
  String updatedAt;

  NearByDriver(
      {required this.bearing,
      required this.g,
      required this.id,
      required this.l,
      required this.updatedAt});

  factory NearByDriver.fromJson(Map<String, dynamic> json) {
    return NearByDriver(
        id: json['id'],
        bearing: json['bearing'],
        g: json['g'],
        l: json['l'],
        updatedAt: json['updated_at']);
  }
}

//add favourites location

addFavLocation(lat, lng, add, name) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/add-favourite-location'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'pick_lat': lat,
          'pick_lng': lng,
          'pick_address': add,
          'address_name': name
        }));
    if (response.statusCode == 200) {
      result = true;
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//sos data
List sosData = [];

getSosData(lat, lng) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/sos/list/$lat/$lng'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      sosData = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//sos admin notification

notifyAdmin() async {
  var db = FirebaseDatabase.instance.ref();
  // var result;

  try {
    await db.child('SOS/${userRequestData['id']}').update({
      "is_driver": "0",
      "is_user": "1",
      "req_id": userRequestData['id'],
      "serv_loc_id": userRequestData['service_location_id'],
      "updated_at": ServerValue.timestamp
    });
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return true;
}

//get current ride messages

List chatList = [];

getCurrentMessages() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/chat-history/${userRequestData['id']}'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        if (chatList.where((element) => element['from_type'] == 2).length !=
            jsonDecode(response.body)['data']
                .where((element) => element['from_type'] == 2)
                .length) {
          // audioPlayer.play(audio);
        }
        chatList = jsonDecode(response.body)['data'];
        valueNotifierBook.incrementNotifier();
      }
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

//send chat

sendMessage(chat) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/send'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body:
            jsonEncode({'request_id': userRequestData['id'], 'message': chat}));
    if (response.statusCode == 200) {
      await getCurrentMessages();
      FirebaseDatabase.instance
          .ref('requests/${userRequestData['id']}')
          .update({'message_by_user': chatList.length});
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

//message seen

messageSeen() async {
  dynamic result;
  var response = await http.post(Uri.parse('${url}api/v1/request/seen'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'request_id': userRequestData['id']}));
  if (response.statusCode == 200) {
    getCurrentMessages();
    result = 'success';
  } else if (response.statusCode == 401) {
    result = 'logout';
  } else {
    debugPrint(response.body);
    result = 'failed';
  }
  return result;
}

//add sos

addSos(name, number) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/common/sos/store'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': name, 'number': number}));

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//remove sos

deleteSos(id) async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/common/sos/delete/$id'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//open url in browser

openBrowser(browseUrl) async {
  if (await canLaunchUrlString(browseUrl)) {
    await launchUrlString(browseUrl);
  } else {
    throw 'Could not launch $browseUrl';
  }
}

//get faq
List faqData = [];
Map<String, dynamic> myFaqPage = {};

getFaqData(lat, lng) async {
  dynamic result;
  myFaqPage.clear();
  try {
    var response = await http
        .get(Uri.parse('${url}api/v1/common/faq/list/$lat/$lng'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      faqData = jsonDecode(response.body)['data'];
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
    return result;
  }
}

getFaqPages(id) async {
  dynamic result;
  try {
    var response =
        await http.get(Uri.parse('${url}api/v1/common/faq/list/$id'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['data'];
      val.forEach((element) {
        faqData.add(element);
      });
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierHome.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
    return result;
  }
}

//remove fav address

removeFavAddress(id) async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/user/delete-favourite-location/$id'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//get user referral

Map<String, dynamic> myReferralCode = {};
getReferral() async {
  dynamic result;
  try {
    var response =
        await http.get(Uri.parse('${url}api/v1/get/referral'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      result = 'success';
      myReferralCode = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//user logout

userLogout() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/logout'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      pref.remove('Bearer');
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//request history
List myHistory = [];
Map<String, dynamic> myHistoryPage = {};

getHistory(id) async {
  dynamic result;

  try {
    var response = await http.get(Uri.parse('${url}api/v1/request/history?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      myHistory = jsonDecode(response.body)['data'];
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getHistoryPages(id) async {
  dynamic result;

  try {
    var response = await http.get(Uri.parse('${url}api/v1/request/history?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        myHistory.add(element);
      });
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get wallet history

Map<String, dynamic> walletBalance = {};
List walletHistory = [];
Map<String, dynamic> walletPages = {};

getWalletHistory() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/wallet/history'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      walletHistory = walletBalance['wallet_history']['data'];
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getWalletHistoryPage(page) async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/wallet/history?page=$page'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      List list = walletBalance['wallet_history']['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        walletHistory.add(element);
      });
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get client token for braintree

getClientToken() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/client/token'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//stripe payment

Map<String, dynamic> stripeToken = {};

getStripePayment(money) async {
  dynamic results;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/payment/stripe/intent'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'amount': money}));
    if (response.statusCode == 200) {
      results = 'success';
      stripeToken = jsonDecode(response.body)['data'];
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

//stripe add money

addMoneyStripe(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/stripe/add/money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//stripe pay money

payMoneyStripe(nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/stripe/make-payment-for-ride'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'request_id': userRequestData['id'], 'payment_id': nonce}));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//paystack payment
Map<String, dynamic> paystackCode = {};

getPaystackPayment(body) async {
  dynamic results;
  paystackCode.clear();
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/payment/paystack/initialize'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: body);
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == false) {
        results = jsonDecode(response.body)['message'];
      } else {
        results = 'success';
        paystackCode = jsonDecode(response.body)['data'];
      }
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

addMoneyPaystack(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/paystack/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      paystackCode.clear();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//flutterwave

addMoneyFlutterwave(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/flutter-wave/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//razorpay

razorpayCreateOrder(amount, publishkey, secretkey) async {
  dynamic result;
  String basicAuth =
      'Basic ${base64Encode(utf8.encode('$publishkey:$secretkey'))}';
  try {
    var response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'amount': amount,
          "currency": walletBalance['currency_code'],
          "receipt":
              'user_${userDetails['id'].toString()}_${DateTime.now().toString()}'
        }));
    if (response.statusCode == 200) {
      result = jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    } else {
      result = 'failure';
    }
  }
  return result;
}

addMoneyRazorpay(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/razerpay/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//cashfree

Map<String, dynamic> cftToken = {};

getCfToken(money, currency) async {
  cftToken.clear();
  cfSuccessList.clear();
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/cashfree/generate-cftoken'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'order_amount': money, 'order_currency': currency}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == 'OK') {
        cftToken = jsonDecode(response.body);
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

Map<String, dynamic> cfSuccessList = {};

cashFreePaymentSuccess() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/cashfree/add-money-to-wallet-webhooks'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'orderId': cfSuccessList['orderId'],
          'orderAmount': cfSuccessList['orderAmount'],
          'referenceId': cfSuccessList['referenceId'],
          'txStatus': cfSuccessList['txStatus'],
          'paymentMode': cfSuccessList['paymentMode'],
          'txMsg': cfSuccessList['txMsg'],
          'txTime': cfSuccessList['txTime'],
          'signature': cfSuccessList['signature']
        }));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
        await getWalletHistory();
        await getUserDetails();
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//edit user profile

updateProfile(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ${bearerToken[0].token}'});
    response.files
        .add(await http.MultipartFile.fromPath('profile_picture', imageFile));
    response.fields['email'] = email;
    response.fields['name'] = name;
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

updateProfileWithoutImage(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ${bearerToken[0].token}'});
    response.fields['email'] = email;
    response.fields['name'] = name;
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

//internet true
internetTrue() {
  internet = true;
  valueNotifierHome.incrementNotifier();
}

//make complaint

List generalComplaintList = [];
getGeneralComplaint(type) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/complaint-titles?complaint_type=$type'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      generalComplaintList = jsonDecode(response.body)['data'];
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

makeGeneralComplaint() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

makeRequestComplaint() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
              'request_id': myHistory[selectedHistory]['id']
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//requestStream
StreamSubscription<DatabaseEvent>? requestStreamStart;
StreamSubscription<DatabaseEvent>? requestStreamEnd;
bool userCancelled = false;

streamRequest() {
  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;
  requestStreamStart = FirebaseDatabase.instance
      .ref('request-meta')
      .child(userRequestData['id'])
      .onChildRemoved
      .handleError((onError) {
    requestStreamStart?.cancel();
  }).listen((event) async {
    getUserDetails();
    requestStreamEnd?.cancel();
    requestStreamStart?.cancel();
  });
}

StreamSubscription<DatabaseEvent>? rideStreamStart;
StreamSubscription<DatabaseEvent>? rideStreamUpdate;

streamRide() {
  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;
  rideStreamUpdate = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildChanged
      .handleError((onError) {
    rideStreamUpdate?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'trip_start' ||
        event.snapshot.key.toString() == 'trip_arrived' ||
        event.snapshot.key.toString() == 'is_completed' ||
        event.snapshot.key.toString() == 'modified_by_driver') {
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      getUserDetails();
    }
  });

  rideStreamStart = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildAdded
      .handleError((onError) {
    rideStreamStart?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'modified_by_driver') {
      getUserDetails();
    }
  });
}

userDelete() async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/user/delete-user-account'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//ccavenue

var ccUrl = '';
getCcavenuePayment(body) async {
  dynamic results;
  ccUrl = '';
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/payment/ccavenue/initialize'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: body);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      ccUrl =
          'https://secure.ccavenue.com/transaction.do?command=initiateTransaction&encRequest=${data['enc_val']}&access_code=${data['access_code']}';

      results = 'success';
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

paymentMethod(payment) async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/user/payment-method'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'request_id': userRequestData['id'],
              'payment_opt': (payment == 'card')
                  ? 0
                  : (payment == 'cash')
                      ? 1
                      : (payment == 'wallet')
                          ? 2
                          : 4
            }));
    if (response.statusCode == 200) {
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'modified_by_user': ServerValue.timestamp});
      await getUserDetails();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

String isemailmodule = '1';
getOwnermodule() async {
  dynamic res;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/common/modules'),
    );

    if (response.statusCode == 200) {
      isemailmodule = jsonDecode(response.body)['enable_email_otp'];

      res = 'success';
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      res = 'no internet';
    }
  }

  return res;
}
