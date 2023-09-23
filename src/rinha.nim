import utils
import strformat
import malebolgia
import mummy, mummy/routers

proc indexHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  # Counter.inc()

  # let pgconf = parseEnv()
  # oprint "Connecting DB"
  # let db_pool = newAsyncPool(
  #   pgconf.hostname, 
  #   pgconf.username, 
  #   pgconf.password, 
  #   pgconf.database, 
  #   pgconf.poolSize)

  # # let db_idx = getFreeConnIdx(db_pool)
  # let db = db_pool.conns[0]

  # let rows = db.getAllRows(sql"""SELECT * FROM public.pessoas p""")
  # echo &"Total records found: {rows.len}"

  var resp = ""
  for i in 0..<10:
    resp.add &"<p>Texto {i}</p>"

  # request.respond(200, headers, &"{now()}] Port [{http_port}]. Cores: {coresToUse} Threads: {workerThreads} Counter: {Counter} Rows: {rows.len} \n")
  request.respond(200, headers, resp)

proc launchWorker(id: int) {.gcsafe.} =
  var router: Router
  router.get("/", indexHandler)
  let server = newServer(router, workerThreads = 8)
  # echo &"Core #{id} serving on port:{http_port} with {workerThreads} threads."
  server.serve(port = Port(3000), address = "0.0.0.0")

proc main() =
  var master = createMaster()
  master.awaitAll:
    for i in 0 ..< 3:
      print(&"Init worker #{i}...", lend="")
      master.spawn(launchWorker(i))
      print("OK.")

when isMainModule:
  main()
