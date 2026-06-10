open Printf

exception Transpile_error of int * string

type frame =
  | Block of string * int
  | Literal of int

let is_space = function
  | ' ' | '\t' | '\n' | '\r' -> true
  | _ -> false

let is_ident_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let trim = String.trim

let ends_with_colon s =
  let trimmed = trim s in
  let len = String.length trimmed in
  len > 0 && trimmed.[len - 1] = ':'

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
  | "module" -> "endmodule", ";"
  | "interface" -> "endinterface", ";"
  | "package" -> "endpackage", ";"
  | "program" -> "endprogram", ";"
  | "function" -> "endfunction", ";"
  | "task" -> "endtask", ";"
  | "class" -> "endclass", ";"
  | "clocking" -> "endclocking", ";"
  | "checker" -> "endchecker", ";"
  | "covergroup" -> "endgroup", ";"
  | "sequence" | "randsequence" -> "endsequence", ";"
  | "property" -> "endproperty", ";"
  | "primitive" -> "endprimitive", ""
  | "config" -> "endconfig", ""
  | "case" | "casex" | "casez" -> "endcase", ""
  | "generate" -> "endgenerate", ""
  | "specify" -> "endspecify", ""
  | "if" | "else" | "for" | "while" | "do" | "repeat" | "forever"
  | "always" | "always_comb" | "always_ff" | "always_latch"
  | "initial" | "final" -> "end", " begin"
  | _ -> "end", " begin"
  end
  | None -> "", "{"

let top_is_endcase stack =
  not (Stack.is_empty stack) &&
  match Stack.top stack with
  | Block ("endcase", _) -> true
  | _ -> false

let bump_line line c = if c = '\n' then line + 1 else line

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

let rec parse_concat input start line0 =
  let len = String.length input in
  let out = Buffer.create 64 in
  let split = ref None in
  let add_char c =
    match !split with
    | None -> Buffer.add_char out c
    | Some rhs -> Buffer.add_char rhs c
  in
  let rec loop i line =
    if i >= len then raise (Transpile_error (line0, "unterminated ${...} concat"))
    else if input.[i] = '}' then
      let left = trim (Buffer.contents out) in
      begin match !split with
      | None -> (i + 1, line, "{" ^ left ^ "}")
      | Some rhs ->
          let rhs_text = trim (Buffer.contents rhs) in
          if rhs_text = "" then raise (Transpile_error (line, "missing repeated concat expression"));
          (i + 1, line, "{" ^ left ^ "{" ^ rhs_text ^ "}}")
      end
    else if i + 1 < len && input.[i] = '$' && input.[i + 1] = '{' then begin
      let next_i, next_line, nested = parse_concat input (i + 2) line in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) nested;
      loop next_i next_line
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '/' then begin
      let next_i, comment = read_line_comment input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) comment;
      loop next_i (String.fold_left bump_line line comment)
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '*' then begin
      let next_i, comment = read_block_comment input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) comment;
      loop next_i (String.fold_left bump_line line comment)
    end else if input.[i] = '"' then begin
      let next_i, str = read_string input i in
      Buffer.add_string (match !split with None -> out | Some rhs -> rhs) str;
      loop next_i (String.fold_left bump_line line str)
    end else if input.[i] = ';' && Option.is_none !split then begin
      split := Some (Buffer.create 32);
      loop (i + 1) line
    end else begin
      add_char input.[i];
      loop (i + 1) (bump_line line input.[i])
    end
  in
  loop start line0

let transpile input =
  let len = String.length input in
  let out = Buffer.create (len * 2) in
  let header = Buffer.create 128 in
  let stack = Stack.create () in
  let header_paren_depth = ref 0 in
  let push_regular c =
    if c = '(' then incr header_paren_depth;
    if c = ')' && !header_paren_depth > 0 then decr header_paren_depth;
    Buffer.add_char header c;
    Buffer.add_char out c;
    if c = ';' && !header_paren_depth = 0 then Buffer.clear header
  in
  let rec loop i line =
    if i >= len then ()
    else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '/' then begin
      let next_i, comment = read_line_comment input i in
      Buffer.add_string out comment;
      loop next_i (String.fold_left bump_line line comment)
    end else if i + 1 < len && input.[i] = '/' && input.[i + 1] = '*' then begin
      let next_i, comment = read_block_comment input i in
      Buffer.add_string out comment;
      loop next_i (String.fold_left bump_line line comment)
    end else if input.[i] = '"' then begin
      let next_i, str = read_string input i in
      Buffer.add_string out str;
      loop next_i (String.fold_left bump_line line str)
    end else if i + 1 < len && input.[i] = '$' && input.[i + 1] = '{' then begin
      let next_i, next_line, concat = parse_concat input (i + 2) line in
      Buffer.add_string out concat;
      Buffer.clear header;
      loop next_i next_line
    end else if input.[i] = '{' then begin
      let frame, replacement =
        let current_header = Buffer.contents header in
        if ends_with_colon current_header then
          (Block ("end", line), " begin")
        else if top_is_endcase stack then
          (Block ("end", line), " begin")
        else begin
          let close, text = classify_header current_header in
          if close = "" then (Literal line, text) else (Block (close, line), text)
        end
      in
      Stack.push frame stack;
      Buffer.add_string out replacement;
      Buffer.clear header;
      loop (i + 1) line
    end else if input.[i] = '}' then begin
      if Stack.is_empty stack then raise (Transpile_error (line, "unexpected }"));
      begin match Stack.pop stack with
      | Block (close, _) -> Buffer.add_string out close
      | Literal _ -> Buffer.add_char out '}'
      end;
      Buffer.clear header;
      loop (i + 1) line
    end else begin
      let c = input.[i] in
      push_regular c;
      loop (i + 1) (bump_line line c)
    end
  in
  loop 0 1;
  if not (Stack.is_empty stack) then (
    match Stack.top stack with
    | Block (_, open_line)
    | Literal open_line -> raise (Transpile_error (open_line, "unbalanced Berilog delimiters"))
  );
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
  | Transpile_error (line, message) ->
      eprintf "berilog: line %d: %s\n" line message;
      exit 1
  | Stack.Empty ->
      eprintf "berilog: internal stack error\n";
      exit 1
  | Failure _ as exn ->
      eprintf "berilog: %s\n" (Printexc.to_string exn);
      exit 1
