import os
import tempfile
import unittest
import zipfile
from subprocess import CompletedProcess
from unittest.mock import patch

from src.flash_ak3 import AnyKernel3


class TestAnyKernel3(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir_ctx = tempfile.TemporaryDirectory()
        self.tmpdir = self.tmpdir_ctx.name

    def tearDown(self) -> None:
        self.tmpdir_ctx.cleanup()

    def _create_ak3_zip(self, name: str = "Image", content: bytes = b"kernel-data") -> str:
        zip_path = os.path.join(self.tmpdir, "anykernel3.zip")
        with zipfile.ZipFile(zip_path, "w") as zf:
            zf.writestr(name, content)
        return zip_path

    def test_extract_zip_and_rename_mainfile(self) -> None:
        zip_path = self._create_ak3_zip("Image", b"img")
        extract_to = os.path.join(self.tmpdir, "extract")
        ak3 = AnyKernel3(zip_path, extract_to=extract_to)

        mainfile = ak3.extract_zip()
        self.assertTrue(os.path.isfile(mainfile))
        self.assertEqual(os.path.basename(mainfile), "Image")

        ak3.rename_mainfile("kernel")
        self.assertEqual(os.path.basename(ak3.mainfile), "kernel")
        self.assertTrue(os.path.isfile(ak3.mainfile))

    def test_patch_bootimg_copies_mainfile_to_kernel(self) -> None:
        ak3 = AnyKernel3("dummy.zip", extract_to=os.path.join(self.tmpdir, "extract"))
        source_kernel = os.path.join(self.tmpdir, "source_kernel")
        unpacked = os.path.join(self.tmpdir, "boot")
        os.makedirs(unpacked, exist_ok=True)

        with open(source_kernel, "wb") as f:
            f.write(b"patched-kernel")

        ak3.mainfile = source_kernel
        ak3.patch_bootimg(unpacked)

        target_kernel = os.path.join(unpacked, "kernel")
        self.assertTrue(os.path.isfile(target_kernel))
        with open(target_kernel, "rb") as f:
            self.assertEqual(f.read(), b"patched-kernel")

    def test_unpack_and_repack_bootimg_calls_magiskboot(self) -> None:
        zip_path = self._create_ak3_zip("Image", b"img")
        extract_to = os.path.join(self.tmpdir, "extract")
        unpacked = os.path.join(self.tmpdir, "boot")
        bootimg = os.path.join(self.tmpdir, "boot.img")
        repacked = os.path.join(self.tmpdir, "boot_patched.img")
        tool_dir = os.path.join(self.tmpdir, "tools")
        os.makedirs(tool_dir, exist_ok=True)
        with open(bootimg, "wb") as f:
            f.write(b"boot")

        ak3 = AnyKernel3(zip_path, extract_to=extract_to)
        ak3.extract_zip()
        ak3.rename_mainfile("kernel")

        ok_result = CompletedProcess(args=["magiskboot"], returncode=0, stdout="", stderr="")
        with patch("src.flash_ak3.subprocess.run", return_value=ok_result) as mock_run:
            with patch.object(AnyKernel3, "_get_cwd", return_value=tool_dir):
                ak3.unpack_bootimg(bootimg, unpacked)
                ak3.patch_bootimg()
                out_path = ak3.repack_bootimg(repack_to=repacked)

        self.assertEqual(out_path, os.path.abspath(repacked))
        self.assertEqual(mock_run.call_count, 2)
        unpack_call = mock_run.call_args_list[0]
        repack_call = mock_run.call_args_list[1]
        self.assertIn("unpack", unpack_call.args[0])
        self.assertIn("repack", repack_call.args[0])


if __name__ == "__main__":
    unittest.main()
