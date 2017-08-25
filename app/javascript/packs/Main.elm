module Main exposing (..)

import Html exposing (Html, h1, text)
import Html.Attributes exposing (style)

-- MODEL

type alias Model =
  {
  }

-- INIT

init : (Model, Cmd Message)
init =
  (Model, Cmd.none)

-- VIEW

view : Model -> Html Message
view model =
  -- avoid loading additional resources. Use a proper stylesheet when building your own app.
  h1 [style [("display", "flex"), ("justify-content", "center")]]
     [text "Hello Cogent!"]

-- MESSAGE

type Message
  = None

-- UPDATE

update : Message -> Model -> (Model, Cmd Message)
update message model =
  (model, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.none

-- MAIN

main : Program Never Model Message
main =
  Html.program
    {
      init = init,
      view = view,
      update = update,
      subscriptions = subscriptions
    }
