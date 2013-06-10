XML = require '../util/xml'


class DeepZoomImageDescriptor
  constructor: (@source, @width, @height, @tileSize, @tileOverlap, @format) ->
    @_levels = []
    @tileWidth = @tileSize
    @tileHeight = @tileSize
    @numLevels = Math.ceil(Math.log(Math.max(@width, @height)) / Math.LN2) + 1
    @_createLevels @tileSize, @tileSize, @numLevels

  _createLevels: (tileWidth, tileHeight, numLevels) ->
    for index in [0...numLevels]
      console.log numLevels
      size = @_getSize index
      width = size.x
      height = size.y
      numColumns = Math.ceil width / tileWidth
      numRows = Math.ceil height / tileHeight
      level = {
        index
        width
        height
        numColumns
        numRows
      }
      @_levels.push level

  @fromXML: (source, xmlString) ->
    xml = XML.parse xmlString
    image = xml.documentElement
    tileSize = image.getAttribute 'TileSize'
    tileOverlap = image.getAttribute 'Overlap'
    format = image.getAttribute 'Format'

    size = image.getElementsByTagName('Size')[0]
    width = size.getAttribute 'Width'
    height = size.getAttribute 'Height'

    new DeepZoomImageDescriptor source, width, height, tileSize,
                                tileOverlap, format

  getTileURL: (level, column, row) ->
    basePath = @source.substring 0, @source.lastIndexOf '.'
    path = "#{basePath}_files"
    "#{path}/#{level}/#{column}_#{row}.#{@format}"

  _getScale: (level) ->
    maxLevel = @numLevels - 1
    # 1 / (1 << maxLevel - level)
    Math.pow 0.5, maxLevel - level

  _getSize: (level) ->
    size = {}
    scale = @_getScale level
    size.x = Math.ceil @width * scale
    size.y = Math.ceil @height * scale
    size

  level: (index) -> @_levels[index]

  getTileBounds: (level, column, row) ->
    bounds = {}
    offsetX = if column is 0 then 0 else @tileOverlap
    offsetY = if row is 0 then 0 else @tileOverlap
    bounds.x = (column * @tileWidth) - offsetX
    bounds.y = (row * @tileHeight) - offsetY

    l = @level level
    width = @tileWidth + (if column is 0 then 1 else 2) * @tileOverlap
    height = @tileHeight + (if row is 0 then 1 else 2) * @tileOverlap
    bounds.width = Math.min width, l.width - bounds.x
    bounds.height = Math.min height, l.height - bounds.y
    bounds


module.exports = DeepZoomImageDescriptor
