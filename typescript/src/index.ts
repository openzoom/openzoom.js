import * as twgl from "twgl.js"

function main() {
  var canvas = document.querySelector("#canvas") as HTMLCanvasElement
  var gl = canvas.getContext("webgl")
  if (!gl) {
    throw new Error("Couldn’t instantiate WebGL context.")
  }

  document.addEventListener("keyup", (event) => {
    if (event.key === "f") {
      canvas.requestFullscreen()
    }
  })

  // setup GLSL program
  var program = twgl.createProgramFromScripts(gl, [
    "drawImage-vertex-shader",
    "drawImage-fragment-shader"
  ])

  // look up where the vertex data needs to go.
  var positionLocation = gl.getAttribLocation(program, "a_position")
  var texcoordLocation = gl.getAttribLocation(program, "a_texcoord")

  // lookup uniforms
  var matrixLocation = gl.getUniformLocation(program, "u_matrix")
  var textureLocation = gl.getUniformLocation(program, "u_texture")

  // Create a buffer.
  var positionBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)

  // Put a unit quad in the buffer
  // prettier-ignore
  var positions = [
    0, 0,
    0, 1,
    1, 0,
    1, 0,
    0, 1,
    1, 1
  ]
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW)

  // Create a buffer for texture coords
  var texcoordBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer)

  // Put texcoords in the buffer
  // prettier-ignore
  var texcoords = [
    0, 0,
    0, 1,
    1, 0,
    1, 0,
    0, 1,
    1, 1
  ]
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(texcoords), gl.STATIC_DRAW)

  // creates a texture info { width: w, height: h, texture: tex }
  // The texture will start with 1x1 pixels and be updated
  // when the image has loaded
  function loadImageAndCreateTextureInfo(url) {
    var tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, tex)
    // Fill the texture with a 1x1 blue pixel.
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      1,
      1,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      new Uint8Array([0, 0, 255, 255])
    )

    // let's assume all images are not a power of 2
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

    var textureInfo = {
      width: 1, // we don't know the size until it loads
      height: 1,
      texture: tex
    }
    var img = new Image()
    img.crossOrigin = ""
    img.addEventListener("load", function () {
      textureInfo.width = img.width
      textureInfo.height = img.height

      gl.bindTexture(gl.TEXTURE_2D, textureInfo.texture)
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img)
    })
    img.src = url

    return textureInfo
  }

  var textureInfos = [
    loadImageAndCreateTextureInfo(
      "https://cache.zoomhub.net/content/0w5YD_files/8/0_0.jpg"
    ),
    loadImageAndCreateTextureInfo(
      "https://cache.zoomhub.net/content/0w5YD_files/7/0_0.jpg"
    ),
    loadImageAndCreateTextureInfo(
      "https://cache.zoomhub.net/content/0w5YD_files/6/0_0.jpg"
    )
  ]

  var drawInfos = []
  var numToDraw = 250
  var speed = 60
  for (var ii = 0; ii < numToDraw; ++ii) {
    var drawInfo = {
      x: Math.random() * gl.canvas.width,
      y: Math.random() * gl.canvas.height,
      dx: Math.random() > 0.5 ? -1 : 1,
      dy: Math.random() > 0.5 ? -1 : 1,
      textureInfo: textureInfos[(Math.random() * textureInfos.length) | 0]
    }
    drawInfos.push(drawInfo)
  }

  function update(deltaTime) {
    drawInfos.forEach(function (drawInfo) {
      drawInfo.x += drawInfo.dx * speed * deltaTime
      drawInfo.y += drawInfo.dy * speed * deltaTime
      if (drawInfo.x < 0) {
        drawInfo.dx = 1
      }
      if (drawInfo.x >= gl.canvas.width) {
        drawInfo.dx = -1
      }
      if (drawInfo.y < 0) {
        drawInfo.dy = 1
      }
      if (drawInfo.y >= gl.canvas.height) {
        drawInfo.dy = -1
      }
    })
  }

  function draw() {
    twgl.resizeCanvasToDisplaySize(gl.canvas)

    // Tell WebGL how to convert from clip space to pixels
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

    gl.clear(gl.COLOR_BUFFER_BIT)

    drawInfos.forEach(function (drawInfo) {
      drawImage(
        drawInfo.textureInfo.texture,
        drawInfo.textureInfo.width,
        drawInfo.textureInfo.height,
        drawInfo.x,
        drawInfo.y
      )
    })
  }

  let then = 0
  function render(time) {
    var now = time * 0.001
    var deltaTime = Math.min(0.1, now - then)
    then = now

    update(deltaTime)
    draw()

    requestAnimationFrame(render)
  }
  requestAnimationFrame(render)

  // Unlike images, textures do not have a width and height associated
  // with them so we'll pass in the width and height of the texture
  function drawImage(tex, texWidth, texHeight, dstX, dstY) {
    gl.bindTexture(gl.TEXTURE_2D, tex)

    // Tell WebGL to use our shader program pair
    gl.useProgram(program)

    // Setup the attributes to pull data from our buffers
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
    gl.enableVertexAttribArray(positionLocation)
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0)
    gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer)
    gl.enableVertexAttribArray(texcoordLocation)
    gl.vertexAttribPointer(texcoordLocation, 2, gl.FLOAT, false, 0, 0)

    // this matrix will convert from pixels to clip space
    var matrix = twgl.m4.ortho(0, gl.canvas.width, gl.canvas.height, 0, -1, 1)

    // this matrix will translate our quad to dstX, dstY
    matrix = twgl.m4.translate(matrix, [dstX, dstY, 0])

    // this matrix will scale our 1 unit quad
    // from 1 unit to texWidth, texHeight units
    matrix = twgl.m4.scale(matrix, [texWidth, texHeight, 1])

    // Set the matrix.
    gl.uniformMatrix4fv(matrixLocation, false, matrix)

    // Tell the shader to get the texture from texture unit 0
    gl.uniform1i(textureLocation, 0)

    // draw the quad (2 triangles, 6 vertices)
    gl.drawArrays(gl.TRIANGLES, 0, 6)
  }
}
main()
