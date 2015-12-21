import os
import sys

from .event import Event

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "config_d"))
from config_parser import BlockRegisters, BlockConfig


class Block(object):

    def __init__(self, num):
        block_name = type(self).__name__.upper()
        regs = BlockRegisters.instances[block_name].fields
        self.reg_base = BlockRegisters.instances[block_name].base
        self.maxnum = BlockConfig.instances[block_name].num
        self.fields = BlockConfig.instances[block_name].fields
        assert num > 0 and num <= self.maxnum, \
            "Num %d out of range" % num
        self.num = num
        diff = set(regs) ^ set(self.fields)
        assert len(diff) == 0, "Mismatch %s" % diff

        # dict bus index -> name
        self.bit_outs, self.pos_outs = {}, {}
        # dict reg num -> name
        self.regs = {}
        # dict reg num -> lo/hi
        self.time_lohi = {}
        for name, field in self.fields.items():
            # Initialise the attribute value to 0
            setattr(self, name, 0)
            if field.cls.endswith("_out"):
                # outs are an array of bus indexes
                bus_index = int(regs[name].split()[self.num - 1])
                setattr(self, name, bus_index)
                if field.cls == "pos_out":
                    self.pos_outs[bus_index] = name
                else:
                    self.bit_outs[bus_index] = name
            elif field.cls == "table":
                # Tables are special...
                # TODO: handle tables
                # if "^" in val:
                #    val = pow(*map(int, val.split("^")))
                # else:
                #    val = int(val)
                self.regs["TABLE"] = name
            elif field.cls == "time":
                # Time values are "lo hi [>offset]"
                split = regs[name].split()
                reg_offset = [int(x) for x in split[:2]]
                self.regs[reg_offset[0]] = name
                self.time_lohi[reg_offset[0]] = "lo"
                self.regs[reg_offset[1]] = name
                self.time_lohi[reg_offset[1]] = "hi"
                # ignore offset as our blocks know about it
            else:
                # everything else is "reg_offset [filter]"
                split = regs[name].split(" ", 1)
                reg_offset = int(split[0])
                self.regs[reg_offset] = name

    def on_event(self, event):
        for name, value in event.reg.items():
            setattr(self, name, value)
        return Event()
