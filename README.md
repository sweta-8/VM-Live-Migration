# VM-Live-Migration

Readme: VM live migration-------------------------------------------------

VM Specifications:

1.  Cores: 16

2.  RAM: 8 GB

3.  OS: Ubuntu 22.04

On Server Machine
-----------------------------------------------------------------------------------

1.  First, install Ubuntu or any OS on virtual machine manager (VMM).

2.  Create libvrt-img folder in /var/lib and create images folder in the libvrt-img.

3.  Mount the VMM disk image of created VMM from /var/lib/libvrt/images in /var/lib/libvrt-img/images using command:

        > Sudo mount –bind /var/lib/libvrt/images /var/lib/libvrt-img/images

4.  Run sudo apt install nfs-kernal-server.

5.  Add ip addresses of your guest machines or NFS client to /etc/hosts.allow Or run
            > sudo ufw allow from 10.130.171.189 to any port nfs

6.  Run sudo systemctl restart nfs-config.service to apply changes.

7.  Run sudo systemctl status nfs.service to know the status of nfs server.

8.  Update /etc/exports with

     > “*/var/lib/libvirt-img/images ip_addr1(rw,sync,no_subtree_check) ip_addr2(rw,sync,no_subtree_check)”*

9.  Run exports –arv ---------------- to update all the setting

On both Guest Machine (source & Destination)
--------------------------------------------

1.  Make libvirt-img folder in /var/lib directory and create images folder in the libvrt-img.

2.  Run command--

         > Sudo mount server_ip_addr:/var/lib/libvrt-img/images/ /var/lib/libvrt-img/images/

3.  Run ls command in /var/lib/libvrt-img/images directory to verify if the disk image from server was mounted in your guest machine ornot.

4.  Run VMM and use that mounted image from server to run virtual machine.

5.  If it runs, then successful mounting of image was done. Yess!!!!!!

Process for Live Migration
-------------------------------------------------------------------------

Note: - To migrate a vm to another machine using qemu+ssh you need to have the SSH keys generated beforehand of the destination system.

1.  Add the “hostname” of source & destination in /etc/hosts on both source and destination.

2.  Run command on source --

        > *sudo virsh migrate --live ubuntu22.04 --verbose qemu+ssh://user@dest_ip_addr/system*

3.  If the above command is successful, then if we run the command on our destination host “*virsh list -- all*" then we can see our VM running there.

***Collecting Statistics of VM live migration****
--------------------------------------------------***

We will start the VM live migration and check the statistics during
migration using command:

    > Virsh domjobinfo

To collect all the stats while migrating, we wrote a script file, which
runs the above command till the migration completes and collect its
statistics for every 1 second till the migration completes.

Run the script file using

sudo bash get_status.sh

Script File for collecting migration details:

> *\#!/bin/bash*

> *OUTPUT_FILE="memory_intensive_csetosweta.txt"*

> *while true; do*

> * \# Redirect both stdout and stderr to the output file*

> * output=$(virsh domjobinfo ubuntu22.04);*

> * \# If the command fails, the exit code will be non-zero*

> * if \[ -z $output \]; then*

> * exit 1;*

> * else *

> * echo "$output"\>\>$OUTPUT_FILE;*

> * fi*

> *Done*

Types of Workloads used:
--------------------------------------------------------------------------------------

1.  CPU-Idle workloads: In this, there is almost 0% of load on all the cores.

2.  CPU intensive workload(cpu_util.c): For this workload, we created 16 threads, and each thread is doing the following computation

> While(1)

> {

> for (int i = 0; i \< ITERATIONS; i++)

> *{*  
> * result += pow(sin(i), i) + tid; // Some heavy arbitrary
> computation*  
> *}*

> }

3.  Memory intensive workload (memory_intensive.c): For this workload, we created 14 threads, and each thread is allocating 512 MB memory, and it does constant load/store operations in the allocated memory.

Migration Techniques:
------------------------------------------------------------------------------------------

We are using pre-copy without any threshold in all the workload except
memory intensive workload because when we used pre-copy for memory
intensive workload, migration was unable to complete due to high no. Of
dirty pages after every iteration. So, we used post-copy for memory
intensive workload.

Migrating using post-copy:
-------------------------------------------------------------------------------------

We first enable userfaultfd feature in the Linux kernel, which is
required for post-copy migration. In some Linux distributions, this
feature is disabled by default for security reasons. So, we enable it
using following command on both host and destination:

    > sudo sysctl -w "vm.unprivileged_userfaultfd=1"

To enable postcopy in QEMU, we run the following command

    > virsh qemu-monitor-command --hmp ubuntu22.04 'migrate_set_capability postcopy-ram on'

This will enable the post-copy in QEMU for the given image (our image
name is ubuntu22.04)

To Migrate our VM using post-copy, we run the following command:

    > *sudo virsh migrate --live --postcopy --timeout 25 --timeout-postcopy ubuntu22.04 --verbose qemu+ssh://user@dest_ip_addr/system*

Steps to be performed for migration to collect:---------------------------------------------------

1.  all our workloads, we first compiled the workload files like memory_intensive.c and cpu_util.c inside our VM .

2.  Run the workload inside VM.

3.  Run the migrate command in one terminal to migrate the VM to destination host.

4.  Run the script file get_status.sh in another terminal to collect all stats
