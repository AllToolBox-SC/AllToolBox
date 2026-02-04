from flash_ak3 import AnyKernel3

ak3 = AnyKernel3("android12-5.10.101-2022-04-AnyKernel3.zip")
ak3.extract_zip()
ak3.rename_mainfile()
ak3.unpack_bootimg("./boot.img", "./boot")
ak3.patch_bootimg()
ak3.repack_bootimg(repack_to="boot_patched.img")