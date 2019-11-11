function Get-SetVMParameters
{
    [CmdletBinding()]
    param (
        [PSCustomObject] $order
    )
    
    begin
    {
        $moduleConfig = Import-Configuration
    }
    
    process
    {
        $output = @{
            Parameters       = @{ }
            ShutdownRequired = $false
        }

        $ordered = [VM]::new($order, $moduleConfig.VMStoragePath)
        $existing = [VM]::Discover($ordered.Name)

        if ($ordered.AutomaticStartAction -ne $existing.AutomaticStartAction)
        {
            $output['Parameters']['AutomaticStartAction'] = $ordered.AutomaticStartAction
        }

        if ($ordered.AutomaticStartDelay -ne $existing.AutomaticStartDelay)
        {
            $output['Parameters']['AutomaticStartDelay'] = $ordered.AutomaticStartDelay
        }

        if ($ordered.AutomaticStopAction -ne $existing.AutomaticStopAction)
        {
            $output['Parameters']['AutomaticStopAction'] = $ordered.AutomaticStopAction

            # Requires shutdown of VM, errors if VM is running
            $output['ShutdownRequired'] = $true
        }

        if ($ordered.ProcessorCount -ne $existing.ProcessorCount)
        {
            $output['Parameters']['ProcessorCount'] = $ordered.ProcessorCount
            
            # Requires always shutdown of VM before changing
            $output['ShutdownRequired'] = $true
        }

        if ($ordered.DynamicMemory -ne $existing.DynamicMemory)
        {
            if ($ordered.DynamicMemory)
            {
                $output['Parameters']['DynamicMemory'] = $true
            }
            else 
            {
                $output['Parameters']['StaticMemory'] = $true
            }
            
            # Requires always shutdown of VM to change from one to the other
            $output['ShutdownRequired'] = $true
        }

        if ($ordered.StartupMemoryInBytes -ne $existing.StartupMemoryInBytes)
        {
            $output['Parameters']['MemoryStartupBytes'] = $ordered.StartupMemoryInBytes

            # StartupBytes requires always shutdown of VM to change
            $output['ShutdownRequired'] = $true
        }

        if ($ordered.MaximumMemoryInBytes -ne $existing.MaximumMemoryInBytes)
        {
            $output['Parameters']['MemoryMaximumBytes'] = $ordered.MaximumMemoryInBytes

            # Shutdown is only required if the new MaximumBytes-value is lower than the old
            if ($ordered.MaximumMemoryInBytes -lt $existing.MaximumMemoryInBytes)
            {
                $output['ShutdownRequired'] = $true
            }
        }

        if ($ordered.MinimumMemoryInBytes -ne $existing.MinimumMemoryInBytes)
        {
            $output['Parameters']['MemoryMinimumBytes'] = $ordered.MinimumMemoryInBytes

            # Shutdown is only required if the new MinimumBytes-value is higher than the old
            if ($ordered.MaximumMemoryInBytes -gt $existing.MaximumMemoryInBytes)
            {
                $output['ShutdownRequired'] = $true
            }
        }

        $output # Write-Output
    }
    
    end
    {
        
    }
}