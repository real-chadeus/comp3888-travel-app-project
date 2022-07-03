import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/firebase_services/database_savedPlan.dart';
import 'package:flutter_app/firebase_services/database_service.dart';
import 'package:flutter_app/objects/savedPlan.dart';
import 'package:flutter_app/objects/user.dart';
import 'package:flutter_app/screens/plan_related/SamplePlan.dart';
import 'package:flutter_app/screens/plan_related/SearchPlace.dart';
import 'package:flutter_app/screens/plan_related/GoogleMap.dart';
import 'package:flutter_app/screens/Plan.dart';
import 'package:flutter_app/screens/AddInterests.dart';
import 'package:flutter_app/widgets/display_title.dart';
import 'package:flutter_app/widgets/white_text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/user_services.dart';
import 'package:flutter_app/firebase_services/database_makePlan.dart';
import 'package:flutter_app/objects/personalPlan.dart';
import 'package:google_directions_api/google_directions_api.dart'
    as direction_api;
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    as polyline_points;
import 'package:flutter_app/screens/BottomNavigation.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../InvitedFriend.dart';
import '../MakeTrip.dart';
import 'DisplayEdit.dart';

class DisplayTrip extends StatefulWidget {
  final GooglePlace? googlePlace;
  final String targetId;
  final String? targetUser;

  const DisplayTrip({Key? key, this.googlePlace, required this.targetId, this.targetUser})
      : super(key: key);

  @override
  _DisplayTripState createState() =>
      _DisplayTripState(this.googlePlace, this.targetId, this.targetUser);
}

class _DisplayTripState extends State<DisplayTrip> {
  final GooglePlace? googlePlace;
  String? targetUser;

  final _dayController = StreamController();
  final _scrollController = ScrollController();

  final String targetId;
  late String uid;
  late String newTitle;
  //late String title;
  int num = 0;
  int _dayCounter = 0;
  String startDate = '';
  Map savedDayList = {};
  int planIndex = 0;
  List allTrip = [];

  User? user = UserServices.getUserInfo();
  LocalUser? localUser;
  SavedPlan? savedPlan;
  DayPlan? dayPlan;

  direction_api.DirectionsService? directinosService;
  List<List<polyline_points.PointLatLng>> polylinePoints = [];
  bool ableToFetBack = true;

  @override
  void initState() {
    super.initState();

    //id = '1';
    user = UserServices.getUserInfo();
    if(widget.targetUser != null){
      targetUser = widget.targetUser;
      print(targetUser);
      print('00000000000000');
    }
  }

  _DisplayTripState(this.googlePlace, this.targetId, this.targetUser);
  @override
  Widget build(BuildContext context) {
    if(targetUser != null){
      return StreamBuilder(
          stream: DatabaseSavedPlan().streamShardPlan,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }
            if (snapshot.data == null) {
              return Text('Loading');
            }
            allTrip = UserServices.dayPlanListFromSnapshot(snapshot);
            planIndex = allTrip.indexWhere((element) => element.id == targetId);
            print('---qqqqqqq----------');
            print(targetId);
            savedPlan = allTrip[planIndex];
            print(planIndex);
            print(allTrip.length);
            print('---llllllllllllllll----------');
            print(savedPlan!.tripInterests);
            print(savedPlan!.tripInterests.length);
            print('---llllllllllllllll----------');
            startDate = savedPlan!.startDate;
            get_polylines();
            return _displayMain();


          });
    }
    else{
      return StreamBuilder(
          stream: DatabaseSavedPlan().streamUserDataSnapshot,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }
            if (snapshot.data == null) {
              return Text('Loading');
            }
            allTrip = UserServices.dayPlanListFromSnapshot(snapshot);
            planIndex = allTrip.indexWhere((element) => element.id == targetId);
            print('---qqqqqqq----------');
            print(targetId);
            savedPlan = allTrip[planIndex];
            print(planIndex);
            print(allTrip.length);
            print('---llllllllllllllll----------');
            print(savedPlan!.tripInterests);
            print(savedPlan!.tripInterests.length);
            print('---llllllllllllllll----------');
            startDate = savedPlan!.startDate;
            get_polylines();
            return _displayMain();


          });

    }


  }

  get_polylines() async {
    polylinePoints.clear();
    String apiKey = dotenv.env['APIKEY'] ?? "";
    if (apiKey == "") {
      print("lack of API key");
      return;
    }
    direction_api.DirectionsService.init(apiKey);
    directinosService = await direction_api.DirectionsService();
    int length = savedPlan!.tripInterests.length;

    for (var i = 1; i <= length; i++) {
      String day = 'Day ' + i.toString();
      // String day = 'Day 1';

      //check origin and destination exists within day plan
      if (savedPlan?.tripInterests[day]['origin'] == null ||
          savedPlan?.tripInterests[day]['destination'] == null) {
        break;
      }
      if (savedPlan?.tripInterests[day]['origin'].length <= 2 ||
          savedPlan?.tripInterests[day]['destination'].length <= 2) {
        break;
      }

      Map temp = {...savedPlan?.tripInterests[day]};
      temp.remove("origin");
      temp.remove("destination");

      int num_waypoints = temp.length;
      print("num_waypoints");
      print(num_waypoints);

      List<direction_api.DirectionsWaypoint> waypoints = [];
      temp.forEach((key, value) {
        print("temp key");
        print(key);
        print(value);
        if (value != null && value.length > 2) {
          String location = value[2].toString() + ',' + value[3].toString();
          waypoints.add(direction_api.DirectionsWaypoint(location: location));
        }
      });
      print(day);
      print(savedPlan?.tripInterests[day]);
      String? Origin_location_lat =
          savedPlan?.tripInterests[day]["origin"][2].toString();
      String? Origin_location_lng =
          savedPlan?.tripInterests[day]["origin"][3].toString();

      String Origin_location = '';
      if (Origin_location_lat != null && Origin_location_lng != null) {
        Origin_location = Origin_location_lat + ',' + Origin_location_lng;
      }

      String? Dest_location_lat =
          savedPlan?.tripInterests[day]["destination"][2].toString();
      String? Dest_location_lng =
          savedPlan?.tripInterests[day]["destination"][3].toString();

      String Dest_location = '';
      if (Dest_location_lat != null && Dest_location_lng != null) {
        Dest_location = Dest_location_lat + ',' + Dest_location_lng;
      }

      List<polyline_points.PointLatLng> polylinePoint = [];
      var request;
      if (waypoints.length != 0) {
        request = await direction_api.DirectionsRequest(
          origin: Origin_location,
          destination: Dest_location,
          travelMode: direction_api.TravelMode.driving,
          waypoints: waypoints,
        );
      } else {
        request = await direction_api.DirectionsRequest(
          origin: Origin_location,
          destination: Dest_location,
          travelMode: direction_api.TravelMode.driving,
        );
      }

      await directinosService?.route(request,
          (direction_api.DirectionsResult response,
              direction_api.DirectionsStatus? status) {
        if (status == direction_api.DirectionsStatus.ok) {
          polylinePoint = polyline_points.PolylinePoints().decodePolyline(
              response.routes?[0].overviewPolyline?.points ?? "");
          print("polylinePoint");
          print(polylinePoint);
          polylinePoints.insert(i - 1, polylinePoint);
        } else {
          print("direction request fail");
        }
      });
    }
    // print("polylinePoints");
    print("polylinePoints.length");
    print(polylinePoints.length);
  }

  Widget _titleImage() {
    num = getPlaceNum();
    return Container(
      height: 153,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(
              'images/edit.jpg',
            )),

      ),
      child: Stack(
        children: [

          Positioned(
            top: 5,
            left: MediaQuery.of(context).size.width * 1 / 3,
            child: Container(
              //margin: EdgeInsets.fromLTRB(0,2,0,120),
              height: 22,
              //width:10,
              //color:Colors.blue,
              alignment: Alignment.center,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Trip to ${savedPlan!.title}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 19.0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 5,
            child: Text(
              '${num} PLACES  ${(savedPlan!.friendsID).length + 1} PEOPLE',
              style: TextStyle(
                color: Color.fromRGBO(39, 78, 114, 1),
                fontSize: 15,
              ),
            ),
          ),
          Positioned(
            right: 27,
            bottom: 27,
            child: Icon(
              Icons.date_range,
              color: Color.fromRGBO(39, 78, 114, 1),
              //alignment: Alignment.center,
            ),

          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Text(
              '$startDate',
              style: TextStyle(
                color: Color.fromRGBO(39, 78, 114, 1),
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayListPage() {
    return Scrollbar(
      isAlwaysShown: true,
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
        child: ListView.separated(
          controller: _scrollController,
          itemCount: _dayCounter + 2,
          shrinkWrap: true,
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return _titleImage();
            }

            if (index == _dayCounter + 1) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    //SizedBox(height: 5),
                    _getEffectivebutton(
                      "Confirm Plan",
                      Plan(googlePlace: googlePlace),
                      //DisplayPlan(googlePlace:googlePlace),
                    ),
                  ],
                ),
              );
            }
            //currentDay = ;
            //if (index == _dayCounter)
            return _everydayInterests('Day $index');
          },
        ),
      ),
    );
  }

  Widget _everydayPlan(String day, String place, String where) {
    return Container(
      height: 200,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromRGBO(243, 245, 252, 1),
        boxShadow: [
          BoxShadow(
              color: Colors.grey,
              offset: Offset(1.0, 1.0),
              blurRadius: 0.5,
              spreadRadius: 0.1)
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 15),
            alignment: Alignment.centerLeft,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(
            color: Color.fromRGBO(39, 78, 114, 1),
            height: 10,
            thickness: 2,
            indent: 10,
            endIndent: 10,
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            alignment: Alignment.centerLeft,
            child: Text(
              where,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 1,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  //margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  height: 50,
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: new Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          offset: Offset(1.0, 1.0),
                          blurRadius: 0.5,
                          spreadRadius: 0.1)
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 5),
                      Expanded(
                        child: _getTextbutton(day, place, context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz,
                  size: 40,
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
          SizedBox(
            height: 11,
          ),
          _getEffectivebutton(
              'Add',
              AddInterests(
                currentDay: day,
              )),
        ],
      ),
    );
  }

  Widget _everydayInterests(String day) {
    String currentDay = day;
    int _currentDay = int.parse(currentDay.substring(4));
    List InterestList = _formInterestList(day, savedDayList);
    return Container(
      height: 420,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromRGBO(243, 245, 252, 1),
        boxShadow: [
          BoxShadow(
              color: Colors.grey,
              offset: Offset(1.0, 1.0),
              blurRadius: 0.5,
              spreadRadius: 0.1)
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                alignment: Alignment.centerLeft,
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                color: Colors.black,
                height: 10,
                thickness: 2,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ListTile(
                      title: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        children: _generalInterests(InterestList, currentDay),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getTextbutton(String currentDay, String word, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 2,),
      child: Text(
        word,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

  }

  Widget _getEffectivebutton(String word, var route) {
    return ElevatedButton(
      onPressed: () async {
        if (word == 'Confirm Plan') {
          await UserServices.updateSavedPlanStartDate(startDate);
          await UserServices.updateSavedPlanTripDuration(
              _dayCounter.toString());
          await UserServices.updateSavedPlanTripInterests(savedDayList);
          //await UserServices.updateSavedPlanTitle(newTitle);
          Fluttertoast.showToast(
            msg: 'Success saved!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          Navigator.of(context).pop();
          /*
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    BottomNavigatorBar(data: 2, isLogin: true)),
          );

           */
        } else if (word == 'ADD') {
          //print(currentDay);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => route),
          ).then((data) {
            setState(() {
              savedDayList = savedPlan!.tripInterests;
              print('????????????');
              print(savedDayList);
            });
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => route),
          );
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
        overlayColor: MaterialStateProperty.all(Colors.blueGrey),
        side:
            MaterialStateProperty.all(BorderSide(width: 1, color: Colors.grey)),
        shadowColor: MaterialStateProperty.all(Colors.grey),
        elevation: MaterialStateProperty.all(3),
        shape: MaterialStateProperty.all(StadiumBorder(
            side: BorderSide(
          style: BorderStyle.solid,
        ))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        child: Text(
          word,
          style: TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget singleInterestField(String general, String detail, String currentDay) {
    return ListTile(
      title: Text(
        general,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Container(
        child: Row(
          //crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(height: 65),
            Expanded(
              child: Container(
                //margin: const EdgeInsets.only(right: 20),
                margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                alignment: Alignment.centerLeft,
                height: 50,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: new Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        offset: Offset(1.0, 1.0),
                        blurRadius: 0.5,
                        spreadRadius: 0.1)
                  ],
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _getTextbutton(currentDay, detail, context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _shareOrNot(){
    if (targetUser != null){
      return SizedBox(width: 0);
    }
    else{
      return IconButton(
        icon: Icon(Icons.share),
        onPressed: _shareTrip,
        color: Colors.black,
      );
    }
  }

  Widget _mapOrNot(){
    if (targetUser != null){
      return SizedBox(width: 0);
    }
    else{
      return IconButton(
        icon: Icon(Icons.map),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Mapdisplay(
                  polylinePoints: polylinePoints,
                  savedPlan: savedPlan),
            ),
          );
        },
        color: Colors.black,
      );
    }
  }

  Widget _displayMain(){
    if (savedPlan!.tripInterests.length == 0) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              _scrollController.animateTo(-10,
                  duration: Duration(milliseconds: 100),
                  curve: Curves.linear);
            },
            child: Text(
              targetUser == null ? 'Display Plan' : "Friend's Plan",
              style: const TextStyle(
                color: Color.fromRGBO(20, 41, 82, 1),
                fontSize: 24.0,
              ),
            ),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          actions: [
            _mapOrNot(),
            _shareOrNot(),
          ],
        ),
        body: Column(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: _titleImage()),
            SizedBox(
              height: 10,
            ),
            _getEffectivebutton('Confirm Plan', '0'),
          ],
        ),
      );
    } else {
      savedPlan!.tripInterests.forEach((key, value) {
        savedDayList[key] = savedPlan!.tripInterests[key];
      });
      _dayCounter = int.parse(savedPlan!.tripDuration);

      print(savedDayList);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(-10,
                duration: Duration(milliseconds: 100),
                curve: Curves.linear);
          },
          child: Text(
              targetUser == null ? 'Display Plan' : "Friend's Plan",
            style: const TextStyle(
              color: Color.fromRGBO(20, 41, 82, 1),
              fontSize: 24.0,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        actions: [
          //SizedBox(width:0),
          IconButton(
            onPressed: _editPlan,
            icon: Icon(Icons.edit),
          ),
          _mapOrNot(),
          _shareOrNot(),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: _dayController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (_dayCounter > 10) {
                  showAlterDialog();
                }

                return _dayListPage();
              }
              return _dayListPage();
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
              onPressed: () {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 100),
                    curve: Curves.linear);
              },
              tooltip: 'Press to bottom',
              icon: Icon(
                Icons.vertical_align_bottom,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );

  }

  int getPlaceNum() {
    int n = 0;
    savedPlan!.tripInterests.forEach((key, value) {
      savedPlan!.tripInterests[key].forEach((key, value) {
        if (value != Null) {
          n += 1;
        }
      });
    });
    return n;
  }

  void _deleteFromInterests(String interest, String currentDay) async {
    String _dayCounter = currentDay.substring(4);
    int dayCounter = int.parse(_dayCounter);
    Map temp = {};

    Map oldInterests = savedDayList["Day $_dayCounter"];

    oldInterests.forEach((key, value) {
      if (key != interest) {
        temp[key] = value;
      }
    });

    savedDayList["Day $_dayCounter"] = temp;
    await UserServices.updateTripInterests(savedDayList);
  }

  List _formInterestList(String day, Map savedDayList) {
    List returnList = [];
    //print('-----!!!!!-----');
    //print(day);
    if (savedDayList[day] != {}) {
      savedDayList[day].forEach((key, value) {
        Map partMap = {};
        partMap['title'] = [key, value[0]];
        returnList.add(partMap);
      });
    }
    return returnList;
  }

  List<Widget> _generalInterests(List all, String currentDay) {
    List<Widget> interests = [];
    for (Map m in all) {
      String detail = '...';
      if (m['title'][1] != '') {
        detail = m['title'][1];
      }
      interests.add(
        //Chip(label: Text(m['title'][0], style:TextStyle(fontSize: 14))),
        singleInterestField(m['title'][0], detail, currentDay),
      );
/*      if(deleteInterest()){
        interests.remove(singleInterestField(m['title'][0], detail),);
      }*/
    }
    return interests;
  }

  void showAlterDialog() async {
    //1.release a notification to user : The maximum duration allowed is 10 days
    if (_dayCounter > 10) {
      _dayCounter = 10;
      //await UserServices.updateTripDuration(_dayCounter.toString());
      Fluttertoast.showToast(
        msg: 'Exceed maximum day limit : \nNo more than 10 days!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  //sample plan page share trip
  void _shareTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InvitedFriend(id: savedPlan!.id)),
    );
  }

  void _editPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              DisplayEdit(googlePlace: googlePlace, targetId: targetId, targetUser:targetUser)),
    );
  }
}
