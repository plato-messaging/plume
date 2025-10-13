import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlumePressedKeys extends ChangeNotifier {
  static PlumePressedKeys of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_PlumePressedKeysAccess>();
    return widget!.pressedKeys;
  }

  bool _metaPressed = false;
  bool _controlPressed = false;

  /// Whether meta key is currently pressed.
  bool get metaPressed => _metaPressed;

  /// Whether control key is currently pressed.
  bool get controlPressed => _controlPressed;

  void _updatePressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final meta = pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
    final control = pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
    if (_metaPressed != meta || _controlPressed != control) {
      _metaPressed = meta;
      _controlPressed = control;
      notifyListeners();
    }
  }
}

class PlumeKeyboardListener extends StatefulWidget {
  final Widget child;
  const PlumeKeyboardListener({super.key, required this.child});

  @override
  PlumeKeyboardListenerState createState() =>
      PlumeKeyboardListenerState();
}

class PlumeKeyboardListenerState extends State<PlumeKeyboardListener> {
  final PlumePressedKeys _pressedKeys = PlumePressedKeys();

  bool _keyEvent(KeyEvent event) {
    _pressedKeys
        ._updatePressedKeys(HardwareKeyboard.instance.logicalKeysPressed);
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_keyEvent);
    _pressedKeys
        ._updatePressedKeys(HardwareKeyboard.instance.logicalKeysPressed);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyEvent);
    _pressedKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PlumePressedKeysAccess(
      pressedKeys: _pressedKeys,
      child: widget.child,
    );
  }
}

class _PlumePressedKeysAccess extends InheritedWidget {
  final PlumePressedKeys pressedKeys;
  const _PlumePressedKeysAccess({
    required this.pressedKeys,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _PlumePressedKeysAccess oldWidget) {
    return oldWidget.pressedKeys != pressedKeys;
  }
}
