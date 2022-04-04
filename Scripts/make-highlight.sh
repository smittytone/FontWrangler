#!/bin/bash

# Additional langauges required
additions=(applescript coffeescript ada brainfuck delphi clojure fortran arduino vbscript lisp erlang elixir protobuf armasm latex)

# REQUIRES highlight.js clone in your $GIT directory
if cd "$GIT/highlight.js" ; then
    if node tools/build.js -t browser :common ${additions} ; then
        if [[ -e build/highlight.min.js ]]; then
            cp build/highlight.min.js "$GIT/HighlighterSwift/Sources/Assets/highlight.min.js"
        else
            echo '[ERROR] highlight.min.js not built'
        fi
    else
        echo '[ERROR] Could not build highlight.js'
    fi
else
    echo '[ERROR] No highlight.js repo in your $GIT directory'
fi
