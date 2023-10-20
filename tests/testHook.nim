import os
import macros
import strformat

const optionSep = {'.'}

import clim

echo commandLineParams()

proc undefinedOptionHook(name, part: string) =
  discard


template parseErrorHook(name, value: string, typ: typedesc) =
  discard


macro duplicateOptionHook(name: string) =
  discard

expandMacros:

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])

  getOpt(commandLineParams())

echo &"{path=}, {help=}, {name=}, {level=}"