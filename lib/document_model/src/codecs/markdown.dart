import 'dart:convert';

import 'package:parchment_delta/parchment_delta.dart';

import '../document.dart';
import '../document/attributes.dart';
import '../document/block.dart';
import '../document/leaf.dart';
import '../document/line.dart';

class MarkdownCodec extends Codec<Document, String> {
  final String unorderedListToken;

  const MarkdownCodec({this.unorderedListToken = '*'});

  @override
  Converter<String, Document> get decoder =>
      _MarkdownDecoder();

  @override
  Converter<Document, String> get encoder =>
      _MarkdownEncoder(unorderedListToken: unorderedListToken);
}

class _MarkdownDecoder extends Converter<String, Document> {
  static final _headingRegExp = RegExp(r'(#+) *(.+)');
  static final _styleRegExp = RegExp(
    // italic then bold
    r'(([*_])(\*{2}|_{2})(?<italic_bold_text>.*?[^ \3\2])\3\2)|'
    // bold then italic
    r'((\*{2}|_{2})([*_])(?<bold_italic_text>.*?[^ \7\6])\7\6)|'
    // italic or bold
    r'(((\*{1,2})|(_{1,2}))(?<bold_or_italic_text>.*?[^ \10])\10)|'
    // strike through
    r'(~~(?<strike_through_text>.+?)~~)|'
    // inline code
    r'(`(?<inline_code_text>.+?)`)',
  );

  static final _linkRegExp = RegExp(r'\[(.+?)\]\(([^)]+)\)');
  static final _ulRegExp = RegExp(r'^( *)[-*+] +(.*)');
  static final _olRegExp = RegExp(r'^( *)\d+[.)] +(.*)');
  static final _clRegExp = RegExp(r'^( *)- +\[( |x|X)\] +(.*)');
  static final _bqRegExp = RegExp(r'^> *(.*)');
  static final _codeRegExpTag = RegExp(r'^( *)```');

  bool _inBlockStack = false;

  @override
  Document convert(String input) {
    final lines = input.split('\n');
    final delta = Delta();

    for (final line in lines) {
      _handleLine(line, delta);
    }

    return Document.fromDelta(delta..trim());
  }

  void _handleLine(String line, Delta delta, [Style? style]) {
    if (line.isEmpty && delta.isEmpty) {
      delta.insert('\n');
      return;
    }

    if (_handleBlockQuote(line, delta, style)) {
      return;
    }
    if (_handleBlock(line, delta, style)) {
      return;
    }
    if (_handleHeading(line, delta, style)) {
      return;
    }

    if (line.isNotEmpty) {
      if (style?.isInline ?? true) {
        _handleSpan(line, delta, true, style);
      } else {
        _handleSpan(line, delta, false,
            Style().putAll(style?.inlineAttributes ?? []));
        _handleSpan('\n', delta, false,
            Style().putAll(style?.lineAttributes ?? []));
      }
    }
  }

  // Markdown supports headings and blocks within blocks (except for within code)
  // but not blocks within headers, or ul within
  bool _handleBlock(String line, Delta delta, [Style? style]) {
    final match = _codeRegExpTag.matchAsPrefix(line);
    if (match != null) {
      _inBlockStack = !_inBlockStack;
      return true;
    }
    if (_inBlockStack) {
      delta.insert(line);
      delta.insert('\n', Attribute.code.toJson());
      // Don't bother testing for code blocks within block stacks
      return true;
    }

    if (_handleCheckList(line, delta, style) ||
        _handleOrderedList(line, delta, style) ||
        _handleUnorderedList(line, delta, style)) {
      return true;
    }

    return false;
  }

  // all blocks are supported within bq
  bool _handleBlockQuote(String line, Delta delta, [Style? style]) {
    // we do not support nested blocks
    if (style?.contains(Attribute.block) ?? false) {
      return false;
    }
    final match = _bqRegExp.matchAsPrefix(line);
    final span = match?.group(1);
    if (span != null) {
      final newStyle = (style ?? Style()).put(Attribute.bq);

      // all blocks are supported within bq
      _handleLine(span, delta, newStyle);
      return true;
    }
    return false;
  }

  // ol is supported within ol and bq, but not supported within ul
  bool _handleOrderedList(String line, Delta delta, [Style? style]) {
    // we do not support nested blocks
    if (style?.contains(Attribute.block) ?? false) {
      return false;
    }
    final match = _olRegExp.matchAsPrefix(line);
    final span = match?.group(2);
    final indent = ((match?.group(1)?.length ?? 0) / 2).floor();
    if (span != null) {
      _handleSpan(span, delta, false, style);
      Style blockStyle = Style().put(Attribute.ol);
      if (indent > 0) {
        blockStyle =
            blockStyle.put(Attribute.indent.withLevel(indent));
      }
      _handleSpan('\n', delta, false, blockStyle);
      return true;
    }
    return false;
  }

  bool _handleUnorderedList(String line, Delta delta, [Style? style]) {
    // we do not support nested blocks
    if (style?.contains(Attribute.block) ?? false) {
      return false;
    }

    final newStyle = (style ?? Style()).put(Attribute.ul);

    final match = _ulRegExp.matchAsPrefix(line);
    final span = match?.group(2);
    if (span != null) {
      _handleSpan(span, delta, false,
          Style().putAll(newStyle.inlineAttributes));
      _handleSpan(
          '\n', delta, false, Style().putAll(newStyle.lineAttributes));
      return true;
    }
    return false;
  }

  bool _handleCheckList(String line, Delta delta, [Style? style]) {
    // we do not support nested blocks
    if (style?.contains(Attribute.block) ?? false) {
      return false;
    }

    Style newStyle =
        (style ?? Style()).put(Attribute.cl);

    final match = _clRegExp.matchAsPrefix(line);
    final span = match?.group(3);
    final isChecked = match?.group(2) != ' ';
    if (isChecked) {
      newStyle = newStyle.put(Attribute.checked);
    }
    if (span != null) {
      _handleSpan(span, delta, false,
          Style().putAll(newStyle.inlineAttributes));
      _handleSpan(
          '\n', delta, false, Style().putAll(newStyle.lineAttributes));
      return true;
    }
    return false;
  }

  bool _handleHeading(String line, Delta delta, [Style? style]) {
    final match = _headingRegExp.matchAsPrefix(line);
    final levelTag = match?.group(1);
    if (levelTag != null) {
      final level = levelTag.length;
      final newStyle = (style ?? Style())
          .put(Attribute.heading.withValue(level));

      final span = match?.group(2);
      if (span == null) {
        return false;
      }
      _handleSpan(span, delta, false,
          Style().putAll(newStyle.inlineAttributes));
      _handleSpan(
          '\n', delta, false, Style().putAll(newStyle.lineAttributes));
      return true;
    }

    return false;
  }

  void _handleSpan(
      String span, Delta delta, bool addNewLine, Style? outerStyle) {
    var start = _handleStyles(span, delta, outerStyle);
    span = span.substring(start);

    if (span.isNotEmpty) {
      start = _handleLinks(span, delta, outerStyle);
      span = span.substring(start);
    }

    if (span.isNotEmpty) {
      if (addNewLine) {
        delta.insert('$span\n', outerStyle?.toJson());
      } else {
        delta.insert(span, outerStyle?.toJson());
      }
    } else if (addNewLine) {
      delta.insert('\n', outerStyle?.toJson());
    }
  }

  int _handleStyles(String span, Delta delta, Style? outerStyle) {
    var start = 0;

    // `**some code**`
    //  does not translate to
    // <code><strong>some code</code></strong>
    //  but to
    // <code>**code**</code>
    if (outerStyle?.contains(Attribute.inlineCode) ?? false) {
      return start;
    }

    final matches = _styleRegExp.allMatches(span);
    for (final match in matches) {
      if (match.start > start) {
        if (span.substring(match.start - 1, match.start) == '[') {
          delta.insert(
              span.substring(start, match.start - 1), outerStyle?.toJson());
          start = match.start -
              1 +
              _handleLinks(span.substring(match.start - 1), delta, outerStyle);
          continue;
        } else {
          delta.insert(
              span.substring(start, match.start), outerStyle?.toJson());
        }
      }

      final String text;
      final String styleTag;
      if (match.namedGroup('italic_bold_text') != null) {
        text = match.namedGroup('italic_bold_text')!;
        styleTag = '${match.group(2)}${match.group(3)}';
      } else if (match.namedGroup('bold_italic_text') != null) {
        text = match.namedGroup('bold_italic_text')!;
        styleTag = '${match.group(6)}${match.group(7)}';
      } else if (match.namedGroup('bold_or_italic_text') != null) {
        text = match.namedGroup('bold_or_italic_text')!;
        styleTag = match.group(10)!;
      } else if (match.namedGroup('strike_through_text') != null) {
        text = match.namedGroup('strike_through_text')!;
        styleTag = '~~';
      } else {
        assert(match.namedGroup('inline_code_text') != null);
        text = match.namedGroup('inline_code_text')!;
        styleTag = '`';
      }
      var newStyle = _fromStyleTag(styleTag);

      if (outerStyle != null) {
        newStyle = newStyle.mergeAll(outerStyle);
      }

      _handleSpan(text, delta, false, newStyle);
      start = match.end;
    }

    return start;
  }

  Style _fromStyleTag(String styleTag) {
    assert(
        (styleTag == '`') |
            (styleTag == '~~') |
            (styleTag == '_') |
            (styleTag == '*') |
            (styleTag == '__') |
            (styleTag == '**') |
            (styleTag == '__*') |
            (styleTag == '**_') |
            (styleTag == '_**') |
            (styleTag == '*__') |
            (styleTag == '***') |
            (styleTag == '___'),
        'Invalid style tag \'$styleTag\'');
    assert(styleTag.isNotEmpty, 'Style tag must not be empty');
    if (styleTag == '`') {
      return Style().put(Attribute.inlineCode);
    }
    if (styleTag == '~~') {
      return Style().put(Attribute.strikethrough);
    }
    if (styleTag.length == 3) {
      return Style()
          .putAll([Attribute.bold, Attribute.italic]);
    }
    if (styleTag.length == 2) {
      return Style().put(Attribute.bold);
    }
    return Style().put(Attribute.italic);
  }

  int _handleLinks(String span, Delta delta, Style? outerStyle) {
    var start = 0;

    final matches = _linkRegExp.allMatches(span);
    for (final match in matches) {
      if (match.start > start) {
        delta.insert(span.substring(start, match.start)); //, outerStyle);
      }

      final text = match.group(1);
      final href = match.group(2);
      if (text == null || href == null) {
        return start;
      }
      final newStyle = (outerStyle ?? Style())
          .put(Attribute.link.fromString(href));

      _handleSpan(text, delta, false, newStyle);
      start = match.end;
    }

    return start;
  }
}

class _MarkdownEncoder extends Converter<Document, String> {
  final String unorderedListToken;

  _MarkdownEncoder({required this.unorderedListToken});

  late final simpleBlocks = <Attribute, String>{
    Attribute.bq: '> ',
    Attribute.ul: '$unorderedListToken ',
    Attribute.ol: '. ',
  };

  String _trimRight(StringBuffer buffer) {
    var text = buffer.toString();
    if (!text.endsWith(' ')) return '';
    final result = text.trimRight();
    buffer.clear();
    buffer.write(result);
    return ' ' * (text.length - result.length);
  }

  void handleText(
      StringBuffer buffer, TextNode node, Style currentInlineStyle) {
    final style = node.style;
    final rightPadding = _trimRight(buffer);

    for (final attr in currentInlineStyle.inlineAttributes.toList().reversed) {
      if (!style.contains(attr)) {
        _writeAttribute(buffer, attr, close: true);
      }
    }

    buffer.write(rightPadding);

    final leftTrimmedText = node.value.trimLeft();

    buffer.write(' ' * (node.length - leftTrimmedText.length));

    for (final attr in style.inlineAttributes) {
      if (!currentInlineStyle.contains(attr)) {
        _writeAttribute(buffer, attr);
      }
    }

    buffer.write(leftTrimmedText);
  }

  @override
  String convert(Document input) {
    final buffer = StringBuffer();
    final lineBuffer = StringBuffer();
    var currentInlineStyle = Style();
    Attribute? currentBlockAttribute;

    void handleLine(LineNode node) {
      if (node.hasBlockEmbed) return;

      for (final attr in node.style.lineAttributes) {
        if (attr.key == Attribute.block.key) {
          if (currentBlockAttribute != attr) {
            _writeAttribute(lineBuffer, attr);
            currentBlockAttribute = attr;
          } else if (attr != Attribute.code) {
            _writeAttribute(lineBuffer, attr);
          }
        } else {
          _writeAttribute(lineBuffer, attr);
        }
      }

      for (final textNode in node.children) {
        handleText(lineBuffer, textNode as TextNode, currentInlineStyle);
        currentInlineStyle = textNode.style;
      }

      handleText(lineBuffer, TextNode(), currentInlineStyle);

      currentInlineStyle = Style();

      final blockAttribute = node.style.get(Attribute.block);
      if (currentBlockAttribute != blockAttribute) {
        _writeAttribute(lineBuffer, currentBlockAttribute, close: true);
      }

      buffer.write(lineBuffer);
      lineBuffer.clear();
    }

    void handleBlock(BlockNode node) {
      // store for each indent level the current item order
      int currentLevel = 0;
      Map<int, int> currentItemOrders = {0: 1};
      for (final lineNode in node.children) {
        if ((lineNode is LineNode) &&
            lineNode.style.contains(Attribute.indent)) {
          final indent = lineNode.style.value(Attribute.indent)!;
          currentLevel++;
          currentItemOrders[currentLevel] = 1;
          // Insert 2 spaces per indent before black start
          lineBuffer.writeAll(List.generate(indent, (_) => '  '));
        }
        if (node.style.containsSame(Attribute.ol)) {
          lineBuffer.write(currentItemOrders[currentLevel]);
        } else if (node.style.containsSame(Attribute.cl)) {
          lineBuffer.write('- [');
          if ((lineNode as LineNode)
              .style
              .contains(Attribute.checked)) {
            lineBuffer.write('X');
          } else {
            lineBuffer.write(' ');
          }
          lineBuffer.write('] ');
        }
        handleLine(lineNode as LineNode);
        if (!lineNode.isLast) {
          buffer.write('\n');
        }
        currentItemOrders[currentLevel] = currentItemOrders[currentLevel]! + 1;
      }

      handleLine(LineNode());
      currentBlockAttribute = null;
    }

    for (final child in input.root.children) {
      if (child is LineNode) {
        handleLine(child);
        buffer.write('\n\n');
      } else if (child is BlockNode) {
        handleBlock(child);
        buffer.write('\n\n');
      }
    }

    return buffer.toString();
  }

  void _writeAttribute(StringBuffer buffer, Attribute? attribute,
      {bool close = false}) {
    if (attribute == Attribute.bold) {
      _writeBoldTag(buffer);
    } else if (attribute == Attribute.italic) {
      _writeItalicTag(buffer);
    } else if (attribute == Attribute.inlineCode) {
      _writeInlineCodeTag(buffer);
    } else if (attribute == Attribute.strikethrough) {
      _writeStrikeThoughTag(buffer);
    } else if (attribute?.key == Attribute.link.key) {
      _writeLinkTag(buffer, attribute as Attribute<String>,
          close: close);
    } else if (attribute?.key == Attribute.heading.key) {
      _writeHeadingTag(buffer, attribute as Attribute<int>);
    } else if (attribute?.key == Attribute.block.key) {
      _writeBlockTag(buffer, attribute as Attribute<String>,
          close: close);
    } else if (attribute?.key == Attribute.checked.key) {
      // no-op already handled in handleBlock
    } else if (attribute?.key == Attribute.indent.key) {
      // no-op already handled in handleBlock
    } else {
      throw ArgumentError('Cannot handle $attribute');
    }
  }

  void _writeBoldTag(StringBuffer buffer) {
    buffer.write('**');
  }

  void _writeItalicTag(StringBuffer buffer) {
    buffer.write('_');
  }

  void _writeInlineCodeTag(StringBuffer buffer) {
    buffer.write('`');
  }

  void _writeStrikeThoughTag(StringBuffer buffer) {
    buffer.write('~~');
  }

  void _writeLinkTag(StringBuffer buffer, Attribute<String> link,
      {bool close = false}) {
    if (close) {
      buffer.write('](${link.value})');
    } else {
      buffer.write('[');
    }
  }

  void _writeHeadingTag(StringBuffer buffer, Attribute<int> heading) {
    var level = heading.value!;
    buffer.write('${'#' * level} ');
  }

  void _writeBlockTag(StringBuffer buffer, Attribute<String> block,
      {bool close = false}) {
    if (block == Attribute.code) {
      if (close) {
        buffer.write('\n```');
      } else {
        buffer.write('```\n');
      }
    } else {
      if (close) return; // no close tag needed for simple blocks.

      final tag = simpleBlocks[block];
      if (tag != null) {
        buffer.write(tag);
      }
    }
  }
}
