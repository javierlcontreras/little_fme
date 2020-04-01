import 'dart:ui';
import 'dart:math';

import 'dart:collection';

import 'package:little_fme/components/icona.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyGame extends Game {
  final SharedPreferences storage;
  Size screenSize;

  int n;
  double tile, smalltile, bigtile;
  double pad;

  double scroll;
  double scrollInit;
  double scrollLast;
  double scrollMax = 0;
  double startY, endY;

  String pantalla; //mix, add, details

  Map<String, MyElement> elements;
  Map<String, Recipe> recipes;
  Set<Icona> iconas;
  SplayTreeSet<String> descoberts;

  Icona holding;
  MyElement detailsShow;

  MyGame(this.storage) {
    initialize();
  }

  void initialize() async {
    resize(await Flame.util.initialDimensions());
    tile = screenSize.width/8;
    n = 5;
    pad = tile/3;
    smalltile = (screenSize.width - (n+3)*pad)/n;
    bigtile = screenSize.height/2 - 8*pad;
    startY = 6*pad;
    endY = screenSize.height;
    scrollInit = -1;
    scroll = 0;
    scrollLast = 0;

    pantalla = "mix";

    elements = Map<String, MyElement>();
    recipes = Map<String, Recipe>();
    iconas = Set<Icona>();

    descoberts = new SplayTreeSet<String>();
    updateDescoberts();
    afegirDades();

    recalcPosDescoberts();
  }

  void afegirDades() {
    MyElement ivet = MyElement("ivet", "Ivet Acosta", "");
    MyElement javier = MyElement("javier", "Javier LC", "");
    MyElement maria = MyElement("maria", "Maria Prat", "");
    MyElement laura = MyElement("laura", "Laura Arribas", "");
    MyElement anna = MyElement("erik", "Anna Felip", "Mama");
    MyElement erik = MyElement("anna", "Erik Ferrando", "Novato");
    elements["ivet"] = ivet;
    elements["anna"] = anna;
    elements["erik"] = erik;
    elements["javier"] = javier;
    elements["maria"] = maria;
    elements["laura"] = laura;
    recipes["anna-maria"] = Recipe("lala", anna, maria, laura);
    recipes["anna-erik"] = Recipe("endogamia", anna, erik, ivet);
    recipes["anna-javier"] = Recipe("endogamia2", anna, javier, laura);
    descoberts.add("anna");
    descoberts.add("erik");
    descoberts.add("javier");
    descoberts.add("maria");
    updateStorageDescoberts();
  }

  void updateStorageDescoberts() {
    storage.setStringList('descoberts', descoberts.toList());
  }

  void updateDescoberts() {
    descoberts = new SplayTreeSet.from(storage.getStringList('descoberts') ?? List<String>());
  }

  void recalcPosDescoberts() {
    double mx = 2*pad, my = startY;
    descoberts?.forEach((String nom) {
      elements[nom].x = mx;
      elements[nom].y = my;
      mx += smalltile + pad;
      if (mx > screenSize.width - 2*pad) {
        mx = 2*pad;
        my += smalltile + 2*pad;
      }
    });
  }

  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff576574);
    canvas.drawRect(bgRect, bgPaint);

    iconas?.forEach((Icona ic) => ic.render(canvas));

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

    if (pantalla == "add" || pantalla == "details") {
      Rect bgRect = Rect.fromLTWH(
          pad, pad, screenSize.width - 2 * pad, screenSize.height - pad);
      Paint bgPaint = Paint();
      bgPaint.color = Color(0xffffffff);
      canvas.drawRect(bgRect, bgPaint);

      canvas.drawCircle(
          Offset(screenSize.width - 3 * pad, 3 * pad),
          pad, _black);

      descoberts?.forEach((String nom) {
        double mx = elements[nom].x;
        double my = elements[nom].y - scroll;
        if (my >= startY && my <= endY) {
          Rect bgRect = Rect.fromLTWH(
            mx,
            my,
            smalltile,
            smalltile,
          );
          elements[nom].img.renderRect(canvas, bgRect);

          TextSpan span = new TextSpan(
              style: new TextStyle(fontSize: pad / 2, color: Color(0xff000000)),
              text: elements[nom].name);
          TextPainter tp = new TextPainter(
              text: span, textAlign: TextAlign.center,
              textDirection: TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, new Offset(mx, my + smalltile + pad / 2));
        }
      });
    }
    if (pantalla == "details") {
      Rect bgRect = Rect.fromLTWH(
          2*pad, screenSize.height/4, screenSize.width - 4 * pad, screenSize.height/2);
      Paint bgPaint = Paint();
      bgPaint.color = Color(0xffeeeeee);
      canvas.drawRect(bgRect, bgPaint);

      canvas.drawCircle(
          Offset(screenSize.width - 4 * pad, screenSize.height/4 + 2*pad),
          pad, _black);

      bgRect = Rect.fromLTWH(
        screenSize.width/2 - bigtile/2,
        screenSize.height/2 - bigtile/2,
        bigtile,
        bigtile,
      );
      detailsShow.img.renderRect(canvas, bgRect);
      TextSpan span = new TextSpan(
          style: new TextStyle(fontSize: pad, color: Color(0xff000000)),
          text: detailsShow.name);
      TextPainter tp = new TextPainter(
          text: span, textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, new Offset(3*pad, screenSize.height/2 + bigtile/2 + pad));

      span = new TextSpan(
          style: new TextStyle(fontSize: 4*pad/5, color: Color(0xff000000)),
          text: detailsShow.desc);
      tp = new TextPainter(
          text: span, textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, new Offset(3*pad, screenSize.height/2 + bigtile/2 + 2.5*pad));

    }
  }

  void resize(Size size) {
    screenSize = size;
  }

  void update(double t) {

  }

  double dist(double x1, double y1, double x2, double y2) {
    return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2));
  }

  void onPanStart(DragStartDetails d) {
    double x = d.globalPosition.dx;
    double y = d.globalPosition.dy;
    if (pantalla == "mix") {
      double r = tile;
      Icona best;
      iconas?.forEach((Icona ic) {
        if (dist(x, y, ic.x, ic.y) < r) {
          r = dist(x, y, ic.x, ic.y);
          best = ic;
        }
      });
      holding = best;
    }
    else if (pantalla == "add") {
      double r;
      String willHold = "";
      descoberts?.forEach((String nom) {
        double mx = elements[nom].x + smalltile/2;
        double my = elements[nom].y - scroll + smalltile/2;

        if (willHold == "" || dist(mx, my, x, y) < r) {
          willHold = nom;
          r = dist(mx, my, x, y);
        }
      });

      if (r > smalltile/2) {
        scrollInit = d.globalPosition.dy;
        scrollLast = scroll;
      }
      else {
        holding = Icona(this, x, y, elements[willHold]);
        iconas.add(holding);
        pantalla = "mix";
      }
    }
  }

  void onPanUpdate(DragUpdateDetails d) {
    if (pantalla == "mix") {
      if (holding == null) return;
      holding.move(d.globalPosition.dx, d.globalPosition.dy);
    }
    else if (pantalla == "add") {
      scroll = scrollLast + scrollInit - d.globalPosition.dy;
      if (scroll > scrollMax) scroll = scrollMax;
      if (scroll < 0) scroll = 0;
    }
  }

  void onPanEnd(DragEndDetails d) {
    if (pantalla == "mix") {
      if (holding == null) return;
      double x = holding.x;
      double y = holding.y;
      double r = tile / 2;

      if (dist(x, y, tile, screenSize.height - tile) < r ||
          (tile > x && screenSize.height - tile < y)) {
        iconas.remove(holding);
        holding = null;
        return;
      }

      Icona best;
      iconas?.forEach((Icona ic) {
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
      if (recipes.containsKey(P1)) {
        iconas.add(Icona(this, best.x, best.y, recipes[P1].p));
        if (!descoberts.contains(recipes[P1].p.id)) {
          descoberts.add(recipes[P1].p.id);
          updateStorageDescoberts();
          recalcPosDescoberts();
        }
        iconas.remove(holding);
        iconas.remove(best);
      }
      else if (recipes.containsKey(P2)) {
        iconas.add(Icona(this, best.x, best.y, recipes[P2].p));
        if (!descoberts.contains(recipes[P2].p.id)) {
          descoberts.add(recipes[P2].p.id);
          updateStorageDescoberts();
          recalcPosDescoberts();
        }
        iconas.remove(holding);
        iconas.remove(best);
      }
      holding = null;
    }
    else if (pantalla == "add") {
      scrollInit = -1;
    }
  }

  void onTapDown(TapDownDetails d) {
    double x = d.globalPosition.dx;
    double y = d.globalPosition.dy;

    if (pantalla == "mix") {
      double r = tile;
      if (dist(x, y, screenSize.width - tile, screenSize.height - tile) < r) {
        pantalla = "add";
      }
      if (dist(x, y, tile, screenSize.height - tile) < r) {
        iconas.clear();
      }
    }
    else if (pantalla == "add") {
      if (dist(x, y, screenSize.width - 3*pad, 3*pad) < tile) {
        pantalla = "mix";
      }
    }
    else if (pantalla == "details") {
      if (dist(x, y,
          screenSize.width - 4 * pad,
          screenSize.height/4 + 2*pad) < tile ||
          y < screenSize.height/4  ||
          y > 3*screenSize.height/4) {
        pantalla = "add";
      }
    }
  }

  void onTapUp(TapUpDetails d) {
    double x = d.globalPosition.dx;
    double y = d.globalPosition.dy;
    if (pantalla == "add") {
      double r = 1e9;
      String willHold = "";
      descoberts?.forEach((String nom) {
        double mx = elements[nom].x + smalltile/2;
        double my = elements[nom].y - scroll + smalltile/2;

        if (willHold == "" || dist(mx, my, x, y) < r) {
          willHold = nom;
          r = dist(mx, my, x, y);
        }
      });

      if (r <= smalltile/2) {
        pantalla = "details";
        detailsShow = elements[willHold];
      }
    }
  }
}


