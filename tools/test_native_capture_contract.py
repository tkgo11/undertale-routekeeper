"""Synthetic pixel regressions for the harmless native WinForms receipt checker.

These fixtures test rejection logic; they never certify a Windows API execution.
"""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

import screen_verify as screen
import windows_e2e as e2e


class NativeCaptureContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    def fixture(self, *, bar=True, size=(640, 480), dpi=192):
        image = Image.new('RGB', size, 'black')
        if bar:
            ImageDraw.Draw(image).rectangle((32, 32, 607, 37), fill='white')
        # A genuine native client may contain sub-grid pixels at 200% DPI. Such
        # pixels must not trigger the GameMaker-only integer-block normalizer.
        if size == (640, 480):
            image.putpixel((620, 450), (30, 40, 50))
        image.save(self.root / 'window.png')
        sidecar = dict(schema=1, method='CopyFromScreen',
                       imageSha256=screen.hash_file(self.root / 'window.png'),
                       clientSize=list(size), foregroundBefore=True,
                       foregroundAfter=True, ownerPid=42, pid=42,
                       runnerSha256='a' * 64, expectedRunnerSha256='a' * 64,
                       startedUtc='2026-10-29T01:00:00+00:00',
                       finishedUtc='2026-10-29T01:00:00.010+00:00', dpi=dpi)
        receipt = dict(kind='NATIVE_NON_GAME_SELFTEST',
                       localSyntheticRecovery='VERIFIED',
                       keyEvents=['down:40', 'up:40'],
                       minimizedCaptureBlocked=True, exclusiveLockVerified=True,
                       interruptedSyntheticRecovery='VERIFIED',
                       focusLossBlocked=True, abortFileBlocked=True,
                       filesystemChecks=['hardlink-refused', 'stream-refused',
                                         'junction-refused'])
        for field, name in [('sourceSha', 'native-selftest.ps1'),
                            ('inputSha', 'input-window.ps1'),
                            ('captureSha', 'capture-client.ps1')]:
            receipt[field] = screen.hash_file(e2e.ROOT / 'tools/runtime' / name)
        (self.root / 'window.png.json').write_bytes(screen.canonical(sidecar))
        (self.root / 'receipt.json').write_bytes(screen.canonical(receipt))
        return sidecar, receipt

    def verify(self):
        with patch.object(e2e.sys, 'platform', 'win32'):
            return e2e.check_native_test(self.root)

    def test_native_client_space_at_supported_dpi(self):
        for dpi in (96, 120, 144, 192):
            with self.subTest(dpi=dpi):
                self.fixture(dpi=dpi)
                result = self.verify()
                self.assertEqual(result['result'], 'PASS')
                self.assertEqual(result['nativeGameplay'], 'NOT_RUN')

    def test_all_black_capture_refused(self):
        self.fixture(bar=False)
        with self.assertRaisesRegex(e2e.StopRun, 'geometry/obstruction'):
            self.verify()

    def test_shifted_bar_refused(self):
        self.fixture(bar=False)
        with Image.open(self.root / 'window.png') as source:
            image = source.convert('RGB')
        ImageDraw.Draw(image).rectangle((32, 33, 607, 38), fill='white')
        image.save(self.root / 'window.png')
        sidecar = screen.load_json(self.root / 'window.png.json')
        sidecar['imageSha256'] = screen.hash_file(self.root / 'window.png')
        (self.root / 'window.png.json').write_bytes(screen.canonical(sidecar))
        with self.assertRaisesRegex(e2e.StopRun, 'geometry/obstruction'):
            self.verify()

    def test_one_pixel_obstruction_refused(self):
        self.fixture()
        with Image.open(self.root / 'window.png') as source:
            image = source.convert('RGB')
        image.putpixel((40, 34), (0, 0, 0))
        image.save(self.root / 'window.png')
        sidecar = screen.load_json(self.root / 'window.png.json')
        sidecar['imageSha256'] = screen.hash_file(self.root / 'window.png')
        (self.root / 'window.png.json').write_bytes(screen.canonical(sidecar))
        with self.assertRaisesRegex(e2e.StopRun, 'geometry/obstruction'):
            self.verify()

    def test_missing_capture_metadata_refused(self):
        sidecar, _ = self.fixture()
        del sidecar['dpi']
        (self.root / 'window.png.json').write_bytes(screen.canonical(sidecar))
        with self.assertRaises(screen.EvidenceError):
            self.verify()

    def test_stale_screenshot_hash_refused(self):
        self.fixture()
        image = Image.new('RGB', (640, 480), 'black')
        image.save(self.root / 'window.png')
        with self.assertRaises(screen.EvidenceError):
            self.verify()

    def test_incomplete_receipt_cannot_certify_capture(self):
        _, receipt = self.fixture()
        receipt['keyEvents'] = ['down:40']
        (self.root / 'receipt.json').write_bytes(screen.canonical(receipt))
        with self.assertRaises(e2e.StopRun):
            self.verify()


if __name__ == '__main__':
    unittest.main()
