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

class PantallaDetails {
  final MyGame game;

  PantallaDetails(this.game) {}

  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(
        game.pad, game.pad, game.screenSize.width - 2 * game.pad, game.screenSize.height - 2*game.pad);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xffffffff);
    RRect roundedRect = RRect.fromRectAndRadius(bgRect, Radius.circular(2*game.pad));
    canvas.drawRRect(roundedRect, bgPaint);


    Paint _black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    bgRect = Rect.fromLTWH(
        2*game.pad, 2*game.pad, game.screenSize.width - 4 * game.pad, game.screenSize.height - 4 * game.pad);
    bgPaint = Paint();
    bgPaint.color = Color(0xffeeeeee);
    RRect bgRRect = RRect.fromRectAndRadius(bgRect, Radius.circular(2*game.pad));
    canvas.drawRRect(bgRRect, bgPaint);

    final icon = Icons.close;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: 2*game.pad-2,fontFamily: icon.fontFamily, color: Color(0xff000000)));
    textPainter.layout();
    textPainter.paint(canvas, Offset(game.screenSize.width - 5 * game.pad - 1, 3*game.pad + 1));

    bgRect = Rect.fromLTWH(
      game.screenSize.width/2 - game.bigtile/2,
      5*game.pad,
      game.bigtile,
      game.bigtile,
    );

    game.detailsShow.img.renderRect(canvas, bgRect);
    TextSpan span = new TextSpan(
        style: new TextStyle(fontSize: 2*game.pad, color: Color(0xff000000)),
        text: game.detailsShow.name + (game.detailsShow.mort ? " \u2713" : ""));
    TextPainter tp = new TextPainter(
        text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1);
    tp.layout(minWidth: game.screenSize.width - 4 * game.pad, maxWidth: game.screenSize.width - 6 * game.pad);
    tp.paint(canvas, new Offset(2*game.pad, 6*game.pad + game.bigtile));


    span = new TextSpan(
        style: new TextStyle(fontSize: game.pad, color: Color(0xff000000)),
        text: game.detailsShow.desc);
    tp = new TextPainter(
        text: span, textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2);
    tp.layout(minWidth: game.screenSize.width - 6 * game.pad, maxWidth: game.screenSize.width - 6 * game.pad);
    tp.paint(canvas, new Offset(3*game.pad, 6*game.pad + game.bigtile + 3*game.pad));

    String txt = game.detailsShow.countr().toString() + "/" + game.detailsShow.maxr.toString() + " receptes descobertes";
    if (game.detailsShow.maxr == 0) txt = "Aquest element és bàsic";
    span = new TextSpan(
        style: new TextStyle(fontSize: game.pad, color: Color(0xff000000)),
        text: txt);
    tp = new TextPainter(
        text: span, textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        maxLines: 1);
    tp.layout(minWidth: game.screenSize.width - 6 * game.pad, maxWidth: game.screenSize.width - 6 * game.pad);
    tp.paint(canvas, new Offset(3*game.pad, game.screenSize.height/2 + game.pad));


    if (game.detailsShow.A != null) {
      game.detailsShow.A.showRecipe(game.screenSize.height/2 + 3*game.pad, canvas);
    }
    if (game.detailsShow.B != null) {
      game.detailsShow.B.showRecipe(game.screenSize.height/2 + 4*game.pad + game.recipetile, canvas);
    }
    if (game.detailsShow.C != null) {
      game.detailsShow.C.showRecipe(game.screenSize.height/2 + 5*game.pad + 2*game.recipetile, canvas);
    }
  }
}