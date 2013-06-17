import 'package:openzoom/openzoom.dart';
import 'package:unittest/unittest.dart';


void main() {
  test('DeepZoom', () {
    String source = 'test.dzi';
    int width = 2048;
    int height = 1152;
    String xml = '''
      <Image Format="jpg" Overlap="1" TileSize="254" xmlns="http://schemas.microsoft.com/deepzoom/2008">
        <Size Height="$height" Width="$width"/>
      </Image>
    ''';
    DeepZoomImageDescriptor descriptor = new DeepZoomImageDescriptor.fromXml(source, xml);
    expect(descriptor.width, equals(2048), reason: 'width');
    expect(descriptor.height, equals(1152), reason: 'height');
    expect(descriptor.numLevels, equals(12), reason: 'levels');
    expect(descriptor.format, equals('jpg'), reason: 'format');
    expect(descriptor.tileSize, equals(254), reason: 'tile size');
    expect(descriptor.tileWidth, equals(254), reason: 'tile width');
    expect(descriptor.tileHeight, equals(254), reason: 'tile height');
    expect(descriptor.tileOverlap, equals(1), reason: 'tile overlap');

    ImagePyramidLevel level = descriptor.getLevelAt(9);
    expect(level.numRows, equals(2), reason: 'rows');
    expect(level.numColumns, equals(3), reason: 'columns');
  });
}
