properties {
    $ModuleName = 'HyperVendingMachine'
    
    $SourceDirectoryName = 'src'

    $ReleasePath = "$PSScriptRoot/release/$ModuleName"
    $SourcePath = "$PSScriptRoot/$SourceDirectoryName/"

    $PSM1Path = "$ReleasePath/$ModuleName.psm1"
}

task Clean {
    if (Test-Path $ReleasePath)
    {
        $null = Remove-Item -Path $ReleasePath -Force -Recurse
    }
}

task Init -depends 'Clean'{
    $null = New-Item -Path $ReleasePath -Force -ItemType 'Directory'
}

task CopyItems -depends 'Init' {
    Copy-Item -Path "$SourcePath/$ModuleName.psd1" -Destination $ReleasePath
    Copy-Item -Path "$SourcePath/config" -Destination $ReleasePath
    Copy-Item -Path "$SourcePath/templates" -Destination $ReleasePath
}

task BuildPSD1 -depends 'Init' {
    "# `n# Commit: $(git rev-parse HEAD) " | 
        Out-File -FilePath $PSM1Path

    "# File generated: $(Get-Date -Format u) `n#" | 
        Out-File -FilePath $PSM1Path -Append
    
    if (Test-Path "$SourcePath/classes")
    {
        "`n# Classes" |
            Out-File -FilePath $PSM1Path -Append

        foreach ($class in (Get-ChildItem -Path "$SourcePath/classes" -Filter '*.ps1'))
        {
            "## $SourceDirectoryName/classes/$($class.Name)" |
                Out-File -FilePath $PSM1Path -Append

            Get-Content -Path $class.FullName | 
                Out-File -FilePath $PSM1Path -Append

            " " | 
                Out-File -FilePath $PSM1Path -Append
        }
    }

    "`n# Functions" | 
        Out-File -FilePath $PSM1Path -Append

    if (Test-Path "$SourcePath/private")
    {
        foreach ($func in (Get-ChildItem -Path "$SourcePath/private" -Filter '*.ps1'))
        {
            "## $SourceDirectoryName/private/$($func.Name)" |
                Out-File -FilePath $PSM1Path -Append

            Get-Content -Path $func.FullName | 
                Out-File -FilePath $PSM1Path -Append

            " " | 
                Out-File -FilePath $PSM1Path -Append
        }
    }

    if (Test-Path "$SourcePath/public")
    {
        foreach ($func in (Get-ChildItem -Path "$SourcePath/public" -Filter '*.ps1'))
        {
            "## $SourceDirectoryName/public/$($func.Name)" |
                Out-File -FilePath $PSM1Path -Append

            Get-Content -Path $func.FullName | 
                Out-File -FilePath $PSM1Path -Append

            " " | 
                Out-File -FilePath $PSM1Path -Append
        }
    }

    if (Test-Path "$SourcePath/OnModuleLoad.ps1")
    {
        "`n# Code that runs when module is loaded" | 
            Out-File -FilePath $PSM1Path -Append

        Get-Content -Path "$SourcePath/OnModuleLoad.ps1" | 
            Out-File -FilePath $PSM1Path -Append
    }
}

task Build -depends 'CopyItems', 'BuildPSD1'