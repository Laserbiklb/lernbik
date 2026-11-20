import 'package:material_ui/material_ui.dart';

/// Laserbik: always dark, article colors glow like laser beams.
abstract final class L {
  static const bg = Color(0xFF0A0C11);
  static const panel = Color(0xFF141822);
  static const panel2 = Color(0xFF161B27);
  static const navBg = Color(0xFF10131A);
  static const line = Color(0xFF252B38);
  static const line2 = Color(0xFF3A4152);
  static const ink = Color(0xFFEEF2FA);
  static const ink2 = Color(0xFFC3CAD8);
  static const muted = Color(0xFF8A94A8);
  static const der = Color(0xFF3D8BFF);
  static const derSoft = Color(0xFF6FA8FF);
  static const die = Color(0xFFFF3355);
  static const das = Color(0xFF22E08A);
  static const sign = Color(0xFFFFD21F);
  static const fire = Color(0xFFFFB347);
  static const me = Color(0xFF1E2433);

  static const head = 'Rajdhani';
  static const body = 'Inter';

  static Color art(String a) => a == 'der'
      ? der
      : a == 'die'
      ? die
      : a == 'das'
      ? das
      : muted;

  static List<BoxShadow> glow(Color c, [double r = 16, double o = .45]) => [
    BoxShadow(
      color: c.withValues(alpha: o),
      blurRadius: r,
    ),
  ];

  static TextStyle h(double size, [Color c = ink]) => TextStyle(fontFamily: head, fontWeight: FontWeight.w700, fontSize: size, color: c, height: 1.1);
  static TextStyle t(double size, {Color c = ink, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontFamily: body, fontSize: size, color: c, fontWeight: w);
  static TextStyle b(double size, [Color c = ink]) => t(size, c: c, w: FontWeight.w600);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: L.der,
    brightness: Brightness.dark,
  ).copyWith(surface: L.bg, primary: L.der, error: L.die, onSurface: L.ink, onSurfaceVariant: L.muted, surfaceContainerHighest: L.panel);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: L.bg,
    fontFamily: L.body,
    canvasColor: L.bg,
    dividerColor: L.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: L.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: L.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: L.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: L.der, width: 2),
      ),
      hintStyle: L.t(15, c: L.muted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: L.panel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: L.panel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: true,
      dragHandleColor: Color(0xFF4A5266),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: L.panel2,
      contentTextStyle: L.t(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: L.line2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: L.der)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : L.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? L.das : L.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: L.das),
  );
}

/// Three glowing bars: der / die / das.
class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) {
    Widget bar(Color c) => Container(
      width: size * .27,
      height: size,
      margin: EdgeInsets.only(right: size * .09),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(size * .09), boxShadow: L.glow(c, 10, .8)),
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [bar(L.der), bar(L.die), bar(L.das)]);
  }
}

/// A dark card with a thin border; optional glow in an accent color.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final double glow;
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero, this.accent, this.color, this.radius = 14, this.onTap, this.glow = 0});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: color ?? L.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent?.withValues(alpha: .6) ?? L.line),
        boxShadow: accent != null && glow > 0 ? L.glow(accent!, glow, .35) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return box;
  }
}

/// Rows inside a Panel, separated by thin lines.
class Rows extends StatelessWidget {
  final List<Widget> children;
  const Rows(this.children, {super.key});
  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(const Divider(height: 1, thickness: 1, color: L.line, indent: 14, endIndent: 14));
      out.add(children[i]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final Color color;
  const SectionTitle(this.text, {super.key, this.trailing, this.color = L.muted});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 2),
    child: Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: L.h(15, color).copyWith(letterSpacing: 1.8))),
        ?trailing,
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const Pill(this.text, {super.key, this.color = L.muted, this.filled = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .6)),
      ),
      child: Text(text, style: L.b(12, filled ? L.bg : (color == L.muted ? L.ink2 : color))),
    );
    return onTap == null
        ? p
        : Semantics(
            button: true,
            label: text,
            onTap: onTap,
            excludeSemantics: true,
            child: InkWell(borderRadius: BorderRadius.circular(99), onTap: onTap, child: p),
          );
  }
}

/// The big glowing call-to-action.
class GlowButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final Color? textColor;
  final double size;
  const GlowButton(this.text, {super.key, this.color = L.die, this.onTap, this.textColor, this.size = 17});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: text,
      onTap: onTap,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(color: on ? color : L.line, borderRadius: BorderRadius.circular(12), boxShadow: on ? L.glow(color, 14, .55) : null),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: L.h(size, on ? (textColor ?? Colors.white) : L.muted).copyWith(letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined, tinted secondary button.
class GhostButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final IconData? icon;
  const GhostButton(this.text, {super.key, this.color = L.der, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? L.muted : color;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: text,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: c.withValues(alpha: .1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.withValues(alpha: .6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: c), const SizedBox(width: 6)],
                Flexible(
                  child: Text(text, textAlign: TextAlign.center, style: L.b(13, c == L.muted ? L.ink2 : c)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small segmented switch (A1 | A2, languages …).
class Seg<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final Color color;
  const Seg({super.key, required this.items, required this.value, required this.onChanged, this.color = L.der});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: L.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: L.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (v, label) in items)
          GestureDetector(
            onTap: () => onChanged(v),
            child: Semantics(
              button: true,
              selected: v == value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: v == value ? color : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: v == value ? L.glow(color, 10, .6) : null,
                ),
                child: Text(label, style: L.b(13, v == value ? (color == L.das ? L.bg : Colors.white) : L.muted)),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Thin progress bar.
class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double width;
  final double height;
  const Bar(this.value, {super.key, this.color = L.das, this.width = 40, this.height = 5});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: L.line, borderRadius: BorderRadius.circular(99)),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: value.clamp(0, 1).toDouble(),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99), boxShadow: value > 0 ? L.glow(color, 6, .8) : null),
      ),
    ),
  );
}

/// Screen header: logo or back arrow + title.
class Header extends StatelessWidget {
  final String title;
  final bool back;
  final List<Widget> actions;
  const Header(this.title, {super.key, this.back = false, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        if (back)
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.chevron_left, size: 30, color: L.muted),
            onPressed: () => Navigator.maybePop(context),
          )
        else ...[
          const Logo(),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: L.h(title.length > 18 ? 21 : 26)),
        ),
        const Spacer(),
        ...actions,
      ],
    ),
  );
}

/// Standard scrolling page body with the screen padding.
class LPage extends StatelessWidget {
  final List<Widget> children;
  final double bottom;
  const LPage({super.key, required this.children, this.bottom = 24});
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
      children: [for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c)],
    ),
  );
}

/// A screen pushed on top of the tabs (rule, dictionary, ranking …).
class SubPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  const SubPage({super.key, required this.title, required this.children, this.actions = const []});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: LPage(
      children: [
        Header(title, back: true, actions: actions),
        ...children,
      ],
    ),
  );
}
