import std / [ sugar, tables, random, sequtils, math ]

type
  UnaryOp* = (float) -> float
  BinaryOp* = (float, float) -> float
  TernaryOp* = (float, float, float) -> float

template newUnaryOp*(body: untyped): UnaryOp = (x: float) => body
template newBinaryOp*(body: untyped): BinaryOp = (x, y: float) => body
template newTernaryOp*(body: untyped): TernaryOp = (x, y, z: float) => body

type
  Symbol* = char
  Gene* = seq[Symbol]
  SymDef* = object
    symToUnaryOp: Table[Symbol, UnaryOp]
    symToBinaryOp: Table[Symbol, BinaryOp]
    symToTernaryOp: Table[Symbol, TernaryOp]
    symToTerminalIdx: Table[Symbol, Natural]
    nameToSym: Table[string, Symbol]
    symToName: Table[Symbol, string]
  Population* = object
    genes: seq[Gene]
    fitness: seq[float]
    headLen: Natural
    unaryOps: seq[Symbol]
    binaryOps: seq[Symbol]
    ternaryOps: seq[Symbol]
    terminals: seq[Symbol]

template genes*(pop: Population): seq[Gene] = pop.genes
template fitness*(pop: Population): seq[float] = pop.fitness
template headLen*(pop: Population): Natural = pop.headLen
template unaryOps*(pop: Population): seq[Symbol] = pop.unaryOps
template binaryOps*(pop: Population): seq[Symbol] = pop.binaryOps
template ternaryOps*(pop: Population): seq[Symbol] = pop.ternaryOps
template terminals*(pop: Population): seq[Symbol] = pop.terminals

proc initSymDef*(
  unaryOps: openArray[tuple[name: string, op: UnaryOp]] = [],
  binaryOps: openArray[tuple[name: string, op: BinaryOp]] = [],
  ternaryOps: openArray[tuple[name: string, op: TernaryOp]] = [],
  terminalIdxs: openArray[tuple[name: string, idx: int]]
): SymDef =
  var count = 0
  for (name, op) in unaryOps:
    result.symToUnaryOp[count.Symbol] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.Symbol
    result.symToName[count.Symbol] = name
    inc count
  for (name, op) in binaryOps:
    result.symToBinaryOp[count.Symbol] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.Symbol
    result.symToName[count.Symbol] = name
    inc count
  for (name, op) in ternaryOps:
    result.symToTernaryOp[count.Symbol] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.Symbol
    result.symToName[count.Symbol] = name
    inc count
  for (name, idx) in terminalIdxs:
    result.symToTerminalIdx[count.Symbol] = idx
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.Symbol
    result.symToName[count.Symbol] = name
    inc count

proc getMaxParamCount(pop: Population): Natural =
  result = 0
  if pop.ternaryOps.len > 0:
    result = 3
  elif pop.binaryOps.len > 0:
    result = 2
  elif pop.unaryOps.len > 0:
    result = 1

proc tailLen(pop: Population): Positive =
  pop.headLen * (pop.getMaxParamCount() - 1) + 1

proc initAllGenes*(pop: var Population) =
  let
    allSymbols = pop.unaryOps.
          concat(pop.binaryOps).
          concat(pop.ternaryOps).
          concat(pop.terminals)
    totalLen = pop.headLen + pop.tailLen
  for gene in pop.genes.mitems:
    gene = newSeq[Symbol](totalLen)
    for idx in 0..<pop.headLen:
      gene[idx] = sample allSymbols
    for idx in pop.headLen..<totalLen:
      gene[idx] = sample pop.terminals

proc initPopulation*(
  def: SymDef,
  size: Positive,
  headLen: Natural;
  unaryOpNames, binaryOpNames, ternaryOpNames: openArray[string] = [],
  terminalNames: openArray[string]
): Population =
  for name in unaryOpNames:
    let sym = def.nameToSym[name]
    result.unaryOps.add(sym)
  for name in binaryOpNames:
    let sym = def.nameToSym[name]
    result.binaryOps.add(sym)
  for name in ternaryOpNames:
    let sym = def.nameToSym[name]
    result.ternaryOps.add(sym)
  for name in terminalNames:
    let sym = def.nameToSym[name]
    result.terminals.add(sym)
  result.headLen = headLen
  result.genes = newSeq[Gene](size)
  result.fitness = newSeq[float](size)
  initAllGenes(result)

proc fromNamesToGene*(def: SymDef, names: openArray[string]): Gene =
  for name in names:
    result.add(def.nameToSym[name])

proc prefixEval*(def: SymDef, gene: Gene, input: openArray[float]; symIdx = 0.Natural): (float, Natural) =
  let sym = gene[symIdx]
  if def.symToBinaryOp.hasKey(sym):
    let
      op = def.symToBinaryOp[sym]
      leftIdx = symIdx + 1
      (evalLeft, leftLastIdx) = def.prefixEval(gene, input, leftIdx)
      rightIdx = leftLastIdx + 1
      (evalRight, rightLastIdx) = def.prefixEval(gene, input, rightIdx)
    return (op(evalLeft, evalRight), rightLastIdx)
  elif def.symToUnaryOp.hasKey(sym):
    let
      targetIdx = symIdx + 1
      op = def.symToUnaryOp[sym]
      (evalTarget, targetLastIdx) = def.prefixEval(gene, input, targetIdx)
    return (op(evalTarget), targetLastIdx)
  elif def.symToTernaryOp.hasKey(sym):
    raise newException(ValueError, "Ternary evaluation is not implemented yet")
  elif def.symToTerminalIdx.hasKey(sym):
    let terminalIdx = def.symToTerminalIdx[sym]
    return (input[terminalIdx], symIdx)
  raise newException(ValueError, "Trying to evaluate an undefined symbol")

proc calculateFitness*[N](def: SymDef, gene: Gene, xy: openArray[tuple[input: array[N, float], expected: float]]): float =
  var sumSquaredError = 0.0
  for (input, expected) in xy:
    let (evaluated, _) = try: def.prefixEval(gene, input) except: return 0.0
    sumSquaredError += pow(expected - evaluated, 2)
  let mse = sumSquaredError / xy.len.float
  return 1e3 / (1.0 + mse)

proc updateAllFitness*[N](def: SymDef, pop: var Population, xy: openArray[tuple[input: array[N, float], expected: float]]) =
  for idx in 0..<pop.genes.len:
    pop.fitness[idx] = def.calculateFitness(pop.genes[idx], xy)

proc ensureSomeFitness*[N](def: SymDef, pop: var Population, xy: openArray[tuple[input: array[N, float], expected: float]], atLeast: float) =
  while true:
    for idx in 0..<pop.genes.len:
      let fitness = pop.fitness[idx]
      if fitness >= atLeast:
        return
    def.updateAllFitness(pop, xy)

proc sortElite*(pop: var Population) =
  var eliteIdx = 0
  for idx in 0..<pop.genes.len:
    if pop.fitness[idx] > pop.fitness[eliteIdx]:
      eliteIdx = idx
  let
    geneZero = pop.genes[0]
    fitnessZero = pop.fitness[0]
  pop.genes[0] = pop.genes[eliteIdx]
  pop.fitness[0] = pop.fitness[eliteIdx]
  pop.genes[eliteIdx] = geneZero
  pop.fitness[eliteIdx] = fitnessZero