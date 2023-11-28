import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxiuser/functions/functions.dart';
import 'package:tagxiuser/functions/geohash.dart';
import 'package:tagxiuser/pages/chatPage/chat_page.dart';
import 'package:tagxiuser/pages/login/login.dart';
import 'package:tagxiuser/pages/onTripPage/invoice.dart';
import 'package:tagxiuser/pages/loadingPage/loading.dart';
import 'package:tagxiuser/pages/onTripPage/map_page.dart';
import 'package:tagxiuser/pages/noInternet/nointernet.dart';
import 'package:tagxiuser/styles/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tagxiuser/translations/translation.dart';
import 'package:tagxiuser/widgets/widgets.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:share_plus/share_plus.dart';

import 'drop_loc_select.dart';

// ignore: must_be_immutable
class BookingConfirmation extends StatefulWidget {
  // const BookingConfirmation({Key? key}) : super(key: key);
  dynamic type;

  //type = 1 is rental ride and type = null is regular ride
  BookingConfirmation({Key? key, this.type}) : super(key: key);

  @override
  State<BookingConfirmation> createState() => _BookingConfirmationState();
}

bool serviceNotAvailable = false;
String promoCode = '';
dynamic promoStatus;
dynamic choosenVehicle = 0;
int payingVia = 0;
dynamic timing;
dynamic mapPadding = 0.0;

bool noDriverFound = false;
var driverData = {};
var driversData = [];
dynamic choosenDateTime;
bool lowWalletBalance = false;
bool tripReqError = false;
List rentalOption = [];
int rentalChoosenOption = 0;
Animation<double>? _animation;

class _BookingConfirmationState extends State<BookingConfirmation>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  TextEditingController promoKey = TextEditingController();
  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();
  GlobalKey iconDistanceKey = GlobalKey();
  final Map minutes = {};
  List myMarker = [];
  Map myBearings = {};
  String _cancelReason = '';
  dynamic _controller;
  late PermissionStatus permission;
  Location location = Location();
  bool _locationDenied = false;
  bool _isLoading = false;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  dynamic pinLocationIcon;
  dynamic pinLocationIcon2;
  dynamic animationController;
  bool _ontripBottom = false;
  bool _cancelling = false;
  bool _choosePayment = false;
  String _cancelCustomReason = '';
  dynamic timers;
  bool _dateTimePicker = false;
  bool _rideLaterSuccess = false;
  bool _confirmRideLater = false;
  bool showSos = false;
  bool notifyCompleted = false;
  bool _showInfo = false;
  dynamic _showInfoInt;
  dynamic _dist;
  String _cancellingError = '';
  bool dropConfirmed = false;
  var iconDropKeys = {};
  bool currentpage = true;
  List gesture = [];
  dynamic start;
  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    promoCode = '';
    mapPadding = 0.0;
    payingVia = 0;
    promoStatus = null;
    serviceNotAvailable = false;
    tripReqError = false;
    myBearings.clear();
    noDriverFound = false;
    etaDetails.clear();
    currentpage = true;

    getLocs();

    super.initState();
  }

  bool islowwalletbalance = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      getUserDetails();
      if (timers == null &&
          userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        timer();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    if (timers != null) {
      timers.cancel;
    }
    _controller?.dispose();
    _controller = null;

    animationController?.dispose();

    super.dispose();
  }

//running timer
  timer() {
    timers?.cancel();
    timers = null;
    timing = userRequestData['maximum_time_for_find_drivers_for_regular_ride'];

    if (mounted) {
      timers = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (timing != null) {
          if (userRequestData.isNotEmpty &&
              userDetails['accepted_at'] == null &&
              timing > 0) {
            timing--;
            valueNotifierBook.incrementNotifier();
          } else if (userRequestData.isNotEmpty &&
              userRequestData['accepted_at'] == null &&
              timing == 0) {
            var val = await cancelRequest();
            if (val == 'logout') {
              navigateLogout();
            }
            setState(() {
              noDriverFound = true;
            });

            timers.cancel();
          } else {
            timers.cancel();
          }
        } else {
          timer.cancel();
          timing = null;
        }
      });
    }
  }

//create icon

  _capturePng(GlobalKey iconKeys) async {
    dynamic bitmap;

    try {
      RenderRepaintBoundary boundary =
      iconKeys.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      bitmap = BitmapDescriptor.fromBytes(pngBytes);
      // return pngBytes;
    } catch (e) {
      debugPrint(e.toString());
    }
    return bitmap;
  }

  addDropMarker() async {
    for (var i = 1; i < addressList.length; i++) {
      var testIcon = await _capturePng(iconDropKeys[i]);
      if (testIcon != null) {
        setState(() {
          myMarker.add(Marker(
              markerId: MarkerId((i + 1).toString()),
              icon: testIcon,
              position: addressList[i].latlng));
        });
      }
    }

    if (widget.type != 1) {
      LatLngBounds bound;
      if (userRequestData.isNotEmpty) {
        if (userRequestData['pick_lat'] > userRequestData['drop_lat'] &&
            userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lat'] > userRequestData['drop_lat']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']));
        } else {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']));
        }
      } else {
        if (addressList
            .firstWhere((element) => element.id == 'pickup')
            .latlng
            .latitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .latitude &&
            addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                .longitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .longitude) {
          bound = LatLngBounds(
              southwest: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng,
              northeast: addressList
                  .firstWhere((element) => element.id == 'pickup')
                  .latlng);
        } else if (addressList
            .firstWhere((element) => element.id == 'pickup')
            .latlng
            .longitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .longitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng
                      .longitude));
        } else if (addressList
            .firstWhere((element) => element.id == 'pickup')
            .latlng
            .latitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .latitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude));
        } else {
          bound = LatLngBounds(
              southwest: addressList
                  .firstWhere((element) => element.id == 'pickup')
                  .latlng,
              northeast: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng);
        }
      }
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 50);
      _controller!.animateCamera(cameraUpdate);
    }
  }

  addMarker() async {
    var testIcon = await _capturePng(iconKey);
    if (testIcon != null) {
      setState(() {
        myMarker.add(Marker(
            markerId: const MarkerId('1'),
            icon: testIcon,
            position: (userRequestData.isEmpty)
                ? addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                : LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng'])));
      });
    }
  }

//add distance marker
  addDistanceMarker(length) async {
    var testIcon = await _capturePng(iconDistanceKey);
    if (testIcon != null) {
      setState(() {
        if (polyList.isNotEmpty) {
          myMarker.add(Marker(
              markerId: const MarkerId('pointdistance'),
              icon: testIcon,
              position: polyList[length],
              anchor: const Offset(0.0, 1.0)));
        }
      });
    }
  }

//add drop marker
  addPickDropMarker() async {
    addMarker();
    // Future.delayed(const Duration(milliseconds: 200), () async {
    if (userRequestData.isNotEmpty &&
        userRequestData['is_rental'] != true &&
        userRequestData['drop_address'] != null) {
      addDropMarker();
      // addToast();

      getPolylines();
    } else if (widget.type == null) {
      addDropMarker();
      await getPolylines();
    } else {
      if (userRequestData.isNotEmpty) {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
            LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']));
        _controller!.animateCamera(cameraUpdate);
      } else {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
            addressList.firstWhere((element) => element.id == 'pickup').latlng);
        _controller!.animateCamera(cameraUpdate);
      }
    }
    // });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
  }

//get location permission and location details
  getLocs() async {
    setState(() {
      _center = (userRequestData.isEmpty)
          ? addressList.firstWhere((element) => element.id == 'pickup').latlng
          : LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']);
    });
    if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      serviceEnabled = true;
    } else {
      serviceEnabled = false;
    }
    final Uint8List markerIcon =
    await getBytesFromAsset('assets/images/top-taxi.png', 40);
    pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
    final Uint8List markerIcon2 =
    await getBytesFromAsset('assets/images/bike.png', 40);
    pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);

    choosenVehicle = null;
    _dist = null;

    if (widget.type == 2) {
      dropConfirmed = true;

      var val = await etaRequest();
      if (val == 'logout') {
        navigateLogout();
      }
    }
    if (widget.type == 1) {
      dropConfirmed = true;

      var val = await rentalEta();
      if (val == 'logout') {
        navigateLogout();
      }
    }

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        locationAllowed = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      // var loc = await location.getLocation();
      locationAllowed = true;
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
      setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 100), () async {
      await addPickDropMarker();
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
    // await getBounds();
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _controller!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    GeoHasher geo = GeoHasher();

    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .latitude -
        (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
        ? userRequestData['pick_lat'] - (lat * 1.24)
        : 0.0;
    double lowerLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .longitude -
        (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
        ? userRequestData['pick_lng'] - (lon * 1.24)
        : 0.0;

    double greaterLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .latitude +
        (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
        ? userRequestData['pick_lat'] - (lat * 1.24)
        : 0.0;
    double greaterLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .longitude +
        (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
        ? userRequestData['pick_lng'] - (lat * 1.24)
        : 0.0;
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (userRequestData.isEmpty) {
          etaDetails.clear();
          promoKey.clear();
          promoStatus = null;
          _rideLaterSuccess = false;
          // addressList.clear();
          myMarker.clear();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Maps()),
                  (route) => false);
          return true;
        } else {
          return false;
        }
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, value, child) {
                  if (_controller != null) {
                    mapPadding = media.width * 1;
                  }
                  if (requestCancelledByDriver == true ||
                      cancelRequestByUser == true) {
                    myMarker.clear();
                    polyline.clear();
                    addressList.removeWhere((element) => element.id == 'drop');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Maps()),
                              (route) => false);
                    });
                  }
                  if (userRequestData['is_completed'] == 1 &&
                      currentpage == true) {
                    currentpage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                              (route) => false);
                    });
                  }
                  if (userRequestData.isNotEmpty &&
                      timers == null &&
                      userRequestData['accepted_at'] == null) {
                    timer();
                  }
                  if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    if (myMarker
                        .where((element) =>
                    element.markerId == const MarkerId('pointdistance'))
                        .isNotEmpty) {
                      myMarker.removeWhere((element) =>
                      element.markerId == const MarkerId('pointdistance'));
                    }
                  }
                  return StreamBuilder<DatabaseEvent>(
                      stream: (userRequestData['driverDetail'] == null &&
                          pinLocationIcon != null)
                          ? fdb.onValue.asBroadcastStream()
                          : null,
                      builder: (context, AsyncSnapshot<DatabaseEvent> event) {
                        if (event.hasData) {
                          if (event.data!.snapshot.value != null) {
                            if (userRequestData['accepted_at'] == null) {
                              DataSnapshot snapshots = event.data!.snapshot;
                              // ignore: unnecessary_null_comparison
                              if (snapshots != null &&
                                  choosenVehicle != null &&
                                  etaDetails.isNotEmpty) {
                                driversData = [];
                                // ignore: avoid_function_literals_in_foreach_calls
                                snapshots.children.forEach((element) {
                                  driversData.add(element.value);
                                });
                                // ignore: avoid_function_literals_in_foreach_calls
                                driversData.forEach((e) {
                                  // here 0000000000000000000000
                                  // choosenVehicle return -1 it must be 0
                                  if (e['is_active'] == 1 &&
                                      e['is_available'] == true) {
                                    if (((e['vehicle_types'] != null &&
                                        ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) ||
                                            (widget.type == 1 &&
                                                e['vehicle_types'].contains(
                                                    rentalOption[choosenVehicle]
                                                    ['type_id'])))) ||
                                        ((widget.type != 1 &&
                                            e['vehicle_type'] ==
                                                etaDetails[choosenVehicle]
                                                ['type_id']) ||
                                            (widget.type == 1 &&
                                                e['vehicle_type'] ==
                                                    rentalOption[choosenVehicle]
                                                    ['type_id'])))) {
                                      DateTime dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          e['updated_at']);
                                      if (DateTime.now()
                                          .difference(dt)
                                          .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                            .toString()
                                            .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                            e['id'].toString()] !=
                                                null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                            LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                  element.markerId
                                                      .toString()
                                                      .contains(
                                                      'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                  element.markerId
                                                      .toString()
                                                      .contains(
                                                      'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                .lastWhere((element) =>
                                                element.markerId
                                                    .toString()
                                                    .contains(
                                                    'car${e['id']}'))
                                                .position
                                                .latitude !=
                                                e['l'][0] ||
                                                myMarker
                                                    .lastWhere((element) =>
                                                    element.markerId
                                                        .toString()
                                                        .contains(
                                                        'car${e['id']}'))
                                                    .position
                                                    .longitude !=
                                                    e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                    duration: const Duration(
                                                        milliseconds:
                                                        1500), //Animation duration of marker

                                                    vsync: this, //From the widget
                                                  );
                                              animateCar(
                                                myMarker
                                                    .lastWhere((element) =>
                                                    element.markerId
                                                        .toString()
                                                        .contains(
                                                        'car${e['id']}'))
                                                    .position
                                                    .latitude,
                                                myMarker
                                                    .lastWhere((element) =>
                                                    element.markerId
                                                        .toString()
                                                        .contains(
                                                        'car${e['id']}'))
                                                    .position
                                                    .longitude,
                                                e['l'][0],
                                                e['l'][1],
                                                _mapMarkerSink,
                                                this,
                                                _controller,
                                                'car${e['id']}',
                                                e['id'],
                                                (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                    ? pinLocationIcon2
                                                    : pinLocationIcon,
                                              );
                                            }
                                          }
                                        }
                                      }
                                    } else if (((e['vehicle_types'] != null &&
                                        ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) ||
                                            (widget.type == 1 &&
                                                e['vehicle_types'].contains(rentalOption[choosenVehicle]['type_id'])))) ||
                                        ((widget.type != 1 && e['vehicle_type'] == etaDetails[choosenVehicle]['type_id']) || (widget.type == 1 && e['vehicle_type'] == rentalOption[choosenVehicle]['type_id'])))) {
                                      DateTime dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          e['updated_at']);
                                      if (DateTime.now()
                                          .difference(dt)
                                          .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                            .toString()
                                            .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                            e['id'].toString()] !=
                                                null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                            LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                  element.markerId
                                                      .toString()
                                                      .contains(
                                                      'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                  element.markerId
                                                      .toString()
                                                      .contains(
                                                      'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                .lastWhere((element) =>
                                                element.markerId
                                                    .toString()
                                                    .contains(
                                                    'car${e['id']}'))
                                                .position
                                                .latitude !=
                                                e['l'][0] ||
                                                myMarker
                                                    .lastWhere((element) =>
                                                    element.markerId
                                                        .toString()
                                                        .contains(
                                                        'car${e['id']}'))
                                                    .position
                                                    .longitude !=
                                                    e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                    duration: const Duration(
                                                        milliseconds:
                                                        1500), //Animation duration of marker

                                                    vsync: this, //From the widget
                                                  );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                          'car${e['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                          'car${e['id']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${e['id']}',
                                                  e['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      if (myMarker
                                          .where((element) => element.markerId
                                          .toString()
                                          .contains('car${e['id']}'))
                                          .isNotEmpty) {
                                        myMarker.removeWhere((element) =>
                                            element.markerId
                                                .toString()
                                                .contains('car${e['id']}'));
                                      } else {
                                        if (myMarker
                                            .where((element) => element.markerId
                                            .toString()
                                            .contains('car${e['id']}'))
                                            .isNotEmpty) {
                                          myMarker.removeWhere((element) =>
                                              element.markerId
                                                  .toString()
                                                  .contains('car${e['id']}'));
                                        }
                                      }
                                    }
                                  }
                                });
                              }
                            }
                          }
                        }

                        return StreamBuilder<DatabaseEvent>(
                            stream: (userRequestData['driverDetail'] != null &&
                                pinLocationIcon != null)
                                ? FirebaseDatabase.instance
                                .ref(
                                'drivers/driver_${userRequestData['driverDetail']['data']['id']}')
                                .onValue
                                .asBroadcastStream()
                                : null,
                            builder:
                                (context, AsyncSnapshot<DatabaseEvent> event) {
                              if (event.hasData) {
                                if (event.data!.snapshot.value != null) {
                                  if (userRequestData['accepted_at'] != null) {
                                    driversData.clear();
                                    if (myMarker.length > 3) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                    }

                                    DataSnapshot snapshots =
                                        event.data!.snapshot;
                                    // ignore: unnecessary_null_comparison
                                    if (snapshots != null) {
                                      driverData = jsonDecode(
                                          jsonEncode(snapshots.value));
                                      if (driverData != {}) {
                                        if (userRequestData['arrived_at'] ==
                                            null) {
                                          var distCalc = calculateDistance(
                                              userRequestData['pick_lat'],
                                              userRequestData['pick_lng'],
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        } else if (userRequestData[
                                        'is_rental'] !=
                                            true &&
                                            userRequestData['drop_lat'] !=
                                                null) {
                                          var distCalc = calculateDistance(
                                            driverData['l'][0],
                                            driverData['l'][1],
                                            userRequestData['drop_lat'],
                                            userRequestData['drop_lng'],
                                          );
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        }
                                        if (myMarker
                                            .where((element) => element.markerId
                                            .toString()
                                            .contains(
                                            'car${driverData['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car${driverData['id']}'),
                                            rotation: (myBearings[
                                            driverData['id']
                                                .toString()] !=
                                                null)
                                                ? myBearings[
                                            driverData['id'].toString()]
                                                : 0.0,
                                            position: LatLng(driverData['l'][0],
                                                driverData['l'][1]),
                                            icon: (driverData[
                                            'vehicle_type_icon'] ==
                                                'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                  .markerId
                                                  .toString()
                                                  .contains(
                                                  'car${driverData['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                  .markerId
                                                  .toString()
                                                  .contains(
                                                  'car${driverData['id']}'))
                                                  .position
                                                  .longitude,
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                .lastWhere((element) =>
                                                element.markerId
                                                    .toString()
                                                    .contains(
                                                    'car${driverData['id']}'))
                                                .position
                                                .latitude !=
                                                driverData['l'][0] ||
                                                myMarker
                                                    .lastWhere((element) =>
                                                    element.markerId
                                                        .toString()
                                                        .contains(
                                                        'car${driverData['id']}'))
                                                    .position
                                                    .longitude !=
                                                    driverData['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                    duration: const Duration(
                                                        milliseconds:
                                                        1500), //Animation duration of marker

                                                    vsync: this, //From the widget
                                                  );

                                              animateCar(
                                                myMarker
                                                    .lastWhere((element) => element
                                                    .markerId
                                                    .toString()
                                                    .contains(
                                                    'car${driverData['id']}'))
                                                    .position
                                                    .latitude,
                                                myMarker
                                                    .firstWhere((element) => element
                                                    .markerId
                                                    .toString()
                                                    .contains(
                                                    'car${driverData['id']}'))
                                                    .position
                                                    .longitude,
                                                driverData['l'][0],
                                                driverData['l'][1],
                                                _mapMarkerSink,
                                                this,
                                                _controller,
                                                'car${driverData['id']}',
                                                driverData['id'],
                                                (driverData['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                    ? pinLocationIcon2
                                                    : pinLocationIcon,
                                              );
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      //get drivers location updates
                                      child: StreamBuilder<List<Marker>>(
                                          stream: mapMarkerStream,
                                          builder: (context, snapshot) {
                                            return GoogleMap(
                                              padding: EdgeInsets.only(
                                                  bottom: mapPadding,
                                                  top: media.height * 0.1 +
                                                      MediaQuery.of(context)
                                                          .padding
                                                          .top),
                                              onMapCreated: _onMapCreated,
                                              compassEnabled: false,
                                              initialCameraPosition:
                                              CameraPosition(
                                                target: _center,
                                                zoom: 11.0,
                                              ),
                                              markers:
                                              Set<Marker>.from(myMarker),
                                              polylines: polyline,
                                              minMaxZoomPreference:
                                              const MinMaxZoomPreference(
                                                  0.0, 20.0),
                                              myLocationButtonEnabled: false,
                                              buildingsEnabled: false,
                                              zoomControlsEnabled: false,
                                              myLocationEnabled: true,
                                            );
                                          })),
                                  (userRequestData['accepted_at'] == null)
                                      ? Positioned(
                                    top: MediaQuery.of(context)
                                        .padding
                                        .top +
                                        12.5,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              if (widget.type == null) {
                                                if (dropConfirmed) {
                                                  setState(() {
                                                    dropConfirmed = false;
                                                  });
                                                } else {
                                                  addressList.removeWhere(
                                                          (element) =>
                                                      element.id ==
                                                          'drop');
                                                  etaDetails.clear();
                                                  promoKey.clear();
                                                  promoStatus = null;
                                                  rentalOption.clear();
                                                  _rideLaterSuccess =
                                                  false;
                                                  myMarker.clear();
                                                  dropStopList.clear();
                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                          const Maps()),
                                                          (route) => false);
                                                }
                                              } else {
                                                addressList.removeWhere(
                                                        (element) =>
                                                    element.id ==
                                                        'drop');
                                                etaDetails.clear();
                                                promoKey.clear();
                                                promoStatus = null;
                                                rentalOption.clear();
                                                _rideLaterSuccess = false;
                                                myMarker.clear();
                                                dropStopList.clear();
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                        const Maps()),
                                                        (route) => false);
                                              }
                                            },
                                            child: Container(
                                              height: media.width * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors
                                                            .black
                                                            .withOpacity(
                                                            0.2),
                                                        spreadRadius: 2,
                                                        blurRadius: 2)
                                                  ],
                                                  color: page),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.arrow_back,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                      : Container(),
                                  Positioned(
                                    bottom: (widget.type != 1)
                                        ? media.width * 1.1
                                        : media.width * 1.15,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          if (userRequestData.isNotEmpty &&
                                              userRequestData['accepted_at'] !=
                                                  null)
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () async {
                                                    await Share.share(
                                                        'Your Driver is ${userRequestData['driverDetail']['data']['name']}. ${userRequestData['driverDetail']['data']['car_color']} ${userRequestData['driverDetail']['data']['car_make_name']} ${userRequestData['driverDetail']['data']['car_model_name']}, Vehicle Number: ${userRequestData['driverDetail']['data']['car_number']}. Track with link: ${url}track/request/${userRequestData['id']}');

                                                    // userRequestData[
                                                    //     'share_ride_text']
                                                  },
                                                  child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.25,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              media.width *
                                                                  0.02),
                                                          color: buttonColor),
                                                      alignment:
                                                      Alignment.center,
                                                      child: Text(
                                                        languages[
                                                        choosenLanguage]
                                                        ['text_shareride'],
                                                        style:
                                                        GoogleFonts.roboto(
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize: media
                                                                .width *
                                                                sixteen,
                                                            color: page),
                                                      )),
                                                ),
                                              ],
                                            ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (userRequestData.isNotEmpty &&
                                              userRequestData[
                                              'is_trip_start'] ==
                                                  1)
                                              ? InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  showSos = true;
                                                });
                                              },
                                              child: Container(
                                                height: media.width * 0.1,
                                                width: media.width * 0.1,
                                                decoration: BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                          blurRadius: 2,
                                                          color: Colors
                                                              .black
                                                              .withOpacity(
                                                              0.2),
                                                          spreadRadius: 2)
                                                    ],
                                                    // color: buttonColor,
                                                    color: buttonColor,
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(media
                                                        .width *
                                                        0.02)),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'SOS',
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                      media.width *
                                                          fourteen,
                                                      color: page),
                                                ),
                                              ))
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (etaDetails.isNotEmpty ||
                                              userRequestData.isNotEmpty)
                                              ? InkWell(
                                            onTap: () async {
                                              if (locationAllowed ==
                                                  true) {
                                                if (currentLocation !=
                                                    null) {
                                                  _controller?.animateCamera(
                                                      CameraUpdate
                                                          .newLatLngZoom(
                                                          currentLocation,
                                                          18.0));
                                                  center =
                                                      currentLocation;
                                                } else {
                                                  _controller?.animateCamera(
                                                      CameraUpdate
                                                          .newLatLngZoom(
                                                          center,
                                                          18.0));
                                                }
                                              } else {
                                                if (serviceEnabled ==
                                                    true) {
                                                  setState(() {
                                                    _locationDenied =
                                                    true;
                                                  });
                                                } else {
                                                  await geolocs.Geolocator
                                                      .getCurrentPosition(
                                                      desiredAccuracy:
                                                      geolocs
                                                          .LocationAccuracy
                                                          .low);

                                                  if (await geolocs
                                                      .GeolocatorPlatform
                                                      .instance
                                                      .isLocationServiceEnabled()) {
                                                    setState(() {
                                                      _locationDenied =
                                                      true;
                                                    });
                                                  }
                                                }
                                              }
                                            },
                                            child: Container(
                                              height: media.width * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                        blurRadius: 2,
                                                        color: Colors
                                                            .black
                                                            .withOpacity(
                                                            0.2),
                                                        spreadRadius: 2)
                                                  ],
                                                  color: page,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(media
                                                      .width *
                                                      0.02)),
                                              child: Icon(
                                                Icons.my_location_sharp,
                                                color: textColor,
                                              ),
                                            ),
                                          )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),

                                  //show bottom nav bar for choosing ride type and vehicles
                                  (addressList.isNotEmpty &&
                                      etaDetails.isNotEmpty &&
                                      userRequestData.isEmpty &&
                                      noDriverFound == false &&
                                      tripReqError == false &&
                                      lowWalletBalance == false &&
                                      dropConfirmed == true)
                                      ? Positioned(
                                      bottom: 0,
                                      child: GestureDetector(
                                        onVerticalDragStart: (v) {
                                          start = v.globalPosition.dy;
                                          gesture.clear();
                                        },
                                        onVerticalDragUpdate: (v) {
                                          gesture.add(v.globalPosition.dy);
                                        },
                                        onVerticalDragEnd: (v) {
                                          if (gesture.isNotEmpty &&
                                              start >
                                                  gesture[
                                                  gesture.length - 1] &&
                                              _ontripBottom == false) {
                                            setState(() {
                                              _ontripBottom = true;
                                            });
                                          } else if (gesture.isNotEmpty &&
                                              start <
                                                  gesture[
                                                  gesture.length - 1] &&
                                              _ontripBottom == true) {
                                            setState(() {
                                              _ontripBottom = false;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.05),
                                          height: (widget.type != 1)
                                              ? media.width * 1
                                              : (widget.type == 1)
                                              ? media.width * 1.1
                                              : media.height * 0.9,
                                          width: media.width * 1,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                              const BorderRadius.only(
                                                  topLeft:
                                                  Radius.circular(
                                                      25),
                                                  topRight:
                                                  Radius.circular(
                                                      25)),
                                              color: page),
                                          child: Column(
                                            children: [
                                              Container(
                                                height: media.width * 0.02,
                                                width: media.width * 0.2,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      media.width *
                                                          0.01),
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              SizedBox(
                                                width: media.width * 0.9,
                                                child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text(
                                                      languages[
                                                      choosenLanguage]
                                                      [
                                                      'text_availablerides'],
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                          media.width *
                                                              fourteen,
                                                          color: textColor),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              (etaDetails.isNotEmpty &&
                                                  widget.type != 1)
                                                  ? Expanded(
                                                child: SizedBox(
                                                  width: media.width *
                                                      0.9,
                                                  child:
                                                  SingleChildScrollView(
                                                    physics:
                                                    const BouncingScrollPhysics(),
                                                    child: Column(
                                                      children: [
                                                        Column(
                                                          children: etaDetails
                                                              .asMap()
                                                              .map((i, value) {
                                                            return MapEntry(
                                                                i,
                                                                StreamBuilder<DatabaseEvent>(
                                                                    stream: fdb.onValue.asBroadcastStream(),
                                                                    builder: (context, AsyncSnapshot event) {
                                                                      if (event.data != null && etaDetails.isNotEmpty) {
                                                                        minutes[etaDetails[i]['type_id']] = '';
                                                                        List vehicleList = [];
                                                                        List vehicles = [];
                                                                        List<double> minsList = [];
                                                                        event.data!.snapshot.children.forEach((e) {
                                                                          vehicleList.add(e.value);
                                                                        });
                                                                        if (vehicleList.isNotEmpty) {
                                                                          // ignore: avoid_function_literals_in_foreach_calls
                                                                          vehicleList.forEach(
                                                                                (e) async {
                                                                              if (e['is_active'] == 1 && e['is_available'] == true && (e['vehicle_type'] == etaDetails[i]['type_id'] || (e['vehicle_types'] != null && e['vehicle_types'].contains(etaDetails[i]['type_id'])))) {
                                                                                DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                  vehicles.add(e);
                                                                                  if (vehicles.isNotEmpty) {
                                                                                    var dist = calculateDistance(addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                    minsList.add(double.parse((dist / 1000).toString()));
                                                                                    var minDist = minsList.reduce(min);
                                                                                    if (minDist > 0 && minDist <= 1) {
                                                                                      minutes[etaDetails[i]['type_id']] = '2 mins';
                                                                                    } else if (minDist > 1 && minDist <= 3) {
                                                                                      minutes[etaDetails[i]['type_id']] = '5 mins';
                                                                                    } else if (minDist > 3 && minDist <= 5) {
                                                                                      minutes[etaDetails[i]['type_id']] = '8 mins';
                                                                                    } else if (minDist > 5 && minDist <= 7) {
                                                                                      minutes[etaDetails[i]['type_id']] = '11 mins';
                                                                                    } else if (minDist > 7 && minDist <= 10) {
                                                                                      minutes[etaDetails[i]['type_id']] = '14 mins';
                                                                                    } else if (minDist > 10) {
                                                                                      minutes[etaDetails[i]['type_id']] = '15 mins';
                                                                                    }
                                                                                  } else {
                                                                                    minutes[etaDetails[i]['type_id']] = '';
                                                                                  }
                                                                                }
                                                                              }
                                                                            },
                                                                          );
                                                                        } else {
                                                                          minutes[etaDetails[i]['type_id']] = '';
                                                                        }
                                                                      } else {
                                                                        minutes[etaDetails[i]['type_id']] = '';
                                                                      }

                                                                      return InkWell(
                                                                        onTap: () {
                                                                          setState(() {
                                                                            choosenVehicle = i;
                                                                          });
                                                                        },
                                                                        child: Container(
                                                                          padding: EdgeInsets.all(media.width * 0.03),
                                                                          decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.circular(12),
                                                                            color: (choosenVehicle != i)
                                                                                ? Colors.transparent
                                                                                : (isDarkTheme == true)
                                                                                ? textColor.withOpacity(0.2)
                                                                                : Colors.grey[200],
                                                                          ),
                                                                          child: Row(
                                                                            children: [
                                                                              Column(
                                                                                children: [
                                                                                  (etaDetails[i]['icon'] != null)
                                                                                      ? SizedBox(
                                                                                      width: media.width * 0.1,
                                                                                      child: Image.network(
                                                                                        etaDetails[i]['icon'],
                                                                                        fit: BoxFit.contain,
                                                                                      ))
                                                                                      : Container(),
                                                                                  SizedBox(height: media.width * 0.01),
                                                                                  (minutes[etaDetails[i]['type_id']] != '')
                                                                                      ? Text(
                                                                                    minutes[etaDetails[i]['type_id']].toString(),
                                                                                    style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.4)),
                                                                                  )
                                                                                      : Text(
                                                                                    '- -',
                                                                                    style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.4)),
                                                                                  )
                                                                                ],
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.05,
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(etaDetails[i]['name'], style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600)),
                                                                                  Row(
                                                                                    children: [
                                                                                      SizedBox(
                                                                                        width: media.width * 0.3,
                                                                                        child: Text(
                                                                                          etaDetails[i]['short_description'],
                                                                                          style: GoogleFonts.roboto(
                                                                                            fontSize: media.width * twelve,
                                                                                            color: textColor,
                                                                                          ),
                                                                                          maxLines: 1,
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(width: media.width * 0.01),
                                                                                      InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {
                                                                                              _showInfoInt = i;
                                                                                              _showInfo = true;
                                                                                            });
                                                                                          },
                                                                                          child: Icon(
                                                                                            Icons.info_outline,
                                                                                            size: media.width * twelve,
                                                                                            color: textColor,
                                                                                          )),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              (widget.type == 2)
                                                                                  ? Container()
                                                                                  : Expanded(
                                                                                  child: (etaDetails[i]['has_discount'] != true)
                                                                                      ? Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    children: [
                                                                                      Text(
                                                                                        etaDetails[i]['currency'] + ' ' + etaDetails[i]['total'].toStringAsFixed(2),
                                                                                        style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                      : Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    children: [
                                                                                      Text(
                                                                                        etaDetails[i]['currency'] + ' ',
                                                                                        style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      ),
                                                                                      Text(
                                                                                        etaDetails[i]['total'].toStringAsFixed(2),
                                                                                        style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                      ),
                                                                                      Text(
                                                                                        ' ${etaDetails[i]['discounted_totel'].toStringAsFixed(2)}',
                                                                                        style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      )
                                                                                    ],
                                                                                  ))
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }));
                                                          })
                                                              .values
                                                              .toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                                  : (etaDetails
                                                  .isNotEmpty &&
                                                  widget.type == 1)
                                                  ? Expanded(
                                                child: SizedBox(
                                                  width: media
                                                      .width *
                                                      0.9,
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        height: media
                                                            .width *
                                                            0.025,
                                                      ),
                                                      SizedBox(
                                                        width: media
                                                            .width *
                                                            0.9,
                                                        child:
                                                        SingleChildScrollView(
                                                          scrollDirection:
                                                          Axis.horizontal,
                                                          child:
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.start,
                                                            children: etaDetails
                                                                .asMap()
                                                                .map((i, value) {
                                                              return MapEntry(
                                                                  i,
                                                                  Container(
                                                                    margin: EdgeInsets.only(right: media.width * 0.05),
                                                                    decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        color: (rentalChoosenOption == i)
                                                                            ? buttonColor
                                                                            : (isDarkTheme == true)
                                                                            ? textColor.withOpacity(0.7)
                                                                            : borderLines),
                                                                    padding: EdgeInsets.all(media.width * 0.02),
                                                                    child: InkWell(
                                                                      onTap: () {
                                                                        setState(() {
                                                                          rentalOption = etaDetails[i]['typesWithPrice']['data'];
                                                                          rentalChoosenOption = i;
                                                                          choosenVehicle = null;
                                                                          payingVia = 0;
                                                                        });
                                                                      },
                                                                      child: Text(
                                                                        etaDetails[i]['package_name'],
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width * sixteen,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: (rentalChoosenOption == i)
                                                                                ? (isDarkTheme == true)
                                                                                ? Colors.black
                                                                                : Colors.white
                                                                                : Colors.black),
                                                                      ),
                                                                    ),
                                                                  ));
                                                            })
                                                                .values
                                                                .toList(),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          height: media.width *
                                                              0.05),
                                                      Expanded(
                                                        child:
                                                        SizedBox(
                                                          width: media.width *
                                                              0.9,
                                                          child:
                                                          SingleChildScrollView(
                                                            physics:
                                                            const BouncingScrollPhysics(),
                                                            child: Column(
                                                                children: rentalOption
                                                                    .asMap()
                                                                    .map((i, value) {
                                                                  return MapEntry(
                                                                      i,
                                                                      StreamBuilder<DatabaseEvent>(
                                                                          stream: fdb.onValue.asBroadcastStream(),
                                                                          builder: (context, AsyncSnapshot event) {
                                                                            if (event.data != null && etaDetails.isNotEmpty) {
                                                                              minutes[rentalOption[i]['type_id']] = '';
                                                                              List vehicleList = [];
                                                                              List vehicles = [];
                                                                              List<double> minsList = [];
                                                                              event.data!.snapshot.children.forEach((e) {
                                                                                vehicleList.add(e.value);
                                                                              });
                                                                              if (vehicleList.isNotEmpty) {
                                                                                // ignore: avoid_function_literals_in_foreach_calls
                                                                                vehicleList.forEach(
                                                                                      (e) async {
                                                                                    if (e['is_active'] == 1 && e['is_available'] == true && e['vehicle_type'] == rentalOption[i]['type_id'] || (e['vehicle_types'] != null && e['vehicle_types'].contains(rentalOption[i]['type_id']))) {
                                                                                      DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                      if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                        vehicles.add(e);
                                                                                        if (vehicles.isNotEmpty) {
                                                                                          var dist = calculateDistance(addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                          minsList.add(double.parse((dist / 1000).toString()));
                                                                                          var minDist = minsList.reduce(min);
                                                                                          if (minDist > 0 && minDist <= 1) {
                                                                                            minutes[rentalOption[i]['type_id']] = '2 mins';
                                                                                          } else if (minDist > 1 && minDist <= 3) {
                                                                                            minutes[rentalOption[i]['type_id']] = '5 mins';
                                                                                          } else if (minDist > 3 && minDist <= 5) {
                                                                                            minutes[rentalOption[i]['type_id']] = '8 mins';
                                                                                          } else if (minDist > 5 && minDist <= 7) {
                                                                                            minutes[rentalOption[i]['type_id']] = '11 mins';
                                                                                          } else if (minDist > 7 && minDist <= 10) {
                                                                                            minutes[rentalOption[i]['type_id']] = '14 mins';
                                                                                          } else if (minDist > 10) {
                                                                                            minutes[rentalOption[i]['type_id']] = '15 mins';
                                                                                          }
                                                                                        } else {
                                                                                          minutes[rentalOption[i]['type_id']] = '';
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  },
                                                                                );
                                                                              } else {
                                                                                minutes[rentalOption[i]['type_id']] = '';
                                                                              }
                                                                            } else {
                                                                              minutes[rentalOption[i]['type_id']] = '';
                                                                            }
                                                                            return InkWell(
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  choosenVehicle = i;
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.all(media.width * 0.03),
                                                                                decoration: BoxDecoration(
                                                                                  borderRadius: BorderRadius.circular(12),
                                                                                  color: (choosenVehicle != i)
                                                                                      ? Colors.transparent
                                                                                      : (isDarkTheme == true)
                                                                                      ? textColor.withOpacity(0.2)
                                                                                      : Colors.grey[200],
                                                                                ),
                                                                                child: Row(
                                                                                  children: [
                                                                                    Column(
                                                                                      children: [
                                                                                        (rentalOption[i]['icon'] != null)
                                                                                            ? SizedBox(
                                                                                            width: media.width * 0.1,
                                                                                            child: Image.network(
                                                                                              rentalOption[i]['icon'],
                                                                                              fit: BoxFit.contain,
                                                                                            ))
                                                                                            : Container(),
                                                                                        (minutes[rentalOption[i]['type_id']] != "")
                                                                                            ? Text(
                                                                                          minutes[rentalOption[i]['type_id']].toString(),
                                                                                          style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.4)),
                                                                                        )
                                                                                            : Text(
                                                                                          '- -',
                                                                                          style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.4)),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.05,
                                                                                    ),
                                                                                    Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(rentalOption[i]['name'], style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600)),
                                                                                        Row(
                                                                                          children: [
                                                                                            SizedBox(
                                                                                              width: media.width * 0.3,
                                                                                              child: Text(
                                                                                                rentalOption[i]['short_description'],
                                                                                                style: GoogleFonts.roboto(
                                                                                                  fontSize: media.width * twelve,
                                                                                                  color: textColor,
                                                                                                ),
                                                                                                maxLines: 1,
                                                                                              ),
                                                                                            ),
                                                                                            SizedBox(width: media.width * 0.01),
                                                                                            InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    _showInfoInt = i;
                                                                                                    _showInfo = true;
                                                                                                  });
                                                                                                },
                                                                                                child: Icon(Icons.info_outline, size: media.width * twelve, color: textColor)),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    Expanded(
                                                                                        child: (rentalOption[i]['has_discount'] != true)
                                                                                            ? Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                          children: [
                                                                                            Text(
                                                                                              rentalOption[i]['currency'] + ' ' + rentalOption[i]['fare_amount'].toStringAsFixed(2),
                                                                                              style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                            ),
                                                                                          ],
                                                                                        )
                                                                                            : Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                          children: [
                                                                                            Text(
                                                                                              rentalOption[i]['currency'] + ' ',
                                                                                              style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                            ),
                                                                                            Text(
                                                                                              rentalOption[i]['fare_amount'].toStringAsFixed(2),
                                                                                              style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                            ),
                                                                                            Text(
                                                                                              ' ${rentalOption[i]['discounted_totel'].toStringAsFixed(2)}',
                                                                                              style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                            )
                                                                                          ],
                                                                                        ))
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }));
                                                                })
                                                                    .values
                                                                    .toList()),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                                  : Container(),
                                              (choosenVehicle != null &&
                                                  widget.type != 1)
                                                  ? InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _choosePayment =
                                                    true;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets
                                                      .all(media
                                                      .width *
                                                      0.02),
                                                  height:
                                                  media.width *
                                                      0.2,
                                                  width: media.width *
                                                      0.9,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: (isDarkTheme ==
                                                              true)
                                                              ? textColor.withOpacity(
                                                              0.4)
                                                              : borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          12)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Text(
                                                        languages[
                                                        choosenLanguage]
                                                        [
                                                        'text_payingvia'],
                                                        style:
                                                        GoogleFonts
                                                            .roboto(
                                                          fontSize: media
                                                              .width *
                                                              twelve,
                                                          color: const Color(
                                                              0xff666666),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width: media
                                                                .width *
                                                                0.06,
                                                            child: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                'cash')
                                                                ? Image
                                                                .asset(
                                                              'assets/images/cash.png',
                                                              fit: BoxFit.contain,
                                                            )
                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                ? Image.asset('assets/images/wallet.png', fit: BoxFit.contain, color: textColor)
                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                ? Image.asset('assets/images/card.png', fit: BoxFit.contain, color: textColor)
                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                ? Image.asset(
                                                              'assets/images/upi.png',
                                                              fit: BoxFit.contain,
                                                            )
                                                                : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media
                                                                .width *
                                                                0.05,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                            children: [
                                                              Text(
                                                                etaDetails[choosenVehicle]['payment_type']
                                                                    .toString()
                                                                    .split(',')
                                                                    .toList()[payingVia]
                                                                    .toString(),
                                                                style: GoogleFonts.roboto(
                                                                    color: textColor,
                                                                    fontSize: media.width * fourteen,
                                                                    fontWeight: FontWeight.w600),
                                                              ),
                                                              (etaDetails[choosenVehicle]['has_discount'] ==
                                                                  false)
                                                                  ? Text(
                                                                (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                    ? languages[choosenLanguage]['text_paywallet']
                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                    ? languages[choosenLanguage]['text_paycard']
                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                    ? languages[choosenLanguage]['text_payupi']
                                                                    : '',
                                                                style: GoogleFonts.roboto(
                                                                  color: textColor,
                                                                  fontSize: media.width * ten,
                                                                ),
                                                              )
                                                                  : Text(
                                                                languages[choosenLanguage]['text_promoaccepted'],
                                                                style: GoogleFonts.roboto(
                                                                  color: const Color(0xff319900),
                                                                  fontSize: media.width * ten,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          Expanded(
                                                              child:
                                                              Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .arrow_forward_ios,
                                                                    color:
                                                                    textColor,
                                                                  ),
                                                                ],
                                                              ))
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              )
                                                  : (choosenVehicle !=
                                                  null &&
                                                  widget.type == 1)
                                                  ? InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _choosePayment =
                                                    true;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets
                                                      .all(media
                                                      .width *
                                                      0.02),
                                                  height: media
                                                      .width *
                                                      0.2,
                                                  width: media
                                                      .width *
                                                      0.9,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                          borderLines,
                                                          width:
                                                          1.2),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Text(
                                                        languages[
                                                        choosenLanguage]
                                                        [
                                                        'text_payingvia'],
                                                        style: GoogleFonts
                                                            .roboto(
                                                          fontSize:
                                                          media.width *
                                                              twelve,
                                                          color: const Color(
                                                              0xff666666),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width:
                                                            media.width * 0.06,
                                                            child: (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                ? Image.asset(
                                                              'assets/images/cash.png',
                                                              fit: BoxFit.contain,
                                                            )
                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                ? Image.asset('assets/images/wallet.png', fit: BoxFit.contain, color: textColor)
                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                ? Image.asset('assets/images/card.png', fit: BoxFit.contain, color: textColor)
                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                ? Image.asset(
                                                              'assets/images/upi.png',
                                                              fit: BoxFit.contain,
                                                            )
                                                                : Container(),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                            media.width * 0.05,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia].toString(),
                                                                style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: textColor),
                                                              ),
                                                              (rentalOption[choosenVehicle]['has_discount'] == false)
                                                                  ? Text(
                                                                (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                    ? languages[choosenLanguage]['text_paywallet']
                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                    ? languages[choosenLanguage]['text_paycard']
                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                    ? languages[choosenLanguage]['text_payupi']
                                                                    : '',
                                                                style: GoogleFonts.roboto(fontSize: media.width * ten, color: textColor),
                                                              )
                                                                  : Text(
                                                                languages[choosenLanguage]['text_promoaccepted'],
                                                                style: GoogleFonts.roboto(
                                                                  color: const Color(0xff319900),
                                                                  fontSize: media.width * ten,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          Expanded(
                                                              child:
                                                              Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment.end,
                                                                children: [
                                                                  Icon(Icons.arrow_forward_ios,
                                                                      color: textColor),
                                                                ],
                                                              ))
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              )
                                                  : Container(),
                                              (choosenVehicle != null)
                                                  ? SizedBox(
                                                height: media.width *
                                                    0.05,
                                              )
                                                  : Container(),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  (userDetails[
                                                  'show_ride_later_feature'] ==
                                                      true)
                                                      ? Button(
                                                      color: page,
                                                      textcolor:
                                                      buttonColor,
                                                      width:
                                                      media.width *
                                                          0.42,
                                                      onTap: () async {
                                                        if (choosenVehicle !=
                                                            null) {
                                                          setState(() {
                                                            choosenDateTime = DateTime
                                                                .now()
                                                                .add(const Duration(
                                                                minutes:
                                                                30));
                                                            _dateTimePicker =
                                                            true;
                                                          });
                                                        }
                                                      },
                                                      text: languages[
                                                      choosenLanguage]
                                                      [
                                                      'text_ridelater'])
                                                      : Container(),
                                                  Button(
                                                      width: (userDetails[
                                                      'show_ride_later_feature'] ==
                                                          true)
                                                          ? media.width *
                                                          0.42
                                                          : media.width *
                                                          0.9,
                                                      color: buttonColor,
                                                      onTap: () async {
                                                        // here 111111111111111111111
                                                        // etaDetails[choosenVehicle]['user_wallet_balance'] return null
                                                        if (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['has_discount'] == true && etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['discounted_totel'])) ||
                                                            (rentalOption.isEmpty &&
                                                                etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] !=
                                                                    'wallet')) ||
                                                            ((rentalOption
                                                                .isNotEmpty &&
                                                                etaDetails[0]['user_wallet_balance'] >=
                                                                    rentalOption[choosenVehicle][
                                                                    'fare_amount'] &&
                                                                rentalOption[choosenVehicle]['has_discount'] ==
                                                                    false) ||
                                                                (rentalOption.isNotEmpty &&
                                                                    rentalOption[choosenVehicle]['has_discount'] ==
                                                                        true &&
                                                                    rentalOption[choosenVehicle]['user_wallet_balance'] >=
                                                                        rentalOption[choosenVehicle][
                                                                        'discounted_totel']) ||
                                                                rentalOption.isNotEmpty &&
                                                                    rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] !=
                                                                        'wallet')) {
                                                          setState(() {
                                                            _isLoading =
                                                            true;
                                                          });
                                                          dropStopList
                                                              .clear();
                                                          dynamic result;
                                                          if (choosenVehicle !=
                                                              null) {
                                                            if (widget
                                                                .type !=
                                                                1) {
                                                              if (etaDetails[
                                                              choosenVehicle]
                                                              [
                                                              'has_discount'] ==
                                                                  false) {
                                                                if (addressList
                                                                    .length >
                                                                    2) {
                                                                  for (var i =
                                                                  1;
                                                                  i < addressList.length;
                                                                  i++) {
                                                                    dropStopList.add(DropStops(
                                                                        order:
                                                                        i.toString(),
                                                                        latitude: addressList[i].latlng.latitude,
                                                                        longitude: addressList[i].latlng.longitude,
                                                                        address: addressList[i].address));
                                                                  }
                                                                }

                                                                result =
                                                                await createRequest();
                                                                if (result ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                              } else {
                                                                if (addressList
                                                                    .length >
                                                                    2) {
                                                                  for (var i =
                                                                  1;
                                                                  i < addressList.length;
                                                                  i++) {
                                                                    dropStopList.add(DropStops(
                                                                        order:
                                                                        i.toString(),
                                                                        latitude: addressList[i].latlng.latitude,
                                                                        longitude: addressList[i].latlng.longitude,
                                                                        address: addressList[i].address));
                                                                  }
                                                                }
                                                                result =
                                                                await createRequestWithPromo();
                                                                if (result ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                              }
                                                            } else {
                                                              if (rentalOption[
                                                              choosenVehicle]
                                                              [
                                                              'has_discount'] ==
                                                                  false) {
                                                                result =
                                                                await createRentalRequest();
                                                                if (result ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                              } else {
                                                                result =
                                                                await createRentalRequestWithPromo();
                                                                if (result ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                              }
                                                            }
                                                          }
                                                          if (result ==
                                                              'success') {
                                                            timer();
                                                          }
                                                          setState(() {
                                                            _isLoading =
                                                            false;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            islowwalletbalance =
                                                            true;
                                                          });
                                                        }
                                                      },
                                                      text: languages[
                                                      choosenLanguage]
                                                      ['text_ridenow']),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                      : Container(),

                                  //show vehicle info
                                  (_showInfo == true)
                                      ? Positioned(
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.only(
                                          bottom: media.width * 0.05),
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      // color: Colors.transparent
                                      //     .withOpacity(0.6),
                                      color: (isDarkTheme == true)
                                          ? textColor.withOpacity(0.2)
                                          : Colors.transparent
                                          .withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.end,
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
                                                      _showInfo = false;
                                                      _showInfoInt = null;
                                                    });
                                                  },
                                                  child: Container(
                                                    height:
                                                    media.width * 0.1,
                                                    width:
                                                    media.width * 0.1,
                                                    decoration:
                                                    BoxDecoration(
                                                        shape: BoxShape
                                                            .circle,
                                                        color: page),
                                                    child: Icon(
                                                      Icons
                                                          .cancel_outlined,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              height: media.width * 0.05),
                                          Container(
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                                color: page),
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            child: (widget.type != 1)
                                                ? Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  etaDetails[
                                                  _showInfoInt]
                                                  ['name'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      color:
                                                      textColor,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width *
                                                      0.025,
                                                ),
                                                Text(
                                                  etaDetails[
                                                  _showInfoInt]
                                                  [
                                                  'description'],
                                                  style: GoogleFonts
                                                      .roboto(
                                                    fontSize: media
                                                        .width *
                                                        fourteen,
                                                    color:
                                                    textColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media
                                                        .width *
                                                        0.05),
                                                Text(
                                                  languages[
                                                  choosenLanguage]
                                                  [
                                                  'text_supported_vehicles'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      color:
                                                      textColor,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width *
                                                      0.025,
                                                ),
                                                Text(
                                                  etaDetails[
                                                  _showInfoInt]
                                                  [
                                                  'supported_vehicles'],
                                                  style: GoogleFonts
                                                      .roboto(
                                                    fontSize: media
                                                        .width *
                                                        fourteen,
                                                    color:
                                                    textColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media
                                                        .width *
                                                        0.05),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    SizedBox(
                                                      width: media
                                                          .width *
                                                          0.4,
                                                      child: Text(
                                                        languages[
                                                        choosenLanguage]
                                                        [
                                                        'text_estimated_amount'],
                                                        style: GoogleFonts.roboto(
                                                            fontSize:
                                                            media.width *
                                                                sixteen,
                                                            color:
                                                            textColor,
                                                            fontWeight:
                                                            FontWeight.w600),
                                                      ),
                                                    ),
                                                    (etaDetails[_showInfoInt]
                                                    [
                                                    'has_discount'] !=
                                                        true)
                                                        ? Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          etaDetails[_showInfoInt]['currency'] +
                                                              ' ' +
                                                              etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    )
                                                        : Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          etaDetails[_showInfoInt]['currency'] +
                                                              ' ',
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                        Text(
                                                          etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600,
                                                              decoration: TextDecoration.lineThrough),
                                                        ),
                                                        Text(
                                                          ' ${etaDetails[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                )
                                              ],
                                            )
                                                : Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  rentalOption[
                                                  _showInfoInt]
                                                  ['name'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      color:
                                                      textColor,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width *
                                                      0.025,
                                                ),
                                                Text(
                                                  rentalOption[
                                                  _showInfoInt]
                                                  [
                                                  'description'],
                                                  style: GoogleFonts
                                                      .roboto(
                                                    fontSize: media
                                                        .width *
                                                        fourteen,
                                                    color:
                                                    textColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media
                                                        .width *
                                                        0.05),
                                                Text(
                                                  languages[
                                                  choosenLanguage]
                                                  [
                                                  'text_supported_vehicles'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      color:
                                                      textColor,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width *
                                                      0.025,
                                                ),
                                                Text(
                                                  rentalOption[
                                                  _showInfoInt]
                                                  [
                                                  'supported_vehicles'],
                                                  style: GoogleFonts
                                                      .roboto(
                                                    fontSize: media
                                                        .width *
                                                        fourteen,
                                                    color:
                                                    textColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media
                                                        .width *
                                                        0.05),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    Text(
                                                      languages[
                                                      choosenLanguage]
                                                      [
                                                      'text_estimated_amount'],
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                          media.width *
                                                              sixteen,
                                                          color:
                                                          textColor,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600),
                                                    ),
                                                    (rentalOption[_showInfoInt]
                                                    [
                                                    'has_discount'] !=
                                                        true)
                                                        ? Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          rentalOption[_showInfoInt]['currency'] +
                                                              ' ' +
                                                              rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    )
                                                        : Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          rentalOption[_showInfoInt]['currency'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                        Text(
                                                          ' ${rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2)}',
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600,
                                                              decoration: TextDecoration.lineThrough),
                                                        ),
                                                        Text(
                                                          ' ${rentalOption[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media.width * fourteen,
                                                              color: textColor,
                                                              fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                      : Container(),

                                  //no driver found
                                  (noDriverFound == true)
                                      ? Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: media.width * 1,
                                        padding: EdgeInsets.all(
                                            media.width * 0.05),
                                        decoration: BoxDecoration(
                                            color: page,
                                            borderRadius:
                                            const BorderRadius.only(
                                                topLeft:
                                                Radius.circular(12),
                                                topRight:
                                                Radius.circular(
                                                    12))),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: media.width * 0.18,
                                              width: media.width * 0.18,
                                              decoration:
                                              const BoxDecoration(
                                                  shape:
                                                  BoxShape.circle,
                                                  color: Color(
                                                      0xffFEF2F2)),
                                              alignment: Alignment.center,
                                              child: Container(
                                                height: media.width * 0.14,
                                                width: media.width * 0.14,
                                                decoration:
                                                const BoxDecoration(
                                                    shape:
                                                    BoxShape.circle,
                                                    color: Color(
                                                        0xffFF0000)),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Text(
                                              languages[choosenLanguage]
                                              ['text_nodriver'],
                                              style: GoogleFonts.roboto(
                                                  fontSize: media.width *
                                                      eighteen,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  color: textColor),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () {
                                                  setState(() {
                                                    noDriverFound = false;
                                                  });
                                                },
                                                text: languages[
                                                choosenLanguage]
                                                ['text_tryagain'])
                                          ],
                                        ),
                                      ))
                                      : Container(),

                                  //internal server error
                                  (tripReqError == true)
                                      ? Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: media.width * 1,
                                        padding: EdgeInsets.all(
                                            media.width * 0.05),
                                        decoration: BoxDecoration(
                                            color: page,
                                            borderRadius:
                                            const BorderRadius.only(
                                                topLeft:
                                                Radius.circular(12),
                                                topRight:
                                                Radius.circular(
                                                    12))),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: media.width * 0.18,
                                              width: media.width * 0.18,
                                              decoration:
                                              const BoxDecoration(
                                                  shape:
                                                  BoxShape.circle,
                                                  color: Color(
                                                      0xffFEF2F2)),
                                              alignment: Alignment.center,
                                              child: Container(
                                                height: media.width * 0.14,
                                                width: media.width * 0.14,
                                                decoration:
                                                const BoxDecoration(
                                                    shape:
                                                    BoxShape.circle,
                                                    color: Color(
                                                        0xffFF0000)),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.8,
                                              child: Text(
                                                  languages[choosenLanguage]
                                                  [
                                                  'text_internal_server_error'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                      media.width *
                                                          eighteen,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color: textColor),
                                                  textAlign:
                                                  TextAlign.center),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () {
                                                  setState(() {
                                                    tripReqError = false;
                                                  });
                                                },
                                                text: languages[
                                                choosenLanguage]
                                                ['text_tryagain'])
                                          ],
                                        ),
                                      ))
                                      : Container(),

                                  //service not available
                                  (serviceNotAvailable == true)
                                      ? Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: media.width * 1,
                                        padding: EdgeInsets.all(
                                            media.width * 0.05),
                                        decoration: BoxDecoration(
                                            color: page,
                                            borderRadius:
                                            const BorderRadius.only(
                                                topLeft:
                                                Radius.circular(12),
                                                topRight:
                                                Radius.circular(
                                                    12))),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: media.width * 0.18,
                                              width: media.width * 0.18,
                                              decoration:
                                              const BoxDecoration(
                                                  shape:
                                                  BoxShape.circle,
                                                  color: Color(
                                                      0xffFEF2F2)),
                                              alignment: Alignment.center,
                                              child: Container(
                                                height: media.width * 0.14,
                                                width: media.width * 0.14,
                                                decoration:
                                                const BoxDecoration(
                                                    shape:
                                                    BoxShape.circle,
                                                    color: Color(
                                                        0xffFF0000)),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.8,
                                              child: Text(
                                                  languages[choosenLanguage]
                                                  ['text_no_service'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                      media.width *
                                                          eighteen,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color: textColor),
                                                  textAlign:
                                                  TextAlign.center),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    serviceNotAvailable =
                                                    false;
                                                  });
                                                  dropStopList.clear();

                                                  if (widget.type != 1) {
                                                    if (addressList.length >
                                                        2) {
                                                      for (var i = 1;
                                                      i <
                                                          addressList
                                                              .length;
                                                      i++) {
                                                        dropStopList.add(DropStops(
                                                            order: i
                                                                .toString(),
                                                            latitude:
                                                            addressList[
                                                            i]
                                                                .latlng
                                                                .latitude,
                                                            longitude:
                                                            addressList[
                                                            i]
                                                                .latlng
                                                                .longitude,
                                                            address:
                                                            addressList[
                                                            i]
                                                                .address));
                                                      }
                                                    }
                                                    var val =
                                                    await etaRequest();
                                                    if (val == 'logout') {
                                                      navigateLogout();
                                                    }
                                                  } else {
                                                    var val =
                                                    await rentalEta();
                                                    if (val == 'logout') {
                                                      navigateLogout();
                                                    }
                                                  }
                                                  setState(() {});
                                                },
                                                text: languages[
                                                choosenLanguage]
                                                ['text_tryagain'])
                                          ],
                                        ),
                                      ))
                                      : Container(),
                                  //islowwallet balance popup
                                  (islowwalletbalance == true)
                                      ? Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width: media.width * 1,
                                        height: media.height * 1,
                                        color:
                                        Colors.black.withOpacity(0.4),
                                        padding: EdgeInsets.all(
                                            media.width * 0.05),
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: media.width * 0.9,
                                          height: media.width * 0.4,
                                          padding: EdgeInsets.all(
                                              media.width * 0.05),
                                          decoration: BoxDecoration(
                                              color: page,
                                              borderRadius:
                                              BorderRadius.circular(
                                                  media.width * 0.04)),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                  languages[
                                                  choosenLanguage]
                                                  [
                                                  'text_wallet_balance_low'],
                                                  style:
                                                  GoogleFonts.poppins(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600,
                                                      color: textColor),
                                                  textAlign:
                                                  TextAlign.center),
                                              Button(
                                                  width: media.width * 0.4,
                                                  height: media.width * 0.1,
                                                  onTap: () {
                                                    setState(() {
                                                      islowwalletbalance =
                                                      false;
                                                    });
                                                  },
                                                  text: languages[
                                                  choosenLanguage]
                                                  ['text_ok'])
                                            ],
                                          ),
                                        ),
                                      ))
                                      : Container(),
                                  //choose payment method
                                  (_choosePayment == true)
                                      ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        // color: Colors.transparent
                                        //     .withOpacity(0.6),
                                        color: (isDarkTheme == true)
                                            ? textColor.withOpacity(0.2)
                                            : Colors.transparent
                                            .withOpacity(0.6),
                                        child: Scaffold(
                                          backgroundColor:
                                          Colors.transparent,
                                          body: SingleChildScrollView(
                                            physics:
                                            const BouncingScrollPhysics(),
                                            child: SizedBox(
                                              height: media.height * 1,
                                              width: media.width * 1,
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .center,
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                    media.width * 0.9,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _choosePayment =
                                                              false;
                                                              promoKey
                                                                  .clear();
                                                            });
                                                          },
                                                          child: Container(
                                                            height: media
                                                                .width *
                                                                0.1,
                                                            width: media
                                                                .width *
                                                                0.1,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color:
                                                                page),
                                                            child: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color:
                                                              textColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                    media.width * 0.05,
                                                  ),
                                                  Container(
                                                    width:
                                                    media.width * 0.9,
                                                    decoration:
                                                    BoxDecoration(
                                                      color: page,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(12),
                                                      // border: Border.all(
                                                      //     color: topBar)
                                                    ),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          languages[
                                                          choosenLanguage]
                                                          [
                                                          'text_paymentmethod'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media
                                                                  .width *
                                                                  twenty,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                              color:
                                                              textColor),
                                                        ),
                                                        SizedBox(
                                                          height:
                                                          media.height *
                                                              0.015,
                                                        ),
                                                        Text(
                                                          languages[
                                                          choosenLanguage]
                                                          [
                                                          'text_choose_paynoworlater'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media
                                                                  .width *
                                                                  twelve,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                              color:
                                                              textColor),
                                                        ),
                                                        SizedBox(
                                                          height:
                                                          media.height *
                                                              0.015,
                                                        ),
                                                        (widget.type != 1)
                                                            ? Column(
                                                          children: etaDetails[choosenVehicle]
                                                          [
                                                          'payment_type']
                                                              .toString()
                                                              .split(
                                                              ',')
                                                              .toList()
                                                              .asMap()
                                                              .map((i,
                                                              value) {
                                                            return MapEntry(
                                                                i,
                                                                InkWell(
                                                                  onTap: () {
                                                                    setState(() {
                                                                      payingVia = i;
                                                                    });
                                                                  },
                                                                  child: Container(
                                                                    padding: EdgeInsets.all(media.width * 0.02),
                                                                    width: media.width * 0.9,
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.06,
                                                                              child: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                  ? Image.asset(
                                                                                'assets/images/cash.png',
                                                                                fit: BoxFit.contain,
                                                                              )
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                  ? Image.asset('assets/images/wallet.png', fit: BoxFit.contain, color: textColor)
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                  ? Image.asset(
                                                                                'assets/images/card.png',
                                                                                fit: BoxFit.contain,
                                                                                color: textColor,
                                                                              )
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
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
                                                                                  etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                  style: GoogleFonts.roboto(color: textColor, fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                ),
                                                                                Text(
                                                                                  (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                      ? languages[choosenLanguage]['text_paycash']
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                      ? languages[choosenLanguage]['text_paywallet']
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                      ? languages[choosenLanguage]['text_paycard']
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                      ? languages[choosenLanguage]['text_payupi']
                                                                                      : '',
                                                                                  style: GoogleFonts.roboto(
                                                                                    color: textColor,
                                                                                    fontSize: media.width * ten,
                                                                                  ),
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
                                                                                      child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)) : Container(),
                                                                                    )
                                                                                  ],
                                                                                ))
                                                                          ],
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ));
                                                          })
                                                              .values
                                                              .toList(),
                                                        )
                                                            : Column(
                                                          children: rentalOption[choosenVehicle]
                                                          [
                                                          'payment_type']
                                                              .toString()
                                                              .split(
                                                              ',')
                                                              .toList()
                                                              .asMap()
                                                              .map((i,
                                                              value) {
                                                            return MapEntry(
                                                                i,
                                                                InkWell(
                                                                  onTap: () {
                                                                    setState(() {
                                                                      payingVia = i;
                                                                    });
                                                                  },
                                                                  child: Container(
                                                                    padding: EdgeInsets.all(media.width * 0.02),
                                                                    width: media.width * 0.9,
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.06,
                                                                              child: (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                  ? Image.asset(
                                                                                'assets/images/cash.png',
                                                                                fit: BoxFit.contain,
                                                                              )
                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                  ? Image.asset('assets/images/wallet.png', fit: BoxFit.contain, color: textColor)
                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                  ? Image.asset('assets/images/card.png', fit: BoxFit.contain, color: textColor)
                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
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
                                                                                  rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                  style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: textColor),
                                                                                ),
                                                                                Text(
                                                                                  (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                      ? languages[choosenLanguage]['text_paycash']
                                                                                      : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                      ? languages[choosenLanguage]['text_paywallet']
                                                                                      : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                      ? languages[choosenLanguage]['text_paycard']
                                                                                      : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
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
                                                                                      child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)) : Container(),
                                                                                    )
                                                                                  ],
                                                                                ))
                                                                          ],
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ));
                                                          })
                                                              .values
                                                              .toList(),
                                                        ),
                                                        SizedBox(
                                                          height:
                                                          media.height *
                                                              0.02,
                                                        ),
                                                        Container(
                                                          decoration:
                                                          BoxDecoration(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                12),
                                                            border: Border.all(
                                                                color:
                                                                borderLines,
                                                                width: 1.2),
                                                          ),
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                              media.width *
                                                                  0.025,
                                                              0,
                                                              media.width *
                                                                  0.025,
                                                              0),
                                                          width:
                                                          media.width *
                                                              0.9,
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                width: media
                                                                    .width *
                                                                    0.06,
                                                                child: Image.asset(
                                                                    'assets/images/promocode.png',
                                                                    fit: BoxFit
                                                                        .contain,
                                                                    color:
                                                                    textColor),
                                                              ),
                                                              SizedBox(
                                                                width: media
                                                                    .width *
                                                                    0.05,
                                                              ),
                                                              Expanded(
                                                                child: (promoStatus ==
                                                                    null)
                                                                    ? TextField(
                                                                  controller:
                                                                  promoKey,
                                                                  onChanged:
                                                                      (val) {
                                                                    setState(() {
                                                                      promoCode = val;
                                                                    });
                                                                  },
                                                                  decoration: InputDecoration(
                                                                      border: InputBorder.none,
                                                                      hintText: languages[choosenLanguage]['text_enterpromo'],
                                                                      hintStyle: GoogleFonts.roboto(fontSize: media.width * twelve, color: (isDarkTheme == true) ? textColor.withOpacity(0.3) : hintColor)),
                                                                  style:
                                                                  GoogleFonts.roboto(color: textColor),
                                                                )
                                                                    : (promoStatus ==
                                                                    1)
                                                                    ? Container(
                                                                  padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Column(
                                                                        children: [
                                                                          Text(promoKey.text, style: GoogleFonts.roboto(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                          Text(languages[choosenLanguage]['text_promoaccepted'], style: GoogleFonts.roboto(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                        ],
                                                                      ),
                                                                      InkWell(
                                                                        onTap: () async {
                                                                          setState(() {
                                                                            _isLoading = true;
                                                                          });
                                                                          dropStopList.clear();

                                                                          dynamic result;
                                                                          if (widget.type != 1) {
                                                                            if (addressList.length > 2) {
                                                                              for (var i = 1; i < addressList.length; i++) {
                                                                                dropStopList.add(DropStops(order: i.toString(), latitude: addressList[i].latlng.latitude, longitude: addressList[i].latlng.longitude, address: addressList[i].address));
                                                                              }
                                                                            }
                                                                            result = await etaRequest();
                                                                            if (result == 'logout') {
                                                                              navigateLogout();
                                                                            }
                                                                          } else {
                                                                            result = await rentalEta();
                                                                            if (result == 'logout') {
                                                                              navigateLogout();
                                                                            }
                                                                          }
                                                                          setState(() {
                                                                            _isLoading = false;
                                                                            if (result == true) {
                                                                              promoStatus = null;
                                                                              promoCode = '';
                                                                            }
                                                                          });
                                                                        },
                                                                        child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xff319900))),
                                                                      )
                                                                    ],
                                                                  ),
                                                                )
                                                                    : (promoStatus == 2)
                                                                    ? Container(
                                                                  padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Text(promoKey.text, style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                      InkWell(
                                                                        onTap: () async {
                                                                          setState(() {
                                                                            _isLoading = true;
                                                                            promoStatus = null;
                                                                            promoCode = '';
                                                                            promoKey.clear();
                                                                          });
                                                                          dropStopList.clear();

                                                                          if (widget.type != 1) {
                                                                            if (addressList.length > 2) {
                                                                              for (var i = 1; i < addressList.length; i++) {
                                                                                dropStopList.add(DropStops(order: i.toString(), latitude: addressList[i].latlng.latitude, longitude: addressList[i].latlng.longitude, address: addressList[i].address));
                                                                              }
                                                                            }
                                                                            var val = await etaRequest();
                                                                            if (val == 'logout') {
                                                                              navigateLogout();
                                                                            }
                                                                          } else {
                                                                            var val = await rentalEta();
                                                                            if (val == 'logout') {
                                                                              navigateLogout();
                                                                            }
                                                                          }

                                                                          setState(() {
                                                                            _isLoading = true;
                                                                          });
                                                                        },
                                                                        child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                      )
                                                                    ],
                                                                  ),
                                                                )
                                                                    : Container(),
                                                              )
                                                            ],
                                                          ),
                                                        ),

                                                        //promo code status
                                                        (promoStatus == 2)
                                                            ? Container(
                                                          width: media
                                                              .width *
                                                              0.9,
                                                          alignment:
                                                          Alignment
                                                              .center,
                                                          padding: EdgeInsets.only(
                                                              top: media.height *
                                                                  0.02),
                                                          child: Text(
                                                              languages[choosenLanguage]
                                                              [
                                                              'text_promorejected'],
                                                              style: GoogleFonts.roboto(
                                                                  fontSize: media.width *
                                                                      ten,
                                                                  color:
                                                                  const Color(0xffFF0000))),
                                                        )
                                                            : Container(),
                                                        SizedBox(
                                                          height:
                                                          media.height *
                                                              0.02,
                                                        ),
                                                        Button(
                                                            onTap:
                                                                () async {
                                                              if (promoCode ==
                                                                  '') {
                                                                setState(
                                                                        () {
                                                                      _choosePayment =
                                                                      false;
                                                                    });
                                                              } else {
                                                                setState(
                                                                        () {
                                                                      _isLoading =
                                                                      true;
                                                                    });
                                                                if (widget
                                                                    .type !=
                                                                    1) {
                                                                  var val =
                                                                  await etaRequestWithPromo();
                                                                  if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                } else {
                                                                  var val =
                                                                  await rentalRequestWithPromo();
                                                                  if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                }
                                                                setState(
                                                                        () {
                                                                      _isLoading =
                                                                      false;
                                                                    });
                                                              }
                                                            },
                                                            text: languages[
                                                            choosenLanguage]
                                                            [
                                                            'text_confirm'])
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ))
                                      : Container(),

                                  //bottom nav bar after request accepted
                                  (userRequestData['accepted_at'] != null)
                                      ? Positioned(
                                      top: MediaQuery.of(context)
                                          .padding
                                          .top +
                                          25,
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(
                                            media.width * 0.05,
                                            media.width * 0.025,
                                            media.width * 0.05,
                                            media.width * 0.025),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2)
                                            ],
                                            color: page),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 10,
                                              width: 10,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        blurRadius: 2,
                                                        color: Colors.black
                                                            .withOpacity(
                                                            0.2),
                                                        spreadRadius: 2)
                                                  ],
                                                  color: (userRequestData[
                                                  'accepted_at'] !=
                                                      null &&
                                                      userRequestData[
                                                      'arrived_at'] ==
                                                          null)
                                                      ? const Color(
                                                      0xff2E67D5)
                                                      : (userRequestData[
                                                  'accepted_at'] !=
                                                      null &&
                                                      userRequestData[
                                                      'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                      'is_trip_start'] ==
                                                          0)
                                                      ? const Color(
                                                      0xff319900)
                                                      : (userRequestData['accepted_at'] != null &&
                                                      userRequestData[
                                                      'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                      'is_trip_start'] !=
                                                          0)
                                                      ? const Color(
                                                      0xffFF0000)
                                                      : Colors
                                                      .transparent),
                                            ),
                                            SizedBox(
                                              width: media.width * 0.02,
                                            ),
                                            Text(
                                                (userRequestData['accepted_at'] != null &&
                                                    userRequestData['arrived_at'] ==
                                                        null &&
                                                    _dist != null)
                                                    ? languages[choosenLanguage][
                                                'text_arrive_eta'] +
                                                    ' ' +
                                                    double.parse(((_dist * 2)).toString())
                                                        .round()
                                                        .toString() +
                                                    ' ' +
                                                    languages[choosenLanguage]
                                                    ['text_mins']
                                                    : (userRequestData['accepted_at'] != null &&
                                                    userRequestData['arrived_at'] !=
                                                        null &&
                                                    userRequestData['is_trip_start'] ==
                                                        0)
                                                    ? languages[choosenLanguage]
                                                ['text_arrived']
                                                    : (userRequestData['accepted_at'] != null &&
                                                    userRequestData['arrived_at'] !=
                                                        null &&
                                                    userRequestData['is_trip_start'] !=
                                                        null &&
                                                    widget.type ==
                                                        null &&
                                                    _dist !=
                                                        null)
                                                    ? languages[choosenLanguage][
                                                'text_onride'] +
                                                    ' in ' +
                                                    double.parse(((_dist * 2)).toString())
                                                        .round()
                                                        .toString() +
                                                    ' ' +
                                                    languages[choosenLanguage]
                                                    [
                                                    'text_mins']
                                                    : languages[choosenLanguage]
                                                ['text_onride'],
                                                style: GoogleFonts.roboto(
                                                  fontSize:
                                                  media.width * twelve,
                                                  color: (userRequestData[
                                                  'accepted_at'] !=
                                                      null &&
                                                      userRequestData[
                                                      'arrived_at'] ==
                                                          null)
                                                      ? const Color(
                                                      0xff2E67D5)
                                                      : (userRequestData[
                                                  'accepted_at'] !=
                                                      null &&
                                                      userRequestData[
                                                      'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                      'is_trip_start'] ==
                                                          0)
                                                      ? const Color(
                                                      0xff319900)
                                                      : (userRequestData['accepted_at'] != null &&
                                                      userRequestData[
                                                      'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                      'is_trip_start'] ==
                                                          1)
                                                      ? const Color(
                                                      0xffFF0000)
                                                      : (etaDetails
                                                      .isNotEmpty)
                                                      ? Colors
                                                      .orange
                                                      : Colors
                                                      .transparent,
                                                ))
                                          ],
                                        ),
                                      ))
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                      userRequestData['is_later'] ==
                                          null &&
                                      userRequestData['accepted_at'] ==
                                          null ||
                                      userRequestData.isNotEmpty &&
                                          userRequestData['is_later'] ==
                                              0 &&
                                          userRequestData['accepted_at'] ==
                                              null)
                                      ? Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: media.width * 1,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        const BorderRadius.only(
                                            topLeft:
                                            Radius.circular(12),
                                            topRight:
                                            Radius.circular(12)),
                                        color: page,
                                      ),
                                      padding: EdgeInsets.all(
                                          media.width * 0.05),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                            ['text_findingdriver'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width *
                                                    fourteen,
                                                color: textColor,
                                                fontWeight:
                                                FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          SizedBox(
                                            height: media.width * 0.4,
                                            child: Image.asset(
                                              'assets/images/waiting_time.gif',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          Container(
                                            height: media.width * 0.02,
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    media.width *
                                                        0.01),
                                                color: Colors.grey),
                                            alignment:
                                            Alignment.centerLeft,
                                            child: Container(
                                              height: media.width * 0.02,
                                              width: (media.width *
                                                  0.9 *
                                                  (timing /
                                                      userDetails[
                                                      'maximum_time_for_find_drivers_for_regular_ride'])),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(media
                                                      .width *
                                                      0.01),
                                                  color: buttonColor),
                                            ),
                                          ),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.end,
                                            children: [
                                              (timing != null)
                                                  ? Text(
                                                '${Duration(seconds: timing).toString().substring(3, 7)} mins',
                                                style: GoogleFonts.roboto(
                                                    fontSize: media
                                                        .width *
                                                        ten,
                                                    color: textColor
                                                        .withOpacity(
                                                        0.4)),
                                              )
                                                  : Container()
                                            ],
                                          ),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          Text(
                                            languages[choosenLanguage]
                                            ['text_finddriverdesc'],
                                            style: GoogleFonts.roboto(
                                              fontSize:
                                              media.width * twelve,
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          Button(
                                              width: media.width * 0.5,
                                              onTap: () async {
                                                var val =
                                                await cancelRequest();
                                                if (val == 'logout') {
                                                  navigateLogout();
                                                }
                                              },
                                              text: languages[
                                              choosenLanguage]
                                              ['text_cancel'])
                                        ],
                                      ),
                                    ),
                                  )
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                      userRequestData['accepted_at'] !=
                                          null)
                                      ? Positioned(
                                      bottom: 0,
                                      child: GestureDetector(
                                        onVerticalDragStart: (v) {
                                          start = v.globalPosition.dy;
                                          gesture.clear();
                                        },
                                        onVerticalDragUpdate: (v) {
                                          gesture.add(v.globalPosition.dy);
                                        },
                                        onVerticalDragEnd: (v) {
                                          if (gesture.isNotEmpty &&
                                              start >
                                                  gesture[
                                                  gesture.length - 1] &&
                                              _ontripBottom == false) {
                                            setState(() {
                                              _ontripBottom = true;
                                            });
                                          } else if (gesture.isNotEmpty &&
                                              start <
                                                  gesture[
                                                  gesture.length - 1] &&
                                              _ontripBottom == true) {
                                            setState(() {
                                              _ontripBottom = false;
                                            });
                                          }
                                        },
                                        child: Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 1,
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                const BorderRadius.only(
                                                    topLeft:
                                                    Radius.circular(
                                                        12),
                                                    topRight:
                                                    Radius.circular(
                                                        12))),
                                            child: SingleChildScrollView(
                                              physics:
                                              const BouncingScrollPhysics(),
                                              child: Column(
                                                children: [
                                                  // SizedBox(height: media.width*0.02,),
                                                  Container(
                                                    height:
                                                    media.width * 0.02,
                                                    width:
                                                    media.width * 0.2,
                                                    decoration:
                                                    BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          media.width *
                                                              0.01),
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  (userRequestData[
                                                  'is_trip_start'] !=
                                                      1 &&
                                                      userRequestData[
                                                      'show_otp_feature'] ==
                                                          true)
                                                      ? Container(
                                                    padding: EdgeInsets
                                                        .fromLTRB(
                                                        0,
                                                        media.width *
                                                            0.02,
                                                        0,
                                                        0),
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                      [
                                                      'text_startridewithotp'] +
                                                          ':' +
                                                          userRequestData[
                                                          'ride_otp']
                                                              .toString(),
                                                      style: GoogleFonts.roboto(
                                                          fontSize: media
                                                              .width *
                                                              fourteen,
                                                          color:
                                                          textColor,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600),
                                                    ),
                                                  )
                                                      : Container(),
                                                  SizedBox(
                                                    height:
                                                    media.height * 0.02,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                        media.width *
                                                            0.16,
                                                        width: media.width *
                                                            0.16,
                                                        decoration: BoxDecoration(
                                                            shape: BoxShape
                                                                .circle,
                                                            image: DecorationImage(
                                                                image: NetworkImage(userRequestData['driverDetail']
                                                                [
                                                                'data']
                                                                [
                                                                'profile_picture']),
                                                                fit: BoxFit
                                                                    .cover)),
                                                      ),
                                                      SizedBox(
                                                          width:
                                                          media.width *
                                                              0.05),
                                                      Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          Text(
                                                            userRequestData[
                                                            'driverDetail']
                                                            ['data']
                                                            ['name'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media
                                                                    .width *
                                                                    eighteen,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                                color:
                                                                textColor),
                                                          ),
                                                          SizedBox(
                                                              height: media
                                                                  .width *
                                                                  0.03),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                userRequestData['driverDetail']['data']
                                                                [
                                                                'rating']
                                                                    .toString(),
                                                                style: GoogleFonts.roboto(
                                                                    fontSize:
                                                                    media.width *
                                                                        twelve,
                                                                    color:
                                                                    textColor),
                                                              ),
                                                              Icon(
                                                                Icons.star,
                                                                color:
                                                                buttonColor,
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .end,
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Container(
                                                                  height: media
                                                                      .width *
                                                                      0.069,
                                                                  decoration: BoxDecoration(
                                                                      border: Border.all(
                                                                          color: Colors.black,
                                                                          width: 1.2),
                                                                      borderRadius: BorderRadius.circular(12)),
                                                                  padding: EdgeInsets.fromLTRB(
                                                                      media.width *
                                                                          0.02,
                                                                      media.width *
                                                                          0.01,
                                                                      media.width *
                                                                          0.02,
                                                                      media.width *
                                                                          0.01),
                                                                  child:
                                                                  Text(
                                                                    userRequestData['driverDetail']['data']
                                                                    [
                                                                    'car_number'],
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize: media.width *
                                                                            fourteen,
                                                                        fontWeight:
                                                                        FontWeight.w600,
                                                                        color: textColor),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: media.width *
                                                                        0.03),
                                                                Text(
                                                                  userRequestData['driverDetail']['data']['car_color'] +
                                                                      ' ' +
                                                                      userRequestData['driverDetail']['data']
                                                                      [
                                                                      'car_make_name'] +
                                                                      ' ' +
                                                                      userRequestData['driverDetail']['data']
                                                                      [
                                                                      'car_model_name'],
                                                                  style: GoogleFonts.roboto(
                                                                      fontSize: media.width *
                                                                          twelve,
                                                                      color:
                                                                      textColor),
                                                                )
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height:
                                                    media.width * 0.05,
                                                  ),
                                                  (userRequestData[
                                                  'is_trip_start'] !=
                                                      1)
                                                      ? Row(
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          makingPhoneCall(userRequestData['driverDetail']
                                                          [
                                                          'data']
                                                          [
                                                          'mobile']);
                                                        },
                                                        child:
                                                        Container(
                                                          height: media
                                                              .width *
                                                              0.117,
                                                          width: media
                                                              .width *
                                                              0.128,
                                                          decoration:
                                                          BoxDecoration(
                                                            border: Border.all(
                                                                color:
                                                                borderLines,
                                                                width:
                                                                1.1),
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                          ),
                                                          alignment:
                                                          Alignment
                                                              .center,
                                                          child:
                                                          SizedBox(
                                                            height: media
                                                                .width *
                                                                0.064,
                                                            width: media
                                                                .width *
                                                                0.064,
                                                            child:
                                                            RotatedBox(
                                                              quarterTurns: (languageDirection ==
                                                                  'rtl')
                                                                  ? 3
                                                                  : 0,
                                                              child: Image
                                                                  .asset(
                                                                'assets/images/call.png',
                                                                fit: BoxFit
                                                                    .contain,
                                                                color:
                                                                textColor,
                                                                // height: media.width*0.064,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: media
                                                            .width *
                                                            0.05,
                                                      ),
                                                      Expanded(
                                                          child:
                                                          InkWell(
                                                            onTap:
                                                                () async {
                                                              var result = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) =>
                                                                      const ChatPage()));
                                                              if (result) {
                                                                setState(
                                                                        () {});
                                                              }
                                                            },
                                                            child:
                                                            Container(
                                                              padding: EdgeInsets.all(
                                                                  media.width *
                                                                      0.03),
                                                              height: media
                                                                  .width *
                                                                  0.117,
                                                              decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                      color: (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isEmpty)
                                                                          ? borderLines
                                                                          : const Color(
                                                                          0xffFF0000),
                                                                      width:
                                                                      1.1),
                                                                  borderRadius:
                                                                  BorderRadius.circular(12)),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                    Text(
                                                                      (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isEmpty)
                                                                          ? languages[choosenLanguage]['text_pickup_instruction']
                                                                          : languages[choosenLanguage]['text_newmessagereceived'],
                                                                      style: GoogleFonts.roboto(
                                                                          fontSize: media.width * twelve,
                                                                          color: (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isEmpty)
                                                                              ? (isDarkTheme == true)
                                                                              ? textColor.withOpacity(0.3)
                                                                              : hintColor
                                                                              : const Color(0xffFF0000)),
                                                                    ),
                                                                  ),
                                                                  (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isEmpty)
                                                                      ? RotatedBox(
                                                                    quarterTurns: (languageDirection == 'rtl') ? 2 : 0,
                                                                    child: Image.asset(
                                                                      'assets/images/send.png',
                                                                      color: textColor,
                                                                    ),
                                                                  )
                                                                      : Text(
                                                                    chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).length.toString(),
                                                                    style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xffFF0000)),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ))
                                                    ],
                                                  )
                                                      : Container(),
                                                  SizedBox(
                                                    height:
                                                    media.width * 0.05,
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                        media.width *
                                                            0.034),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                            borderLines,
                                                            width: 1.2),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                            12)),
                                                    width:
                                                    media.width * 0.9,
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                          children: [
                                                            Container(
                                                              height: media
                                                                  .width *
                                                                  0.025,
                                                              width: media
                                                                  .width *
                                                                  0.025,
                                                              alignment:
                                                              Alignment
                                                                  .center,
                                                              decoration: BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: const Color(
                                                                      0xff319900)
                                                                      .withOpacity(
                                                                      0.3)),
                                                              child:
                                                              Container(
                                                                height: media
                                                                    .width *
                                                                    0.01,
                                                                width: media
                                                                    .width *
                                                                    0.01,
                                                                decoration: const BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: Color(
                                                                        0xff319900)),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: media
                                                                  .width *
                                                                  0.75,
                                                              child: Text(
                                                                userRequestData[
                                                                'pick_address'],
                                                                style: GoogleFonts.roboto(
                                                                    fontSize:
                                                                    media.width *
                                                                        twelve,
                                                                    color:
                                                                    textColor),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        SizedBox(
                                                            height: media
                                                                .width *
                                                                0.02),
                                                        (userRequestData[
                                                        'is_rental'] !=
                                                            true &&
                                                            userRequestData[
                                                            'drop_address'] !=
                                                                null)
                                                            ? Column(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                          children: [
                                                            (tripStops.isNotEmpty &&
                                                                _ontripBottom == true)
                                                                ? Column(
                                                              children: tripStops
                                                                  .asMap()
                                                                  .map((i, value) {
                                                                return MapEntry(
                                                                    i,
                                                                    (i != tripStops.length - 1)
                                                                        ? Container(
                                                                      padding: EdgeInsets.only(bottom: media.width * 0.02),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Container(
                                                                            height: media.width * 0.025,
                                                                            width: media.width * 0.025,
                                                                            alignment: Alignment.center,
                                                                            decoration: BoxDecoration(shape: BoxShape.circle, color: tripStops[i]['for_pickup'] == 1 ? const Color(0xff319900).withOpacity(0.3) : const Color(0xffFF0000).withOpacity(0.3)),
                                                                            child: Container(
                                                                              height: media.width * 0.01,
                                                                              width: media.width * 0.01,
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: tripStops[i]['for_pickup'] == 1 ? const Color(0xff319900) : const Color(0xffFF0000)),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width: media.width * 0.75,
                                                                            child: Text(
                                                                              tripStops[i]['address'],
                                                                              style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )
                                                                        : Container());
                                                              })
                                                                  .values
                                                                  .toList(),
                                                            )
                                                                : Container(),
                                                            (userRequestData['is_rental'] != true &&
                                                                userRequestData['drop_address'] != null)
                                                                ? Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Container(
                                                                  height: media.width * 0.025,
                                                                  width: media.width * 0.025,
                                                                  alignment: Alignment.center,
                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffFF0000).withOpacity(0.3)),
                                                                  child: Container(
                                                                    height: media.width * 0.01,
                                                                    width: media.width * 0.01,
                                                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffFF0000)),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: media.width * 0.75,
                                                                  child: Text(
                                                                    userRequestData['drop_address'],
                                                                    style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor),
                                                                  ),
                                                                )
                                                              ],
                                                            )
                                                                : Container(),
                                                          ],
                                                        )
                                                            : Container(),
                                                        (userRequestData[
                                                        'is_trip_start'] !=
                                                            1)
                                                            ? Container(
                                                          margin: EdgeInsets.only(
                                                              bottom: media.width *
                                                                  0.05),
                                                          height: 1,
                                                          width: media
                                                              .width *
                                                              0.9,
                                                          color:
                                                          borderLines,
                                                        )
                                                            : Container(),
                                                        (userRequestData[
                                                        'is_trip_start'] !=
                                                            1)
                                                            ? Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                          children: [
                                                            (userRequestData['is_trip_start'] !=
                                                                1)
                                                                ? InkWell(
                                                              onTap: () async {
                                                                setState(() {
                                                                  _isLoading = true;
                                                                });
                                                                var reason = await cancelReason((userRequestData['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                if (reason == true) {
                                                                  setState(() {
                                                                    _cancellingError = '';
                                                                    _cancelling = true;
                                                                  });
                                                                } else if (reason == 'logout') {
                                                                  navigateLogout();
                                                                }
                                                                setState(() {
                                                                  _isLoading = false;
                                                                });
                                                              },
                                                              child: Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: media.width * 0.064,
                                                                    width: media.width * 0.064,
                                                                    child: Image.asset(
                                                                      'assets/images/cancel.png',
                                                                      color: textColor,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media.width * 0.02,
                                                                  ),
                                                                  Text(
                                                                    languages[choosenLanguage]['text_cancel'],
                                                                    style: GoogleFonts.roboto(fontSize: media.width * ten, fontWeight: FontWeight.w600, color: textColor),
                                                                  )
                                                                ],
                                                              ),
                                                            )
                                                                : Container(),
                                                          ],
                                                        )
                                                            : Container(),
                                                        SizedBox(
                                                          height:
                                                          media.width *
                                                              0.05,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  (_ontripBottom == true)
                                                      ? Container(
                                                    margin: EdgeInsets
                                                        .only(
                                                        top: media
                                                            .width *
                                                            0.05),
                                                    padding: EdgeInsets
                                                        .all(media
                                                        .width *
                                                        0.02),
                                                    height:
                                                    media.width *
                                                        0.2,
                                                    width:
                                                    media.width *
                                                        0.9,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                            borderLines,
                                                            width:
                                                            1.2),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                            12)),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          languages[
                                                          choosenLanguage]
                                                          [
                                                          'text_payingvia'],
                                                          style: GoogleFonts
                                                              .roboto(
                                                            fontSize:
                                                            media.width *
                                                                twelve,
                                                            color: const Color(
                                                                0xff666666),
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: media.width *
                                                                  0.06,
                                                              child: (userRequestData['payment_opt'] ==
                                                                  '1')
                                                                  ? Image.asset(
                                                                'assets/images/cash.png',
                                                                fit: BoxFit.contain,
                                                              )
                                                                  : (userRequestData['payment_opt'] == '2')
                                                                  ? Image.asset('assets/images/wallet.png', fit: BoxFit.contain, color: textColor)
                                                                  : (userRequestData['payment_opt'] == '0')
                                                                  ? Image.asset('assets/images/card.png', fit: BoxFit.contain, color: textColor)
                                                                  : Container(),
                                                            ),
                                                            SizedBox(
                                                              width: media.width *
                                                                  0.05,
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  (userRequestData.isNotEmpty)
                                                                      ? userRequestData['payment_type_string']
                                                                      : etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia].toString(),
                                                                  style: GoogleFonts.roboto(
                                                                      fontSize: media.width * fourteen,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: textColor),
                                                                ),
                                                                Text(
                                                                  (userRequestData['payment_opt'] == '1')
                                                                      ? languages[choosenLanguage]['text_paycash']
                                                                      : (userRequestData['payment_opt'] == '2')
                                                                      ? languages[choosenLanguage]['text_paywallet']
                                                                      : (userRequestData['payment_opt'] == '0')
                                                                      ? languages[choosenLanguage]['text_paycard']
                                                                      : '',
                                                                  style:
                                                                  GoogleFonts.roboto(fontSize: media.width * ten, color: textColor),
                                                                )
                                                              ],
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                      : Container()
                                                ],
                                              ),
                                            )),
                                      ))
                                      : Container(),

                                  //cancel request
                                  (_cancelling == true)
                                      ? Positioned(
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        // color: Colors.transparent
                                        //     .withOpacity(0.6),
                                        color: (isDarkTheme == true)
                                            ? textColor.withOpacity(0.2)
                                            : Colors.transparent
                                            .withOpacity(0.6),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  color: page,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      12)),
                                              child: Column(children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                  const BoxDecoration(
                                                      shape:
                                                      BoxShape.circle,
                                                      color: Color(
                                                          0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height:
                                                    media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                    const BoxDecoration(
                                                        shape: BoxShape
                                                            .circle,
                                                        color: Color(
                                                            0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.cancel_outlined,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: cancelReasonsList
                                                      .asMap()
                                                      .map((i, value) {
                                                    return MapEntry(
                                                        i,
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _cancelReason =
                                                              cancelReasonsList[i]
                                                              [
                                                              'reason'];
                                                            });
                                                          },
                                                          child:
                                                          Container(
                                                            padding: EdgeInsets
                                                                .all(media
                                                                .width *
                                                                0.01),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  height: media.height *
                                                                      0.05,
                                                                  width: media.width *
                                                                      0.05,
                                                                  decoration: BoxDecoration(
                                                                      shape:
                                                                      BoxShape.circle,
                                                                      border: Border.all(color: textColor, width: 1.2)),
                                                                  alignment:
                                                                  Alignment.center,
                                                                  child: (_cancelReason ==
                                                                      cancelReasonsList[i]['reason'])
                                                                      ? Container(
                                                                    height: media.width * 0.03,
                                                                    width: media.width * 0.03,
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      color: textColor,
                                                                    ),
                                                                  )
                                                                      : Container(),
                                                                ),
                                                                SizedBox(
                                                                  width: media.width *
                                                                      0.05,
                                                                ),
                                                                SizedBox(
                                                                    width: media.width *
                                                                        0.65,
                                                                    child:
                                                                    Text(
                                                                      cancelReasonsList[i]['reason'],
                                                                      style:
                                                                      TextStyle(color: textColor),
                                                                    ))
                                                              ],
                                                            ),
                                                          ),
                                                        ));
                                                  })
                                                      .values
                                                      .toList(),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _cancelReason =
                                                      'others';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.01),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          height:
                                                          media.height *
                                                              0.05,
                                                          width: media.width *
                                                              0.05,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color:
                                                                  textColor,
                                                                  width:
                                                                  1.2)),
                                                          alignment: Alignment
                                                              .center,
                                                          child:
                                                          (_cancelReason ==
                                                              'others')
                                                              ? Container(
                                                            height: media.width *
                                                                0.03,
                                                            width: media.width *
                                                                0.03,
                                                            decoration:
                                                            BoxDecoration(
                                                              shape:
                                                              BoxShape.circle,
                                                              color:
                                                              textColor,
                                                            ),
                                                          )
                                                              : Container(),
                                                        ),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.05,
                                                        ),
                                                        Text(
                                                          languages[
                                                          choosenLanguage]
                                                          ['text_others'],
                                                          style: TextStyle(
                                                              color:
                                                              textColor),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                (_cancelReason == 'others')
                                                    ? Container(
                                                  margin: EdgeInsets
                                                      .fromLTRB(
                                                      0,
                                                      media.width *
                                                          0.025,
                                                      0,
                                                      media.width *
                                                          0.025),
                                                  padding:
                                                  EdgeInsets.all(
                                                      media.width *
                                                          0.05),
                                                  // height: media.width*0.2,
                                                  width:
                                                  media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                          borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          12)),
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                        border:
                                                        InputBorder
                                                            .none,
                                                        hintText: languages[
                                                        choosenLanguage]
                                                        [
                                                        'text_cancelRideReason'],
                                                        hintStyle: GoogleFonts.roboto(
                                                            color: textColor
                                                                .withOpacity(
                                                                0.4),
                                                            fontSize: media
                                                                .width *
                                                                twelve)),
                                                    style: TextStyle(
                                                        color:
                                                        textColor),
                                                    maxLines: 4,
                                                    minLines: 2,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _cancelCustomReason =
                                                            val;
                                                      });
                                                    },
                                                  ),
                                                )
                                                    : Container(),
                                                (_cancellingError != '')
                                                    ? Container(
                                                    padding: EdgeInsets.only(
                                                        top: media.width *
                                                            0.02,
                                                        bottom:
                                                        media.width *
                                                            0.02),
                                                    width:
                                                    media.width * 0.9,
                                                    child: Text(
                                                        _cancellingError,
                                                        style: GoogleFonts.roboto(
                                                            fontSize: media
                                                                .width *
                                                                twelve,
                                                            color: Colors
                                                                .red)))
                                                    : Container(),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    Button(
                                                        color: page,
                                                        textcolor:
                                                        buttonColor,
                                                        width: media.width *
                                                            0.39,
                                                        onTap: () async {
                                                          setState(() {
                                                            _isLoading = true;
                                                          });
                                                          if (_cancelReason !=
                                                              '') {
                                                            if (_cancelReason ==
                                                                'others') {
                                                              if (_cancelCustomReason !=
                                                                  '' &&
                                                                  _cancelCustomReason
                                                                      .isNotEmpty) {
                                                                _cancellingError =
                                                                '';
                                                                var val =
                                                                await cancelRequestWithReason(
                                                                    _cancelCustomReason);
                                                                if (val ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                                setState(() {
                                                                  _cancelling =
                                                                  false;
                                                                });
                                                              } else {
                                                                setState(() {
                                                                  _cancellingError =
                                                                  languages[choosenLanguage]
                                                                  [
                                                                  'text_add_cancel_reason'];
                                                                });
                                                              }
                                                            } else {
                                                              var val =
                                                              await cancelRequestWithReason(
                                                                  _cancelReason);
                                                              if (val ==
                                                                  'logout') {
                                                                navigateLogout();
                                                              }
                                                              setState(() {
                                                                _cancelling =
                                                                false;
                                                              });
                                                            }
                                                          } else {}
                                                          setState(() {
                                                            _isLoading =
                                                            false;
                                                          });
                                                        },
                                                        text: languages[
                                                        choosenLanguage]
                                                        ['text_cancel']),
                                                    Button(
                                                        width: media.width *
                                                            0.39,
                                                        onTap: () {
                                                          setState(() {
                                                            _cancelling =
                                                            false;
                                                          });
                                                        },
                                                        text: languages[
                                                        choosenLanguage]
                                                        [
                                                        'tex_dontcancel'])
                                                  ],
                                                )
                                              ]),
                                            ),
                                          ],
                                        ),
                                      ))
                                      : Container(),

                                  //date picker for ride later
                                  (_dateTimePicker == true)
                                      ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color: Colors.transparent
                                            .withOpacity(0.6),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                      height: media.height *
                                                          0.1,
                                                      width: media.width *
                                                          0.1,
                                                      decoration:
                                                      BoxDecoration(
                                                          shape: BoxShape
                                                              .circle,
                                                          color: page),
                                                      child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _dateTimePicker =
                                                              false;
                                                            });
                                                          },
                                                          child: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color:
                                                              textColor))),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: media.width * 0.5,
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                                  color: topBar),
                                              child: CupertinoDatePicker(
                                                  minimumDate: DateTime.now()
                                                      .add(Duration(
                                                      minutes: int.parse(
                                                          userDetails[
                                                          'user_can_make_a_ride_after_x_miniutes']))),
                                                  initialDateTime: DateTime.now()
                                                      .add(Duration(
                                                      minutes: int.parse(
                                                          userDetails[
                                                          'user_can_make_a_ride_after_x_miniutes']))),
                                                  maximumDate:
                                                  DateTime.now().add(
                                                      const Duration(
                                                          days: 4)),
                                                  onDateTimeChanged: (val) {
                                                    choosenDateTime = val;
                                                  }),
                                            ),
                                            Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Button(
                                                    onTap: () {
                                                      setState(() {
                                                        _dateTimePicker =
                                                        false;
                                                        _confirmRideLater =
                                                        true;
                                                      });
                                                    },
                                                    text: languages[
                                                    choosenLanguage]
                                                    ['text_confirm']))
                                          ],
                                        ),
                                      ))
                                      : Container(),

                                  //confirm ride later
                                  (_confirmRideLater == true)
                                      ? Positioned(
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color: Colors.transparent
                                          .withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                    height: media.height *
                                                        0.1,
                                                    width: media.width *
                                                        0.1,
                                                    decoration:
                                                    BoxDecoration(
                                                        shape: BoxShape
                                                            .circle,
                                                        color: page),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _dateTimePicker =
                                                            true;
                                                            _confirmRideLater =
                                                            false;
                                                          });
                                                        },
                                                        child: Icon(
                                                            Icons
                                                                .cancel_outlined,
                                                            color:
                                                            textColor))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                                border: Border.all(
                                                    color: topBar),
                                                color: page),
                                            child: Column(
                                              children: [
                                                Text(
                                                  languages[
                                                  choosenLanguage]
                                                  [
                                                  'text_confirmridelater'],
                                                  style: GoogleFonts
                                                      .roboto(
                                                      fontSize: media
                                                          .width *
                                                          fourteen,
                                                      color:
                                                      textColor),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width * 0.05,
                                                ),
                                                Text(
                                                  DateFormat()
                                                      .format(
                                                      choosenDateTime)
                                                      .toString(),
                                                  style:
                                                  GoogleFonts.roboto(
                                                      fontSize: media
                                                          .width *
                                                          sixteen,
                                                      color:
                                                      textColor,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      if (widget.type !=
                                                          1) {
                                                        if (etaDetails[
                                                        choosenVehicle]
                                                        [
                                                        'has_discount'] ==
                                                            false) {
                                                          dynamic val;
                                                          setState(() {
                                                            _isLoading =
                                                            true;
                                                          });

                                                          val =
                                                          await createRequestLater();
                                                          if (val ==
                                                              'logout') {
                                                            navigateLogout();
                                                          }
                                                          setState(() {
                                                            if (val ==
                                                                'success') {
                                                              _isLoading =
                                                              false;
                                                              _confirmRideLater =
                                                              false;
                                                              _rideLaterSuccess =
                                                              true;
                                                            }
                                                          });
                                                        } else {
                                                          dynamic val;
                                                          setState(() {
                                                            _isLoading =
                                                            true;
                                                          });

                                                          val =
                                                          await createRequestLaterPromo();
                                                          if (val ==
                                                              'logout') {
                                                            navigateLogout();
                                                          }
                                                          setState(() {
                                                            if (val ==
                                                                'success') {
                                                              _isLoading =
                                                              false;

                                                              _confirmRideLater =
                                                              false;
                                                              _rideLaterSuccess =
                                                              true;
                                                            }
                                                          });
                                                        }
                                                      } else {
                                                        if (rentalOption[
                                                        choosenVehicle]
                                                        [
                                                        'has_discount'] ==
                                                            false) {
                                                          dynamic val;
                                                          setState(() {
                                                            _isLoading =
                                                            true;
                                                          });

                                                          val =
                                                          await createRentalRequestLater();
                                                          if (val ==
                                                              'logout') {
                                                            navigateLogout();
                                                          }
                                                          setState(() {
                                                            if (val ==
                                                                'success') {
                                                              _isLoading =
                                                              false;
                                                              _confirmRideLater =
                                                              false;
                                                              _rideLaterSuccess =
                                                              true;
                                                            }
                                                          });
                                                        } else {
                                                          dynamic val;
                                                          setState(() {
                                                            _isLoading =
                                                            true;
                                                          });

                                                          val =
                                                          await createRentalRequestLaterPromo();
                                                          if (val ==
                                                              'logout') {
                                                            navigateLogout();
                                                          }
                                                          setState(() {
                                                            if (val ==
                                                                'success') {
                                                              _isLoading =
                                                              false;

                                                              _confirmRideLater =
                                                              false;
                                                              _rideLaterSuccess =
                                                              true;
                                                            }
                                                          });
                                                        }
                                                        setState(() {
                                                          _isLoading =
                                                          false;
                                                        });
                                                      }
                                                    },
                                                    text: languages[
                                                    choosenLanguage]
                                                    ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                      : Container(),

                                  //ride later success
                                  (_rideLaterSuccess == true)
                                      ? Positioned(
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color: Colors.transparent
                                            .withOpacity(0.6),
                                        child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                    border: Border.all(
                                                        color: topBar),
                                                    color: page),
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      languages[
                                                      choosenLanguage]
                                                      [
                                                      'text_rideLaterSuccess'],
                                                      style:
                                                      GoogleFonts.roboto(
                                                          fontSize: media
                                                              .width *
                                                              fourteen,
                                                          color:
                                                          textColor,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                      media.width * 0.05,
                                                    ),
                                                    Button(
                                                        onTap: () {
                                                          addressList
                                                              .removeWhere(
                                                                  (element) =>
                                                              element
                                                                  .id ==
                                                                  'drop');
                                                          _rideLaterSuccess =
                                                          false;
                                                          // addressList.clear();
                                                          myMarker.clear();
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                  const Maps()),
                                                                  (route) =>
                                                              false);
                                                        },
                                                        text: languages[
                                                        choosenLanguage]
                                                        ['text_confirm'])
                                                  ],
                                                ),
                                              )
                                            ]),
                                      ))
                                      : Container(),

                                  //sos popup
                                  (showSos == true)
                                      ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color: (isDarkTheme == true)
                                            ? textColor.withOpacity(0.2)
                                            : Colors.transparent
                                            .withOpacity(0.6),
                                        child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.7,
                                                child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          notifyCompleted =
                                                          false;
                                                          showSos = false;
                                                        });
                                                      },
                                                      child: Container(
                                                        height:
                                                        media.width *
                                                            0.1,
                                                        width: media.width *
                                                            0.1,
                                                        decoration:
                                                        BoxDecoration(
                                                            shape: BoxShape
                                                                .circle,
                                                            color:
                                                            page),
                                                        child: Icon(
                                                            Icons
                                                                .cancel_outlined,
                                                            color:
                                                            textColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                height: media.height * 0.5,
                                                width: media.width * 0.7,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(12),
                                                    color: page),
                                                child:
                                                SingleChildScrollView(
                                                    physics:
                                                    const BouncingScrollPhysics(),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        InkWell(
                                                          onTap:
                                                              () async {
                                                            setState(
                                                                    () {
                                                                  notifyCompleted =
                                                                  false;
                                                                });
                                                            var val =
                                                            await notifyAdmin();
                                                            if (val ==
                                                                true) {
                                                              setState(
                                                                      () {
                                                                    notifyCompleted =
                                                                    true;
                                                                  });
                                                            }
                                                          },
                                                          child:
                                                          Container(
                                                            padding: EdgeInsets.all(
                                                                media.width *
                                                                    0.05),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      languages[choosenLanguage]['text_notifyadmin'],
                                                                      style: GoogleFonts.roboto(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                    ),
                                                                    (notifyCompleted == true)
                                                                        ? Container(
                                                                      padding: EdgeInsets.only(top: media.width * 0.01),
                                                                      child: Text(
                                                                        languages[choosenLanguage]['text_notifysuccess'],
                                                                        style: GoogleFonts.roboto(
                                                                          fontSize: media.width * twelve,
                                                                          color: const Color(0xff319900),
                                                                        ),
                                                                      ),
                                                                    )
                                                                        : Container()
                                                                  ],
                                                                ),
                                                                Icon(
                                                                    Icons
                                                                        .notification_add,
                                                                    color:
                                                                    textColor)
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        (sosData.isNotEmpty)
                                                            ? Column(
                                                          children: sosData
                                                              .asMap()
                                                              .map((i, value) {
                                                            return MapEntry(
                                                                i,
                                                                InkWell(
                                                                  onTap: () {
                                                                    makingPhoneCall(sosData[i]['number'].toString().replaceAll(' ', ''));
                                                                  },
                                                                  child: Container(
                                                                    padding: EdgeInsets.all(media.width * 0.05),
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.4,
                                                                              child: Text(
                                                                                sosData[i]['name'],
                                                                                style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.01,
                                                                            ),
                                                                            Text(
                                                                              sosData[i]['number'],
                                                                              style: GoogleFonts.roboto(
                                                                                fontSize: media.width * twelve,
                                                                                color: textColor,
                                                                              ),
                                                                            )
                                                                          ],
                                                                        ),
                                                                        Icon(Icons.call, color: textColor)
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ));
                                                          })
                                                              .values
                                                              .toList(),
                                                        )
                                                            : Container(
                                                          width: media.width *
                                                              0.7,
                                                          alignment:
                                                          Alignment.center,
                                                          child:
                                                          Text(
                                                            languages[choosenLanguage]
                                                            [
                                                            'text_noDataFound'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media.width * eighteen,
                                                                fontWeight: FontWeight.w600,
                                                                color: textColor),
                                                          ),
                                                        ),
                                                      ],
                                                    )),
                                              )
                                            ]),
                                      ))
                                      : Container(),

                                  (_locationDenied == true)
                                      ? Positioned(
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color: Colors.transparent
                                            .withOpacity(0.6),
                                        child: Column(
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
                                                        _locationDenied =
                                                        false;
                                                      });
                                                    },
                                                    child: Container(
                                                      height:
                                                      media.height * 0.05,
                                                      width:
                                                      media.height * 0.05,
                                                      decoration:
                                                      BoxDecoration(
                                                        color: page,
                                                        shape:
                                                        BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                          Icons.cancel,
                                                          color: buttonColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                                height: media.width * 0.025),
                                            Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                                  color: page,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        blurRadius: 2.0,
                                                        spreadRadius: 2.0,
                                                        color: Colors.black
                                                            .withOpacity(0.2))
                                                  ]),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                      width:
                                                      media.width * 0.8,
                                                      child: Text(
                                                        languages[
                                                        choosenLanguage]
                                                        [
                                                        'text_open_loc_settings'],
                                                        style: GoogleFonts.roboto(
                                                            fontSize:
                                                            media.width *
                                                                sixteen,
                                                            color: textColor,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600),
                                                      )),
                                                  SizedBox(
                                                      height:
                                                      media.width * 0.05),
                                                  Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      InkWell(
                                                          onTap: () async {
                                                            await perm
                                                                .openAppSettings();
                                                          },
                                                          child: Text(
                                                            languages[
                                                            choosenLanguage]
                                                            [
                                                            'text_open_settings'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media
                                                                    .width *
                                                                    sixteen,
                                                                color:
                                                                buttonColor,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                          )),
                                                      InkWell(
                                                          onTap: () async {
                                                            setState(() {
                                                              _locationDenied =
                                                              false;
                                                              _isLoading =
                                                              true;
                                                            });

                                                            if (locationAllowed ==
                                                                true) {
                                                              if (positionStream ==
                                                                  null ||
                                                                  positionStream!
                                                                      .isPaused) {
                                                                positionStreamData();
                                                              }
                                                            }
                                                          },
                                                          child: Text(
                                                            languages[
                                                            choosenLanguage]
                                                            ['text_done'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media
                                                                    .width *
                                                                    sixteen,
                                                                color:
                                                                buttonColor,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                          ))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ))
                                      : Container(),

                                  //displaying address details for edit
                                  ((dropConfirmed == false &&
                                      userRequestData.isEmpty &&
                                      widget.type == null))
                                      ? Positioned(
                                    bottom: 0,
                                    child: Container(
                                        width: media.width * 1,
                                        color: page,
                                        // height: media.width * 0.5,
                                        padding: EdgeInsets.all(
                                            media.width * 0.05),
                                        child: Column(
                                          children: [
                                            Column(
                                              children: [
                                                SizedBox(
                                                  width:
                                                  media.width * 0.9,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      Text(
                                                          languages[
                                                          choosenLanguage][
                                                          'text_confirm_details'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media
                                                                  .width *
                                                                  sixteen,
                                                              color:
                                                              textColor,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600)),
                                                      (addressList
                                                          .where((element) =>
                                                      element.type ==
                                                          'drop')
                                                          .length <
                                                          4 &&
                                                          widget.type !=
                                                              1)
                                                          ? InkWell(
                                                        onTap:
                                                            () async {
                                                          var nav = await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) => DropLocation(
                                                                    from: 'add stop',
                                                                  )));
                                                          if (nav) {
                                                            setState(
                                                                    () {});
                                                            Future.delayed(
                                                                const Duration(milliseconds: 100),
                                                                    () {
                                                                  addPickDropMarker();
                                                                });
                                                          }
                                                        },
                                                        child: Text(
                                                            languages[choosenLanguage]['text_add_stop'] +
                                                                ' +',
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media.width *
                                                                    sixteen,
                                                                fontWeight:
                                                                FontWeight.w600,
                                                                color: buttonColor)),
                                                      )
                                                          : Container(),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                  media.width * 0.02,
                                                ),
                                                SizedBox(
                                                  height: (addressList
                                                      .where((element) =>
                                                  element
                                                      .id ==
                                                      'pickup')
                                                      .length <=
                                                      5)
                                                      ? media.width *
                                                      0.125 *
                                                      (addressList
                                                          .where((element) =>
                                                      element
                                                          .id ==
                                                          'pickup')
                                                          .length)
                                                      : media.width *
                                                      0.125 *
                                                      5,
                                                  child: Column(
                                                      children:
                                                      addressList
                                                          .asMap()
                                                          .map((i,
                                                          value) {
                                                        return MapEntry(
                                                          i,
                                                          (addressList[i].id ==
                                                              'pickup')
                                                              ? Container(
                                                            key: ValueKey(i),
                                                            margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                            alignment: Alignment.center,
                                                            height: media.width * 0.1,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                InkWell(
                                                                  onTap: () async {
                                                                    var val = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => DropLocation(
                                                                              from: addressList[i].id,
                                                                            )));
                                                                    if (val) {
                                                                      setState(() {});
                                                                      Future.delayed(const Duration(milliseconds: 100), () {
                                                                        addPickDropMarker();
                                                                      });
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    padding: EdgeInsets.fromLTRB(media.width * 0.03, media.width * 0.02, media.width * 0.03, media.width * 0.02),
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                          color: Colors.grey,
                                                                          width: 1.5,
                                                                        ),
                                                                        borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                        color: page),
                                                                    alignment: Alignment.center,
                                                                    height: media.width * 0.1,
                                                                    width: (addressList.where((element) => element.id == 'pickup').length > 1) ? media.width * 0.8 : media.width * 0.9,
                                                                    child: Row(
                                                                      children: [
                                                                        Container(
                                                                          height: media.width * 0.025,
                                                                          width: media.width * 0.025,
                                                                          alignment: Alignment.center,
                                                                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff319900).withOpacity(0.3)),
                                                                          child: Container(
                                                                            height: media.width * 0.01,
                                                                            width: media.width * 0.01,
                                                                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xff319900)),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: media.width * 0.05,
                                                                        ),
                                                                        Expanded(
                                                                          child: Text(
                                                                            addressList[i].address.toString(),
                                                                            style: GoogleFonts.roboto(
                                                                              fontSize: media.width * twelve,
                                                                              color: textColor,
                                                                            ),
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                (addressList.where((element) => element.id == 'pickup').length > 1)
                                                                    ? InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        addressList.removeAt(i);
                                                                        myMarker.removeWhere((element) => element.markerId.toString().contains('car') != true);
                                                                        addPickDropMarker();
                                                                      });
                                                                    },
                                                                    child: Icon(
                                                                      Icons.delete,
                                                                      size: media.width * 0.07,
                                                                      color: textColor,
                                                                    ))
                                                                    : Container()
                                                              ],
                                                            ),
                                                          )
                                                              : Container(
                                                            key: ValueKey(addressList[i].id),
                                                          ),
                                                        );
                                                      })
                                                          .values
                                                          .toList()),
                                                ),
                                                SizedBox(
                                                  height: (addressList
                                                      .length <=
                                                      4)
                                                      ? media.width *
                                                      0.125 *
                                                      (addressList
                                                          .length -
                                                          1)
                                                      : media.width *
                                                      0.125 *
                                                      4,
                                                  child:
                                                  ReorderableListView(
                                                      onReorder:
                                                          (oldIndex,
                                                          newIndex) {
                                                        if (newIndex <
                                                            oldIndex) {
                                                          var val1 =
                                                          addressList[
                                                          oldIndex]; //1
                                                          var id1 =
                                                              addressList[oldIndex]
                                                                  .id;
                                                          var val2 = addressList[
                                                          oldIndex -
                                                              1]; //2
                                                          var id2 =
                                                              addressList[oldIndex -
                                                                  1]
                                                                  .id;

                                                          addressList[
                                                          oldIndex] =
                                                              val2; //2
                                                          addressList[oldIndex]
                                                              .id =
                                                              id1; //1
                                                          addressList[oldIndex -
                                                              1] =
                                                              val1; //1
                                                          addressList[oldIndex -
                                                              1]
                                                              .id =
                                                              id2; //2
                                                        } else if (newIndex >
                                                            oldIndex) {
                                                          // var newIndexEdit =
                                                          //     addressList
                                                          //             .length -
                                                          //         1;

                                                          var val1 =
                                                          addressList[
                                                          oldIndex]; //1
                                                          var id1 =
                                                              addressList[oldIndex]
                                                                  .id;
                                                          var val2 = addressList[
                                                          oldIndex +
                                                              1]; //2
                                                          var id2 =
                                                              addressList[oldIndex +
                                                                  1]
                                                                  .id;
                                                          addressList[
                                                          oldIndex] =
                                                              val2; //2
                                                          addressList[oldIndex]
                                                              .id =
                                                              id1; //1
                                                          addressList[oldIndex +
                                                              1] =
                                                              val1; //1
                                                          addressList[oldIndex +
                                                              1]
                                                              .id =
                                                              id2; //2
                                                        }
                                                        setState(() {
                                                          addPickDropMarker();
                                                        });
                                                      },
                                                      children:
                                                      addressList
                                                          .asMap()
                                                          .map((i,
                                                          value) {
                                                        return MapEntry(
                                                          i,
                                                          (addressList[i].type == 'drop')
                                                              ? Container(
                                                            key: ValueKey(i),
                                                            margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                            alignment: Alignment.center,
                                                            height: media.width * 0.1,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                InkWell(
                                                                  onTap: () async {
                                                                    var val = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => DropLocation(
                                                                              from: addressList[i].id,
                                                                            )));
                                                                    if (val) {
                                                                      setState(() {});
                                                                      Future.delayed(const Duration(milliseconds: 100), () {
                                                                        addPickDropMarker();
                                                                      });
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    padding: EdgeInsets.fromLTRB(media.width * 0.03, media.width * 0.02, media.width * 0.03, media.width * 0.02),
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                          color: Colors.grey,
                                                                          width: 1.5,
                                                                        ),
                                                                        borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                        color: page),
                                                                    alignment: Alignment.center,
                                                                    height: media.width * 0.1,
                                                                    width: (addressList.where((element) => element.type == 'drop').length > 1) ? media.width * 0.8 : media.width * 0.9,
                                                                    child: Row(
                                                                      children: [
                                                                        // Text(i.toString()),

                                                                        Container(
                                                                          height: media.width * 0.025,
                                                                          width: media.width * 0.025,
                                                                          alignment: Alignment.center,
                                                                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffFF0000).withOpacity(0.3)),
                                                                          child: Container(
                                                                            height: media.width * 0.01,
                                                                            width: media.width * 0.01,
                                                                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffFF0000)),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: media.width * 0.05,
                                                                        ),
                                                                        Expanded(
                                                                          child: Text(
                                                                            addressList[i].address.toString(),
                                                                            style: GoogleFonts.roboto(
                                                                              fontSize: media.width * twelve,
                                                                              color: textColor,
                                                                            ),
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width: media.width * 0.02,
                                                                        ),
                                                                        (addressList.where((element) => element.type == 'drop').length > 1)
                                                                            ? SizedBox(
                                                                            height: media.width * 0.07,
                                                                            child: Icon(
                                                                              Icons.move_down_rounded,
                                                                              size: media.width * 0.05,
                                                                              color: textColor,
                                                                            ))
                                                                            : Container()
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                (addressList.where((element) => element.type == 'drop').length > 1)
                                                                    ? InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        addressList.removeAt(i);
                                                                        myMarker.removeWhere((element) => element.markerId.toString().contains('car') != true);
                                                                        addPickDropMarker();
                                                                      });
                                                                    },
                                                                    child: Icon(
                                                                      Icons.delete,
                                                                      size: media.width * 0.07,
                                                                      color: textColor,
                                                                    ))
                                                                    : Container()
                                                              ],
                                                            ),
                                                          )
                                                              : Container(
                                                            key: ValueKey(addressList[i].id),
                                                          ),
                                                        );
                                                      })
                                                          .values
                                                          .toList()),
                                                ),
                                              ],
                                            ),
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                    dropStopList.clear();
                                                  });
                                                  if (widget.type != 1) {
                                                    if (addressList
                                                        .length >
                                                        2) {
                                                      for (var i = 1;
                                                      i <
                                                          addressList
                                                              .length;
                                                      i++) {
                                                        dropStopList.add(
                                                            DropStops(
                                                              order: i
                                                                  .toString(),
                                                              latitude:
                                                              addressList[
                                                              i]
                                                                  .latlng
                                                                  .latitude,
                                                              longitude:
                                                              addressList[
                                                              i]
                                                                  .latlng
                                                                  .longitude,
                                                              address:
                                                              addressList[
                                                              i]
                                                                  .address
                                                                  .toString(),
                                                            ));
                                                      }
                                                    }
                                                    var val =
                                                    await etaRequest();
                                                    if (val == 'logout') {
                                                      navigateLogout();
                                                    }
                                                  } else {
                                                    var val =
                                                    await rentalEta();
                                                    if (val == 'logout') {
                                                      navigateLogout();
                                                    }
                                                  }
                                                  setState(() {
                                                    dropConfirmed = true;
                                                    _isLoading = false;
                                                  });
                                                },
                                                text: languages[
                                                choosenLanguage]
                                                ['text_confirm'])
                                          ],
                                        )),
                                  )
                                      : Container(),

                                  //loader
                                  (_isLoading == true)
                                      ? const Positioned(
                                      top: 0, child: Loading())
                                      : Container(),

                                  //no internet
                                  (internet == false)
                                      ? Positioned(
                                      top: 0,
                                      child: NoInternet(
                                        onTap: () {
                                          setState(() {
                                            internetTrue();
                                          });
                                        },
                                      ))
                                      : Container(),

                                  //pick drop marker
                                  Positioned(
                                    top: media.height * 1.5,
                                    child: RepaintBoundary(
                                        key: iconKey,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: media.width * 0.5,
                                              height: media.width * 0.12,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                  color: page),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: media.width * 0.12,
                                                    width: media.width * 0.12,
                                                    decoration: BoxDecoration(
                                                        borderRadius: (languageDirection ==
                                                            'ltr')
                                                            ? const BorderRadius.only(
                                                            topLeft: Radius
                                                                .circular(
                                                                10),
                                                            bottomLeft:
                                                            Radius.circular(
                                                                10))
                                                            : const BorderRadius.only(
                                                            topRight: Radius
                                                                .circular(
                                                                10),
                                                            bottomRight:
                                                            Radius.circular(
                                                                10)),
                                                        color: const Color(
                                                            0xff222222)),
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons.star,
                                                      color: Color(0xff319900),
                                                    ),
                                                  ),
                                                  Expanded(
                                                      child: Container(
                                                        padding: EdgeInsets.only(
                                                            left:
                                                            media.width * 0.02,
                                                            right:
                                                            media.width * 0.02),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                          children: [
                                                            Text(
                                                              languages[
                                                              choosenLanguage]
                                                              [
                                                              'text_pickpoint'],
                                                              style: GoogleFonts.roboto(
                                                                  fontSize:
                                                                  media.width *
                                                                      twelve,
                                                                  color: textColor,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                            ),
                                                            (userRequestData
                                                                .isNotEmpty)
                                                                ? Text(
                                                              userRequestData[
                                                              'pick_address'],
                                                              softWrap: false,
                                                              style: GoogleFonts.roboto(
                                                                  color:
                                                                  textColor,
                                                                  fontSize: media
                                                                      .width *
                                                                      twelve),
                                                            )
                                                                : (addressList
                                                                .where((element) =>
                                                            element
                                                                .id ==
                                                                'pickup')
                                                                .isNotEmpty)
                                                                ? Text(
                                                              addressList
                                                                  .firstWhere((element) =>
                                                              element.id ==
                                                                  'pickup')
                                                                  .address,
                                                              softWrap:
                                                              false,
                                                              style: GoogleFonts.roboto(
                                                                  color:
                                                                  textColor,
                                                                  fontSize:
                                                                  media.width *
                                                                      twelve),
                                                            )
                                                                : Container(),
                                                          ],
                                                        ),
                                                      ))
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/userloc.png'),
                                                      fit: BoxFit.contain)),
                                              height: media.width * 0.05,
                                              width: media.width * 0.05,
                                            )
                                          ],
                                        )),
                                  ),
                                  (widget.type != 1)
                                      ? Positioned(
                                      top: media.height * 2,
                                      child: Column(
                                        children: addressList
                                            .asMap()
                                            .map((i, value) {
                                          iconDropKeys[i] = GlobalKey();
                                          return MapEntry(
                                            i,
                                            (i > 0)
                                                ? RepaintBoundary(
                                                key:
                                                iconDropKeys[i],
                                                child: Column(
                                                  children: [
                                                    (i ==
                                                        addressList.length -
                                                            1)
                                                        ? Container(
                                                      width: media.width *
                                                          0.5,
                                                      height: media.width *
                                                          0.12,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius.circular(10),
                                                          color: page),
                                                      child:
                                                      Row(
                                                        children: [
                                                          Container(
                                                            height: media.width * 0.12,
                                                            width: media.width * 0.12,
                                                            decoration: BoxDecoration(borderRadius: (languageDirection == 'ltr') ? const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)) : const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)), color: const Color(0xff222222)),
                                                            alignment: Alignment.center,
                                                            child: const Icon(
                                                              Icons.star,
                                                              color: Color(0xffE60000),
                                                            ),
                                                          ),
                                                          Expanded(
                                                              child: Container(
                                                                padding: EdgeInsets.only(left: media.width * 0.02, right: media.width * 0.02),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      languages[choosenLanguage]['text_droppoint'],
                                                                      style: GoogleFonts.roboto(
                                                                        fontSize: media.width * twelve,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: textColor,
                                                                      ),
                                                                    ),
                                                                    (addressList[i].address.isNotEmpty)
                                                                        ? Text(
                                                                      addressList[i].address,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.fade,
                                                                      softWrap: false,
                                                                      style: GoogleFonts.roboto(
                                                                        fontSize: media.width * twelve,
                                                                        color: textColor,
                                                                      ),
                                                                    )
                                                                        : Container(),
                                                                  ],
                                                                ),
                                                              ))
                                                        ],
                                                      ),
                                                    )
                                                        : Text(
                                                      (i).toString(),
                                                      style: GoogleFonts.roboto(
                                                          fontSize: media.width *
                                                              sixteen,
                                                          fontWeight:
                                                          FontWeight.w600,
                                                          color: Colors.red),
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Container(
                                                      decoration: const BoxDecoration(
                                                          shape: BoxShape
                                                              .circle,
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  'assets/images/droploc.png'),
                                                              fit: BoxFit
                                                                  .contain)),
                                                      height: media
                                                          .width *
                                                          0.05,
                                                      width: media
                                                          .width *
                                                          0.05,
                                                    )
                                                  ],
                                                ))
                                                : Container(),
                                          );
                                        })
                                            .values
                                            .toList(),
                                      ))
                                      : Container(),

                                  (widget.type != 1)
                                      ? Positioned(
                                    top: media.height * 2,
                                    child: RepaintBoundary(
                                        key: iconDistanceKey,
                                        child: Stack(
                                          children: [
                                            Icon(Icons.chat_bubble,
                                                size: media.width * 0.2,
                                                color: page,
                                                shadows: [
                                                  BoxShadow(
                                                      spreadRadius: 2,
                                                      blurRadius: 2,
                                                      color: Colors.black
                                                          .withOpacity(
                                                          0.2))
                                                ]),
                                            if (etaDetails.isNotEmpty)
                                              if (etaDetails[0]
                                              ['distance'] !=
                                                  null)
                                                Positioned(
                                                    left: media.width *
                                                        0.03,
                                                    top: media.width *
                                                        0.03,
                                                    child: Container(
                                                        width:
                                                        media.width *
                                                            0.14,
                                                        height:
                                                        media.width *
                                                            0.1,
                                                        alignment:
                                                        Alignment
                                                            .center,
                                                        child: Text(
                                                          "${etaDetails[0]['distance'].toString()} ${etaDetails[0]['unit_in_words'].toString()} ",
                                                          style: GoogleFonts.roboto(
                                                              fontSize: media
                                                                  .width *
                                                                  twelve,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600),
                                                        )))
                                          ],
                                        )),
                                  )
                                      : Container(),
                                ],
                              );
                            });
                      });
                }),
          ),
        ),
      ),
    );
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
      mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
      provider, //Ticker provider of the widget. This is used for animation

      GoogleMapController controller, //Google map controller of our widget

      markerid,
      markerBearing,
      icon) async {
    final double bearing =
    getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
        markerId: MarkerId(markerid),
        position: LatLng(fromLat, fromLong),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        draggable: false);

    myMarker.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarker).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarker
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        carMarker = Marker(
            markerId: MarkerId(markerid),
            position: newPos,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.

        myMarker.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarker).toList());
      });

    //Starting the animation

    animationController.forward();
  }
}