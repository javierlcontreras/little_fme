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

class PantallaInicial {
  final MyGame game;

  PantallaInicial(this.game) {}

  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(
        game.pad, game.pad, game.screenSize.width - 2 * game.pad, game.screenSize.height/3);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xffffffff);
    canvas.drawRect(bgRect, bgPaint);
  }

}