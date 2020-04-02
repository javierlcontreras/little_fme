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

class PantallaMix {
  final MyGame game;

  PantallaMix(this.game) {}

  void render(Canvas canvas) {

    Rect bgRect = Rect.fromLTWH(0, 0, game.screenSize.width, game.screenSize.height);
    Paint bgPaint = Paint();
    //bgPaint.color = Color(0xff576574);
    bgPaint.color = Color(game.mixColor);
    canvas.drawRect(bgRect, bgPaint);

    game.iconas?.forEach((Icona ic) => ic.render(canvas));

    Paint _black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (game.holding == null) {
      Paint _green = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(game.screenSize.width - game.tile, game.screenSize.height - game.tile),
          game.tile - game.pad, _green);
      canvas.drawCircle(
          Offset(game.screenSize.width - game.tile, game.screenSize.height - game.tile),
          game.tile - game.pad, _black);
    }
    Paint _red = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(game.tile, game.screenSize.height - game.tile),
        game.tile - game.pad, _red);
    canvas.drawCircle(
        Offset(game.tile, game.screenSize.height - game.tile),
        game.tile - game.pad, _black);
  }
}