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
  { x: 0.0
  , step: 10.0
  }

scene ::
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , boxSize :: Number
  }
scene =
  { x: 0.0
  , y: 0.0
  , width: 800.0
  , height: 800.0
  , boxSize: 25.0
  }

update :: State -> State
update state =
  if state.x + scene.boxSize > scene.width then
    { x: scene.width - scene.boxSize
    , step: -state.step
    }
  else if state.x < scene.x then
    { x: scene.x
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
  _ <- C.fillRect ctx { x: 0.0, y: 0.0, w: scene.width, h: scene.height }
  pure unit

drawRect :: forall e. C.Context2D -> State -> Eff (canvas :: C.CANVAS | e) Unit
drawRect ctx state = do
  _ <- C.setFillStyle "#0088DD" ctx
  _ <- C.fillRect ctx
        { x: state.x
        , y: scene.height / 2.0
        , w: scene.boxSize
        , h: scene.boxSize
        }
  pure unit
