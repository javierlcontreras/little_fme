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

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Util flameUtil = Util();
  flameUtil.fullScreen();
  flameUtil.setOrientation(DeviceOrientation.portraitUp);

  Flame.images.loadAll(<String>[
    'anna.png',
    'ivet.png',
    'erik.png',
  ]);

  MyGame game = MyGame();
  PanGestureRecognizer dragger = PanGestureRecognizer();
  TapGestureRecognizer tapper = TapGestureRecognizer();
  tapper.onTapDown = game.onTapDown;
  dragger.onStart = game.onPanStart;
  dragger.onUpdate = game.onPanUpdate;
  dragger.onEnd = game.onPanEnd;
  runApp(game.widget);
  flameUtil.addGestureRecognizer(dragger);
  flameUtil.addGestureRecognizer(tapper);
}
