module Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Maybe (Maybe(Just, Nothing))
import DOM (DOM)
import Graphics.Canvas as C
import Graphics.Canvas (CANVAS)
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)
import Data.Int (decimal, toStringAs)
import Color (Color, rgb, toHexString)
import Data.Array ((!!))

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
      let app = foldp (const update) initialState frames
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
  { image :: ImagePyramid
  , alpha :: Number
  }

initialState :: State
initialState =
  { image : ImagePyramid
    { width: 400
    , height: 400
    , tileWidth: 200
    , tileHeight: 200
    , tileOverlap: 0
    , levels: [
        ImagePyramidLevel
          { index: 0
          , width: 400
          , height: 400
          , numColumns: 1
          , numRows: 1
          , color: rgb 255 128 0
          }
      ]
    }
  , alpha : 0.0
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

update :: State -> State
update state = state { alpha = clamp 0.0 1.0 (state.alpha + 0.05) }

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
    case image.levels !! 0 of
      (Just (ImagePyramidLevel level)) -> do
        _ <- C.setFillStyle (toHexString level.color) ctx
        _ <- C.setGlobalAlpha ctx state.alpha
        _ <- C.fillRect ctx
              { x: 0.0
              , y: 0.0
              , w: scene.width / 2.0
              , h: scene.height / 2.0
              }
        pure unit
      _ -> pure unit
