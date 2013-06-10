DeepZoomImageDescriptor = require './descriptors/deepzoom'


# Constants
BACKGROUND_FILL_STYLE = 'rgb(0,0,0)'
LEVEL = 13
DZI_URL = 'http://cache.zoom.it/content/1cb.dzi'
DZI_XML = """
  <?xml version="1.0" encoding="utf-8"?>
  <Image
      TileSize="254"
      Overlap="1"
      Format="png"
      ServerFormat="Default"
      xmlns="http://schemas.microsoft.com/deepzoom/2009">
      <Size Width="6740" Height="4768" />
  </Image>
"""


# Create DZI descriptor from XML string literal
dzi = DeepZoomImageDescriptor.fromXML DZI_URL, DZI_XML

# Initialize canvas
canvas = document.getElementById 'image'
context = canvas.getContext '2d'

draw = (sceneWidth, sceneHeight) ->
  canvas.width = sceneWidth
  canvas.height = sceneHeight
  context.fillStyle = BACKGROUND_FILL_STYLE
  context.fillRect 0, 0, sceneWidth, sceneHeight

  # Load and draw tiles
  level = dzi.level LEVEL
  for column in [0...level.numColumns]
    for row in [0...level.numRows]
      do ->
        tileImage = new Image
        url = dzi.getTileURL level.index, column, row
        {x, y, width, height} = dzi.getTileBounds level.index, column, row
        tileImage.src = url
        tileImage.onload = ->
          offsetX = (sceneWidth - level.width) / 2
          offsetY = (sceneHeight - level.height) / 2
          context.drawImage tileImage, offsetX + x, offsetY + y

# Main
resize = ->
  draw  window.innerWidth, window.innerHeight

window.addEventListener 'resize', resize
resize()
