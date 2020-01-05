function Invoke-Order
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory)]
        [hashtable] $Order
    )
    
    begin
    {
        
    }
    
    process
    {
        $parsedOrder = ParseOrder -Order $Order
        $actionPlan = GetOrderActions -Order $parsedOrder

        foreach ($action in $ActionPlan)
        {
            Write-Debug -Message $($action | ConvertTo-Json)

            $functionParams = $action.Parameters

            if ($action.Command -eq 'NewVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Creating VM"))
                {
                    New-VM @functionParams
                    #Set-VMFirmware -VMName $functionParams.Name -SecureBootTemplate 'MicrosoftUEFICertificateAuthority'
                }
            }
            elseif ($action.Command -eq 'SetVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Altering $($action.Parameters.Keys.Count - 1) properties on VM"))
                {
                    Set-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'StopVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Stopping VM"))
                {
                    Stop-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'StartVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Starting VM"))
                {
                    Start-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'CreateVHDX')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Path, "Creating Virtual Disk"))
                {
                    New-VHD @functionParams
                }
            }
            elseif ($action.Command -eq 'AddVHDXToVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Adding disk to VM: $($action.Parameters.Path)"))
                {
                    Add-VMHardDiskDrive @functionParams
                }
            }
            elseif ($action.Command -eq 'ExpandVHDX')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Path, "Expand Virtual Disk to: $($action.Parameters.SizeBytes / 1GB)GB"))
                {
                    Resize-VHD @functionParams
                }
            }
            elseif ($action.Command -eq 'CopyImage')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Destination, "Create system-disk using image-disk '$($action.Parameters.ImageDisk)'"))
                {
                    if (-not (Test-Path $action.Parameters.ImageDisk))
                    {
                        Write-Error -Message "Unable to find file: $($action.Parameters.ImageDisk), please specify a valid Image" -ErrorAction Stop
                    }

                    $destinationContainer = $action.Parameters.Destination.Directory
                    $copyFileName = $action.Parameters.ImageDisk.Name

                    Copy-Item -Path $action.Parameters.ImageDisk.FullName -Destination $destinationContainer
                    Rename-Item -Path "$($destinationContainer.FullName)\$copyFileName" -NewName "$($action.Parameters.Destination.Name)"
                }
            }
            elseif ($action.Command -eq 'CreateCloudInitDisk')
            {
                $_tempfolder = "$($action.Parameters.StoragePath)\cloud-init-files"
                $_isopath = "$($action.Parameters.StoragePath)\cloud-init.iso"

                if ($PSCmdlet.ShouldProcess($_isopath, "Create cloud-init-disk"))
                {
                    if (-not (Test-Path $_tempfolder))
                    {
                        New-Item -Path $_tempfolder -ItemType Directory
                    }

                    if (Test-Path $_isopath)
                    {
                        Remove-Item -Path $_isopath -Force
                    }

                    Set-Content -Path "$_tempfolder\meta-data" -Value ([byte[]][char[]] "$($action.Parameters.MetaData)") -Encoding Byte -Force
                    Set-Content -Path "$_tempfolder\user-data" -Value ([byte[]][char[]] "$($action.Parameters.UserData)") -Encoding Byte -Force

                    & ($action.Parameters.oscdimgPath) "$_tempfolder" "$_isopath" -j2 -lcidata
                }
            }
            elseif ($action.Command -eq 'SetDiskISO')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Path, "Set disk for VM '$($action.Parameters.Path)'"))
                {
                    Set-VMDvdDrive -VMName $action.Parameters.Name -Path $action.Parameters.Path
                }                
            }
            elseif ($action.Command -eq 'AddNetAdapter')
            {
                if ($PSCmdlet.ShouldProcess('Network Adapter', "Recreating network adapter for VM: '$($action.Parameters.Path)'"))
                {                        
                    $existingAdapter = Get-VMNetworkAdapter -VMName $action.Parameters.VMName
                    $existingAdapter | Remove-VMNetworkAdapter

                    Add-VMNetworkAdapter -VMName $action.Parameters.VMName -SwitchName $action.Parameters.Switch
                                       
                    if ($action.Parameters.Vlan -ne $false)
                    {
                        $newAdapter = Get-VMNetworkAdapter -VMName $action.Parameters.VMName
                        $newAdapter | Set-VMNetworkAdapterVlan -VlanId $action.Parameters.Vlan -Access
                    }
                }
            }
        }
    

        $actionPlan # Write-Output actions taken
    }
    
    end
    {
        
    }
}