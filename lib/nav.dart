import 'package:flutter/foundation.dart';

/// Which tab is open and which chapter "Lernen" shows.
class NavState extends ChangeNotifier {
  int tab = 0;
  String? lv; // chapter picked by the learner; null = the course chapter
  int? n;

  void go(int t) {
    tab = t;
    notifyListeners();
  }

  void openChapter(String level, int no) {
    lv = level;
    n = no;
    tab = 1;
    notifyListeners();
  }

  void backToCourse() {
    lv = null;
    n = null;
    notifyListeners();
  }
}

final nav = NavState();
