
part of openzoom;


class DeepZoomImageDescriptor {
  final String source;
  final int width;
  final int height;
  final int tileSize;
  int tileWidth;
  int tileHeight;
  final int tileOverlap;
  final String format;
  int numLevels;
  List<ImagePyramidLevel> _levels;

  DeepZoomImageDescriptor(this.source, this.width, this.height,
                          this.tileSize, this.tileOverlap, this.format) {
    _levels = [];
    tileWidth = tileSize;
    tileHeight = tileSize;
    numLevels = (math.log(math.max(width, height)) / math.LN2).ceil() + 1;
    _createLevels(tileSize, tileSize, numLevels);
  }

  factory DeepZoomImageDescriptor.fromXml(String source, String xmlString) {
    XmlDocument image = parse(xmlString);
    Function getAttribute = (node, name) {
      return node.attributes.singleWhere((attr) => (attr.name.local == name));
    };

    int tileSize = int.parse(getAttribute(image.firstChild, 'TileSize').value,
        radix: 10);
    int tileOverlap = int.parse(getAttribute(image.firstChild, 'Overlap').value,
        radix: 10);
    String format = getAttribute(image.firstChild, 'Format').value;

    XmlElement size = image.findAllElements('Size').first;
    int width = int.parse(getAttribute(size, 'Width').value, radix: 10);
    int height = int.parse(getAttribute(size, 'Height').value, radix: 10);

    return new DeepZoomImageDescriptor(source, width, height, tileSize,
                                       tileOverlap, format);
  }

  _createLevels(tileWidth, tileHeight, numLevels) {
    for (var index = 0; index < numLevels; index++) {
      Point size = _getSize(index);
      int width = size.x;
      int height = size.y;
      ImagePyramidLevel level = new ImagePyramidLevel(index, width, height,
                                                      tileWidth, tileHeight);
      _levels.add(level);
    }
  }

  String getTileURL(int level, int column, int row) {
    String basePath = this.source.substring(0, this.source.lastIndexOf('.'));
    String path = "${basePath}_files";
    return "$path/$level/${column}_$row.$format";
  }

  num _getScale(level) {
    int maxLevel = numLevels - 1;
    // 1 / (1 << maxLevel - level)
    return math.pow(0.5, maxLevel - level);
  }

  Point _getSize(int level) {
    var scale = _getScale(level);
    int x = (width * scale).ceil();
    int y = (height * scale).ceil();
    return new Point(x, y);
  }

  ImagePyramidLevel getLevelAt(int index) => _levels[index];

  Rect getTileBounds(int level, int column, int row) {
    int tileWidth = tileSize;
    int tileHeight = tileSize;
    ImagePyramidLevel l = getLevelAt(level);
    int offsetX = (column == 0) ? 0 : tileOverlap;
    int offsetY = (row == 0) ? 0 : tileOverlap;
    num width = tileWidth + (column == 0 ? 1 : 2) * tileOverlap;
    num height = tileHeight + (row == 0 ? 1 : 2) * tileOverlap;

    num left = (column * tileWidth) - offsetX;
    num top = (row * tileHeight) - offsetY;
    width = math.min(width, l.width - left);
    height = math.min(height, l.height - top);
    return new Rect(left, top, width, height);
  }

  toString() => '[DeepZoomImageDescriptor width=$width height=$height]';
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility class for representing two-dimensional positions.
 */
class Point {
  final num x;
  final num y;

  const Point([num x = 0, num y = 0]): x = x, y = y;

  String toString() => '($x, $y)';

  bool operator ==(other) {
    if (other is !Point) return false;
    return x == other.x && y == other.y;
  }

  Point operator +(Point other) {
    return new Point(x + other.x, y + other.y);
  }

  Point operator -(Point other) {
    return new Point(x - other.x, y - other.y);
  }

  Point operator *(num factor) {
    return new Point(x * factor, y * factor);
  }

  /**
   * Returns the distance between two points.
   */
  double distanceTo(Point other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Returns the squared distance between two points.
   *
   * Squared distances can be used for comparisons when the actual value is not
   * required.
   */
  num squaredDistanceTo(Point other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return dx * dx + dy * dy;
  }

  Point ceil() => new Point(x.ceil(), y.ceil());
  Point floor() => new Point(x.floor(), y.floor());
  Point round() => new Point(x.round(), y.round());

  /**
   * Truncates x and y to integers and returns the result as a new point.
   */
  Point toInt() => new Point(x.toInt(), y.toInt());
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A class for representing two-dimensional rectangles.
 */
class Rect {
  final num left;
  final num top;
  final num width;
  final num height;

  const Rect(this.left, this.top, this.width, this.height);

  factory Rect.fromPoints(Point a, Point b) {
    var left;
    var width;
    if (a.x < b.x) {
      left = a.x;
      width = b.x - left;
    } else {
      left = b.x;
      width = a.x - left;
    }
    var top;
    var height;
    if (a.y < b.y) {
      top = a.y;
      height = b.y - top;
    } else {
      top = b.y;
      height = a.y - top;
    }

    return new Rect(left, top, width, height);
  }

  num get right => left + width;
  num get bottom => top + height;

  // NOTE! All code below should be common with Rect.
  // TODO: implement with mixins when available.

  String toString() {
    return '($left, $top, $width, $height)';
  }

  bool operator ==(other) {
    if (other is !Rect) return false;
    return left == other.left && top == other.top && width == other.width &&
        height == other.height;
  }

  /**
   * Computes the intersection of this rectangle and the rectangle parameter.
   * Returns null if there is no intersection.
   */
  Rect intersection(Rect rect) {
    var x0 = math.max(left, rect.left);
    var x1 = math.min(left + width, rect.left + rect.width);

    if (x0 <= x1) {
      var y0 = math.max(top, rect.top);
      var y1 = math.min(top + height, rect.top + rect.height);

      if (y0 <= y1) {
        return new Rect(x0, y0, x1 - x0, y1 - y0);
      }
    }
    return null;
  }


  /**
   * Returns whether a rectangle intersects this rectangle.
   */
  bool intersects(Rect other) {
    return (left <= other.left + other.width && other.left <= left + width &&
        top <= other.top + other.height && other.top <= top + height);
  }

  /**
   * Returns a new rectangle which completely contains this rectangle and the
   * input rectangle.
   */
  Rect union(Rect rect) {
    var right = math.max(this.left + this.width, rect.left + rect.width);
    var bottom = math.max(this.top + this.height, rect.top + rect.height);

    var left = math.min(this.left, rect.left);
    var top = math.min(this.top, rect.top);

    return new Rect(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether this rectangle entirely contains another rectangle.
   */
  bool containsRect(Rect another) {
    return left <= another.left &&
           left + width >= another.left + another.width &&
           top <= another.top &&
           top + height >= another.top + another.height;
  }

  /**
   * Tests whether this rectangle entirely contains a point.
   */
  bool containsPoint(Point another) {
    return another.x >= left &&
           another.x <= left + width &&
           another.y >= top &&
           another.y <= top + height;
  }

  Rect ceil() => new Rect(left.ceil(), top.ceil(), width.ceil(), height.ceil());
  Rect floor() => new Rect(left.floor(), top.floor(), width.floor(),
      height.floor());
  Rect round() => new Rect(left.round(), top.round(), width.round(),
      height.round());

  /**
   * Truncates coordinates to integers and returns the result as a new
   * rectangle.
   */
  Rect toInt() => new Rect(left.toInt(), top.toInt(), width.toInt(),
      height.toInt());

  Point get topLeft => new Point(this.left, this.top);
  Point get bottomRight => new Point(this.left + this.width,
      this.top + this.height);
}
