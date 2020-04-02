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

class PantallaAdd {
  final MyGame game;

  PantallaAdd(this.game) {}

  void render(Canvas canvas) {
  /*  game.elements?.forEach((String s, MyElement e) {
      if (e.img.image == null) e.img = Sprite('default.png');
    });
  */
    Rect bgRect = Rect.fromLTWH(
        game.pad, game.pad, game.screenSize.width - 2 * game.pad, game.screenSize.height - 2*game.pad);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xffffffff);
    canvas.drawRect(bgRect, bgPaint);

    game.descoberts?.forEach((String nom) {
      game.elements[nom].render(canvas);
    });

    bgRect = Rect.fromLTWH(
        game.pad, game.pad, game.screenSize.width - 2 * game.pad, 4*game.pad);
    canvas.drawRect(bgRect, bgPaint);

    bgRect = Rect.fromLTWH(
        game.pad, game.screenSize.height - 2*game.pad, game.screenSize.width - 2 * game.pad, game.pad);
    canvas.drawRect(bgRect, bgPaint);

    Paint bgPaint2 = Paint();
    bgPaint2.color = Color(game.mixColor);
    bgRect = Rect.fromLTWH(
        game.pad, game.screenSize.height - game.pad, game.screenSize.width - 2 * game.pad, game.pad);
    canvas.drawRect(bgRect, bgPaint2);


    TextSpan span = new TextSpan(
        style: new TextStyle(fontSize: game.pad, color: Color(0xff000000)),
        text: game.descoberts.length.toString() + "/" + game.elements.length.toString() + " elements descoberts");
    TextPainter tp = new TextPainter(
        text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(2*game.pad, 2*game.pad + game.pad/2));

    drawCloseButton(canvas);
  }

  void drawCloseButton(Canvas canvas) {
    Paint _black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
        Offset(game.screenSize.width - 3 * game.pad, 3 * game.pad),
        game.pad-1, _black);
  }
}