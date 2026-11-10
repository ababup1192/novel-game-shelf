module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Catalog exposing (Work)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html, a, div, h2, i, p, span, text)
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
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = BackendTask.succeed {}
        }
        |> RouteBuilder.buildNoState { view = view }


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "ノベルゲームシェルフ"
        , image =
            { url = [ "brand", "mark.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "ノベルゲームシェルフ"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "スマホの縦の画面で遊ぶノベルゲームを、無料で配信する棚。"
        , locale = Nothing
        , title = "ノベルゲームシェルフ"
        }
        |> Seo.website


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    let
        base =
            app.sharedData.base

        catalog =
            app.sharedData.catalog

        playable =
            catalog.works |> List.filter (\w -> not w.mock)

        mocks =
            catalog.works |> List.filter .mock

        card =
            Ui.bookCard base catalog

        badgeOf w =
            if List.member "new" w.tags then
                Just ( "新作", True )

            else if List.member "popular" w.tags then
                Just ( "人気", False )

            else
                Nothing
    in
    { title = "ノベルゲームシェルフ"
    , body =
        [ Ui.header base
        , div [ class "hero" ] (Catalog.withTag "pick" catalog |> List.map (heroCard base))
        , div [ class "dots" ] [ i [ class "on" ] [], i [] [], i [] [] ]
        , div [ class "home-cols" ]
            [ div []
                [ Ui.shelf "今すぐ遊べる" "もっと見る ›" (playable |> List.map (\w -> card (badgeOf w) w))
                , Ui.shelf "5分〜10分で読める" "もっと見る ›" (catalog.works |> List.filter (\w -> w.minutes <= 10) |> List.map (card Nothing))
                , Ui.shelf "近日公開" "カレンダー ›" (comingSoon catalog |> List.map (card Nothing))
                , authorsRow base catalog
                , Ui.shelf "これから（モック）" "" (mocks |> List.map (card Nothing))
                ]
            , div [ class "rank-wrap" ] [ ranking base catalog playable ]
            ]
        , footer
        , Ui.tabbar Ui.Home
        ]
    }


heroCard : String -> Work -> Html msg
heroCard base work =
    let
        art =
            case work.hero of
                Just h ->
                    div
                        [ class "art"
                        , style "background-image" ("url(" ++ Ui.asset base h.image ++ ")")
                        , style "background-position" (Maybe.withDefault "center" h.position)
                        , style "background-size" (Maybe.withDefault "cover" h.size)
                        ]
                        []

                Nothing ->
                    div [ class "art" ] []

        label =
            if List.member "new" work.tags then
                "新作"

            else if List.member "popular" work.tags then
                "人気"

            else
                "おすすめ"
    in
    Route.Works__Slug_ { slug = work.slug }
        |> Route.link [ class "hero-card" ]
            [ art
            , div [ class "txt" ]
                [ span [ class "lbl" ] [ text label ]
                , if Maybe.map .titleInArt work.hero == Just True then
                    text ""

                  else
                    h2 [] [ text work.title ]
                , p [] [ text (String.left 34 work.synopsis ++ "…") ]
                ]
            ]


authorsRow : String -> Catalog.Catalog -> Html msg
authorsRow _ catalog =
    Html.section [ class "sec" ]
        [ div [ class "sec-h" ] [ Html.h3 [] [ text "作者" ], a [] [ text "一覧 ›" ] ]
        , div [ class "authors" ]
            (catalog.authors
                |> List.map
                    (\au ->
                        Route.Authors__Id_ { id = au.id }
                            |> Route.link [ class "au" ] [ Ui.avatar "" au, text au.name ]
                    )
            )
        ]


ranking : String -> Catalog.Catalog -> List Work -> Html msg
ranking base catalog works =
    Html.section [ class "sec" ]
        [ div [ class "sec-h" ] [ Html.h3 [] [ text "ランキング" ], a [] [ text "週間（仮）" ] ]
        , div [ class "rank" ]
            (works
                |> List.indexedMap
                    (\n w ->
                        Route.Works__Slug_ { slug = w.slug }
                            |> Route.link [ class "rank-row" ]
                                [ div [ class ("rank-no r" ++ String.fromInt (n + 1)) ] [ text (String.fromInt (n + 1)) ]
                                , Ui.cover base w []
                                , div [ class "info" ]
                                    [ Html.b [] [ text w.title ]
                                    , div [ class "ba" ] [ text (Catalog.authorOf catalog w).name ]
                                    , div [ class "chips" ] (List.map Ui.chip w.genres)
                                    ]
                                ]
                    )
            )
        ]


comingSoon : Catalog.Catalog -> List Work
comingSoon catalog =
    catalog.works
        |> List.filterMap (\w -> Catalog.nextComing w |> Maybe.map (\e -> ( e.date, w )))
        |> List.sortBy Tuple.first
        |> List.map Tuple.second


footer : Html msg
footer =
    Html.footer [ class "foot" ]
        [ p [ class "mock-pay-foot" ] [ text "有料の話・コインは見た目を確かめるためのモックです。実際の支払いは一切発生しません。" ]
        , Route.Guidelines |> Route.link [] [ text "配信ガイドライン" ]
        , span [] [ text "ノベルゲームシェルフ（試作）" ]
        ]
