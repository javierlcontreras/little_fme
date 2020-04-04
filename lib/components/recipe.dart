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

class Recipe {
  final MyGame game;

  String id;
  MyElement m1, m2;
  MyElement p;

  Recipe(this.game, String _id, MyElement _m1, MyElement _m2, MyElement _p) {
    id = _id;
    m1 = _m1;
    m2 = _m2;
    p = _p;
  }
  
  void showRecipe(double y, Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(
      game.screenSize.width/4 - game.recipetile/2,
      y,
      game.recipetile,
      game.recipetile,
    );
    m1.img.renderRect(canvas, bgRect);

    TextSpan span = new TextSpan(
      style: new TextStyle(fontSize: game.pad/2, color: Color(0xff000000)),
      text:  m1.name);
    TextPainter tp = new TextPainter(
      text: span, textAlign: TextAlign.center,
      textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.recipetile);
    tp.paint(canvas, new Offset(game.screenSize.width/4 - game.recipetile/2, y + game.recipetile + game.pad/6));
  
    double xplus = 3/8*game.screenSize.width;
    span = new TextSpan(
      style: new TextStyle(fontSize: 2*game.pad, color: Color(0xff000000)),
      text: "+");
    tp = new TextPainter(
      text: span, textAlign: TextAlign.center,
      textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(xplus - 0.8*game.pad, y + game.recipetile/2 - game.pad));
  
  
    bgRect = Rect.fromLTWH(
      game.screenSize.width/2 - game.recipetile/2,
      y,
      game.recipetile,
      game.recipetile,
    );
    m2.img.renderRect(canvas, bgRect);
    span = new TextSpan(
      style: new TextStyle(fontSize: game.pad/2, color: Color(0xff000000)),
      text:  m2.name);
    tp = new TextPainter(
      text: span, textAlign: TextAlign.center,
      textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.recipetile);
    tp.paint(canvas, new Offset(game.screenSize.width/2 - game.recipetile/2,
              y + game.recipetile + game.pad/6));
  
    double xeq = 5/8*game.screenSize.width;
    span = new TextSpan(
      style: new TextStyle(fontSize: 2*game.pad, color: Color(0xff000000)),
      text: "=");
    tp = new TextPainter(
      text: span, textAlign: TextAlign.center,
      textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(xeq - 0.6*game.pad, y + game.recipetile/2 - game.pad));
  
    bgRect = Rect.fromLTWH(
      3/4*game.screenSize.width - game.recipetile/2,
      y,
      game.recipetile,
      game.recipetile,
    );
    p.img.renderRect(canvas, bgRect);
    span = new TextSpan(
      style: new TextStyle(fontSize: game.pad/2, color: Color(0xff000000)),
      text: p.name);
    tp = new TextPainter(
      text: span, textAlign: TextAlign.center,
      textDirection: TextDirection.ltr);
    tp.layout(minWidth: game.recipetile);
    tp.paint(canvas, new Offset(3/4*game.screenSize.width - game.recipetile/2,
                y + game.recipetile + game.pad/6));
  }
  void discoverRecipe() {
    MyElement prod = p;

    if (prod.A == null) {
      prod.A = this;
      return;
    }
    else if (prod.A == this) return;

    if (prod.B == null) {
      prod.B = this;
      return;
    }
    else if (prod.B == this) return;

    if (prod.C == null) {
      prod.C = this;
      return;
    }
    else if (prod.C == this) return;
  }

}

