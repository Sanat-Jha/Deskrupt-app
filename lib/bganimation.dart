import 'dart:convert';
import 'dart:typed_data';
import 'package:deskrupt_app/animations/bubble_animation.dart';
import 'package:deskrupt_app/animations/rain_animation.dart';
import 'package:flutter/material.dart';
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
  String? base64Image;

  @override
  void initState() {
    super.initState();
    _loadImageFromPreferences();
  }

  Future<void> _loadImageFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      base64Image = prefs.getString('base64Image');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (base64Image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Uint8List decodedBytes = base64Decode(base64Image!);

    Map<String, Widget> animations = {
      'Bubble': BubbleBackgroundContainer(
        backgroundImageWidget: Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
        ),
        child: widget.child,
      ),
      'Rain': RainBackgroundWidget(
        imageWidget: Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
        ),
        child: widget.child,
      ),
    };

    return animations[widget.animation] ?? Container();
  }
}
