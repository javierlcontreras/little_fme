import 'dart:ui';
import 'dart:math';
import 'dart:collection';
import 'dart:io';

import 'package:little_fme/my-game.dart';
import 'package:little_fme/pantalla-inicial.dart';
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

double dist(double x1, double y1, double x2, double y2) {
  return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2));
}

class MyGame extends Game {
  final SharedPreferences storage;
  Size screenSize;

  int n;
  double tile, smalltile, bigtile, recipetile;
  double pad;

  double scroll;
  double scrollDetails;
  double scrollInit;
  double scrollLast;
  double scrollMax = 1000;
  double startY, endY;

  String pantalla; //mix, add, details
  int mixColor;

  PantallaInicial inicial;
  PantallaMix mix;
  PantallaAdd add;
  PantallaDetails details;

  Map<String, MyElement> elements;
  Map<String, Recipe> recipes;
  Set<Icona> iconas;
  SplayTreeSet<String> descoberts;
  SplayTreeSet<String> descobertsRecipes;

  Icona holding;
  MyElement detailsShow;

  MyGame(this.storage) {
    initialize();
  }

  void initialize() async {
    resize(await Flame.util.initialDimensions());

    tile = screenSize.width/8;
    n = 4;
    pad = tile/3;
    smalltile = (screenSize.width - (n+5)*pad)/n;
    bigtile = screenSize.height/2 - 12*pad;
    recipetile = (screenSize.height - bigtile - 15*pad - 7*pad)/3;

    startY = pad;
    endY = screenSize.height - pad;
    scrollInit = -1;
    scroll = 0;
    scrollDetails = 0;
    scrollLast = 0;

    mixColor = 0xffAAD3FF;
    pantalla = "inicial";

    elements = Map<String, MyElement>();
    recipes = Map<String, Recipe>();
    iconas = Set<Icona>();

    inicial = PantallaInicial(this);
    mix = PantallaMix(this);
    add = PantallaAdd(this);
    details = PantallaDetails(this);

    descoberts = new SplayTreeSet<String>();
    descobertsRecipes = new SplayTreeSet<String>();

    readDescoberts();
    readDescobertsRecipes();

    // TODO uncomment reads to not restart game every time

    afegirDades();
    //cheat();

    contaReceptesPerElement();
    propagarGastades();
    propagarDescobertsRecipes();
    recalcPosDescoberts();
  }

  void contaReceptesPerElement() {
    recipes.forEach((String id, Recipe r) {
      r.p.maxr++;
    });
  }

  void propagarGastades() {
    recipes.forEach((String id, Recipe r) {
      if (!descobertsRecipes.contains(id)) {
        r.m1.mort = false;
        r.m2.mort = false;
      }
    });
  }

  void propagarDescobertsRecipes() {
    for (var a in descobertsRecipes) {
      recipes[a].discoverRecipe();
    }
  }

  void saveDescoberts() {
    storage.setStringList('descoberts', descoberts.toList());
  }

  void readDescoberts() {
    descoberts = new SplayTreeSet.from(storage.getStringList('descoberts') ?? List<String>());
  }

  void saveDescobertsRecipes() {
    storage.setStringList('descobertsRecipes', descobertsRecipes.toList());
  }

  void readDescobertsRecipes() {
    descobertsRecipes = new SplayTreeSet.from(storage.getStringList('descobertsRecipes') ?? List<String>());
  }

  void recalcPosDescoberts() {
    double mx = 3*pad, my = 6*pad;

    scrollMax = 1.0*((descoberts?.length ?? 0)/n).ceil();
    scrollMax -= ((screenSize.height - 7*pad)/(smalltile + 2*pad)).floor();
    scrollMax *= (smalltile + 2*pad);
    if (scrollMax < 0) scrollMax = 0;

    int it = 0;
    descoberts?.forEach((String nom) {
      elements[nom].x = mx;
      elements[nom].y = my;
      mx += smalltile + pad;
      it++;
      if (it == n) {
        it = 0;
        mx = 3*pad;
        my += smalltile + 2*pad;
      }
    });
  }

  void render(Canvas canvas) {
    mix.render(canvas);
    if (pantalla == "inicial") inicial.render(canvas);
    if (pantalla == "add" || pantalla == "details") {
      add.render(canvas);
    }
    if (pantalla == "details") {
      details.render(canvas);
    }
  }

  // GESTURES
  void onPanStart(DragStartDetails d) {
    if (pantalla == "inicial") {
      pantalla = "mix";
      return;
    }
    double x = d.globalPosition.dx;
    double y = d.globalPosition.dy;
    if (pantalla == "mix") {
      double r = tile;
      Icona best;
      iconas?.forEach((Icona ic) {
        if (dist(x, y, ic.x, ic.y+pad) < r) {
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
        double my = elements[nom].y - scroll + smalltile/2 + pad;

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

      String M1 = holding.el.id;
      String M2 = best.el.id;
      if (M1.compareTo(M2) > 0) {
        String aux = M1;
        M1 = M2;
        M2 = aux;
      }
      String P = M1 + "-" + M2;
      if (recipes.containsKey(P)) {

        if (!descobertsRecipes.contains(P)) {
          recipes[P].discoverRecipe();
          descobertsRecipes.add(P);
          saveDescobertsRecipes();
          pantalla = "details";
          detailsShow = elements[recipes[P].p.id];
          if (!descoberts.contains(recipes[P].p.id)) {
            descoberts.add(recipes[P].p.id);
            saveDescoberts();
            recalcPosDescoberts();
          }
          propagarGastades();
        }
        iconas.add(Icona(this, best.x, best.y, recipes[P].p));
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
    if (pantalla == "inicial") {
      pantalla = "mix";
      return;
    }
  }
  void onTapUp(TapUpDetails d) {
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
        return;
      }

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
    else if (pantalla == "details") {
      if (dist(x, y,
          screenSize.width - 4 * pad, 4*pad) < tile) {
        pantalla = "add";
      }
    }

  }

  // USELESS
  void resize(Size size) {
    screenSize = size;
  }
  void update(double t) {

  }

  // MACHINE GENERATED CODE
  void afegirDades() {
    MyElement mates = MyElement(this, "mates", "Mates", "El que ens uneix a tots nosaltres");
    elements["mates"] = mates;
    MyElement alcohol = MyElement(this, "alcohol", "Alcohol", "Hemos venido a emborracharnos y el resultado nos da igual");
    elements["alcohol"] = alcohol;
    MyElement drama = MyElement(this, "drama", "Drama", "Indispensable a una bona festa");
    elements["drama"] = drama;
    MyElement salseo = MyElement(this, "salseo", "Salseo", "Essencial");
    elements["salseo"] = salseo;
    MyElement cuqui = MyElement(this, "cuqui", "Cuqui", "Només ens donem la mà");
    elements["cuqui"] = cuqui;
    MyElement risas = MyElement(this, "risas", "Risas", "JAJAJAJAJAJAJA");
    elements["risas"] = risas;
    MyElement ivetacosta = MyElement(this, "ivetacosta", "Ivet", "La reiiiiiina del salseo");
    elements["ivetacosta"] = ivetacosta;
    MyElement fme = MyElement(this, "fme", "FME", "Família");
    elements["fme"] = fme;
    MyElement novatos = MyElement(this, "novatos", "Novatos", "Els bebés de la FME");
    elements["novatos"] = novatos;
    MyElement birres = MyElement(this, "birres", "Birres", "1,60€");
    elements["birres"] = birres;
    MyElement amor = MyElement(this, "amor", "Amor", "Pesaos");
    elements["amor"] = amor;
    MyElement festa = MyElement(this, "festa", "Festa", "La festa continua a Barrokos");
    elements["festa"] = festa;
    MyElement terrassa = MyElement(this, "terrassa", "Terrassa", "La cité de l’amour");
    elements["terrassa"] = terrassa;
    MyElement samucapellas = MyElement(this, "samucapellas", "Samu", "Sabes el guapo? Pues su novio");
    elements["samucapellas"] = samucapellas;
    MyElement potar = MyElement(this, "potar", "Potar", "Récord: 4 llits");
    elements["potar"] = potar;
    MyElement upc = MyElement(this, "upc", "UPC", "Universitat Politècnica de Catalunya");
    elements["upc"] = upc;
    MyElement profe = MyElement(this, "profe", "Profe", "Torturador");
    elements["profe"] = profe;
    MyElement barsanjuan = MyElement(this, "barsanjuan", "Bar San Juan", "No confondre amb Cafetería Molino");
    elements["barsanjuan"] = barsanjuan;
    MyElement lio = MyElement(this, "lio", "Lio", "El que hauries d’estar fent ara mateix");
    elements["lio"] = lio;
    MyElement cfis = MyElement(this, "cfis", "CFIS", "Capullus");
    elements["cfis"] = cfis;
    MyElement ressaca = MyElement(this, "ressaca", "Ressaca", "Noches de desenfreno, mañanas de ibuprofeno");
    elements["ressaca"] = ressaca;
    MyElement dele = MyElement(this, "dele", "Dele", "Delegació d’alumnes de la FME");
    elements["dele"] = dele;
    MyElement maripaz = MyElement(this, "maripaz", "Mari Paz", "Profe I Would Like to Fuck");
    elements["maripaz"] = maripaz;
    MyElement examen = MyElement(this, "examen", "Examen", "Rip");
    elements["examen"] = examen;
    MyElement albertjimenez = MyElement(this, "albertjimenez", "Albert Jiménez", "Pepino");
    elements["albertjimenez"] = albertjimenez;
    MyElement gabrialujas = MyElement(this, "gabrialujas", "Gabri", "Tirillas");
    elements["gabrialujas"] = gabrialujas;
    MyElement oriolbaeza = MyElement(this, "oriolbaeza", "Oriol Baeza", "Toca el clarinet xd");
    elements["oriolbaeza"] = oriolbaeza;
    MyElement luisdelbar = MyElement(this, "luisdelbar", "Luis del Bar", "L’explotació és il·legal");
    elements["luisdelbar"] = luisdelbar;
    MyElement sergiodelbar = MyElement(this, "sergiodelbar", "Sergio del Bar", "Alcohòlic");
    elements["sergiodelbar"] = sergiodelbar;
    MyElement rafahhajjar = MyElement(this, "rafahhajjar", "Rafah", "Mr. abraçades");
    elements["rafahhajjar"] = rafahhajjar;
    MyElement sortida = MyElement(this, "sortida", "Sortida de la Dele", "Se líaaaaaa");
    elements["sortida"] = sortida;
    MyElement pelea = MyElement(this, "pelea", "Pelea", "Uno pa uno sin camiseta");
    elements["pelea"] = pelea;
    MyElement recu = MyElement(this, "recu", "Recu", "rip en majúscules");
    elements["recu"] = recu;
    MyElement dunatomas = MyElement(this, "dunatomas", "Duna", "Panda lover");
    elements["dunatomas"] = dunatomas;
    MyElement graf = MyElement(this, "graf", "Graf", "Connecting people");
    elements["graf"] = graf;
    MyElement abracada = MyElement(this, "abracada", "Abraçada", "Per què no m’estàs abraçant?");
    elements["abracada"] = abracada;
    MyElement guapo = MyElement(this, "guapo", "Guapo", "Rafah guapo");
    elements["guapo"] = guapo;
    MyElement dormir = MyElement(this, "dormir", "Dormir", "Zzzz");
    elements["dormir"] = dormir;
    MyElement erikferrando = MyElement(this, "erikferrando", "Erik Ferrando", "Ferpolles, Nepe, Fulrecu, Fregando, Fernepinya...");
    elements["erikferrando"] = erikferrando;
    MyElement segon = MyElement(this, "segon", "Segon", "Millor curs");
    elements["segon"] = segon;
    MyElement odi = MyElement(this, "odi", "Odi", "A la FME? Mai");
    elements["odi"] = odi;
    MyElement einstein = MyElement(this, "einstein", "Einstein", "In Memoriam");
    elements["einstein"] = einstein;
    MyElement numerica = MyElement(this, "numerica", "Numèrica", "La xupa");
    elements["numerica"] = numerica;
    MyElement tiracanyes = MyElement(this, "tiracanyes", "Tiracanyes", "El que tothom és quan va una mica passat de copes");
    elements["tiracanyes"] = tiracanyes;
    MyElement gespeta = MyElement(this, "gespeta", "Gespeta", "Odia la festa gran");
    elements["gespeta"] = gespeta;
    MyElement foratalsostre = MyElement(this, "foratalsostre", "Forat al sostre", "Puto fernepe vaya cabrón, FERNEPINYAAA");
    elements["foratalsostre"] = foratalsostre;
    MyElement tercer = MyElement(this, "tercer", "Tercer", "Any del paso");
    elements["tercer"] = tercer;
    MyElement brisca = MyElement(this, "brisca", "Brisca", "Basurisca");
    elements["brisca"] = brisca;
    MyElement borde = MyElement(this, "borde", "Borde", "edroB");
    elements["borde"] = borde;
    MyElement elegant = MyElement(this, "elegant", "Elegant", "Contrari de Civit");
    elements["elegant"] = elegant;
    MyElement rubendelbar = MyElement(this, "rubendelbar", "Rubén del Bar", "àlies InformerFME");
    elements["rubendelbar"] = rubendelbar;
    MyElement edusimon = MyElement(this, "edusimon", "Edu Simón", "Edu calla");
    elements["edusimon"] = edusimon;
    MyElement laiapomar = MyElement(this, "laiapomar", "Laia Pomar", "End call for everyone");
    elements["laiapomar"] = laiapomar;
    MyElement frisbee = MyElement(this, "frisbee", "Frisbee", "Plat volador");
    elements["frisbee"] = frisbee;
    MyElement quart = MyElement(this, "quart", "Quart", "Fidels sala CFIS");
    elements["quart"] = quart;
    MyElement secta = MyElement(this, "secta", "Secta", "@sectasectafme");
    elements["secta"] = secta;
    MyElement enaitzquilez = MyElement(this, "enaitzquilez", "Enaitz", "Mandarina");
    elements["enaitzquilez"] = enaitzquilez;
    MyElement olgamartinez = MyElement(this, "olgamartinez", "Olga", "La xonaka de la FME");
    elements["olgamartinez"] = olgamartinez;
    MyElement porros = MyElement(this, "porros", "Porros", "Mmmmonchis");
    elements["porros"] = porros;
    MyElement lauraarribas = MyElement(this, "lauraarribas", "Laura Arribas", "En boca cerrada no entran moscas");
    elements["lauraarribas"] = lauraarribas;
    MyElement irenecusine = MyElement(this, "irenecusine", "Irene", "Un 7");
    elements["irenecusine"] = irenecusine;
    MyElement marionasanchez = MyElement(this, "marionasanchez", "Mariona Sánchez", "Con salsa, sin salsa");
    elements["marionasanchez"] = marionasanchez;
    MyElement festadenadal = MyElement(this, "festadenadal", "Festa de Nadal", "All I want for Christmas is Barrokos");
    elements["festadenadal"] = festadenadal;
    MyElement amaliasimon = MyElement(this, "amaliasimon", "Amàlia", "Pots plorar si vols, plorar és bo");
    elements["amaliasimon"] = amaliasimon;
    MyElement zorra = MyElement(this, "zorra", "Zorra", "RAAAAWR");
    elements["zorra"] = zorra;
    MyElement albertgimo = MyElement(this, "albertgimo", "Albert Gimó", "Albert-Francesc");
    elements["albertgimo"] = albertgimo;
    MyElement esport = MyElement(this, "esport", "Esport", "I just wanna make you sweat");
    elements["esport"] = esport;
    MyElement cinque = MyElement(this, "cinque", "Cinquè", "Perdona, qui?");
    elements["cinque"] = cinque;
    MyElement claudiarodes = MyElement(this, "claudiarodes", "Clàudia Rodés", "Cookie");
    elements["claudiarodes"] = claudiarodes;
    MyElement patricorbera = MyElement(this, "patricorbera", "Patri", "Què mires nen?");
    elements["patricorbera"] = patricorbera;
    MyElement victordeblas = MyElement(this, "victordeblas", "Víctor de Blas", "Víctor el Blau");
    elements["victordeblas"] = victordeblas;
    MyElement picatrencada = MyElement(this, "picatrencada", "Pica trencada", "Després ens vam rentar les mans");
    elements["picatrencada"] = picatrencada;
    MyElement perrofla = MyElement(this, "perrofla", "Perrofla", "Rinyo i rastess");
    elements["perrofla"] = perrofla;
    MyElement jordicondom = MyElement(this, "jordicondom", "Condom", "Burro");
    elements["jordicondom"] = jordicondom;
    MyElement xino = MyElement(this, "xino", "Xino", "Esquereeeee");
    elements["xino"] = xino;
    MyElement gerardcontreras = MyElement(this, "gerardcontreras", "Gerard Contreras", "Cuquíssim");
    elements["gerardcontreras"] = gerardcontreras;
    MyElement premi = MyElement(this, "premi", "Premi", "I el guanyador és…. la diversió!");
    elements["premi"] = premi;
    MyElement davidariza = MyElement(this, "davidariza", "David Ariza", "Eleven");
    elements["davidariza"] = davidariza;
    MyElement cefme = MyElement(this, "cefme", "CEFME", "SALUT, CEFME");
    elements["cefme"] = cefme;
    MyElement nofestes = MyElement(this, "nofestes", "No Festes", "Grande festes 99’");
    elements["nofestes"] = nofestes;
    MyElement annafelip = MyElement(this, "annafelip", "Anna Felip", "La mami no tan mami");
    elements["annafelip"] = annafelip;
    MyElement mortissim = MyElement(this, "mortissim", "Mortíssim", "Envia’l a la funeraria mortíssim, l’incineren per tu");
    elements["mortissim"] = mortissim;
    MyElement javilopezcontreras = MyElement(this, "javilopezcontreras", "Javi", "Súper creador d’aquest joc");
    elements["javilopezcontreras"] = javilopezcontreras;
    MyElement heredia = MyElement(this, "heredia", "Heredia", "Ampl, Matlab, Pràctiques, el símplex");
    elements["heredia"] = heredia;
    MyElement roura = MyElement(this, "roura", "Roura", "Doncs això...");
    elements["roura"] = roura;
    MyElement pichi = MyElement(this, "pichi", "Pichi", "Activitat de la franja cultural");
    elements["pichi"] = pichi;
    MyElement luissierra = MyElement(this, "luissierra", "Luis Sierra", "Putíssim Luis Sierra");
    elements["luissierra"] = luissierra;
    MyElement jaumemarti = MyElement(this, "jaumemarti", "Jaume Martí", "Gràcies per les classes de repàs");
    elements["jaumemarti"] = jaumemarti;
    MyElement cubatada = MyElement(this, "cubatada", "Cubatada", "Però de cubates de veritat");
    elements["cubatada"] = cubatada;
    MyElement pauredon = MyElement(this, "pauredon", "Pau Redón", "El frontón");
    elements["pauredon"] = pauredon;
    MyElement info = MyElement(this, "info", "Info", "Carrera molt inferior a mates");
    elements["info"] = info;
    MyElement lamari = MyElement(this, "lamari", "La Mari", "La pots trobar en el party después del party que se llama el afterparty");
    elements["lamari"] = lamari;
    MyElement mariaprat = MyElement(this, "mariaprat", "Maria Prat", "Súper creadora d’aquest joc");
    elements["mariaprat"] = mariaprat;
    MyElement janafarran = MyElement(this, "janafarran", "Jana Farran", "Algun dia");
    elements["janafarran"] = janafarran;
    MyElement jordicivit = MyElement(this, "jordicivit", "Jordi Civit", "Comi fills de puta");
    elements["jordicivit"] = jordicivit;
    MyElement carlotacorrales = MyElement(this, "carlotacorrales", "Carlota Corrales", "Com es diu la teva germana?");
    elements["carlotacorrales"] = carlotacorrales;
    MyElement martinacolas = MyElement(this, "martinacolas", "Martina Colás", "Jordi, calla");
    elements["martinacolas"] = martinacolas;
    MyElement verapujadas = MyElement(this, "verapujadas", "Vera Pujadas", "Veralimonchela");
    elements["verapujadas"] = verapujadas;
    MyElement carlotagracia = MyElement(this, "carlotagracia", "Carlota Gràcia", "Pink lady");
    elements["carlotagracia"] = carlotagracia;
    MyElement andreuhuguet = MyElement(this, "andreuhuguet", "Andreu Huguet", "De res");
    elements["andreuhuguet"] = andreuhuguet;
    MyElement jordivila = MyElement(this, "jordivila", "Jordi Vilà", "Heineken");
    elements["jordivila"] = jordivila;
    MyElement maxruiz = MyElement(this, "maxruiz", "Max Ruiz", "Amb la dessuadora de Rick & Morty, millor");
    elements["maxruiz"] = maxruiz;
    MyElement edupena = MyElement(this, "edupena", "Edu Peña", "Edu calla");
    elements["edupena"] = edupena;
    MyElement danimunoz = MyElement(this, "danimunoz", "Dani Muñoz", "Un, dos, TREEES");
    elements["danimunoz"] = danimunoz;
    MyElement edgarmoreno = MyElement(this, "edgarmoreno", "Edgar Moreno", "El terror de los profes");
    elements["edgarmoreno"] = edgarmoreno;
    MyElement silviagarcia = MyElement(this, "silviagarcia", "Sílvia Garcia", "Una cosaaaa");
    elements["silviagarcia"] = silviagarcia;
    MyElement josepfontana = MyElement(this, "josepfontana", "Josep Fontana", "Fontana di Trevi te veo en la revi");
    elements["josepfontana"] = josepfontana;
    MyElement ainaazkargorta = MyElement(this, "ainaazkargorta", "Aina", "Cognom més complicat de la FME");
    elements["ainaazkargorta"] = ainaazkargorta;
    MyElement perellorens = MyElement(this, "perellorens", "Pere Llorens", "El hada del bosque");
    elements["perellorens"] = perellorens;
    MyElement narciso = MyElement(this, "narciso", "Narciso", "\\//_");
    elements["narciso"] = narciso;
    MyElement jocdalgorismia = MyElement(this, "jocdalgorismia", "Joc d’algorísmia", "Dummy 1000 Tu 40");
    elements["jocdalgorismia"] = jocdalgorismia;
    MyElement novatorevelacio = MyElement(this, "novatorevelacio", "Novato Revelació", "Premi més injust de la FME");
    elements["novatorevelacio"] = novatorevelacio;
    MyElement edps = MyElement(this, "edps", "EDPs", "Equacions Diferencials Puto Subnormal");
    elements["edps"] = edps;
    MyElement festadenovatos = MyElement(this, "festadenovatos", "Festa de Novatos", "Pluja d’arestes");
    elements["festadenovatos"] = festadenovatos;
    MyElement festahawaiana = MyElement(this, "festahawaiana", "Festa Hawaiana", "Pluja de recus");
    elements["festahawaiana"] = festahawaiana;
    MyElement jaumefranch = MyElement(this, "jaumefranch", "Jaume Franch", "Franki");
    elements["jaumefranch"] = jaumefranch;
    MyElement festatropical = MyElement(this, "festatropical", "Festa Tropical", "aka Festa Hawaiana");
    elements["festatropical"] = festatropical;
    MyElement pibuti = MyElement(this, "pibuti", "Pi-buti", "Ara vendrem hamburgueses, que és la setmana de la dona");
    elements["pibuti"] = pibuti;
    MyElement merceolle = MyElement(this, "merceolle", "Mercè Ollé", "A sub i, j a la super k");
    elements["merceolle"] = merceolle;
    MyElement xaviercabre = MyElement(this, "xaviercabre", "Xavier Cabré", "Ens veiem l’any que ve");
    elements["xaviercabre"] = xaviercabre;
    MyElement leonsito = MyElement(this, "leonsito", "Leonsito", "Fua neeeeeen");
    elements["leonsito"] = leonsito;
    MyElement pacs = MyElement(this, "pacs", "Pacs", "A cinc minuts de Gelida");
    elements["pacs"] = pacs;
    MyElement tonto = MyElement(this, "tonto", "Tonto", "Tonto el que lo lea");
    elements["tonto"] = tonto;
    MyElement dades = MyElement(this, "dades", "Dades", "Carrera inferior a mates");
    elements["dades"] = dades;
    MyElement dissenydesamarreta = MyElement(this, "dissenydesamarreta", "Disseny de samarreta", "Existeixo i sóc única");
    elements["dissenydesamarreta"] = dissenydesamarreta;
    MyElement inu = MyElement(this, "inu", "Inu", "Iiiiiiiiinuuuuuuuuu");
    elements["inu"] = inu;
    MyElement novatades = MyElement(this, "novatades", "Novatades", "Superior a anar a fonaments cfis");
    elements["novatades"] = novatades;
    MyElement cadenaderoba = MyElement(this, "cadenaderoba", "Cadena de roba", "Algú ha vist els meus calçotets?");
    elements["cadenaderoba"] = cadenaderoba;
    MyElement fmemes00 = MyElement(this, "fmemes00", "@fmemes00", "Divertidíssim");
    elements["fmemes00"] = fmemes00;
    MyElement matematiksan0n1ms = MyElement(this, "matematiksan0n1ms", "@matematiksan0n1ms", "meh");
    elements["matematiksan0n1ms"] = matematiksan0n1ms;
    MyElement memesfme = MyElement(this, "memesfme", "@memesfme", "nah");
    elements["memesfme"] = memesfme;
    MyElement conjuntbuit = MyElement(this, "conjuntbuit", "Conjunt Buit", " ");
    elements["conjuntbuit"] = conjuntbuit;
    MyElement barja = MyElement(this, "barja", "Barja", "Teorema del punto gordo");
    elements["barja"] = barja;
    MyElement np = MyElement(this, "np", "NP", "Esta ya pal año que viene");
    elements["np"] = np;
    MyElement iaio = MyElement(this, "iaio", "Iaio", "Fuig del coronavirus");
    elements["iaio"] = iaio;
    MyElement teatrefme = MyElement(this, "teatrefme", "TeatreFME", "Prohibido suicidarse en cuarentena");
    elements["teatrefme"] = teatrefme;
    MyElement festadecarnaval = MyElement(this, "festadecarnaval", "Festa de Carnaval", "Última festa de Festes 99’");
    elements["festadecarnaval"] = festadecarnaval;
    MyElement palomo = MyElement(this, "palomo", "Palomo", "El principio del palomar");
    elements["palomo"] = palomo;
    MyElement caramotxo = MyElement(this, "caramotxo", "Caramotxo", "Caramotxoooo ooh eeh ooh");
    elements["caramotxo"] = caramotxo;
    MyElement ferranlopez = MyElement(this, "ferranlopez", "Ferran López", "Que nooo tonto, que lo he visto en un documental");
    elements["ferranlopez"] = ferranlopez;
    MyElement jofrecosta = MyElement(this, "jofrecosta", "Jofre Costa", "Gofre");
    elements["jofrecosta"] = jofrecosta;
    MyElement amandasanjuan = MyElement(this, "amandasanjuan", "Amanda", "Heavy de fort de cuqui");
    elements["amandasanjuan"] = amandasanjuan;
    MyElement lavabocfis = MyElement(this, "lavabocfis", "Lavabo CFIS", "S’hi fa de tot menys pis");
    elements["lavabocfis"] = lavabocfis;
    MyElement bikinada = MyElement(this, "bikinada", "Bikinada", "To be or not to be, that is the question");
    elements["bikinada"] = bikinada;
    MyElement festagran = MyElement(this, "festagran", "Festa Gran", "Prohibida l’entrada a telecos");
    elements["festagran"] = festagran;
    MyElement estadistics = MyElement(this, "estadistics", "Estadístics", "Carrera molt molt inferior a mates");
    elements["estadistics"] = estadistics;
    MyElement senyorgrane = MyElement(this, "senyorgrane", "Senyor Grané", "Persona més cuqui de la FME");
    elements["senyorgrane"] = senyorgrane;
    MyElement cobra = MyElement(this, "cobra", "Cobra", "Game over. Try again?");
    elements["cobra"] = cobra;
    MyElement ericvalls = MyElement(this, "ericvalls", "Eric Valls", "Pollito");
    elements["ericvalls"] = ericvalls;
    MyElement k9 = MyElement(this, "k9", "K9", "@canoutop");
    elements["k9"] = k9;
    MyElement rosa = MyElement(this, "rosa", "Rosa", "I vermell no combinen");
    elements["rosa"] = rosa;
    MyElement joc = MyElement(this, "joc", "Joc", "Si combina salseo i alcohol molt millor");
    elements["joc"] = joc;
    MyElement mus = MyElement(this, "mus", "Mus", "Arriba y abajo");
    elements["mus"] = mus;
    MyElement catan = MyElement(this, "catan", "Catan", "Et canvio una pedra per una palla");
    elements["catan"] = catan;
    MyElement escacs = MyElement(this, "escacs", "Escacs", "Jaque mate");
    elements["escacs"] = escacs;
    MyElement pingpong = MyElement(this, "pingpong", "Ping pong", "Tennis taula");
    elements["pingpong"] = pingpong;
    MyElement rouritos = MyElement(this, "rouritos", "Rouritos", "Pesaos que okupen el CFIS");
    elements["rouritos"] = rouritos;
    MyElement menjar = MyElement(this, "menjar", "Menjar", "Segona cosa més robada després del catan");
    elements["menjar"] = menjar;
    MyElement lomoqueso = MyElement(this, "lomoqueso", "Lomo queso", "Objectivament superior a bacon queso");
    elements["lomoqueso"] = lomoqueso;
    MyElement croissant = MyElement(this, "croissant", "Croissant", "Stonks");
    elements["croissant"] = croissant;
    MyElement tupper = MyElement(this, "tupper", "Tupper", "Recoged los tuppers cuando os vayáis");
    elements["tupper"] = tupper;
    MyElement temaso = MyElement(this, "temaso", "Temaso", "Esque esa gyal tiene que ser mi gambina");
    elements["temaso"] = temaso;
    MyElement volum = MyElement(this, "volum", "Volum", "OOOOGHHJ");
    elements["volum"] = volum;
    MyElement discurs = MyElement(this, "discurs", "Discurs", "Txapa");
    elements["discurs"] = discurs;
    MyElement jordibosch = MyElement(this, "jordibosch", "Jordi Bosch", "Enorme nigro");
    elements["jordibosch"] = jordibosch;
    MyElement ambulancia = MyElement(this, "ambulancia", "Ambulància", "Ni no ni no ni no ni no");
    elements["ambulancia"] = ambulancia;
    MyElement burro = MyElement(this, "burro", "Burro", "Jordi Condom");
    elements["burro"] = burro;
    MyElement pepino = MyElement(this, "pepino", "Pepino", "Albert");
    elements["pepino"] = pepino;
    MyElement biblio = MyElement(this, "biblio", "Biblio", "On vas quan vols estudiar de veritat");
    elements["biblio"] = biblio;
    MyElement marcesquerra = MyElement(this, "marcesquerra", "Marc Esquerrà", "Marc Skerranus Il Hombre Annus");
    elements["marcesquerra"] = marcesquerra;
    MyElement pikipiki = MyElement(this, "pikipiki", "Piki piki", "Ferri vs Edu Simón");
    elements["pikipiki"] = pikipiki;
    MyElement team = MyElement(this, "team", "Team", "Eiii algú vol fer classes a l’eixample?");
    elements["team"] = team;
    MyElement llops = MyElement(this, "llops", "Llops", "Piiiico pico pico pico");
    elements["llops"] = llops;
    MyElement trivial = MyElement(this, "trivial", "Trivial", "Quan encara existia...");
    elements["trivial"] = trivial;
    MyElement assemblea = MyElement(this, "assemblea", "Assemblea", "Assamblea");
    elements["assemblea"] = assemblea;
    MyElement andreuboix = MyElement(this, "andreuboix", "Andreu Boix", "Xicot de la Martina de Sant Celoni");
    elements["andreuboix"] = andreuboix;
    MyElement alexaibar = MyElement(this, "alexaibar", "Àlex Aibar", "Tonto se nace, loko");
    elements["alexaibar"] = alexaibar;
    MyElement arnauprats = MyElement(this, "arnauprats", "Arnau Prats", "Culazo");
    elements["arnauprats"] = arnauprats;
    MyElement plattrencat = MyElement(this, "plattrencat", "Plat trencat", "DEP");
    elements["plattrencat"] = plattrencat;
    MyElement bolera = MyElement(this, "bolera", "Bolera", "Passat el Parc Científic a l’esquerra");
    elements["bolera"] = bolera;
    MyElement io = MyElement(this, "io", "IO", "Assignatura de matemàtiques no impartida per matemàtics");
    elements["io"] = io;
    MyElement danivilardell = MyElement(this, "danivilardell", "Dani Vilardell", "El teclas");
    elements["danivilardell"] = danivilardell;
    MyElement baixet = MyElement(this, "baixet", "Baixet", "1.5");
    elements["baixet"] = baixet;

    recipes["alcohol-fme"] = Recipe(this, "birres1", alcohol, fme, birres);
    recipes["mates-mates"] = Recipe(this, "fme1", mates, mates, fme);
    recipes["cuqui-mates"] = Recipe(this, "novatos1", cuqui, mates, novatos);
    recipes["birres-salseo"] = Recipe(this, "ivetacosta1", birres, salseo, ivetacosta);
    recipes["drama-salseo"] = Recipe(this, "amor1", drama, salseo, amor);
    recipes["fme-salseo"] = Recipe(this, "festa1", fme, salseo, festa);
    recipes["amor-ivetacosta"] = Recipe(this, "terrassa1", amor, ivetacosta, terrassa);
    recipes["drama-ivetacosta"] = Recipe(this, "samucapellas1", drama, ivetacosta, samucapellas);
    recipes["amor-rafahhajjar"] = Recipe(this, "samucapellas2", amor, rafahhajjar, samucapellas);
    recipes["alcohol-alcohol"] = Recipe(this, "potar1", alcohol, alcohol, potar);
    recipes["fme-fme"] = Recipe(this, "upc1", fme, fme, upc);
    recipes["fme-mates"] = Recipe(this, "profe1", fme, mates, profe);
    recipes["birres-fme"] = Recipe(this, "barsanjuan1", birres, fme, barsanjuan);
    recipes["festa-salseo"] = Recipe(this, "lio1", festa, salseo, lio);
    recipes["mates-upc"] = Recipe(this, "cfis1", mates, upc, cfis);
    recipes["alcohol-festa"] = Recipe(this, "ressaca1", alcohol, festa, ressaca);
    recipes["fme-upc"] = Recipe(this, "dele1", fme, upc, dele);
    recipes["profe-salseo"] = Recipe(this, "maripaz1", profe, salseo, maripaz);
    recipes["drama-profe"] = Recipe(this, "examen1", drama, profe, examen);
    recipes["potar-terrassa"] = Recipe(this, "gabrialujas1", potar, terrassa, gabrialujas);
    recipes["novatos-terrassa"] = Recipe(this, "oriolbaeza1", novatos, terrassa, oriolbaeza);
    recipes["barsanjuan-cuqui"] = Recipe(this, "luisdelbar1", barsanjuan, cuqui, luisdelbar);
    recipes["alcohol-barsanjuan"] = Recipe(this, "sergiodelbar1", alcohol, barsanjuan, sergiodelbar);
    recipes["cfis-cuqui"] = Recipe(this, "rafahhajjar1", cfis, cuqui, rafahhajjar);
    recipes["dele-salseo"] = Recipe(this, "sortida1", dele, salseo, sortida);
    recipes["dele-festa"] = Recipe(this, "sortida2", dele, festa, sortida);
    recipes["drama-drama"] = Recipe(this, "pelea1", drama, drama, pelea);
    recipes["drama-examen"] = Recipe(this, "recu1", drama, examen, recu);
    recipes["cuqui-dele"] = Recipe(this, "dunatomas1", cuqui, dele, dunatomas);
    recipes["lio-lio"] = Recipe(this, "graf1", lio, lio, graf);
    recipes["cuqui-rafahhajjar"] = Recipe(this, "abracada1", cuqui, rafahhajjar, abracada);
    recipes["rafahhajjar-rafahhajjar"] = Recipe(this, "guapo1", rafahhajjar, rafahhajjar, guapo);
    recipes["ressaca-sortida"] = Recipe(this, "dormir1", ressaca, sortida, dormir);
    recipes["cfis-recu"] = Recipe(this, "erikferrando1", cfis, recu, erikferrando);
    recipes["mates-novatos"] = Recipe(this, "segon1", mates, novatos, segon);
    recipes["drama-pelea"] = Recipe(this, "odi1", drama, pelea, odi);
    recipes["pelea-samucapellas"] = Recipe(this, "einstein1", pelea, samucapellas, einstein);
    recipes["alcohol-samucapellas"] = Recipe(this, "einstein2", alcohol, samucapellas, einstein);
    recipes["dormir-mates"] = Recipe(this, "numerica1", dormir, mates, numerica);
    recipes["alcohol-guapo"] = Recipe(this, "tiracanyes1", alcohol, guapo, tiracanyes);
    recipes["dormir-fme"] = Recipe(this, "gespeta1", dormir, fme, gespeta);
    recipes["erikferrando-sortida"] = Recipe(this, "foratalsostre1", erikferrando, sortida, foratalsostre);
    recipes["mates-segon"] = Recipe(this, "tercer1", mates, segon, tercer);
    recipes["salseo-segon"] = Recipe(this, "brisca1", salseo, segon, brisca);
    recipes["cuqui-odi"] = Recipe(this, "borde1", cuqui, odi, borde);
    recipes["guapo-guapo"] = Recipe(this, "elegant1", guapo, guapo, elegant);
    recipes["dormir-terrassa"] = Recipe(this, "gabrialujas2", dormir, terrassa, gabrialujas);
    recipes["barsanjuan-tiracanyes"] = Recipe(this, "rubendelbar1", barsanjuan, tiracanyes, rubendelbar);
    recipes["drama-tiracanyes"] = Recipe(this, "edusimon1", drama, tiracanyes, edusimon);
    recipes["brisca-tercer"] = Recipe(this, "ivetacosta2", brisca, tercer, ivetacosta);
    recipes["secta-segon"] = Recipe(this, "laiapomar1", secta, segon, laiapomar);
    recipes["gespeta-sortida"] = Recipe(this, "frisbee1", gespeta, sortida, frisbee);
    recipes["mates-tercer"] = Recipe(this, "quart1", mates, tercer, quart);
    recipes["salseo-tercer"] = Recipe(this, "secta1", salseo, tercer, secta);
    recipes["borde-dele"] = Recipe(this, "enaitzquilez1", borde, dele, enaitzquilez);
    recipes["borde-brisca"] = Recipe(this, "olgamartinez1", borde, brisca, olgamartinez);
    recipes["gespeta-gespeta"] = Recipe(this, "porros1", gespeta, gespeta, porros);
    recipes["brisca-salseo"] = Recipe(this, "lauraarribas1", brisca, salseo, lauraarribas);
    recipes["brisca-cuqui"] = Recipe(this, "irenecusine1", brisca, cuqui, irenecusine);
    recipes["brisca-lio"] = Recipe(this, "marionasanchez1", brisca, lio, marionasanchez);
    recipes["elegant-festa"] = Recipe(this, "festadenadal1", elegant, festa, festadenadal);
    recipes["brisca-elegant"] = Recipe(this, "amaliasimon1", brisca, elegant, amaliasimon);
    recipes["edusimon-ivetacosta"] = Recipe(this, "zorra1", edusimon, ivetacosta, zorra);
    recipes["lauraarribas-novatos"] = Recipe(this, "albertgimo1", lauraarribas, novatos, albertgimo);
    recipes["frisbee-frisbee"] = Recipe(this, "esport1", frisbee, frisbee, esport);
    recipes["mates-quart"] = Recipe(this, "cinque1", mates, quart, cinque);
    recipes["cuqui-secta"] = Recipe(this, "claudiarodes1", cuqui, secta, claudiarodes);
    recipes["borde-secta"] = Recipe(this, "patricorbera1", borde, secta, patricorbera);
    recipes["novatos-porros"] = Recipe(this, "victordeblas1", novatos, porros, victordeblas);
    recipes["festa-lauraarribas"] = Recipe(this, "picatrencada1", festa, lauraarribas, picatrencada);
    recipes["porros-porros"] = Recipe(this, "perrofla1", porros, porros, perrofla);
    recipes["amor-porros"] = Recipe(this, "perrofla2", amor, porros, perrofla);
    recipes["risas-secta"] = Recipe(this, "jordicondom1", risas, secta, jordicondom);
    recipes["frisbee-risas"] = Recipe(this, "xino1", frisbee, risas, xino);
    recipes["cuqui-quart"] = Recipe(this, "gerardcontreras1", cuqui, quart, gerardcontreras);
    recipes["festadenadal-salseo"] = Recipe(this, "premi1", festadenadal, salseo, premi);
    recipes["festadenadal-risas"] = Recipe(this, "premi2", festadenadal, risas, premi);
    recipes["elegant-quart"] = Recipe(this, "davidariza1", elegant, quart, davidariza);
    recipes["cuqui-elegant"] = Recipe(this, "davidariza2", cuqui, elegant, davidariza);
    recipes["cinque-segon"] = Recipe(this, "erikferrando2", cinque, segon, erikferrando);
    recipes["esport-fme"] = Recipe(this, "cefme1", esport, fme, cefme);
    recipes["einstein-picatrencada"] = Recipe(this, "nofestes1", einstein, picatrencada, nofestes);
    recipes["amor-perrofla"] = Recipe(this, "annafelip1", amor, perrofla, annafelip);
    recipes["irenecusine-jordicondom"] = Recipe(this, "mortissim1", irenecusine, jordicondom, mortissim);
    recipes["brisca-premi"] = Recipe(this, "javilopezcontreras1", brisca, premi, javilopezcontreras);
    recipes["javilopezcontreras-pelea"] = Recipe(this, "heredia1", javilopezcontreras, pelea, heredia);
    recipes["javilopezcontreras-profe"] = Recipe(this, "roura1", javilopezcontreras, profe, roura);
    recipes["cefme-gespeta"] = Recipe(this, "pichi1", cefme, gespeta, pichi);
    recipes["erikferrando-javilopezcontreras"] = Recipe(this, "pelea2", erikferrando, javilopezcontreras, pelea);
    recipes["cuqui-profe"] = Recipe(this, "jaumemarti1", cuqui, profe, jaumemarti);
    recipes["barsanjuan-ivetacosta"] = Recipe(this, "cubatada1", barsanjuan, ivetacosta, cubatada);
    recipes["mates-roura"] = Recipe(this, "info1", mates, roura, info);
    recipes["marionasanchez-salseo"] = Recipe(this, "lamari1", marionasanchez, salseo, lamari);
    recipes["alcohol-dele"] = Recipe(this, "sortida3", alcohol, dele, sortida);
    recipes["cuqui-info"] = Recipe(this, "mariaprat1", cuqui, info, mariaprat);
    recipes["carlotacorrales-dunatomas"] = Recipe(this, "baixet1", carlotacorrales, dunatomas, baixet);
    recipes["albertjimenez-ivetacosta"] = Recipe(this, "baixet2", albertjimenez, ivetacosta, baixet);
    recipes["lauraarribas-odi"] = Recipe(this, "baixet3", lauraarribas, odi, baixet);
    recipes["baixet-ivetacosta"] = Recipe(this, "pauredon1", baixet, ivetacosta, pauredon);
    recipes["baixet-novatos"] = Recipe(this, "pauredon2", baixet, novatos, pauredon);
    recipes["alcohol-secta"] = Recipe(this, "janafarran1", alcohol, secta, janafarran);
    recipes["profe-risas"] = Recipe(this, "narciso1", profe, risas, narciso);
    recipes["examen-risas"] = Recipe(this, "recu2", examen, risas, recu);
    recipes["jocdalgorismia-secta"] = Recipe(this, "carlotagracia1", jocdalgorismia, secta, carlotagracia);
    recipes["mates-risas"] = Recipe(this, "fme2", mates, risas, fme);
    recipes["novatos-premi"] = Recipe(this, "novatorevelacio1", novatos, premi, novatorevelacio);
    recipes["novatorevelacio-tercer"] = Recipe(this, "verapujadas1", novatorevelacio, tercer, verapujadas);
    recipes["elegant-secta"] = Recipe(this, "verapujadas2", elegant, secta, verapujadas);
    recipes["novatos-salseo"] = Recipe(this, "ainaazkargorta1", novatos, salseo, ainaazkargorta);
    recipes["novatorevelacio-segon"] = Recipe(this, "danimunoz1", novatorevelacio, segon, danimunoz);
    recipes["novatorevelacio-novatos"] = Recipe(this, "josepfontana1", novatorevelacio, novatos, josepfontana);
    recipes["novatorevelacio-quart"] = Recipe(this, "xino2", novatorevelacio, quart, xino);
    recipes["drama-mates"] = Recipe(this, "edps1", drama, mates, edps);
    recipes["festa-novatos"] = Recipe(this, "festadenovatos1", festa, novatos, festadenovatos);
    recipes["festa-recu"] = Recipe(this, "festahawaiana1", festa, recu, festahawaiana);
    recipes["cuqui-festa"] = Recipe(this, "jaumefranch1", cuqui, festa, jaumefranch);
    recipes["festahawaiana-jaumefranch"] = Recipe(this, "festatropical1", festahawaiana, jaumefranch, festatropical);
    recipes["festa-gespeta"] = Recipe(this, "pibuti1", festa, gespeta, pibuti);
    recipes["porros-risas"] = Recipe(this, "victordeblas2", porros, risas, victordeblas);
    recipes["numerica-profe"] = Recipe(this, "merceolle1", numerica, profe, merceolle);
    recipes["edps-profe"] = Recipe(this, "xaviercabre1", edps, profe, xaviercabre);
    recipes["amor-amor"] = Recipe(this, "mortissim2", amor, amor, mortissim);
    recipes["brisca-pacs"] = Recipe(this, "irenecusine2", brisca, pacs, irenecusine);
    recipes["recu-recu"] = Recipe(this, "tonto1", recu, recu, tonto);
    recipes["mates-tonto"] = Recipe(this, "dades1", mates, tonto, dades);
    recipes["brisca-dades"] = Recipe(this, "luissierra1", brisca, dades, luissierra);
    recipes["brisca-risas"] = Recipe(this, "albertjimenez1", brisca, risas, albertjimenez);
    recipes["dades-secta"] = Recipe(this, "andreuhuguet1", dades, secta, andreuhuguet);
    recipes["andreuhuguet-sortida"] = Recipe(this, "leonsito1", andreuhuguet, sortida, leonsito);
    recipes["andreuhuguet-leonsito"] = Recipe(this, "pacs1", andreuhuguet, leonsito, pacs);
    recipes["elegant-pibuti"] = Recipe(this, "dissenydesamarreta1", elegant, pibuti, dissenydesamarreta);
    recipes["dele-dele"] = Recipe(this, "edupena1", dele, dele, edupena);
    recipes["cuqui-ivetacosta"] = Recipe(this, "inu1", cuqui, ivetacosta, inu);
    recipes["novatos-risas"] = Recipe(this, "novatades1", novatos, risas, novatades);
    recipes["joc-novatos"] = Recipe(this, "novatades2", joc, novatos, novatades);
    recipes["festadenovatos-salseo"] = Recipe(this, "cadenaderoba1", festadenovatos, salseo, cadenaderoba);
    recipes["gabrialujas-sortida"] = Recipe(this, "potar2", gabrialujas, sortida, potar);
    recipes["lauraarribas-risas"] = Recipe(this, "fmemes001", lauraarribas, risas, fmemes00);
    recipes["fmemes00-novatos"] = Recipe(this, "matematiksan0n1ms1", fmemes00, novatos, matematiksan0n1ms);
    recipes["fmemes00-tercer"] = Recipe(this, "memesfme1", fmemes00, tercer, memesfme);
    recipes["festa-tercer"] = Recipe(this, "conjuntbuit1", festa, tercer, conjuntbuit);
    recipes["festa-upc"] = Recipe(this, "nofestes2", festa, upc, nofestes);
    recipes["cfis-profe"] = Recipe(this, "barja1", cfis, profe, barja);
    recipes["examen-jordicivit"] = Recipe(this, "np1", examen, jordicivit, np);
    recipes["examen-ivetacosta"] = Recipe(this, "np2", examen, ivetacosta, np);
    recipes["edupena-examen"] = Recipe(this, "np3", edupena, examen, np);
    recipes["cinque-mates"] = Recipe(this, "iaio1", cinque, mates, iaio);
    recipes["dele-iaio"] = Recipe(this, "jordicivit1", dele, iaio, jordicivit);
    recipes["drama-risas"] = Recipe(this, "teatrefme1", drama, risas, teatrefme);
    recipes["cuqui-teatrefme"] = Recipe(this, "carlotacorrales1", cuqui, teatrefme, carlotacorrales);
    recipes["festa-teatrefme"] = Recipe(this, "festadecarnaval1", festa, teatrefme, festadecarnaval);
    recipes["tonto-tonto"] = Recipe(this, "palomo1", tonto, tonto, palomo);
    recipes["terrassa-tonto"] = Recipe(this, "albertjimenez2", terrassa, tonto, albertjimenez);
    recipes["palomo-segon"] = Recipe(this, "albertjimenez3", palomo, segon, albertjimenez);
    recipes["palomo-tercer"] = Recipe(this, "caramotxo1", palomo, tercer, caramotxo);
    recipes["palomo-quart"] = Recipe(this, "ferranlopez1", palomo, quart, ferranlopez);
    recipes["dormir-lavabocfis"] = Recipe(this, "jofrecosta1", dormir, lavabocfis, jofrecosta);
    recipes["cuqui-novatos"] = Recipe(this, "amandasanjuan1", cuqui, novatos, amandasanjuan);
    recipes["novatos-novatos"] = Recipe(this, "perellorens1", novatos, novatos, perellorens);
    recipes["segon-segon"] = Recipe(this, "danimunoz2", segon, segon, danimunoz);
    recipes["tercer-tercer"] = Recipe(this, "andreuhuguet2", tercer, tercer, andreuhuguet);
    recipes["quart-quart"] = Recipe(this, "jordicivit2", quart, quart, jordicivit);
    recipes["cfis-salseo"] = Recipe(this, "lavabocfis1", cfis, salseo, lavabocfis);
    recipes["lauraarribas-lavabocfis"] = Recipe(this, "picatrencada2", lauraarribas, lavabocfis, picatrencada);
    recipes["festa-picatrencada"] = Recipe(this, "pibuti2", festa, picatrencada, pibuti);
    recipes["festa-festa"] = Recipe(this, "festagran1", festa, festa, festagran);
    recipes["fme-tonto"] = Recipe(this, "estadistics1", fme, tonto, estadistics);
    recipes["cfis-iaio"] = Recipe(this, "senyorgrane1", cfis, iaio, senyorgrane);
    recipes["info-risas"] = Recipe(this, "jocdalgorismia1", info, risas, jocdalgorismia);
    recipes["amor-andreuhuguet"] = Recipe(this, "martinacolas", amor, andreuhuguet, martinacolas);
    recipes["cinque-cobra"] = Recipe(this, "ericvalls1", cinque, cobra, ericvalls);
    recipes["quart-tercer"] = Recipe(this, "k91", quart, tercer, k9);
    recipes["drama-lio"] = Recipe(this, "cobra2", drama, lio, cobra);
    recipes["secta-secta"] = Recipe(this, "rosa1", secta, secta, rosa);
    recipes["risas-risas"] = Recipe(this, "joc1", risas, risas, joc);
    recipes["barsanjuan-joc"] = Recipe(this, "mus1", barsanjuan, joc, mus);
    recipes["cfis-joc"] = Recipe(this, "catan1", cfis, joc, catan);
    recipes["dele-joc"] = Recipe(this, "escacs1", dele, joc, escacs);
    recipes["edgarmoreno-jaumefranch"] = Recipe(this, "escacs2", edgarmoreno, jaumefranch, escacs);
    recipes["dele-esport"] = Recipe(this, "pingpong1", dele, esport, pingpong);
    recipes["info-joc"] = Recipe(this, "jocdalgorismia3", info, joc, jocdalgorismia);
    recipes["cfis-roura"] = Recipe(this, "rouritos1", cfis, roura, rouritos);
    recipes["cfis-rouritos"] = Recipe(this, "menjar1", cfis, rouritos, menjar);
    recipes["luisdelbar-menjar"] = Recipe(this, "lomoqueso1", luisdelbar, menjar, lomoqueso);
    recipes["menjar-rubendelbar"] = Recipe(this, "croissant1", menjar, rubendelbar, croissant);
    recipes["barsanjuan-menjar"] = Recipe(this, "tupper1", barsanjuan, menjar, tupper);
    recipes["brisca-escacs"] = Recipe(this, "edgarmoreno1", brisca, escacs, edgarmoreno);
    recipes["andreuhuguet-samucapellas"] = Recipe(this, "temaso1", andreuhuguet, samucapellas, temaso);
    recipes["festa-temaso"] = Recipe(this, "volum1", festa, temaso, volum);
    recipes["secta-volum"] = Recipe(this, "martinacolas1", secta, volum, martinacolas);
    recipes["danimunoz-volum"] = Recipe(this, "discurs1", danimunoz, volum, discurs);
    recipes["novatos-temaso"] = Recipe(this, "danivilardell1", novatos, temaso, danivilardell);
    recipes["cinque-risas"] = Recipe(this, "jordibosch1", cinque, risas, jordibosch);
    recipes["alcohol-janafarran"] = Recipe(this, "ambulancia1", alcohol, janafarran, ambulancia);
    recipes["jordicondom-tonto"] = Recipe(this, "burro1", jordicondom, tonto, burro);
    recipes["rosa-secta"] = Recipe(this, "carlotagracia2", rosa, secta, carlotagracia);
    recipes["albertjimenez-tonto"] = Recipe(this, "pepino1", albertjimenez, tonto, pepino);
    recipes["cadenaderoba-secta"] = Recipe(this, "jordivila1", cadenaderoba, secta, jordivila);
    recipes["examen-examen"] = Recipe(this, "biblio1", examen, examen, biblio);
    recipes["biblio-brisca"] = Recipe(this, "silviagarcia1", biblio, brisca, silviagarcia);
    recipes["cinque-dormir"] = Recipe(this, "marcesquerra1", cinque, dormir, marcesquerra);
    recipes["festa-menjar"] = Recipe(this, "bikinada1", festa, menjar, bikinada);
    recipes["fme-risas"] = Recipe(this, "pikipiki1", fme, risas, pikipiki);
    recipes["iaio-pikipiki"] = Recipe(this, "team1", iaio, pikipiki, team);
    recipes["info-secta"] = Recipe(this, "maxruiz1", info, secta, maxruiz);
    recipes["festagran-gespeta"] = Recipe(this, "conjuntbuit2", festagran, gespeta, conjuntbuit);
    recipes["gespeta-joc"] = Recipe(this, "llops1", gespeta, joc, llops);
    recipes["fme-joc"] = Recipe(this, "trivial1", fme, joc, trivial);
    recipes["mariaprat-mortissim"] = Recipe(this, "javilopezcontreras2", mariaprat, mortissim, javilopezcontreras);
    recipes["javilopezcontreras-mortissim"] = Recipe(this, "mariaprat2", javilopezcontreras, mortissim, mariaprat);
    recipes["marionasanchez-mortissim"] = Recipe(this, "xino3", marionasanchez, mortissim, xino);
    recipes["mortissim-xino"] = Recipe(this, "marionasanchez2", mortissim, xino, marionasanchez);
    recipes["davidariza-mortissim"] = Recipe(this, "amaliasimon2", davidariza, mortissim, amaliasimon);
    recipes["amaliasimon-mortissim"] = Recipe(this, "davidariza2", amaliasimon, mortissim, davidariza);
    recipes["marcesquerra-mortissim"] = Recipe(this, "verapujadas2", marcesquerra, mortissim, verapujadas);
    recipes["mortissim-verapujadas"] = Recipe(this, "marcesquerra2", mortissim, verapujadas, marcesquerra);
    recipes["albertgimo-mortissim"] = Recipe(this, "lauraarribas2", albertgimo, mortissim, lauraarribas);
    recipes["lauraarribas-mortissim"] = Recipe(this, "albertgimo2", lauraarribas, mortissim, albertgimo);
    recipes["dunatomas-mortissim"] = Recipe(this, "edupena2", dunatomas, mortissim, edupena);
    recipes["edupena-mortissim"] = Recipe(this, "dunatomas2", edupena, mortissim, dunatomas);
    recipes["edgarmoreno-mortissim"] = Recipe(this, "silviagarcia2", edgarmoreno, mortissim, silviagarcia);
    recipes["mortissim-silviagarcia"] = Recipe(this, "edgarmoreno2", mortissim, silviagarcia, edgarmoreno);
    recipes["danivilardell-mortissim"] = Recipe(this, "amandasanjuan2", danivilardell, mortissim, amandasanjuan);
    recipes["amandasanjuan-mortissim"] = Recipe(this, "danivilardell2", amandasanjuan, mortissim, danivilardell);
    recipes["maxruiz-mortissim"] = Recipe(this, "carlotagracia3", maxruiz, mortissim, carlotagracia);
    recipes["carlotagracia-mortissim"] = Recipe(this, "maxruiz2", carlotagracia, mortissim, maxruiz);
    recipes["jordibosch-mortissim"] = Recipe(this, "martinacolas3", jordibosch, mortissim, martinacolas);
    recipes["martinacolas-mortissim"] = Recipe(this, "jordibosch2", martinacolas, mortissim, jordibosch);
    recipes["fme-perrofla"] = Recipe(this, "assemblea1", fme, perrofla, assemblea);
    recipes["assemblea-novatos"] = Recipe(this, "conjuntbuit3", assemblea, novatos, conjuntbuit);
    recipes["examen-np"] = Recipe(this, "recu3", examen, np, recu);
    recipes["conjuntbuit-festa"] = Recipe(this, "nofestes3", conjuntbuit, festa, nofestes);
    recipes["conjuntbuit-joc"] = Recipe(this, "catan2", conjuntbuit, joc, catan);
    recipes["iaio-pingpong"] = Recipe(this, "jordicivit3", iaio, pingpong, jordicivit);
    recipes["brisca-pingpong"] = Recipe(this, "gabrialujas3", brisca, pingpong, gabrialujas);
    recipes["carlotacorrales-k9"] = Recipe(this, "ivetacosta3", carlotacorrales, k9, ivetacosta);
    recipes["jordicivit-k9"] = Recipe(this, "jordicondom2", jordicivit, k9, jordicondom);
    recipes["k9-xino"] = Recipe(this, "andreuhuguet3", k9, xino, andreuhuguet);
    recipes["davidariza-k9"] = Recipe(this, "verapujadas2", davidariza, k9, verapujadas);
    recipes["birres-novatades"] = Recipe(this, "festadenovatos2", birres, novatades, festadenovatos);
    recipes["festa-novatades"] = Recipe(this, "festadenovatos3", festa, novatades, festadenovatos);
    recipes["estadistics-gespeta"] = Recipe(this, "cubatada2", estadistics, gespeta, cubatada);
    recipes["cinque-graf"] = Recipe(this, "festadecarnaval2", cinque, graf, festadecarnaval);
    recipes["martinacolas-novatos"] = Recipe(this, "andreuboix1", martinacolas, novatos, andreuboix);
    recipes["andreuboix-josepfontana"] = Recipe(this, "escacs2", andreuboix, josepfontana, escacs);
    recipes["birres-brisca"] = Recipe(this, "lauraarribas3", birres, brisca, lauraarribas);
    recipes["brisca-lomoqueso"] = Recipe(this, "luissierra2", brisca, lomoqueso, luissierra);
    recipes["laiapomar-olgamartinez"] = Recipe(this, "zorra2", laiapomar, olgamartinez, zorra);
    recipes["festa-lamari"] = Recipe(this, "lio2", festa, lamari, lio);
    recipes["catan-quart"] = Recipe(this, "info2", catan, quart, info);
    recipes["rubendelbar-tupper"] = Recipe(this, "odi2", rubendelbar, tupper, odi);
    recipes["enaitzquilez-sortida"] = Recipe(this, "zorra3", enaitzquilez, sortida, zorra);
    recipes["erikferrando-xino"] = Recipe(this, "plattrencat1", erikferrando, xino, plattrencat);
    recipes["annafelip-plattrencat"] = Recipe(this, "frisbee2", annafelip, plattrencat, frisbee);
    recipes["cfis-edusimon"] = Recipe(this, "terrassa2", cfis, edusimon, terrassa);
    recipes["jordicivit-novatos"] = Recipe(this, "victordeblas2", jordicivit, novatos, victordeblas);
    recipes["novatos-numerica"] = Recipe(this, "bolera1", novatos, numerica, bolera);
    recipes["joc-numerica"] = Recipe(this, "bolera2", joc, numerica, bolera);
    recipes["festahawaiana-premi"] = Recipe(this, "palomo2", festahawaiana, premi, palomo);
    recipes["cubatada-ivetacosta"] = Recipe(this, "ambulancia2", cubatada, ivetacosta, ambulancia);
    recipes["ainaazkargorta-lio"] = Recipe(this, "alexaibar1", ainaazkargorta, lio, alexaibar);
    recipes["alexaibar-amor"] = Recipe(this, "arnauprats1", alexaibar, amor, arnauprats);
    recipes["heredia-maripaz"] = Recipe(this, "io1", heredia, maripaz, io);
    recipes["claudiarodes-mortissim"] = Recipe(this, "claudiageri1", claudiarodes, mortissim, gerardcontreras);
    recipes["gerardcontreras-mortissim"] = Recipe(this, "claudiageri2", gerardcontreras, mortissim, claudiarodes);

    descoberts.add("alcohol");
    descoberts.add("mates");
    descoberts.add("cuqui");
    descoberts.add("drama");
    descoberts.add("salseo");
    descoberts.add("risas");
  }

  void cheat() {
    descoberts.clear();
    descobertsRecipes.clear();
    saveDescoberts();
    saveDescobertsRecipes();
    elements.forEach((String s, MyElement e) {
      descoberts.add(s);
    });
    recipes.forEach((String s, Recipe e) {
      descobertsRecipes.add(s);
    });
  }
}
