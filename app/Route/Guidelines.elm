module Route.Guidelines exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (div, h1, h2, li, p, table, td, text, th, tr, ul)
import Html.Attributes exposing (class)
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
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "ノベルゲームシェルフ"
        , image = { url = [ "brand", "mark.png" ] |> UrlPath.join |> Pages.Url.fromPath, alt = "ノベルゲームシェルフ", dimensions = Nothing, mimeType = Nothing }
        , description = "ノベルゲームシェルフの配信ガイドライン"
        , locale = Nothing
        , title = "配信ガイドライン — ノベルゲームシェルフ"
        }
        |> Seo.website


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view _ _ =
    let
        section title items =
            [ h2 [] [ text title ], ul [] (List.map (\t -> li [] [ text t ]) items) ]
    in
    { title = "配信ガイドライン — ノベルゲームシェルフ"
    , body =
        [ Html.header [ class "top" ]
            [ div [ class "back-row" ] [ Route.Index |> Route.link [ class "ic" ] [ Ui.icon "back" ], text "配信ガイドライン" ] ]
        , div [ class "doc" ]
            ([ h1 [] [ text "配信ガイドライン" ]
             , div [ class "upd" ] [ text "2026 年 11 月 10 日（試作の文面）" ]
             ]
                ++ section "1. 遊ぶ人へ"
                    [ "作品はすべて無料で遊べます。アカウントは要りません。"
                    , "セーブはお使いの端末（ブラウザ）に保存されます。別の端末へは引き継げません。"
                    , "作品ごとの「表現について」を、はじめる前に確認してください。"
                    ]
                ++ [ h2 [] [ text "2. 表現の注意と年齢の目安" ]
                   , table [ class "tbl" ]
                        [ tr [] [ th [] [ text "全年齢" ], td [] [ text "注意が必要な表現なし" ] ]
                        , tr [] [ th [] [ text "12+" ], td [] [ text "驚かせる演出・軽い恐怖" ] ]
                        , tr [] [ th [] [ text "15+" ], td [] [ text "流血・暴力の描写、強い恐怖" ] ]
                        , tr [] [ th [] [ text "18+" ], td [] [ text "このサイトでは配信しません" ] ]
                        ]
                   , p [ class "muted" ] [ text "注意の札: 流血の表現 / 大きな音 / 画面の点滅 / 刃物 / 驚かせる演出（作者が作品ごとに付けます）" ]
                   ]
                ++ section "3. 感想・いいねの決まり（準備中）"
                    [ "感想は作者だけに届きます。人を傷つける言葉は送らないでください。"
                    , "結末の内容（ネタバレ）は書かないでください。"
                    ]
                ++ section "4. 作者の方へ"
                    [ "自作、または使用を許された素材だけを使ってください。出典は作品の中のクレジットに書いてください。"
                    , "表現の注意と年齢の目安を正しく付けてください。"
                    , "実在の人物・団体を傷つける内容、18 歳未満が見てはいけない内容は配信できません。"
                    ]
                ++ section "5. 通報と対応"
                    [ "ガイドラインに反する作品を見つけたら、運営へ知らせてください（窓口は準備中）。"
                    , "確認のうえ、非公開にすることがあります。"
                    ]
            )
        ]
    }
