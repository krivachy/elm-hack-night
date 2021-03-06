module Search where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Events exposing (onChange, onEnter)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json exposing ((:=))
import Task
import Signal exposing (message,forwardTo,Address)
import Graphics.Input exposing (clickable)



-- MODEL


type alias Model =
    { query : String
    , albumId : String
    , answers : List Answer
    }


type alias Answer =
    { name : String
    , id: String
    }


init : (Model, Effects Action)
init =
  ( Model "" "" []
  , Effects.none
  )



-- UPDATE


type Action
    = QueryChange String
    | Query
    | RegisterAnswers (Maybe (List Answer))
    | FindTracks String


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    QueryChange newQuery ->
      ( Model newQuery model.albumId model.answers
      , Effects.none
      )

    Query ->
      ( model
      , search model.query
      )

    RegisterAnswers maybeAnswers ->
      ( Model model.query model.albumId (Maybe.withDefault [] maybeAnswers)
      , Effects.none
      )

    FindTracks albumId ->
      ( Model model.query albumId model.answers
      , getTracks albumId
      )



-- VIEW


containerFluid =
  div [class "container-fluid"]


row =
  div [class "row"]


bootstrap =
  node "link"
    [ href "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"
    , rel "stylesheet"
    ]
    []


view : Signal.Address Action -> Model -> Html
view address model =
  div
    [style [("margin", "20px 0")]]
    [ bootstrap
    , containerFluid
        [ inputForm address model
        , resultsList address model
        ]
    ]


inputForm address model =
  input
    [ type' "text"
    , placeholder "Search for an album..."
    , value model.query
    , onChange address QueryChange
    , onEnter address Query
    ]
    []


resultsList address model =
  let
    toEntry answer =
      div
        [class "col-xs-2 col-md-3"]
        [resultView address answer]
  in
    row (List.map toEntry model.answers)


-- resultView : Signal.Address -> Answer -> Html
resultView address answer =
  div [class "panel panel-info"]
      [ div
          [class "panel-heading"]
          [text "Album"]
      , div
          [ class "panel-body"
          , style [("height", "10rem")]
          ]
      [ div
          [onClick address (FindTracks (answer.id))]
          [text answer.name]
          ]
      ]



-- EFFECTS


(=>) = (,)




search : String -> Effects Action
search query =
  Http.get decodeAnswers (searchUrl query)
    |> Task.toMaybe
    |> Task.map RegisterAnswers
    |> Effects.task


searchUrl : String -> String
searchUrl query =
  Http.url "https://api.spotify.com/v1/search"
    [ "q" => query
    , "type" => "album"
    ]

getTracks : String -> Effects Action
getTracks albumId =
  Http.get decodeTracks (tracksUrl albumId)
    |> Task.toMaybe
    |> Task.map RegisterAnswers
    |> Effects.task

tracksUrl : String -> String
tracksUrl albumId =
  Http.url ("https://api.spotify.com/v1/albums/" ++ albumId ++ "/tracks") []

decodeAnswer : Json.Decoder Answer
decodeAnswer =
  Json.object2 Answer
    ("name" := Json.string)
    ("id" := Json.string)

decodeAnswers : Json.Decoder (List Answer)
decodeAnswers =
    Json.at ["albums", "items"] (Json.list decodeAnswer)

decodeTracks : Json.Decoder (List Answer)
decodeTracks =
    Json.at ["items"] (Json.list decodeAnswer)
