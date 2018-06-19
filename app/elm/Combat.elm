module Combat exposing (Model, Msg, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


-- Model


type alias Model =
    { character : Creature
    , enemy : Creature
    , turnActions : List Attack
    }


init : Creature -> Model
init player =
    { character = player
    , enemy = Creature.new Goblin
    , turnActions = []
    }



-- Update


type Msg
    = PlayerAttack


update : Msg -> Model -> Model
update msg model =
    case msg of
        PlayerAttack ->
            let
                playerAttackResult =
                    Creature.attack model.character model.enemy

                enemyAttackResult =
                    Creature.attack playerAttackResult.victim playerAttackResult.attacker
            in
            { model
                | character = enemyAttackResult.victim
                , enemy = enemyAttackResult.attacker
                , turnActions = [ playerAttackResult, enemyAttackResult ]
            }



-- View


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ Creature.showSprite model.character
            , Creature.showSprite model.enemy
            ]
        , div [] [ button [ onClick PlayerAttack ] [ text "attack!" ] ]
        ]