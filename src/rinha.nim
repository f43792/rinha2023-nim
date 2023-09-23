import os
import utils
import strformat
import types
import json

const SLEEP_TIME = 1000

proc main() =
  var p: Pessoa

  p = Pessoa(id: "localhost", apelido:"nimal", nome: "fabio", stack: @["python", "nim", "c++"])

  print(%p)

  var ic: int = 1
  loop:
    print("Contando...", lend="")
    sleep(SLEEP_TIME)
    print(&"{ic}'s.")
    ic.inc()

when isMainModule:
  main()
