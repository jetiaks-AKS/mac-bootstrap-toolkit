#!/usr/bin/env python3
"""Focused Bundle publication interruption and raw tar-header regressions."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / "modules/bundle/bundle.py"
spec = importlib.util.spec_from_file_location("bundle", MODULE)
bundle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bundle)


class PublicationSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.stage = self.root / "stage"
        (self.stage / "generated").mkdir(parents=True)
        (self.stage / "generated/new").write_text("new generated")
        (self.stage / "blueprint.conf").write_text("new blueprint")

    def config_at(self, name):
        config = self.root / name
        (config / "generated").mkdir(parents=True)
        (config / "generated/old").write_text("old generated")
        (config / "blueprint.conf").write_text("old blueprint")
        return config

    def interrupt(self, config, point):
        script = r'''
import importlib.util, os, pathlib, shutil, sys
spec = importlib.util.spec_from_file_location("bundle", sys.argv[1])
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)
b.CONFIG = pathlib.Path(sys.argv[2])
b.RECOVERY = b.CONFIG / ".bundle-publication"
stage, point = pathlib.Path(sys.argv[3]), sys.argv[4]
if point == "before-marker":
    original = b.write_file
    def interrupt_marker(path, data):
        if path == b.RECOVERY / "preparing":
            raise KeyboardInterrupt()
        return original(path, data)
    b.write_file = interrupt_marker
elif point == "after-copy":
    original = shutil.copytree
    def interrupt_copy(source, target, *args, **kwargs):
        result = original(source, target, *args, **kwargs)
        if target == b.RECOVERY / "generated.new":
            os._exit(91)
        return result
    shutil.copytree = interrupt_copy
elif point == "after-preparation":
    original = os.replace
    def interrupt_replace(source, target):
        if pathlib.Path(source) == b.RECOVERY / "preparing":
            os._exit(91)
        return original(source, target)
    os.replace = interrupt_replace
else:
    original = os.rename
    trigger = {
        "after-old-generated": ("destination", "generated.old"),
        "after-old-blueprint": ("destination", "blueprint.old"),
        "after-new-generated": ("source", "generated.new"),
        "after-new-blueprint": ("source", "blueprint.new"),
        "after-completion": ("destination", "complete"),
    }[point]
    def interrupt_rename(source, target):
        result = original(source, target)
        selected = source if trigger[0] == "source" else target
        if pathlib.Path(selected).name == trigger[1]:
            os._exit(91)
        return result
    os.rename = interrupt_rename
try:
    b.publish(stage)
except KeyboardInterrupt:
    sys.exit(130)
'''
        return subprocess.run([sys.executable, "-c", script, str(MODULE), str(config),
                               str(self.stage), point], capture_output=True, timeout=5)

    def test_preparation_and_each_publication_step_recover_then_retry(self):
        points = ("after-copy", "after-preparation", "after-old-generated",
                  "after-old-blueprint", "after-new-generated", "after-new-blueprint")
        for point in points:
            with self.subTest(point=point):
                config = self.config_at(point)
                result = self.interrupt(config, point)
                self.assertEqual(result.returncode, 91, result.stderr)
                with patch.object(bundle, "CONFIG", config), patch.object(
                        bundle, "RECOVERY", config / ".bundle-publication"):
                    bundle.recover()
                    self.assertEqual((config / "generated/old").read_text(), "old generated")
                    self.assertEqual((config / "blueprint.conf").read_text(), "old blueprint")
                    self.assertFalse((config / ".bundle-publication").exists())
                    bundle.publish(self.stage)
                    self.assertEqual((config / "generated/new").read_text(), "new generated")
                    self.assertEqual((config / "blueprint.conf").read_text(), "new blueprint")

    def test_interruption_before_marker_has_no_prepared_state(self):
        config = self.config_at("before-marker")
        result = self.interrupt(config, "before-marker")
        self.assertEqual(result.returncode, 130, result.stderr)
        self.assertFalse((config / ".bundle-publication").exists())
        self.assertEqual((config / "generated/old").read_text(), "old generated")
        with patch.object(bundle, "CONFIG", config), patch.object(
                bundle, "RECOVERY", config / ".bundle-publication"):
            bundle.recover()
            bundle.publish(self.stage)
        self.assertEqual((config / "generated/new").read_text(), "new generated")

    def test_committed_publication_survives_interrupted_cleanup(self):
        config = self.config_at("after-completion")
        result = self.interrupt(config, "after-completion")
        self.assertEqual(result.returncode, 91, result.stderr)
        with patch.object(bundle, "CONFIG", config), patch.object(
                bundle, "RECOVERY", config / ".bundle-publication"):
            bundle.recover()
            self.assertEqual((config / "generated/new").read_text(), "new generated")
            bundle.publish(self.stage)

    def test_unrelated_prepared_names_survive_publication_and_recovery(self):
        config = self.config_at("unrelated")
        unrelated_dir = config / ".bundle-generated-new"
        unrelated_dir.mkdir()
        (unrelated_dir / "keep").write_text("unrelated")
        unrelated_file = config / ".bundle-blueprint-new"
        unrelated_file.write_text("unrelated")
        result = self.interrupt(config, "after-preparation")
        self.assertEqual(result.returncode, 91, result.stderr)
        with patch.object(bundle, "CONFIG", config), patch.object(
                bundle, "RECOVERY", config / ".bundle-publication"):
            bundle.recover()
            bundle.publish(self.stage)
        self.assertEqual((unrelated_dir / "keep").read_text(), "unrelated")
        self.assertEqual(unrelated_file.read_text(), "unrelated")

    def test_unexpected_recovery_entry_is_preserved_for_manual_review(self):
        config = self.config_at("unexpected")
        self.assertEqual(self.interrupt(config, "after-preparation").returncode, 91)
        extra = config / ".bundle-publication/unrelated"
        extra.write_text("preserve")
        with patch.object(bundle, "CONFIG", config), patch.object(
                bundle, "RECOVERY", config / ".bundle-publication"):
            with self.assertRaises(bundle.Invalid):
                bundle.recover()
        self.assertEqual(extra.read_text(), "preserve")
        self.assertEqual((config / "generated/old").read_text(), "old generated")

    def test_legacy_pre_marker_state_retries_without_deleting_unproven_paths(self):
        config = self.config_at("legacy-marker")
        record = {}
        for name, current, source in (("generated", config / "generated", self.stage / "generated"),
                                      ("blueprint", config / "blueprint.conf",
                                       self.stage / "blueprint.conf")):
            stat = current.stat()
            record[name] = {"present": True, "dev": stat.st_dev, "ino": stat.st_ino,
                            "old": bundle.fingerprint(current), "new": bundle.fingerprint(source)}
        recovery = config / ".bundle-publication"
        recovery.mkdir()
        (recovery / "marker.tmp").write_text(json.dumps(record))
        (config / ".bundle-generated-new").mkdir()
        (config / ".bundle-generated-new/keep").write_text("unproven")
        with patch.object(bundle, "CONFIG", config), patch.object(bundle, "RECOVERY", recovery):
            bundle.recover()
            self.assertEqual((config / "generated/old").read_text(), "old generated")
            bundle.publish(self.stage)
        self.assertEqual((config / ".bundle-generated-new/keep").read_text(), "unproven")
        self.assertEqual((config / "generated/new").read_text(), "new generated")


class TarHeaderSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    @staticmethod
    def header(size):
        data = bytearray(512)
        data[:8] = b"bad.mbt\0"
        data[124:136] = size
        data[156:157] = b"0"
        return bytes(data)

    def reject(self, data, message):
        archive = self.root / "malformed.mbt"
        archive.write_bytes(data)
        result = subprocess.run([sys.executable, str(MODULE), "unpack", str(archive),
                                 str(self.root / "stage"), str(self.root)],
                                capture_output=True, timeout=2)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn(message, result.stderr.decode())
        self.assertFalse((self.root / "stage").exists())

    def test_negative_and_signed_sizes_terminate(self):
        for size in (b"-0000001000\0", b"+0000000001\0"):
            with self.subTest(size=size):
                self.reject(self.header(size) + bytes(1024), "invalid archive header")

    def test_nonoctal_and_empty_sizes_terminate(self):
        for size in (b"0000000008\0", b"00 00000001\0", bytes(12)):
            with self.subTest(size=size):
                self.reject(self.header(size) + bytes(1024), "invalid archive header")

    def test_entry_count_and_size_are_bounded_during_raw_scan(self):
        self.reject(self.header(b"00000000000\0") * 33 + bytes(1024),
                    "too many Bundle entries")
        self.reject(self.header(f"{bundle.MAX_MEMBER + 1:011o}\0".encode()) + bytes(1024),
                    "oversized archive entry")
        self.reject(self.header(b"00000002000\0") + bytes(512),
                    "invalid archive entry size")


if __name__ == "__main__":
    unittest.main()
