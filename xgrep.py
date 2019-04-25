#!/usr/bin/env python3

from __future__ import with_statement, print_function

import sys
import re
import json
import os
from optparse import OptionParser

default_config_path = "~/xgrep-config.json"

config_defaults = {
  "exclude_dirs": {
    "description": "dict of name:directory_names to exclude-dir by default",
    "default": {
      "npm": "node_modules",
      "bower": "bower_components",
    },
  },
  "super_exclude_dirs": {
    "description": "dict of name:directory_names to exclude-dir by default, even for --every",
    "default": {
      "idea": ".idea",
      "git": ".git",
      "dist": "dist",
    },
  },
  "excludes": {
    "description": "dict of name:glob_patterns to exclude by default",
    "default": {
      "package": "package.json"
    },
  },
  "super_excludes": {
    "description": "dict of name:directory_names to exclude by default, even for --every",
    "default": {
      "gulpfile": "gulpfile.json",
    },
  },
  "groups": {
    "none": [
    ],
    "default": [
      "*.js",
      "*.htm",
      "*.html",
      "*.py",
      "*.json",
      "*.css",
    ],
    "node": [
      "*.js",
      "*.htm",
      "*.html",
      "*.json",
      "*.css",
      "package.json",
    ],
    "web": [
      "*.js",
      "*.htm",
      "*.html",
      "*.shtml",
      "*.json",
      "*.css",
      "*.scss",
      "*.sass",
    ],
    "node-web": [
      "*.js",
      "*.htm",
      "*.html",
      "*.shtml",
      "*.json",
      "*.css",
      "*.scss",
      "*.sass",
      "package.json",
    ],
    "c": [
      "*.c",
      "*.cpp",
      "*.h",
      "*.hpp",
    ],
  }

}

default_exclude_dirs = list(config_defaults['exclude_dirs']['default'].values())
default_super_exclude_dirs = list(config_defaults['super_exclude_dirs']['default'].values())
default_excludes = list(config_defaults['excludes']['default'].values())
default_super_excludes = list(config_defaults['super_excludes']['default'].values())

defaults = {
  'exclude_dirs': {},
  'super_exclude_dirs': {},
  'excludes': {},
  'super_excludes': {},
}


from collections import ChainMap


def error(s):
  sys.stderr.write(s)

def merge_dicts (high_priority, low_priority):
  return dict(ChainMap({}, high_priority, low_priority))

def read_config(options):
  config = {}
  path = os.path.expanduser(options.config_path)
  if os.path.exists(path):
    try:
      with open(path, 'r') as config_file:
        config = json.load(config_file)
    except TypeError as err:
      sys.stderr.write('Error: config file exists but is unparseable {path} with {err}\n'.format(path=path, err=err))
    except EnvironmentError as err:  # parent of IOError, OSError *and* WindowsError where available
      sys.stderr.write('Error: config file exists but is unreadable {path} with {err}\n'.format(path=path, err=err))

  for key, value in defaults.items():
    env_var = 'XGREP_' + key.upper()
    if env_var in os.environ:
      defaults[key] = {s.strip(): s.strip() for s in os.environ[env_var].split(',')}
    elif key in config:
      value = config[key]
      # treat as null, string(comma delimited), dict or array/list?
      if value is None:
        defaults[key] = {}
      elif hasattr(value, 'capitalize'):
        # string - split on commas
        defaults[key] = {s.strip(): s.strip() for s in value.split(',')}
      elif isinstance(value, dict):
        # dict, use as is
        defaults[key] = value
        # merged with factory defaults if _factory_ is truthy
        if '_factory_' in value:
          if value['_factory_']:
            defaults[key] = merge_dicts(value, config_defaults[key]['default'])
          # remove special key
          del defaults[key]['_factory_']
      elif isinstance(value, list):
        defaults[key] = {s.strip(): s.strip() for s in value}
      else:
        sys.stderr.write('Warning: unable to parse value in config for {}\n'.format(key))

    else:
      defaults[key] = config_defaults[key]['default']


def str_shell_quote(s):
  if re.match(r'^[-%+.-:=@-Z_a-z]*?$', s):
    return s
  else:
    return "'" + s.replace("'", "'\\''") + "'"


def shell_quote(s):
  if s == '':
    return "''"
  elif s == "'":
    return '"\'"'
  else:  # if s[0] == "'" or s[-1] == "'":
    match = re.match(r'(\'*)(.*?)(\'*)$', s)
    return "\\'" * len(match[1]) + str_shell_quote(match[2]) + "\\'" * len(match[3])


def main():
  parser = OptionParser()
  parser.add_option("-V", "--xverbose", "--verbose", action="store_true", dest="verbose", default=False,
      help="xgrep verbose output")
  parser.add_option("--config-path", action="store", dest="config_path", default=default_config_path,
      help="path for user's config file to override defaults")
  parser.add_option("--gverbose", action="store_true", dest="gverbose", default=False,
      help="grep/egrep/fgrep verbose output")
  parser.add_option("--list", action="store_true", dest="list_files", default=False,
      help="list files that would be searched")
  parser.add_option("-v", "--invert-match", action="store_true", dest="invert", default=False,
      help="invert match")
  parser.add_option("-o", "--only-matching", action="store_true", dest="only", default=False,
      help="invert match")
  parser.add_option("-i", "--ignore-case", action="store_true", dest="ignore", default=False,
      help="ignore case")
  parser.add_option("-f", "--fixed-string", action="store_true", dest="fixed", default=False,
      help="fixed string")
  parser.add_option("-F", "--git-fixed", action="store_true", dest="git_fixed", default=False,
      help="use git grep with fixed string(s) (fgrep style)")
  parser.add_option("-G", "--git-extended", action="store_true", dest="git_extended", default=False,
      help="use git grep with POSIX extended regex (egrep style)")
  parser.add_option("-g", "--git-pcre", action="store_true", dest="git_pcre", default=False,
      help="use git grep with pcre regex (Perl)")

  parser.add_option("-w", "--word", action="store_true", dest="word_match", default=False,
      help="match whole words only, force use of git grep")

  parser.add_option("-c", "--count", action="store_true", dest="show_count", default=False,
      help="show counts of matches only")

  parser.add_option("--no-color", action="store_false", dest="color", default=True,
      help="supress color in output")
  parser.add_option("--no-line-num", action="store_false", dest="lineNum", default=True,
      help="supress line number in output")
  parser.add_option("--no-file-name", action="store_false", dest="fileName", default=True,
      help="supress file name in output")

  parser.add_option("-x", "--group", action="store", dest="group", default="default",
      help="pattern groups, one of {}".format(", ".join(config_defaults['groups'].keys())))

  parser.add_option("--exclude", action="append", dest="extra_excludes", default=[],
      help="additionally exclude files by another glob")
  parser.add_option("--exclude-dir", action="append", dest="extra_exclude_dirs", default=[],
      help="additionally exclude directories by another glob")

  parser.add_option("--include", "--unexclude", action="append", dest="exclude_overrides", default=[],
      help="search directories")

  parser.add_option("-e", "--every", action="store_true", dest="include_every", default=False,
      help="include directories & paths normally skipped like: {}".format(', '.join(default_exclude_dirs + default_excludes)))
  parser.add_option("--every-directory", action="store_true", dest="include_everyting_dir", default=False,
      help="include directories normally skipped like: {}".format(', '.join(default_super_exclude_dirs)))
  parser.add_option("--super-every-directory", action="store_true", dest="super_include_everyting_dir", default=False,
      help="include directories normally always skipped like: {}".format(', '.join(default_super_exclude_dirs)))
  parser.add_option("--every-path", action="store_true", dest="include_everyting_path", default=False,
      help="include directories normally skipped like: {}".format(', '.join(default_excludes)))
  parser.add_option("--super-every-path", action="store_true", dest="super_include_everyting_path", default=False,
      help="include directories normally always skipped like: {}".format(', '.join(default_super_excludes)))

  parser.add_option("--dir", action="append", dest="search_dirs", default=[],
      help="search directories")

  parser.add_option("--only", action="append", dest="only_pats", default=[],
      help="only search these file patterns, e.g. --only='*.txt'")
  parser.add_option("--also", action="append", dest="also_pats", default=[],
      help="also search these file patterns, e.g. --also='*.txt'")

  parser.add_option("--debug", action="store_true", dest="debug_mode", default=False,
      help="xgrep debug mode, just output grep command")

  (options, args) = parser.parse_args()

  read_config(options)

  using_git = False

  if options.verbose or options.debug_mode:
    def verbose(s):
      sys.stderr.write(s)
  else:
    def verbose(s):
      pass

  if options.list_files:
    args = ['^']

  if len(args) == 0:
    sys.stderr.write('ERROR: Missing string to search\n')
    sys.stdout.write('exit 1')
    sys.exit()

  if '(' in args or 'AND' in args or 'OR' in args or 'NOT' in args or ')' in args:
    if not options.git_fixed and not options.git_extended and not options.git_pcre:
      options.git_extended = True

  # =========== MODES ===========

  if options.list_files:
    verbose('Mode: listing files to be searched only\n')
    cmd = 'grep -lEr '
  elif options.git_fixed:
    using_git = True
    cmd = 'git grep -f '
  elif options.git_extended:
    using_git = True
    cmd = 'git grep -E '
  elif options.git_pcre or options.word_match:
    using_git = True
    cmd = 'git grep -P '
  elif options.fixed:
    verbose('Mode: searching for fixed string\n')
    cmd = 'grep -Fr '
  else:
    verbose('Mode: searching with extended regular expression(s)\n')
    cmd = 'egrep -Er '

  if using_git and not os.path.exists('.git') and not os.path.exists('../.git') and not os.path.exists('../../.git'):
    cmd += '--no-index '

  if using_git:
    cmd += '--threads 4 '

  # =========== MISC OPTIONS ===========

  cmd += '-V ' if options.ignore and not using_git else ''
  cmd += '-i ' if options.ignore else ''
  cmd += '-c ' if options.show_count else ''

  if not options.list_files:
    cmd += '-o ' if options.only else ''
    cmd += '-n ' if options.lineNum else ''
    cmd += '-H ' if options.fileName else '-h '
  cmd += '-i ' if options.invert else ''
  cmd += '--color ' if options.color else ''

  cmd += '--word-regexp ' if options.word_match else ''

  # =========== SEARCH TERMS ===========

  terms = ''
  op = ''
  for n, term in enumerate(args):
    if term in ['AND', 'OR', 'NOT'] and using_git:
      terms += '--' + term.lower() + ' '
      op = term + ' '
    elif term == '(' or term == ')':
      terms += '\\' + term + ' '
    else:
      op = 'or' if op == '' else op
      verbose('{}: {}\n'.format('Search for' if n == 0 else '%10s' % op, term))
      term = re.sub(r"``", "'", term)
      terms += '-e ' + shell_quote(term) + ' '

  if not using_git:
    cmd += terms

  # =========== PATHS TO SEARCH ===========

  places = ''

  if len(options.search_dirs):
    for n, dir in enumerate(options.search_dirs):
      verbose('{} directory: {}\n'.format('Searching' if n == 0 else '      and', dir))
    places += ' '.join(options.search_dirs) + ' '
  else:
    verbose('Searching working directory\n')
    places += '. '

  if not using_git:
    cmd += places

  # =========== INCLUDE: FILES TO SEARCH ===========

  to_search_pats = ''
  if options.group not in config_defaults['groups'].keys():
    error('Error: unknown group: "{}"'.format(options.group))
    sys.exit(1)
  builtin_pats = config_defaults['groups'][options.group]

  pats = (options.only_pats + options.also_pats) if len(options.only_pats) else (builtin_pats + options.also_pats)

  if len(pats):
    for n, pat in enumerate(pats):
      verbose('{} files that match: {}\n'.format('Scanning' if n == 0 else '     and', pat))
      to_search_pats += "--include=" + shell_quote(pat) + " "
  else:
    verbose('Scanning all files\n')

  if not using_git:
    cmd += to_search_pats

  # =========== EXCLUDE: DIRS & GLOBS TO SKIP ===========

  def skipped(name, value, everything, super):
    return (name in options.exclude_overrides or value in options.exclude_overrides or
        everything or (not super and options.include_every))

  global grep_excludes, git_excludes
  grep_excludes = ''
  git_excludes = ''

  def add_exclude_dir(value):
    global grep_excludes, git_excludes
    grep_excludes += '--exclude-dir=' + shell_quote(value) + ' '
    git_excludes += shell_quote(':!**/' + value + '/*') + ' '

  def add_exclude(value):
    global grep_excludes, git_excludes
    grep_excludes += '--exclude=' + shell_quote(value) + ' '
    git_excludes += shell_quote(':!**/' + value) + ' '

  # ----------- dirs -----------

  for name, value in defaults['exclude_dirs'].items():
    if skipped(name, value, options.include_everyting_dir, False):
      verbose('Not excluding directory: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
    else:
      verbose('Excluding directory: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
      add_exclude_dir(value)

  for name, value in defaults['super_exclude_dirs'].items():
    if skipped(name, value, options.super_include_everyting_dir, True):
      verbose('Not excluding directory: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
    else:
      verbose('Excluding directory: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
      add_exclude_dir(value)

  for value in options.extra_exclude_dirs:
    verbose('Excluding directory [extra]: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
    add_exclude_dir(value)

  # ----------- globs -----------

  for name, value in defaults['excludes'].items():
    if skipped(name, value, options.include_everyting_path, False):
      verbose('Not excluding glob path: {}\n'.format(value))
    else:
      verbose('Excluding glob path: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
      add_exclude(value)

  for name, value in defaults['super_excludes'].items():
    if skipped(name, value, options.super_include_everyting_path, True):
      verbose('Not excluding glob path: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
    else:
      verbose('Excluding glob path: {}{}\n'.format(value, '' if name == value else ' [{}]'.format(name)))
      add_exclude(value)

  for value in options.extra_exclude_dirs:
    verbose('Excluding glob path [extra]: {}\n'.format(value))
    add_exclude(value)

  if not using_git:
    cmd += grep_excludes

  # =========== END STUFF ===========

  if using_git:
    cmd += terms
    cmd += '-- '
    cmd += places + git_excludes
    cmd += '| cat'

  # =========== OUTPUT ===========

  if options.verbose:
    sys.stderr.write('\x1B[36m' + cmd + '\x1B[0m\n')

  if options.debug_mode:
    cmd = 'echo ' + shell_quote(cmd)

  sys.stdout.write(cmd)

if __name__ == "__main__":
   main()
