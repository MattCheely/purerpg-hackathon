module Combat exposing (Model, Msg, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import List.Extra as ListX


-- Model


type alias Model =
    { turnHistory : List Attack
    , party : List String
    , turn : Int
    , turnOrder : List Creature
    }


init : Creature -> Model
init player =
    { turnHistory = []
    , party = [ "1234" ]
    , turn = 0
    , turnOrder = [ player, Creature.new Goblin "" ]
    }


getCombatant : Model -> String -> Maybe Creature
getCombatant model id =
    model.turnOrder
        |> List.filter
            (\combatant ->
                combatant.id == id
            )
        |> List.head


updateCombatant : Creature -> Model -> Model
updateCombatant combatant model =
    { model
        | turnOrder =
            ListX.replaceIf
                (\creature ->
                    creature.id == combatant.id
                )
                combatant
                model.turnOrder
    }


activeCreatureId : Model -> Maybe String
activeCreatureId model =
    ListX.getAt model.turn model.turnOrder
        |> Maybe.map .id


isPlayerTurn : Model -> String -> Bool
isPlayerTurn model userId =
    activeCreatureId model == Just userId


inParty : Model -> Creature -> Bool
inParty model creature =
    List.member creature.id model.party


getParty : Model -> List Creature
getParty model =
    List.filter (inParty model) model.turnOrder


getEnemies : Model -> List Creature
getEnemies model =
    List.filter (not << inParty model) model.turnOrder



-- Update


type Msg
    = PlayerAttack String


update : Msg -> Model -> String -> Model
update msg model userId =
    case msg of
        PlayerAttack targetId ->
            -- Handle the player's attack action, then handle any subsequent NPC turns.
            handleAttack userId targetId model
                |> doNPCAttacks


doNPCAttacks : Model -> Model
doNPCAttacks model =
    let
        upcomingNPCs =
            {- To get the NPCs that are up next, we have to start from the current turn
               but also wrap around the list in case we go past the end without hitting a PC
            -}
            List.concat
                [ List.drop model.turn model.turnOrder
                , List.take model.turn model.turnOrder
                ]
                |> ListX.takeWhile Creature.isNPC
    in
    -- Keep updating the model with NPC attacks for all of the upcoming NPCs
    List.foldl doNPCAttack model upcomingNPCs


doNPCAttack : Creature -> Model -> Model
doNPCAttack creature model =
    -- TODO: Randomly select a player
    handleAttack creature.id "1234" model


handleAttack : String -> String -> Model -> Model
handleAttack attackerId victimId model =
    let
        foundAttacker =
            getCombatant model attackerId

        foundVictim =
            getCombatant model victimId
    in
    case ( foundAttacker, foundVictim ) of
        ( Just attacker, Just victim ) ->
            let
                attackResult =
                    Creature.attack attacker victim

                modelWithDamage =
                    model
                        |> updateCombatant attackResult.attacker
                        |> updateCombatant attackResult.victim
            in
            { modelWithDamage
                | turn = (model.turn + 1) % List.length model.turnOrder
                , turnHistory = attackResult :: model.turnHistory
            }

        ( _, _ ) ->
            Debug.log "Who you attacking bro?" model



-- View


view : String -> Model -> Html Msg
view userId model =
    div []
        [ div []
            [ showAllies (getParty model)
            , showEnemies (getEnemies model) (isPlayerTurn model userId)
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
                button [ onClick (PlayerAttack enemy.id) ] [ text "attack!" ]
              else
                text ""
            ]
        ]
