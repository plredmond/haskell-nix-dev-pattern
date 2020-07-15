module Abcexample where

-- https://www.haskell.org/cabal/users-guide/developing-packages.html#accessing-data-files-from-package-code
import qualified Paths_abcexample

-- $setup
-- >>> import Test.QuickCheck

-- |
--
-- >>> 1 + 1
-- 2
--
-- prop> \n -> n * 2 == n + n
--
main :: IO ()
main = do
    putStrLn "Hello world!"
    putStrLn $ "abcexample is " <> show Paths_abcexample.version
