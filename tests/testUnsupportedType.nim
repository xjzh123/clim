import os
import macros

import clim

opt(foo, BackwardsIndex, ["--foo"])

doAssert not compiles(getOpt(commandLineParams()))
