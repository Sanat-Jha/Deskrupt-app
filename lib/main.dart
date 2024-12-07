import 'dart:convert';
import 'dart:io';
import 'package:deskrupt_app/bganimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'fetch_deck.dart'; // Make sure to have this function to fetch the deck

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    title: "Deskrupt",
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(true);
    await windowManager.show();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Home(),
      ),
    );
  }
}
class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<Map<String, dynamic>>? futureDeck;
  TextEditingController _deckCodeController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool isCtrlPressed = false;
  bool isShiftPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadDeckFromPreferences();
  }

  Future<void> _loadDeckFromPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deckData = prefs.getString('deckData');
      String? deckCode = prefs.getString('deckCode');
      print("here");

      if (deckData != null && deckCode != null) {
        setState(() {
          futureDeck = Future.value(jsonDecode(deckData));
          _deckCodeController.text = deckCode;
        });
      } else {
        // No valid data in preferences, show the deck code dialog
        _showDeckCodeDialog();
      }
    } catch (e) {
      // Handle any errors and open the dialog box
      print("Error loading deck from preferences: $e");
      _showDeckCodeDialog();
    }
  }

  Future<void> _fetchAndSaveDeck(String deckCode) async {
    try {
      final response = await fetchDeck(deckCode);

      if (response.containsKey('error')) {
        // If the response contains an error, show a SnackBar and do nothing else
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch deck: ${response['error']}")),
        );
        return; // Early return to avoid updating SharedPreferences
      }
      final Directory directory = await getApplicationDocumentsDirectory();
      // If no error, save the deck data and deck code to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('deckData', jsonEncode(response));
      await prefs.setString('deckCode', deckCode);
      await prefs.setString('directory', directory.path);

      setState(() {
        futureDeck = Future.value(response);
              Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
      });

      // Reload the app by restarting the widget tree

    } catch (error) {
      // Handle network or unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch deck: $error")),
      );
    }
  }

  void _showDeckCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Deck Code"),
          content: TextField(
            controller: _deckCodeController,
            decoration: InputDecoration(
              hintText: "Enter deck code (format: username/decktitletext/text)",
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                String input = _deckCodeController.text;
                if (RegExp(r'^[a-zA-Z0-9]+/[a-zA-Z0-9]+$').hasMatch(input)) {
                  _fetchAndSaveDeck(input);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invalid format! Please use username/decktitle."),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
        print("built");

    return FutureBuilder(
      future: futureDeck,
      builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  } else if (snapshot.hasError || snapshot.data == null) {
    return Center(child: Text('No deck data available.'));
  } else {
    Map<String, dynamic> deck = snapshot.data as Map<String, dynamic>;

    // Handle null values by providing defaults
    String animation = deck['animation'] ?? 'default_animation';

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.physicalKey == PhysicalKeyboardKey.controlLeft ||
              event.physicalKey == PhysicalKeyboardKey.controlRight) {
            isCtrlPressed = true;
          }
          if (event.physicalKey == PhysicalKeyboardKey.shiftLeft ||
              event.physicalKey == PhysicalKeyboardKey.shiftRight) {
            isShiftPressed = true;
          }

          if (isCtrlPressed &&
              isShiftPressed &&
              event.physicalKey == PhysicalKeyboardKey.keyD) {
            _showDeckCodeDialog();
          }
        }

        if (event is KeyUpEvent) {
          if (event.physicalKey == PhysicalKeyboardKey.controlLeft ||
              event.physicalKey == PhysicalKeyboardKey.controlRight) {
            isCtrlPressed = false;
          }
          if (event.physicalKey == PhysicalKeyboardKey.shiftLeft ||
              event.physicalKey == PhysicalKeyboardKey.shiftRight) {
            isShiftPressed = false;
          }
        }
      },
      child: BGanimation(
        animation: animation, // Use the non-null animation string
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sanat Jha',
                  style: TextStyle(
                    fontFamily: 'NovaMono',
                    fontSize: 70,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
},

    );
  }
}
