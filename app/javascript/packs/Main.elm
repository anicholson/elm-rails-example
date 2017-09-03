port module Main exposing (..)

import Html exposing (Html, a, h1, h2, button, p, text, div, section, figure, img)
import Html.Attributes exposing (class, alt, src)
import Html.Attributes.Aria exposing (role)
import Html.Events exposing (onClick)
import Dict exposing (Dict)


-- MODEL


type alias Cents =
    Int


type alias Bundle =
    { amount : Int, price : Cents }


type alias Product =
    { name : String, code : String, description : String, prices : List Bundle, imageUrl: Maybe String }


type alias Catalog =
    Dict String Product


type alias OrderSummary =
    { items : List Bundle, total : Cents }


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


totalForOrder : List Bundle -> Cents
totalForOrder items =
    let
        prices =
            List.map (\item -> item.price) items
    in
        List.sum prices


updateOrder : Order -> Bundle -> Product -> Order
updateOrder order bundle product =
    let
        newBundles =
            \oldBundles -> bundle :: oldBundles
    in
        case order of
            Unfillable ->
                Unfillable

            Empty ->
                Fillable { items = [ bundle ], total = bundle.price }

            Fillable o ->
                let
                    newOrder =
                        { items = newBundles o.items, total = o.total + bundle.price }
                in
                    Fillable newOrder



-- INIT


init : ( Model, Cmd Message )
init =
    ( { catalog = Nothing, currentOrder = Empty, appState = Waiting }, Cmd.none )



-- VIEW


header : Html Never
header =
    section [ class "hero is-dark" ]
        [ div [ class "hero-body" ]
            [ section [ class "container" ]
                [ h1 [ class "title" ] [ text "My wonderful flower shop" ]
                ]
            ]
        ]


itemCount : Order -> Int
itemCount order =
    case order of
        Fillable summary ->
            List.length summary.items

        otherwise ->
            0


headline : Model -> Html Message
headline model =
    let
        displayCart =
            case model.currentOrder of
                Fillable _ ->
                    True

                otherwise ->
                    False

        leftSection =
            div [ class "level-left" ]
                [ div [ class "level-item" ] [ h2 [ class "subtitle" ] [ text "Our current seasonal offerings" ] ] ]

        rightSection =
            div [ class "level-right" ]
                [ div [ class "level-item" ]
                    [ button [ class "button is-primary" ]
                        [ text <| "Cart (" ++ (toString <| itemCount model.currentOrder) ++ ")"
                        ]
                    ]
                ]

        subview =
            if displayCart then
                [ leftSection, rightSection ]
            else
                [ leftSection ]
    in
        div [ class "level" ] subview


productView : Product -> Html Message
productView product =
    let
        purchaseButton =
            \bundle ->
                a [ class "card-footer-item is-primary", role "button", onClick (OrderedBundle ( bundle, product )) ] [ text (toString bundle.amount) ]

        purchaseButtons =
            List.map purchaseButton product.prices

        productPicture = Maybe.withDefault "http://bulma.io/images/placeholders/1280x960.png" product.imageUrl
    in
        div [ class "column" ]
            [ div [ class "card" ]
                [ div [ class "card-image" ]
                    [ figure [ class "image is-4by3" ]
                        [ img [ src productPicture, alt product.name ] [] ]
                    ]
                , div [ class "card-content" ]
                    [ h1 [ class "title" ] [ text product.name ]
                    , p [] [ text product.description ]
                    ]
                , div [ class "card-footer" ] purchaseButtons
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
                    [ div [ class "notification is-primary" ] [ text "Loading catalog..." ] ]

                otherwise ->
                    [ headline model
                    , catalogView model.catalog
                    ]
    in
        section [ class "section" ]
            [ div [ class "container" ] subview
            ]



-- MESSAGE


type Message
    = None
    | ReceivedRawCatalog (List Product)
    | ReceivedCatalog Catalog
    | Start
    | OrderedBundle ( Bundle, Product )


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

        OrderedBundle ( bundle, product ) ->
            let
                b =
                    Debug.log "Ordered bundle:" bundle

                newOrder =
                    Debug.log "Finished order:" <| updateOrder model.currentOrder bundle product
            in
                ( { model | currentOrder = newOrder }, Cmd.none )

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
