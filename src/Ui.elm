module Ui exposing
    ( Tab(..)
    , asset
    , avatar
    , badge
    , bookCard
    , chip
    , cover
    , header
    , icon
    , shelf
    , tabbar
    )

import Catalog exposing (Author, Catalog, TitlePlacement(..), Work)
import Html exposing (Html, a, div, nav, span, text)
import Html.Attributes exposing (attribute, class, href, src, style)
import Route
import Svg
import Svg.Attributes as SA


asset : String -> String -> String
asset base path =
    base ++ "/" ++ path


type Tab
    = Home
    | Search
    | Shelf
    | Me
    | NoTab


header : String -> Html msg
header base =
    Html.header [ class "top" ]
        [ div [ class "top-row" ]
            [ Route.Index
                |> Route.link [ class "logo" ]
                    [ Html.img [ src (asset base "brand/logo.png"), Html.Attributes.alt "ノベルゲームシェルフ" ] [] ]
            , nav [ class "pcnav" ]
                [ a [ class "on" ] [ text "ホーム" ]
                , a [] [ text "ランキング" ]
                , a [] [ text "新着" ]
                , Route.Guidelines |> Route.link [] [ text "ガイドライン" ]
                ]
            , div [ class "sp" ] []
            , span [ class "coins", Html.Attributes.title "コインはモックです（購入できません）" ] [ icon "coin", text "0" ]
            , span [ class "ic" ] [ icon "search" ]
            , span [ class "ic" ] [ icon "bell" ]
            ]
        , div [ class "tabs" ]
            ([ "おすすめ", "ホラー", "怪談", "ダーク童話", "青春", "5分で読める", "新着" ]
                |> List.indexedMap
                    (\i t ->
                        a
                            [ class
                                (if i == 0 then
                                    "on"

                                 else
                                    ""
                                )
                            ]
                            [ text t ]
                    )
            )
        ]


tabbar : Tab -> Html msg
tabbar active =
    let
        item tab label iconName =
            a
                [ class
                    (if tab == active then
                        "on"

                     else
                        ""
                    )
                ]
                [ icon iconName, text label ]
    in
    nav [ class "tabbar" ]
        [ Route.Index |> Route.link [ class (if active == Home then "on" else "") ] [ icon "home", text "ホーム" ]
        , item Search "さがす" "search"
        , item Shelf "本棚" "shelf"
        , item Me "マイページ" "user"
        ]


cover : String -> Work -> List (Html msg) -> Html msg
cover base work extra =
    let
        c =
            work.cover

        layers =
            List.filterMap identity
                [ c.image |> Maybe.map (\i -> "url(" ++ asset base i ++ ")")
                , c.background
                ]

        bgSize =
            case ( c.image, c.size ) of
                ( Just _, Just s ) ->
                    s ++ ", cover"

                _ ->
                    "cover"

        bgPos =
            Maybe.withDefault "center" c.position ++ ", center"

        titleView =
            case c.title of
                Vertical ->
                    div [ class "tv" ] [ text work.title ]

                Bottom ->
                    div [ class "t" ] [ text work.title ]
    in
    div
        [ class
            (case c.title of
                Vertical ->
                    "cover title-v"

                Bottom ->
                    "cover title-b"
            )
        , style "background-image" (String.join ", " layers)
        , style "background-size" bgSize
        , style "background-position" bgPos
        , style "background-repeat" "no-repeat"
        ]
        (titleView :: extra)


badge : String -> Bool -> Html msg
badge label isNew =
    span
        [ class
            (if isNew then
                "badge new"

             else
                "badge"
            )
        ]
        [ text label ]


bookCard : String -> Catalog -> Maybe ( String, Bool ) -> Work -> Html msg
bookCard base catalog maybeBadge work =
    let
        author =
            Catalog.authorOf catalog work

        priceBadge =
            if Catalog.hasPaid work && Catalog.firstPlayable work /= Nothing then
                Just (span [ class "badge price" ] [ text "1話無料" ])

            else if Catalog.hasPaid work then
                Just (span [ class "badge price" ] [ text "有料" ])

            else
                Nothing

        extra =
            List.filterMap identity
                [ maybeBadge |> Maybe.map (\( l, n ) -> badge l n)
                , priceBadge
                , if work.mock then
                    Just (span [ class "badge mock" ] [ text "モック" ])

                  else
                    Nothing
                ]
    in
    Route.Works__Slug_ { slug = work.slug }
        |> Route.link [ class "book" ]
            [ cover base work extra
            , div [ class "bt" ] [ text work.title ]
            , div [ class "ba" ] [ text author.name ]
            , div [ class "meta" ]
                (case Catalog.nextComing work of
                    Just ep ->
                        [ span [ class "next" ] [ text (Catalog.dateLabel ep.date ++ " " ++ ep.label) ] ]

                    Nothing ->
                        [ span [] [ text ("全" ++ String.fromInt (List.length work.episodes) ++ "話") ]
                        , span [] [ text work.age ]
                        ]
                )
            ]


shelf : String -> String -> List (Html msg) -> Html msg
shelf title more cards =
    Html.section [ class "sec" ]
        [ div [ class "sec-h" ] [ Html.h3 [] [ text title ], a [] [ text more ] ]
        , div [ class "shelf" ] cards
        ]


chip : String -> Html msg
chip label =
    span [ class "chip" ] [ text label ]


avatar : String -> Author -> Html msg
avatar cls author =
    let
        ( c1, c2 ) =
            author.colors
    in
    span
        [ class ("av " ++ cls)
        , style "background" ("linear-gradient(135deg," ++ c1 ++ "," ++ c2 ++ ")")
        ]
        [ text (String.left 1 author.name) ]


icon : String -> Html msg
icon name =
    let
        stroke d =
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2", SA.strokeLinecap "round", SA.strokeLinejoin "round" ]
                (List.map (\p -> Svg.path [ SA.d p ] []) d)

        solid d =
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "currentColor" ] [ Svg.path [ SA.d d ] [] ]
    in
    case name of
        "search" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2" ]
                [ Svg.circle [ SA.cx "11", SA.cy "11", SA.r "7" ] [], Svg.path [ SA.d "M20 20l-3.5-3.5" ] [] ]

        "bell" ->
            stroke [ "M6 8a6 6 0 1112 0c0 7 3 8 3 8H3s3-1 3-8", "M10 20a2 2 0 004 0" ]

        "home" ->
            stroke [ "M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6h-6v6H4a1 1 0 01-1-1z" ]

        "shelf" ->
            stroke [ "M4 4h4v16H4z", "M10 4h4v16h-4z", "M16 5l3.5-1 2 15.5-3.5 1z" ]

        "user" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2" ]
                [ Svg.circle [ SA.cx "12", SA.cy "8", SA.r "4" ] [], Svg.path [ SA.d "M4 21c1-4 4-6 8-6s7 2 8 6" ] [] ]

        "heart" ->
            solid "M12 21s-7.5-4.6-9.5-9.2C1.2 8.6 3.3 5 6.8 5c2 0 3.6 1.1 5.2 3 1.6-1.9 3.2-3 5.2-3 3.5 0 5.6 3.6 4.3 6.8C19.5 16.4 12 21 12 21z"

        "heartO" ->
            stroke [ "M12 21s-7.5-4.6-9.5-9.2C1.2 8.6 3.3 5 6.8 5c2 0 3.6 1.1 5.2 3 1.6-1.9 3.2-3 5.2-3 3.5 0 5.6 3.6 4.3 6.8C19.5 16.4 12 21 12 21z" ]

        "back" ->
            stroke [ "M15 5l-7 7 7 7" ]

        "share" ->
            stroke [ "M12 3v13", "M7 8l5-5 5 5", "M5 14v6h14v-6" ]

        "play" ->
            solid "M7 4l13 8-13 8z"

        "sound" ->
            stroke [ "M4 9h4l5-4v14l-5-4H4z", "M17 8a5 5 0 010 8", "M19.5 5.5a9 9 0 010 13" ]

        "drop" ->
            stroke [ "M12 3s6 7 6 11a6 6 0 01-12 0c0-4 6-11 6-11z" ]

        "flash" ->
            stroke [ "M13 2L4 14h7l-1 8 9-12h-7z" ]

        "clock" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2" ]
                [ Svg.circle [ SA.cx "12", SA.cy "12", SA.r "9" ] [], Svg.path [ SA.d "M12 7v5l3 2" ] [] ]

        "save" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2" ]
                [ Svg.rect [ SA.x "6", SA.y "2", SA.width "12", SA.height "20", SA.rx "2" ] [], Svg.path [ SA.d "M11 18h2" ] [] ]

        "check" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "3" ] [ Svg.path [ SA.d "M5 12l5 5 9-10" ] [] ]

        "chev" ->
            stroke [ "M9 6l6 6-6 6" ]

        "coin" ->
            Svg.svg [ SA.viewBox "0 0 24 24" ]
                [ Svg.circle [ SA.cx "12", SA.cy "12", SA.r "10", SA.fill "#ffc83d", SA.stroke "#b8860b", SA.strokeWidth "2" ] []
                , Svg.circle [ SA.cx "12", SA.cy "12", SA.r "5.5", SA.fill "none", SA.stroke "#b8860b", SA.strokeWidth "1.8" ] []
                ]

        "lock" ->
            Svg.svg [ SA.viewBox "0 0 24 24", SA.fill "none", SA.stroke "currentColor", SA.strokeWidth "2" ]
                [ Svg.rect [ SA.x "5", SA.y "11", SA.width "14", SA.height "10", SA.rx "2" ] [], Svg.path [ SA.d "M8 11V7a4 4 0 018 0v4" ] [] ]

        "external" ->
            stroke [ "M14 4h6v6", "M20 4l-9 9", "M18 14v6H4V6h6" ]

        _ ->
            Svg.svg [ attributeNone ] []


attributeNone : Svg.Attribute msg
attributeNone =
    SA.class ""
