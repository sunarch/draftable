# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from std/paths import Path
import std/streams as streams
from std/strformat import fmt
from std/strutils import split, strip, `%`

# project imports
import exit as exit


type SourceItem = object
  level: string = ""
  id: string = ""
  content: string = ""


proc parse_line(line: string): SourceItem =
  result = SourceItem()

  let split_iter: seq[string] = line.split('|', maxsplit=2)

  if split_iter.len != 3:
    exit.failure_msg(fmt"Malformatted meta in source line: '{line}'")

  result.level = split_iter[0].strip
  result.id = split_iter[1].strip
  result.content = split_iter[2].strip


func html_tag(tag: string, content: string, class: string = ""): string =
  result = fmt("<{tag} class=\"{class}\">{content}</{tag}>")


func table_row(content: string): string =
  result = html_tag("tr", content)


func table_cell(content: string): string =
  result = html_tag("td", content)


proc build_row(line: string): string =

  let source_item = parse_line(line)

  var content = source_item.content
  case source_item.level
    of "h1":
      content = html_tag("h1", content)
    of "h2":
      content = html_tag("h2", content)
    of "p1":
      content = content
    of "p2":
      let prefix = html_tag("span", "    ", "indent-1")
      content = fmt"{prefix}{content}"
    else:
      content = content

  let cell_id = table_cell(source_item.id)
  let cell_content = table_cell(content)

  result = table_row(fmt"{cell_id}{cell_content}")


proc build*(main_file_path: Path): string =
  result = ""

  var strm = streams.newFileStream(main_file_path.string, fmRead)
  defer: strm.close()

  if isNil(strm):
    return

  var line = ""

  while strm.readLine(line):

    if line == "":
      continue

    let row = build_row(line)
    result = fmt"{result}{row}"
