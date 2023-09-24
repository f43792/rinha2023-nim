# import options
# General templates
import types
import db_connector/db_postgres

# Python "kind" print function
template print*(text: untyped, lend: string = "\n", flush: bool = true): untyped =
  stdout.write(text, lend)
  if flush:
    flushFile(stdout)

# Rust "copycat" for infinite loop  
template loop*(body: untyped): untyped =
  while true:
    body

template db_exec*(dbenv: PgConfig, conn: untyped, body: untyped): untyped =
  var conn: DbConn
  try:
    conn = open(dbenv.hostname, dbenv.username, dbenv.password, dbenv.database)
    body
  except:
    # quit("Error opening db connection")
    raise
  finally:
    conn.close()