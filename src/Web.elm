module Web exposing (..)

import Http


host : String
host =
    "https://api.polinpin.blackquill.cc"


requestWithHeaders : String -> { url : String, body : Http.Body, expect : Http.Expect msg, headers : List Http.Header } -> Cmd msg
requestWithHeaders method { url, body, expect, headers } =
    Http.request
        { method = method
        , headers = headers
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


post : { url : String, body : Http.Body, headers : List Http.Header, expect : Http.Expect msg } -> Cmd msg
post params =
    requestWithHeaders "POST" params


get : { url : String, body : Http.Body, headers : List Http.Header, expect : Http.Expect msg } -> Cmd msg
get params =
    requestWithHeaders "GET" params

delete : { url : String, body : Http.Body, headers : List Http.Header, expect : Http.Expect msg } -> Cmd msg
delete params =
    requestWithHeaders "DELETE" params

patch : { url : String, body : Http.Body, headers : List Http.Header, expect : Http.Expect msg } -> Cmd msg
patch params =
    requestWithHeaders "PATCH" params
