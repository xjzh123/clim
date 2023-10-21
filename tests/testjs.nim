import macros
import strformat
import json

import clim

expandMacros:

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])
  opt(definitions, seq[string], ["--define", "-d"])
  opt(config, JsonNode, ["--config"], %*{})

  getOpt(@["--path:foo", "--level:1"])

echo &"{path=}, {help=}, {name=}, {level=}, {definitions=}, {config=}"

