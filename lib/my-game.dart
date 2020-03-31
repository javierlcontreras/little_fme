import 'dart:ui';
import 'dart:math';
import 'package:ordered_set/ordered_set.dart';

import 'package:little_fme/components/icona.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

class MyGame extends Game {
  Size screenSize;
  int n;
  double tile, smalltile;
  double pad;

  String pantalla; //mix, add, elem

  Map<String, MyElement> elements;
  Map<String, Recipe> recipes;
  Set<Icona> iconas;
  OrderedSet<String> descoberts;

  Icona holding;

  MyGame() {
    initialize();
  }

  void initialize() async {
    resize(await Flame.util.initialDimensions());
    tile = screenSize.width/8;
    pad = tile/3;
    n = 4;
    smalltile = (screenSize.width - (n+3)*pad)/n;
    pantalla = "mix";

    elements = Map<String, MyElement>();
    recipes = Map<String, Recipe>();
    iconas = Set<Icona>();
    descoberts = OrderedSet<String>();

    MyElement ivet = MyElement("ivet", "Ivet Acosta", "");
    MyElement anna = MyElement("erik", "Anna Felip", "Mama");
    MyElement erik = MyElement("anna", "Erik Ferrando", "Novato");
    elements["ivet"] = ivet;
    elements["anna"] = anna;
    elements["erik"] = erik;

    recipes["anna-erik"] = Recipe("endogamia", anna, erik, ivet);

    iconas.add(Icona(this, tile, tile, anna));
    iconas.add(Icona(this, tile, 3*tile, erik));
    descoberts.add("anna");
    descoberts.add("erik");
    //iconas.add(Icona(this, tile, 3*tile, ivet));
  }

  void render(Canvas canvas) {
    //print("...rendering...");

    Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff576574);
    canvas.drawRect(bgRect, bgPaint);
   /* bgRect = Rect.fromLTWH(screenSize.width - tile, 0, tile, screenSize.height);
    bgPaint = Paint();
    bgPaint.color = Color(0xffffffff);
    canvas.drawRect(bgRect, bgPaint);
  */
    iconas.forEach((Icona ic) => ic.render(canvas));

    Paint _black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (holding == null) {
      Paint _green = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(screenSize.width - tile, screenSize.height - tile),
          tile - pad, _green);
      canvas.drawCircle(
          Offset(screenSize.width - tile, screenSize.height - tile),
          tile - pad, _black);
    }
    Paint _red = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(tile, screenSize.height - tile),
        tile - pad, _red);
    canvas.drawCircle(
        Offset(tile, screenSize.height - tile),
        tile - pad, _black);

    if (pantalla == "add") {
      Rect bgRect = Rect.fromLTWH(
          pad, pad, screenSize.width - 2 * pad, screenSize.height - pad);
      Paint bgPaint = Paint();
      bgPaint.color = Color(0xffffffff);
      canvas.drawRect(bgRect, bgPaint);

      canvas.drawCircle(
          Offset(screenSize.width - 3 * pad, 3 * pad),
          pad, _black);

      descoberts.forEach((String nom) {
        double mx = elements[nom].x;
        double my = elements[nom].y;
        Rect bgRect = Rect.fromLTWH(
          mx,
          my,
          smalltile,
          smalltile,
        );
        elements[nom].img.renderRect(canvas, bgRect);

        TextSpan span = new TextSpan(
            style: new TextStyle(fontSize: pad/2, color: Color(0xff000000)),
                    text: elements[nom].name);
        TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center,
                                          textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, new Offset(mx, my + smalltile + pad / 2));
      });
    }
  }

  void update(double t) {
    iconas.forEach((Icona ic) => ic.update(t));

    double mx = 2*pad, my = 6*pad;
    descoberts.forEach((String nom) {
      elements[nom].x = mx;
      elements[nom].y = my;
      mx += smalltile + pad;
      if (mx > screenSize.width - 2*pad) {
        mx = 2*pad;
        my += smalltile + 2*pad;
      }
    });
  }

  void resize(Size size) {
    screenSize = size;
    super.resize(size);
  }

  double dist(double x1, double y1, double x2, double y2) {
    return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2));
  }

  void onPanStart(DragStartDetails d) {
    if (pantalla == "mix") {
      double x = d.globalPosition.dx;
      double y = d.globalPosition.dy;
      double r = tile;
      Icona best;
      iconas.forEach((Icona ic) {
        if (dist(x, y, ic.x, ic.y) < r) {
          r = dist(x, y, ic.x, ic.y);
          best = ic;
        }
      });
      holding = best;
    }
  }

  void onPanUpdate(DragUpdateDetails d) {
    if (pantalla == "mix") {
      if (holding == null) return;
      holding.move(d.globalPosition.dx, d.globalPosition.dy);
    }
  }

  void onPanEnd(DragEndDetails d) {
    if (pantalla == "mix") {
      if (holding == null) return;
      double x = holding.x;
      double y = holding.y;
      double r = tile / 2;

      if (dist(x, y, tile, screenSize.height - tile) < r) {
        iconas.remove(holding);
        holding = null;
        return;
      }

      Icona best;
      iconas.forEach((Icona ic) {
        if (ic != holding && dist(x, y, ic.x, ic.y) < r) {
          r = dist(x, y, ic.x, ic.y);
          best = ic;
        }
      });

      if (best == null) {
        holding = null;
        return;
      }

      String P1 = holding.el.id + "-" + best.el.id;
      String P2 = best.el.id + "-" + holding.el.id;
      iconas.remove(holding);
      iconas.remove(best);
      if (recipes.containsKey(P1)) {
        iconas.add(Icona(this, best.x, best.y, recipes[P1].p));
        descoberts.add(recipes[P1].p.id);
      }
      else if (recipes.containsKey(P2)) {
        iconas.add(Icona(this, best.x, best.y, recipes[P2].p));
        descoberts.add(recipes[P2].p.id);
      }
      holding = null;
    }
  }

  void onTapDown(TapDownDetails d) {
    double x = d.globalPosition.dx;
    double y = d.globalPosition.dy;
    double r = tile;
    if (pantalla == "mix") {
      if (dist(x, y, screenSize.width - tile, screenSize.height - tile) < r) {
        pantalla = "add";
      }
      if (dist(x, y, tile, screenSize.height - tile) < r) {
        iconas.clear();
      }
    }
    else if (pantalla == "add") {
      if (dist(x, y, screenSize.width - 3*pad, 3*pad) < r) {
        pantalla = "mix";
      }
    }
  }
}