import 'package:test/test.dart';
import 'package:plume/document_model/document_model.dart';

void main() {
  group('$Style', () {
    test('get', () {
      var attrs = Style.fromJson(<String, dynamic>{'block': 'ul'});
      var attr = attrs.get(Attribute.block);
      expect(attr, Attribute.ul);
    });

    test('get unset', () {
      var attrs = Style.fromJson(<String, dynamic>{'b': null});
      var attr = attrs.get(Attribute.bold);
      expect(attr, Attribute.bold.unset);
    });
  });

  group('$Attribute', () {
    test('create background attribute with color', () {
      final attribute = Attribute.backgroundColor.withColor(0xFFFF0000);
      expect(attribute.key, Attribute.backgroundColor.key);
      expect(attribute.scope, Attribute.backgroundColor.scope);
      expect(attribute.value, 0xFFFF0000);
    });

    test('create background attribute with transparent color', () {
      final attribute = Attribute.backgroundColor.withColor(0x00000000);
      expect(attribute, Attribute.backgroundColor.unset);
    });

    test('create foreground attribute with color', () {
      final attribute = Attribute.foregroundColor.withColor(0x00FF0000);
      expect(attribute.key, Attribute.foregroundColor.key);
      expect(attribute.scope, Attribute.foregroundColor.scope);
      expect(attribute.value, 0x00FF0000);
    });

    test('create foreground attribute with black color', () {
      final attribute = Attribute.foregroundColor.withColor(0x00000000);
      expect(attribute, Attribute.foregroundColor.unset);
    });
  });
}
