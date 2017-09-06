module Main where

import Prelude

import Color (Color, rgb, toHexString)
import Control.Monad.Eff (Eff, foreachE)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Array ((!!), findIndex, mapWithIndex)
import Data.Int (decimal, toStringAs, toNumber)
import Data.Maybe (Maybe(Just, Nothing))
import Debug.Trace (traceShow)
import DOM (DOM)
import Graphics.Canvas (CANVAS)
import Graphics.Canvas as C
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)

-- ADTs
data ImagePyramid = ImagePyramid
  { width  :: Int
  , height :: Int
  , tileWidth :: Int
  , tileHeight :: Int
  , tileOverlap :: Int
  , levels :: Array ImagePyramidLevel
  }

data ImagePyramidLevel = ImagePyramidLevel
  { index      :: Int
  , width      :: Int
  , height     :: Int
  , numRows    :: Int
  , numColumns :: Int
  , color      :: Color
  }

data ImagePyramidTile = ImagePyramidTile
  { width  :: Int
  , bounds ::
    { x :: Number
    , y :: Number
    , width :: Number
    , height :: Number
    }
  , row    :: Int
  , column :: Int
  }

-- Main
main :: forall eff. Eff (canvas :: CANVAS, console :: CONSOLE, dom :: DOM, timer :: TIMER | eff) Unit
main = do
  mcanvas <- C.getCanvasElementById "scene"
  case mcanvas of
    Just canvas -> do
      context <- C.getContext2D canvas
      frames <- animationFrame
      let app = foldp (\ts state -> update state Render) initialState frames
      runSignal $ render context <$> app
    Nothing -> pure unit

-- Helper
loadImage :: forall eff. ImagePyramidLevel -> Eff (canvas :: CANVAS, console :: CONSOLE | eff) Unit
loadImage (ImagePyramidLevel level) = C.tryLoadImage src callback
  where
    src = "http://content.zoomhub.net/dzis/8_files/" <> levelPath <> "/0_0.jpg"
    levelPath = toStringAs decimal level.index
    callback mcanvas =
      case mcanvas of
        Just canvas -> pure unit
        Nothing -> pure unit

type State =
  { image      :: ImagePyramid
  , levelAlpha :: Array Number
  }

initialState :: State
initialState =
  { image : ImagePyramid
    { width: 600
    , height: 600
    , tileWidth: 200
    , tileHeight: 200
    , tileOverlap: 0
    , levels:
        [ ImagePyramidLevel
            { index: 0
            , width: 600
            , height: 600
            , numColumns: 3
            , numRows: 3
            , color: rgb 255 128 0
            }
        , ImagePyramidLevel
            { index: 1
            , width: 400
            , height: 400
            , numColumns: 2
            , numRows: 2
            , color: rgb 0 128 255
            }
        , ImagePyramidLevel
            { index: 2
            , width: 200
            , height: 200
            , numColumns: 1
            , numRows: 1
            , color: rgb 0 255 0
            }
        ]
    }
  , levelAlpha: [0.0, 0.0, 0.0]
  }

scene ::
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , color :: Color
  }
scene =
  { x: 0.0
  , y: 0.0
  , width: 800.0
  , height: 800.0
  , color: rgb 0 0 0
  }

data Action =
    Render
  | LoadImage

update :: State -> Action -> State
update state action = traceShow state.levelAlpha $ \_ -> case action of
  Render ->
    -- Find lowest level with alpha < 1.0
    let (ImagePyramid image) = state.image
        mLowestTransparentLevelIndex = findIndex (_ < 1.0) state.levelAlpha in
    case mLowestTransparentLevelIndex of
      Just lowestIndex ->
        state { levelAlpha = mapWithIndex (updateLevelAlpha lowestIndex) state.levelAlpha }
      Nothing ->
        state
  _ -> state
  where
    updateLevelAlpha targetIndex index value
      | index == targetIndex = clamp 0.0 1.0 (value + 0.025)
      | otherwise = value

render :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
render context state = do
  clearCanvas context
  drawImage context state
  pure unit

clearCanvas :: forall eff. C.Context2D -> Eff (canvas :: CANVAS | eff) Unit
clearCanvas ctx = do
  _ <- C.setFillStyle (toHexString scene.color) ctx
  _ <- C.fillRect ctx { x: 0.0, y: 0.0, w: scene.width, h: scene.height }
  pure unit

drawImage :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
drawImage ctx state = do
    let (ImagePyramid image) = state.image
    -- Draw levels from lowest to highest
    foreachE image.levels \(ImagePyramidLevel level) -> do
      case state.levelAlpha !! level.index of
        Just alpha -> do
          _ <- C.setFillStyle (toHexString level.color) ctx
          _ <- C.setGlobalAlpha ctx alpha
          _ <- C.fillRect ctx
                { x: (scene.width - toNumber level.width) / 2.0
                , y: (scene.height - toNumber level.height) / 2.0
                , w: toNumber level.width
                , h: toNumber level.height
                }
          pure unit
        Nothing ->
          pure unit
      pure unit
