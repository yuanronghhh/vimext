import subprocess
import sys
import json
import re
import platform
import logging
import VimPy
import Util

from os import path

c_setter_common = """\
  self->${prop} = ${prop};
"""

c_setter_str = """\
  if(self->${prop}) {
    sys_clear_pointer(&self->${prop}, sys_free);
  }

  self->${prop} = sys_strdup(${prop});
"""


c_getter_setter_template_h = """\
void ${type_name}_set_${prop}(${TypeName} *self, ${prop_type} ${prop});
${prop_type} ${type_name}_get_${prop}(${TypeName} *self);

"""

c_getter_setter_template_c = """\
void ${type_name}_set_${prop}(${TypeName} *self, ${prop_type} ${prop}) {
  sys_return_if_fail(self != NULL);

${SetterHandle}\
}

${prop_type} ${type_name}_get_${prop}(${TypeName} *self) {
  sys_return_val_if_fail(self != NULL, ${default_return});

  return self->${prop};
}\
"""

class GetterGenerator:
    def __init__(self, filename, line):
        self.line = line
        self.filename = filename
        self.default_set = {
            "SysBool": "false",
            "SysInt": "-1",
            "SysInt64": "-1",
            "SysUInt64": "-1",
            "SysUInt": "0",
            "SysDouble": "-1"
        }

    def parse(self):
        param = self.line.split(",")
        plen = len(param)

        if plen < 2:
            return False

        self.prop_type = param[0].strip()
        self.prop = param[1].strip()

        if self.prop.find(" ") > -1:
            return False

        if plen == 2:
            bname = Util.get_filename(self.filename)
            self.type_name = Util.to_under_line_name(bname)
            self.TypeName = Util.to_camecase_name(self.type_name)
        elif plen == 3:
            self.type_name = param[2].strip()
            self.TypeName = Util.to_camecase_name(self.type_name)
        elif plen == 4:
            self.type_name = param[2].strip()
            self.TypeName = param[3].strip()
        else:
            return False

        if not self.type_name:
            return False


        return True

    def parse_type_name(self, type_name):
        if not type_name:
            return

        u = type_name.find('_')
        if u == -1 or len(type_name) < 3:
            return None

        prefix = '%s%s' % (type_name[0].upper(), type_name[1:u])
        rname = '%s%s' % (type_name[u+1].upper(), type_name[u+2:])

        fname = prefix + rname

        return fname

    def relace_vars(self, tpl):
        default_return = "NULL"
        if self.prop_type in self.default_set:
            default_return = self.default_set[self.prop_type]

        return tpl\
                .replace("${TypeName}", self.TypeName)\
                .replace("${type_name}", self.type_name)\
                .replace("${prop}", self.prop)\
                .replace("${prop_type}", self.prop_type)\
                .replace("${default_return}", default_return)

    def gen_c(self):
        ntpl = c_getter_setter_template_c
        if self.prop_type.find("SysChar *") > -1:
            ntpl = ntpl\
                    .replace("${SetterHandle}", c_setter_str)
        else:
            ntpl = ntpl\
                    .replace("${SetterHandle}", c_setter_common)

        return self.relace_vars(ntpl)

    def gen_h(self):
        return self.relace_vars(c_getter_setter_template_h)


def get_undef_position(lines):
    n_count = len(lines)

    for i in range(n_count, 0, -1):
        if lines[i-1].find("END_DECLS") > -1:
            return i-1

    return -1


def write_to_h_file(h_file, content):
    if not path.exists(h_file):
        return

    with open(h_file, "r+", newline="\n") as fp:
        lines = fp.readlines()
        i = get_undef_position(lines)
        if i == -1:
            return

        lines.insert(i, content)

        fp.seek(0)
        fp.writelines(lines)
        fp.close()

def gen_c_getter_setter():
    line = VimPy.get_line()
    filename = VimPy.fullname()

    if not filename.endswith(".c"):
        return []

    gen = GetterGenerator(filename, line)
    if not gen.parse():
        return []

    hstr = gen.gen_h()
    cstr = gen.gen_c()

    h_file = "%s.h" % (Util.get_fullname_without_ext(filename))
    write_to_h_file(h_file, hstr)

    return cstr.split("\n")
