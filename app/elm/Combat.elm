module Combat exposing (Model, Msg, Status(..), encode, init, update, view)

import Creature exposing (Attack, AttackResult(..), Creature, CreatureType(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode exposing (object)
import List.Extra as ListX
import Random exposing (Seed, initialSeed)


-- Model


type alias Model =
    { turnHistory : List Attack
    , party : List String
    , turn : Int
    , turnOrder : List Creature
    , status : Status
    , randomSeed : Seed
    }


type Status
    = Victory
    | Defeat
    | Ongoing


init : Creature -> Int -> Model
init player seed =
    { turnHistory = []
    , party = [ player.id ]
    , turn = 0
    , turnOrder = [ player, Creature.new Goblin "" ]
    , status = Ongoing
    , randomSeed = initialSeed seed
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
    | ClearAttacks String


gameStatus : Model -> String -> Status
gameStatus model userId =
    let
        playerChar =
            getCombatant model userId

        enemies =
            getEnemies model
    in
    case playerChar of
        Just player ->
            if player.hitPoints <= 0 then
                Defeat
            else if List.all (\enemy -> enemy.hitPoints <= 0) enemies then
                Victory
            else
                Ongoing

        Nothing ->
            Defeat


update : Msg -> Model -> String -> ( Model, Maybe String )
update msg model userId =
    case msg of
        PlayerAttack targetId ->
            -- Handle the player's attack action, then handle any subsequent NPC turns.
            let
                newModel =
                    handleAttack userId userId targetId model
                        |> doNPCAttacks userId

                hadHit =
                    List.any
                        (\attack ->
                            case attack.result of
                                Hit _ ->
                                    True

                                Miss ->
                                    False
                        )
                        newModel.turnHistory
            in
            ( newModel
            , if hadHit then
                Just "hit"
              else
                Nothing
            )

        ClearAttacks creatureId ->
            ( { model
                | turnHistory = List.filter (\attack -> attack.victim.id /= creatureId) model.turnHistory
              }
            , Nothing
            )


doNPCAttacks : String -> Model -> Model
doNPCAttacks userId model =
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
    List.foldl (doNPCAttack userId userId) model upcomingNPCs


doNPCAttack : String -> String -> Creature -> Model -> Model
doNPCAttack userId victimId creature model =
    -- TODO: Randomly select a player
    handleAttack userId creature.id victimId model


handleAttack : String -> String -> String -> Model -> Model
handleAttack userId attackerId victimId model =
    let
        foundAttacker =
            getCombatant model attackerId

        foundVictim =
            getCombatant model victimId
    in
    case ( foundAttacker, foundVictim ) of
        ( Just attacker, Just victim ) ->
            let
                ( attackResult, newSeed ) =
                    Creature.attack attacker victim model.randomSeed

                modelWithDamage =
                    model
                        |> updateCombatant attackResult.attacker
                        |> updateCombatant attackResult.victim

                status =
                    gameStatus modelWithDamage userId
            in
            { modelWithDamage
                | turn = (model.turn + 1) % List.length model.turnOrder
                , turnHistory = attackResult :: model.turnHistory
                , randomSeed = newSeed
                , status = status
            }

        ( _, _ ) ->
            Debug.log "Who you attacking bro?" model



-- View


view : String -> Model -> Html Msg
view userId model =
    case model.status of
        Victory ->
            div [] [ text "Victory" ]

        Defeat ->
            div [] [ text "Defeat" ]

        Ongoing ->
            combat model userId


combat : Model -> String -> Html Msg
combat model userId =
    let
        playerType =
            getCombatant model userId
                |> Maybe.map .creatureType
                |> Maybe.withDefault Fighter
    in
    div []
        [ div [ class "characterDisplay" ]
            [ div [ class "character" ]
                [ showAllies (getParty model) model.turnHistory
                ]
            , div [ class "enemies faceLeft" ]
                [ showEnemies (getEnemies model) (isPlayerTurn model userId) playerType model.turnHistory
                ]
            ]
        ]


showEnemies : List Creature -> Bool -> CreatureType -> List Attack -> Html Msg
showEnemies enemies isPlayerTurn playerType attacks =
    div []
        (List.map (showEnemy isPlayerTurn playerType attacks) enemies)


showAllies : List Creature -> List Attack -> Html Msg
showAllies allies attacks =
    div []
        (List.map (showCreature attacks) allies)


showEnemy : Bool -> CreatureType -> List Attack -> Creature -> Html Msg
showEnemy isPlayerTurn playerType attacks enemy =
    let
        attackClass =
            case playerType of
                Wizard ->
                    "spellAttack"

                _ ->
                    "weaponAttack"

        baseElement =
            if isPlayerTurn then
                button [ class ("enemy " ++ attackClass), onClick (PlayerAttack enemy.id) ]
            else
                div [ class "enemy" ]
    in
    baseElement [ showCreature attacks enemy ]


showCreature : List Attack -> Creature -> Html Msg
showCreature attacks creature =
    let
        wasHit =
            attacks
                |> List.any
                    (\attack ->
                        case attack.result of
                            Hit _ ->
                                attack.victim.id == creature.id

                            Miss ->
                                False
                    )
    in
    div
        [ classList [ ( "wasHit", wasHit ) ]
        , onAnimationEnd (ClearAttacks creature.id)
        ]
        [ Creature.showSprite creature ]


onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd msg =
    Html.Events.on "animationend" (Decode.succeed msg)



-- Encode/Decode


encode : Model -> Encode.Value
encode model =
    object
        []
