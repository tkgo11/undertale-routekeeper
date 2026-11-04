"""Portable source IO policy and a non-UTF8 locale simulation; no native claim."""
import ast
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class SourceEncoding(unittest.TestCase):
    def test_hangul_catalog_survives_non_utf8_locale(self):
        original = Path.read_text
        def locale_read(path, encoding=None, errors=None):
            return original(path, encoding=encoding or 'cp1252', errors=errors)
        with patch.object(Path, 'read_text', locale_read):
            namespace = runpy.run_path(str(ROOT / 'integration/ui/generate.py'), run_name='offline_import')
        self.assertEqual(namespace['CAT']['text']['language'][1], '언어')

    def test_all_tracked_path_text_io_is_explicit_and_portable(self):
        paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
        for name in paths:
            if not name.endswith('.py'):
                continue
            tree = ast.parse((ROOT / name).read_bytes(), filename=name)
            for node in ast.walk(tree):
                if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr in ('read_text', 'write_text'):
                    keywords = {k.arg: k.value.value for k in node.keywords if isinstance(k.value, ast.Constant)}
                    with self.subTest(path=name, line=node.lineno):
                        self.assertEqual(keywords.get('encoding'), 'utf-8')
                        if node.func.attr == 'write_text':
                            self.assertEqual(keywords.get('newline'), '\n')


if __name__ == '__main__':
    unittest.main()
