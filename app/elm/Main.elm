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


type Model
    = SelectingCharacter
    | WithCharacter CombatModel


type alias CombatModel =
    { character : Creature
    , enemy : Creature
    , turnActions : List Attack
    }


type alias Creature =
    { creatureType : CreatureType
    , hitPoints : Int
    }


type CreatureType
    = Goblin
    | Fighter
    | Wizard


newCreature : CreatureType -> Creature
newCreature creatureType =
    { creatureType = creatureType
    , hitPoints = maxHp creatureType
    }


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
    ( SelectingCharacter
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
    case ( model, msg ) of
        ( SelectingCharacter, CharacterSelected creatureType ) ->
            ( WithCharacter
                { character = newCreature creatureType
                , enemy = newCreature Goblin
                , turnActions = []
                }
            , Cmd.none
            )

        ( WithCharacter combatModel, CombatEvent msg ) ->
            ( WithCharacter (updateCombat msg combatModel), Cmd.none )

        ( _, _ ) ->
            Debug.log "Message & Model mismatch" ( model, Cmd.none )


updateCombat : CombatMsg -> CombatModel -> CombatModel
updateCombat msg model =
    case msg of
        PlayerAttack ->
            let
                playerAttackResult =
                    doAttack model.character model.enemy

                enemyAttackResult =
                    doAttack playerAttackResult.victim playerAttackResult.attacker
            in
            { model
                | character = enemyAttackResult.victim
                , enemy = enemyAttackResult.attacker
                , turnActions = [ playerAttackResult, enemyAttackResult ]
            }


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
    case model of
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
            [ creatureView model.character.creatureType ]
        , div []
            [ div [] [ text (toString model.character.creatureType ++ " hp: " ++ toString model.character.hitPoints) ]
            , img [ src (creatureImg model.character.creatureType) ] []
            , img [ src (creatureImg model.enemy.creatureType) ] []
            , div [] [ text (toString model.enemy.creatureType ++ " hp: " ++ toString model.enemy.hitPoints) ]
            ]
        , div [] [ button [ onClick (CombatEvent PlayerAttack) ] [ text "attack!" ] ]
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
