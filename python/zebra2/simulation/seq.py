import numpy

from .block import Block
from .event import Event
from collections import deque, OrderedDict

class Seq(Block):
    def __init__(self, num):
        super(Seq, self).__init__(num)
        self.inputs = OrderedDict([('D',0), ('C',0), ('B',0), ('A',0)])
        self.params = {'rpt':0,
                        'inMask': 0,
                        'inCond':0,
                        'p1Out':0,
                        'p2Out':0,
                        'p1Len':0,
                        'p2Len':0
                       }
        self.active = 0
        self.gate = 0
        self.tlength = 0
        self.twrite_addr = 0
        self.cur_frame = 0
        self.table_repeats = 0
        self.prescale = 1
        self.fword_count = 0
        self.table_strobes = 0
        self.fcycle = 0
        self.tcycle = 0
        self.frame_ok = False
        self.p2_queue = deque()
        self.next_frame_queue = deque()
        self.frpt_queue = deque()
        self.trpt_queue = deque()
        self.end_queue = deque()
        self.table = numpy.zeros(512*4, dtype=numpy.uint32)

    def do_start(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 1
        self.gate = 1
        self.cur_frame = 1
        self.fcycle = 1
        self.tcycle = 1
        self.set_read_registers()
        self.check_inputs(next_event, event)

    def do_stop(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 0
        self.gate = 0
        self.set_outputs_zero( next_event, event)
        self.reset_state()

    def reset_state(self):
        self.cur_frame = 0
        self.fcycle = 0
        self.tcycle = 0
        self.p2_queue.clear()
        self.frpt_queue.clear()
        self.trpt_queue.clear()
        self.set_read_registers()

    def process_inputs(self, next_event, event):
        #record inputs
        input_map = {self.INPA:'A',
                     self.INPB:'B',
                     self.INPC:'C',
                     self.INPD:'D'
                     }
        for name, val in event.bit.items():
            self.inputs[input_map[name]] = val
        if self.active and self.frame_ok:
            self.check_inputs(next_event, event)

    def check_inputs(self, next_event, event):
        inputint = self.get_input_interger()
        self.get_table_data()
        # if inputs & input bitmask == input conditions: outputs = phase outputs
        if (inputint & self.params['inMask'] ==
                self.params['inCond'] & self.params['inMask']):
            self.set_outputs_phase1(next_event, event)

    def set_outputs_phase1(self, next_event, event):
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = (self.params['p1Out'] & 1)
        next_event.bit[self.OUTB] = (self.params['p1Out'] & 2) >> 1
        next_event.bit[self.OUTC] = (self.params['p1Out'] & 4) >> 2
        next_event.bit[self.OUTD] = (self.params['p1Out'] & 8) >> 3
        next_event.bit[self.OUTE] = (self.params['p1Out'] & 16) >> 4
        next_event.bit[self.OUTF] = (self.params['p1Out'] & 32) >> 5
        self.p2_queue.append((event.ts + self.params['p1Len']))
        self.CUR_FCYCLE = self.fcycle
        self.CUR_TCYCLE = self.tcycle
        #if we receive an input that matches criteria, and we are due to process
        #a repeat queue, clear the queue to prevent the outputs being set twice
        if self.frpt_queue and self.frpt_queue[0] == event.ts:
            self.frpt_queue.popleft()
        if self.trpt_queue and self.trpt_queue[0] == event.ts:
            self.trpt_queue.popleft()

    def set_outputs_phase2(self, next_event, event):
        self.get_table_data()
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = (self.params['p2Out'] & 1)
        next_event.bit[self.OUTB] = (self.params['p2Out'] & 2) >> 1
        next_event.bit[self.OUTC] = (self.params['p2Out'] & 4) >> 2
        next_event.bit[self.OUTD] = (self.params['p2Out'] & 8) >> 3
        next_event.bit[self.OUTE] = (self.params['p2Out'] & 16) >> 4
        next_event.bit[self.OUTF] = (self.params['p2Out'] & 32) >> 5
        #handle repeating frames
        if self.cur_frame < self.tlength and self.fcycle == self.params['rpt']:
            self.cur_frame += 1
            self.fcycle = 1
            self.next_frame_queue.append((event.ts + self.params['p2Len']))
        elif self.fcycle < self.params['rpt'] or self.fcycle == 0:
            self.fcycle += 1
            self.frpt_queue.append((event.ts + self.params['p2Len']))
        #handle repeating tables
        elif self.cur_frame == self.tlength:
            if self.tcycle < self.table_repeats or self.tcycle == 0:
                self.tcycle += 1
                self.cur_frame = 1
                self.fcycle = 1
                self.trpt_queue.append((event.ts + self.params['p2Len']))
            elif self.tcycle == self.table_repeats:
                self.end_queue.append(event.ts + self.params['p2Len'])

    def set_outputs_zero(self, next_event, event):
        next_event.bit[self.OUTA] = 0
        next_event.bit[self.OUTB] = 0
        next_event.bit[self.OUTC] = 0
        next_event.bit[self.OUTD] = 0
        next_event.bit[self.OUTE] = 0
        next_event.bit[self.OUTF] = 0

    def get_input_interger(self):
        #get inputs as a single integer
        inputarray = []
        for name, value in self.inputs.iteritems():
            inputarray.append(value)
        return int(''.join(map(str,inputarray)),2)

    def get_cur_frame(self, next_event, event):
        self.CUR_FRAME = self.cur_frame

    def do_table_write(self, next_event, event):
        self.frame_ok = False
        self.table[self.twrite_addr] = self.TABLE_DATA
        self.twrite_addr += 1
        #check that the whole frame is written
        self.fword_count += 1
        self.table_strobes += 1
        if self.fword_count == 4:
            self.fword_count = 0
            self.frame_ok = True
        self.TABLE_STROBES = self.table_strobes

    def do_table_reset(self, next_event, event):
        self.twrite_addr = 0
        next_event.bit[self.ACTIVE] = self.active = 0
        self.set_outputs_zero( next_event, event)
        self.reset_state()

    def set_read_registers(self):
        self.CUR_FRAME = self.cur_frame
        self.CUR_TCYCLE = self.tcycle
        self.CUR_FCYCLE = self.fcycle

    def do_table_write_finished(self, next_event, event):
        if self.table_strobes != 0:
            self.tlength = self.TABLE_LENGTH
        if self.gate:
            next_event.bit[self.ACTIVE] = self.active = 1
            self.cur_frame = 1
            self.fcycle = 1
            self.tcycle = 1
            self.set_read_registers()
        self.table_strobes = 0

    def get_table_data(self):
        table_offset = 4*(self.cur_frame - 1)
        self.params['rpt'] = self.table[0 + table_offset]
        self.params['p1Len'] = self.table[2 + table_offset] * self.prescale
        self.params['p2Len'] = self.table[3 + table_offset] * self.prescale
        self.params['inMask'] = (self.table[1 + table_offset] >> 28) & 0xF
        self.params['inCond'] = (self.table[1 + table_offset] >> 24) & 0xF
        self.params['p2Out'] = (self.table[1 + table_offset] >> 8) & 0x3F
        self.params['p1Out'] = (self.table[1 + table_offset] >> 16) & 0x3F

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        self.get_cur_frame(next_event, event)
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "SOFT_GATE" and value:
                    self.do_start(next_event, event)
                if name == "SOFT_GATE" and not value:
                    self.do_stop(next_event, event)
                elif name == "TABLE_DATA":
                    self.do_table_write(next_event, event)
                elif name == "TABLE_RST":
                    self.do_table_reset(next_event, event)
                elif name == "TABLE_CYCLE":
                    self.table_repeats = value
                elif name == "PRESCALE":
                    self.prescale = value
                elif name == "TABLE_LENGTH":
                    self.do_table_write_finished(next_event, event)
                elif name == "TABLE":
                    self.table[:len(value)] = value
                    # write each value in value array to table
        # if we got an input on a rising edge, then process it
        elif event.bit:
            input_bits = [self.INPA, self.INPB, self.INPC, self.INPD]
            if any(x in event.bit for x in input_bits):
                #if we are due to repeat, pop off the queue so we wait until
                #the inputs are correct again
                if self.frpt_queue:
                    self.frpt_queue.popleft()
                self.process_inputs(next_event, event)
            for name, value in event.bit.items():
                if name == self.GATE and value:
                    self.do_start(next_event, event)
                elif name == self.GATE and not value:
                    self.do_stop(next_event, event)
        # if we have an event on one of our queues that is due, produce it
        if self.p2_queue and self.p2_queue[0] == event.ts:
            self.p2_queue.popleft()
            self.set_outputs_phase2(next_event, event)
        if self.frpt_queue and self.frpt_queue[0] == event.ts:
            self.frpt_queue.popleft()
            self.check_inputs(next_event, event)
            self.CUR_FCYCLE = self.fcycle
        if self.trpt_queue and self.trpt_queue[0] == event.ts:
            self.trpt_queue.popleft()
            self.CUR_TCYCLE = self.tcycle
            self.check_inputs(next_event, event)
        if self.next_frame_queue and self.next_frame_queue[0] == event.ts:
            self.next_frame_queue.popleft()
            self.check_inputs(next_event, event)
        if self.next_frame_queue and self.next_frame_queue[0] < event.ts:
            self.next_frame_queue.popleft()
        if self.end_queue and self.end_queue[0] == event.ts:
            self.set_outputs_zero(next_event,event)
            next_event.bit[self.ACTIVE] = self.active = 0
        # return any changes and next ts
        return next_event