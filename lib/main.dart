import 'dart:math';
import 'dart:ui';

import 'package:little_fme/my-game.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:flame/util.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/components/component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Util flameUtil = Util();
  flameUtil.fullScreen();
  flameUtil.setOrientation(DeviceOrientation.portraitUp);

  SharedPreferences storage = await SharedPreferences.getInstance();

  MyGame game = MyGame(storage);
  PanGestureRecognizer dragger = PanGestureRecognizer();
  TapGestureRecognizer tapper = TapGestureRecognizer();
  tapper.onTapDown = game.onTapDown;
  tapper.onTapUp = game.onTapUp;
  dragger.onStart = game.onPanStart;
  dragger.onUpdate = game.onPanUpdate;
  dragger.onEnd = game.onPanEnd;

  if (!kIsWeb) {
    await Flame.util.setPortrait();
    await Flame.util.fullScreen();
  }
  runApp(game.widget);

  flameUtil.addGestureRecognizer(dragger);
  flameUtil.addGestureRecognizer(tapper);
}
