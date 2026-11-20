import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Neon animations. All of them can be switched off in Ich ([Fx.on]); then everything is instant.
abstract final class Fx {
  static bool on = true;

  /// A duration that becomes zero when animations are off.
  static Duration d(int ms) => on ? Duration(milliseconds: ms) : Duration.zero;
}

/// Shakes sideways once when [active] turns true (a wrong answer).
class Shake extends StatefulWidget {
  final bool active;
  final Widget child;
  const Shake({super.key, required this.active, required this.child});
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && Fx.on) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    child: widget.child,
    builder: (_, child) => Transform.translate(offset: Offset(sin(c.value * pi * 6) * 9 * (1 - c.value), 0), child: child),
  );
}

/// Pops (grows and settles) once when [active] turns true (a right answer, a tick).
class Pop extends StatefulWidget {
  final bool active;
  final Widget child;
  final double scale;
  const Pop({super.key, required this.active, required this.child, this.scale = 1.07});
  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(Pop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && Fx.on) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    child: widget.child,
    builder: (_, child) {
      final t = c.value;
      final s = 1 + (widget.scale - 1) * sin(t * pi) * (1 - t * .3);
      return Transform.scale(scale: s, child: child);
    },
  );
}

/// Shrinks a little while pressed, like a real button.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const Pressable({super.key, required this.child, this.enabled = true});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;
  void _set(bool v) {
    if (down != v && mounted) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !Fx.on) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(scale: down ? .96 : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
    );
  }
}

/// Fades and slides in when first shown (feedback boxes, list items).
class Appear extends StatelessWidget {
  final Widget child;
  final int delay;
  final double dy;
  const Appear({super.key, required this.child, this.delay = 0, this.dy = 14});
  @override
  Widget build(BuildContext context) {
    if (!Fx.on) return child;
    final total = 320 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      child: child,
      builder: (_, v, child) {
        final t = Curves.easeOutCubic.transform(((v * total - delay) / 320).clamp(0, 1).toDouble());
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * dy), child: child),
        );
      },
    );
  }
}

/// A number that counts up to its value (XP, words).
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String prefix, suffix;
  const CountUp(this.value, {super.key, required this.style, this.prefix = '', this.suffix = ''});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: Fx.d(900 + min(value, 60) * 10),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('$prefix${v.round()}$suffix', style: style),
  );
}

/// A soft neon glow that breathes (the current chapter, the streak flame).
class Breathe extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  const Breathe({super.key, required this.child, required this.color, this.radius = 14});
  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (Fx.on) c.repeat(reverse: true);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Fx.on) return widget.child;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .12 + .22 * c.value),
              blurRadius: 10 + 12 * c.value,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Neon confetti over the whole screen (end of a round, a rule learned).
void confetti(BuildContext context, {int count = 80}) {
  if (!Fx.on) return;
  final o = Overlay.maybeOf(context, rootOverlay: true);
  if (o == null) return;
  late OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _Confetti(count: count, onEnd: () => e.remove()),
    ),
  );
  o.insert(e);
}

class _Confetti extends StatefulWidget {
  final int count;
  final VoidCallback onEnd;
  const _Confetti({required this.count, required this.onEnd});
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _P {
  final double x, vx, vy, size, spin, delay;
  final Color color;
  final bool bar;
  _P(Random r)
    : x = r.nextDouble(),
      vx = (r.nextDouble() - .5) * .5,
      vy = -.9 - r.nextDouble() * .7,
      size = 4 + r.nextDouble() * 5,
      spin = (r.nextDouble() - .5) * 14,
      delay = r.nextDouble() * .15,
      color = [L.der, L.die, L.das, L.sign][r.nextInt(4)],
      bar = r.nextBool();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final ps = [for (var i = 0; i < widget.count; i++) _P(Random(i * 7919 + DateTime.now().millisecond))];

  @override
  void initState() {
    super.initState();
    c.forward().whenComplete(widget.onEnd);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(ps, c.value)),
  );
}

class _ConfettiPainter extends CustomPainter {
  final List<_P> ps;
  final double t;
  _ConfettiPainter(this.ps, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final tt = ((t - p.delay) / (1 - p.delay)).clamp(0, 1).toDouble();
      if (tt <= 0) continue;
      // Shot up from the bottom, then falling with gravity.
      final x = (p.x + p.vx * tt) * size.width;
      final y = size.height * (1.02 + p.vy * tt * 1.5 + 1.6 * tt * tt);
      final a = (1 - max(0, tt - .7) / .3).clamp(0, 1).toDouble();
      final paint = Paint()..color = p.color.withValues(alpha: a);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * tt);
      if (p.bar) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size * 2.2, height: p.size * .8), const Radius.circular(2)),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * .55, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Screen changes: fade, a slight rise and zoom. Instant when animations are off.
class NeonPageTransitions extends PageTransitionsBuilder {
  const NeonPageTransitions();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (!Fx.on) return child;
    final a = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(a),
        child: ScaleTransition(scale: Tween(begin: .98, end: 1.0).animate(a), child: child),
      ),
    );
  }
}
