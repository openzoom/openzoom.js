module Main where

import Prelude

import Color (black, complementary, toHexString)
import Control.Monad.Eff (Eff, foreachE)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Array (elemIndex, (!!))
import Data.Int as Int
import Data.Map as Map
import Data.Maybe (Maybe(Just, Nothing))
import Debug.Trace (traceAny)
import DOM (DOM)
import Graphics.Canvas (CANVAS)
import Graphics.Canvas as C
-- import Partial.Unsafe (unsafePartial)
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)
-- import Signal.Time (every)

import OpenZoom.Render ( getActiveTiles
                       , ImagePyramidTileState(ImagePyramidTileState)
                       , tileBlendDuration
                       , ImagePyramidTileStates
                       )
import OpenZoom.Types ( ImagePyramid(ImagePyramid)
                      , ImagePyramidLevel(ImagePyramidLevel)
                      , ImagePyramidTile(ImagePyramidTile)
                      , Scene
                      , testImage
                      )

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

type State =
  { image               :: ImagePyramid
  , tiles               :: ImagePyramidTileStates
  , activeTiles         :: Array ImagePyramidTile
  -- See: https://mdn.io/requestAnimationFrame
  , lastRenderTimestamp :: Number
  , targetLevel         :: Int
  }

mkTile :: Int -> ImagePyramidTile
mkTile level = ImagePyramidTile
  { level
  , column: 0
  , row: 0
  , bounds: { x: 0, y: 0, width: size, height: size }
  }
  where
    size = Int.pow 2 level

mkTileState :: Number -> ImagePyramidTileState
mkTileState alpha = ImagePyramidTileState { alpha }

initialState :: State
initialState =
  { image: testImage
  , tiles:
      Map.insert (ImagePyramidTile {level: 7, column: 0, row: 0, bounds: {x: 0, y: 0, width: 64, height: 64}}) (mkTileState 0.0) $
      Map.insert (ImagePyramidTile {level: 7, column: 1, row: 0, bounds: {x: 66, y: 0, width: 64, height: 64}}) (mkTileState 0.0) $
      Map.insert (ImagePyramidTile {level: 7, column: 0, row: 1, bounds: {x: 0, y: 66, width: 64, height: 64}}) (mkTileState 0.0) $
      Map.insert (ImagePyramidTile {level: 7, column: 1, row: 1, bounds: {x: 66, y: 66, width: 88, height: 88}}) (mkTileState 0.0) $
      Map.insert (mkTile 6) (mkTileState 0.0) $
      Map.insert (mkTile 5) (mkTileState 0.0) $
      Map.insert (mkTile 4) (mkTileState 0.0) $
      Map.insert (mkTile 3) (mkTileState 0.0) $
      Map.insert (mkTile 2) (mkTileState 0.0) $
      Map.insert (mkTile 1) (mkTileState 0.0) $
      Map.insert (mkTile 0) (mkTileState 0.0) Map.empty
  , activeTiles: []
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
        activeTiles = getActiveTiles scene state.image state.tiles
        tiles' = Map.mapWithKey (updateAlpha timestamp activeTiles) state.tiles
    in
    -- traceAny activeTiles \_ ->
    state { activeTiles = activeTiles
          , lastRenderTimestamp = timestamp
          , tiles = tiles'
          }
  where
    updateAlpha :: Number ->
                   Array ImagePyramidTile ->
                   ImagePyramidTile ->
                   ImagePyramidTileState ->
                   ImagePyramidTileState
    updateAlpha timestamp tiles tile t@(ImagePyramidTileState tileState) =
      let dt = timestamp - state.lastRenderTimestamp
          alpha = case elemIndex tile tiles of
            (Just _) -> clamp 0.0 1.0 (tileState.alpha + dt / tileBlendDuration)
            _ -> tileState.alpha
      in
      ImagePyramidTileState { alpha }

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
    foreachE state.activeTiles \t@(ImagePyramidTile tile) -> do
      case { level: image.levels !! tile.level, tile: Map.lookup t state.tiles } of
        { level: Just (ImagePyramidLevel level), tile: Just (ImagePyramidTileState tile') } -> do
          let scale = scene.width / (Int.toNumber level.width) / 2.0
              -- offset = Int.toNumber level.index * 8.0
              offset = 0.0
          -- Texture
          _ <- C.setGlobalAlpha ctx tile'.alpha
          _ <- C.setFillStyle (toHexString level.color) ctx
          _ <- C.fillRect ctx
                { x: offset + scale * Int.toNumber tile.bounds.x
                , y: offset + scale * Int.toNumber tile.bounds.y
                , w: scale * Int.toNumber tile.bounds.width
                , h: scale * Int.toNumber tile.bounds.height
                }
          -- Label
          _ <- C.setGlobalAlpha ctx 1.0
          _ <- C.setFont "18px sans-serif" ctx
          _ <- C.setFillStyle (toHexString (complementary level.color)) ctx
          _ <- C.fillText ctx (toLabel t)
                (scale * Int.toNumber tile.bounds.x + 16.0)
                (scale * Int.toNumber tile.bounds.y + 24.0)
          pure unit
        _ ->
          -- Draw error
          pure unit
      where
        toLabel :: ImagePyramidTile -> String
        toLabel (ImagePyramidTile t) = show t.level <> " @ (" <>
          show t.column <> ", " <> show t.row <> ")"
