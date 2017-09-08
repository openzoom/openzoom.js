module Main where

import Prelude

import Color (black, toHexString)
import Control.Monad.Eff (Eff, foreachE)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Array (head, (!!))
import Data.Int as Int
import Data.Map as Map
import Data.Map (Map)
import Data.Maybe (fromJust, Maybe(Just, Nothing))
import DOM (DOM)
import Graphics.Canvas (CANVAS)
import Graphics.Canvas as C
import OpenZoom.Types (getVisibleTiles,
                       ImagePyramid(ImagePyramid),
                       ImagePyramidLevel(ImagePyramidLevel),
                       ImagePyramidTile(ImagePyramidTile),
                       Scene, testImage)
import Partial.Unsafe (unsafePartial)
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)

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

newtype ImagePyramidTileData = ImagePyramidTileData
  { alpha :: Number -- [0, 1]
  }

instance showImagePyramidTileData :: Show ImagePyramidTileData where
  show (ImagePyramidTileData x) = "{ alpha: " <> show x.alpha <> " }"

type State =
  { image               :: ImagePyramid
  , tiles               :: Map ImagePyramidTile ImagePyramidTileData
  -- See: https://mdn.io/requestAnimationFrame
  , lastRenderTimestamp :: Number
  , targetLevel         :: Int
  }

mkTile :: Int -> ImagePyramidTile
mkTile level = ImagePyramidTile
  { level
  , bounds: { x: 0, y: 0, width: size, height: size }
  , column: 0
  , row: 0
  }
  where
    size = Int.pow 2 level

mkTileData :: Number -> ImagePyramidTileData
mkTileData alpha = ImagePyramidTileData { alpha }

initialState :: State
initialState =
  { image: testImage
  , tiles:
      Map.insert (mkTile 2) (mkTileData 0.2) $
      Map.insert (mkTile 1) (mkTileData 0.4) $
      Map.insert (mkTile 0) (mkTileData 0.0) Map.empty
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
    let (ImagePyramid image) = state.image
        visibleTiles = getVisibleTiles scene state.image
        firstTile = unsafePartial (fromJust $ head visibleTiles)
        tiles' = Map.update (updateAlpha timestamp) firstTile state.tiles
    in
    state { lastRenderTimestamp = timestamp, tiles = tiles' }
  where
    updateAlpha :: Number -> ImagePyramidTileData -> Maybe ImagePyramidTileData
    updateAlpha timestamp (ImagePyramidTileData tile) =
      let dt = timestamp - state.lastRenderTimestamp
          alpha = clamp 0.0 1.0 (tile.alpha + dt / tileBlendDuration)
      in
      Just (ImagePyramidTileData { alpha })

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
    foreachE tiles \t@(ImagePyramidTile tile) -> do
      case { level: image.levels !! tile.level, tile: Map.lookup t state.tiles } of
        { level: Just (ImagePyramidLevel level), tile: Just (ImagePyramidTileData tile') } -> do
          let scale = scene.width / (Int.toNumber level.width) / 2.0
              offset = Int.toNumber level.index * 8.0
          _ <- C.setGlobalAlpha ctx tile'.alpha
          _ <- C.setFillStyle (toHexString level.color) ctx
          _ <- C.fillRect ctx
                { x: offset + scale * Int.toNumber tile.bounds.x
                , y: offset + scale * Int.toNumber tile.bounds.y
                , w: scale * Int.toNumber tile.bounds.width
                , h: scale * Int.toNumber tile.bounds.height
                }
          pure unit
        _ ->
          -- Draw error
          pure unit
