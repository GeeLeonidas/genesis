import std / [ sugar, tables, random ]

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
  Population* = object
    genes: seq[string]
    headSize: Natural
    unaryOps: seq[char]
    binaryOps: seq[char]
    ternaryOps: seq[char]
    terminals: seq[char]

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
    inc count
  for (name, op) in binaryOps:
    result.symToBinaryOp[count.char] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    inc count
  for (name, op) in ternaryOps:
    result.symToTernaryOp[count.char] = op
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    inc count
  for (name, idx) in terminalIdxs:
    result.symToTerminalIdx[count.char] = idx
    if result.nameToSym.hasKey(name):
      raise newException(ValueError, "Do not attribute the same name to different symbols")
    result.nameToSym[name] = count.char
    inc count

proc addGeneTo(pop: var Population) =
  discard # TODO: gene initialization

proc initPopulation*(
  def: SymDef,
  size: Positive,
  headSize: Natural;
  unaryOpNames, binaryOpNames, ternaryOpNames, terminalNames: openArray[string]
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
  result.headSize = headSize
  for _ in 1..size:
    addGeneTo(result)

proc getMaxParamCount(pop: Population): Natural =
  result = 0
  if pop.ternaryOps.len > 0:
    result = 3
  elif pop.binaryOps.len > 0:
    result = 2
  elif pop.unaryOps.len > 0:
    result = 1

proc tailSize(pop: Population, def: SymDef): Positive =
  pop.headSize * (pop.getMaxParamCount() - 1) + 1

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