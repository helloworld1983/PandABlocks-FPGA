import os
import shutil
import unittest
from common.python.generate_app import AppGenerator


TEST_DATA = os.path.join(os.path.dirname(__file__), "test_data")


class TestGenerateApp(unittest.TestCase):
    maxDiff = None
    app_build_dir = None

    @classmethod
    def setUpClass(cls):
        here = os.path.dirname(__file__)
        app = os.path.join(here, "test_data", "test.app.ini")
        cls.app_build_dir = "/tmp/test_app_build_dir"
        if os.path.exists(cls.app_build_dir):
            shutil.rmtree(cls.app_build_dir)
        cls.expected_dir = os.path.join(here, "test_data", "app-expected")
        AppGenerator(app, cls.app_build_dir)

    def assertGeneratedEqual(self, *path):
        with open(os.path.join(self.expected_dir, *path)) as f:
            expected = f.read()
        with open(os.path.join(self.app_build_dir, *path)) as f:
            actual = f.read()
        self.assertMultiLineEqual(expected, actual)

    def test_lut_description(self):
        self.assertGeneratedEqual("config_d", "descriptions")

    def test_lut_config(self):
        self.assertGeneratedEqual("config_d", "config")

    def test_lut_registers(self):
        self.assertGeneratedEqual("config_d", "registers")

    def test_lut_wrapper(self):
        self.assertGeneratedEqual("hdl", "lut_wrapper.vhd")

    def test_soft_blocks(self):
        self.assertGeneratedEqual("hdl", "soft_blocks.vhd")

    def test_lut_ctrl(self):
        self.assertGeneratedEqual("hdl", "lut_ctrl.vhd")

    def test_addr_defines(self):
        self.assertGeneratedEqual("hdl", "addr_defines.vhd")

if __name__ == '__main__':
    unittest.main()