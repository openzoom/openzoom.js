export class DeepZoomImageDescriptor {
  private url: string
  private width: number
  private height: number
  private tileSize: number
  private tileOverlap: number
  private tileFormat: TileFormat

  levels: Array<ImagePyramidLevel>
  numLevels: number

  constructor({
    url,
    width,
    height,
    tileSize,
    tileOverlap,
    tileFormat
  }: {
    url: string
    width: number
    height: number
    tileSize: number
    tileOverlap: number
    tileFormat: TileFormat
  }) {
    this.url = url
    this.width = width
    this.height = height
    this.tileSize = tileSize
    this.tileOverlap = tileOverlap
    this.tileFormat = tileFormat

    this.numLevels = this.getNumLevels(width, height)
  }

  private getNumLevels(width: number, height: number): number {
    return Math.ceil(Math.log(Math.max(width, height)) / Math.LN2) + 1
  }
  private createLevels(
    originalWidth: number,
    originalHeight: number,
    tileWidth: number,
    tileHeight: number,
    numLevels: number
  ): void {
    var maxLevel: number = numLevels - 1

    for (var index: number = 0; index <= maxLevel; index++) {
      var size: Point = this.getSize(index)
      var width: number = size.x
      var height: number = size.y
      var numColumns: number = Math.ceil(width / tileWidth)
      var numRows: number = Math.ceil(height / tileHeight)
      var level: ImagePyramidLevel = new ImagePyramidLevel(
        this,
        index,
        width,
        height,
        numColumns,
        numRows
      )

      // addLevel(level)
      this.levels.push(level)
    }
  }

  private getScale(level: number): number {
    var maxLevel: number = this.numLevels - 1
    // 1 / (1 << maxLevel - level)
    return Math.pow(0.5, maxLevel - level)
  }

  private getSize(level: number): Point {
    var size: Point = new Point()
    var scale: number = this.getScale(level)
    size.x = Math.ceil(this.width * scale)
    size.y = Math.ceil(this.height * scale)

    return size
  }
}

type TileFormat = "jpg" | "jpeg" | "png"

class ImagePyramidLevel {
  descriptor: DeepZoomImageDescriptor
  index: number
  width: number
  height: number
  numColumns: number
  numRows: number

  constructor(
    descriptor: DeepZoomImageDescriptor,
    index: number,
    width: number,
    height: number,
    numColumns: number,
    numRows: number
  ) {
    this.descriptor = descriptor

    this.index = index
    this.width = width
    this.height = height
    this.numColumns = numColumns
    this.numRows = numRows
  }
}

class Point {
  x: number
  y: number

  // FIXME: Avoid defaults
  constructor(x: number = 0, y: number = 0) {
    this.x = x
    this.y = y
  }
}
