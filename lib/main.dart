import 'dart:io';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SnapSheetExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SnappingSheet(
        sheetBelow: SnappingSheetContent(
            child: Container(
              color: Colors.red,
            ),
            heightBehavior: SnappingSheetHeight.fit()),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(
      ChangeNotifierProvider(create: (_) => UserRepository(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        // Add the 3 lines from here...
        primaryColor: Colors.red,
      ), // ... to here.
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  GlobalKey<ScaffoldState> _scaffoldkeySaved =
      GlobalKey<ScaffoldState>(debugLabel: '_scaffoldkeySaved');
  GlobalKey<ScaffoldState> _scaffoldkeyMainScreen =
      GlobalKey<ScaffoldState>(debugLabel: '_scaffoldkeyMainScreen');
  final List<WordPair> _suggestions = <WordPair>[]; // NEW
  final TextStyle _biggerFont = const TextStyle(fontSize: 18); // NEW
  var _saved = Set<WordPair>(); // NEW
  static bool disabledB = false;
  FirebaseAuth _auth;
  bool loggedin = false;
  String userID = "";
  String userEmail = "";
  bool validator1 = false;
  favMaterialPageRoute() => MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          Provider.of<UserRepository>(context);
          final tiles = _saved.map(
            (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
                trailing: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onTap: () {
                  _saved.remove(pair);
                  updateFirestore();

                  setState(() {
                    Provider.of<UserRepository>(context, listen: false)
                        .Update();
                  });
                },
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            key: _scaffoldkeySaved,
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      );

  void _pushSaved() {
    Navigator.of(context).push(
      favMaterialPageRoute(),
    );
  }
bool confirmclicked=false;
  final _formKey = GlobalKey<FormState>();
  loginMaterialPageRoute() => MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          final isLoggingIn = Provider.of<UserRepository>(context).status;
          final myControllerEmail = TextEditingController();
          final myControllerPass = TextEditingController();
          final myControllerConfirm = TextEditingController();
          final Email = Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                controller: myControllerEmail,
              ));
          final Password = Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                controller: myControllerPass,
              ));
          final loginButton = FlatButton(
            onPressed: isLoggingIn == Status.Authenticating
                ? null
                : () async {
                    Provider.of<UserRepository>(context, listen: false)
                        .Authenticating();
                    String email = myControllerEmail.text;
                    String password = myControllerPass.text;
                    bool t = false;
                    FocusScope.of(context).unfocus();
                    _auth = FirebaseAuth.instance;

                    try {
                      await _auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      t = true;
                    } catch (e) {}

                    disabledB = false;

                    if (t) {
                      //Login successful

                      loggedin = true;
                      userID = _auth.currentUser.uid;
                      userEmail = _auth.currentUser.email;
                      try {
                        imageLink = await FirebaseStorage.instance
                            .ref()
                            .child(userID)
                            .getDownloadURL();
                      } catch (e) {}
                      await updateFirestoreOnLogin();
                      await updateFirestore();
                      Provider.of<UserRepository>(context, listen: false)
                          .Authenticated();
                      Navigator.of(context).pop();
                      setState(() {
                        //build(context);
                      });
                    } else {
                      //Login FAILED
                      userID = "";
                      userEmail = "";
                      final snackBar = SnackBar(
                          content:
                              Text("There was an error logging into the app"));
                      _scaffoldkeySaved.currentState.showSnackBar(snackBar);
                      Provider.of<UserRepository>(context, listen: false)
                          .Unauthenticated();
                    }

                    //myControllerEmail.dispose();
                    //myControllerPass.dispose();
                  },
            child: Text(
              "Log in",
            ),
            color: Colors.red,
            textColor: Colors.white,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
          );

          final signupButton = FlatButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              color: Colors.teal,
              onPressed: () {
                showModalBottomSheet<void>(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: Container(
                          height: 200,
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Please confirm your password below:'),
                                Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Form(
                                        key:_formKey,
                                        child:TextFormField(
                                      obscureText: true,
                                      validator: (String val){
                                        if(val != myControllerPass.text && confirmclicked) {
                                          confirmclicked=false;
                                          return "Passwords must match";
                                        }
                                        else{
                                          return null;
                                        }
                                      }
                                          ,
                                      decoration: InputDecoration(
                                          labelText: 'Password:'),
                                      controller: myControllerConfirm,
                                    ))),
                                ElevatedButton(
                                  child: const Text('Confirm'),
                                  onPressed: () async {
                                    confirmclicked=true;
                                    _formKey.currentState.validate();
                                    _auth = FirebaseAuth.instance;
                                    var t = false;
                                    var email = myControllerEmail.text;
                                    var confirmpassword =
                                        myControllerConfirm.text;
                                    var password = myControllerPass.text;
                                    if (confirmpassword == password) {
                                      try {
                                        await _auth
                                            .createUserWithEmailAndPassword(
                                                email: email,
                                                password: password);
                                        t = true;
                                      } catch (e) {}

                                      if (t) {
                                        //Login successful

                                        loggedin = true;
                                        userID = _auth.currentUser.uid;
                                        userEmail = _auth.currentUser.email;
                                        await updateFirestoreOnLogin();
                                        await updateFirestore();
                                        Provider.of<UserRepository>(context,
                                                listen: false)
                                            .Authenticated();
                                        Navigator.of(context).pop();
                                        setState(() {
                                          //build(context);
                                        });
                                      } else {
                                        //Login FAILED
                                        userID = "";
                                        userEmail = "";
                                        final snackBar = SnackBar(
                                            content: Text(
                                                "There was an error signing up"));
                                        _scaffoldkeySaved.currentState
                                            .showSnackBar(snackBar);
                                        Provider.of<UserRepository>(context,
                                                listen: false)
                                            .Unauthenticated();
                                      }

                                      //myControllerEmail.dispose();
                                      //myControllerPass.dispose();

                                      Navigator.pop(context);
                                    } else {
                                      //Passwords do not match

                                    }
                                  },
                                )
                              ],
                            ),
                          ),
                        ));
                  },
                );
              },
              child: Text("New user? Click to sign up",
                  style: TextStyle(color: Colors.white)));

          return Scaffold(
              key: _scaffoldkeySaved,
              appBar: AppBar(
                title: Text('Login'),
              ),
              body: Column(
                  children: [Email, Password, loginButton, signupButton]));
        }, // ...to here.
      );

  void _pushLogin() {
    Navigator.of(context).push(
      loginMaterialPageRoute(),
    );
  }

  Future<void> signOut() async {
    await updateFirestore();
    _saved = {};
    await _auth.signOut();
    loggedin = false;
    userID = "";
    userEmail = "";
    imageLink = "";
    setState(() {
      //build(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkeyMainScreen,
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          IconButton(
              icon: loggedin ? Icon(Icons.exit_to_app) : Icon(Icons.login),
              onPressed: loggedin ? signOut : _pushLogin),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  Future<void> updateFirestoreOnLogin() async {
    List<dynamic> array1 = [];
    List<dynamic> array2 = [];
    DocumentSnapshot retrieve;
    Map myMap;
    CollectionReference database =
        FirebaseFirestore.instance.collection('Users');
    //---- Retrieval ----
    try {
      retrieve = await database.doc(userID).get();
      myMap = retrieve.data();
      array1 = myMap['firstList'];
      array2 = myMap['secondList'];
      var i = 0;
      for (String s1 in array1) {
        _saved.add(WordPair(s1, array2[i]));
        i += 1;
      }
    } catch (e) {}

    //if(retrieve.hasData){
    //var retrieveList=retrieve.entries.toList();

// }
//------
  }

  Future<void> updateFirestore() async {
    if (userID == "") {
      return;
    }
    List<String> array1 = [];
    List<String> array2 = [];

    CollectionReference database =
        await FirebaseFirestore.instance.collection('Users');

    for (WordPair p in _saved) {
      array1.add(p.first);
      array2.add(p.second);
    }

    await database
        .document(userID)
        .setData({'firstList': array1, 'secondList': array2});
    // }
    //Update the document with current _saved.
    //database.doc(userID).set({'saved':_saved});
    //database.doc(userID).update({'saved':_saved});
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            updateFirestore();
          } else {
            _saved.add(pair);
            updateFirestore();
          }
        });
      }, // ... to here.
    );
  }

  SnappingSheetController mysnapControl = SnappingSheetController();
  bool position = false;
  String imageLink = "";
  Widget _buildSuggestions() {
    //Provider.of<UserRepository>(context); //THIS CAUSES FIREBASE ERROR AT THE START
    final myposition = [
      SnapPosition(
          positionPixel: 0.0,
          snappingCurve: Curves.easeOut,
          snappingDuration: Duration(milliseconds: 700)),
      SnapPosition(
          positionPixel: MediaQuery
              .of(context)
              .size
              .height * 0.15,
          snappingCurve: Curves.easeIn,
          snappingDuration: Duration(milliseconds: 700)),
    ];
    return userID != ""
        ? Scaffold(
            body: SnappingSheet(
              snappingSheetController: mysnapControl,
              grabbing: GestureDetector(
                  onTap: () {

                    setState(() {
                      mysnapControl.snapToPosition(myposition[mysnapControl.currentSnapPosition == myposition[0] ? 1 : 0]);

                    });
                  },child:

                Container(
                  color: Colors.grey,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("      Welcome Back,  " + userEmail,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16)),
                        Container(
                            child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 30,
                        ))
                      ]),
                )

                ),
              //initSnapPosition: myposition[0],
                snapPositions: myposition,
                sheetBelow: SnappingSheetContent(
                    child: Container(
                      color: Colors.white,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                      image: NetworkImage(imageLink != ""
                                          ? imageLink
                                          : 'https://uxwing.com/wp-content/themes/uxwing/download/07-design-and-development/image-not-found.png'),
                                      fit: BoxFit.fill),
                                )),
                            SingleChildScrollView(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userEmail,
                                    style: TextStyle(

                                        color: Colors.black,
                                        fontSize: 22)),
                                FlatButton(
                                  color: Colors.teal,
                                  textColor: Colors.white,
                                  disabledColor: Colors.grey,
                                  disabledTextColor: Colors.black,
                                  padding: EdgeInsets.all(8.0),
                                  splashColor: Colors.teal,
                                  onPressed: () async {
                                    File _image;
                                    final picker = ImagePicker();
                                    var pickedFile = await picker.getImage(
                                        source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      _image = File(pickedFile.path);
                                      await FirebaseStorage.instance
                                          .ref()
                                          .child(userID)
                                          .putFile(_image);
                                      imageLink = await FirebaseStorage.instance
                                          .ref()
                                          .child(userID)
                                          .getDownloadURL();
                                      setState(() {});
                                    } else {
                                      final snackBar = SnackBar(
                                          content: Text("No image selected"));
                                      _scaffoldkeyMainScreen.currentState
                                          .showSnackBar(snackBar);
                                    }
                                  },
                                  child: Text("Change avatar"),
                                )
                              ],
                            ))
                          ]),
                    ),
                    heightBehavior: SnappingSheetHeight.fit()),
                child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // The itemBuilder callback is called once per suggested
                    // word pairing, and places each suggestion into a ListTile
                    // row. For even rows, the function adds a ListTile row for
                    // the word pairing. For odd rows, the function adds a
                    // Divider widget to visually separate the entries. Note that
                    // the divider may be difficult to see on smaller devices.
                    itemBuilder: (BuildContext _context, int i) {
                      // Add a one-pixel-high divider widget before each row
                      // in the ListView.
                      if (i.isOdd) {
                        return Divider();
                      }

                      // The syntax "i ~/ 2" divides i by 2 and returns an
                      // integer result.
                      // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
                      // This calculates the actual number of word pairings
                      // in the ListView,minus the divider widgets
                      final int index = i ~/ 2;
                      // If you've reached the end of the available word
                      // pairings...
                      if (index >= _suggestions.length) {
                        // ...then generate 10 more and add them to the
                        // suggestions list.
                        _suggestions.addAll(generateWordPairs().take(10));
                      }
                      return _buildRow(_suggestions[index]);
                    }),
              ),

          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            // The itemBuilder callback is called once per suggested
            // word pairing, and places each suggestion into a ListTile
            // row. For even rows, the function adds a ListTile row for
            // the word pairing. For odd rows, the function adds a
            // Divider widget to visually separate the entries. Note that
            // the divider may be difficult to see on smaller devices.
            itemBuilder: (BuildContext _context, int i) {
              // Add a one-pixel-high divider widget before each row
              // in the ListView.
              if (i.isOdd) {
                return Divider();
              }

              // The syntax "i ~/ 2" divides i by 2 and returns an
              // integer result.
              // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
              // This calculates the actual number of word pairings
              // in the ListView,minus the divider widgets.
              final int index = i ~/ 2;
              // If you've reached the end of the available word
              // pairings...
              if (index >= _suggestions.length) {
                // ...then generate 10 more and add them to the
                // suggestions list.
                _suggestions.addAll(generateWordPairs().take(10));
              }
              return _buildRow(_suggestions[index]);
            });
  }
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  FirebaseUser _user;
  Status _status = Status.Uninitialized;

  UserRepository() {
    Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
  }

  Status get status => _status;
  FirebaseUser get user => _user;

  void Authenticated() {
    _status = Status.Authenticated;
    notifyListeners();
  }

  void Authenticating() {
    _status = Status.Authenticating;
    notifyListeners();
  }

  void Unauthenticated() {
    _status = Status.Unauthenticated;
    notifyListeners();
  }

  void Update() {
    notifyListeners();
  }
}
