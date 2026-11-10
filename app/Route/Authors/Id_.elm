module Route.Authors.Id_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Catalog
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (div, h1, p, small, span, text)
import Html.Attributes exposing (class, style)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import Ui
import UrlPath
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { id : String }


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = Catalog.load |> BackendTask.map (.authors >> List.map (\a -> { id = a.id }))
        , data = \_ -> BackendTask.succeed {}
        }
        |> RouteBuilder.buildNoState { view = view }


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    case Catalog.findAuthor app.routeParams.id app.sharedData.catalog of
        Just author ->
            Seo.summary
                { canonicalUrlOverride = Nothing
                , siteName = "ノベルゲームシェルフ"
                , image = { url = [ "brand", "mark.png" ] |> UrlPath.join |> Pages.Url.fromPath, alt = author.name, dimensions = Nothing, mimeType = Nothing }
                , description = author.bio
                , locale = Nothing
                , title = author.name ++ " — ノベルゲームシェルフ"
                }
                |> Seo.website

        Nothing ->
            []


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    let
        base =
            app.sharedData.base

        catalog =
            app.sharedData.catalog
    in
    case Catalog.findAuthor app.routeParams.id catalog of
        Just author ->
            let
                works =
                    Catalog.worksBy author.id catalog

                ( c1, c2 ) =
                    author.colors
            in
            { title = author.name ++ " — ノベルゲームシェルフ"
            , body =
                [ div [ class "au-banner", style "background" ("linear-gradient(120deg," ++ c1 ++ "," ++ c2 ++ ")") ]
                    [ div [ class "back-row light" ] [ Route.Index |> Route.link [ class "ic" ] [ Ui.icon "back" ] ] ]
                , div [ class "au-head" ]
                    [ Ui.avatar "lg" author
                    , h1 [] [ text author.name ]
                    , p [] [ text author.bio ]
                    , div [ class "au-stats" ]
                        [ span [] [ Html.b [] [ text (String.fromInt (List.length works)) ], text "作品" ]
                        , span [] [ Html.b [] [ text "—" ], text "いいね" ]
                        ]
                    ]
                , Html.section [ class "sec" ]
                    [ div [ class "sec-h" ] [ Html.h3 [] [ text "作品" ] ]
                    , div [ class "grid" ] (List.map (Ui.bookCard base catalog Nothing) works)
                    ]
                , if List.isEmpty author.news then
                    text ""

                  else
                    Html.section [ class "sec" ]
                        [ div [ class "sec-h" ] [ Html.h3 [] [ text "お知らせ" ] ]
                        , div [ class "news" ] (author.news |> List.map (\n -> div [] [ small [] [ text n.date ], text n.text ]))
                        ]
                , Html.section [ class "sec" ]
                    [ div [ class "news" ]
                        [ div [ class "muted" ]
                            [ text "この作者は "
                            , Route.Guidelines |> Route.link [ class "link" ] [ text "配信ガイドライン" ]
                            , text " に同意して作品を配信しています。"
                            ]
                        ]
                    ]
                , Ui.tabbar Ui.NoTab
                ]
            }

        Nothing ->
            { title = "見つかりません", body = [ text "作者が見つかりません" ] }
