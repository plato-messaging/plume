import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plume/document_model/document_model.dart';

import 'editor.dart';

class PlumeShortcuts extends Shortcuts {
  PlumeShortcuts({super.key, required super.child})
      : super(
          shortcuts: _shortcuts,
        );

  static Map<ShortcutActivator, Intent> get _shortcuts {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _defaultShortcuts;
      case TargetPlatform.fuchsia:
        return _defaultShortcuts;
      case TargetPlatform.iOS:
        return _macShortcuts;
      case TargetPlatform.linux:
        return _defaultShortcuts;
      case TargetPlatform.macOS:
        return _macShortcuts;
      case TargetPlatform.windows:
        return _defaultShortcuts;
    }
  }

  static const Map<ShortcutActivator, Intent> _defaultShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyB, control: true):
        ToggleBoldStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyI, control: true):
        ToggleItalicStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true):
        ToggleUnderlineStyleIntent(),
    SingleActivator(LogicalKeyboardKey.tab, control: false):
        AddIndentationIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true):
        RemoveIndentationIntent()
  };

  static const Map<ShortcutActivator, Intent> _macShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyB, meta: true):
        ToggleBoldStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyI, meta: true):
        ToggleItalicStyleIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, meta: true):
        ToggleUnderlineStyleIntent(),
    SingleActivator(LogicalKeyboardKey.tab, control: false):
        AddIndentationIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true):
        RemoveIndentationIntent()
  };
}

class ToggleBoldStyleIntent extends Intent {
  const ToggleBoldStyleIntent();
}

class ToggleItalicStyleIntent extends Intent {
  const ToggleItalicStyleIntent();
}

class ToggleUnderlineStyleIntent extends Intent {
  const ToggleUnderlineStyleIntent();
}

class AddIndentationIntent extends Intent {
  const AddIndentationIntent();
}

class RemoveIndentationIntent extends Intent {
  const RemoveIndentationIntent();
}

class PlumeActions extends Actions {
  PlumeActions({
    super.key,
    required super.child,
  }) : super(
          actions: _shortcutsActions,
        );

  static final Map<Type, Action<Intent>> _shortcutsActions =
      <Type, Action<Intent>>{
    ToggleBoldStyleIntent: _ToggleInlineStyleAction(Attribute.bold),
    ToggleItalicStyleIntent:
        _ToggleInlineStyleAction(Attribute.italic),
    ToggleUnderlineStyleIntent:
        _ToggleInlineStyleAction(Attribute.underline),
    AddIndentationIntent: _AddRemoveIndentationAction(addIndentation: true),
    RemoveIndentationIntent: _AddRemoveIndentationAction(addIndentation: false)
  };
}

class _AddRemoveIndentationAction extends ContextAction<Intent> {
  final bool addIndentation;

  _AddRemoveIndentationAction({required this.addIndentation});

  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    final editorState = context!.findAncestorStateOfType<RawEditorState>()!;
    final style = editorState.controller.getSelectionStyle();
    final indentLevel = style.get(Attribute.indent)?.value ?? 0;
    if (indentLevel == 0 && !addIndentation) {
      return null;
    }
    if (indentLevel == 1 && !addIndentation) {
      editorState.controller.formatSelection(Attribute.indent.unset);
    } else {
      editorState.controller.formatSelection(Attribute.indent
          .withLevel(indentLevel + (addIndentation ? 1 : -1)));
    }
    return null;
  }
}

class _ToggleInlineStyleAction extends ContextAction<Intent> {
  final Attribute attribute;

  _ToggleInlineStyleAction(this.attribute);

  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    final editorState = context!.findAncestorStateOfType<RawEditorState>()!;
    final style = editorState.controller.getSelectionStyle();
    final actualAttr =
        style.containsSame(attribute) ? attribute.unset : attribute;
    editorState.controller.formatSelection(actualAttr);
    return null;
  }
}
