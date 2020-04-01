import 'dart:ui';
import 'dart:math';
import 'dart:collection';
import 'dart:io' as io;

import 'package:little_fme/my-game.dart';
import 'package:little_fme/pantalla-mix.dart';
import 'package:little_fme/pantalla-add.dart';
import 'package:little_fme/pantalla-details.dart';
import 'package:little_fme/components/icona.dart';
import 'package:little_fme/components/my-element.dart';
import 'package:little_fme/components/recipe.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyElement {
  final MyGame game;

  String id;
  String name;
  String desc;
  Sprite img;

  double x;
  double y;

  Recipe A;
  Recipe B;
  Recipe C;

  MyElement(this.game, String _id, String _name, String _desc)  {
    id = _id;
    loadImage();
    name = _name;
    desc = _desc;
  }

  void loadImage() {
    img = Sprite(id + '.png');
  }

  void render(Canvas canvas) {
    double my = y - game.scroll;
    if (my >= game.startY && my <= game.endY) {
      Rect bgRect = Rect.fromLTWH(
        x,
        my,
        game.smalltile,
        game.smalltile,
      );
      img.renderRect(canvas, bgRect);

      TextSpan span = new TextSpan(
          style: new TextStyle(fontSize: game.pad / 2, color: Color(0xff000000)),
          text: name);
      TextPainter tp = new TextPainter(
          text: span, textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout(minWidth: game.smalltile);
      tp.paint(canvas, new Offset(x, my + game.smalltile + game.pad / 2));
    }
  }
}
