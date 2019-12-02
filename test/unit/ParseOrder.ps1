. $PSScriptRoot\..\..\src\private\ParseOrder.ps1

# ParseOrder
Describe 'ParseOrder' {
    Context 'Memory' {
        $memTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = '512MB'
                }
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = 1073741824
                }
            }
            @{
                case = 'Dynamic memory without min,max (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                    }
                }
            }
            @{
                case = 'Dynamic memory without min (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '1GB'
                        Max     = '1GB'
                    }
                }
            }
            @{
                case = 'Dynamic memory without max (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                        Min     = '512MB'
                    }
                }
            }
            @{
                case = 'Extra key (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                        Kake    = $true
                    }
                }
            }
        )

        It 'Is hashtable - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $result.Memory | Should -BeOfType [hashtable]
        }

        $memoryKeys = @('Dynamic', 'Boot', 'Min', 'Max')

        It 'Adds missing properties - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $missingKeys = $memoryKeys.Where{ $_ -notin $result.Memory.Keys }
            $missingKeys -join ', ' | Should -BeNullOrEmpty
        }

        It 'Removes unknown keys - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $missingKeys = $result.Memory.Keys.Where{ $_ -notin $memoryKeys }
            $missingKeys -join ', ' | Should -BeNullOrEmpty
        }

        It 'Ensures numbers are [long] - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder

            $result.Memory.Boot | Should -BeOfType [long]
            $result.Memory.Min | Should -BeOfType [long]
            $result.Memory.Max | Should -BeOfType [long]
        }
    }

    Context 'Disk' {
        $diskTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = '10GB'
                }
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = 5368709120
                }
            }
            @{
                case = 'Single disk, no system (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            Size = '15GB'
                        }
                    )
                }
            }
            @{
                case = 'Single disk (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            System = $true
                            Size   = '15GB'
                        }
                    )
                }
            }
            @{
                case = 'Multiple disks (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            System = $true
                            Size   = '15GB'
                        }
                        @{
                            Name = 'Data'
                            Size = '20GB'
                        }
                    )
                }
            }
        )

        It 'Converts single value to one disk' {
            $obj = @{
                VMName = 'test' # Mandatory
                Disks  = '10GB'
            }
            $result = $obj | ParseOrder
            #$result.Disks | Should -BeOfType [System.Object[]]
            $result.Disks | Should -BeOfType [System.Collections.Hashtable]
            $result.Disks.Count | Should -Be 1
        }

        It 'Is array - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $result.Disks | Should -BeOfType [System.Collections.Hashtable]
        }

        It 'Adds missing properties - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder

            foreach ($disk in $result.Disks)
            {
                $missingKeys = @('System', 'Name', 'Size').Where{ $_ -notin $disk.Keys }
                $missingKeys -join ', ' | Should -BeNullOrEmpty
            }
        }

        It 'Ensures .Size is [long] - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder

            foreach ($disk in $result.Disks)
            {
                $disk.Size | Should -BeOfType [long]
            }
        }
    }
}