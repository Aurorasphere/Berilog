open Printf

type frame =
  | Block of string
  | Literal

let is_space = function
  | ' ' | '\t' | '\n' | '\r' -> true
  | _ -> false

let is_ident_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let trim = String.trim

let supported_keyword = function
  | "module" | "interface" | "package" | "program" | "function" | "task"
  | "class" | "clocking" | "checker" | "covergroup" | "sequence" | "randsequence" | "property"
  | "primitive" | "config"
  | "case" | "casex" | "casez" | "generate" | "specify"
  | "if" | "else" | "for" | "while" | "do" | "repeat" | "forever"
  | "always" | "always_comb" | "always_ff" | "always_latch"
  | "initial" | "final" -> true
  | _ -> false

let last_supported_keyword header =
  let len = String.length header in
  let rec loop i last =
    if i >= len then last
    else if is_ident_char header.[i] && not (Char.code header.[i] >= Char.code '0' && Char.code header.[i] <= Char.code '9') then
      let j = ref (i + 1) in
      while !j < len && is_ident_char header.[!j] do
        incr j
      done;
      let word = String.sub header i (!j - i) |> String.lowercase_ascii in
      let next = if supported_keyword word then Some word else last in
      loop !j next
    else
      loop (i + 1) last
  in
  loop 0 None

let classify_header header =
  match last_supported_keyword header with
  | Some keyword -> begin match keyword with
  | "module" -> Block "endmodule", ";"
  | "interface" -> Block "endinterface", ";"
  | "package" -> Block "endpackage", ";"
  | "program" -> Block "endprogram", ";"
  | "function" -> Block "endfunction", ";"
  | "task" -> Block "endtask", ";"
  | "class" -> Block "endclass", ";"
  | "clocking" -> Block "endclocking", ";"
  | "checker" -> Block "endchecker", ";"
  | "covergroup" -> Block "endgroup", ";"
  | "sequence" | "randsequence" -> Block "endsequence", ";"
  | "property" -> Block "endproperty", ";"
  | "primitive" -> Block "endprimitive", ""
  | "config" -> Block "endconfig", ""
  | "case" | "casex" | "casez" -> Block "endcase", ""
  | "generate" -> Block "endgenerate", ""
  | "specify" -> Block "endspecify", ""
  | "if" | "else" | "for" | "while" | "do" | "repeat" | "forever"
  | "always" | "always_comb" | "always_ff" | "always_latch"
  | "initial" | "final" -> Block "end", " begin"
  | _ -> Block "end", " begin"
  end
  | None -> Literal, "{"

let read_string input start =
  let len = String.length input in
  let out = Buffer.create 32 in
  Buffer.add_char out '"';
  let i = ref (start + 1) in
  let escaped = ref false in
  while !i < len && (!escaped || input.[!i] <> '"') do
    let c = input.[!i] in
    Buffer.add_char out c;
    escaped := c = '\\' && not !escaped;
    if c <> '\\' then escaped := false;
    incr i
  done;
  if !i < len then Buffer.add_char out '"';
  (min len (!i + 1), Buffer.contents out)

let read_line_comment input start =
  let len = String.length input in
  let out = Buffer.create 32 in
  Buffer.add_string out "//";
  let i = ref (start + 2) in
  while !i < len && input.[!i] <> '\n' do
    Buffer.add_char out input.[!i];
    incr i
  done;
  (!i, Buffer.contents out)

let read_block_comment input start =
  let len = String.length input in
  let out = Buffer.create 32 in
  Buffer.add_string out "/*";
  let i = ref (start + 2) in
  while !i + 1 < len && not (input.[!i] = '*' && input.[!i + 1] = '/') do
    Buffer.add_char out input.[!i];
    incr i
  done;
  if !i + 1 < len then Buffer.add_string out "*/";
  (min len (!i + 2), Buffer.contents out)

let rec parse_concat input start =
  let len = String.length input in
  let out = Buffer.create 64 in
  let split = ref None in
  let add_char c =
    match !split with
    | None -> Buffer.add_char out c
    | Some rhs -> Buffer.add_char rhs c
  in
  let rec loop i =
    if i >= len then failwith "unterminated concat"
    else if input.[i] = '}' then
      let left = trim (Buffer.contents out) in
      begin match !split with
      | None -> (i + 1, "{" ^ left ^ "}")
      | Some rhs -> (i + 1, "{" ^ left ^ "{" ^ trim (Buffer.contents rhs) ^ "}}")
      end
    else if i + 1 < len && input.[i] = '$' && input.[i + 1] = '{' then begin
      let next_i, nested = parse_concat input (i + 2) in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) nested;
      loop next_i
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '/' then begin
      let next_i, comment = read_line_comment input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) comment;
      loop next_i
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '*' then begin
      let next_i, comment = read_block_comment input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) comment;
      loop next_i
    end else if input.[i] = '"' then begin
      let next_i, str = read_string input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) str;
      loop next_i
    end else if input.[i] = ';' && Option.is_none !split then begin
      split := Some (Buffer.create 32);
      loop (i + 1)
    end else begin
      add_char input.[i];
      loop (i + 1)
    end
  in
  loop start

let transpile input =
  let len = String.length input in
  let out = Buffer.create (len * 2) in
  let header = Buffer.create 128 in
  let stack = Stack.create () in
  let push_regular c =
    Buffer.add_char header c;
    Buffer.add_char out c;
    if c = ';' then Buffer.clear header
  in
  let rec loop i =
    if i >= len then ()
    else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '/' then begin
      let next_i, comment = read_line_comment input i in
      Buffer.add_string out comment;
      loop next_i
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '*' then begin
      let next_i, comment = read_block_comment input i in
      Buffer.add_string out comment;
      loop next_i
    end else if input.[i] = '"' then begin
      let next_i, str = read_string input i in
      Buffer.add_string out str;
      loop next_i
    end else if i + 1 < len && input.[i] = '$' && input.[i + 1] = '{' then begin
      let next_i, concat = parse_concat input (i + 2) in
      Buffer.add_string out concat;
      Buffer.clear header;
      loop next_i
    end else if input.[i] = '{' then begin
      let frame, replacement = classify_header (Buffer.contents header) in
      Stack.push frame stack;
      Buffer.add_string out replacement;
      Buffer.clear header;
      loop (i + 1)
    end else if input.[i] = '}' then begin
      begin match Stack.pop stack with
      | Block close -> Buffer.add_string out close
      | Literal -> Buffer.add_char out '}'
      end;
      Buffer.clear header;
      loop (i + 1)
    end else begin
      let c = input.[i] in
      push_regular c;
      loop (i + 1)
    end
  in
  loop 0;
  if not (Stack.is_empty stack) then failwith "unbalanced Berilog delimiters";
  Buffer.contents out

let read_all ic = In_channel.input_all ic

type cli = {
  input_path : string option;
  output_path : string option;
}

let usage = "usage: berilog [input.b] [-o output.sv|output_dir]"

let parse_args () =
  let rec loop args cli =
    match args with
    | [] -> cli
    | "-o" :: path :: rest -> loop rest { cli with output_path = Some path }
    | "-o" :: [] -> failwith usage
    | path :: rest ->
        begin match cli.input_path with
        | None -> loop rest { cli with input_path = Some path }
        | Some _ -> failwith usage
        end
  in
  loop (List.tl (Array.to_list Sys.argv)) { input_path = None; output_path = None }

let read_input cli =
  match cli.input_path with
  | None ->
      if Unix.isatty Unix.stdin then failwith usage;
      read_all stdin
  | Some path -> In_channel.with_open_bin path read_all

let output_name_from_input input_path =
  let base = Filename.basename input_path in
  let stem =
    try Filename.chop_extension base with
    | Invalid_argument _ -> base
  in
  stem ^ ".sv"

let resolve_output_path cli path =
  if Sys.file_exists path && Sys.is_directory path then
    match cli.input_path with
    | Some input_path -> Filename.concat path (output_name_from_input input_path)
    | None -> failwith "-o directory requires an input file path"
  else
    path

let write_output cli output =
  match cli.output_path with
  | None -> output_string stdout output
  | Some path ->
      let resolved = resolve_output_path cli path in
      Out_channel.with_open_bin resolved (fun oc -> output_string oc output)

let run () =
  let cli = parse_args () in
  let input = read_input cli in
  let output = "// Auto-generated with Aurorasphere's Berilog transcompiler\n" ^ transpile input in
  write_output cli output

let () =
  try run () with
  | Stack.Empty
  | Failure _ as exn ->
      eprintf "berilog: %s\n" (Printexc.to_string exn);
      exit 1
