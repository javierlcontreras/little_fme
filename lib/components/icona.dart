import 'dart:ui';
import 'dart:math';
import 'dart:collection';
import 'dart:io';

import 'package:little_fme/my-game.dart';
import 'package:little_fme/pantalla-mix.dart';
import 'package:little_fme/pantalla-add.dart';
import 'package:little_fme/pantalla-details.dart';
import 'package:little_fme/components/icona.dart';
import 'package:little_fme/components/my-element.dart';
import 'package:little_fme/components/recipe.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Icona {
  final MyGame game;

  double x;
  double y;
  MyElement el;

  Icona(this.game, double _x, double _y, MyElement _el) {
    x = _x;
    y = _y;
    el = _el;
  }

  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(
      x - game.tile/2,
      y - game.tile/2,
      game.tile,
      game.tile,
    );
    el.img.renderRect(canvas, bgRect);

    TextSpan span = new TextSpan(
        style: new TextStyle(fontSize: game.pad / 2, color: Color(0xffeeeeee)),
        text: el.name);
    TextPainter tp = new TextPainter(
        text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(x - game.tile/2, y + game.tile/2 + game.pad / 2));
  }

  void move(double _x, double _y) {
    x = _x;
    y = _y;
  }
}