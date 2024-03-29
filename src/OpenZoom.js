/* @flow */

// --- Helpers -----------------------------------------------------------------

const clamp = (value, min, max) => {
  if (value < min) {
    return min
  }

  if (value > max) {
    return max
  }

  return value
}

// --- Setup -------------------------------------------------------------------

const scene = document.getElementById("image")

if (!(scene instanceof HTMLCanvasElement)) {
  throw new Error("`scene` must be a <canvas>")
}

const context: ?CanvasRenderingContext2D = scene.getContext("2d")

if (!context) {
  throw new Error("Couldn’t instantiate canvas context.")
}

context.fillStyle = "black"
context.fillRect(0, 0, scene.width, scene.height)

// --- State -------------------------------------------------------------------

const history = []
let state = {
  levels: []
}

const getState = () => state
const setState = (newState) => {
  history.push(state)
  state = newState
}

const update = (currentState, action) => {
  switch (action.type) {
    case "imageLoaded": {
      const { image, level: levelIndex } = action.payload
      const newLevels = [...currentState.levels]
      const level = currentState.levels[levelIndex] || {}
      newLevels[levelIndex] = { ...level, image, loaded: true }

      return { ...currentState, levels: newLevels }
    }

    default:
      throw new Error(`Unknown action type: ${action.type}`)
  }
}

// --- Preloading --------------------------------------------------------------

/*eslint-disable no-magic-numbers */
const LEVELS = [0, 1, 2, 3, 4, 5, 6, 7, 8]
/*eslint-enable no-magic-numbers */

LEVELS.forEach((level) => {
  const image = new Image()
  image.src = `http://cache.zoomhub.net/content/0w5YD_files/${level}/0_0.jpg`
  image.onload = () => {
    const newState = update(getState(), {
      type: "imageLoaded",
      payload: { image, level }
    })
    setState(newState)
  }
})

// --- Rendering ---------------------------------------------------------------

const LEVEL_BLEND_DURATION = 100
let lastTimestamp = null
let levelIndex = 0

const step = (timestamp) => {
  if (lastTimestamp === null) {
    lastTimestamp = timestamp
  }

  const elapsedTime = timestamp - lastTimestamp
  const isLevelLoaded =
    state.levels[levelIndex] && state.levels[levelIndex].loaded

  if (isLevelLoaded) {
    const levelImage = state.levels[levelIndex].image
    const alpha = clamp(elapsedTime / LEVEL_BLEND_DURATION, 0, 1)
    context.globalAlpha = alpha

    /*eslint-disable id-length*/
    const sx = 0
    const sy = 0
    const sw = levelImage.width
    const sh = levelImage.height

    const dx = 0
    const dy = 0
    const dw = scene.width
    const dh = scene.height
    /*eslint-enable id-length*/

    context.drawImage(levelImage, sx, sy, sw, sh, dx, dy, dw, dh)

    if (alpha === 1 && levelIndex < LEVELS.length - 1) {
      lastTimestamp = timestamp
      levelIndex += 1
    }
  }

  window.requestAnimationFrame(step)
}

window.requestAnimationFrame(step)
