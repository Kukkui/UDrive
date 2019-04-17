import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart' as globals;
import 'services/crud.dart';
import 'dart:async';
import 'googleMaps.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Feed extends StatefulWidget{
  @override
  _Feed createState() => new _Feed();
}

class _Feed extends State<Feed> {
  @override
  Widget build(BuildContext context) {
    return Container(
    //return new Scaffold(
     // appBar: new AppBar(
       //   title: new Text('Pool Feed')
     // ),
      child: ListPage()
    //);
    );
  }
}
class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  Future _data;
  List<DocumentSnapshot> documentList = new List();


  Future getPosts() async {
    int i = 0;
    var firestore = Firestore.instance;
    QuerySnapshot qn = await firestore.collection('Rides').getDocuments(); // move to crud

    await qn.documents.forEach((DocumentSnapshot document) {
      print("did i do this");
      print(globals.diff_dates(document.data["date"]));
      if (globals.diff_dates(document.data["date"])<=0) {
        documentList.insert(i, document);
        i++;
        print(globals.diff_dates(document.data["date"]));
      }
    });
    return documentList.cast<dynamic>();
    //return qn.documents;
  }

  navigateToDetail(DocumentSnapshot ride){
    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(ride: ride,)));
  }


  @override
  initState() {

    super.initState();
    _data = getPosts();
  }

  void launchMap(String startAddress, String endAddress, String midPoint) async{
    const double lat = 2.813812,  long = 101.503413;
    const String map_api= "1";
    //const url = "https://maps.google.com/maps/search/?api=$map_api&query=$lat,$long";
    String part1 = 'https://www.google.com/maps/dir/?api=1&origin=';
    String startA = startAddress.replaceAll(' ', '+');
    String part2 = '&waypoints=';
    String midpoint = midPoint.replaceAll(' ', '+');
    String part3 = '&destination=';
    String endA = endAddress.replaceAll(' ', '+');
    String part5 = '&travelmode=driving';
    print(midPoint);

    String url2 = part1+startA+part2+midpoint+part3+endA+part5;
    //const url3 = url2.;

    const url = 'https://www.google.com/maps/dir/?api=1&origin=16350+SW+45th+Terr+Miami+FL+33185&waypoints=6861+SW+44th+St+Miami+FL&destination=1320+S+Dixie+Hwy+Coral+Gables+FL&travelmode=driving';
    //const url = 'https://www.google.com/maps/dir/?api=1&origin=Space+Needle+Seattle+WA&destination=Pike+Place+Market+Seattle+WA&travelmode=bicycling';

    if (await canLaunch(url2)) {
      print("Can launch");
      void initState(){
        super.initState();

        canLaunch( "https://maps.google.com/maps/search/?api=$map_api&query=$lat,$long");
      }

      await launch(url2);
    } else {
      print("Could not launch");
      throw 'Could not launch Maps';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
          future: _data,
          builder: (_,snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Text('Loading...'),
              );
            } else {
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (_, index) {
                   // if (globals.diff_dates(snapshot.data[index].data["date"])<0)  {
                    return Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('\nDate: '+ globals.formatDate(snapshot.data[index].data["date"]) + '\n'),
                          Text('Driver\'s name: ' + snapshot.data[index].data["driver_name"]),
                          Text('Start Address: ' + snapshot.data[index].data["start_address"]),
                          Text('End Address: '+ snapshot.data[index].data["end_address"]),
                          Text('Start Time: ' + globals.formatTime(snapshot.data[index].data["start_time"])),
                          Text('End Time: ' + globals.formatTime(snapshot.data[index].data["end_time"])),
                          ButtonTheme.bar( // make buttons use the appropriate styles for cards
                            child: ButtonBar(
                              children: <Widget>[
                                FlatButton(
                                  child: const Text('View Ride'),
                                  onPressed: () {
                                    launchMap(snapshot.data[index].data["start_address"], snapshot.data[index].data["end_address"], globals.address);
                                    print("tried doing map");
                                    },
                                ),
                                FlatButton(
                                  child: const Text('Request Ride'),
                                  onPressed: () => navigateToDetail(snapshot.data[index]),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ); //}
                  });
            }
          }),
    );
  }
}


class DetailPage extends StatefulWidget {
  final DocumentSnapshot ride;
  DetailPage({this.ride});
  @override
  _DetailPageState createState() => _DetailPageState();
}
class _DetailPageState extends State<DetailPage> {
  final formKey = new GlobalKey<FormState>();
  String amountToPay;
  TimeOfDay arrivalTime = new TimeOfDay.now();
  crudMethods crudObj = new crudMethods();

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void goToMaps() async
  {
    var url = 'https://www.google.com/maps/dir/?api=1&origin=Space+Needle+Seattle+WA&destination=Pike+Place+Market+Seattle+WA&travelmode=bicycling';
    var response = await http.post(url);
    //launch(url);
    //print('Response status: ${response.statusCode}');
    //print('Response body: ${response.body}');

    //print(await http.read('http://example.com/foobar.txt'));
  }

  Future<Null> _selectTime(BuildContext context) async{
    final TimeOfDay picked = (await showTimePicker(
        context: context,
        initialTime: arrivalTime
    )); //as DateTime;
    if(picked != null){
      setState(() {
        arrivalTime = picked;
      });
      print('Time selected:  ${arrivalTime.toString()}');

    }
  }

  List<Widget> buildInputs() {
    return [
      new TextFormField(
        decoration: new InputDecoration(labelText: 'Ride bid'),
        validator: (value) => value.isEmpty ? 'Bid can\'t be empty' : null,
        inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
        onSaved: (value) => amountToPay = value,
      ),
      new RaisedButton(
        child: new Text('Select Arrival Time: ' + this.arrivalTime.format(context), style: new TextStyle(fontSize: 20.0)),
        onPressed: (){
          _selectTime(context);
        },
      )
    ];

  }

   String hash_Code() {
      int hash = 7;
      hash = 41 * hash + widget.ride.data["start_time"].hashCode;
      hash = 41 * hash + widget.ride.data["end_time"].hashCode;
      hash = 41 * hash + widget.ride.data["date"].hashCode;
      hash = 41 * hash + widget.ride.data["driver_id"].hashCode;
      hash = 41 * hash + widget.ride.data["rider_id"].hashCode;
      return hash.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ride.data["driver_name"]+'\'s ride'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Card(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('\nDate: ' + globals.formatDate(widget.ride.data["date"]) +
                    '\n'),
                Text('Start Address: ' + widget.ride.data["start_address"]),
                Text('End Address: ' + widget.ride.data["end_address"]),
                Text('Start Time: ' +
                    globals.formatTime(widget.ride.data["start_time"])),
                Text('End Time: ' +
                    globals.formatTime(widget.ride.data["end_time"])),
                new Form(
                  key: formKey,
                  child: new TextFormField(
                    decoration: new InputDecoration(labelText: 'Ride bid'),
                    validator: (value) => value.isEmpty ? 'Bid can\'t be empty' : null,
                    keyboardType: TextInputType.number,
                    onSaved: (value) => amountToPay = value,
          )
          ),
          SizedBox(height: 50),
          RaisedButton(
            color: Colors.amber,
            child: new Text('Select Arrival Time: ' + this.arrivalTime.format(context), style: new TextStyle(fontSize: 20.0)),
            onPressed: (){
              _selectTime(context);
            },
          ),
               // child: buildInputs(),
                ButtonTheme
                    .bar( // make buttons use the appropriate styles for cards
                  child: ButtonBar(
                    children: <Widget>[
                      FlatButton(
                        child: const Text('Submit Request'),
                        onPressed: ()
                        {
                          final form = formKey.currentState;
                          form.save();
                        addToDatabase();
                        }
                      ),
                    ],
                  ),
                ),
              ]
          ),
        ),
      ),
    );
  }

  void addToDatabase() async {
    //if(validateAndSave()) {
    Map <String, dynamic> rideCatalog = {
      'date': widget.ride.data["date"],
      'start_time': widget.ride.data["start_time"],
      'end_time': widget.ride.data["end_time"],
      'start_address': widget.ride.data["start_address"],
      'end_address': widget.ride.data["end_address"],
      'mid_address': globals.address,
      'rider_id': globals.get_userID(),
      'driver_id': widget.ride.data["uid"],
      'driver_name': widget.ride.data["driver_name"],
      'rider_name': globals.fname,
      'arrival_time': this.arrivalTime.toString(),
      'bid_amount': this.amountToPay.toString(),
      'status': "Pending",
    };
    crudObj.addRideCatalog(rideCatalog, hash_Code()).catchError((e) {
      print(e);
    });
    //}
    // moveToLogin(); This should clear all values and let you submit a new ride
    //}
  }
}

