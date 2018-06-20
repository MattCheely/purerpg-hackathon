module Creature exposing (Attack, Creature, CreatureType(..), attack, decoder, encode, new, showSprite)

import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, style)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (object)
import Random exposing (Seed, step)


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


health : Creature -> Float
health creature =
    if creature.hitPoints < 0 then
        0
    else
        (toFloat creature.hitPoints / toFloat (maxHp creature.creatureType)) * 100


attack : Creature -> Creature -> Seed -> ( Attack, Seed )
attack attacker victim seed =
    let
        damageGenerator =
            case attacker.creatureType of
                Wizard ->
                    Random.int 0 4

                Fighter ->
                    Random.int 0 2

                Goblin ->
                    Random.int 0 1

        ( damage, randomSeed ) =
            step damageGenerator seed
    in
    ( { attacker = attacker
      , victim = { victim | hitPoints = victim.hitPoints - damage }
      , result = Hit damage
      }
    , randomSeed
    )


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
    div [ class "creature" ]
        [ img [ src (creatureImg creature.creatureType) ] []
        , div [ class "creatureStats" ]
            [ img [ class "hpImage", src "images/hp.png" ] []
            , div
                [ class "progressBar" ]
                [ div [ class "progress", style [ ( "width", toString (health creature) ++ "%" ) ] ] []
                ]
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
