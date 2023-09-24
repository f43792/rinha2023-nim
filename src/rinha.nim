import std/[strformat, strutils]
import utils
import types
import json
import uuids
import sequtils

import malebolgia
import mummy, mummy/routers
# import asyncdispatch

import db_connector/db_postgres
import db_utils

# ========= Define symbols =================
const coresToUse {.intdefine.} = 4
const workerThreads {.intdefine.} = 8
# const poolSizePerThread {.intdefine.} = 1

const dbc = parseEnv()


#############################################
## initDB - initializes the database
## and add sample records
## ##########################################
proc initDB() =
  db_exec(dbc, conn):
    try:
      print("Executing initDB tasks:")
      for line in initDBStrings.split('#'):
        conn.exec(sql(line))
    finally:
      print(&"Inserting {dbc.data_samples} sample records...", lend="")
      for i in 0 ..< dbc.data_samples:
        # print(&"Inserting[{i}]", line_end="")
        conn.exec(sql"INSERT INTO public.pessoas (apelido, nome, nascimento, stack, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
              "strApelido_" & $i, 
              "strNome_" & $i, 
              "1974-06-07 00:00:00.000", 
              "python, javascript, cpp, " & $i, 
              "2023-09-19 00:00:00.000", 
              "2023-09-20 00:00:00.000")
      print("OK.")


#############################################
## contagem_pessoas - returns qty "pessoas"
## 
## ##########################################
proc contagem_pessoas(request: Request) =
  var
    headers: HttpHeaders
    resp = ""
  
  headers["Content-Type"] = "text/text"
  db_exec(dbc, conn):
    let rows = conn.getAllRows(sql"""SELECT COUNT(*) FROM public.pessoas p""")
    resp = rows[0][0]

  request.respond(200, headers, resp)


proc insert_pessoa(request: Request) =
  var
    headers: HttpHeaders

  let pessoa = Pessoa()
  let body = parseJson(request.body)
  let uuid = $genUUID()

  pessoa.id = uuid
  pessoa.apelido = body["apelido"].getStr
  pessoa.nome = body["nome"].getStr
  pessoa.nascimento = body["nascimento"].getStr
  pessoa.stack = newSeq[string]()
  for item in body["stack"]:
    pessoa.stack.add(item.getStr)
  

  db_exec(dbc, conn):
    try:
      if all(pessoa.stack, proc (x: string): bool = x.len <= 32):
        conn.exec(sql"""INSERT INTO public.pessoas (id, apelido, nome, nascimento, stack, created_at, updated_at)
                        VALUES (?, ?, ?, ?, ?, NOW(), NOW());""", 
                        pessoa.id, pessoa.apelido, pessoa.nome, pessoa.nascimento, pessoa.stack.join(","))

        headers["Location"] = "/pessoas/" & uuid
        request.respond(201, headers, "")
      else:
        request.respond(400, headers, "")
    except:
      request.respond(422, headers, "")



#############################################
## search_pessoas - returns qty "pessoas"
## 
#############################################
proc search_pessoas(request: Request) =
  var
    headers: HttpHeaders
    resp = newSeq[Pessoa]()
    # uu: Tuuid

  debugEcho "search_pessoas"
  debugEcho "Request uri: " & request.uri

  let requestedID = request.uri.split("/")[^1]
  # discard uuid_parse(requestedID.cstring, uu)
  debugEcho($requestedID)

  if request.uri.toLower().find("?id") > 0:
    # Procura por id
    let requestedID = request.uri.split("=")[^1]
    if requestedID.len() > 0:
      db_exec(dbc, conn):
        # var rows: newSeq[Row]()
        let row = conn.getRow(sql"""SELECT id::text, apelido, nome, to_char(nascimento, 'YYYY-MM-DD'), stack
          FROM public.pessoas p
          where p.id=?""", 
          requestedID)

        let pessoa = Pessoa(id: row[0], apelido: row[1], nome: row[2], nascimento: row[3], stack: row[4].split(","))
        if pessoa.id != "":
          debugEcho "SOMETHING FOUND"
          resp.add(pessoa)
          headers["Content-Type"] = "text/json"
          request.respond(200, headers, &"{%*resp}")
        else:
          debugEcho "NOT FOUND"
          headers["Content-Type"] = "text/text"
          request.respond(404, headers, "Usuario nao encontrado")

  # Procura por termo
  else:
    if request.uri.toLower().find("t") > 0:
      let search_term = request.uri.split("=")[^1]
      debugEcho &"Searchable term: {search_term}"
      db_exec(dbc, conn):
        let rows = conn.getAllRows(sql"""
          SELECT id::text, apelido, nome, to_char(nascimento, 'YYYY-MM-DD'), stack
          FROM public.pessoas p
          where p.searchable ILIKE ?;""",
          &"%{search_term}%")
        for row in rows:
          resp.add(Pessoa(id: row[0], apelido: row[1], nome: row[2], nascimento: row[3], stack: row[4].split(",")))

      request.respond(200, headers, &"{%*resp}")


proc launchWorker(id: int) = 
  var router: Router
  router.get("/pessoas", search_pessoas)
  router.post("/pessoas", insert_pessoa)
  router.get("/contagem-pessoas", contagem_pessoas)
  let server = newServer(router, workerThreads = workerThreads)
  server.serve(port = Port(3000), address = "0.0.0.0")




proc main() =
  initDB()
  print(&"Creating {coresToUse} threads and {workerThreads} workers per thread...")
  var m = createMaster()
  m.awaitAll:
    for i in 0 ..< coresToUse:
      m.spawn(launchWorker(i))
  print("done.")

when isMainModule:
  main()
