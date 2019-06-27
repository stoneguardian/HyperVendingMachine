@{
    # Name = ''
    CPUs = 1
    Memory = 2GB
    DynamicMemory = $false

    NetworkSwitch = @('Default Switch')

    Disks = @(
        @{
            Size = 50GB
        }
    )

    ISO = 'WindowsServer-2016'
}