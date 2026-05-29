import 'package:plume/plume.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const PlumeApp());
}

class PlumeApp extends StatelessWidget {
  const PlumeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: const [
      PlumeLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: PlumeLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    title: 'Fleather - rich-text editor for Flutter',
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<EditorState> _editorKey = GlobalKey();
  PlumeController? _controller;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    _initController();
  }

  @override
  void dispose() {
    super.dispose();
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
  }

  Future<void> _initController() async {
    try {
      // final result = await rootBundle.loadString('assets/welcome.json');
      final heuristics = Heuristics(
        formatRules: [],
        insertRules: [ForceNewlineForInsertsAroundInlineImageRule()],
        deleteRules: [],
      ).merge(Heuristics.fallback);
      final doc = Document.fromJson([
        {'insert': 'Salut ca roule?\n'},
      ], heuristics: heuristics);
      _controller = PlumeController(document: doc);
    } catch (err, st) {
      if (kDebugMode) {
        print('Cannot read welcome.json: $err\n$st');
      }
      _controller = PlumeController();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Fleather Demo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            final selection = _controller!.selection;
            _controller!.replaceText(
              selection.baseOffset,
              selection.extentOffset - selection.baseOffset,
              EmbeddableObject(
                'image',
                inline: false,
                data: {
                  'source_type': kIsWeb ? 'url' : 'file',
                  'source': image.path,
                },
              ),
            );
            _controller!.replaceText(
              selection.baseOffset + 1,
              0,
              '\n',
              selection: TextSelection.collapsed(
                offset: selection.baseOffset + 2,
              ),
            );
          }
        },
        child: const Icon(Icons.add_a_photo),
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                PlumeToolbar.basic(
                  controller: _controller!,
                  editorKey: _editorKey,
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                Expanded(
                  child: PlumeEditor(
                    controller: _controller!,
                    focusNode: _focusNode,
                    editorKey: _editorKey,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    onLaunchUrl: _launchUrl,
                    maxContentWidth: 800,
                    spellCheckConfiguration: SpellCheckConfiguration(
                      spellCheckService: DefaultSpellCheckService(),
                      misspelledSelectionColor: Colors.red,
                      misspelledTextStyle: DefaultTextStyle.of(context).style,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widget _embedBuilder(BuildContext context, EmbedNode node) {
  //   if (node.value.type == 'icon') {
  //     final data = node.value.data;
  //     // Icons.rocket_launch_outlined
  //     return Icon(
  //       IconData(int.parse(data['codePoint']), fontFamily: data['fontFamily']),
  //       color: Color(int.parse(data['color'])),
  //       size: 18,
  //     );
  //   }
  //
  //   if (node.value.type == 'image') {
  //     final sourceType = node.value.data['source_type'];
  //     ImageProvider? image;
  //     if (sourceType == 'assets') {
  //       image = AssetImage(node.value.data['source']);
  //     } else if (sourceType == 'file') {
  //       image = FileImage(File(node.value.data['source']));
  //     } else if (sourceType == 'url') {
  //       image = NetworkImage(node.value.data['source']);
  //     } else if (sourceType == 'data') {
  //       // source: 'data:image/jpeg;base64, LzlqLzRBQ... <!-- Base64 data -->'
  //       RegExp regex = RegExp(
  //         r'^data:image\/(png|jpe?g|gif|bmp|webp);base64,',
  //         caseSensitive: false,
  //       );
  //       if (regex.hasMatch(node.value.data['source'])) {
  //         String base64Image =
  //         node.value.data['source'].replaceFirst(regex, '');
  //         image = MemoryImage(base64Decode(base64Image));
  //       }
  //     }
  //     if (image != null) {
  //       return Padding(
  //         // Caret takes 2 pixels, hence not symmetric padding values.
  //         padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
  //         child: Container(
  //           width: (node.value.data['width'] as num?)?.toDouble() ?? 300,
  //           height: (node.value.data['height'] as num?)?.toDouble() ?? 300,
  //           decoration: BoxDecoration(
  //             image: DecorationImage(image: image, fit: BoxFit.cover),
  //           ),
  //         ),
  //       );
  //     }
  //   }
  //
  //   return defaultFleatherEmbedBuilder(context, node);
  // }

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }
}

/// This is an example insert rule that will insert a new line before and
/// after inline image embed.
class ForceNewlineForInsertsAroundInlineImageRule extends InsertRule {
  @override
  Delta? apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final cursorBeforeInlineEmbed = _isInlineImage(target.data);
    final cursorAfterInlineEmbed =
        previous != null && _isInlineImage(previous.data);

    if (cursorBeforeInlineEmbed || cursorAfterInlineEmbed) {
      final delta = Delta()..retain(index);
      if (cursorAfterInlineEmbed && !data.startsWith('\n')) {
        delta.insert('\n');
      }
      delta.insert(data);
      if (cursorBeforeInlineEmbed && !data.endsWith('\n')) {
        delta.insert('\n');
      }
      return delta;
    }
    return null;
  }

  bool _isInlineImage(Object data) {
    if (data is EmbeddableObject) {
      return data.type == 'image' && data.inline;
    }
    if (data is Map) {
      return data[EmbeddableObject.kTypeKey] == 'image' &&
          data[EmbeddableObject.kInlineKey];
    }
    return false;
  }
}
