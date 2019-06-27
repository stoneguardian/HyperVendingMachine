function Get-AvailableResources
{
    [CmdletBinding()]
    param (
        
    )
    
    begin
    {
        $ModuleConfig = Import-Configuration
        $output = @{
            CPU    = @{ }
            Memory = @{ } 
            Disk   = @{ }
        }
    }
    
    process
    {
        $output['CPU']['Used'] = (Get-VM | Measure-Object -Property ProcessorCount -Sum).Sum
        $output['CPU']['Max'] = (Get-CimInstance -ClassName 'Win32_Processor' | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum * $ModuleConfig.OverprovisionFactors.CPU
        $output['CPU']['Available'] = $output['CPU']['Max'] - $output['CPU']['Used']
        $output['CPU']['PercentageUsed'] = [Math]::Round(($output['CPU']['Used'] * 100) / $output['CPU']['Max'], 2)

        $output['Memory']['Used'] = (Get-VM | Measure-Object -Property MemoryStartup -Sum).Sum
        $output['Memory']['Max'] = (Get-CimInstance -ClassName 'cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum * $ModuleConfig.OverprovisionFactors.Memory
        $output['Memory']['Available'] = $output['Memory']['Max'] - $output['Memory']['Used']
        $output['Memory']['PercentageUsed'] = [Math]::Round(($output['Memory']['Used'] * 100) / $output['Memory']['Max'], 2)

        $volume = Get-Volume -DriveLetter $ModuleConfig.VMStoragePath[0] # First char is driveletter
        $output['Disk']['Used'] = $volume.Size - $volume.SizeRemaining
        $output['Disk']['Max'] = $volume.Size
        $output['Disk']['Available'] = $volume.SizeRemaining
        $output['Disk']['PercentageUsed'] = [Math]::Round(($output['Disk']['Used'] * 100) / $output['Disk']['Max'], 2)

        $output # Write-Output
    }
    
    end
    {
    }
}