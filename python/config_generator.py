#!/bin/env dls-python
from pkg_resources import require
require("Jinja2")
import os, sys
import csv
import collections
from jinja2 import Environment, FileSystemLoader

ROOT_DIR = os.path.abspath(os.pardir)
OUTPUT_DIR = os.path.join(ROOT_DIR, "build", "config_d")
MODULE_DIR = os.path.join(ROOT_DIR, "modules")
APP_DIR = os.path.join(ROOT_DIR, "apps")

template_environment = Environment(
    autoescape=False,
    loader=FileSystemLoader(MODULE_DIR),
    trim_blocks=True)

def render_template(template_filename, context):
    return template_environment.get_template(template_filename).render(context)

def generateOutputFile(app_config, outputfile, variables):
    #generate the output config file
    fname = os.path.join(OUTPUT_DIR, outputfile)
    with open(fname, 'w') as f:
        #get the config templates from the base
        output_file = render_template(os.path.join("panda_carrier/", outputfile), variables)
        f.write(output_file)
        for config in app_config.keys():
            output_file = render_template(os.path.join(config.lower(), outputfile), variables)
            f.write(output_file)

def generateDescription(app_config, outputfile):
    fname = os.path.join(OUTPUT_DIR, outputfile)
    with open(fname, 'w') as outfile:
        #get the description from the base
        description_file =  os.path.join(MODULE_DIR, "panda_carrier", "description")
        with open(description_file) as infile:
            outfile.write(infile.read())
        for config in app_config.keys():
            description_file = os.path.join(MODULE_DIR, config.lower(), "description")
            with open(description_file) as infile:
                outfile.write(infile.read())

# def generateRegisters(templatefiles, outputfile, variables):
#     #generate the output registers files
#     fname = os.path.join(OUTPUT_DIR, outputfile)
#     with open(fname, 'w') as f:
#         #get the config templates from the base
#         output_file = render_template("panda_carrier/registers", variables)
#         f.write(output_file)
#         for config in templatefiles.keys():
#             output_file = render_template(config.lower() + "/registers", variables)
#             f.write(output_file)

def extractFileInfo(file):
    file_info = collections.OrderedDict()
    with open(file, 'rb') as csvfile:
        try:
            appreader = csv.reader(csvfile, delimiter=' ')
            for row in appreader:
                #ignore comments and put in dictionary
                if row and not row[0].startswith("#"):
                    file_info[row[0]] = row[1]
        except:
        #NEED SOME EXTRA CHECKING ON THIS FILE
            print "INVALID ENTRY, LINE", appreader.line_num,": ", row
    return file_info

def parseAppFile(appfile):
    file = os.path.join(APP_DIR, appfile)
    return extractFileInfo(file)

def parseMetaFile(metafile, block):
    meta_info = collections.OrderedDict()
    meta_file = os.path.join(MODULE_DIR, block.lower(), "meta")
    try:
        meta_info = extractFileInfo(meta_file)
    except:
        print "no meta file for: ", block, sys.exc_info()[0]
    return meta_info

def checkBlockMax(app_config):
    for block in app_config.keys():
        meta_file = os.path.join(MODULE_DIR, block.lower(), "meta")
        meta_info = parseMetaFile(meta_file, block)
        #check the defined number in the config against the max in the meta
        if app_config[block] > meta_info["MAX"]:
            app_config[block] = meta_info["MAX"]
            print block, "> MAX ", meta_info["MAX"], ", CHANGING TO MAX: ", meta_info["MAX"]

# def newBitBus(block):
#     bus_values = ""
#     for values in range(app_config[block])
#
#     return "NEW VALUE: " + a

# template_environment.globals['newBitBus'] = newBitBus

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    #read in app config file
    app_config = parseAppFile("myapp")
    variables = {"app_config": app_config}

    checkBlockMax(app_config)

    #combine all relevent descriptions for the output description file
    generateDescription(app_config, "description")

    #combine all relevent config for the output config file
    generateOutputFile(app_config, "config", variables)
        #-check that each requested config doesn't exceed the max (from the meta file)
        #-make sure to only include the ones that aren't 0
        #-other error checking ?

    #combine all relevent registers for the output registers file
    generateOutputFile(app_config, "registers", variables)
        #-check that each requested config doesn't exceed the max (from the meta file)
        #-check there are only unique bit numbers ?
        #-other error checking ?

if __name__ == "__main__":
    main()
