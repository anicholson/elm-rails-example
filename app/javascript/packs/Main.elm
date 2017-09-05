port module Main exposing (..)

import Html exposing (Html, a, h1, h2, button, p, text, header, footer, table, thead, tbody, tfoot, td, tr, th, div, section, figure, img)
import Html.Attributes exposing (class, alt, src)
import Html.Attributes.Aria exposing (role, ariaLabel)
import Html.Events exposing (onClick)
import Dict exposing (Dict)
import Round


-- MODEL


type alias Cents =
    Int


price : Cents -> String
price cents =
    let
        centsAsFloat =
            Round.round 2 <| toFloat cents / 100.0
    in
        "$" ++ centsAsFloat


type alias Bundle =
    { amount : Int, price : Cents }


type alias Product =
    { name : String, code : String, description : String, prices : List Bundle, imageUrl : Maybe String }


type alias Catalog =
    Dict String Product


type alias OrderSummary =
    { items : List ( Product, Bundle ), total : Cents }


type Order
    = Fillable OrderSummary
    | Unfillable
    | Empty


type alias ReadyState =
    { viewingCart : Bool }


defaultReadyState : ReadyState
defaultReadyState =
    { viewingCart = False }


type AppState
    = Waiting
    | Ready ReadyState


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
            \oldBundles -> ( product, bundle ) :: oldBundles
    in
        case order of
            Unfillable ->
                Unfillable

            Empty ->
                Fillable { items = [ ( product, bundle ) ], total = bundle.price }

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
                    [ button [ class "button is-primary", onClick OpenedCart ]
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

        productPicture =
            Maybe.withDefault "http://bulma.io/images/placeholders/1280x960.png" product.imageUrl
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


cartView : Order -> Html Message
cartView order =
    let
        itemView =
            \( product, bundle ) ->
                tr []
                    [ td [] [ text product.name ]
                    , td [] [ text <| toString bundle.amount ]
                    , td [ class "has-text-right" ] [ text <| price bundle.price ]
                    ]

        itemsView =
            case order of
                Fillable o ->
                    section [ class "modal-card-body" ]
                        [ table [ class "table is-striped is-fullwidth" ]
                            [ thead []
                                [ tr []
                                    [ th [] [ text "Item" ]
                                    , th [] [ text "Qty" ]
                                    , th [ class "has-text-right" ] [ text "Price" ]
                                    ]
                                ]
                            , tbody [] <| List.map itemView o.items
                            , tfoot []
                                [ tr []
                                    [ td [] []
                                    , td [] []
                                    , th [ class "has-text-right" ] [ text <| price o.total ]
                                    ]
                                ]
                            ]
                        ]

                otherwise ->
                    section [ class "modal-card-body" ] [ h1 [ class "subtitle" ] [ text "Your card is currently empty." ] ]

        footerView =
            footer [ class "modal-card-foot" ]
                [ button [ class "button is-success" ] [ text "Buy now!" ]
                , button [ class "button" ] [ text "Clear items" ]
                ]
    in
        div [ class "modal is-active" ]
            [ div [ class "modal-background", onClick ClosedCart ] []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ] [ text "Your Cart" ]
                    , button [ class "delete", ariaLabel "close", onClick ClosedCart ] []
                    ]
                , itemsView
                , footerView
                ]
            , button [ class "modal-close is-large", ariaLabel "close", onClick ClosedCart ] []
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

                Ready state ->
                    let
                        cart =
                            case state.viewingCart of
                                True ->
                                    [ cartView model.currentOrder ]

                                False ->
                                    []
                    in
                        [ headline model
                        , catalogView model.catalog
                        ]
                            ++ cart
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
    | OpenedCart
    | ClosedCart


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
            ( { model | appState = Ready defaultReadyState }, Cmd.none )

        OrderedBundle ( bundle, product ) ->
            let
                b =
                    Debug.log "Ordered bundle:" bundle

                newOrder =
                    Debug.log "Finished order:" <| updateOrder model.currentOrder bundle product
            in
                ( { model | currentOrder = newOrder }, Cmd.none )

        OpenedCart ->
            case model.appState of
                Waiting ->
                    let
                        warning =
                            Debug.log "WARN: OpenedCart event that should not have been possible" ()
                    in
                        ( model, Cmd.none )

                Ready state ->
                    let
                        newAppState =
                            Ready { state | viewingCart = True }
                    in
                        ( { model | appState = newAppState }, Cmd.none )

        ClosedCart ->
            case model.appState of
                Waiting ->
                    let
                        warning =
                            Debug.log "WARN: ClosedCart event that should not have been possible" ()
                    in
                        ( model, Cmd.none )

                Ready state ->
                    let
                        newAppState =
                            Ready { state | viewingCart = False }
                    in
                        ( { model | appState = newAppState }, Cmd.none )

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
