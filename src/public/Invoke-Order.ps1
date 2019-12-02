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
                if ($PSCmdlet.ShouldProcess($action.Parameters.Path, "Expand Virtual Disk to: $($action.Parameters.Path.SizeBytes / 1GB)GB"))
                {
                    Resize-VHD @functionParams
                }
            }
        }

        $actionPlan # Write-Output actions taken
    }
    
    end
    {
        
    }
}