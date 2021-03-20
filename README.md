# elm-file

[![][badge-license]][license]
[![][badge-doc]][doc]

[badge-doc]: https://img.shields.io/badge/documentation-latest-yellow.svg?style=flat-square
[doc]: http://package.elm-lang.org/packages/mpizenberg/elm-file/latest
[badge-license]: https://img.shields.io/badge/license-BSD--3--Clause-blue.svg?style=flat-square
[license]: https://opensource.org/licenses/BSD-3-Clause

Alternative to [`elm/file`][elm/file] that can be encoded and passed through ports.

The `File` type provided by `elm/file` cannot be encoded and passed through ports.
It is thus impossible to process files via WebAssembly or JS for tasks
that aren't possible or efficient enough in Elm.

This package provides an alternative `File` type,
which is basically a record with a JavaScript `Value` containing the actual file,
and some fields for basics file properties.
The `Value` can thus be passed intact through a port to JavaScript if needed.

> This package will become obsolete the day Elm has a 0-cost way
> of passing a `File` through a port to JS.

For convenience, this package also provides helper functions
to load files via a file input or a drop area.

An example usage is provided in the `example/` directory.

![elm-file example screenshot][screenshot]

[elm/file]: git@github.com:mpizenberg/elm-file.git
[screenshot]: https://mpizenberg.github.io/resources/elm-file/elm-file.png
