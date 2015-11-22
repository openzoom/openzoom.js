/* @flow */


const image = document.getElementById('image')

if (!(image instanceof HTMLCanvasElement)) {
  throw new Error('`image` must be a <canvas>')
}

const context: ?CanvasRenderingContext2D = image.getContext('2d')

if (context === null) {
  throw new Error('Couldn’t instantiate canvas context.')
}

context.fillStyle = '#000000'
context.fillRect(0, 0, image.width, image.height)
