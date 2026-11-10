module Catalog exposing
    ( Author
    , Catalog
    , Cover
    , Hero
    , TitlePlacement(..)
    , Warning(..)
    , Work
    , authorOf
    , findAuthor
    , findWork
    , load
    , warningLabel
    , warningNote
    , withTag
    , worksBy
    )

import BackendTask exposing (BackendTask)
import BackendTask.File
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)


type alias Catalog =
    { works : List Work
    , authors : List Author
    }


type alias Work =
    { slug : String
    , title : String
    , author : String
    , genres : List String
    , synopsis : String
    , authorNote : String
    , minutes : Int
    , endings : Int
    , age : String
    , warnings : List Warning
    , cover : Cover
    , hero : Maybe Hero
    , playUrl : Maybe String
    , publishedAt : String
    , tags : List String
    , mock : Bool
    }


type alias Cover =
    { image : Maybe String
    , title : TitlePlacement
    , background : Maybe String
    , position : Maybe String
    , size : Maybe String
    }


type alias Hero =
    { image : String
    , position : Maybe String
    , size : Maybe String
    , titleInArt : Bool
    }


type TitlePlacement
    = Vertical
    | Bottom


type Warning
    = Blood
    | Loud
    | Flash
    | Blade
    | Jumpscare


type alias Author =
    { id : String
    , name : String
    , bio : String
    , colors : ( String, String )
    , mock : Bool
    , news : List { date : String, text : String }
    }


load : BackendTask FatalError Catalog
load =
    BackendTask.map2 Catalog
        (BackendTask.File.jsonFile (Decode.list workDecoder) "content/works.json" |> BackendTask.allowFatal)
        (BackendTask.File.jsonFile (Decode.list authorDecoder) "content/authors.json" |> BackendTask.allowFatal)


findWork : String -> Catalog -> Maybe Work
findWork slug catalog =
    catalog.works |> List.filter (\w -> w.slug == slug) |> List.head


findAuthor : String -> Catalog -> Maybe Author
findAuthor id catalog =
    catalog.authors |> List.filter (\a -> a.id == id) |> List.head


authorOf : Catalog -> Work -> Author
authorOf catalog work =
    findAuthor work.author catalog
        |> Maybe.withDefault
            { id = work.author, name = work.author, bio = "", colors = ( "#777", "#333" ), mock = True, news = [] }


worksBy : String -> Catalog -> List Work
worksBy id catalog =
    catalog.works |> List.filter (\w -> w.author == id)


withTag : String -> Catalog -> List Work
withTag tag catalog =
    catalog.works |> List.filter (\w -> List.member tag w.tags)


warningLabel : Warning -> String
warningLabel w =
    case w of
        Blood ->
            "流血の表現"

        Loud ->
            "大きな音"

        Flash ->
            "画面の点滅"

        Blade ->
            "刃物"

        Jumpscare ->
            "驚かせる演出"


warningNote : Warning -> String
warningNote w =
    case w of
        Loud ->
            "音量を下げてから始めてください。"

        Flash ->
            "光に敏感な方はご注意ください。"

        _ ->
            "苦手な方はご注意ください。"



-- 決まった語の一覧に無い札は、黙って捨てずにビルドを止める（作者の書き間違いが注意の欠けになる）


warningDecoder : Decoder Warning
warningDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "blood" ->
                        Decode.succeed Blood

                    "loud" ->
                        Decode.succeed Loud

                    "flash" ->
                        Decode.succeed Flash

                    "blade" ->
                        Decode.succeed Blade

                    "jumpscare" ->
                        Decode.succeed Jumpscare

                    other ->
                        Decode.fail ("知らない注意の札: " ++ other)
            )


workDecoder : Decoder Work
workDecoder =
    Decode.succeed Work
        |> field "slug" Decode.string
        |> field "title" Decode.string
        |> field "author" Decode.string
        |> field "genres" (Decode.list Decode.string)
        |> field "synopsis" Decode.string
        |> field "authorNote" Decode.string
        |> field "minutes" Decode.int
        |> field "endings" Decode.int
        |> field "age" Decode.string
        |> field "warnings" (Decode.list warningDecoder)
        |> field "cover" coverDecoder
        |> field "hero" (Decode.nullable heroDecoder)
        |> field "playUrl" (Decode.nullable Decode.string)
        |> field "publishedAt" Decode.string
        |> field "tags" (Decode.list Decode.string)
        |> field "mock" Decode.bool


coverDecoder : Decoder Cover
coverDecoder =
    Decode.map5 Cover
        (optional "image" Decode.string)
        (Decode.field "title" Decode.string
            |> Decode.map
                (\s ->
                    if s == "bottom" then
                        Bottom

                    else
                        Vertical
                )
        )
        (optional "background" Decode.string)
        (optional "position" Decode.string)
        (optional "size" Decode.string)


heroDecoder : Decoder Hero
heroDecoder =
    Decode.map4 Hero
        (Decode.field "image" Decode.string)
        (optional "position" Decode.string)
        (optional "size" Decode.string)
        (optional "titleInArt" Decode.bool |> Decode.map (Maybe.withDefault False))


authorDecoder : Decoder Author
authorDecoder =
    Decode.map6 Author
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "bio" Decode.string)
        (Decode.field "colors"
            (Decode.map2 Tuple.pair (Decode.index 0 Decode.string) (Decode.index 1 Decode.string))
        )
        (Decode.field "mock" Decode.bool)
        (Decode.field "news"
            (Decode.list
                (Decode.map2 (\d t -> { date = d, text = t })
                    (Decode.field "date" Decode.string)
                    (Decode.field "text" Decode.string)
                )
            )
        )


field : String -> Decoder a -> Decoder (a -> b) -> Decoder b
field name decoder =
    Decode.map2 (|>) (Decode.field name decoder)


optional : String -> Decoder a -> Decoder (Maybe a)
optional name decoder =
    Decode.maybe (Decode.field name (Decode.nullable decoder))
        |> Decode.map (Maybe.andThen identity)
