# Constants
CANVAS_WIDTH = 800
CANVAS_HEIGHT = 600

DZI_URL = 'http://cache.zoom.it/content/1cb.dzi'
DZI_XML = '''
<?xml version="1.0" encoding="utf-8"?>
<Image
    TileSize="254"
    Overlap="1"
    Format="png"
    ServerFormat="Default"
    xmlns="http://schemas.microsoft.com/deepzoom/2009">
    <Size Width="6740" Height="4768" />
</Image>
'''

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

    getTileURL: (level, column, row) ->
        basePath = @source.substring 0, @source.lastIndexOf '.'
        path = "#{basePath}_files"
        return "#{path}/#{level}/#{column}_#{row}.#{@format}"

# Create DZI descriptor from XML string literal
dzi = DeepZoomImageDescriptor.fromXML DZI_URL, DZI_XML

# Initialize canvas
canvas = document.getElementById 'image'
context = canvas.getContext '2d'
context.fillStyle = "rgb(0,0,0)"
context.fillRect 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT

# Load and draw tile
tile = new Image()
tile.src = dzi.getTileURL 8, 0, 0
tile.onload = ->
    context.drawImage tile, 0, 0
