# HyperVendingMachine

Module to simplify creating/modifying Hyper-V VMs

## Examples

Create VM with 1 CPU, 4GB dynamic memory and 10GB system-disk:
```powershell
$order = @{
    VMName = 'Test'
    CPUs = 1
    Memory = 4GB
    Disks = 10GB
}

Invoke-HVMOrder -Order 
```
---
Create VM with 2GB static memory and two disks:
```powershell
$order = @{
    VMName = 'Test2'
    CPUs = 1
    Memory = @{
        Dynamic = $false
        Boot = 2GB
    }
    Disks = @(
        30GB, # First disk is assigned as "system-disk"
        50GB
    )
}

Invoke-HVMOrder -Order $order
```
---
Create VM with network-adapter connected to v-switch `test-switch`:
```powershell
$order = @{
    VMName = 'Test3'
    CPUs = 1
    Memory = 1GB
    Disks = 5GB
    Network = 'test-switch'
}

Invoke-HVMOrder -Order $order
```
---
Assign VLAN-id to network-adapter:
```powershell
$order = @{
    VMName = 'Test4'
    CPUs = 1
    Memory = 1GB
    Disks = 5GB
    Network = @{
        Switch = 'test-switch'
        Vlan = 1
    }
}

Invoke-HVMOrder -Order $order
```
---
Change `Test2`s memory configuration from Static to Dynamic
```powershell
$order = @{
    VMName = 'Test2'
    Memory = @{
        Dynamic = $true
        Boot = 2GB
        # Min = <if not set = 'Boot' / 2>
        # Max = <if not set = 2 x'Boot'>
    }
}

Invoke-HVMOrder -Order $order # Reboots VM if running
```
---
Create VM using ubuntu 18.04 .vhdx found in `D:\HyperVendingMachine\Image`, and create admin-user using [cloud-init](https://cloudinit.readthedocs.io/en/latest/):
```powershell
$order = @{
    VMName = 'TestFromImage'
    Memory = 2GB
    Disks = 10GB
    Image = 'ubuntu/bionic'
    Network = 'test-switch'
    CI_UserData =  @{
        users = @(@{
            name = 'serveradmin'
            'ssh-import-id' = 'gh:stoneguardian'
        }
    }
}

Invoke-HVMOrder -Order $order
```