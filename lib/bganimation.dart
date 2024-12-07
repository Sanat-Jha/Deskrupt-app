import 'dart:io';
import 'package:deskrupt_app/animations/bubble_animation.dart';
import 'package:deskrupt_app/animations/rain_animation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BGanimation extends StatefulWidget {
  final Widget child;
  final String animation;

  const BGanimation({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  State<BGanimation> createState() => _BGanimationState();
}

class _BGanimationState extends State<BGanimation> {
  late Future<String> _directoryPathFuture;

  @override
  void initState() {
    super.initState();
    _directoryPathFuture = _getDirectoryPath();
  }

  // Fetch the directory path asynchronously
  Future<String> _getDirectoryPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      final String filepath = prefs.getString('directory')??'';
    return filepath;
  }
  // Future<String> _getDirectoryPath() async {
  //   final Directory directory = await getApplicationDocumentsDirectory();
  //   return directory.path;
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _directoryPathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for the directory path
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Handle errors gracefully
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          // Directory path is ready; now build the animations map
          // String directoryPath = snapshot.data!;
          Map<String, Widget> animations = {
            'Bubble': BubbleBackgroundContainer(
              backgroundImageWidget: Image.file(
                File(snapshot.data!+"\\deck.png"),
                fit: BoxFit.cover,
              ),
              child: widget.child,
            ),
            'Rain': RainBackgroundWidget(
              imageWidget: Image.file(
                File(snapshot.data!+"\\deck.png"),
                fit: BoxFit.cover,
              ),
              child: widget.child,
            ),
          };

          // Return the selected animation
          return animations[widget.animation] ?? Container();
        } else {
          // Fallback if no data is available
          return const Center(child: Text('Something went wrong'));
        }
      },
    );
  }
}
