# QEMU/KVM and GPU Passthrough

A handful of things that need to be done first:

- Enable the VM network ([forum post](https://www.reddit.com/r/VFIO/comments/6iwth1/network_default_is_not_active_after_every/))

        sudo virsh net-start default
        sudo virsh net-autostart default

- Change the NIC to `vfio`
- In CPU, set the topology appropriately

- Add some lines to the VM's XML config

        <features>
            <acpi/>
            <apic/>
            <hyperv mode="custom">
                <relaxed state="on"/>
                <vapic state="on"/>
                <spinlocks state="on" retries="8191"/>
                <vendor_id state="on" value="kvm hyperv"/>
            </hyperv>
            <kvm>
                <hidden state="on"/>
            </kvm>
            <vmport state="off"/>
            <ioapic driver="kvm"/>
        </features>


- Also update the GPU elements with `driver name vfio` 

        <hostdev mode="subsystem" type="pci" managed="yes">
            <driver name="vfio"/>
            <source>
                <address domain="0x0000" bus="0x0b" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
        </hostdev>

- Pass through Pulseaudio for sound input/output

        <sound model="ich9">
            <codec type="micro"/>
            <audio id="1"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
        </sound>
        <audio id="1" type="pulseaudio" serverName="/run/user/1000/pulse/native">
            <input mixingEngine="no"/>
            <output mixingEngine="no"/>
        </audio>

- Per [this forum post](https://forums.unraid.net/topic/127639-easy-anti-cheat-launch-error-cannot-run-under-virtual-machine/) to work around EAC


    > under `<os>` put

        <smbios mode='host'/>

    > directly below that put this under `<features>`

        <kvm> 
            <hidden state='on'/> 
        </kvm>

    > under `<cpu mode ='host-passthrough'`....... put

        <feature policy='disable' name='hypervisor'/>

    > and i also deleted any lines pertaining to hyper-v 