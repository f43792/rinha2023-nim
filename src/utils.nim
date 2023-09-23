# import options
# General templates

# Python "kind" print function
template print*(text: untyped, lend: string = "\n", flush: bool = true): untyped =
  stdout.write(text, lend)
  if flush:
    flushFile(stdout)

# Rust "copycat" for infinite loop  
template loop*(body: untyped): untyped =
  while true:
    body

# proc `$`*[T: object](x: T): string =
#   result = ""
#   for name, val in fieldPairs(x):
#     if val.isSome():
#       result.add name
#       result.add ": "
#       result.add $val.get()
#       result.add "\n"