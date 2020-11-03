import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(          // Add the 3 lines from here...
        primaryColor: Colors.red,
      ),                         // ... to here.
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final GlobalKey<ScaffoldState> _scaffoldkeySaved = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldkeyLogin = new GlobalKey<ScaffoldState>();
  final List<WordPair> _suggestions = <WordPair>[];            // NEW
  final TextStyle _biggerFont = const TextStyle(fontSize: 18); // NEW
  final _saved = Set<WordPair>();     // NEW
  static bool disabledB=false;
  FirebaseAuth _auth;
  bool loggedin=false;
  String userID="";




  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
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
                onTap: () {      // NEW lines from here..
                  final snackBar = SnackBar(content: Text('Deletion is not implemented yet'));

// Find the Scaffold in the widget tree and use it to show a SnackBar.
                  _scaffoldkeySaved.currentState.showSnackBar(snackBar);
                },               // ... to here.
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
      ),
    );
  }

  void _pushLogin() {

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {

          final myControllerEmail = TextEditingController();
          final myControllerPass = TextEditingController();
          final Email = TextFormField(
            decoration: InputDecoration(
                labelText: 'Email'
            ),
            controller: myControllerEmail,
          );
          final Password = TextFormField(
            decoration: InputDecoration(
                labelText: 'Password'
            ),
            controller: myControllerPass,
          );
          final loginButton =FlatButton(
            onPressed: disabledB ? null : () async {
              //TODO: fix this somehow (IDK how to update this screen)
              disabledB = true;
              Navigator.of(context).setState(() {
                Navigator.of(context).build(context);
              });


              String emails=myControllerEmail.text;
              String passs=myControllerPass.text;
              bool t= false;

              _auth = FirebaseAuth.instance;


              try {
                await _auth.signInWithEmailAndPassword(email: emails, password: passs);
                t= true;
              } catch (e) {

              }

              disabledB=false;




              if(t){ //Login successful
                loggedin=true;
                userID=_auth.currentUser.uid;
                await updateFirestoreOnLogin();
                await updateFirestore();
                Navigator.of(context).pop();
                setState(() {
                  build(context);
                });

              }
              else{ //Login FAILED
                 userID="";
                 final snackBar = SnackBar(content: Text("There was an error logging into the app"));
                 _scaffoldkeyLogin.currentState.showSnackBar(snackBar);
              }
// Find the Scaffold in the widget tree and use it to show a SnackBar.

            },
            child: Text(
              "Log in",
            ),
            color:Colors.red,
            textColor: Colors.white,
          );

          return Scaffold(
              key: _scaffoldkeyLogin,
            appBar: AppBar(
              title: Text('Login'),
            ),
            body: Column(children:[Email,Password,loginButton])
          );
        }, // ...to here.
      ),
    );
  }
void signOut(){
  _auth.signOut();
  loggedin=false;
  userID="";
  setState(() {
    build(context);
  });
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          IconButton(icon: loggedin ? Icon(Icons.exit_to_app) : Icon(Icons.login), onPressed:loggedin ? signOut : _pushLogin),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

Future<void> updateFirestoreOnLogin() async {
  List<dynamic> array1=[];
  List<dynamic> array2=[];
  DocumentSnapshot retrieve;
  Map myMap;
  CollectionReference database = FirebaseFirestore.instance.collection('Users');
  //---- Retrieval ----
  try{
  retrieve= await database.doc(userID).get();
  }
  catch(e){
  }


  //if(retrieve.hasData){
  //var retrieveList=retrieve.entries.toList();
  myMap=retrieve.data();
  array1= myMap['firstList'];
  array2= myMap['secondList'];
  var i=0;
  for(String s1 in array1){
  _saved.add(WordPair(s1,array2[i]));
  i+=1;
  }
// }
//------
}
  Future<void> updateFirestore()  async {
    if(userID==""){
      return;
    }
    List<String> array1=[];
    List<String> array2=[];

    CollectionReference database = FirebaseFirestore.instance.collection('Users');

       for(WordPair p in _saved) {
         array1.add(p.first);
         array2.add(p.second);
       }

      await database.document(userID).setData({'firstList':array1,'secondList':array2});
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
      onTap: () {      // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            updateFirestore();
          } else {
            _saved.add(pair);
            updateFirestore();
          }
        });
      },               // ... to here.
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
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
        }
    );
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
