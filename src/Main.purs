module Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Timer (TIMER)
import Data.Maybe (Maybe(Just, Nothing))
import DOM (DOM)
import DOM.HTML.Types (HTMLImageElement)
import Graphics.Canvas as C
import Graphics.Canvas (CANVAS)
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)
import Data.Int (decimal, toStringAs)
-- import Data.Number.Format (toString)

type Level =
  { index :: Int
  , alpha :: Number
  , image :: Maybe HTMLImageElement
  }

defaultLevel :: Level
defaultLevel =
  { index : 0
  , alpha : 0.0
  , image : Nothing
  }

data ImagePyramid = ImagePyramid
  { width :: Int
  , height :: Int
  }

main :: forall eff. Eff (canvas :: CANVAS, console :: CONSOLE, dom :: DOM, timer :: TIMER | eff) Unit
main = do
  _ <- loadImage (defaultLevel { index = 8 })
  mcanvas <- C.getCanvasElementById "scene"
  case mcanvas of
    Just canvas -> do
      context <- C.getContext2D canvas
      frames <- animationFrame
      let app = foldp (const update) initialState frames
      runSignal $ render context <$> app
    Nothing -> pure unit

loadImage :: forall eff. Level -> Eff (canvas :: CANVAS, console :: CONSOLE | eff) Unit
loadImage level = C.tryLoadImage src callback
  where
    src = "http://content.zoomhub.net/dzis/8_files/" <> levelPath <> "/0_0.jpg"
    levelPath = toStringAs decimal level.index
    callback mcanvas =
      case mcanvas of
        Just canvas -> pure unit
        Nothing -> pure unit

type State =
  { levels :: Array Level
  , alpha :: Number
  }

initialState :: State
initialState =
  { levels : []
  , alpha : 0.0
  }

scene ::
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }
scene =
  { x: 0.0
  , y: 0.0
  , width: 800.0
  , height: 800.0
  }

data Action =
    Render
  | ImageLoaded

update :: State -> State
update state = state { alpha = clamp 0.0 1.0 (state.alpha + 0.05) }

render :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
render context state = do
  clearCanvas context
  drawImage context state
  pure unit

clearCanvas :: forall eff. C.Context2D -> Eff (canvas :: CANVAS | eff) Unit
clearCanvas ctx = do
  _ <- C.setFillStyle "#000000" ctx
  _ <- C.fillRect ctx { x: 0.0, y: 0.0, w: scene.width, h: scene.height }
  pure unit

drawImage :: forall eff. C.Context2D -> State -> Eff (canvas :: CANVAS | eff) Unit
drawImage ctx state = do
  _ <- C.setFillStyle "#0088DD" ctx
  _ <- C.setGlobalAlpha ctx state.alpha
  _ <- C.fillRect ctx
        { x: 0.0
        , y: 0.0
        , w: scene.width / 2.0
        , h: scene.height / 2.0
        }
  pure unit
