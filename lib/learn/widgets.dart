import 'package:material_ui/material_ui.dart';

import '../i18n.dart';
import '../ui.dart' show openTranslate;
import '../fx.dart';
import '../theme.dart';

enum OptState { idle, sel, good, bad, dim }

/// Opens Google Translate from German into the phone's language.
void openGoogle(String text) => openTranslate(text);

/// An answer button with a colored laser bar on the left.
class OptionTile extends StatelessWidget {
  final String label;
  final Color color;
  final OptState state;
  final VoidCallback? onTap;
  final int? num;
  final bool big;
  const OptionTile({super.key, required this.label, this.color = L.der, this.state = OptState.idle, this.onTap, this.num, this.big = false});
  @override
  Widget build(BuildContext context) {
    final c = switch (state) {
      OptState.good => L.das,
      OptState.bad => L.die,
      OptState.sel => L.der,
      _ => color,
    };
    final hot = state == OptState.good || state == OptState.bad || state == OptState.sel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shake(
        active: state == OptState.bad,
        child: Pop(
          active: state == OptState.good,
          child: Pressable(
            enabled: onTap != null,
            child: AnimatedOpacity(
              duration: Fx.d(250),
              opacity: state == OptState.dim ? .45 : 1,
              child: AnimatedContainer(
                duration: Fx.d(200),
                decoration: BoxDecoration(
                  color: hot ? c.withValues(alpha: .16) : L.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hot ? c : L.line, width: hot ? 2 : 1),
                  boxShadow: hot ? L.glow(c, 18, .55) : null,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: big ? 14 : 13),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: big ? 32 : 24,
                            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3), boxShadow: L.glow(c, 8, .9)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(label, style: big ? L.h(30, c) : L.b(15))),
                          if (state == OptState.good) Text('✓', style: L.h(24, L.das)),
                          if (state == OptState.bad) Text('✕', style: L.h(22, L.die)),
                          if (num != null && state == OptState.idle) Text('$num', style: L.t(12, c: L.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The prompt: a big line and a small hint under it.
class Ask extends StatelessWidget {
  final String main, sub;
  final Color? subColor;
  const Ask(this.main, this.sub, {super.key, this.subColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(main, style: L.h(30)),
        const SizedBox(height: 4),
        Text(sub, style: L.b(13, subColor ?? L.muted)),
      ],
    ),
  );
}

/// Tappable word/letter chips (for letters and word order).
class TokenLine extends StatelessWidget {
  final List<String> tokens;
  final void Function(int)? onTap;
  final bool placeholder;
  final List<OptState>? states;

  /// Single letters: big square tiles that are easy to hit.
  final bool letters;

  /// Word pieces (syllables): bigger tiles than normal tokens.
  final bool chunks;
  const TokenLine({super.key, required this.tokens, this.onTap, this.placeholder = false, this.states, this.letters = false, this.chunks = false});
  @override
  Widget build(BuildContext context) {
    final w = Wrap(
      spacing: letters ? 7 : 8,
      runSpacing: letters ? 7 : 8,
      children: [
        for (var i = 0; i < tokens.length; i++)
          Material(
            color: _bg(i),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: _border(i)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap == null ? null : () => onTap!(i),
              child: letters
                  ? SizedBox(
                      width: 52,
                      height: 56,
                      child: Center(child: Text(tokens[i] == ' ' ? '␣' : tokens[i], style: L.b(26))),
                    )
                  : chunks
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 60, minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Center(widthFactor: 1, child: Text(tokens[i], style: L.b(24))),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      child: Text(tokens[i] == ' ' ? '␣' : tokens[i], style: L.b(17)),
                    ),
            ),
          ),
      ],
    );
    if (!placeholder) return w;
    return Container(
      constraints: BoxConstraints(minHeight: letters ? 74 : 58),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: L.line2),
        color: L.bg,
      ),
      child: w,
    );
  }

  Color _bg(int i) => switch (states?[i]) {
    OptState.bad => L.die.withValues(alpha: .2),
    OptState.good => L.das.withValues(alpha: .2),
    _ => L.panel,
  };
  Color _border(int i) => switch (states?[i]) {
    OptState.bad => L.die,
    OptState.good => L.das,
    _ => L.line2,
  };
}

/// Text field with ä ö ü ß buttons.
class TypeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool locked;
  final VoidCallback onSubmit;
  final String hint;
  const TypeBox({super.key, required this.controller, required this.focus, required this.locked, required this.onSubmit, this.hint = ''});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: controller,
        focusNode: focus,
        readOnly: locked,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        style: L.h(26),
        decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        onSubmitted: (_) => onSubmit(),
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final c in ['ä', 'ö', 'ü', 'ß'])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: L.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: L.line2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: locked
                        ? null
                        : () {
                            final t = controller.text, s = controller.selection;
                            final at = s.isValid ? s.start : t.length, end = s.isValid ? s.end : t.length;
                            controller.text = t.replaceRange(at, end, c);
                            controller.selection = TextSelection.collapsed(offset: at + 1);
                            focus.requestFocus();
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: Text(c, style: L.b(17))),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

/// Right / wrong line with "next", listen and translate.
class Verdict extends StatelessWidget {
  final bool ok;
  final InlineSpan text;
  final String lang;
  final VoidCallback? onNext, onSay;
  final String? onTranslate;
  final String? why;
  const Verdict({super.key, required this.ok, required this.text, required this.lang, this.onNext, this.onSay, this.onTranslate, this.why});
  @override
  Widget build(BuildContext context) {
    final c = ok ? L.das : L.die;
    return Appear(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: ok ? '${l3(lang, 'Richtig!', 'Верно!', 'Correct!')} ' : '${l3(lang, 'Leider nicht.', 'Мимо.', 'Not quite.')} ',
                    style: L.b(15, c),
                  ),
                  text,
                ],
              ),
              style: L.t(15),
            ),
            if (why != null && why!.isNotEmpty) ...[const SizedBox(height: 6), Text(why!, style: L.t(13, c: L.ink2))],
            if (onNext != null || onSay != null || onTranslate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onNext != null)
                    Expanded(
                      child: GlowButton(l3(lang, 'Weiter', 'Дальше', 'Next'), color: ok ? L.das : L.die, textColor: ok ? L.bg : null, size: 16, onTap: onNext),
                    ),
                  if (onSay != null)
                    IconButton(
                      tooltip: l3(lang, 'Anhören', 'Послушать', 'Listen'),
                      onPressed: onSay,
                      icon: const Icon(Icons.volume_up_outlined, color: L.der),
                    ),
                  if (onTranslate != null)
                    IconButton(
                      tooltip: l3(lang, 'Übersetzen', 'Перевести', 'Translate'),
                      onPressed: () => openGoogle(onTranslate!),
                      icon: const Icon(Icons.translate, color: L.muted, size: 20),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PairCell extends StatelessWidget {
  final Widget child;
  final OptState state;
  final VoidCallback? onTap;
  const PairCell({super.key, required this.child, this.state = OptState.idle, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = switch (state) {
      OptState.good => L.das,
      OptState.bad => L.die,
      OptState.sel => L.der,
      _ => L.line,
    };
    final hot = state != OptState.idle;
    return Shake(
      active: state == OptState.bad,
      child: Pop(
        active: state == OptState.good,
        child: AnimatedOpacity(
          duration: Fx.d(300),
          opacity: state == OptState.good ? .5 : 1,
          child: AnimatedContainer(
            duration: Fx.d(200),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: hot ? c.withValues(alpha: .15) : L.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hot ? c : L.line, width: state == OptState.sel ? 2 : 1),
              boxShadow: state == OptState.sel || state == OptState.bad ? L.glow(c, 14, .6) : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five dots: the level of a word (box 0 … 5).
class LevelDots extends StatelessWidget {
  final int b;
  const LevelDots(this.b, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$b / 5',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          AnimatedContainer(
            duration: Fx.d(400 + i * 120),
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(color: b >= i ? L.das : L.line, shape: BoxShape.circle, boxShadow: b >= i ? L.glow(L.das, 5, .8) : null),
          ),
      ],
    ),
  );
}
