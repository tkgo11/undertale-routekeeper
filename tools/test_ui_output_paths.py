"""Disposable output-link refusals for real UI generator/preview implementations."""
import contextlib
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'integration/ui'))
import generate as ui_generate
import preview


@unittest.skipIf(os.name == 'nt', 'Portable symlink fixture; native Windows reparse tests are separate')
class UiOutputPaths(unittest.TestCase):
    def test_every_generated_gml_leaf_refuses_links(self):
        for name in ui_generate.sources():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary).resolve(); gml = root/'gml'; gml.mkdir()
                outside = root/'original.bin'; outside.write_bytes(b'SYNTHETIC ORIGINAL MUST REMAIN')
                (gml/name).symlink_to(outside)
                with patch.object(ui_generate, 'ROOT', root), patch.object(sys, 'argv', ['generate.py']), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(ValueError):
                    ui_generate.main()
                self.assertEqual(outside.read_bytes(), b'SYNTHETIC ORIGINAL MUST REMAIN')

    def test_generator_ancestor_link_refuses_before_outside_writes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); outside = root/'outside'; outside.mkdir(); (root/'gml').symlink_to(outside, target_is_directory=True)
            with patch.object(ui_generate, 'ROOT', root), patch.object(sys, 'argv', ['generate.py']), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(ValueError):
                ui_generate.main()
            self.assertEqual(list(outside.iterdir()), [])

    def test_preview_leaf_refuses_without_modifying_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); outside = root/'original.bin'; outside.write_bytes(b'SYNTHETIC ORIGINAL')
            output = root/'preview.png'; output.symlink_to(outside)
            with self.assertRaises(ValueError): preview.Renderer(0).save(output)
            self.assertEqual(outside.read_bytes(), b'SYNTHETIC ORIGINAL')

    def test_preview_output_ancestor_refuses_before_mkdir(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); outside = root/'outside'; outside.mkdir(); (root/'alias').symlink_to(outside, target_is_directory=True)
            with patch.object(sys, 'argv', ['preview.py', '--output', str(root/'alias/new')]), self.assertRaises(ValueError): preview.main()
            self.assertEqual(list(outside.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
