# Windows
## Reinstall Boot Manager
These instructions also work if:
- Bitlocker is activated
- the EFI partition is not displayed as a volume.

1. Delete EFI partition using `diskpart`:
   ```cmd
   REM select correct disk (replace x with the id of the disk)
   list disk
   sel disk X
   REM select efi partition (replace n with the id of the efi partition)
   list part
   sel part N
   REM delete efi partition
   del part override
   ```

2. Create new EFI partition using `diskpart`:
   ```cmd
   REM create efi system partition
   create partition EFI size=200
   REM format partition as fat32
   format quick fs=fat32 label="System"
   ```
   If more disk space is required to create the fat32 system (16 MB is not enough!), the C: partition can be reduced in size: 
   ```cmd
   REM select C:\ (replace n with the id of the root partition (probally the largest one))
   list part
   sel part N
   REM create more free space (200mb)
   shrink desired=200
   ```

3. Assign letter for EFI partition using `diskpart`:
   ```cmd
   REM select efi partition (replace n with the id of the efi partition)
   list vol
   sel vol N
   assign letter Y:
   ```

4. Reinstall Bootloader
   ```cmd
   bootrec /rebuildbcd
   bootrec /fixmbr
   bootrec /fixboot  # works even if you get access denied...
   bcdboot c:\Windows /s Y: /f ALL
   ```

5. Reboot
