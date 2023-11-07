when not isMainModule:
  {.fatal: "This module is not supposed to be used as a library".}

import genesis
import std / [ unittest, sugar ]

suite "Gene Expression Programming":
  test "Define and evaluate arithmetic symbols":
    let
      def = initSymDef(
        binaryOps = {
          "Add": newBinaryOp(x + y),
          "Sub": newBinaryOp(x - y),
          "Mul": newBinaryOp(x * y),
          "Div": newBinaryOp(x / y)
        },
        terminalIdxs = {
          "a": 0,
          "b": 1,
          "c": 2
        }
      )
      geneOne = def.fromNamesToGene(["Mul", "Add", "a", "b", "c"])
      geneTwo = def.fromNamesToGene(["Div", "Add", "Mul", "Sub", "a", "b", "c", "b", "a"])
      checks = {
        geneOne: {
          def.prefixEval(geneOne, [1.0, 2.0, 3.0]):  9.0,
          def.prefixEval(geneOne, [3.0, 2.0, 1.0]):  5.0,
          def.prefixEval(geneOne, [2.0, 0.0, 2.0]):  4.0
        },
        geneTwo: {
          def.prefixEval(geneTwo, [1.0, 2.0, 3.0]): -1.0,
          def.prefixEval(geneTwo, [3.0, 2.0, 1.0]):  1.0,
          def.prefixEval(geneTwo, [2.0, 0.0, 2.0]):  2.0
        }
      }
    for checkGroup in checks:
      let (gene, evalTable) = checkGroup
      for row in evalTable:
        let
          (evalInfo, expected) = row
          (evaluated, lastIdx) = evalInfo
        check evaluated == expected
        check lastIdx   == gene.high