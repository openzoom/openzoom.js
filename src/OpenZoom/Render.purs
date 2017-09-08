module OpenZoom.Render where

import Prelude

-- import Data.Array (mapMaybe, concatMap, (!!), (..))
import Data.Maybe (Maybe(Just, Nothing))

import OpenZoom.Types (getTileBounds, ImagePyramid(ImagePyramid),
  ImagePyramidTile(ImagePyramidTile), Scene)

tileBlendDuration :: Number
tileBlendDuration = 2000.0

newtype ImagePyramidTileState = ImagePyramidTileState
  { alpha :: Number -- [0, 1]
  }

instance showImagePyramidTileState :: Show ImagePyramidTileState where
  show (ImagePyramidTileState x) = "{ alpha: " <> show x.alpha <> " }"

getVisibleTiles :: Scene -> ImagePyramid -> Array ImagePyramidTile
getVisibleTiles s p@(ImagePyramid image) =
    case getTileBounds p 0 0 0 of
      Just bounds ->
        [ ImagePyramidTile
            { level: 0
            , bounds
            , column: 0
            , row: 0
            }
        ]
      _ -> []
  -- (flip concatMap) image.levels \(ImagePyramidLevel level) ->
  --   (flip concatMap) (0..(level.numColumns - 1)) \column ->
  --     (flip mapMaybe) (0..(level.numRows - 1)) \row ->
  --       case getTileBounds p level.index column row of
  --         Just bounds ->
  --           Just $ ImagePyramidTile
  --             { level: level.index
  --             , bounds
  --             , column
  --             , row
  --             }
  --         Nothing -> Nothing
