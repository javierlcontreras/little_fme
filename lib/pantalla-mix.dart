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
    game.iconas?.forEach((Icona ic) => ic.render(canvas));

    Paint _black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (game.holding == null) {
      Paint _green = Paint()
        ..color = Color(0xff25d366)
        ..style = PaintingStyle.fill;
      final icon = Icons.add_circle;
      TextPainter textPainter = TextPainter(textDirection: TextDirection.rtl);
      textPainter.text = TextSpan(text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontSize: 2*(game.tile - game.pad),fontFamily: icon.fontFamily, color: Color(0xff3dc151)));
      textPainter.layout();
      textPainter.paint(canvas, Offset(game.screenSize.width - game.tile - (game.tile - game.pad), game.screenSize.height - 2*game.tile + game.pad));
      /*
      canvas.drawCircle(
          Offset(game.screenSize.width - game.tile, game.screenSize.height - game.tile),
          game.tile - game.pad, _green);
      canvas.drawCircle(
          Offset(game.screenSize.width - game.tile, game.screenSize.height - game.tile),
          game.tile - game.pad, _black);
          */
      Paint _red = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final icon2 = Icons.delete;
      TextPainter textPainter2 = TextPainter(textDirection: TextDirection.rtl);
      textPainter2.text = TextSpan(text: String.fromCharCode(icon2.codePoint),
          style: TextStyle(fontSize: 2*(game.tile - game.pad),fontFamily: icon2.fontFamily, color: Color(0xffFF5733)));
      textPainter2.layout();
      textPainter2.paint(canvas, Offset(game.pad, game.screenSize.height - 2*game.tile + game.pad));

    } else {
      Paint _red = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final icon = Icons.delete_forever;
      TextPainter textPainter = TextPainter(textDirection: TextDirection.rtl);
      textPainter.text = TextSpan(text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontSize: 2*(game.tile - game.pad),fontFamily: icon.fontFamily, color: Color(0xffFF5733)));
      textPainter.layout();
      textPainter.paint(canvas, Offset(game.pad, game.screenSize.height - 2*game.tile + game.pad));

    }

    /*
    canvas.drawCircle(
        Offset(game.tile, game.screenSize.height - game.tile),
        game.tile - game.pad, _red);
    canvas.drawCircle(
        Offset(game.tile, game.screenSize.height - game.tile),
        game.tile - game.pad, _black);

     */
  }
}

// Offset(game.screenSize.width - 5 * game.pad - 1, 3*game.pad + 1)