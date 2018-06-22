module Main exposing (main)

import Combat exposing (Status(..))
import Creature exposing (Attack, Creature, CreatureType(..))
import Html exposing (Html, button, div, img, text, audio)
import Html.Attributes exposing (class, src, id)
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
    , seed : Int
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

        charDecodeResult =
            Decode.decodeValue (Decode.field "char" Creature.decoder) config

        seed =
            Decode.decodeValue (Decode.field "seed" Decode.int) config
                |> Result.withDefault 42

        appModel =
            case charDecodeResult of
                Ok character ->
                    WithCharacter
                        { character = character
                        , route = CharacterView
                        }

                Err msg ->
                    SelectingCharacter
    in
        ( { userId = userId
          , token = token
          , seed = seed
          , appModel = appModel
          }
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
            updateApp model.seed model.userId msg model.appModel
    in
        ( { model | appModel = appModel }, cmd )


updateApp : Int -> String -> Msg -> AppModel -> ( AppModel, Cmd Msg )
updateApp seed userId msg appModel =
    case ( appModel, msg ) of
        ( SelectingCharacter, CharacterSelected creatureType ) ->
            let
                char =
                    Creature.new creatureType userId
            in
                ( WithCharacter
                    { character = char
                    , route = CharacterView
                    }
                , InterOp.saveCharacter userId char
                )

        ( WithCharacter adventureModel, AdventureEvent msg ) ->
            updateAdventure seed userId msg adventureModel
                |> Tuple.mapFirst WithCharacter

        ( _, _ ) ->
            Debug.log "Message & Model mismatch" ( appModel, Cmd.none )


updateAdventure : Int -> String -> AdventureMsg -> AdventureModel -> ( AdventureModel, Cmd Msg )
updateAdventure seed userId msg model =
    let
        ( updatedRoute, cmd ) =
            case ( msg, model.route ) of
                ( GoAdventure, CharacterView ) ->
                    ( CombatView (Combat.init model.character seed), Cmd.none )

                ( CombatEvent combatMsg, CombatView combatModel ) ->
                    let
                        ( newModel, sound ) =
                            Combat.update combatMsg combatModel userId

                        soundCmd =
                            case sound of
                                Just name ->
                                    InterOp.playSound name

                                Nothing ->
                                    Cmd.none
                    in
                        if newModel.status == Victory then
                            ( CombatView newModel, Cmd.batch [ InterOp.showAchievement, soundCmd ] )
                        else
                            ( CombatView newModel, Cmd.batch [ InterOp.saveCombat "asdf" combatModel, soundCmd ] )

                ( _, _ ) ->
                    ( model.route, Cmd.none )
    in
        ( { model | route = updatedRoute }, cmd )



-- View


view : Model -> Html Msg
view model =
    div []
        [ case model.appModel of
            SelectingCharacter ->
                characterSelectionView

            WithCharacter adventureModel ->
                adventureView model.userId adventureModel
        , sounds
        ]


sounds : Html Msg
sounds =
    div []
        [ sound "hit" ]


sound : String -> Html Msg
sound name =
    audio [ id ("sound-" ++ name), src ("sounds/" ++ name ++ ".wav") ] []


characterSelectionView : Html Msg
characterSelectionView =
    div []
        [ div []
            [ text "Choose your character!" ]
        , div [ class "characterSelect" ]
            [ button [ onClick (CharacterSelected Wizard) ]
                [ img [ src "images/wizard.png" ] [] ]
            , button [ onClick (CharacterSelected Fighter) ]
                [ img [ src "images/fighter.png" ] [] ]
            ]
        ]


adventureView : String -> AdventureModel -> Html Msg
adventureView userId model =
    case model.route of
        CharacterView ->
            div []
                [ div [ class "actions" ]
                    [ button [ onClick (AdventureEvent GoAdventure) ] [ text "Adventure!" ]
                    , characterView model.character
                    ]
                ]

        CombatView combatModel ->
            Html.map (AdventureEvent << CombatEvent) (Combat.view userId combatModel)


characterView : Creature -> Html Msg
characterView character =
    Creature.showSprite character



-- Subscriptions


subs : Model -> Sub Msg
subs model =
    Sub.none
