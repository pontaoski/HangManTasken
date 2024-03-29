module TreeTest exposing (..)

import Http
import Json.Decode as D
import Json.Encode as E
import Task
import Tree
import Web


type alias Study =
    { tree : Tree.Node Item
    , name : String
    , tasks : List Task
    }


type alias Item =
    { text : String
    }


type alias Task =
    { text : String
    , correctAnswer : Tree.ID
    }


type alias MyTreeTests =
    { tests : List TreeTestOverview
    }


type alias TreeTestOverview =
    { name : String
    , id : String
    }


nullableList : D.Decoder a -> D.Decoder (List a)
nullableList item =
    D.oneOf
        [ D.nullable (D.list item) |> D.map (Maybe.withDefault [])
        , D.null []
        ]


encodeStudy : Study -> E.Value
encodeStudy study =
    E.object
        [ ( "name", E.string study.name )
        , ( "tasks", E.list encodeTask study.tasks )
        , ( "tree", Tree.encodeNode encodeItem study.tree )
        ]


studyDecoder : D.Decoder Study
studyDecoder =
    D.map3 Study
        (D.field "tree" (Tree.nodeDecoder itemDecoder))
        (D.field "name" D.string)
        (D.field "tasks" (nullableList taskDecoder))


itemDecoder : D.Decoder Item
itemDecoder =
    D.map Item
        (D.field "text" D.string)


taskDecoder : D.Decoder Task
taskDecoder =
    D.map2 Task
        (D.field "text" D.string)
        (D.field "correctAnswer" D.string |> D.map Tree.ID)


myTreeTestsDecoder : D.Decoder MyTreeTests
myTreeTestsDecoder =
    D.map MyTreeTests
        (D.field "tests"
            (D.map2 TreeTestOverview
                (D.field "name" D.string)
                (D.field "id" D.string)
                |> nullableList
            )
        )


encodeTask : Task -> E.Value
encodeTask { text, correctAnswer } =
    let
        (Tree.ID nid) =
            correctAnswer
    in
    E.object
        [ ( "text", E.string text )
        , ( "correctAnswer", E.string nid )
        ]


encodeItem : Item -> E.Value
encodeItem { text } =
    E.object
        [ ( "text", E.string text )
        ]


getStudy : String -> (Result Http.Error Study -> msg) -> Cmd msg
getStudy id f =
    Http.get
        { url = Web.host ++ "/viewer/tree-test/" ++ id
        , expect = Http.expectJson f studyDecoder
        }


setStudy : String -> String -> Study -> (Result Http.Error () -> msg) -> Cmd msg
setStudy token id study f =
    Web.patch
        { url = Web.host ++ "/my/tree-tests/" ++ id
        , body = Http.jsonBody <| encodeStudy study
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectWhatever f
        }


myTreeTests : String -> (Result Http.Error MyTreeTests -> msg) -> Cmd msg
myTreeTests token f =
    Web.get
        { url = Web.host ++ "/my/tree-tests"
        , body = Http.emptyBody
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectJson f myTreeTestsDecoder
        }


createTreeTest : String -> String -> (Result Http.Error String -> msg) -> Cmd msg
createTreeTest token name f =
    Web.post
        { url = Web.host ++ "/my/tree-tests"
        , body = Http.jsonBody (E.object [ ( "name", E.string name ) ])
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectJson f D.string
        }

deleteTreeTest : String -> String -> (Result Http.Error () -> msg) -> Cmd msg
deleteTreeTest token id f =
    Web.delete
        { url = Web.host ++ "/my/tree-tests/" ++ id
        , body = Http.emptyBody
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectWhatever f
        }

type alias TreeTestStatistics =
    { medianTime : Float
    , minimumTime : Float
    , maximumTime : Float
    , percentCorrect : Float
    , percentDirect : Float
    , taskStatistics : List TaskStatistics
    , study : Study
    , userCount : Int
    }

type alias TaskStatistics =
    { correctDirect : Int
    , correctIndirect : Int
    , incorrectDirect : Int
    , incorrectIndirect : Int
    }

taskStatisticsDecoder : D.Decoder TaskStatistics
taskStatisticsDecoder =
    D.map4 TaskStatistics
        (D.field "correctDirect" D.int)
        (D.field "correctIndirect" D.int)
        (D.field "incorrectDirect" D.int)
        (D.field "incorrectIndirect" D.int)

treetestStatisticsDecoder : D.Decoder TreeTestStatistics
treetestStatisticsDecoder =
    D.map8 TreeTestStatistics
        (D.field "medianTime" D.float)
        (D.field "minimumTime" D.float)
        (D.field "maximumTime" D.float)
        (D.field "percentCorrect" D.float)
        (D.field "percentDirect" D.float)
        (D.field "taskStatistics" (D.list taskStatisticsDecoder))
        (D.field "study" studyDecoder)
        (D.field "userCount" D.int)

treeTestStatistics : String -> String -> (Result Http.Error TreeTestStatistics -> msg) -> Cmd msg
treeTestStatistics token id f =
    Web.get
        { url = Web.host ++ "/my/tree-tests/" ++ id ++ "/statistics/"
        , body = Http.emptyBody
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectJson f treetestStatisticsDecoder
        }