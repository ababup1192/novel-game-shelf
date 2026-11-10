module Route.Works.Slug_ exposing (ActionData, Data, Model, Msg, route)

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
    { slug : String }


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = Catalog.load |> BackendTask.map (.works >> List.map (\w -> { slug = w.slug }))
        , data = \_ -> BackendTask.succeed {}
        }
        |> RouteBuilder.buildNoState { view = view }


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    case Catalog.findWork app.routeParams.slug app.sharedData.catalog of
        Just work ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = "ノベルゲームシェルフ"
                , image =
                    { url = work.cover.image |> Maybe.withDefault "brand/mark.png" |> String.split "/" |> UrlPath.join |> Pages.Url.fromPath
                    , alt = work.title
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = work.synopsis
                , locale = Nothing
                , title = work.title ++ " — ノベルゲームシェルフ"
                }
                |> Seo.website

        Nothing ->
            []


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    case Catalog.findWork app.routeParams.slug app.sharedData.catalog of
        Just work ->
            { title = work.title ++ " — ノベルゲームシェルフ"
            , body = WorkPage.view app.sharedData.base app.sharedData.catalog work True
            }

        Nothing ->
            { title = "見つかりません", body = [ Html.text "作品が見つかりません" ] }
