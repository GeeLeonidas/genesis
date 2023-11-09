when not isMainModule:
  {.fatal: "This module is not supposed to be used as a library".}

import genesis
import std / [ unittest, sugar, strutils, sequtils ]

suite "Gene Expression Programming":
  setup:
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
  test "Evaluate arithmetic symbols":
    let
      geneOne = def.fromNamesToGene("Mul:Add:a:b:c".split(":"))
      geneTwo = def.fromNamesToGene("Div:Add:Mul:Sub:a:b:c:b:a".split(":"))
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
  test "Gene and population initialization":
    let pop = def.initPopulation(
      size = 10,
      headLen = 3,
      binaryOpNames = "Add:Sub:Mul:Div".split(":"),
      terminalNames = "a:b:c".split(":")
    )
    var count = 0
    for gene in pop.genes:
      inc count
      check gene.len == 7
      check gene[pop.headLen..<gene.len].allIt(it in pop.terminals)
      check pop.fitness[count - 1] == 0.0
    check count == 10
  test "Population fitness calculation and elite ensurance":
    var
      pop = def.initPopulation(
        size = 5,
        headLen = 5,
        binaryOpNames = "Add:Sub:Mul".split(":"),
        terminalNames = "a:b:c".split(":")
      )
    let
      xy = { # y = a * a + b
        [ 2.0,  5.0, 10.0]:  9.0,
        [-2.0,  1.0, -3.0]:  5.0,
        [ 1.0, -2.0,  7.0]: -1.0
      }
    def.updateAllFitness(pop, xy)
    for idx in 0..<pop.genes.len:
      check pop.fitness[idx] > 0.0
    def.ensureSomeFitness(pop, xy, atLeast = 80.0)
    sortElite(pop)
    check pop.fitness[0] >= 80.0
  test "Roulette selection":
    var
      pop = def.initPopulation(
        size = 5,
        headLen = 10,
        binaryOpNames = "Add:Sub:Mul:Div".split(":"),
        terminalNames = "a:b:c".split(":")
      )
    let
      xy = { # y = a / (b * b + 1)
        [ 2.0,  1.0, 10.0]:  1.0,
        [-2.0,  0.0, -3.0]: -2.0,
        [ 1.0, -2.0,  7.0]:  1/5
      }
    def.updateAllFitness(pop, xy)
    var invalidFound = false
    for idx in 0..<pop.genes.len:
      if pop.fitness[idx] == 0.0:
        invalidFound = true
        break
    check invalidFound
    apllyRouletteSelection(pop)
    for idx in 0..<pop.genes.len:
      check pop.fitness[idx] > 0.0