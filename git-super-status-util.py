#!/usr/bin/env python

import sys, re, json

if len(sys.argv) > 2 and sys.argv[1] == 'strip':
  print(re.sub(r"%\{|%\}|%[1-9]?G","",sys.argv[2]))

elif len(sys.argv) > 5 and sys.argv[1] == 'diff':
  before = sys.argv[2].split('\n')
  after = sys.argv[3].split('\n')
  begin_mark = sys.argv[4]
  end_mark = sys.argv[5]

  # [won't work in 2.6] before_lines = {line.split(':',1)[0]:line for line in before}
  before_lines = {}
  for line in before:
    before_lines[line.split(':',1)[0]] = line

  keep_diffing = True
  for i, line in enumerate(after):
    key, value = line.split(':', 1) if ':' in line else (line, ' ')
    if key in before_lines.keys() and before_lines[key] != line and keep_diffing:
      if 'Root' in key:
        keep_diffing = False
      else: 
        pass
      if '%{' in line:
        after[i] = begin_mark + key + ':' + end_mark + value
      else:
        after[i] = begin_mark + line + end_mark

  print('\n'.join(after))

else:
  raise ValueError('First parameter should be one of: strip, diff')