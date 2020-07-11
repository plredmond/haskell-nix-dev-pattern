module Main where

import qualified Test.DocTest

main :: IO ()
main = Test.DocTest.doctest
    [ "./Main.hs"
    , "./lib/"
    ]
