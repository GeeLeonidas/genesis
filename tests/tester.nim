when not isMainModule:
  {.fatal: "This module is not supposed to be used as a library".}

import genesis
import std / [ unittest, sugar ]

suite "Gene Expression Programming":
  test "Define and evaluate arithmetic symbols":
    let
      def = initSymDef(
        binaryOps = [
          ("Add", newBinaryOp(x + y)),
          ("Sub", newBinaryOp(x - y)),
          ("Mul", newBinaryOp(x * y)),
          ("Div", newBinaryOp(x / y))
        ],
        terminalIdxs = [
          ("a", 0),
          ("b", 1),
          ("c", 2)
        ]
      )
      geneOne = def.fromNamesToGene(["Mul", "Add", "a", "b", "c"])
      geneTwo = def.fromNamesToGene(["Div", "Add", "Mul", "Sub", "a", "b", "c", "b", "a"])
    check def.prefixEval(geneOne, [1.0, 2.0, 3.0])[0] ==  9.0
    check def.prefixEval(geneOne, [3.0, 2.0, 1.0])[0] ==  5.0
    check def.prefixEval(geneOne, [2.0, 0.0, 2.0])[0] ==  4.0
    check def.prefixEval(geneTwo, [1.0, 2.0, 3.0])[0] == -1.0
    check def.prefixEval(geneTwo, [3.0, 2.0, 1.0])[0] ==  1.0
    check def.prefixEval(geneTwo, [2.0, 0.0, 2.0])[0] ==  2.0