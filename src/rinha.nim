import os
# import asyncdispatch
import utils
import strformat

const SLEEP_TIME = 1000

proc main() =
  var ic: int = 1
  loop:
    print("Contando...", lend="")
    sleep(SLEEP_TIME)
    print(&"{ic}'s.")
    ic.inc()

when isMainModule:
  main()
