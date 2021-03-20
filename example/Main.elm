module Main exposing (main)

import Browser
import Element exposing (Element)
import Element.Border
import Element.Font
import FeatherIcons as Icons
import FileValue as File exposing (File)
import Html exposing (Html)
import Html.Attributes


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Idle, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type Model
    = Idle
    | DraggingSomeFiles
    | DroppedSomeFiles File (List File)


type Msg
    = DragOver File (List File)
    | Drop File (List File)
    | DragLeave


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( DragOver _ _, _ ) ->
            ( DraggingSomeFiles, Cmd.none )

        ( Drop file otherFiles, _ ) ->
            ( DroppedSomeFiles file otherFiles, Cmd.none )

        ( DragLeave, _ ) ->
            ( Idle, Cmd.none )



-- View ##############################################################


view : Model -> Html Msg
view model =
    Element.layout [] (viewElmUI model)


viewElmUI : Model -> Element Msg
viewElmUI model =
    case model of
        Idle ->
            viewBeforeDrop False

        DraggingSomeFiles ->
            viewBeforeDrop True

        DroppedSomeFiles file otherFiles ->
            viewDroppedFiles file otherFiles


viewBeforeDrop : Bool -> Element Msg
viewBeforeDrop dragging =
    let
        border =
            if dragging then
                Element.Border.solid

            else
                Element.Border.dashed
    in
    Element.el (Element.width Element.fill :: Element.height Element.fill :: List.map Element.htmlAttribute onDropAttributes)
        (Element.column
            [ Element.centerX, Element.centerY, Element.spacing 32 ]
            [ Element.el
                [ border
                , Element.Border.width 4
                , Element.Border.rounded 16
                , Element.padding 16
                , Element.Font.color (Element.rgb255 50 50 250)
                , Element.centerX
                ]
                (Element.html (Icons.toHtml [] (Icons.withSize 48 Icons.arrowDown)))
            , Element.row []
                [ Element.text "Drop files or "
                , Element.html (File.hiddenInputMultiple "TheFileInput" [] Drop)
                , Element.el [ Element.Font.underline ]
                    (Element.html
                        (Html.label [ Html.Attributes.for "TheFileInput", Html.Attributes.style "cursor" "pointer" ]
                            [ Html.text "load from disk" ]
                        )
                    )
                ]
            ]
        )


onDropAttributes : List (Html.Attribute Msg)
onDropAttributes =
    File.onDrop
        { onOver = DragOver
        , onDrop = Drop
        , onLeave = Just { id = "FileDropArea", msg = DragLeave }
        }


viewDroppedFiles : File -> List File -> Element Msg
viewDroppedFiles file otherFiles =
    Element.column
        [ Element.centerX, Element.centerY, Element.spacing 16 ]
        (List.map (Element.text << .name) (file :: otherFiles))
