{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_HADDOCK show-extensions #-}

-- |
-- Module      :  Yi.Keymap.Vim.Ex.Commands.Edit
-- License     :  GPL-2
-- Maintainer  :  yi-devel@googlegroups.com
-- Stability   :  experimental
-- Portability :  portable
--
-- Implements quit commands.

module Yi.Keymap.Vim.Ex.Commands.Edit (parse) where

import           Control.Applicative              (Alternative ((<|>)))
import           Control.Monad                    (void, when)
import           Data.Maybe                       (isJust)
import qualified Data.Text                        as T (Text, append, pack, unpack, null)
import qualified Data.Attoparsec.Text             as P (anyChar, many', many1, space, string, try, option)
import           Yi.Editor                        (MonadEditor (withEditor), newTabE)
import           Yi.File                          (openNewFile)
import           Yi.Keymap                        (Action (YiA))
import           Yi.Keymap.Vim.Common             (EventString)
import qualified Yi.Keymap.Vim.Ex.Commands.Common as Common (filenameComplete, impureExCommand, parse)
import           Yi.Keymap.Vim.Ex.Types           (ExCommand (cmdAction, cmdComplete, cmdShow))
import           Yi.Editor                        (printMsg)

parse :: EventString -> Maybe ExCommand
parse = Common.parse $ do
    tab <- P.option Nothing $ Just <$> P.string "tab"
    void $ P.try (P.string "edit") <|> P.string "e"
    void $ P.many1 P.space
    filename <- T.pack <$> P.many' P.anyChar
    return $! edit (isJust tab) filename

edit :: Bool -> T.Text -> ExCommand
edit tab f = Common.impureExCommand {
    cmdShow = showEdit tab f
  , cmdAction = YiA $
        if T.null f
          then printMsg "No file name"
          else do
            when tab $ withEditor newTabE
            openNewFile $ T.unpack f
  , cmdComplete = (fmap . fmap)
                    (showEdit tab) (Common.filenameComplete f)
  }

showEdit :: Bool -> T.Text -> T.Text
showEdit tab f = (if tab then "tab" else "") `T.append` "edit " `T.append` f
