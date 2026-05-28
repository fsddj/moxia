import 'package:flutter/foundation.dart';

class UndoRedoController extends ChangeNotifier {
  static const int _maxHistory = 100;

  final List<String> _history = [];
  int _currentIndex = -1;
  bool _restoring = false;

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  void reset(String text) {
    _history.clear();
    _history.add(text);
    _currentIndex = 0;
    notifyListeners();
  }

  void push(String text) {
    if (_restoring) return;
    if (_currentIndex >= 0 && _history[_currentIndex] == text) return;
    _history.removeRange(_currentIndex + 1, _history.length);
    _history.add(text);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    } else {
      _currentIndex++;
    }
    notifyListeners();
  }

  String undo(String currentText) {
    if (!canUndo) return currentText;
    if (_history[_currentIndex] != currentText) {
      _history[_currentIndex] = currentText;
    }
    _restoring = true;
    _currentIndex--;
    final result = _history[_currentIndex];
    notifyListeners();
    return result;
  }

  String redo(String currentText) {
    if (!canRedo) return currentText;
    if (_history[_currentIndex] != currentText) {
      _history[_currentIndex] = currentText;
    }
    _restoring = true;
    _currentIndex++;
    final result = _history[_currentIndex];
    notifyListeners();
    return result;
  }

  void endRestore() {
    _restoring = false;
  }
}
