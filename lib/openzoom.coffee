# Constants
CANVAS_WIDTH = 800
CANVAS_HEIGHT = 600
TILE_URL = 'http://cache.zoom.it/content/1cb_files/8/0_0.png'

# Classes
class DeepZoomImageDescriptor
    constructor: (@source, @width, @height, @tileSize, @tileOverlap, @format) ->

    @fromXML: (source, xmlString) ->
        xml = @parseXML xmlString
        image = xml.documentElement
        tileSize = image.getAttribute 'TileSize'
        tileOverlap = image.getAttribute 'Overlap'
        format = image.getAttribute 'Format'

        size = image.getElementsByTagName('Size')[0]
        width = size.getAttribute 'Width'
        height = size.getAttribute 'Height'

        descriptor = new DeepZoomImageDescriptor source, width, height,
            tileSize, tileOverlap, format
        return descriptor

    @parseXML: (xmlString) ->
        # IE
        if window.ActiveXObject
            try
                xml = new ActiveXObject 'Microsoft.XMLDOM'
                xml.async = false
                xml.loadXML xmlString
        # Other browsers
        else if window.DOMParser
            try
                parser = new DOMParser()
                xml = parser.parseFromString xmlString, 'text/xml'
        return xml


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
