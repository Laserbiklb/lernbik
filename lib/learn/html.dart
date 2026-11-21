import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Renders the small HTML of rule explanations: p, ul/li, table, b, i, s, br, small, div.
class _N {
  final String tag;
  final List<_N> kids = [];
  final String text;
  _N(this.tag, [this.text = '']);
}

_N _parse(String html) {
  final root = _N('root');
  final stack = [root];
  final re = RegExp(r'<(/?)([a-zA-Z0-9]+)[^>]*?(/?)>|([^<]+)');
  for (final m in re.allMatches(html)) {
    if (m.group(4) != null) {
      stack.last.kids.add(_N('#', _ent(m.group(4)!)));
      continue;
    }
    final close = m.group(1) == '/', tag = m.group(2)!.toLowerCase();
    if (tag == 'br') {
      stack.last.kids.add(_N('br'));
      continue;
    }
    if (close) {
      for (var i = stack.length - 1; i > 0; i--) {
        if (stack[i].tag == tag) {
          stack.removeRange(i, stack.length);
          break;
        }
      }
    } else {
      final n = _N(tag);
      stack.last.kids.add(n);
      if (m.group(3) != '/') stack.add(n);
    }
  }
  return root;
}

String _ent(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

const _blocks = {'p', 'ul', 'ol', 'table', 'div', 'tr', 'li', 'h3', 'h4'};

class RuleHtml extends StatelessWidget {
  final String html;
  final double size;

  /// Words to colour wherever they stand (e.g. how well each part of a rule is mastered).
  final Map<String, Color> marks;
  const RuleHtml(this.html, {super.key, this.size = 14.5, this.marks = const {}});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _blocksOf(_parse(html).kids));

  List<Widget> _blocksOf(List<_N> nodes) {
    final out = <Widget>[];
    var inline = <_N>[];
    void flush() {
      if (inline.any((n) => n.tag != '#' || n.text.trim().isNotEmpty)) out.add(_para(inline));
      inline = [];
    }

    for (final n in nodes) {
      if (_blocks.contains(n.tag)) {
        flush();
        out.add(_block(n));
      } else {
        inline.add(n);
      }
    }
    flush();
    return out;
  }

  Widget _para(List<_N> ns) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(TextSpan(children: ns.map((n) => _span(n, const TextStyle())).toList()), style: L.t(size).copyWith(height: 1.45)),
  );

  Widget _block(_N n) {
    switch (n.tag) {
      case 'p':
      case 'h3':
      case 'h4':
        return _para(n.kids);
      case 'ul':
      case 'ol':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final li in n.kids.where((k) => k.tag == 'li'))
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(color: L.der.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
                  child: Text.rich(
                    TextSpan(children: li.kids.map((k) => _span(k, const TextStyle())).toList()),
                    style: L.t(size).copyWith(height: 1.4),
                  ),
                ),
            ],
          ),
        );
      case 'table':
        return _table(n);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _blocksOf(n.kids));
    }
  }

  Widget _table(_N t) {
    final rows = <_N>[];
    void collect(_N n) {
      for (final k in n.kids) {
        if (k.tag == 'tr') {
          rows.add(k);
        } else if (k.tag != '#') {
          collect(k);
        }
      }
    }

    collect(t);
    if (rows.isEmpty) return const SizedBox.shrink();
    final cols = rows.map((r) => r.kids.where((c) => c.tag == 'td' || c.tag == 'th').length).fold(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(horizontalInside: BorderSide(color: L.line.withValues(alpha: .9))),
          children: [
            for (final r in rows)
              TableRow(
                children: [
                  for (var i = 0; i < cols; i++)
                    () {
                      final cells = r.kids.where((c) => c.tag == 'td' || c.tag == 'th').toList();
                      if (i >= cells.length) return const SizedBox.shrink();
                      final c = cells[i];
                      final th = c.tag == 'th';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text.rich(
                          TextSpan(children: c.kids.map((k) => _span(k, const TextStyle())).toList()),
                          style: th ? L.b(size - 2, L.muted) : L.t(size - .5),
                        ),
                      );
                    }(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  InlineSpan _span(_N n, TextStyle st) {
    switch (n.tag) {
      case '#':
        return _marked(n.text, st);
      case 'br':
        return TextSpan(text: '\n', style: st);
      case 'b':
      case 'strong':
        return TextSpan(
          children: n.kids.map((k) => _span(k, st.copyWith(fontWeight: FontWeight.w700, color: L.das))).toList(),
        );
      case 'i':
      case 'em':
        return TextSpan(
          children: n.kids.map((k) => _span(k, st.copyWith(fontStyle: FontStyle.italic, color: L.ink2))).toList(),
        );
      case 's':
        return TextSpan(
          children: n.kids.map((k) => _span(k, st.copyWith(decoration: TextDecoration.lineThrough, color: L.die))).toList(),
        );
      case 'small':
        return TextSpan(
          children: n.kids.map((k) => _span(k, st.copyWith(fontSize: size - 2.5, color: L.muted))).toList(),
        );
      default:
        return TextSpan(children: n.kids.map((k) => _span(k, st)).toList());
    }
  }
}

extension on RuleHtml {
  /// Plain text with the [marks] words coloured (longest first, whole words only).
  InlineSpan _marked(String text, TextStyle st) {
    if (marks.isEmpty) return TextSpan(text: text, style: st);
    final ws = marks.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final re = RegExp(
      '(?<![A-Za-zÄÖÜäöüß])(${ws.map(RegExp.escape).join('|')})(?![A-Za-zÄÖÜäöüß])',
      caseSensitive: false,
    );
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > at) out.add(TextSpan(text: text.substring(at, m.start), style: st));
      final key = ws.firstWhere((w) => w.toLowerCase() == m.group(1)!.toLowerCase());
      final c = marks[key]!;
      out.add(
        TextSpan(
          text: m.group(1),
          style: st.copyWith(color: c, fontWeight: FontWeight.w700, backgroundColor: c.withValues(alpha: .14)),
        ),
      );
      at = m.end;
    }
    if (at < text.length) out.add(TextSpan(text: text.substring(at), style: st));
    return TextSpan(children: out);
  }
}

/// Inline HTML (b, i, mark, em, br, s, small) as text spans, for task prompts and "why" lines.
InlineSpan htmlSpan(String html, {double size = 15, Color color = L.ink, bool head = false}) {
  final r = RuleHtml('', size: size);
  final root = _parse(html.replaceAll(RegExp(r'</?(p|div|span)[^>]*>'), ''));
  return TextSpan(
    children: root.kids.map((n) => r._spanM(n, const TextStyle())).toList(),
    style: L.t(size, c: color),
  );
}

extension on RuleHtml {
  InlineSpan _spanM(_N n, TextStyle st) {
    if (n.tag == 'mark') {
      return TextSpan(
        children: n.kids
            .map(
              (k) =>
                  _spanM(k, st.copyWith(color: L.sign, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: L.sign)),
            )
            .toList(),
      );
    }
    if (n.tag == 'em') return TextSpan(children: n.kids.map((k) => _spanM(k, st.copyWith(fontStyle: FontStyle.italic))).toList());
    if (n.kids.isEmpty || n.tag == '#' || n.tag == 'br') return _span(n, st);
    return switch (n.tag) {
      'b' || 'strong' => TextSpan(
        children: n.kids.map((k) => _spanM(k, st.copyWith(fontWeight: FontWeight.w700, color: L.das))).toList(),
      ),
      'i' => TextSpan(
        children: n.kids.map((k) => _spanM(k, st.copyWith(fontStyle: FontStyle.italic, color: L.ink2))).toList(),
      ),
      's' => TextSpan(
        children: n.kids.map((k) => _spanM(k, st.copyWith(decoration: TextDecoration.lineThrough, color: L.die))).toList(),
      ),
      'small' => TextSpan(children: n.kids.map((k) => _spanM(k, st.copyWith(color: L.muted))).toList()),
      _ => TextSpan(children: n.kids.map((k) => _spanM(k, st)).toList()),
    };
  }
}
