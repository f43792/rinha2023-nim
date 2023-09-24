import std/[options,json]
import os

# Config definition
type
  PgConfig* = object
    hostname*: string
    port*: int
    username*: string
    password*: string
    database*: string
    poolSize*: int
    data_samples*: int

# Model definition
type
  Pessoa* = ref object
    id*: string
    apelido*: string
    nome*: string
    nascimento*: string
    stack*: seq[string]

# serializers
proc toJson*(p: Pessoa): JsonNode =
  result = newJObject()
  result["id"] = %p.id
  result["apelido"] = %p.apelido
  result["nome"] = %p.nome
  result["nascimento"] = %p.nascimento
  result["stack"] = %p.stack

proc toJson*(p: seq[Pessoa]): JsonNode =
  result = newJArray()
  for pessoa in p:
    result.add(pessoa.toJson())

proc fromJson*(node: JsonNode, T: typedesc[string]): string =
  if node.kind == JString:
    return some(node.getStr)
  else:
    return none(string)

proc fromJson*(node: JsonNode, T: typedesc[seq[string]]): seq[string] =
  if node.kind == JArray:
    var arr: seq[string] = @[]
    for child in node:
      if child.kind == JString:
        arr.add(child.getStr)
    return some(arr)
  else:
    return none(seq[string])

# proc fromJson*(node: JsonNode, T: typedesc[Pessoa]): Pessoa =
#   new(result)
#   for key, value in fieldpairs(result):
#     node[key] = value
