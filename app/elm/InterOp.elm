port module InterOp exposing (..)

import Creature exposing (Creature)
import Json.Encode as Encode exposing (Value)


port toJs : Value -> Cmd msg


port fromJs : (Value -> msg) -> Sub msg


saveCharacter : String -> Creature -> Cmd msg
saveCharacter userId char =
    Encode.object
        [ ( "action", Encode.string "save" )
        , ( "userId", Encode.string userId )
        , ( "character", Creature.encode char )
        ]
        |> toJs
