import os
import macros
import strformat
import json
import options

import clim

echo commandLineParams()

expandMacros:

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])
  opt(definitions, seq[string], ["--define", "-d"])
  opt(config, JsonNode, ["--config"], %*{})
  opt(output, Option[string], ["--output", "-o"])

  getOpt(commandLineParams())

echo &"{path=}, {help=}, {name=}, {level=}, {definitions=}, {config=}, {output=}"

