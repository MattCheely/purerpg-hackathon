module Main exposing (main)

import Combat
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
    { userId : String
    , token : String
    , appModel : AppModel
    }


type AppModel
    = SelectingCharacter
    | WithCharacter AdventureModel


type alias AdventureModel =
    { character : Creature
    , route : Route
    }


type Route
    = CharacterView
    | CombatView Combat.Model


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
                        , route = CharacterView
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
    | AdventureEvent AdventureMsg


type AdventureMsg
    = GoAdventure
    | CombatEvent Combat.Msg


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
                , route = CharacterView
                }
            , InterOp.saveCharacter userId char
            )

        ( WithCharacter adventureModel, AdventureEvent msg ) ->
            updateAdventure msg adventureModel
                |> Tuple.mapFirst WithCharacter

        ( _, _ ) ->
            Debug.log "Message & Model mismatch" ( appModel, Cmd.none )


updateAdventure : AdventureMsg -> AdventureModel -> ( AdventureModel, Cmd Msg )
updateAdventure msg model =
    let
        ( updatedRoute, cmd ) =
            case ( msg, model.route ) of
                ( GoAdventure, CharacterView ) ->
                    ( CombatView (Combat.init model.character), Cmd.none )

                ( CombatEvent combatMsg, CombatView combatModel ) ->
                    ( CombatView (Combat.update combatMsg combatModel), InterOp.saveCombat "asdf" combatModel )

                ( _, _ ) ->
                    ( model.route, Cmd.none )
    in
    ( { model | route = updatedRoute }, cmd )



-- View


view : Model -> Html Msg
view model =
    case model.appModel of
        SelectingCharacter ->
            characterSelectionView

        WithCharacter adventureModel ->
            adventureView adventureModel


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


adventureView : AdventureModel -> Html Msg
adventureView model =
    case model.route of
        CharacterView ->
            div []
                [ div [ class "actions" ]
                    [ button [ onClick (AdventureEvent GoAdventure) ] [ text "Adventure!" ]
                    , characterView model.character
                    ]
                ]

        CombatView combatModel ->
            Html.map (AdventureEvent << CombatEvent) (Combat.view combatModel)


characterView : Creature -> Html Msg
characterView character =
    Creature.showSprite character



-- Subscriptions


subs : Model -> Sub Msg
subs model =
    Sub.none
