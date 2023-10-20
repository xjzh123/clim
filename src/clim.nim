## Yet another CLI option parser generator.

runnableExamples:
  import os

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])

  getOpt(commandLineParams())

  echo &"{path=}, {help=}, {name=}, {level=}"


import macros
import macrocache
import strutils
import strformat
import sequtils
import algorithm
import json


const
  optionIdents = CacheSeq"climOptionIdents"
  optionParams = CacheSeq"climOptionParams"
  optionTypes = CacheSeq"climOptionTypes"
  optionDefaults = CacheSeq"climOptionDefaults"


type ParseAble = string | cstring | bool | SomeInteger | SomeFloat | enum | JsonNode


const optionDelimiters = {':', '='}


template undefinedOptionHookImpl(name, part: string) =
  when compiles(undefinedOptionHook(name, part)):
    undefinedOptionHook(name, part)
  else:
    echo "Warning: Option \"", name, "\" is not defined, \"", part, "\" is ignored."


template parseErrorHookImpl(name, value: string, typ: typedesc) =
  when compiles(parseErrorHook(name, value, typ)):
    parseErrorHook(name, value, typ)
  else:
    echo "Warning: Option \"", name, "\" is set to \"", value, "\" but can not be parsed to \"", typ, "\"."


template duplicateOptionHookImpl(name: string) =
  when compiles(duplicateOptionHook(name)):
    duplicateOptionHook(name)
  else:
    echo "Warning: Option \"", name, "\" is set for multiple times. Only the last one will be used."


macro debugEchoWhenIsMain(x: varargs[untyped]): untyped =
  quote do:
    when isMainModule:
      debugEcho(`x`)


proc getParam*(param: string): (string, string, string) =
  let tmp = param.split(optionDelimiters, 1)
  let
    prefix = tmp[0]
    name = prefix.strip(trailing = false, chars = {'-'})
    value =
      if len(tmp) == 1:
        "true"
      else:
        tmp[1]
  debugEchoWhenIsMain &"{name=}, {value=}"
  (prefix, name, value)


macro opt*[T](name: untyped, typ: typedesc[T], params: openArray[string],
    default: T): untyped =
  optionIdents.add name
  optionParams.add params
  optionDefaults.add default
  optionTypes.add typ


macro opt*[T](name: untyped, typ: typedesc[T], params: openArray[
    string]): untyped =
  optionIdents.add name
  optionParams.add params
  optionDefaults.add newEmptyNode()
  optionTypes.add typ


macro getOpt*(src: seq[string]): untyped =
  result = nnkStmtList.newTree()

  result.add nnkStaticStmt.newTree(nnkStmtList.newTree())

  template typeCheck: NimNode = result[0][0]

  let identNamesThatIsSet = genSym(nskVar, "identNamesThatIsSet")

  result.add quote do:
    var `identNamesThatIsSet`: seq[string]

  result.add nnkVarSection.newTree()

  template varSection: NimNode = result[2]

  let
    part = genSym(nskForVar, "part")
    prefix = genSym(nskLet, "prefix")
    name = genSym(nskLet, "name")
    value = genSym(nskLet, "value")

  result.add quote do:
    let src: seq[string] = `src`
    for `part` in src:
      let (`prefix`, `name`, `value`) = getParam(`part`)

  template forBody: NimNode = result[3][1]

  debugEchoWhenIsMain &"{forBody.astGenRepr=}"

  forBody[2].add nnkCaseStmt.newTree(
    quote do: `prefix`
  )

  template caseBody: NimNode = forBody[2][1]

  for i in 0 ..< optionIdents.len:
    let
      ident = optionIdents[i]
      params = optionParams[i]
      typ = optionTypes[i]
      default = optionDefaults[i]

    debugEchoWhenIsMain &"{ident=}, {params.astGenRepr=}, {typ=}, {default.astGenRepr=}"

    typeCheck.add quote do:
      when `typ` isnot ParseAble:
        error("Unsupported option type: " & $`typ`)

    varSection.add(
      nnkIdentDefs.newTree(ident, typ, default)
    )

    let options = params.toSeq

    caseBody.add nnkOfBranch.newTree(options)

    let identName = ident.strVal

    caseBody[^1].add:
      quote do:
        `identNamesThatIsSet`.add `identName`

        try:
          `ident` =
            when `typ` is string:          `value`
            elif `typ` is cstring:         cstring(`value`)
            elif `typ` is bool:            parseBool(`value`)
            elif `typ` is SomeSignedInt:   `typ`parseInt(`value`)
            elif `typ` is SomeUnSignedInt: `typ`parseUInt(`value`)
            elif `typ` is SomeFloat:       `typ`parseFloat(`value`)
            elif `typ` is enum:            parseEnum[`typ`](`value`)
            elif `typ` is JsonNode:        parseJson(`value`)
            else: doAssert false # This can't happen, because typ is already checked in compiletime with a static block.
        except ValueError:
          parseErrorHookImpl(`identName`, `value`, typeof `typ`)

  caseBody.add nnkElse.newTree(
    quote do:
      undefinedOptionHookImpl(`name`, `part`)
  )

  result.add quote do:
    let deduplicated = `identNamesThatIsSet`.deduplicate
    if `identNamesThatIsSet`.len != deduplicated.len:
      for ident in deduplicated:
        `identNamesThatIsSet`.del(`identNamesThatIsSet`.binarySearch(ident))
        if ident in `identNamesThatIsSet`:
          duplicateOptionHookImpl(ident)

  debugEchoWhenIsMain astGenRepr(result)
  debugEchoWhenIsMain result.toStrLit



when isMainModule:
  import os

  echo commandLineParams()

  expandMacros:

    opt(path, string, ["--path", "-p"], ".")
    opt(help, bool, ["--help", "-h"])
    opt(name, string, ["--name"])
    opt(level, int, ["--level"])

    getOpt(commandLineParams())

  echo &"{path=}, {help=}, {name=}, {level=}"

