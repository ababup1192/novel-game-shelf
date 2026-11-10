module Route.Works.Slug_.Buy.N_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Catalog
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import UrlPath
import View exposing (View)
import WorkPage


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String, n : String }


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = Catalog.load |> BackendTask.map paidPages
        , data = \_ -> BackendTask.succeed {}
        }
        |> RouteBuilder.buildNoState { view = view }


paidPages : Catalog.Catalog -> List RouteParams
paidPages catalog =
    catalog.works
        |> List.concatMap
            (\w ->
                w.episodes
                    |> List.indexedMap Tuple.pair
                    |> List.filter (\( _, e ) -> Catalog.episodeState e == Catalog.Paid e.price)
                    |> List.map (\( i, _ ) -> { slug = w.slug, n = String.fromInt (i + 1) })
            )


lookup : App Data ActionData RouteParams -> Maybe ( Catalog.Work, Catalog.Episode )
lookup app =
    Catalog.findWork app.routeParams.slug app.sharedData.catalog
        |> Maybe.andThen
            (\w ->
                String.toInt app.routeParams.n
                    |> Maybe.andThen (\n -> Catalog.findEpisode n w)
                    |> Maybe.map (Tuple.pair w)
            )


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    case lookup app of
        Just ( work, ep ) ->
            Seo.summary
                { canonicalUrlOverride = Nothing
                , siteName = "ノベルゲームシェルフ"
                , image = { url = [ "brand", "mark.png" ] |> UrlPath.join |> Pages.Url.fromPath, alt = work.title, dimensions = Nothing, mimeType = Nothing }
                , description = work.title ++ " " ++ ep.label ++ "（課金はモック）"
                , locale = Nothing
                , title = work.title ++ " " ++ ep.label ++ " — ノベルゲームシェルフ"
                }
                |> Seo.website

        Nothing ->
            []


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    case lookup app of
        Just ( work, ep ) ->
            { title = work.title ++ " " ++ ep.label ++ " — ノベルゲームシェルフ"
            , body = WorkPage.view app.sharedData.base app.sharedData.catalog work False ++ [ WorkPage.buySheet work ep ]
            }

        Nothing ->
            { title = "見つかりません", body = [ Html.text "話が見つかりません" ] }
