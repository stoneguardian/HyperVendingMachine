class VM
{
    [ValidateNotNullOrEmpty()]
    [string] $Name

    [string] $Path

    [ValidateSet(1, 2)]
    [int] $Generation = 2

    [ValidateSet('StartIfRunning', 'Start', 'Nothing')]
    [string] $AutomaticStartAction = 'StartIfRunning'

    [int] $AutomaticStartDelay = 0

    [ValidateSet('Save', 'ShutDown', 'TurnOff')]
    [string] $AutomaticStopAction = 'Save'

    [int] $ProcessorCount = 1

    [bool] $DynamicMemory = $true

    [long] $StartupMemoryInBytes

    [long] $MaximumMemoryInBytes

    [long] $MinimumMemoryInBytes

    VM([PSCustomObject]$order, [string]$baseStoragePath)
    {
        $missingMandatoryProperties = $order |
        PSCustomObjectContainsProperty -Name 'Name', 'StartupMemoryInBytes'

        if (@($missingMandatoryProperties).Count -gt 0)
        {
            Write-Error -Message "The follow mandatory parameters were not given: `n -$($missingMandatoryProperties -join "`n -")" -ErrorAction Stop
        }

        $this.Name = $order.Name
        $this.Path = "$baseStoragePath\$($order.Name)"
        $this.StartupMemoryInBytes = $order.StartupMemoryInBytes

        if (PSCustomObjectContainsProperty -Name 'ProcessorCount' -InputObject $order -BoolOutput)
        {
            $this.ProcessorCount = $order.ProcessorCount
        }

        # Memory
        $orderHasMaxProp = PSCustomObjectContainsProperty -Name 'MaximumMemoryInBytes' -InputObject $order -BoolOutput
        $orderHasMinProp = PSCustomObjectContainsProperty -Name 'MinimumMemoryInBytes' -InputObject $order -BoolOutput

        $this.DynamicMemory = ($orderHasMaxProp) -or ($orderHasMinProp)

        if (($this.DynamicMemory) -and ($orderHasMaxProp))
        {
            $this.MaximumMemoryInBytes = $order.MaximumMemoryInBytes
        }
        elseif ($this.DynamicMemory)
        {
            $this.MaximumMemoryInBytes = $this.StartupMemoryInBytes
        }

        if (($this.DynamicMemory) -and ($orderHasMinProp))
        {
            $this.MinimumMemoryInBytes = $order.MinimumMemoryInBytes
        }
        elseif ($this.DynamicMemory)
        {
            $this.MinimumMemoryInBytes = $this.StartupMemoryInBytes
        }

        if ($this.MaximumMemoryInBytes -le $this.MinimumMemoryInBytes)
        {
            Write-Warning "Maximum memory ($($this.MaximumMemoryInBytes / 1GB) GB) is less than minimum memory ($($this.MinimumMemoryInBytes / 1GB) GB), setting Maximum memory to $($this.MinimumMemoryInBytes / 1GB) GB"
            $this.MaximumMemoryInBytes = $this.MinimumMemoryInBytes
        }
    }

    VM([string]$name)
    {
        $this.Name = $name
    }

    static [VM] Discover([string]$name)
    {
        $vm = Get-VM -Name $name
        $vm_cpu = Get-VMProcessor -VMName $name
        $vm_mem = Get-VMMemory -VMName $name

        $output = [VM]::new($name)
        $output.Path = $vm.Path
        $output.Generation = $vm.Generation
        $output.AutomaticStartAction = $vm.AutomaticStartAction
        $output.AutomaticStartDelay = $vm.AutomaticStartDelay
        $output.AutomaticStopAction = $vm.AutomaticStopAction
        $output.ProcessorCount = $vm_cpu.Count
        $output.DynamicMemory = $vm_mem.DynamicMemoryEnabled
        $output.StartupMemoryInBytes = $vm_mem.Startup
        $output.MaximumMemoryInBytes = $vm_mem.Maximum
        $output.MinimumMemoryInBytes = $vm_mem.Minimum

        return $output
    }
}