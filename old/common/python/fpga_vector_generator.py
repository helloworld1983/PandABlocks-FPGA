#!/usr/bin/env python

from pkg_resources import require
require("numpy")
import sys
import os
import getopt
from collections import OrderedDict

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "python"))

from pandablocks.block import Block
from pandablocks.sequenceparser import SequenceParser
from pandablocks.configparser import ConfigParser

# import modules
# MODULE_DIR = os.path.join(os.path.dirname(modules.__file__))
PAR_DIR = os.path.join(__file__, os.pardir, os.pardir)
MODULE_DIR = os.path.join(os.path.abspath(PAR_DIR), "..",  "modules")
ROOT_DIR = os.path.dirname(os.path.abspath(PAR_DIR))
BUILD_DIR = os.path.join(ROOT_DIR,'build', 'PandABox')
CONFIG_DIR = os.path.join(BUILD_DIR, 'config_d')


Block.load_config(CONFIG_DIR)

# Time between SIM_RESET being set high and the next test starting
RESET_DEADTIME = 12500


class FpgaSequence(object):
    def __init__(self, parser, block, fpga_dir):
        self.parser = parser
        self.block = block
        self.fpga_dir = fpga_dir
        # field types
        config_block = Block.parser.blocks[block.upper()]
        # Get the column headings
        self.bus_in = ["TS", "SIM_RESET"]
        self.bus_out = ["TS"]
        self.reg_in = ["TS"]
        self.reg_out = ["TS"]
        self.bit_bus = []
        self.pos_bus = []
        # Add registers
        for name, (_, field) in config_block.registers.items():
            if field and field.cls.endswith("_mux"):
                if not name.endswith("_DLY"):
                    self.bus_in.append(name)
            elif field.cls == "read":
                self.reg_out.append(name)
            else:
                self.reg_in.append(name)
                self.reg_in.append(name + "_WSTB")
        # Add outputs
        for name, (_, field) in config_block.outputs.items():
            if field.cls != "ext_out":
                self.bus_out.append(name)
        # Add PCAP registers if we are a pcap block
        if block == "pcap":
            #get the headers for the pos_bus and bit_bus
            self.bit_bus = ["TS"] + ["BIT[%d]" % i for i in range(128)]
            self.pos_bus = ["TS"] + ["POS[%d]" % i for i in range(32)]
            reg_block = Block.parser.blocks["*REG"]
            for name in reg_block.registers:
                if name.startswith("PCAP_"):
                    self.reg_in.append(name[len("PCAP_"):])
                    self.reg_in.append(name[len("PCAP_"):] + "_WSTB")
            self.bus_out += ["DATA", "DATA_WSTB", "ERROR"]
        self.make_lines()

    def write(self):
        # Write the lines
        try:
            os.makedirs(self.fpga_dir)
        except OSError:
            pass
        #add the bit_bus and pos_bus to be written if we have them
        if self.bit_bus and self.pos_bus:
            names = \
                ["bus_in", "bus_out", "reg_in", "reg_out", "bit_bus", "pos_bus"]
        else:
            names = ["bus_in", "bus_out", "reg_in", "reg_out"]
        for name in names:
            f = open(os.path.join(
                self.fpga_dir, "%s_%s.txt" % (self.block, name)), "w")
            headings = getattr(self, name)
            f.write("\t".join(headings) + "\n")
            lines = getattr(self, name + "_lines")
            for line in lines:
                f.write("\t".join(line) + "\n")
            f.close()

    def add_line(self, ts, current):
        lbus_in = [str(current.get(name, 0)) for name in self.bus_in]
        lbus_out = [str(current.get(name, 0)) for name in self.bus_out]
        lreg_in = [str(current.get(name, 0)) for name in self.reg_in]
        lreg_out = [str(current.get(name, 0)) for name in self.reg_out]
        lbus_in[0] = str(ts)
        lbus_out[0] = str(ts+1)
        lreg_in[0] = str(ts)
        lreg_out[0] = str(ts+1)
        self.bus_in_lines.append(lbus_in)
        self.bus_out_lines.append(lbus_out)
        self.reg_in_lines.append(lreg_in)
        self.reg_out_lines.append(lreg_out)
        #if we have a pcap block, fill the pos_bus and bit_bus output files
        if self.pos_bus and self.bit_bus:
            lpos_bus = [str(current.get(name, 0)) for name in self.pos_bus]
            lbit_bus = [str(current.get(name, 1)) if name == 'BITS.ONE'
                        else str(current.get(name, 0))for name in self.bit_bus]
            lpos_bus[0] = str(ts)
            lbit_bus[0] = str(ts)
            self.pos_bus_lines.append(lpos_bus)
            self.bit_bus_lines.append(lbit_bus)

    def set_wstb(self, changes):
        strobes = {}
        for name in self.reg_in + ["DATA"]:
            if name in changes:
                strobes[name + "_WSTB"] = 1
        return strobes

    def make_lines(self):
        # make lines list
        self.bus_in_lines = []
        self.bus_out_lines = []
        self.reg_in_lines = []
        self.reg_out_lines = []
        self.bit_bus_lines = []
        self.pos_bus_lines = []
        # add an offset for each sequence
        ts_off = 0
        for sequence in self.parser.sequences:
            # reset simultion
            current = {}
            self.add_line(ts_off, dict(SIM_RESET=1))
            ts_off += RESET_DEADTIME
            ts_wstb_off = None
            # start the sequence
            for ts in sequence.inputs:
                changes = {}
                # Work out if any writestrobes are set
                strobes = [k for k in current
                           if k.endswith("_WSTB") and current[k]]
                # If there are strobes set and we should set them before ts
                # then add a line for it
                if strobes:
                    if ts > ts_wstb_off:
                        for name in strobes:
                            current[name] = 0
                        self.add_line(ts_wstb_off + ts_off, current)
                    else:
                        # otherwise just merge them in with the changes
                        for name in strobes:
                            changes[name] = 0
                # Work out what has changed
                changes.update(sequence.inputs[ts])
                changes.update(sequence.outputs[ts])
                # Update our current state with changes
                current.update(changes)
                # And with any write strobes that need to be set as a result
                current.update(self.set_wstb(changes))
                self.add_line(ts + ts_off, current)
                ts_wstb_off = ts + 1
            ts_off += ts + 1


def generate_fpga_test_vectors(build_dir):
    sequences = []
    for module in os.walk(MODULE_DIR):
        if 'sim' in module[1]:
            sim_sequence_path = os.path.join(module[0], 'sim')
            sys.path.insert(0, sim_sequence_path)
            for fname in os.listdir(sim_sequence_path):
                if fname.endswith(".seq"):
                    parser = SequenceParser(os.path.join(sim_sequence_path, fname))
                    for seq in parser.sequences:
                        sequences.append((fname.split(".")[0], seq))
                    FpgaSequence(parser, fname.split(".")[0], build_dir).write()
    # These are the tests that start with !

def main(argv):
    output_dir = BUILD_DIR
    try:
        opts, args = getopt.getopt(argv, "ho:", ["outputdir="])
    except getopt.GetoptError:
        print 'fpga_vector_generator.py -o <output dir>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'fpga_vector_generator.py -o <output dir>'
            sys.exit(2)
        elif opt in ("-o", "--outputdir"):
            output_dir = arg
    generate_fpga_test_vectors(os.path.join(output_dir, 'fpga_sequences'))


if __name__ == '__main__':
    main(sys.argv[1:])
    # generate_fpga_test_vectors()
