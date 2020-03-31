import 'dart:ui';

import 'package:little_fme/my-game.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';

import 'package:flutter/material.dart';

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

  void update(double t) {

  }

  void move(double _x, double _y) {
    x = _x;
    y = _y;
  }
}

class MyElement {
  String id;
  String name;
  String desc;
  Sprite img;

  double x;
  double y;

  MyElement(String _id, String _name, String _desc) {
    id = _id;
    img = Sprite(id + '.png');
    name = _name;
    desc = _desc;
  }
}

class Recipe {
  String id;
  MyElement m1, m2;
  MyElement p;

  Recipe(String _id, MyElement _m1, MyElement _m2, MyElement _p) {
    id = _id;
    m1 = _m1;
    m2 = _m2;
    p = _p;
  }
}

