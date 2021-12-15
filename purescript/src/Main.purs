module Main where

import Prelude

import Color (black, complementary, toHexString)
import Control.Monad.Eff (Eff, foreachE)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Array (head, elemIndex, (!!))
import Data.Int as Int
import Data.Map as Map
import Data.Maybe (Maybe(Just, Nothing))
-- import Debug.Trace (traceAny)
import Data.Tuple (Tuple(Tuple))
import DOM (DOM)
import Graphics.Canvas (CANVAS)
import Graphics.Canvas as C
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)
-- import Signal.Time (every)

import OpenZoom.Render ( getActiveTiles
                       , getUncachedTiles
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
  -- let frames = every (1000.0 / 60.0)
  -- let frames = every 5000.0
  frames <- animationFrame
  mCanvas <- C.getCanvasElementById "scene"
  case mCanvas of
    Just canvas -> do
      context <- C.getContext2D canvas
      let app = foldp step (Tuple initialState None) frames
      runSignal $ (\(Tuple s _) -> render context s) <$> app
    Nothing -> pure unit
  where
    step :: Number -> Tuple State Action -> Tuple State Action
    step ts (Tuple s a) =
      let a' = case a of
                  None -> Render ts
                  _    -> a
      in
      update s a'

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


newtype State = State
  { image               :: ImagePyramid
  , tiles               :: ImagePyramidTileStates
  , activeTiles         :: Array ImagePyramidTile
  -- See: https://mdn.io/requestAnimationFrame
  , lastRenderTimestamp :: Number
  , targetLevel         :: Int
  }

initialState :: State
initialState = State
  { image: testImage
  , tiles:  Map.empty
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

data Action =
    Render Number
  | LoadTile ImagePyramidTile
  | None

update :: State -> Action -> Tuple State Action
update (State state) action = case action of
  Render timestamp ->
    let (ImagePyramid image) = state.image
        activeTiles = getActiveTiles scene state.image state.tiles
        uncachedTiles = getUncachedTiles state.tiles activeTiles
        tiles' = Map.mapWithKey (updateAlpha timestamp activeTiles) state.tiles
        nextAction = case head uncachedTiles of
          Just t -> LoadTile t
          Nothing -> None
    in
    -- traceAny activeTiles \_ ->
    Tuple (State $
           state { activeTiles = activeTiles
                 , lastRenderTimestamp = timestamp
                 , tiles = tiles'
                 }
          ) nextAction
  LoadTile tile ->
    Tuple (State $ state { tiles = Map.insert tile initialTileState state.tiles }) None
  None ->
    Tuple (State state) None
  where
    initialTileState :: ImagePyramidTileState
    initialTileState = ImagePyramidTileState { alpha: 0.0, image: Just true }

    updateAlpha :: Number ->
                   Array ImagePyramidTile ->
                   ImagePyramidTile ->
                   ImagePyramidTileState ->
                   ImagePyramidTileState
    updateAlpha timestamp tiles tile t@(ImagePyramidTileState tileState) =
      let dt = timestamp - state.lastRenderTimestamp
          alpha' = case elemIndex tile tiles of
            (Just _) -> clamp 0.0 1.0 (tileState.alpha + dt / tileBlendDuration)
            _ -> tileState.alpha
      in
      ImagePyramidTileState (tileState { alpha = alpha' })

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
drawImagePyramid ctx (State state) = do
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
