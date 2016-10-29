# json_specs.tcl --
#
#       This file defines the JSON specifications for Discord objects, which can
#       be used as the spec argument to discord::rest::DictToJson.
#
# Copyright (c) 2016, Yixin Zhang
#
# See the file "LICENSE" for information on usage and redistribution of this
# file.

set discord::JsonSpecs {
        overwrite {
            id      string
            type    string
            allow   bare
            deny    bare
        }
}
