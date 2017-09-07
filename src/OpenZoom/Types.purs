module OpenZoom.Types where

import Prelude

import Color (Color, hsl, rgb)
import Data.Array (mapMaybe, concatMap, (!!), (..))
import Data.Maybe (Maybe(Just, Nothing))
import Data.Int as Int
import Math as Math

data ImagePyramid = ImagePyramid
  { width       :: Int
  , height      :: Int
  , tileWidth   :: Int
  , tileHeight  :: Int
  , tileOverlap :: Int
  , levels      :: Array ImagePyramidLevel
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
  { level  :: Int
  , bounds :: Bounds
  , column :: Int
  , row    :: Int
  }

type Rect a =
  { x      :: a
  , y      :: a
  , width  :: a
  , height :: a
  }

type Bounds = Rect Int

type Scene =
  { x      :: Number
  , y      :: Number
  , width  :: Number
  , height :: Number
  , color  :: Color
  }

type Viewport = Rect Number

getVisibleTiles :: Scene -> ImagePyramid -> Array ImagePyramidTile
getVisibleTiles s p@(ImagePyramid image) =
  (flip concatMap) image.levels \(ImagePyramidLevel level) ->
    (flip concatMap) (0..(level.numColumns - 1)) \column ->
      (flip mapMaybe) (0..(level.numRows - 1)) \row ->
        case getTileBounds p level.index column row of
          Just bounds ->
            Just $ ImagePyramidTile
              { level: level.index
              , bounds
              , column
              , row
              }
          Nothing -> Nothing

getTileBounds :: ImagePyramid -> Int -> Int -> Int -> Maybe Bounds
getTileBounds (ImagePyramid image) levelIndex column row =
  case image.levels !! levelIndex of
    Just (ImagePyramidLevel level) ->
      let x = column * image.tileWidth
          y = row * image.tileHeight
          width = clamp 0 (level.width - x) image.tileWidth
          height = clamp 0 (level.height - y) image.tileHeight
      in
      -- Just { x: x + 1, y: y + 1, width: max 0 width - 2, height: max 0 height - 2 }
      Just { x, y, width, height }
    Nothing -> Nothing

-- Test
scene =
  { x: 0.0
  , y: 0.0
  , width: 800.0
  , height: 800.0
  , color: rgb 0 0 0
  }

testImage :: ImagePyramid
testImage =
  let tileSize = 64
      maxLevel = 7
  in
  ImagePyramid
    { width: Int.pow 2 maxLevel
    , height: Int.pow 2 maxLevel
    , tileWidth: tileSize
    , tileHeight: tileSize
    , tileOverlap: 0
    , levels: 0..maxLevel <#> \index ->
        let size = Int.pow 2 index
            value = Int.toNumber $ (index * 20) `mod` 100
            h = Math.floor (100.0 - value) * 120.0 / 100.0
            s = Math.abs (value - 50.0) / 50.0
            l = 0.5
        in
        ImagePyramidLevel
          { index
          , width: size
          , height: size
          , numColumns: Int.ceil (Int.toNumber size / Int.toNumber tileSize)
          , numRows: Int.ceil (Int.toNumber size / Int.toNumber tileSize)
          , color: hsl h s l
          }
    }
