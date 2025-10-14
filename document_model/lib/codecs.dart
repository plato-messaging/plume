/// Provides codecs to convert documents to other formats.
library;

import '../src/codecs/markdown.dart';
import '../src/codecs/html.dart';

export '../src/codecs/markdown.dart';
export '../src/codecs/html.dart';
export '../src/codecs/html_utils.dart';

/// Markdown codec for [Document]s.
const markdownCodec = MarkdownCodec();

/// HTML codec for [Document]s.
const htmlCodec = HtmlCodec();
