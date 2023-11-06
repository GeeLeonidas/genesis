when not isMainModule:
  {.fatal: "This module is not supposed to be used as a library".}

import genesis
import std / unittest

suite "Gene Expression Programming":
  test "TODO":
    require false