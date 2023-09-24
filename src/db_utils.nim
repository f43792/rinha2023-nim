# import db_connector/postgres
import std/[options,json]
import os, strutils
import asyncdispatch
# import utils
import types


# Config definition
# type
#   PgConfig* = object
#     hostname*: string
#     port*: int
#     username*: string
#     password*: string
#     database*: string
#     poolSize*: int
#     data_samples*: int

# type
#   # db pool
#   AsyncPool* = ref object
#     conns*: seq[DbConn]
#     busy*: seq[bool]

# var
#   db_pool* {.threadvar.}: AsyncPool

# Forward declarations
# proc parseEnv*() : PgConfig
# proc newAsyncPool*(connection, user, password, database: string, num: int): AsyncPool

# let
#   pgconf = parseEnv()

# db_pool = newAsyncPool(
#   pgconf.hostname, 
#   pgconf.username, 
#   pgconf.password, 
#   pgconf.database, 
#   pgconf.poolSize)

# # Excpetion to catch on errors
# PGError* = object of Exception

# proc newAsyncPool*(
#     connection,
#     user,
#     password,
#     database: string,
#     num: int
#   ): AsyncPool =
#   ## Create a new async pool of num connections.
#   result = AsyncPool()
#   print(&"Adding {num} connections to the pool...", lend="")
#   for i in 0..<num:
#     let conn = open(connection, user, password, database)
#     assert conn.status == CONNECTION_OK
#     result.conns.add conn
#     result.busy.add false
#   print("OK.")

# proc getFreeConnIdx*(pool: AsyncPool): int =
#   ## Wait for a free connection and return it.
#   loop:
#     for conIdx in 0..<pool.conns.len:
#       if not pool.busy[conIdx]:
#         pool.busy[conIdx] = true
#         print(&"Returning connection #{conIdx}...")
#         return conIdx
#     sleep(100)

# proc returnConn*(pool: AsyncPool, conIdx: int) =
#   ## Make the connection as free after using it and getting results.
#   # print(&"...done [{conIdx}]")
#   pool.busy[conIdx] = false

proc `$`[T: object](x: T): string =
  result = ""
  for name, val in fieldPairs(x):
    result.add name
    result.add ": "
    result.add $val
    result.add "\n"

proc parseEnv*() : PgConfig =
  debugEcho("Initializing parseEnv...")
  var config = PgConfig()
  let hostname = getEnv("DB_HOST")
  if len(hostname) == 0:
    config.hostname = "localhost"
  else:
    config.hostname = hostname

  try:
    let port = parseInt(getEnv("DB_PORT"))
    config.port = port
  except:
    config.port = 5432

  let username = getEnv("DB_USERNAME")
  if len(username) == 0:
    config.username = "postgres"
  else:
    config.username = username

  let password = getEnv("DB_PASSWORD")
  if len(password) == 0:
    config.password = "password"
  else:
    config.password = password

  let database = getEnv("DB_DATABASE")
  if len(database) == 0:
    config.database = "postgres"
  else:
    config.database = database

  try:
    let poolSize = parseInt(getEnv("DB_POOL_SIZE"))
    config.poolSize = poolSize
  except:
    config.poolSize = 10

  try:
    let data_samples = parseInt(getEnv("DATA_SAMPLES"))
    config.data_samples = data_samples
  except:
    config.data_samples = 10

  return config


var initDBStrings*: string = """
    CREATE EXTENSION IF NOT EXISTS pg_trgm;#
    DROP TABLE IF EXISTS public.pessoas CASCADE;#
    CREATE TABLE public.pessoas (
        id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
        apelido character varying(32) UNIQUE NOT NULL,
        nome character varying(100) NOT NULL,
        nascimento timestamp(6) without time zone,
        stack character varying,
        created_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL,
        searchable text GENERATED ALWAYS AS ((((((nome)::text || ' '::text) || (apelido)::text) || ' '::text) || (COALESCE(stack, ' '::character varying))::text)) STORED
    );"""

# proc initDB*() =
#   let dbc = parseEnv()
#   db_exec(dbc, conn):
#     try:
#       print("Creating data base...", lend="")
#       for l in createPessoaTable().split(';'):
#         conn.exec(sql(&"{l};"))
#       print("OK.")
#     finally:
#       print(&"Inserting {dbc.data_samples} sample records...", lend="")
#       for i in 0 ..< dbc.data_samples:
#         # print(&"Inserting[{i}]", line_end="")
#         conn.exec(sql"INSERT INTO public.pessoas (apelido, nome, nascimento, stack, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
#               "strApelido_" & $i, 
#               "strNome_" & $i, 
#               "1974-01-01 00:00:00.000", 
#               "[python, javascript, cpp, " & $i & "]", 
#               "2023-09-19 00:00:00.000", 
#               "2023-09-20 00:00:00.000")
#       print("OK.")
      
#     let r = conn.getAllRows(sql"""SELECT * FROM public.pessoas p""")
#     echo &"Total records found: {r.len}"
#     var ic = 0
#     for row in conn.fastRows(sql"""SELECT * FROM public.pessoas p"""):
#       print(&"{ic}] {row[0]} : {row[2]}")
#       ic.inc

  # returnConn(db_pool, db_idx)