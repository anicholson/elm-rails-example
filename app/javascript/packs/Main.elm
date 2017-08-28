port module Main exposing (..)

import Html exposing (Html, h1, h2, p, text, div, section, figure, img)
import Html.Attributes exposing (class, alt, src)
import Dict exposing (Dict)
import Json.Decode exposing (Value)


-- MODEL


type alias Cents =
    Int


type alias Bundle =
    { amount : Int, price : Cents }


type alias Product =
    { name : String, code : String, description : String, prices : List Bundle }


type alias Catalog =
    Dict String Product


type alias LineItem =
    { product : Product, qty : Int }


type alias OrderSummary =
    { items : List LineItem, total : Cents }


type Order
    = Fillable OrderSummary
    | Unfillable
    | Empty


type AppState
    = Waiting
    | Ready


type alias Model =
    { catalog : Maybe Catalog
    , currentOrder : Order
    , appState : AppState
    }



-- INIT


init : ( Model, Cmd Message )
init =
    ( { catalog = Nothing, currentOrder = Empty, appState = Waiting }, Cmd.none )



-- VIEW


productView : Product -> Html Message
productView product =
    div [ class "column" ]
        [ div [ class "card" ]
            [ div [ class "card-image" ]
                [ figure [ class "image is-4by3" ]
                    [ img [ src "http://bulma.io/images/placeholders/1280x960.png", alt product.name ] [] ]
                ]
            , div [ class "card-content" ]
                [ h1 [ class "title" ] [ text product.name ]
                , p [] [ text product.description ]
                ]
            , div [ class "card-footer" ]
                []
            ]
        ]



catalogView : Maybe Catalog -> Html Message
catalogView catalog =
    let
        products =
            \c -> Dict.values c

        productViews =
            List.map productView

        subview =
            case catalog of
                Just c ->
                    productViews <| products c

                Nothing ->
                    [ div [] [] ]
    in
        div [ class "columns" ] subview


view : Model -> Html Message
view model =
    let
        subview =
            case model.appState of
                Waiting ->
                    div [ class "notification is-primary" ] [ text "Loading catalog..." ]

                otherwise ->
                    catalogView model.catalog
    in
        section [ class "section" ]
            [ div [ class "container" ]
                [ h2 [ class "subtitle" ] [ text "Our current seasonal offerings" ]
                , subview
                ]
            ]



-- MESSAGE


type Message
    = None
    | ReceivedRawCatalog (List Product)
    | ReceivedCatalog Catalog
    | Start


port catalog : (List Product -> msg) -> Sub msg



-- UPDATE


processedCatalog : List Product -> Catalog
processedCatalog products =
    let
        catalog =
            Dict.empty

        addEntry =
            \entry -> \c -> Dict.insert entry.code entry c
    in
        List.foldl addEntry catalog products


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        ReceivedRawCatalog raw ->
            let
                newCatalog =
                    processedCatalog raw
            in
                update (ReceivedCatalog newCatalog) model

        ReceivedCatalog c ->
            let
                newModel =
                    { model | catalog = Just c }
            in
                update Start newModel

        Start ->
            ( { model | appState = Ready }, Cmd.none )

        otherwise ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.batch
        [ catalog ReceivedRawCatalog ]



-- MAIN


main : Program Never Model Message
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
