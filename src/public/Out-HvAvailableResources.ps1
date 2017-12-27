function Out-HVAvailableResources {
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable] $ModuleConfig = $(Import-PowerShellDataFile -Path "$PSScriptRoot\..\config\module.psd1" )
    )
    
    begin {  
    }
    
    process {
        $outputPath = "$($ModuleConfig.BasePath)\ReadOnly\available.resources.json"

        $output = @{
            CPU = @{}
            Memory = @{} 
            Disk = @{}
        }

        # CPU
        Write-Verbose "Getting CPU-info..."
        $output.CPU.InUse = (Get-VM | Measure-Object -Property ProcessorCount -Sum).Sum
        $output.CPU.Max = (Get-CimInstance -ClassName 'Win32_Processor' | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum * $ModuleConfig.OverProvisioningFactors.CPU
        $output.CPU.Available = $output.CPU.Max - $output.CPU.InUse
        $output.CPU.InUsePercentage = [Math]::Round(($output.CPU.InUse * 100) / $output.CPU.Max, 2)
        
        # Memory
        Write-Verbose "Getting Memory-info..."
        $output.Memory.InUse = (Get-VM | Measure-Object -Property MemoryStartup -Sum).Sum
        $output.Memory.Max = (Get-CimInstance -ClassName 'cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum * $ModuleConfig.OverProvisioningFactors.Memory
        $output.Memory.Available = $output.Memory.Max - $output.Memory.InUse
        $output.Memory.InUsePercentage = [Math]::Round(($output.Memory.InUse * 100) / $output.Memory.Max, 2) 

        # Disk
        Write-Verbose "Getting Disk-info..."
        $vhd_volumes = Get-Volume -DriveLetter $ModuleConfig.HyperVStorage.VhdDriveLetters

        $output.Disk = @(foreach($volume in $vhd_volumes)
        {
            $v_output = @{
                DriveLetter = $volume.DriveLetter
                Label = $volume.FileSystemLabel
            }

            $v_output.InUse = $volume.Size - $volume.SizeRemaining
            $v_output.Max = $volume.Size
            $v_output.Available = $volume.SizeRemaining
            $v_output.InUsePercentage = [Math]::Round(($v_output.InUse * 100) / $volume.Size, 2)

            $v_output
        })

        # Output JSON to disk
        Write-Verbose "Writing to file: $outputPath"
        $output | ConvertTo-Json -Depth 10 | Out-File $outputPath
    }
    
    end {
    }
}