# gentoo-cloud-prep

Some scripts to help with the following:

- Get the latest stage3 from a mirror
- Catalyst that shit up into a stage4 for your own voodoo
- Prepare a physical disk based on that stage4, throw grub on it, generate a qcow2 image

### Prep and Usage: How do?

First we need some packages.

`# emerge catalyst qemu`

Now we can run `catalyst` and `qemu-img`.  If you only need the stage4, you can omit `qemu`.

Next you'll notice the scripts.  They each have variables you'll probably want to change, or prep your system for.  Do one of those two things, or well, expect tears.

Run the scripts in order, and you'll have a shiny new set of files, depending on what you wanted.

### Quick Overview: What do?

- `01-get-stage3.sh` will get the latest stage3 for you, from whatever mirror is supplied in the script.  You can use the default, but it's throttled for traffic outside my IP range.
- `02-catalyst-that-shit.sh` will take the stage3 generated a moment ago, and spit out a stage4 for you.  You will have to change variables here, I haven't included any overlays.  Stop here if you only want a stage4.
- `03-prep-that-image.sh` will take that stage4 that you just generated, and first wipe the target disk (entirely), make a partition table, `mkfs.ext4` it, splat the stage4 on it, and newest portage.  It will then unmount it, and throw grub on it.  After that, it will `dd` the disk into a raw image, and then `qemu-img convert` that raw image into a `qcow2` format, then remove the raw image.

### License: No don't!

Just kidding, do whatever you want.  Unless that involves blaming me.  Don't blame me.
