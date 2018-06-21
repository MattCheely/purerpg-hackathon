module Combat exposing (Model, Msg, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import List.Extra as ListX


-- Model


type alias Model =
    { turnHistory : List Attack
    , players : List String
    , characters :
        { allies : List Creature
        , enemies : List Creature
        }
    , turn : Int
    , turnOrder : List Creature
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
    , turnOrder = [ player, Creature.new Goblin "" ]
    }


getPlayerCharacter : Model -> String -> Maybe Creature
getPlayerCharacter model userId =
    model.characters.allies
        |> List.filter
            (\character ->
                character.id == userId
            )
        |> List.head


activeCreatureId : Model -> Maybe String
activeCreatureId model =
    ListX.getAt model.turn model.turnOrder
        |> Maybe.map .id


isPlayerTurn : Model -> String -> Bool
isPlayerTurn model userId =
    activeCreatureId model == Just userId



-- Update


type Msg
    = PlayerAttack Creature


update : Msg -> Model -> String -> Model
update msg model userId =
    case msg of
        PlayerAttack target ->
            let
                foundCharacter =
                    getPlayerCharacter model userId
            in
            case foundCharacter of
                Just player ->
                    let
                        playerAttackResult =
                            Creature.attack player target

                        updatedEnemies =
                            ListX.updateIf
                                --currying
                                (Creature.isSame target)
                                (\_ -> playerAttackResult.victim)
                                model.characters.enemies

                        characters =
                            model.characters

                        updatedCharacters =
                            { characters | enemies = updatedEnemies }
                    in
                    { model
                        | turn = (model.turn + 1) % List.length model.turnOrder
                        , turnHistory = playerAttackResult :: model.turnHistory
                        , characters = updatedCharacters
                    }

                Nothing ->
                    Debug.log "Uh, where's your character, dude?" model



-- View


view : String -> Model -> Html Msg
view userId model =
    div []
        [ div []
            [ showAllies model.characters.allies
            , showEnemies model.characters.enemies (isPlayerTurn model userId)
            ]
        ]


showEnemies : List Creature -> Bool -> Html Msg
showEnemies enemies isPlayerTurn =
    div []
        (List.map (showEnemy isPlayerTurn) enemies)


showAllies : List Creature -> Html Msg
showAllies allies =
    div []
        (List.map Creature.showSprite allies)


showEnemy : Bool -> Creature -> Html Msg
showEnemy isPlayerTurn enemy =
    div []
        [ Creature.showSprite enemy
        , div []
            [ if isPlayerTurn then
                button [ onClick (PlayerAttack enemy) ] [ text "attack!" ]
              else
                text ""
            ]
        ]
