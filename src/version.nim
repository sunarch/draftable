# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from std/strformat import fmt


const
  ProgramName* = "draftable"
  VersionMajor = 0
  VersionMinor = 1
  VersionPatch = 0
  CopyrightYears = "2024"
  CopyrightName = "András Németh"


func short: string =
  result = fmt"{VersionMajor}.{VersionMinor}.{VersionPatch}"


func long*: string =
  result = fmt"{ProgramName} {short()}"


func compiled*: string =
  result = fmt"Compiled on {COMPILE_DATE}"


func copyright*: string =
  result = fmt"Copyright (c) {CopyrightYears} by {CopyrightName}"
