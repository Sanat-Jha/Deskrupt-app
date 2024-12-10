import 'dart:convert';
import 'package:deskrupt_app/bganimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

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

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("start");
    return const MaterialApp(
      home: Scaffold(
        body: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<Map<String, dynamic>>? futureDeck;
  final TextEditingController _deckCodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
      String? base64Image = prefs.getString('base64Image');

      if (deckData != null && deckCode != null && base64Image != null) {
        setState(() {
          futureDeck = Future.value(jsonDecode(deckData));
          _deckCodeController.text = deckCode;
        });
      } else {
        _showDeckCodeDialog();
      }
    } catch (e) {
      _showDeckCodeDialog();
    }
  }

  Future<void> _fetchAndSaveDeck(String deckCode) async {
    try {
      final response = await fetchDeck(deckCode);

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch deck: ${response['error']}")),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('deckData', jsonEncode(response));
      await prefs.setString('deckCode', deckCode);
      await prefs.setString('base64Image', response['base64Image']);  // Store the base64 image

      setState(() {
        Phoenix.rebirth(context); // Refresh the app
      });
    } catch (error) {
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
          title: const Text("Enter Deck Code"),
          content: TextField(
            controller: _deckCodeController,
            decoration: const InputDecoration(
              hintText: "Enter deck code (format: username/decktitletext/text)",
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                String input = _deckCodeController.text;
                if (RegExp(r'^[a-zA-Z0-9]+/[a-zA-Z0-9]+$').hasMatch(input)) {
                  _fetchAndSaveDeck(input);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
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
    return FutureBuilder(
      future: futureDeck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('No deck data available.'));
        } else {
          Map<String, dynamic> deck = snapshot.data as Map<String, dynamic>;

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
              animation: animation,
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

Future<Map<String, dynamic>> fetchDeck(String deckcode) async {
  try {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/app/deck"),
      headers: {
        'Content-Type': 'application/json',
        'token': 'from windows app',
      },
      body: jsonEncode({'deck': deckcode}),
    );

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);

      String imageUrl = body['bgimageurl'];

      // Fetch the image data and encode it as a base64 string
      var imageBytes = await Dio().get(imageUrl, options: Options(responseType: ResponseType.bytes));
      String base64Image = base64Encode(imageBytes.data);

      body['base64Image'] = base64Image;  // Add base64 image to the response body

      return body;
    } else {
      return {'error': 'Deck not found! (${response.statusCode})'};
    }
  } catch (e) {
    return {'error': 'Exception: $e'};
  }
}
