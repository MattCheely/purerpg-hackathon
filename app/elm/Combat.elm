module Combat exposing (Model, Msg, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Random exposing (Seed, initialSeed)


-- Model


type alias Model =
    { character : Creature
    , enemy : Creature
    , status : Status
    , turnActions : List Attack
    , randomSeed : Seed
    }


type Status
    = Victory
    | Defeat
    | Ongoing


init : Creature -> Model
init player =
    { character = player
    , enemy = Creature.new Goblin
    , status = Ongoing
    , turnActions = []
    , randomSeed = initialSeed 1
    }



-- Update


type Msg
    = PlayerAttack


gameStatus : Attack -> Status
gameStatus attack =
    if attack.victim.hitPoints <= 0 then
        Defeat
    else if attack.attacker.hitPoints <= 0 then
        Victory
    else
        Ongoing


update : Msg -> Model -> Model
update msg model =
    case msg of
        PlayerAttack ->
            let
                ( playerAttackResult, seed ) =
                    Creature.attack model.character model.enemy model.randomSeed

                ( enemyAttackResult, newSeed ) =
                    Creature.attack playerAttackResult.victim playerAttackResult.attacker seed

                status =
                    gameStatus enemyAttackResult
            in
            { model
                | character = enemyAttackResult.victim
                , enemy = enemyAttackResult.attacker
                , status = status
                , turnActions = [ playerAttackResult, enemyAttackResult ]
                , randomSeed = newSeed
            }



-- View


view : Model -> Html Msg
view model =
    case model.status of
        Victory ->
            div [] [ text "Victory" ]

        Defeat ->
            div [] [ text "Defeat" ]

        Ongoing ->
            combat model


combat : Model -> Html Msg
combat model =
    div []
        [ div [ class "characterDisplay" ]
            [ div [ class "character" ] [ Creature.showSprite model.character ]
            , div [ class "enemy" ] [ Creature.showSprite model.enemy ]
            ]
        , div
            [ class "characterControl" ]
            [ button [ class "attackButton", onClick PlayerAttack ] [ text "attack!" ] ]
        ]
