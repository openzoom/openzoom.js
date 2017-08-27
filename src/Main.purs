module Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Timer (TIMER)
import Data.Maybe (Maybe(Just, Nothing))
import DOM (DOM)
import Graphics.Canvas as C
import Signal (foldp, runSignal)
import Signal.DOM (animationFrame)

main :: forall e. Eff (canvas :: C.CANVAS, dom :: DOM, timer :: TIMER | e) Unit
main = do
  mcanvas <- C.getCanvasElementById "scene"
  case mcanvas of
    Just canvas -> do
      context <- C.getContext2D canvas
      frames <- animationFrame
      let game = foldp (const update) initialState frames
      runSignal (render context <$> game)
    Nothing -> pure unit

type State =
  { x :: Number
  , step :: Number
  }

initialState :: State
initialState =
  { x : 0.0
  , step : 10.0
  }

update :: State -> State
update state =
  if state.x >= 800.0 then
    { x: 799.0
    , step: -state.step
    }
  else if state.x <= 0.0 then
    { x: 1.0
    , step: -state.step
    }
  else
    { x: state.x + state.step
    , step: state.step
    }

render :: forall e. C.Context2D -> State -> Eff (canvas :: C.CANVAS | e) Unit
render context state = do
  clearCanvas context
  drawRect context state
  pure unit

clearCanvas :: forall e. C.Context2D -> Eff (canvas :: C.CANVAS | e) Unit
clearCanvas ctx = do
  _ <- C.setFillStyle "#000000" ctx
  _ <- C.fillRect ctx { x: 0.0, y: 0.0, w: 800.0, h: 800.0 }
  pure unit

drawRect :: forall e. C.Context2D -> State -> Eff (canvas :: C.CANVAS | e) Unit
drawRect ctx state = do
  _ <- C.setFillStyle "#0088DD" ctx
  _ <- C.fillRect ctx { x: state.pos, y: 400.0, w: 25.0, h: 25.0 }
  pure unit
