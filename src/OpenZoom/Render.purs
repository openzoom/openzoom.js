module OpenZoom.Render where

import Prelude

import Data.Array (mapMaybe, concatMap, uncons, (..))
import Data.Foldable (any)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (fromJust, Maybe(Just, Nothing))
import Partial.Unsafe (unsafePartial)

import OpenZoom.Types ( getTileBounds
                      , ImagePyramid(ImagePyramid)
                      , ImagePyramidLevel(ImagePyramidLevel)
                      , ImagePyramidTile(ImagePyramidTile)
                      , Scene
                      )

tileBlendDuration :: Number
tileBlendDuration = 400.0

type ImagePyramidTileStates = Map ImagePyramidTile ImagePyramidTileState

newtype ImagePyramidTileState = ImagePyramidTileState
  { alpha :: Number -- [0, 1]
  }

instance showImagePyramidTileState :: Show ImagePyramidTileState where
  show (ImagePyramidTileState x) = "{ alpha: " <> show x.alpha <> " }"

-- TODO: Compute visibility of tiles:
getActiveTiles :: Scene ->
                  ImagePyramid ->
                  ImagePyramidTileStates ->
                  Array ImagePyramidTile
getActiveTiles scene pyramid@(ImagePyramid image) tiles =
    go scene pyramid image.levels tiles
  where
    go :: Scene ->
          ImagePyramid ->
          Array ImagePyramidLevel ->
          ImagePyramidTileStates ->
          Array ImagePyramidTile
    go _ _ [] _ = []
    go s p levels ts =
      let { head: l, tail: ls } = unsafePartial (fromJust (uncons levels))
          levelTiles = getTilesForLevel p l
          anyTransparent = any (isTransparent ts) levelTiles
      in
      case anyTransparent of
        true -> levelTiles
        false -> levelTiles <> go s p ls ts

    isTransparent :: ImagePyramidTileStates -> ImagePyramidTile ->  Boolean
    isTransparent ts tile =
      case Map.lookup tile ts of
        Just (ImagePyramidTileState s) -> s.alpha < 1.0
        _ -> true

isSingleTileLevel :: ImagePyramidLevel -> Boolean
isSingleTileLevel (ImagePyramidLevel level) =
  level.numColumns == 1 && level.numRows == 1

getTilesForLevel :: ImagePyramid -> ImagePyramidLevel -> Array ImagePyramidTile
getTilesForLevel p (ImagePyramidLevel level) =
  let columns = 0..(level.numColumns - 1)
      rows = 0..(level.numRows - 1)
      forConcat = flip concatMap
      forMaybe = flip mapMaybe
  in
  forConcat columns \column ->
    forMaybe rows \row ->
      case getTileBounds p level.index column row of
        Just bounds ->
          Just $ ImagePyramidTile
            { level: level.index
            , bounds
            , column
            , row
            }
        Nothing -> Nothing
