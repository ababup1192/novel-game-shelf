module WorkPage exposing (startSheet, view)

{-| 作品の頁と、その上に重ねる「遊ぶ前のシート」。
シートは別の URL（/works/<slug>/start）にして、JS の状態を持たずに静的な頁のまま開け閉めする。
-}

import Catalog exposing (Catalog, Work)
import Html exposing (Html, a, button, div, h1, h2, h4, p, small, span, text)
import Html.Attributes exposing (class, href, rel, style, target)
import Route
import Ui


view : String -> Catalog -> Work -> Bool -> List (Html msg)
view base catalog work withCta =
    let
        author =
            Catalog.authorOf catalog work

        others =
            Catalog.worksBy work.author catalog |> List.filter (\w -> w.slug /= work.slug)

        blurImage =
            case ( work.cover.image, work.cover.background ) of
                ( Just img, _ ) ->
                    "url(" ++ Ui.asset base img ++ ")"

                ( Nothing, Just bg ) ->
                    bg

                _ ->
                    "none"
    in
    [ div [ class "wk-head" ]
        [ div [ class "blur", style "background-image" blurImage ] []
        , div [ class "back-row light" ]
            [ Route.Index |> Route.link [ class "ic" ] [ Ui.icon "back" ]
            , div [ class "sp" ] []
            , span [ class "ic" ] [ Ui.icon "share" ]
            ]
        , div [ class "in" ]
            [ Ui.cover base work []
            , div []
                [ h1 [] [ text work.title ]
                , Route.Authors__Id_ { id = author.id }
                    |> Route.link [ class "by" ] [ Ui.avatar "sm" author, text author.name, Ui.icon "chev" ]
                , div [ class "tags" ] (List.map Ui.chip work.genres)
                ]
            ]
        ]
    , div [ class "stats" ]
        [ stat "—" "いいね"
        , stat ("約" ++ String.fromInt work.minutes ++ "分") "プレイ時間"
        , stat (String.fromInt work.endings) "結末"
        , stat "縦" "画面"
        ]
    , if work.mock then
        div [ class "box mock-note" ] [ text "これはモックの作品です。まだ遊べません。" ]

      else
        text ""
    , div [ class "box" ]
        [ h4 [] [ text "表現について", span [ class "age" ] [ text work.age ] ]
        , if List.isEmpty work.warnings then
            p [ class "muted" ] [ text "注意が必要な表現はありません。" ]

          else
            div [ class "warn-row" ]
                (work.warnings |> List.map (\w -> span [ class "warn" ] [ warningIcon w, text (Catalog.warningLabel w) ]))
        , div [ class "note" ] [ text "音が出ます。イヤホンでの読み進めをおすすめします。" ]
        ]
    , div [ class "box" ] [ h4 [] [ text "あらすじ" ], p [] [ text work.synopsis ] ]
    , div [ class "box" ]
        [ h4 [] [ text "感想" ]
        , p [ class "muted" ] [ text "感想といいねは準備中です（作者だけに届く形で受け付ける予定）。" ]
        ]
    , if List.isEmpty others then
        text ""

      else
        Ui.shelf (author.name ++ " の作品") "" (List.map (Ui.bookCard base catalog Nothing) others)
    , if withCta then
        cta work

      else
        text ""
    ]


stat : String -> String -> Html msg
stat value label =
    div [] [ Html.b [] [ text value ], text label ]


warningIcon : Catalog.Warning -> Html msg
warningIcon w =
    case w of
        Catalog.Loud ->
            Ui.icon "sound"

        Catalog.Flash ->
            Ui.icon "flash"

        _ ->
            Ui.icon "drop"


cta : Work -> Html msg
cta work =
    div [ class "cta" ]
        [ button [ class "btn ghost", Html.Attributes.disabled True ] [ Ui.icon "heartO", text "いいね" ]
        , if work.mock then
            span [ class "btn off" ] [ text "準備中" ]

          else
            Route.Works__Slug___Start { slug = work.slug }
                |> Route.link [ class "btn" ] [ Ui.icon "play", text "無料で遊ぶ" ]
        ]


startSheet : Catalog -> Work -> Html msg
startSheet catalog work =
    let
        author =
            Catalog.authorOf catalog work

        line iconName cls title sub =
            div [ class "li" ]
                [ div [ class ("i " ++ cls) ] [ Ui.icon iconName ]
                , div [] [ Html.b [] [ text title ], span [] [ text sub ] ]
                ]

        warnLines =
            work.warnings
                |> List.map
                    (\w ->
                        div [ class "li" ]
                            [ div [ class "i w" ] [ warningIcon w ]
                            , div [] [ Html.b [] [ text (Catalog.warningLabel w ++ "があります") ], span [] [ text (Catalog.warningNote w) ] ]
                            ]
                    )
    in
    div []
        [ Route.Works__Slug_ { slug = work.slug } |> Route.link [ class "dim" ] []
        , div [ class "sheet" ]
            [ div [ class "grip" ] []
            , h2 [] [ text work.title ]
            , div [ class "subt" ] [ text "はじめる前に" ]
            , div [ class "lst" ]
                (warnLines
                    ++ [ line "sound" "" "音が出ます" "イヤホン推奨・ゲームの設定から音量を変えられます"
                       , line "clock" "" ("約" ++ String.fromInt work.minutes ++ "分・結末 " ++ String.fromInt work.endings) "途中でやめても、続きから遊べます"
                       , line "save" "" "セーブはこの端末に残ります" "別の端末やアプリ版へは引き継げません"
                       ]
                )
            , if String.isEmpty work.authorNote then
                text ""

              else
                div [ class "msg" ] [ text work.authorNote, div [ class "by" ] [ text ("— " ++ author.name ++ "（作者からのひとこと）") ] ]
            , div [ class "chk" ]
                [ span [ class "bx" ] [ Ui.icon "check" ]
                , span []
                    [ text "はじめると "
                    , Route.Guidelines |> Route.link [] [ text "配信ガイドライン" ]
                    , text " に同意したものとします"
                    , Html.br [] []
                    , small [] [ text "ゲームは作品ごとの頁（GitHub Pages）で開きます" ]
                    ]
                ]
            , case work.playUrl of
                Just url ->
                    a [ class "btn wide", href url ] [ Ui.icon "play", text "はじめる" ]

                Nothing ->
                    span [ class "btn wide off" ] [ text "準備中" ]
            ]
        ]
