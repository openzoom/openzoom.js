# Constants
CANVAS_WIDTH = 800
CANVAS_HEIGHT = 600
TILE_URL = 'http://cache.zoom.it/content/1cb_files/8/0_0.png'

# Initialize canvas
canvas = document.getElementById 'image'
context = canvas.getContext '2d'
context.fillStyle = "rgb(0,0,0)"
context.fillRect 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT

# Load and draw tile
tile = new Image()
tile.src = TILE_URL
tile.onload = ->
    context.drawImage tile, 0, 0
