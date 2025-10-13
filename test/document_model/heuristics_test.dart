import 'package:plume/document_model/document_model.dart';
import 'package:test/test.dart';

Document dartconfDoc() {
  return Document()..insert(0, 'DartConf\nLos Angeles');
}

final ul = Attribute.ul.toJson();
final h1 = Attribute.h1.toJson();

void main() {
  group('$Heuristics', () {
    test('ensures heuristics are applied', () {
      final doc = dartconfDoc();
      final heuristics = Heuristics(
        formatRules: [],
        insertRules: [],
        deleteRules: [],
      );

      expect(() {
        heuristics.applyInsertRules(doc, 0, 'a');
      }, throwsStateError);

      expect(() {
        heuristics.applyDeleteRules(doc, 0, 1);
      }, throwsStateError);

      expect(() {
        heuristics.applyFormatRules(doc, 0, 1, Attribute.bold);
      }, throwsStateError);
    });
  });
}
