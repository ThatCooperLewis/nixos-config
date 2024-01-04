# QEMU/KVM and GPU Passthrough

A handful of things that need to be done first:

- Enable the VM network

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
