#!/usr/bin/env python3

import argparse
import datetime
import os
import re
import sys
from enum import IntEnum

LINE_SUB = 's'
FILE_SUB = 'S'
LINE_FIXED_SUB = 'f'
FILTER = 'g'
LINE_FILTER = 'G'
EXCLUDE = 'x'
LINE_EXCLUDE = 'X'
LINE_ONLY = 'o'
FILE_ONLY = 'O'
LINE_REMOVE = 'r'
FILE_REMOVE = 'R'
LINE_UPPER = 'u'
FILE_UPPER = 'U'
LINE_LOWER = 'l'
FILE_LOWER = 'L'
LINE_TITLE = 't'
FILE_TITLE = 'T'
LINE_CAPITALIZE = 'c'
FILE_CAPITALIZE = 'C'
LINE_PREPEND = 'p'
FILE_PREPEND = 'P'
LINE_APPEND = 'a'
FILE_APPEND = 'A'
LINE_INSERT = 'i'
FILE_INSERT = 'I'
LINE_REPLACE = 'y'
FILE_REPLACE = 'Y'
LINE_DELETE = 'd'
FILE_DELETE = 'D'
ALL_FILTERS = [FILTER, LINE_FILTER, EXCLUDE, LINE_EXCLUDE, LINE_ONLY, LINE_REMOVE]

ANSI_BLACK = '\u001b[30m'
ANSI_RED = '\u001b[31m'
ANSI_GREEN = '\u001b[32m'
ANSI_YELLOW = '\u001b[33m'
ANSI_BLUE = '\u001b[34m'
ANSI_MAGENTA = '\u001b[35m'
ANSI_CYAN = '\u001b[36m'
ANSI_WHITE = '\u001b[37m'
ANSI_RESET = '\u001b[0m'
ANSI_BOLD = '\u001b[1m'
ANSI_UNDERLINE = '\u001b[4m'
ANSI_REVERSE = '\u001b[7m'

EPILOG = '''
<mark-over>Commands:

    s - regexp substitution within lines
    S - regexp substitution across lines, regexp match can span lines† 
    f - fixed string substitution within lines (shorthand for `s` & -F)
    g - [grep] regexp filter lines, keep only lines with one more more matches
    G - regexp filter lines, keep only lines that completely match
    x - [exclude] regexp filter lines, keep only lines WITHOUT one more more matches
    X - regexp filter lines, keep only lines that DO NOT completely match
    o - [only] regexp filter lines keeping only the matching parts of lines
    O - Only keep part(s) of the file that matches the regexp†
    r - regexp filter lines removing only the matching parts of lines
    R - Only remove part(s) of the file that matches the regexp†
    l - transform match to lower case by line
    L - transform match to lower case across lines†
    u - transform match to upper case by line
    U - transform match to upper case across lines†
    t - transform match to title case by line
    T - transform match to title case across lines¹
    c - transform match to a capitalized sentence by line
    C - transform match to a capitalized sentence across lines†
    a - append lines
    A - append characters
    p - prepend lines
    P - prepend characters
    i - insert by line number 'i/<pos>/str/' 1: after the first line, -1: before the last line
    I - insert at character position  'I/<pos>/str/' 1: after the first char, -1: before the last char
    y - replace lines 'y/<pos>/<count>/str/'
    Y - replace characters 'y/<pos>/<count>/str/'
    d - delete lines by line number and count
    D - delete characters by position and count

Commands are processed in the order they appear, usually
consisting of a one character operation code and parameters
delimited by a slash or other punctuation, for example:

  s/this/that/

would invoke the `s` for substitution operation which would replace
all occurrences of `this` with `that`. The first parameter is a
regular expression and the second is the replacement string. Though
similar to the venerable sed command, the regular expressions are
python compatible, see: https://tinyurl.com/py3-re-syntax . 

Delimiters can be any punctuation character so no meta-escaping is needed,
for example to change all slashes to underscores you could use:

  s:/:_:

Also, the trailing delimiter is optional, the following is identical to 
the preceding:

  s:/:_

Use of single quotes is recommended to avoid shell pattern and meta-character  
issues:

  $> ped -f input 's:$:_'

The substitution command with a uppercase `S` can use patterns that span lines, 
so if you wanted to change Fred Flintstone to Barney Rubble even if Fred was 
at the end of one line and Flintstone was at the beginning of the next you might
use:

  $> ped -f story.txt 'S/Fred(\\s+)Flintstone/Barney\\1Rubble'

Explanations: \\s matches any white space character, \\s+ matches one or more
whitespace, e.g. a space at the end of the line AND the line ending character(s)
AND any indentation on the next line. Using \\1 in the replacement preserves whatever
whitespace existed between Fred and Flintstone.

The fixed `f` command is shorthand for `s` with the --fixed or -F option. The pattern
is treated as a literal string, not a regular expression. All of these examples are
equivalent:

  $> ped -f story.txt 'f/./!/'
  $> ped -f story.txt --fixed 's/./!/'
  $> ped -f story.txt 's/\\./!/'

Filtering

The `g`, `G`, `x`, `X`, `o` filter text line by line:

  `g` - keep only lines that have a match anywhere on the line (like egrep)
  `G` - keep only lines that completely match (excluding the line endings \\n and/or \\r) (like egrep -x)
  `x` - keep only lines that DON'T have a match anywhere on the line (like egrep -v)
  `X` - keep only lines that DON'T completely match (excluding the line endings \\n and/or \\r) (like egrep -v -x)
  `o` - keep only the part(s) of lines that match, lines with no match are eliminated. (like egrep -o²)

Removing matches 

`r` will remove matches within a line, `R` will remove matches even if patterns span lines. These 
commands are shorthand for for `s` and `S` with an empty replacement string.

Case changing commands

`l`, `L`, `u`, `U`, `t`, `T`, `c`, `C` replace matches with a lowercase, uppercase, title case 
and capitalized sentence transformation of the matched text. The upper case versions 
can match text across lines. Consult official python documentation for the technical 
specification for each of these operations. See: https://docs.python.org/3/library/stdtypes.html#string-methods

  $> ped -f story.txt -i 'U/fred\\s+flintstone/'

Appending & Prepending

`a`, `p` are used to append and prepend a line³ based on the POSIX definition⁴ of lines.
`A`, `P` are used to append and prepend characters to the input without regard to lines

  $> ped -f shopping-list.txt 'a/eggs/'

Line number operations

`i`, `y`, `d` are used to insert, replace and delete lines by line number, negative values index from 
the last line up. 0 positions before the first line, 1 positions after the first line, -1 positions
before the last line. For the case of replace and delete the number of lines are specified with a second 
numeric parameter. Replace `y` takes a third parameter of text to use for the replacement as literal text
without any escaping supported or required. positions and/or counts are clamped to the range of data.

  $> ped -f shopping-list.txt 'i/0/avocados/'   # same as prepend
  $> ped -f shopping-list.txt 'i/1/eggs/'       # eggs are inserted as the second line
  $> ped -f shopping-list.txt 'y/2/3/eggs'      # eggs replace the 3rd, 4th and 5th items on the list
  $> ped -f shopping-list.txt 'y/-2/2/eggs'     # eggs replace the last two items on the list
  $> ped -f shopping-list.txt 'd/5/1'           # delete 6th line
  $> ped -f shopping-list.txt 'd/-2/2'          # delete last two lines

¹ you will often want to use the --dotall option so that a dot `.` will match any
character including line separators like \\r and \\n.

² there is a subtle difference, egrep -o will create multiple lines of output for multiple matches on
the same line

³ embedded line termination characters will effectively append multiple lines

⁴ POSIX defines a line as including a line ending character so a empty input (file) is considered to have zero lines 
'''.strip()

# ¹²³⁴⁵⁶⁷⁸⁹⁰

DESCRIPTION = 'make edit to text file, line endings will be normalized to the os convention'


def main(argv):
    parser = argparse.ArgumentParser(description=DESCRIPTION, epilog=EPILOG, formatter_class=CustomFormatter)
    parser.add_argument('commands', metavar='COMMAND', type=str, nargs='*', help='edit command')
    parser.add_argument('-f', '--filepath', metavar='FILE', dest='path', action='store', type=str,
                        default='-', help='file to edit, `-` for stdin')
    parser.add_argument('-e', '--in-place', dest='inplace', action='store_true', default=False,
                        help='edit in place, update source file while making backup')
    parser.add_argument('-i', '--ignore-case', dest='insensitive', action='store_const', default=0,
                        const=re.IGNORECASE, help='case insensitive matching')
    parser.add_argument('-n', '--normalize', dest='normalize', action='store_true', default=False,
                        help='normalize line endings, even when using multiline')
    parser.add_argument('-F', '--fixed', dest='fixed', action='store_true', default=False,
                        help='treat regular expression as a fixed string by quoting all meta char')
    parser.add_argument('-m', '--multiline', dest='multiline', action='store_const', default=0,
                        const=re.MULTILINE,
                        help=r'`^` and `$` match beginning and end of lines, \A and \Z match beginning and end of file')
    parser.add_argument('-d', '--dotall', dest='dotall', action='store_const', default=0,
                        const=re.DOTALL, help='dot `.` will match any character including line endings')
    parser.add_argument('-a', '--ascii', dest='ascii', action='store_const', default=0,
                        const=re.ASCII,
                        help=r'ascii mode where \w, \W, \b, \B, \d, \D, \s and \S only match ASCII characters')
    parser.add_argument('-b', '--backup-path', metavar='DIR', dest='backup_dir', action='store', type=str, nargs=1,
                        default='~/.ped-backups', help='backup directory')
    parser.add_argument('-E', '--line-ending', metavar='CHAR', dest='ending', action='store',
                        default=os.linesep, help='line ending to be used instead of platform default')
    parser.add_argument('-Z', '--no-eof', dest='eof', action='store_false',
                        default=True, help='suppress line ending on last line/end of file')
    parser.add_argument('-M', '--max-substitutions', metavar='NUMBER', dest='maxsub', action='store', type=int,
                        default=0, help='maximum total number of substitutions per command')
    parser.add_argument('-L', '--line-max-substitutions', metavar='NUMBER', dest='maxlinesub', action='store', type=int,
                        default=0, help='maximum total number of substitutions per line (for each command)')
    parser.add_argument('--force-color', dest='color', default=None, action='store_false',
                        help="force use of ANSI color adornment even if output stream does not appear to support it")
    parser.add_argument('--no-color', dest='color', default=None, action='store_true',
                        help="disable ANSI color adornment even if output stream appears to support it")
    args = parser.parse_args(argv)

    contents = sys.stdin.read() if args.path == '-' else get_file_contents(args.path)
    output = get_string(args, get_lines(args, contents)) if args.normalize else contents

    for item in args.commands:
        op = item[0]
        sep = item[1]
        if op == FILE_SUB or op == FILE_REMOVE:
            output = file_sub(args, output, item, op, sep)
        elif op == FILE_ONLY:
            output = file_only(args, output, item, op, sep)
        elif op == LINE_SUB or op == LINE_FIXED_SUB:
            output = line_sub(args, output, item, op, sep)
        elif op in ALL_FILTERS:
            output = filter_lines(args, output, item, op, sep)
        elif op in [LINE_UPPER, LINE_LOWER, LINE_TITLE, LINE_CAPITALIZE]:
            output = xform_lines(args, output, item, op, sep)
        elif op in [FILE_UPPER, FILE_LOWER, FILE_TITLE, FILE_CAPITALIZE]:
            output = xform_file(args, output, item, op, sep)
        elif op in [LINE_APPEND, LINE_PREPEND]:
            output = append_prepend_line(args, output, item, op, sep)
        elif op in [FILE_APPEND, FILE_PREPEND]:
            output = append_prepend_characters(args, output, item, op, sep)
        elif op == LINE_INSERT:
            output = insert_line(args, output, item, op, sep)
        elif op == FILE_INSERT:
            output = insert_chars(args, output, item, op, sep)
        elif op == LINE_REPLACE:
            output = replace_lines(args, output, item, op, sep)
        elif op == FILE_REPLACE:
            output = replace_chars(args, output, item, op, sep)
        elif op == LINE_DELETE:
            output = delete_lines(args, output, item, op, sep)
        elif op == FILE_DELETE:
            output = delete_chars(args, output, item, op, sep)
        else:
            raise PedError(f'Unknown command: "{item}" from the "{item}" command', PedErrorTypes.PED_UNKNOWN_COMMAND_ERROR)

    if args.inplace:
        raw_dir = args.backup_dir[0] if isinstance(args.backup_dir, list) else args.backup_dir
        backup_dir = os.path.expanduser(raw_dir)
        if not os.path.isdir(backup_dir):
            os.makedirs(backup_dir)
        if not os.path.isdir(backup_dir):
            raise PedError(f'Backup dir does not exist: {backup_dir}', PedErrorTypes.PED_IO_ERROR)
        backup_name = os.path.basename(args.path)
        ts = datetime.datetime.now().isoformat(timespec="seconds")
        backup_name = re.sub(r'((\.[^.]+)?$)', f'-{ts}\\1', backup_name, 1)
        backup_path = os.path.join(backup_dir, backup_name)
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(contents)
        with open(args.path, 'w', encoding='utf-8') as f:
            f.write(get_string(args, output))
    else:
        sys.stdout.write(get_string(args, output))


def join_lines(args: argparse.Namespace, lines):
    return args.ending.join(lines) + (args.ending if len(lines) and args.eof else '')


def get_lines(_args: argparse.Namespace, data):
    return data if isinstance(data, list) else data.splitlines()


def get_string(args: argparse.Namespace, data):
    return join_lines(args, data) if isinstance(data, list) else data


def get_normalized_lines(args: argparse.Namespace, data):
    return get_lines(args, get_string(args, data))


def param_str(cmd, sep='/'):
    str1, *_ = f'{cmd[2:]}{sep}'.split(sep, 2)
    return str1


def param_str_str(cmd, sep='/'):
    (str1, str2, *_) = f'{cmd[2:]}{sep}'.split(sep, 2)
    return str1, str2


def param_num_str(cmd, sep='/'):
    (num, s, *_) = f'{cmd[2:]}{sep}'.split(sep, 2)
    num = num.strip()
    if not re.match(r'^-?\d+$', num):
        raise ValueError(f'Expected a numeric parameter: "{num}"')
    return int(num), s


def param_num_num_str(cmd, sep='/'):
    (num1, num2, str1, *_) = f'{cmd[2:]}{sep}'.split(sep, 3)
    num1 = num1.strip()
    if not re.match(r'^-?\d+$', num1):
        raise ValueError(f'Expected a numeric parameter: "{num1}"')
    num2 = num2.strip()
    if not re.match(r'^-?\d+$', num2):
        raise ValueError(f'Expected a numeric parameter: "{num2}"')
    return int(num1), int(num2), str1


def param_num_num(cmd, sep='/'):
    (num1, num2, *_) = f'{cmd[2:]}{sep}'.split(sep, 2)
    num1 = num1.strip()
    if not re.match(r'^-?\d+$', num1):
        raise ValueError(f'Expected a numeric parameter: "{num1}"')
    num2 = num2.strip()
    if not re.match(r'^-?\d+$', num2):
        raise ValueError(f'Expected a numeric parameter: "{num2}"')
    return int(num1), int(num2)


def insert_line(args, data, item, _op, sep='/'):
    lines = get_lines(args, data)
    index, text = param_num_str(item, sep)
    if index < 0:
        count = len(lines)
        index = max(count + index, 0)
    lines.insert(index, text)
    return get_normalized_lines(args, lines) if '\n' in text else lines


def insert_chars(args, data, item, _op, sep='/'):
    data = get_string(args, data)
    index, text = param_num_str(item, sep)
    if index < 0:
        count = len(data)
        index = max(count + index, 0)
    return data[:index] + text + data[index:]


def replace_lines(args, data, item, _op, sep='/'):
    lines = get_lines(args, data)
    start, count, string = param_num_num_str(item, sep)
    return lines[:start] + string.splitlines() + lines[start + count:]


def replace_chars(args, data, item, _op, sep='/'):
    buf = get_string(args, data)
    start, count, string = param_num_num_str(item, sep)
    return buf[:start] + string + buf[start + count:]


def delete_lines(args, data, item, _op, sep='/'):
    lines = get_lines(args, data)
    start, count = param_num_num(item, sep)
    return lines[:start] + lines[start + count:]


def delete_chars(args, data, item, _op, sep='/'):
    buf = get_string(args, data)
    start, count = param_num_num(item, sep)
    return buf[:start] + buf[start + count:]


def append_prepend_line(args, data, item, op, sep='/'):
    lines = get_lines(args, data)
    string = param_str(item, sep)
    if op == LINE_APPEND:
        lines.append(string)
    else:
        lines.insert(0, string)
    return get_normalized_lines(args, lines) if '\n' in string else lines


def append_prepend_characters(args, data, item, op, sep='/'):
    string = param_str(item, sep)
    if op == FILE_APPEND:
        return get_string(args, data) + string
    return string + get_string(args, data)


def xform_file(args, data, item, op, sep='/'):
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    e = param_str(item, sep)
    e = re.escape(e) if args.fixed else e
    return re.sub(e, lambda m: xform(m, op), data, count=args.maxsub, flags=flags)


def xform_lines(args, data, item, op, sep='/'):
    lines = get_lines(args, data)
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    e = param_str(item, sep)
    e = re.escape(e) if args.fixed else e
    if args.maxsub > 0:
        maxsub = args.maxsub
        for i, line in enumerate(lines):
            subs = maxsub if args.maxlinesub == 0 else min(maxsub, args.maxlinesub)
            lines[i], count = re.subn(e, lambda m: xform(m, op), line, count=subs, flags=flags)
            maxsub -= count
            if maxsub <= 0:
                break
        return lines
    else:
        return [re.sub(e, lambda m: xform(m, op), line, flags=flags) for line in lines]


def xform(match, op):
    if op == 'u' or op == 'U':
        return match[0].upper()
    elif op == 'l' or op == 'L':
        return match[0].lower()
    elif op == 't' or op == 'T':
        return match[0].title()
    elif op == 'c' or op == 'C':
        return match[0].capitalize()
    else:
        raise ValueError(f'Unknown command: "{op}"')


def filter_lines(args, data, item, op, sep='/'):
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    e = param_str(item, sep)
    e = re.escape(e) if args.fixed else e
    output = []
    for line in get_lines(args, data):
        if op == FILTER:
            if re.search(e, line, flags=flags):
                output.append(line)
        elif op == LINE_FILTER:
            if re.fullmatch(e, line, flags=flags):
                output.append(line)
        elif op == EXCLUDE:
            if not re.search(e, line, flags=flags):
                output.append(line)
        elif op == LINE_EXCLUDE:
            if not re.fullmatch(e, line, flags=flags):
                output.append(line)
        elif op == LINE_ONLY:
            matches = list(re.finditer(e, line, flags=flags))
            if len(matches):
                output.append(''.join([match[0] for match in matches]))
        elif op == LINE_REMOVE:
            output.append(re.sub(e, '', line, flags=flags))
        else:
            raise ValueError(f'Unknown command: "{op}" from the "{item}" command')
    return output


def line_sub(args, data, item, op, sep='/'):
    resplit = False
    lines = get_lines(args, data)
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    e, r = param_str_str(item, sep)
    e = re.escape(e) if args.fixed or op == LINE_FIXED_SUB else e
    if args.maxsub > 0:
        maxsub = args.maxsub
        for i, line in enumerate(lines):
            subs = maxsub if args.maxlinesub == 0 else min(maxsub, args.maxlinesub)
            lines[i], count = re.subn(e, r, line, count=subs, flags=flags)
            maxsub -= count
            if count:
                if '\n' in lines[i]:
                    resplit = True
            if maxsub <= 0:
                break
        return get_normalized_lines(args, lines) if resplit else lines
    else:
        resplit = False
        new_lines = []
        for line in lines:
            new_lines.append(new_line := re.sub(e, r, line, count=args.maxlinesub, flags=flags))
            resplit = resplit or '\n' in new_line
        return get_normalized_lines(args, new_lines) if resplit else new_lines
        # return [re.sub(e, r, line, count=args.maxlinesub, flags=flags) for line in lines]


def file_sub(args, data, item, op, sep='/'):
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    if op == FILE_REMOVE:
        e = param_str(item, sep)
        r = ''
    else:
        e, r = param_str_str(item, sep)
    e = re.escape(e) if args.fixed else e
    return re.sub(e, r, get_string(args, data), count=args.maxsub, flags=flags)


def file_only(args, data, item, _op, sep='/'):
    flags = args.insensitive | args.multiline | args.ascii | args.dotall
    e = param_str(item, sep)
    e = re.escape(e) if args.fixed else e
    matches = list(re.finditer(e, data, flags=flags))
    out = ''
    if len(matches):
        out = ''.join([match[0] for match in matches])
    return ''.join(out)


def get_file_contents(path):
    f = open(path, encoding="utf-8")
    data = f.read()
    f.close()
    return data


class CustomFormatter(argparse.HelpFormatter):
    # noinspection PyMethodMayBeStatic
    def _flow(self, text):
        lines = text.splitlines()
        new_text = lines[0]
        last = True
        for line in lines[1:]:
            cur = line.strip() != '' and line[0] != ' '
            new_text += (' ' if last and cur else os.linesep) + line
            last = cur
        return new_text

    def _format_text(self, text):
        import textwrap
        text_width = max(self._width - self._current_indent, 11)
        indent = ' ' * self._current_indent
        if '<mark-over>' in text:
            lines = []
            for line in self._flow(text).splitlines():
                line = re.sub(r'<mark-over>', '', line)
                if line.strip() == '':
                    lines.append(line)
                elif line[0] == ' ':
                    spaces = (len(line) - len(line.lstrip()))
                    lines = lines + textwrap.wrap(line.lstrip(), text_width, initial_indent=' ' * spaces,
                                                  subsequent_indent=' ' * spaces * 2)
                else:
                    line = re.sub(r'\s{2,}', ' ', line)
                    lines = lines + textwrap.wrap(line, text_width, initial_indent=indent, subsequent_indent=indent)
            return os.linesep.join(lines) + '\n\n'


class PedErrorTypes(IntEnum):
    PED_UNKNOWN_COMMAND_ERROR = 2
    PED_IO_ERROR = 2
    PED_RE_ERROR = 3
    PED_OTHER_ERROR = 4


class PedError(Exception):
    def __init__(self, message, error_type):
        super().__init__(message)
        self.msg = message
        self.type = error_type


def use_color(args, stream=sys.stdout):
    supported_platform = (sys.platform != 'win32' or 'ANSICON' in os.environ)
    is_a_tty = hasattr(stream, 'isatty') and sys.stdout.isatty()
    return args.color is True or (supported_platform and is_a_tty and args.color is not False)


def catching_main(argv):
    try:
        main(argv)
    except PedError as ex:
        raise
    except re.error as ex:
        raise PedError(f'''Error: regular expression invalid - '''
                       f'''{ex.msg if hasattr(ex, "msg") else "???"}'''
                       f'''{f' : "{ex.pattern}"' if hasattr(ex, 'pattern') else ''}''', PedErrorTypes.PED_RE_ERROR) from ex
    except FileNotFoundError as ex:
        raise PedError(f'Error: file not found' + (f' - "{ex.filename}"' if hasattr(ex, 'filename') else ''),
                       PedErrorTypes.PED_IO_ERROR) from ex
    except PermissionError as ex:
        raise PedError(f'Error: permissions error', PedErrorTypes.PED_IO_ERROR) from ex
    except OSError as ex:
        fn = f'''{"" if ex.filename is None else f' "{ex.filename}" '}'''
        error_type = PedErrorTypes.PED_OTHER_ERROR if ex.filename is None else PedErrorTypes.PED_IO_ERROR
        raise PedError(f'Error: [{ex.errno}] {ex.strerror}{fn}', error_type) from ex
    except Exception as ex:
        if hasattr(ex, 'strerror'):
            msg = f'- {ex.strerror}'
        elif hasattr(ex, 'msg'):
            msg = f'- {ex.msg}'
        elif hasattr(ex, 'message'):
            msg = f'- {ex.message}'
        else:
            msg = 'unknown'
        raise PedError(f'Error: unexpected error - {msg}', PedErrorTypes.PED_OTHER_ERROR) from ex


if __name__ == '__main__':
    rc = 0
    try:
        catching_main(sys.argv[1:])
    except PedError as pex:
        print(pex.msg, file=sys.stderr)
        rc = pex.type
    sys.exit(int(rc))
