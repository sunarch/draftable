# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from std/paths import Path
import std/streams as streams
from std/strformat import fmt
from std/strutils import split, strip, `%`


type SourceItem = object
  level: string = ""
  id: string = ""
  content: string = ""


func html_tag(tag: string, content: string, class: string = ""): string =
  result = fmt("<{tag} class=\"{class}\">{content}</{tag}>")


func parse_line(line: string): SourceItem =
  result = SourceItem()

  let split_iter: seq[string] = line.split('|', maxsplit=2)

  if split_iter.len != 3:
    result.level = "p1"
    result.id = "**WARN**"
    let content_prefix = html_tag("b", "Malformed meta in source line:")
    result.content = fmt"{content_prefix} '{line}'"
    return

  result.level = split_iter[0].strip
  result.id = split_iter[1].strip
  result.content = split_iter[2].strip


func table_row(content: string): string =
  result = html_tag("tr", content)


func table_cell(content: string): string =
  result = html_tag("td", content)


func build_row(line: string): string =

  let source_item = parse_line(line)

  var content = source_item.content
  case source_item.level
    of "#":  # Heading 1
      content = html_tag("h1", content)
    of "##":  # Heading 2
      content = html_tag("h2", content)
    of "###":  # Heading 3
      content = html_tag("h3", content)
    of "####":  # Heading 4
      content = html_tag("h4", content)
    of "#####":  # Heading 5
      content = html_tag("h5", content)
    of "######":  # Heading 6
      content = html_tag("h6", content)
    of "p1":
      content = content
    of "p2":
      let prefix = html_tag("span", "    ", "indent-1")
      content = fmt"{prefix}{content}"
    else:
      let prefix_unformatted = "[**UNFORMATTED**]"
      content = fmt"{prefix_unformatted}{content}"

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
