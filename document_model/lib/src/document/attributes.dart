import 'dart:math' as math;

import 'package:collection/collection.dart';

/// Scope of a style attribute, defines context in which an attribute can be
/// applied.
enum AttributeScope {
  /// Inline-scoped attributes are applicable to all characters within a line.
  ///
  /// Inline attributes cannot be applied to the line itself.
  inline,

  /// Line-scoped attributes are only applicable to a line of text as a whole.
  ///
  /// Line attributes do not have any effect on any character within the line.
  line,
}

/// Interface for objects which provide access to an attribute key.
///
/// Implemented by [Attribute] and [AttributeBuilder].
abstract class AttributeKey<T> {
  /// Unique key of this attribute.
  String get key;
}

/// Builder for style attributes.
///
/// Useful in scenarios when an attribute value is not known upfront, for
/// instance, link attribute.
///
/// See also:
///   * [LinkAttributeBuilder]
///   * [BlockAttributeBuilder]
///   * [HeadingAttributeBuilder]
///   * [IndentAttributeBuilder
///   * [BackgroundColorAttributeBuilder]
///   * [DirectionAttributeBuilder]
abstract class AttributeBuilder<T> implements AttributeKey<T> {
  const AttributeBuilder._(this.key, this.scope);

  @override
  final String key;
  final AttributeScope scope;

  Attribute<T> get unset => Attribute<T>._(key, scope, null);

  Attribute<T> withValue(T? value) => Attribute<T>._(key, scope, value);
}

/// Style attribute applicable to a segment of a [Document].
///
/// All supported attributes are available via static fields on this class.
/// Here is an example of applying styles to a document:
///
///     void makeItPretty(Document document) {
///       // Format 5 characters at position 0 as bold
///       document.format(0, 5, Attribute.bold);
///       // Similarly for italic
///       document.format(0, 5, Attribute.italic);
///       // Format first line as a heading (h1)
///       // Note that there is no need to specify character range of the whole
///       // line. Simply set index position to anywhere within the line and
///       // length to 0.
///       document.format(0, 0, Attribute.h1);
///     }
///
/// List of supported attributes:
///
///   * [Attribute.bold]
///   * [Attribute.italic]
///   * [Attribute.underline]
///   * [Attribute.strikethrough]
///   * [Attribute.inlineCode]
///   * [Attribute.link]
///   * [Attribute.heading]
///   * [Attribute.backgroundColor]
///   * [Attribute.checked]
///   * [Attribute.block]
///   * [Attribute.direction]
///   * [Attribute.alignment]
///   * [Attribute.indent]
class Attribute<T> implements AttributeBuilder<T> {
  static final Map<String, AttributeBuilder> _registry = {
    Attribute.bold.key: Attribute.bold,
    Attribute.italic.key: Attribute.italic,
    Attribute.underline.key: Attribute.underline,
    Attribute.strikethrough.key: Attribute.strikethrough,
    Attribute.inlineCode.key: Attribute.inlineCode,
    Attribute.link.key: Attribute.link,
    Attribute.heading.key: Attribute.heading,
    Attribute.foregroundColor.key: Attribute.foregroundColor,
    Attribute.backgroundColor.key: Attribute.backgroundColor,
    Attribute.checked.key: Attribute.checked,
    Attribute.block.key: Attribute.block,
    Attribute.direction.key: Attribute.direction,
    Attribute.alignment.key: Attribute.alignment,
    Attribute.indent.key: Attribute.indent,
  };

  // Inline attributes

  /// Bold style attribute.
  static const bold = _BoldAttribute();

  /// Italic style attribute.
  static const italic = _ItalicAttribute();

  /// Underline style attribute.
  static const underline = _UnderlineAttribute();

  /// Strikethrough style attribute.
  static const strikethrough = _StrikethroughAttribute();

  /// Inline code style attribute.
  static const inlineCode = _InlineCodeAttribute();

  /// Foreground color attribute.
  static const foregroundColor = ForegroundColorAttributeBuilder._();

  /// Background color attribute.
  static const backgroundColor = BackgroundColorAttributeBuilder._();

  /// Link style attribute.
  // ignore: const_eval_throws_exception
  static const link = LinkAttributeBuilder._();

  // Line attributes

  /// Heading style attribute.
  // ignore: const_eval_throws_exception
  static const heading = HeadingAttributeBuilder._();

  /// Alias for [Attribute.heading.level1].
  static Attribute<int> get h1 => heading.level1;

  /// Alias for [Attribute.heading.level2].
  static Attribute<int> get h2 => heading.level2;

  /// Alias for [Attribute.heading.level3].
  static Attribute<int> get h3 => heading.level3;

  /// Alias for [Attribute.heading.level4].
  static Attribute<int> get h4 => heading.level4;

  /// Alias for [Attribute.heading.level5].
  static Attribute<int> get h5 => heading.level5;

  /// Alias for [Attribute.heading.level5].
  static Attribute<int> get h6 => heading.level6;

  /// Indent attribute
  static const indent = IndentAttributeBuilder._();

  /// Applies checked style to a line of text in checklist block.
  static const checked = _CheckedAttribute();

  /// Block attribute
  // ignore: const_eval_throws_exception
  static const block = BlockAttributeBuilder._();

  /// Alias for [Attribute.block.bulletList].
  static Attribute<String> get ul => block.bulletList;

  /// Alias for [Attribute.block.numberList].
  static Attribute<String> get ol => block.numberList;

  /// Alias for [Attribute.block.checkList].
  static Attribute<String> get cl => block.checkList;

  /// Alias for [Attribute.block.quote].
  static Attribute<String> get bq => block.quote;

  /// Alias for [Attribute.block.code].
  static Attribute<String> get code => block.code;

  /// Direction attribute
  static const direction = DirectionAttributeBuilder._();

  /// Alias for [Attribute.direction.rtl].
  static Attribute<String> get rtl => direction.rtl;

  /// Alignment attribute
  static const alignment = AlignmentAttributeBuilder._();

  /// Alias for [Attribute.alignment.unset]
  static Attribute<String> get left => alignment.unset;

  /// Alias for [Attribute.alignment.right]
  static Attribute<String> get right => alignment.right;

  /// Alias for [Attribute.alignment.center]
  static Attribute<String> get center => alignment.center;

  /// Alias for [Attribute.alignment.justify]
  static Attribute<String> get justify => alignment.justify;

  static Attribute _fromKeyValue(String key, dynamic value) {
    if (!_registry.containsKey(key)) {
      throw ArgumentError.value(
        key,
        'No attribute with key "$key" registered.',
      );
    }
    final builder = _registry[key]!;
    return builder.withValue(value);
  }

  const Attribute._(this.key, this.scope, this.value);

  /// Unique key of this attribute.
  @override
  final String key;

  /// Scope of this attribute.
  @override
  final AttributeScope scope;

  /// Value of this attribute.
  ///
  /// If value is `null` then this attribute represents a transient action
  /// of removing associated style and is never persisted in a resulting
  /// document.
  ///
  /// See also [unset], [Style.merge] and [Style.put]
  /// for details.
  final T? value;

  /// Returns special "unset" version of this attribute.
  ///
  /// Unset attribute's [value] is always `null`.
  ///
  /// When composed into a rich text document, unset attributes remove
  /// associated style.
  @override
  Attribute<T> get unset => Attribute<T>._(key, scope, null);

  /// Returns `true` if this attribute is an unset attribute.
  bool get isUnset => value == null;

  /// Returns `true` if this is an inline-scoped attribute.
  bool get isInline => scope == AttributeScope.inline;

  @override
  Attribute<T> withValue(T? value) => Attribute<T>._(key, scope, value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Attribute<T>) return false;
    return key == other.key && scope == other.scope && value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, scope, value);

  @override
  String toString() => '$key: $value';

  Map<String, dynamic> toJson() => <String, dynamic>{key: value};
}

/// Collection of style attributes.
class Style {
  Style._(this._data);

  final Map<String, Attribute> _data;

  static Style fromJson(Map<String, dynamic>? data) {
    if (data == null) return Style();

    final result = data.map((String key, dynamic value) {
      var attr = Attribute._fromKeyValue(key, value);
      return MapEntry<String, Attribute>(key, attr);
    });
    return Style._(result);
  }

  Style() : _data = <String, Attribute>{};

  /// Returns `true` if this attribute set is empty.
  bool get isEmpty => _data.isEmpty;

  /// Returns `true` if this attribute set is note empty.
  bool get isNotEmpty => _data.isNotEmpty;

  /// Returns `true` if this style is not empty and contains only inline-scoped
  /// attributes and is not empty.
  bool get isInline => isNotEmpty && values.every((item) => item.isInline);

  /// Checks that this style has only one attribute, and returns that attribute.
  Attribute get single => _data.values.single;

  /// Returns line-scoped attributes
  Iterable<Attribute> get lineAttributes =>
      values.where((e) => e.scope == AttributeScope.line);

  /// Returns inline-scoped attributes
  Iterable<Attribute> get inlineAttributes =>
      values.where((e) => e.scope == AttributeScope.inline);

  /// Returns `true` if attribute with [key] is present in this set.
  ///
  /// Only checks for presence of specified [key] regardless of the associated
  /// value.
  ///
  /// To test if this set contains an attribute with specific value consider
  /// using [containsSame].
  bool contains(AttributeKey key) => _data.containsKey(key.key);

  /// Returns `true` if this set contains attribute with the same value as
  /// [attribute].
  bool containsSame(Attribute attribute) {
    return get<dynamic>(attribute) == attribute;
  }

  /// Returns value of specified attribute [key] in this set.
  T? value<T>(AttributeKey<T> key) => get(key)?.value;

  /// Returns [Attribute] from this set by specified [key].
  Attribute<T>? get<T>(AttributeKey<T> key) => _data[key.key] as Attribute<T>?;

  /// Returns collection of all attribute keys in this set.
  Iterable<String> get keys => _data.keys;

  /// Returns collection of all attributes in this set.
  Iterable<Attribute> get values => _data.values;

  /// Puts [attribute] into this attribute set and returns result as a new set.
  Style put(Attribute attribute) {
    final result = Map<String, Attribute>.from(_data);
    result[attribute.key] = attribute;
    return Style._(result);
  }

  /// Puts [attributes] into this attribute set and returns result as a new set.
  Style putAll(Iterable<Attribute> attributes) {
    final result = Map<String, Attribute>.from(_data);
    for (final attr in attributes) {
      result[attr.key] = attr;
    }
    return Style._(result);
  }

  /// Merges this attribute set with [attribute] and returns result as a new
  /// attribute set.
  ///
  /// Performs compaction if [attribute] is an "unset" value, e.g. removes
  /// corresponding attribute from this set completely.
  ///
  /// See also [put] method which does not perform compaction and allows
  /// constructing styles with "unset" values.
  Style merge(Attribute attribute) {
    final merged = Map<String, Attribute>.from(_data);
    if (attribute.isUnset) {
      merged.remove(attribute.key);
    } else {
      merged[attribute.key] = attribute;
    }
    return Style._(merged);
  }

  /// Merges all attributes from [other] into this style and returns result
  /// as a new instance of [Style].
  Style mergeAll(Style other) {
    var result = Style._(_data);
    for (var value in other.values) {
      result = result.merge(value);
    }
    return result;
  }

  /// Removes [attributes] from this style and returns new instance of
  /// [Style] containing result.
  Style removeAll(Iterable<Attribute> attributes) {
    final merged = Map<String, Attribute>.from(_data);
    attributes.map((item) => item.key).forEach(merged.remove);
    return Style._(merged);
  }

  /// Returns JSON-serializable representation of this style.
  Map<String, dynamic>? toJson() => _data.isEmpty
      ? null
      : _data.map<String, dynamic>(
          (String _, Attribute value) =>
              MapEntry<String, dynamic>(value.key, value.value),
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Style) return false;
    final eq = const MapEquality<String, Attribute>();
    return eq.equals(_data, other._data);
  }

  @override
  int get hashCode {
    final hashes = _data.entries.map(
      (entry) => Object.hash(entry.key, entry.value),
    );
    return Object.hashAll(hashes);
  }

  @override
  String toString() => "{${_data.values.join(', ')}}";
}

/// Applies bold style to a text segment.
class _BoldAttribute extends Attribute<bool> {
  const _BoldAttribute() : super._('b', AttributeScope.inline, true);
}

/// Applies italic style to a text segment.
class _ItalicAttribute extends Attribute<bool> {
  const _ItalicAttribute() : super._('i', AttributeScope.inline, true);
}

/// Applies underline style to a text segment.
class _UnderlineAttribute extends Attribute<bool> {
  const _UnderlineAttribute() : super._('u', AttributeScope.inline, true);
}

/// Applies strikethrough style to a text segment.
class _StrikethroughAttribute extends Attribute<bool> {
  const _StrikethroughAttribute() : super._('s', AttributeScope.inline, true);
}

/// Applies code style to a text segment.
class _InlineCodeAttribute extends Attribute<bool> {
  const _InlineCodeAttribute() : super._('c', AttributeScope.inline, true);
}

/// Builder for color-based style attributes.
///
/// Useful in scenarios when a color attribute value is not known upfront.
///
/// See also:
///   * [BackgroundColorAttributeBuilder]
///   * [ForegroundColorAttributeBuilder]
abstract class ColorAttributeBuilder extends AttributeBuilder<int> {
  const ColorAttributeBuilder._(super.key, super.scope) : super._();

  /// Creates the color attribute with [color] value
  Attribute<int> withColor(int color);
}

/// Builder for background color value.
/// Color is interpreted from the lower 32 bits of an [int].
///
/// The bits are interpreted as follows:
///
/// * Bits 24-31 are the alpha value.
/// * Bits 16-23 are the red value.
/// * Bits 8-15 are the green value.
/// * Bits 0-7 are the blue value.
/// (see [Color] documentation for more details
///
/// There is no need to use this class directly, consider using
/// [Attribute.backgroundColor] instead.
class BackgroundColorAttributeBuilder extends ColorAttributeBuilder {
  static const _bgColor = 'bg';
  static const _transparentColor = 0;

  const BackgroundColorAttributeBuilder._()
    : super._(_bgColor, AttributeScope.inline);

  /// Creates foreground color attribute with [color] value
  ///
  /// If color is transparent, [unset] is returned
  @override
  Attribute<int> withColor(int color) {
    if (color == _transparentColor) {
      return unset;
    }
    return Attribute<int>._(key, scope, color);
  }
}

/// Builder for text color value.
/// Color is interpreted from the lower 32 bits of an [int].
///
/// The bits are interpreted as follows:
///
/// * Bits 24-31 are the alpha value.
/// * Bits 16-23 are the red value.
/// * Bits 8-15 are the green value.
/// * Bits 0-7 are the blue value.
/// (see [Color] documentation for more details
///
/// There is no need to use this class directly, consider using
/// [Attribute.foregroundColor] instead.
class ForegroundColorAttributeBuilder extends ColorAttributeBuilder {
  static const _fgColor = 'fg';
  static const _black = 0x00000000;

  const ForegroundColorAttributeBuilder._()
    : super._(_fgColor, AttributeScope.inline);

  /// Creates foreground color attribute with [color] value
  ///
  /// If color is black, [unset] is returned
  @override
  Attribute<int> withColor(int color) {
    if (color == _black) {
      return unset;
    }
    return Attribute._(key, scope, color);
  }
}

/// Builder for link attribute values.
///
/// There is no need to use this class directly, consider using
/// [Attribute.link] instead.
class LinkAttributeBuilder extends AttributeBuilder<String> {
  static const _kLink = 'a';

  const LinkAttributeBuilder._() : super._(_kLink, AttributeScope.inline);

  /// Creates a link attribute with specified link [value].
  Attribute<String> fromString(String value) =>
      Attribute<String>._(key, scope, value);
}

/// Builder for heading attribute styles.
///
/// There is no need to use this class directly, consider using
/// [Attribute.heading] instead.
class HeadingAttributeBuilder extends AttributeBuilder<int> {
  static const _kHeading = 'heading';

  const HeadingAttributeBuilder._() : super._(_kHeading, AttributeScope.line);

  /// Level 1 heading, equivalent of `H1` in HTML.
  Attribute<int> get level1 => Attribute<int>._(key, scope, 1);

  /// Level 2 heading, equivalent of `H2` in HTML.
  Attribute<int> get level2 => Attribute<int>._(key, scope, 2);

  /// Level 3 heading, equivalent of `H3` in HTML.
  Attribute<int> get level3 => Attribute<int>._(key, scope, 3);

  /// Level 4 heading, equivalent of `H4` in HTML.
  Attribute<int> get level4 => Attribute<int>._(key, scope, 4);

  /// Level 5 heading, equivalent of `H5` in HTML.
  Attribute<int> get level5 => Attribute<int>._(key, scope, 5);

  /// Level 6 heading, equivalent of `H6` in HTML.
  Attribute<int> get level6 => Attribute<int>._(key, scope, 6);
}

/// Applies checked style to a line in a checklist block.
class _CheckedAttribute extends Attribute<bool> {
  const _CheckedAttribute() : super._('checked', AttributeScope.line, true);
}

/// Builder for block attribute styles (number/bullet lists, code and quote).
///
/// There is no need to use this class directly, consider using
/// [Attribute.block] instead.
class BlockAttributeBuilder extends AttributeBuilder<String> {
  static const _kBlock = 'block';

  const BlockAttributeBuilder._() : super._(_kBlock, AttributeScope.line);

  /// Formats a block of lines as a bullet list.
  Attribute<String> get bulletList => Attribute<String>._(key, scope, 'ul');

  /// Formats a block of lines as a number list.
  Attribute<String> get numberList => Attribute<String>._(key, scope, 'ol');

  /// Formats a block of lines as a check list.
  Attribute<String> get checkList => Attribute<String>._(key, scope, 'cl');

  /// Formats a block of lines as a code snippet, using monospace font.
  Attribute<String> get code => Attribute<String>._(key, scope, 'code');

  /// Formats a block of lines as a quote.
  Attribute<String> get quote => Attribute<String>._(key, scope, 'quote');
}

class DirectionAttributeBuilder extends AttributeBuilder<String> {
  static const _kDirection = 'direction';

  const DirectionAttributeBuilder._()
    : super._(_kDirection, AttributeScope.line);

  Attribute<String> get rtl => Attribute<String>._(key, scope, 'rtl');
}

class AlignmentAttributeBuilder extends AttributeBuilder<String> {
  static const _kAlignment = 'alignment';

  const AlignmentAttributeBuilder._()
    : super._(_kAlignment, AttributeScope.line);

  Attribute<String> get right => Attribute<String>._(key, scope, 'right');

  Attribute<String> get center => Attribute<String>._(key, scope, 'center');

  Attribute<String> get justify => Attribute<String>._(key, scope, 'justify');
}

const _maxIndentationLevel = 8;

class IndentAttributeBuilder extends AttributeBuilder<int> {
  static const _kIndent = 'indent';

  const IndentAttributeBuilder._() : super._(_kIndent, AttributeScope.line);

  Attribute<int> withLevel(int level) {
    if (level == 0) {
      return unset;
    }
    return Attribute._(key, scope, math.min(_maxIndentationLevel, level));
  }
}
