module Combat exposing (Model, Msg, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


-- Model


type alias Model =
    { turnHistory : List ( Int, Attack )
    , players : List String
    , characters :
        { allies : List Creature
        , enemies : List Creature
        }
    , turn : Int
    , turnOrder : List ( Int, Creature )
    }


init : Creature -> Model
init player =
    { turnHistory = []
    , players = [ "1234" ]
    , characters =
        { allies = [ player ]
        , enemies = [ Creature.new Goblin "" ]
        }
    , turn = 0
    , turnOrder = [ ( 0, player ), ( 1, Creature.new Goblin "" ) ]
    }



-- Update


type Msg
    = PlayerAttack Creature


update : Msg -> Model -> Model
update msg model =
    case msg of
        PlayerAttack target ->
            let
                player =
                    List.head (Tuple.second model.turnOrder)

                playerAttackResult =
                    case player of
                        Creature ->
                            Creature.attack player target

                enemyAttackResult =
                    Creature.attack target player

                playerTurn =
                    ( model.turn, playerAttackResult )

                enemyTurn =
                    ( model.turn + 1, enemyAttackResult )
            in
            { model
                | turn = model.turn + 2
                , turnHistory = enemyTurn :: playerTurn :: model.turnHistory
            }



-- View


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ showAllies model.characters.allies
            , showEnemies model.characters.enemies
            ]
        ]


showEnemies : List Creature -> Html Msg
showEnemies enemies =
    div []
        (List.map Creature.showSprite enemies)


showAllies : List Creature -> Html Msg
showAllies allies =
    div []
        (List.map Creature.showSprite allies)


showEnemy : Creature -> Html Msg
showEnemy enemy =
    div []
        [ Creature.showSprite enemy
        , div [] [ button [ onClick PlayerAttack enemy ] [ text "attack!" ] ]
        ]
