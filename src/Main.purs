module Main where

import Prelude

-- import Data.Generic.Rep
-- import Data.Generic.Rep.Show (genericShow)
-- import Data.Map (Map)
import Color (black, toHexString)
import Control.Monad.Eff (Eff, foreachE)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Array ((!!))
import Data.Int as Int
import Data.Maybe (Maybe(Just, Nothing))
-- import Debug.Trace (trace, traceShow, traceAny)
import DOM (DOM)
import Graphics.Canvas (CANVAS)
import Graphics.Canvas as C
-- import Math as Math
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)
-- import Signal.Time (every)
import OpenZoom.Types (getVisibleTiles,
                       ImagePyramid(ImagePyramid),
                       ImagePyramidLevel(ImagePyramidLevel),
                       ImagePyramidTile(ImagePyramidTile),
                       Scene, testImage)

-- Main
type CoreEffects = forall eff. Eff (
  canvas :: CANVAS, console :: CONSOLE, dom :: DOM, timer :: TIMER | eff) Unit

main :: CoreEffects
main = do
  -- let frames = every 500.0
  frames <- animationFrame
  mCanvas <- C.getCanvasElementById "scene"
  case mCanvas of
    Just canvas -> do
      context <- C.getContext2D canvas
      let app = foldp (\ts prevState -> update prevState (Render ts)) initialState frames
      runSignal $ render context <$> app
    Nothing -> pure unit

-- Helper
loadImage :: forall eff. ImagePyramidLevel -> Eff (canvas :: CANVAS, console :: CONSOLE | eff) Unit
loadImage (ImagePyramidLevel level) = C.tryLoadImage src callback
  where
    src = "http://content.zoomhub.net/dzis/8_files/" <> levelPath <> "/0_0.jpg"
    levelPath = Int.toStringAs Int.decimal level.index
    callback mCanvas =
      case mCanvas of
        Just canvas -> pure unit
        Nothing -> pure unit

tileBlendDuration :: Number
tileBlendDuration = 500.0

type State =
  { image               :: ImagePyramid
  -- , tileData            :: Map ImagePyramidTile ImagePyramidTileData
  -- See: https://mdn.io/requestAnimationFrame
  , lastRenderTimestamp :: Number
  , levelAlpha          :: Array Number
  , targetLevel         :: Int
  }

initialState :: State
initialState =
  { image: testImage
  , levelAlpha: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  , lastRenderTimestamp: 0.0
  , targetLevel: 0
  }

scene :: Scene
scene =
  { x: 0.0
  , y: 0.0
  , width: 800.0
  , height: 800.0
  , color: black
  }

data Action = Render Number

update :: State -> Action -> State
update state action = case action of
  Render timestamp ->
    let (ImagePyramid image) = state.image in
    state { lastRenderTimestamp = timestamp}
  where
    updateLevelAlpha :: Number -> Int -> Int -> Number -> Number
    updateLevelAlpha timestamp targetIndex index value
      | index == targetIndex =
          clamp 0.0 1.0 (value + (timestamp - state.lastRenderTimestamp) / tileBlendDuration)
      | otherwise = value

render :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
render context state = do
  clearCanvas context
  drawImagePyramid context state
  pure unit

clearCanvas :: forall eff. C.Context2D -> Eff (canvas :: CANVAS | eff) Unit
clearCanvas ctx = do
  _ <- C.setFillStyle (toHexString scene.color) ctx
  _ <- C.fillRect ctx { x: 0.0, y: 0.0, w: scene.width, h: scene.height }
  pure unit

drawImagePyramid :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
drawImagePyramid ctx state = do
    let (ImagePyramid image) = state.image
        tiles = getVisibleTiles scene state.image
    -- traceAny tiles \_ ->
    foreachE tiles \(ImagePyramidTile tile) -> do
      case image.levels !! tile.level of
        Just (ImagePyramidLevel level) -> do
          let scale = scene.width / (Int.toNumber level.width) / 2.0
              offset = Int.toNumber level.index * 2.0
          _ <- C.setGlobalAlpha ctx 0.1
          _ <- C.setFillStyle (toHexString level.color) ctx
          _ <- C.fillRect ctx
                { x: offset + scale * Int.toNumber tile.bounds.x
                , y: offset + scale * Int.toNumber tile.bounds.y
                , w: scale * Int.toNumber tile.bounds.width
                , h: scale * Int.toNumber tile.bounds.height
                }
          pure unit
          -- traceAny tile \_ -> pure unit
        Nothing ->
          pure unit
          -- trace "no level" \_ -> pure unit
