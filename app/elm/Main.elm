module Main exposing (main)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subs
        }



-- Model


type alias Model =
    { character : Character
    }


type alias Character =
    { class : Class
    , hitPoints : Int
    }


type Class
    = Fighter
    | Wizard


maxHp : Class -> Int
maxHp class =
    case class of
        Wizard ->
            6

        Fighter ->
            10


init : ( Model, Cmd Msg )
init =
    ( { character =
            { class = Wizard
            , hitPoints = maxHp Wizard
            }
      }
    , Cmd.none
    )



-- Update


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    div []
        [ classView model.character.class
        ]


classView : Class -> Html Msg
classView class =
    case class of
        Wizard ->
            text "You're a wizard, Harry!"

        Fighter ->
            text "Conan, what is best in life?!"



-- Subscriptions


subs : Model -> Sub Msg
subs model =
    Sub.none
