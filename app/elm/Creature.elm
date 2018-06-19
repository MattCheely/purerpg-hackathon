module Creature exposing (Attack, Creature, CreatureType(..), attack, decoder, encode, new, showSprite)

import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (object)


-- Data


type alias Creature =
    { creatureType : CreatureType
    , hitPoints : Int
    }


type CreatureType
    = Goblin
    | Fighter
    | Wizard


new : CreatureType -> Creature
new creatureType =
    { creatureType = creatureType
    , hitPoints = maxHp creatureType
    }


maxHp : CreatureType -> Int
maxHp class =
    case class of
        Wizard ->
            6

        Fighter ->
            10

        Goblin ->
            5


attack : Creature -> Creature -> Attack
attack attacker victim =
    let
        damage =
            case attacker.creatureType of
                Wizard ->
                    4

                Fighter ->
                    2

                Goblin ->
                    1
    in
    { attacker = attacker
    , victim = { victim | hitPoints = victim.hitPoints - damage }
    , result = Hit damage
    }


type alias Attack =
    { attacker : Creature
    , victim : Creature
    , result : AttackResult
    }


type AttackResult
    = Hit Int
    | Miss



-- Views


showSprite : Creature -> Html msg
showSprite creature =
    div []
        [ img [ src (creatureImg creature.creatureType) ] []
        , div []
            [ text
                (toString creature.creatureType
                    ++ " hp: "
                    ++ toString creature.hitPoints
                )
            ]
        ]


creatureImg : CreatureType -> String
creatureImg class =
    case class of
        Wizard ->
            "images/wizard.png"

        Fighter ->
            "images/fighter.png"

        Goblin ->
            "images/goblin.png"



-- Encode/Decode


encode : Creature -> Encode.Value
encode creature =
    object
        [ ( "creatureType", Encode.string (toString creature.creatureType) )
        , ( "hitPoints", Encode.int creature.hitPoints )
        ]


decoder : Decoder Creature
decoder =
    Decode.map2 Creature
        (Decode.field "creatureType" typeDecoder)
        (Decode.field "hitPoints" Decode.int)


typeDecoder : Decoder CreatureType
typeDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "Fighter" ->
                        Decode.succeed Fighter

                    "Wizard" ->
                        Decode.succeed Wizard

                    "Goblin" ->
                        Decode.succeed Goblin

                    unknown ->
                        Decode.fail ("Unrecognized creature type: " ++ unknown)
            )
