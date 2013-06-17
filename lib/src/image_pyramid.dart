part of openzoom;


class ImagePyramidLevel {
  final int index;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final int numColumns;
  final int numRows;

  ImagePyramidLevel(index, width, height,
                    tileWidth, tileHeight) :
                      index = index,
                      width = width,
                      height = height,
                      tileWidth = tileWidth,
                      tileHeight = tileHeight,
                      numColumns = (width / tileWidth).ceil(),
                      numRows = (height / tileHeight).ceil();
}
