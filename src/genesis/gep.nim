import std / [ sugar, tables, random, sequtils ]

type
  UnaryOp* = (float) -> float
  BinaryOp* = (float, float) -> float
  TernaryOp* = (float, float, float) -> float

template newUnaryOp*(body: untyped): UnaryOp = (x: float) => body
template newBinaryOp*(body: untyped): BinaryOp = (x, y: float) => body
template newTernaryOp*(body: untyped): TernaryOp = (x, y, z: float) => body

type
  SymDef* = object
    symToUnaryOp: Table[char, UnaryOp]
    symToBinaryOp: Table[char, BinaryOp]
    symToTernaryOp: Table[char, TernaryOp]
    symToTerminalIdx: Table[char, Natural]
    nameToSym: Table[string, char]
    symToName: Table[char, string]
  Population* = object
    genes: seq[string]
    headLen: Natural
    unaryOps: seq[char]
    binaryOps: seq[char]
    ternaryOps: seq[char]
    terminals: seq[char]

template genes*(pop: Population): seq[string] = pop.genes
template headLen*(pop: Population): Natural = pop.headLen
template unaryOps*(pop: Population): seq[char] = pop.unaryOps
template binaryOps*(pop: Population): seq[char] = pop.binaryOps
template ternaryOps*(pop: Population): seq[char] = pop.ternaryOps
template terminals*(pop: Population): seq[char] = pop.terminals

proc initSymDef*(
  unaryOps: openArray[tuple[name: string, op: UnaryOp]] = [],
  binaryOps: openArray[tuple[name: string, op: BinaryOp]] = [],
  ternaryOps: openArray[tuple[name: string, op: TernaryOp]] = [],
  terminalIdxs: openArray[tuple[name: string, idx: int]]
): SymDef =
  var count = 0
  for (name, op) in unaryOps:
    result.symToUnaryOp[count.char] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    result.symToName[count.char] = name
    inc count
  for (name, op) in binaryOps:
    result.symToBinaryOp[count.char] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    result.symToName[count.char] = name
    inc count
  for (name, op) in ternaryOps:
    result.symToTernaryOp[count.char] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    result.symToName[count.char] = name
    inc count
  for (name, idx) in terminalIdxs:
    result.symToTerminalIdx[count.char] = idx
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    result.symToName[count.char] = name
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
    gene = newString(totalLen)
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
  result.genes = newSeq[string](size)
  initAllGenes(result)

proc fromNamesToGene*(def: SymDef, names: openArray[string]): string =
  for name in names:
    result.add(def.nameToSym[name])

proc prefixEval*(def: SymDef, gene: string, input: openArray[float]; symIdx = 0.Natural): (float, Natural) =
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