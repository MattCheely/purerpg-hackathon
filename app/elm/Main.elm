module Main exposing (main)

import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, img, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick)
import InterOp
import Json.Decode as Decode exposing (Value)


main : Program Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subs
        }



-- Model


type alias Model =
    { userId: String
    , token : String
    , appModel : AppModel
    }


type AppModel
    = SelectingCharacter
    | WithCharacter CombatModel


type alias CombatModel =
    { character : Creature
    , enemy : Creature
    , turnActions : List Attack
    }


init : Value -> ( Model, Cmd Msg )
init config =
    let
        userId =
            Decode.decodeValue (Decode.field "userId" Decode.string) config
                |> Result.withDefault "1234"

        token =
            Decode.decodeValue (Decode.field "token" Decode.string) config
                |> Result.withDefault "1234"

        previousChar =
            Decode.decodeValue (Decode.field "char" Creature.decoder) config

        appModel =
            case previousChar of
                Ok character ->
                    WithCharacter
                        { character = character
                        , enemy = Creature.new Goblin
                        , turnActions = []
                        }

                Err msg ->
                    SelectingCharacter
    in
    ( { userId = userId, token = token, appModel = appModel }
    , Cmd.none
    )



-- Update



type Msg
    = CharacterSelected CreatureType
    | CombatEvent CombatMsg


type CombatMsg
    = PlayerAttack


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( appModel, cmd ) =
            updateApp model.userId msg model.appModel
    in
    ( { model | appModel = appModel }, cmd )


updateApp : String -> Msg -> AppModel -> ( AppModel, Cmd Msg )
updateApp userId msg appModel =
    case ( appModel, msg ) of
        ( SelectingCharacter, CharacterSelected creatureType ) ->
            let
                char =
                    Creature.new creatureType
            in
            ( WithCharacter
                { character = char
                , enemy = Creature.new Goblin
                , turnActions = []
                }
            , InterOp.saveCharacter userId char
            )

        ( WithCharacter combatModel, CombatEvent msg ) ->
            ( WithCharacter (updateCombat msg combatModel), Cmd.none )

        ( _, _ ) ->
            Debug.log "Message & Model mismatch" ( appModel, Cmd.none )


updateCombat : CombatMsg -> CombatModel -> CombatModel
updateCombat msg model =
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
    case model.appModel of
        SelectingCharacter ->
            characterSelectionView

        WithCharacter combatModel ->
            combatView combatModel


characterSelectionView : Html Msg
characterSelectionView =
    div []
        [ div []
            [ text "Choose your character!" ]
        , div [ class "characters" ]
            [ button [ onClick (CharacterSelected Wizard) ] [ text "Wizard!" ]
            , button [ onClick (CharacterSelected Fighter) ] [ text "Fighter!" ]
            ]
        ]


combatView : CombatModel -> Html Msg
combatView model =
    div []
        [ div []
            [ Creature.showSprite model.character
            , Creature.showSprite model.enemy
            ]
        , div [] [ button [ onClick (CombatEvent PlayerAttack) ] [ text "attack!" ] ]
        ]



-- Subscriptions


subs : Model -> Sub Msg
subs model =
    Sub.none
