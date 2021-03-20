module FileValue exposing
    ( File, decoder, encode
    , hiddenInputSingle, hiddenInputMultiple
    , onDrop, DropConfig
    )

{-|


# Files

@docs File, decoder, encode


# Load files with an input

@docs hiddenInputSingle, hiddenInputMultiple


# Drop files

@docs onDrop, DropConfig

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Time


{-| Represents an uploaded file with its metadata.

The file is store as its raw JavaScript value.
If needed, it is possible to convert it to the `File`
type defined in [`elm/type`](/packages/elm/file)
simply by using the decoder defined there on the `value` field here.

-}
type alias File =
    { value : Value
    , name : String
    , mime : String
    , size : Int
    , lastModified : Time.Posix
    }


{-| Decode `File` values.
-}
decoder : Decoder File
decoder =
    Decode.map5 File
        Decode.value
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "size" Decode.int)
        (Decode.map Time.millisToPosix (Decode.field "lastModified" Decode.int))


{-| Encode a `File`.
-}
encode : File -> Value
encode file =
    file.value



-- Select


{-| A hidden file input to load a single file.
To use it, add a visible label linked to this input by its id.

    type Msg
        = LoadData File

    view _ =
        div []
            [ hiddenInputSingle "TheFileInput" [ "text/csv" ] LoadData
            , label [ for "TheFileInput" ] [ text "click to load data" ]
            ]

-}
hiddenInputSingle : String -> List String -> (File -> msg) -> Html msg
hiddenInputSingle id mimes msgTag =
    Html.input (loadFile msgTag :: inputAttributes id mimes) []


{-| A hidden file input to load multiple files.
To use it, add a visible label linked to this input by its id.

    type Msg
        = LoadImages File (List File)

    view _ =
        div []
            [ hiddenInputMultiple "TheFileInput" [ "image/*" ] LoadImages
            , label [ for "TheFileInput" ] [ text "click to load the images" ]
            ]

-}
hiddenInputMultiple : String -> List String -> (File -> List File -> msg) -> Html msg
hiddenInputMultiple id mimes msgTag =
    Html.input (loadMultipleFiles msgTag :: Html.Attributes.multiple True :: inputAttributes id mimes) []


inputAttributes : String -> List String -> List (Html.Attribute msg)
inputAttributes id mimes =
    [ Html.Attributes.id id
    , Html.Attributes.type_ "file"
    , Html.Attributes.style "display" "none"
    , Html.Attributes.accept (String.join "," mimes)
    ]


loadFile : (File -> msg) -> Html.Attribute msg
loadFile msgTag =
    Decode.at [ "target", "files", "0" ] decoder
        |> Decode.map (\file -> { message = msgTag file, stopPropagation = True, preventDefault = True })
        |> Html.Events.custom "change"


loadMultipleFiles : (File -> List File -> msg) -> Html.Attribute msg
loadMultipleFiles msgTag =
    Decode.at [ "target", "files" ] multipleFilesDecoder
        |> Decode.map (\( file, list ) -> { message = msgTag file list, stopPropagation = True, preventDefault = True })
        |> Html.Events.custom "change"



-- Drop files


{-| Create attributes for a file dropping area.
-}
onDrop : DropConfig msg -> List (Html.Attribute msg)
onDrop config =
    filesOn "dragover" config.onOver
        :: filesOn "drop" config.onDrop
        :: (case config.onLeave of
                Nothing ->
                    []

                Just { id, msg } ->
                    [ Html.Attributes.id id
                    , onWithId id "dragleave" msg
                    ]
           )


{-| Configuration of a file drop target.
The `onOver`, `onDrop` and `onLeave` record entries of `DropConfig` correspond
respectively to the Html `dragover`, `drop` and `dragleave` events.

The Html `dragenter` and `dragleave` events generally are unreliable
because they bubble up from children items and do not behave
consistently with borders.

Since the `dragover` event can usually replace the `dragenter` event,
we do not provide a config entry for `dragenter`.
Beware though that the `dragover` event
will trigger multiple times while the mouse is moving on the drop area.

If you really want to track `dragleave` events,
you need to also provide a unique id that will be used to identify the event original target.

-}
type alias DropConfig msg =
    { onOver : File -> List File -> msg
    , onDrop : File -> List File -> msg
    , onLeave : Maybe { id : String, msg : msg }
    }


filesOn : String -> (File -> List File -> msg) -> Html.Attribute msg
filesOn event msgTag =
    Decode.at [ "dataTransfer", "files" ] multipleFilesDecoder
        |> Decode.map (\( file, list ) -> { message = msgTag file list, stopPropagation = True, preventDefault = True })
        |> Html.Events.custom event


onWithId : String -> String -> msg -> Html.Attribute msg
onWithId id event msg =
    Decode.at [ "target", "id" ] Decode.string
        |> Decode.andThen
            (\targetId ->
                if targetId == id then
                    Decode.succeed msg

                else
                    Decode.fail "Wrong target"
            )
        |> Decode.map (\message -> { message = message, stopPropagation = True, preventDefault = True })
        |> Html.Events.custom event


onCurrent : String -> msg -> Html.Attribute msg
onCurrent event msg =
    currentTargetDecoder
        |> Decode.andThen
            (\( currentTarget, target ) ->
                if Debug.log "currentTarget" currentTarget == Debug.log "target" target then
                    Decode.succeed msg

                else
                    Decode.fail "Wrong target"
            )
        |> Decode.map (\message -> { message = message, stopPropagation = True, preventDefault = True })
        |> Html.Events.custom event


currentTargetDecoder : Decoder ( Value, Value )
currentTargetDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "currentTarget" Decode.value)
        (Decode.field "target" Decode.value)



-- Helper functions


multipleFilesDecoder : Decoder ( File, List File )
multipleFilesDecoder =
    dynamicListOf decoder
        |> Decode.andThen
            (\files ->
                case files of
                    file :: list ->
                        Decode.succeed ( file, list )

                    _ ->
                        Decode.succeed ( errorFile, [] )
            )


errorFile : File
errorFile =
    { value = Encode.null
    , name = "If you see this file, please report an error at https://github.com/mpizenberg/elm-files/issues"
    , mime = "text/plain"
    , size = 0
    , lastModified = Time.millisToPosix 0
    }


dynamicListOf : Decoder a -> Decoder (List a)
dynamicListOf itemDecoder =
    let
        decodeN n =
            List.range 0 (n - 1)
                |> List.map decodeOne
                |> all

        decodeOne n =
            Decode.field (String.fromInt n) itemDecoder
    in
    Decode.field "length" Decode.int
        |> Decode.andThen decodeN


all : List (Decoder a) -> Decoder (List a)
all =
    List.foldr (Decode.map2 (::)) (Decode.succeed [])
