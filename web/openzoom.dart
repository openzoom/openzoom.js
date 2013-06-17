import 'dart:html';
import 'dart:math' as math;
import 'package:openzoom/openzoom.dart' as oz;


const String BACKGROUND_FILL_STYLE = 'rgb(0,0,0)';
const int LEVEL = 9;

final CanvasElement canvas = query("#image") as CanvasElement;
final CanvasRenderingContext2D context = canvas.context2D;
final List<Map<String, Object>> dzis = [];


_draw(sceneWidth, sceneHeight) {
  canvas.width = sceneWidth;
  canvas.height = sceneHeight;
  context.fillStyle = BACKGROUND_FILL_STYLE;
  context.fillRect(0, 0, sceneWidth, sceneHeight);

  for (Map<String, Object> entry in dzis) {
    Point position = entry['position'];
    oz.DeepZoomImageDescriptor dzi = entry['descriptor'];
    oz.ImagePyramidLevel level = dzi.getLevelAt(LEVEL);
    for (int column = 0; column < level.numColumns; column++) {
      for (int row = 0; row < level.numRows; row++) {
        var url = dzi.getTileURL(level.index, column, row);
        oz.Rect bounds = dzi.getTileBounds(level.index, column, row);
        ImageElement tileImage = new ImageElement(src: url);
        tileImage.onLoad.listen((e) {
          context.drawImage(tileImage,
                            position.x + bounds.left,
                            position.y + bounds.top);
        });
      }
    }
  }

}

void redraw() => _draw(window.innerWidth, window.innerHeight);

void main() {
  final List<Map<String, Object>> images = [
    {
      'url': '../images/1.dzi',
      'width': 2048,
      'height': 1152
    },
    {
      'url': '../images/2.dzi',
      'width': 2048,
      'height': 1363
    },
    {
      'url': '../images/3.dzi',
      'width': 1463,
      'height': 2048
    },
    {
      'url': '../images/4.dzi',
      'width': 2048,
      'height': 1152
    },
    {
      'url': '../images/5.dzi',
      'width': 2048,
      'height': 2048
    },
    {
      'url': '../images/6.dzi',
      'width': 1363,
      'height': 2048
    }
  ];

  for (var image in images) {
    String url = image['url'];
    int width = image['width'];
    int height = image['height'];

    // FIXME: Enable parsing of XML declaration
    //        Reference: https://github.com/prujohn/dart-xml/issues/2
    //<?xml version="1.0" encoding="UTF-8"?>
    String xml = """
      <Image Format="jpg" Overlap="1" TileSize="254" xmlns="http://schemas.microsoft.com/deepzoom/2008">
      <Size Height="$height" Width="$width"/>
      </Image>
    """;

    oz.DeepZoomImageDescriptor descriptor = new oz.DeepZoomImageDescriptor.fromXml(url, xml);
    oz.ImagePyramidLevel level = descriptor.getLevelAt(LEVEL);
    math.Random random = new math.Random();
    Point position = new Point(random.nextInt(window.innerWidth - level.width),
                               random.nextInt(window.innerHeight - level.height));
    dzis.add({
      'position': position,
      'descriptor': descriptor
    });
  }

  // Redraw when window is resized
  window.onResize.listen((e) => redraw());
  redraw();
}
