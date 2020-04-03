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
import 'package:google_fonts/google_fonts.dart';

class PantallaInicial {
  final MyGame game;

  PantallaInicial(this.game) {}

  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(
        game.pad, game.pad, game.screenSize.width - 2 * game.pad, game.screenSize.height - 2*game.pad);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff4c80b9);
    RRect roundedRect = RRect.fromRectAndRadius(bgRect, Radius.circular(2*game.pad));
    canvas.drawRRect(roundedRect, bgPaint);

    TextSpan span = new TextSpan(
        style: new TextStyle(fontSize: game.tile + game.pad, color: Color(0xffffffff), fontFamily: 'TitleFont'),
        text: 'Little FME');
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.screenSize.width - 2 * game.pad);
    tp.paint(canvas, new Offset(game.pad, game.screenSize.height/4));

    span = new TextSpan(
        style: new TextStyle(fontSize: 1.5*game.pad, color: Color(0xffc9e3ff), fontFamily: 'TitleFont'),
        text: 'Trobes a faltar la FME? \n Crea-la des de zero!');
    tp = new TextPainter(text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.screenSize.width - 2 * game.pad);
    tp.paint(canvas, new Offset(game.pad, game.screenSize.height/4 + game.tile +  3*game.pad));



    Rect playRect = Rect.fromLTWH(
        game.screenSize.width/2 - 2*game.tile,
        game.screenSize.height/4 + game.tile +  8*game.pad,
        4*game.tile,
        2*game.tile);
    RRect playRRect = RRect.fromRectAndRadius(playRect, Radius.circular(2*game.pad));
    Paint playPaint = Paint();
    playPaint.color = Color(0xffffffff);
    canvas.drawRRect(playRRect, playPaint);

    playRect = Rect.fromLTWH(
        game.screenSize.width/2 - 2*game.tile + 0.75*game.pad,
        game.screenSize.height/4 + game.tile +  8*game.pad + 0.75*game.pad,
        4*game.tile - 1.5*game.pad,
        2*game.tile - 1.5*game.pad);
    playRRect = RRect.fromRectAndRadius(playRect, Radius.circular(game.pad));
    playPaint = Paint();

    playPaint.color = Color(0xffc9e3ff);
    canvas.drawRRect(playRRect, playPaint);

    span = new TextSpan(
        style: new TextStyle(fontSize: 1.6*game.tile - 2*game.pad, color: Color(0xff4c80b9), fontFamily: 'TitleFont'),
        text: 'Jugar!');
    tp = new TextPainter(text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.screenSize.width);
    tp.paint(canvas, new Offset(0, game.screenSize.height/4 + 0.8*game.tile + 9.5*game.pad));


  }

}
