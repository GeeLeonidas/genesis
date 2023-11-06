### The name of this file can't have `-`, use `_` instead ###

# Package

version       = "0.1.0"
author        = "Guilherme Leoi"
description   = "Template for Nim projects"
license       = "Unlicense"
srcDir        = "src"
binDir        = "bin"
namedBin      = {"nim_template": "program"}.toTable()


# Dependencies

requires "nim >= 1.6.0"
