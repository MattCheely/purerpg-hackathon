port module InterOp exposing (..)

import Combat
import Creature exposing (Creature)
import Json.Encode as Encode exposing (Value)


port toJs : Value -> Cmd msg


port fromJs : (Value -> msg) -> Sub msg


saveCharacter : String -> Creature -> Cmd msg
saveCharacter userId char =
    Encode.object
        [ ( "action", Encode.string "saveCharacter" )
        , ( "userId", Encode.string userId )
        , ( "character", Creature.encode char )
        ]
        |> toJs


saveCombat : String -> Combat.Model -> Cmd msg
saveCombat combatId combat =
    Encode.object
        [ ( "action", Encode.string "saveCombat" )
        , ( "combatId", Encode.string combatId )
        , ( "combat", Combat.encode combat )
        ]
        |> toJs


showAchievement : Cmd msg
showAchievement =
    Encode.object
        [ ( "action", Encode.string "showAchievement" )
        , ( "message", Encode.string "Won your first battle" )
        ]
        |> toJs


playSound : String -> Cmd msg
playSound name =
    Encode.object
        [ ( "action", Encode.string "playSound" )
        , ( "sound", Encode.string name )
        ]
        |> toJs
