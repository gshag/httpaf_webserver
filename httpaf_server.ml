module MySys = Sys

open Core
open Async
open Httpaf_async

let main port () =
  let where_to_listen = Tcp.Where_to_listen.of_port port in
  let request_handler _ = Httpaf_examples.Server.benchmark in
  let error_handler _ = Httpaf_examples.Server.error_handler in
  Tcp.(Server.create_sock ~on_handler_error:`Ignore
      ~backlog:11_000 ~max_connections:10_000 where_to_listen)
    (Server.create_connection_handler ~request_handler ~error_handler)
  >>= fun server ->
  Deferred.forever () (fun () ->
    Clock.after Time.Span.(of_sec 0.5) >>| fun () ->
      Log.Global.printf "conns: %d" (Tcp.Server.num_connections server));
  Deferred.never ()

let exit_handle _ =
  Stdlib.exit 0

let attach_handler () =
  let open MySys in
  set_signal sigint (Signal_handle exit_handle)

let () =
  attach_handler ();
  Command.async
    ~summary:"Start a hello world Async server"
    (Command.Param.return (main 8080))
  |> Command.run;
