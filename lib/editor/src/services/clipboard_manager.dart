import 'package:flutter/services.dart';
import 'package:parchment_delta/parchment_delta.dart';

/// Encapsulates clipboard data
///
/// One of the properties should be non-null or null should be returned
/// from [PlumeCustomClipboardGetData].
/// When pasting data in editor, [delta] has precedence over [plainText].
class PlumeClipboardData {
  final String? plainText;
  final Delta? delta;

  PlumeClipboardData({this.plainText, this.delta})
      : assert(plainText != null || delta != null);

  bool get hasDelta => delta != null;

  bool get hasPlainText => plainText != null;

  bool get isEmpty => !hasPlainText && !hasDelta;
}

/// An abstract class for getting and setting data to clipboard
abstract class ClipboardManager {
  const ClipboardManager();

  Future<void> setData(PlumeClipboardData data);

  Future<PlumeClipboardData?> getData();
}

/// A [ClipboardManager] which only handles reading and setting
/// of [PlumeClipboardData.plainText] and used by default in editor.
class PlainTextClipboardManager extends ClipboardManager {
  const PlainTextClipboardManager();

  @override
  Future<void> setData(PlumeClipboardData data) async {
    if (data.hasPlainText) {
      await Clipboard.setData(ClipboardData(text: data.plainText!));
    }
  }

  @override
  Future<PlumeClipboardData?> getData() =>
      Clipboard.getData(Clipboard.kTextPlain).then((data) => data?.text != null
          ? PlumeClipboardData(plainText: data!.text!)
          : null);
}

/// Used by [PlumeCustomClipboardManager] to get clipboard data.
///
/// Null should be returned in case clipboard has no data
/// or data is invalid and both [PlumeClipboardData.plainText]
/// and [PlumeClipboardData.delta] are null.
typedef PlumeCustomClipboardGetData = Future<PlumeClipboardData?>
    Function();

/// Used by [PlumeCustomClipboardManager] to set clipboard data.
typedef PlumeCustomClipboardSetData = Future<void> Function(
    PlumeClipboardData data);

/// A [ClipboardManager] which delegates getting and setting data to user and
/// can be used to have rich clipboard.
final class PlumeCustomClipboardManager extends ClipboardManager {
  final PlumeCustomClipboardGetData _getData;
  final PlumeCustomClipboardSetData _setData;

  const PlumeCustomClipboardManager({
    required PlumeCustomClipboardGetData getData,
    required PlumeCustomClipboardSetData setData,
  })  : _getData = getData,
        _setData = setData;

  @override
  Future<void> setData(PlumeClipboardData data) => _setData(data);

  @override
  Future<PlumeClipboardData?> getData() => _getData();
}
