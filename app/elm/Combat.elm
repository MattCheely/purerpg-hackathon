module Combat exposing (Model, Msg, init, update, view, encode)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (object)
import Random exposing (Seed, initialSeed)


-- Model


type alias Model =
    { character : Creature
    , enemy : Creature
    , turnActions : List Attack
    , randomSeed : Seed
    }


init : Creature -> Model
init player =
    { character = player
    , enemy = Creature.new Goblin
    , turnActions = []
    , randomSeed = initialSeed 1
    }



-- Update


type Msg
    = PlayerAttack


update : Msg -> Model -> Model
update msg model =
    case msg of
        PlayerAttack ->
            let
                ( playerAttackResult, seed ) =
                    Creature.attack model.character model.enemy model.randomSeed

                ( enemyAttackResult, newSeed ) =
                    Creature.attack playerAttackResult.victim playerAttackResult.attacker seed
            in
            { model
                | character = enemyAttackResult.victim
                , enemy = enemyAttackResult.attacker
                , turnActions = [ playerAttackResult, enemyAttackResult ]
                , randomSeed = newSeed
            }



-- View


view : Model -> Html Msg
view model =
    div []
        [ div [ class "characterDisplay" ]
            [ div [ class "character" ] [ Creature.showSprite model.character ]
            , div [ class "enemy" ] [ Creature.showSprite model.enemy ]
            ]
        , div
            [ class "characterControl" ]
            [ button [ class "attackButton", onClick PlayerAttack ] [ text "attack!" ] ]
        ]


-- Encode/Decode

encode : Model -> Encode.Value
encode model =
    object
        [ ( "character", Creature.encode model.character )
        , ( "enemy", Creature.encode model.enemy )
        ]