import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const OrbitApp());

const bg = Color(0xFF0A0D14);
const surface = Color(0xFF121826);
const line = Color(0xFF243049);
const accent = Color(0xFFFF7A3D);
const ice = Color(0xFF8FD3FF);
const mute = Color(0xFF97A3BD);

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit Atlas',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: accent, secondary: ice, surface: surface),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: accent.withOpacity(0.25),
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  static const titles = ['SPACEX', 'PLANETS', 'CREWS', 'TIMELINE'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ORBIT ATLAS  /  ${titles[index]}')),
      body: IndexedStack(
        index: index,
        children: const [HomePage(), PlanetsPage(), CrewPage(), TimelinePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.rocket_launch_outlined), label: 'SpaceX'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Planets'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Crews'),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Timeline'),
        ],
      ),
    );
  }
}

// ---------- Shared widgets ----------
class Box extends StatelessWidget {
  final Widget child;
  const Box({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }
}

// Photos come from Wikipedia at runtime (REST summary API), so no image files are bundled.
final Map<String, Future<String?>> _imgCache = {};

Future<String?> wikiImage(String title) => _imgCache.putIfAbsent(title, () async {
      try {
        final r = await http.get(Uri.parse(
            'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}'));
        if (r.statusCode != 200) return null;
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        return (j['thumbnail']?['source']) as String?;
      } catch (_) {
        return null;
      }
    });

class Wiki extends StatelessWidget {
  final String title;
  final double height;
  const Wiki(this.title, this.height, {super.key});

  Widget fill(Widget child) => Container(color: line, child: Center(child: child));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FutureBuilder<String?>(
          future: wikiImage(title),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return fill(const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final url = snap.data;
            if (url == null) return fill(const Icon(Icons.image_not_supported_outlined, color: mute));
            return Image.network(
              url,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => fill(const Icon(Icons.broken_image_outlined, color: mute)),
            );
          },
        ),
      ),
    );
  }
}

class Item extends StatelessWidget {
  final String title, sub, text;
  final String? wiki;
  const Item(this.title, this.sub, this.text, {this.wiki, super.key});

  @override
  Widget build(BuildContext context) {
    return Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wiki != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Wiki(wiki!, 200)),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: ice, fontSize: 13)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: mute, height: 1.45)),
        ],
      ),
    );
  }
}

class Fact extends StatelessWidget {
  final String text;
  final String? wiki;
  const Fact(this.text, {this.wiki, super.key});

  @override
  Widget build(BuildContext context) {
    return Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wiki != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Wiki(wiki!, 170)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.auto_awesome, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
          ]),
        ],
      ),
    );
  }
}

Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
    );

// ---------- Page 1: SpaceX ----------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget stat(String big, String small) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
            Text(small, style: const TextStyle(color: mute, fontSize: 12)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Making life multiplanetary',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 12),
        const Text(
          'SpaceX was founded by Elon Musk in 2002 in Hawthorne, California. Its goal is to cut the cost of reaching space by reusing rockets, and eventually to carry people to Mars.',
          style: TextStyle(color: mute, height: 1.5),
        ),
        const SizedBox(height: 16),
        Row(children: [stat('2002', 'Founded'), stat('2008', 'Falcon 1 orbit')]),
        Row(children: [stat('2015', 'First landing'), stat('2020', 'Crewed Dragon')]),
        heading('Vehicles'),
        const Item('Falcon 9', 'Reusable two-stage rocket',
            'The workhorse. Its first stage lands and flies again, launching satellites, cargo and crews.',
            wiki: 'Falcon_9'),
        const Item('Falcon Heavy', 'Three-core heavy lifter',
            'Debuted in 2018 by sending a Tesla Roadster toward Mars orbit.',
            wiki: 'Falcon_Heavy'),
        const Item('Dragon 2', 'Crew and cargo capsule',
            'Carries astronauts to the International Space Station and on private orbital missions.',
            wiki: 'SpaceX_Dragon_2'),
        const Item('Starship', 'Fully reusable super heavy system',
            'The largest rocket ever built, designed for the Moon, Mars and large payloads.',
            wiki: 'SpaceX_Starship'),
        const Item('Starlink', 'Satellite internet',
            'A large constellation in low Earth orbit giving broadband to remote areas.',
            wiki: 'Starlink'),
        heading('Did you know?'),
        const Fact(
            'A Tesla Roadster with a mannequin called Starman in a spacesuit was launched on the first Falcon Heavy in 2018. It still orbits the Sun.',
            wiki: "Elon_Musk's_Tesla_Roadster"),
        const Fact('Falcon 9 first stages have been reused more than 20 times each, which cut the cost of launching.'),
        const Fact('Landing a rocket upright on a drone ship at sea is something no one had done before 2016.'),
        const Fact('Starship stacked with its Super Heavy booster is about 120 meters tall, taller than the Statue of Liberty on its pedestal.'),
      ],
    );
  }
}

// ---------- Page 2: Planets ----------
class Planet {
  final String name, text, fun, wiki;
  final Color color;
  final List<List<String>> facts;
  const Planet(this.name, this.color, this.text, this.fun, this.wiki, this.facts);
}

const planets = [
  Planet('Mercury', Color(0xFF9A8F86), 'Smallest planet, closest to the Sun.',
      'Despite being closest to the Sun, it is not the hottest planet.', 'Mercury_(planet)',
      [['Diameter', '4,879 km'], ['Day', '59 Earth days'], ['Year', '88 days'], ['Moons', '0']]),
  Planet('Venus', Color(0xFFE0B872), 'Hottest planet, with a thick carbon dioxide atmosphere.',
      'A day on Venus is longer than its year.', 'Venus',
      [['Diameter', '12,104 km'], ['Day', '243 Earth days'], ['Year', '225 days'], ['Moons', '0']]),
  Planet('Earth', Color(0xFF3F8FD8), 'The only known world with life.',
      'About 71% of the surface is covered with water.', 'Earth',
      [['Diameter', '12,742 km'], ['Day', '24 hours'], ['Year', '365 days'], ['Moons', '1']]),
  Planet('Mars', Color(0xFFC8532F), 'A cold desert world and the long-term target for a SpaceX city.',
      'Olympus Mons on Mars is the tallest volcano in the solar system, about 22 km high.', 'Mars',
      [['Diameter', '6,779 km'], ['Day', '24.6 hours'], ['Year', '687 days'], ['Moons', '2']]),
  Planet('Jupiter', Color(0xFFD3A574), 'Largest planet, a gas giant with the Great Red Spot storm.',
      'The Great Red Spot is a storm wider than Earth.', 'Jupiter',
      [['Diameter', '139,820 km'], ['Day', '10 hours'], ['Year', '11.9 Earth years'], ['Moons', '95 or more']]),
  Planet('Saturn', Color(0xFFE6D19A), 'Famous for its bright rings of ice and rock.',
      'Saturn is less dense than water, so it would float in a big enough bath.', 'Saturn',
      [['Diameter', '116,460 km'], ['Day', '10.7 hours'], ['Year', '29.5 Earth years'], ['Moons', '140 or more']]),
  Planet('Uranus', Color(0xFF9FE0E6), 'An ice giant tilted on its side.',
      'It spins on its side, with a tilt of about 98 degrees.', 'Uranus',
      [['Diameter', '50,724 km'], ['Day', '17 hours'], ['Year', '84 Earth years'], ['Moons', '28 or more']]),
  Planet('Neptune', Color(0xFF4A62D8), 'Windy ice giant, the farthest planet from the Sun.',
      'Winds on Neptune can pass 2,000 km/h.', 'Neptune',
      [['Diameter', '49,244 km'], ['Day', '16 hours'], ['Year', '165 Earth years'], ['Moons', '16 or more']]),
];

class PlanetsPage extends StatefulWidget {
  const PlanetsPage({super.key});

  @override
  State<PlanetsPage> createState() => _PlanetsPageState();
}

class _PlanetsPageState extends State<PlanetsPage> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  int sel = 3;

  @override
  void initState() {
    super.initState();
    // value * 86400 = seconds of animation time, runs for a day without looping
    c = AnimationController(vsync: this, duration: const Duration(days: 1))..forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void tapAt(Offset p, Size s) {
    final t = c.value * 86400;
    double best = 30;
    int? hit;
    for (var i = 0; i < planets.length; i++) {
      final d = (SolarPainter.pos(i, s, t) - p).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit != null) setState(() => sel = hit!);
  }

  @override
  Widget build(BuildContext context) {
    final p = planets[sel];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tap a planet in orbit', style: TextStyle(color: mute)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, cons) {
          final s = Size(cons.maxWidth, cons.maxWidth);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTapDown: (d) => tapAt(d.localPosition, s),
              child: Container(
                color: const Color(0xFF070A10),
                child: CustomPaint(size: s, painter: SolarPainter(c, sel)),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: planets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(planets[i].name),
              selected: i == sel,
              selectedColor: accent.withOpacity(0.3),
              backgroundColor: surface,
              side: const BorderSide(color: line),
              onSelected: (_) => setState(() => sel = i),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(painter: SpherePainter(c, p)),
          ),
        ),
        Text(p.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(p.text, style: const TextStyle(color: mute, height: 1.45)),
        const SizedBox(height: 16),
        Box(
          child: Column(
            children: [
              for (final f in p.facts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f[0], style: const TextStyle(color: mute)),
                      Text(f[1], style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Fact(p.fun, wiki: p.wiki),
      ],
    );
  }
}

// Animated solar system: planets orbit the Sun, stars twinkle.
class SolarPainter extends CustomPainter {
  final Animation<double> c;
  final int sel;
  SolarPainter(this.c, this.sel) : super(repaint: c);

  static const periods = [10.0, 15.0, 20.0, 30.0, 60.0, 100.0, 200.0, 300.0];
  static const radii = [4.0, 6.0, 6.5, 5.0, 12.0, 10.5, 8.0, 8.0];

  static double orbitR(int i, Size s) => (s.shortestSide / 2 - 16) * (0.16 + 0.84 * i / 7);

  static Offset pos(int i, Size s, double t) {
    final a = t * 2 * pi / periods[i] + i * 0.9;
    final r = orbitR(i, s);
    return Offset(s.width / 2 + r * cos(a), s.height / 2 + r * sin(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = c.value * 86400;
    final ctr = Offset(size.width / 2, size.height / 2);

    final rnd = Random(7);
    for (var k = 0; k < 70; k++) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 1.5 + k));
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 0.8,
        Paint()..color = Colors.white.withOpacity(tw * 0.8),
      );
    }

    final orbit = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < planets.length; i++) {
      canvas.drawCircle(ctr, orbitR(i, size), orbit);
    }

    canvas.drawCircle(
      ctr,
      26,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE08A), accent, Color(0x00FF7A3D)],
        ).createShader(Rect.fromCircle(center: ctr, radius: 26)),
    );
    canvas.drawCircle(ctr, 11, Paint()..color = const Color(0xFFFFD27A));

    for (var i = 0; i < planets.length; i++) {
      final o = pos(i, size, t);
      final r = radii[i];
      if (planets[i].name == 'Saturn') {
        canvas.drawOval(
          Rect.fromCenter(center: o, width: r * 3.2, height: r * 0.9),
          Paint()
            ..color = const Color(0xFFD9C48A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      canvas.drawCircle(o, r, Paint()..color = planets[i].color);
      canvas.drawCircle(o.translate(-r * 0.3, -r * 0.3), r * 0.35,
          Paint()..color = Colors.white.withOpacity(0.25));
      if (i == sel) {
        canvas.drawCircle(
          o,
          r + 6,
          Paint()
            ..color = ice
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        final tp = TextPainter(
          text: TextSpan(text: planets[i].name, style: const TextStyle(color: Colors.white, fontSize: 11)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, o.translate(-tp.width / 2, r + 9));
      }
    }
  }

  @override
  bool shouldRepaint(SolarPainter old) => old.sel != sel;
}

// Large rotating planet: surface patches drift across a shaded sphere.
class SpherePainter extends CustomPainter {
  final Animation<double> c;
  final Planet p;
  SpherePainter(this.c, this.p) : super(repaint: c);

  @override
  void paint(Canvas canvas, Size size) {
    final t = c.value * 86400;
    final ctr = Offset(size.width / 2, size.height / 2);
    final R = size.shortestSide / 2 * (p.name == 'Saturn' ? 0.62 : 0.8);
    final ringRect = Rect.fromCenter(center: Offset.zero, width: R * 2.7, height: R * 0.75);
    final ringPaint = Paint()
      ..color = const Color(0xFFD9C48A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.18;
    final isSaturn = p.name == 'Saturn';

    if (isSaturn) {
      canvas.save();
      canvas.translate(ctr.dx, ctr.dy);
      canvas.rotate(-0.35);
      canvas.drawOval(ringRect, ringPaint);
      canvas.restore();
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: R)));
    canvas.drawCircle(ctr, R, Paint()..color = p.color);

    for (var b = 0; b < 6; b++) {
      canvas.drawRect(
        Rect.fromLTWH(ctr.dx - R, ctr.dy - R + b * R / 3, R * 2, R / 6),
        Paint()..color = (b.isEven ? Colors.white : Colors.black).withOpacity(0.07),
      );
    }
    for (var k = 0; k < 14; k++) {
      final lon = k * 2 * pi / 14 + t * 0.2;
      final vis = cos(lon);
      if (vis <= 0) continue;
      final lat = (((k * 37) % 11) / 11 - 0.5) * 1.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ctr.dx + R * sin(lon), ctr.dy + R * lat),
          width: R * 0.55 * vis,
          height: R * (0.12 + (k % 3) * 0.04),
        ),
        Paint()..color = (k.isEven ? Colors.white : Colors.black).withOpacity(0.16 * vis),
      );
    }

    final rect = Rect.fromCircle(center: ctr, radius: R);
    canvas.drawCircle(
      ctr,
      R,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          stops: const [0.35, 1.0],
        ).createShader(rect),
    );
    canvas.restore();

    if (isSaturn) {
      canvas.save();
      canvas.translate(ctr.dx, ctr.dy);
      canvas.rotate(-0.35);
      canvas.drawArc(ringRect, 0, pi, false, ringPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SpherePainter old) => old.p != p;
}

// ---------- Page 3: Crews ----------
class CrewPage extends StatelessWidget {
  const CrewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Item('Yuri Gagarin', 'USSR, 1961',
            'First human in space. He orbited Earth once aboard Vostok 1 on April 12, 1961.',
            wiki: 'Yuri_Gagarin'),
        Item('Valentina Tereshkova', 'USSR, 1963',
            'First woman in space, flying solo on Vostok 6 for almost three days.',
            wiki: 'Valentina_Tereshkova'),
        Item('Alexei Leonov', 'USSR, 1965',
            'Made the first spacewalk, lasting about 12 minutes outside Voskhod 2.',
            wiki: 'Alexei_Leonov'),
        Item('Neil Armstrong', 'USA, 1969',
            'Commander of Apollo 11 and first person to walk on the Moon.',
            wiki: 'Neil_Armstrong'),
        Item('Bob Behnken and Doug Hurley', 'NASA, 2020',
            'Flew Crew Dragon Demo-2, the first crewed orbital launch from US soil in nine years.',
            wiki: 'SpaceX_Crew_Dragon_Demo-2'),
        Item('Inspiration4', '2021',
            'The first all-civilian crew to orbit Earth, flying a Dragon for three days.',
            wiki: 'Inspiration4'),
        Item('Roscosmos cosmonauts', 'ISS crew exchange',
            'Russian cosmonauts and NASA astronauts swap seats on Soyuz and Dragon so both countries keep a presence on the ISS.',
            wiki: 'Roscosmos'),
        Fact('Gagarin’s whole flight lasted 108 minutes, and he did not land inside the capsule: he ejected and parachuted down separately.'),
        Fact('During his spacewalk, Leonov’s suit swelled in the vacuum and he had to release air to fit back through the hatch.'),
        Fact('Tereshkova was a textile worker and amateur parachutist before she became a cosmonaut.'),
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Photos load from Wikipedia and Wikimedia Commons.',
              style: TextStyle(color: mute, fontSize: 12)),
        ),
      ],
    );
  }
}

// ---------- Page 4: Timeline ----------
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  static const events = [
    ['2008', 'Falcon 1 becomes the first privately built liquid-fuel rocket to reach orbit.'],
    ['2010', 'Dragon is the first commercial spacecraft recovered from orbit.'],
    ['2012', 'Dragon docks with the ISS, a first for a private company.'],
    ['2015', 'A Falcon 9 first stage lands upright after launching to orbit.'],
    ['2019', 'Starlink launches begin.'],
    ['2020', 'Crew Dragon carries NASA astronauts to the ISS.'],
    ['2023', 'First integrated Starship flight test.'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final e in events)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(width: 2, color: line)),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e[0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(e[1], style: const TextStyle(color: mute, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        heading('What comes next'),
        const Text(
          'Orbital refueling, lunar landings under NASA’s Artemis program, and uncrewed cargo flights to Mars. Dates change often, so check spacex.com for current plans.',
          style: TextStyle(color: mute, height: 1.45),
        ),
      ],
    );
  }
}
