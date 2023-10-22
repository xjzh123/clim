import os
import macros
import strformat

import clim

echo commandLineParams()

expandMacros:

  opt(foo, BackwardsIndex, ["--foo"])

  getOpt(commandLineParams())

echo &"{foo=}"

