module Main exposing (main)

import Html exposing (Html, button, div, img, text)
import Html.Attributes exposing (class, src)
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
    { character : Creature
    , enemy : Creature
    , lastAttack : Maybe Attack
    }


type alias Creature =
    { creatureType : CreatureType
    , hitPoints : Int
    }


type CreatureType
    = Goblin
    | Fighter
    | Wizard


maxHp : CreatureType -> Int
maxHp class =
    case class of
        Wizard ->
            6

        Fighter ->
            10

        Goblin ->
            5


type alias Attack =
    { attacker : Creature
    , victim : Creature
    , result : AttackResult
    }


type AttackResult
    = Hit Int
    | Miss


init : ( Model, Cmd Msg )
init =
    ( { character =
            { creatureType = Wizard
            , hitPoints = maxHp Wizard
            }
      , enemy =
            { creatureType = Goblin
            , hitPoints = maxHp Goblin
            }
      , lastAttack = Nothing
      }
    , Cmd.none
    )



-- Update


type Msg
    = PlayerAttack


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayerAttack ->
            let
                attackResult =
                    doAttack model.character model.enemy
            in
            ( { model
                | character = attackResult.attacker
                , enemy = attackResult.victim
                , lastAttack = Just attackResult
              }
            , Cmd.none
            )


doAttack : Creature -> Creature -> Attack
doAttack attacker victim =
    let
        damage =
            case attacker.creatureType of
                Wizard ->
                    4

                Fighter ->
                    2

                Goblin ->
                    1
    in
    { attacker = attacker
    , victim = { victim | hitPoints = victim.hitPoints - damage }
    , result = Hit damage
    }



-- View


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ creatureView model.character.creatureType ]
        , div []
            [ div [] [ text (toString model.character.creatureType ++ " hp: " ++ toString model.character.hitPoints) ]
            , img [ src (creatureImg model.character.creatureType) ] []
            , img [ src (creatureImg model.enemy.creatureType) ] []
            , div [] [ text (toString model.enemy.creatureType ++ " hp: " ++ toString model.enemy.hitPoints) ]
            ]
        , div [] [ button [ onClick PlayerAttack ] [ text "attack!" ] ]
        ]


creatureView : CreatureType -> Html Msg
creatureView creature =
    case creature of
        Wizard ->
            text "You're a wizard, Harry!"

        Fighter ->
            text "Conan, what is best in life?!"

        Goblin ->
            text "Splork smash!"


creatureImg : CreatureType -> String
creatureImg class =
    case class of
        Wizard ->
            "images/wizard.png"

        Fighter ->
            "images/fighter.png"

        Goblin ->
            "images/goblin.png"



-- Subscriptions


subs : Model -> Sub Msg
subs model =
    Sub.none
