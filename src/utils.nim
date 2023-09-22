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