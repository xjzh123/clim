import os
import strformat

import clim

echo commandLineParams()

block:

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])

  getOpt(commandLineParams())

  echo &"{path=}, {help=}, {name=}, {level=}"

block:

  getOpt(@["--path:foo", "--level:1"])

  echo &"{path=}, {help=}, {name=}, {level=}"