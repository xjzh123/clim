# Clim

Yet another CLI option parser generator for Nim.

Clim has a very simple usage, a feature set enough for (very?) simple CLI tools, and gracefully handles some problems for you.

## Getting started

```nim
import os

opt(path, string, ["--path", "-p"], ".") # Default value is "."
opt(help, bool, ["--help", "-h"])
opt(name, string, ["--name"])
opt(level, int, ["--level"])
opt(definitions, seq[string], ["--define", "-d"])
opt(config, JsonNode, ["--config"], %*{}) # Must provide default for JsonNode
opt(output, Option[string], ["--output", "-o"])

getOpt(commandLineParams())

echo &"{path=}, {help=}, {name=}, {level=}, {definitions=}, {config=}, {output=}"
```

Expands roughly to:

```nim
static :
  when string isnot CommandParamTypes:
    error("Unsupported option type: " & $string)
  when bool isnot CommandParamTypes:
    error("Unsupported option type: " & $bool)
  when string isnot CommandParamTypes:
    error("Unsupported option type: " & $string)
  when int isnot CommandParamTypes:
    error("Unsupported option type: " & $int)
  when seq[string] isnot CommandParamTypes:
    error("Unsupported option type: " & $seq[string])
  when JsonNode isnot CommandParamTypes:
    error("Unsupported option type: " & $JsonNode)
  when Option[string] isnot CommandParamTypes:
    error("Unsupported option type: " & $Option[string])

var identNamesThatIsSet: seq[string]
var
  path: string = "."
  help: bool
  name: string
  level: int
  definitions: seq[string]
  config: JsonNode = newJObject()
  output: Option[string]
let src: seq[string] = commandLineParams()
for part in src:
  let (prefix, name, value) = getParam(part)
  case prefix
  of "--path", "-p":
    try:
      path = value
      add(identNamesThatIsSet, "path")
    except ValueError:
      echo ["Warning: Option \"", "path", "\" is set to \"", value,
            "\" but can not be parsed to \"", "string", "\"."]
  of "--help", "-h":
    try:
      help = parseBool(value)
      add(identNamesThatIsSet, "help")
    except ValueError:
      echo ["Warning: Option \"", "help", "\" is set to \"", value,
            "\" but can not be parsed to \"", "bool", "\"."]
  of "--name":
    try:
      name = value
      add(identNamesThatIsSet, "name")
    except ValueError:
      echo ["Warning: Option \"", "name", "\" is set to \"", value,
            "\" but can not be parsed to \"", "string", "\"."]
  of "--level":
    try:
      level = int(parseInt(value))
      add(identNamesThatIsSet, "level")
    except ValueError:
      echo ["Warning: Option \"", "level", "\" is set to \"", value,
            "\" but can not be parsed to \"", "int", "\"."]
  of "--define", "-d":
    try:
      definitions.add(value)
    except ValueError:
      echo ["Warning: Option \"", "definitions", "\" is set to \"", value,
            "\" but can not be parsed to \"", "string", "\"."]
  of "--config":
    try:
      config = parseJson(value)
      add(identNamesThatIsSet, "config")
    except ValueError:
      echo ["Warning: Option \"", "config", "\" is set to \"", value,
            "\" but can not be parsed to \"", "JsonNode", "\"."]
  of "--output", "-o":
    try:
      output = some(value)
      add(identNamesThatIsSet, "output")
    except ValueError:
      echo ["Warning: Option \"", "output", "\" is set to \"", value,
            "\" but can not be parsed to \"", "string", "\"."]
  else:
    echo ["Warning: Option \"", name, "\" is not defined, \"", part,
          "\" is ignored."]
let deduplicated = deduplicate(identNamesThatIsSet, false)
if len(identNamesThatIsSet) != len(deduplicated):
  for ident in deduplicated:
    identNamesThatIsSet.del binarySearch(identNamesThatIsSet, ident)
    if ident in identNamesThatIsSet:
      echo ["Warning: Option \"", ident,
            "\" is set for multiple times. Only the last one will be used."]
```

Yes! As you can see, the generated code is *very* clear and simple. And it handles parse error, duplicated options and undefined options for you.

`opt` registers a variable that is bound to some command parameters. `getOpt` parses the given `seq[string]` and assigns option values to the varaibles. So, in one program you can only have one set of parameters. You **can't** do so:

```nim
block:
  opt(foo, string, ["--foo"])
  getOpt(@["--foo:foo"])

block:
  opt(foo, int, ["--foo"])
  getOpt(@["--foo:1"])
```

Although Clim supports very simple CLI features, there is support for containers of options: `seq[ParseAble]`. This allows you to implement things like Nim compiler's `--define` option. In the example above, `./test -d:foo -d:bar` will let `definitions` to be `@["foo", "bar"]`.

## Hooks

You can define template/macro/procedure `undefinedOptionHook`, `parseErrorHook`, `duplicateOptionHook` to customize how the generated code handles parse error, duplicated options and undefined options. If you want to make a CLI tool in another language than English, it can be helpful to rewrite such warning texts.

Example:

```nim
import os
import macros
import strformat

import clim

echo commandLineParams()

proc undefinedOptionHook(name, part: string) =
  discard


template parseErrorHook(name, value: string, typ: typedesc) =
  discard


macro duplicateOptionHook(name: string) =
  discard

expandMacros:

  opt(path, string, ["--path", "-p"], ".")
  opt(help, bool, ["--help", "-h"])
  opt(name, string, ["--name"])
  opt(level, int, ["--level"])

  getOpt(commandLineParams())

echo &"{path=}, {help=}, {name=}, {level=}"
```

**Note:** Due to implemention of strformat, you can't use strformat to format template parameters here.

## Types for options

```nim
type ParseAble = string | cstring | bool | SomeInteger | SomeFloat | enum | JsonNode

type CommandParamTypes = ParseAble | seq[ParseAble] | Option[ParseAble]
```

Clim provides a rather small set of types that can be parsed from CLI options, because it is reasonable and natural to write code yourself to parse special types in your own way. This also works for files or paths.

For example, you can do:

```nim
import paths

opt(pathString, string, ["--path", "-p"], ".")

getOpt(commandLineParams())

var path = Path(pathString)
```

Clim supports JSON options, but it is not very sweet to write them in commands, you need to write like `--config:"{\"key\": \"value\"}"` or `--config:"{""key"": ""value""}"` to escape quotation marks.

Clim supports option types: `Option[ParseAble]`.

## Internal

Clim uses procedure `getparam` to parse parameters. It works very naturally, returns `(string, string, string)`. `--name:value` will return `("--name", "name", "value")`. `--name` will return `("--name", "name", "true")`.

Clim generates human readable code with very simple logic. If Clim can't fulfill your needs but you can implement them by editing clim itself (e.g. Customize parsing), and you don't want to learn another option parser library, you can use `expandMacros` to see the generated code and start from it to write your own code. With good helper functions, you mat not need a option parser library.

## Comparison

|                               | Clim | Cliche | Cligen | Docopt |
|-------------------------------|------|--------|--------|--------|
| Directly assign to variables  | T    | T      | F      | F      |
| Generated Code Simplicity     | ++   | +      | F      | F      |
| Flexibility                   | +    | -      | +      | ++     |
| Custom Param name[^1]         | T    | F      | /      | F      |
| User defined hook             | T    | F      | F      | T      |
| Generated CLI Help            | F    | T      | T      | T      |
| Advanced features[^2]         | F    | F      | T      | T      |

Clim is inspired by [cliche](https://github.com/juancarlospaco/cliche), and created in order to remove its drawbacks, but keep its easy to use.

With cliche, you are not allowed to get from mutiple param names for one option, or allow `--name:value` and `--name=value` at the same time. You are also not allowed to get from a param name that is different from the variable name.

Cliche uses `--name=value` for default, which is different from what is used in Nim official documents! (Cliche doesn't support multiple delimiters. However, for the time being custom delimiters are not supported by Clim, only the default value `{':', '='}`.)

Cliche uses no procedures to help its work, it generates what is used, and even compares strings in a low-level way:

```nim
import std/[macros, os, strutils], cliche
expandMacros:
  commandLineParams().getOpt (foo: 'x')
doAssert foo == 'z'
```

Expands to:

```nim
var foo = 'x'
for v in commandLineParams():
  var sepPos: int
  var k, b: string
  if not(v.len > 3) or v[0] != '-'  or v[1] != '-': continue
  if v.len == 6 and v[0] == 'h' and v[1] == 'e' and v[2] == 'l' and v[3] == 'p':
    quit(apiExplained, 0)
  if len(v) == 8 and v[2] == 'x' and v[3] == 'd' and v[4] == 'e' and v[5] == 'b' and v[6] == 'u' and v[7] == 'g':
    quit(debuginfos, 0)
  for x in 2 .. v.len:
    if v[x] == '=':
      sepPos = x
      break
  k = v[2 ..< sepPos]
  b = v[sepPos .. ^1]
  if k.len == 3 and k[0] == 'f' and k[1] == 'o' and k[2] == 'o':
    foo = char(b[0])
```

(From cliche repo)

By contrast, Clim generates graceful, human-readable code, and handles edge cases for you.

[^1]: For example, when you want `-O` to equal to `--optimize`, or `-x` to equal to `--checks`.
[^2]: Arguments, subcommand, etc.

## Todo

- [ ] Now, flags are implemented by parsing `--name` as `--name:true`. Should warn when `name` is not `bool`.
