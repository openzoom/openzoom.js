DeepZoomImageDescriptor = require './descriptors/deepzoom'


# Constants
BACKGROUND_FILL_STYLE = 'rgb(0,0,0)'
LEVEL = 9

images = [
  {
    url: '../images/1.dzi'
    width: 2048
    height: 1152
  }
  {
    url: '../images/2.dzi'
    width: 2048
    height: 1363
  }
  {
    url: '../images/3.dzi'
    width: 1463
    height: 2048
  }
  {
    url: '../images/4.dzi'
    width: 2048
    height: 1152
  }
  {
    url: '../images/5.dzi'
    width: 2048
    height: 2048
  }
  {
    url: '../images/6.dzi'
    width: 1363
    height: 2048
  }
]


# Create DZI descriptor from XML string literal
dzis = []
for image in images
  xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Image Format="jpg" Overlap="1" TileSize="254" xmlns="http://schemas.microsoft.com/deepzoom/2008">
      <Size Height="#{image.height}" Width="#{image.width}"/>
    </Image>
  """
  dzis.push DeepZoomImageDescriptor.fromXML image.url, xml

# Initialize canvas
canvas = document.getElementById 'image'
context = canvas.getContext '2d'

draw = (sceneWidth, sceneHeight) ->
  canvas.width = sceneWidth
  canvas.height = sceneHeight
  context.fillStyle = BACKGROUND_FILL_STYLE
  context.fillRect 0, 0, sceneWidth, sceneHeight

  # Load and draw tiles
  for dzi in dzis
    level = dzi.level LEVEL
    for column in [0...level.numColumns]
      for row in [0...level.numRows]
          console.log dzi
          do ->
            tileImage = new Image
            url = dzi.getTileURL level.index, column, row
            {x, y, width, height} = dzi.getTileBounds level.index, column, row
            tileImage.src = url
            tileImage.onload = ->
              # offsetX = (sceneWidth - level.width) / 2
              # offsetY = (sceneHeight - level.height) / 2
              offsetX = (sceneWidth - level.width) * Math.random()
              offsetY = (sceneHeight - level.height) * Math.random()
              context.drawImage tileImage, offsetX + x, offsetY + y

# Main
resize = ->
  draw  window.innerWidth, window.innerHeight

window.addEventListener 'resize', resize
resize()
