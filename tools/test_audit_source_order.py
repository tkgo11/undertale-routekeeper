"""Cross-platform golden ordering tests using disposable, non-game path names."""
import ast
from pathlib import Path, PurePosixPath, PureWindowsPath
from types import SimpleNamespace
import unittest
from unittest.mock import Mock


SCRIPT = Path(__file__).with_name('audit-endings.py')


class AuditSourceOrderTests(unittest.TestCase):
    def setUp(self):
        # The CLI intentionally requires authentic source inputs at module level.
        # Load its actual small enumeration function without running the oracle.
        tree = ast.parse(SCRIPT.read_text(encoding='utf-8'))
        self.function = next(node for node in tree.body
                             if isinstance(node, ast.FunctionDef)
                             and node.name == 'source_paths')

    def ordered(self, paths, pattern='*.gml'):
        source = SimpleNamespace(glob=Mock(return_value=paths))
        namespace = {'a': SimpleNamespace(source=source)}
        exec(compile(ast.Module(body=[self.function], type_ignores=[]),
                     str(SCRIPT), 'exec'), namespace)
        result = namespace['source_paths'](pattern)
        source.glob.assert_called_once_with(pattern)
        return [path.name for path in result]

    def test_windows_casefold_does_not_change_golden_order(self):
        paths = [PureWindowsPath('C:/private/fixture_body_Create_0.gml'),
                 PureWindowsPath('C:/private/fixture_Create_0.gml')]
        expected = ['fixture_Create_0.gml', 'fixture_body_Create_0.gml']
        self.assertNotEqual([path.name for path in sorted(paths)], expected)
        self.assertEqual(self.ordered(paths), expected)

    def test_posix_and_windows_paths_produce_identical_order(self):
        names = ['fixture_body_Draw_0.gml', 'fixture_Create_0.gml',
                 'fixture_Alarm_3.gml', 'fixture_body_Create_0.gml']
        expected = ['fixture_Alarm_3.gml', 'fixture_Create_0.gml',
                    'fixture_body_Create_0.gml', 'fixture_body_Draw_0.gml']
        for kind in (PureWindowsPath, PurePosixPath):
            with self.subTest(path_type=kind.__name__):
                self.assertEqual(self.ordered([kind(name) for name in names]),
                                 expected)
                self.assertEqual(self.ordered([kind(name) for name in reversed(names)]),
                                 expected)

    def test_globs_cannot_bypass_ordinal_source_enumerator(self):
        tree = ast.parse(SCRIPT.read_text(encoding='utf-8'))
        globs = [node for node in ast.walk(tree)
                 if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Attribute)
                 and node.func.attr == 'glob']
        self.assertTrue(globs)
        helper_globs = [node for node in ast.walk(self.function)
                        if isinstance(node, ast.Call)
                        and isinstance(node.func, ast.Attribute)
                        and node.func.attr == 'glob']
        self.assertEqual(len(globs), len(helper_globs))
        self.assertEqual(self.ordered([], 'fixture_*.gml'), [])


if __name__ == '__main__':
    unittest.main()
