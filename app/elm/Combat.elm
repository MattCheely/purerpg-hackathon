module Combat exposing (Model, Msg, encode, init, update, view)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, img, text)
import Html.Attributes exposing (class, classList, src, style)
import Html.Events exposing (onClick)
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


init : Creature -> Model
init player =
    { turnHistory = []
    , party = [ player.id ]
    , turn = 0
    , turnOrder = [ player, Creature.new Goblin "" ]
    , status = Ongoing
    , randomSeed = initialSeed 1
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


update : Msg -> Model -> String -> Model
update msg model userId =
    case msg of
        PlayerAttack targetId ->
            -- Handle the player's attack action, then handle any subsequent NPC turns.
            handleAttack userId userId targetId model
                |> doNPCAttacks userId


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
    let
        playerType =
            getCombatant model userId
                |> Maybe.map .creatureType
                |> Maybe.withDefault Fighter
    in
    case model.status of
        Victory ->
            div [ class "victoryDisplay" ]
                [ text "Victory"
                , img [ class "victoryImg", src (victoryImg playerType model.status) ] []
                , div [ class "experience" ]
                    [ text "+10 XP"
                    , div
                        [ class "experienceBar" ]
                        [ text "XP"
                        , div
                            [ class "experienceLevel progressBar" ]
                            [ div [ class "experienceLevel progress", style [ ( "width", "60%" ) ] ] []
                            , div [ class "progress", style [ ( "width", "10%" ) ] ] []
                            ]
                        ]
                    ]
                ]

        Defeat ->
            div [ class "victoryDisplay" ]
                [ text "Defeat"
                , img [ class "victoryImg", src (victoryImg playerType model.status) ] []
                ]

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
            [ div [ class "character" ] [ showAllies (getParty model) ]
            , div [ class "enemies faceLeft" ] [ showEnemies (getEnemies model) (isPlayerTurn model userId) playerType ]
            ]
        ]


showEnemies : List Creature -> Bool -> CreatureType -> Html Msg
showEnemies enemies isPlayerTurn playerType =
    div []
        (List.map (showEnemy isPlayerTurn playerType) enemies)


showAllies : List Creature -> Html Msg
showAllies allies =
    div []
        (List.map Creature.showSprite allies)


victoryImg : CreatureType -> Status -> String
victoryImg creatureType status =
    case creatureType of
        Wizard ->
            case status of
                Victory ->
                    "images/wizard-victory.gif"

                Defeat ->
                    "images/wizard-defeat.gif"

                _ ->
                    ""

        Fighter ->
            case status of
                Victory ->
                    "images/warrior-victory.gif"

                Defeat ->
                    "images/warrior-defeat.gif"

                _ ->
                    ""

        _ ->
            ""


showEnemy : Bool -> CreatureType -> Creature -> Html Msg
showEnemy isPlayerTurn playerType enemy =
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
    baseElement [ Creature.showSprite enemy ]



-- Encode/Decode


encode : Model -> Encode.Value
encode model =
    object
        []
