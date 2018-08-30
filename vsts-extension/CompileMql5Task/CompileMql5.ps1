[CmdletBinding()]
param()

$compilerDownloadLink = ""
Trace-VstsEnteringInvocation $MyInvocation

try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

    #get the inputs
    [string]$pathToSources = Get-VstsInput -Name pathToSources -Require
    [string]$mql5IncludePath = Get-VstsInput -Name mql5IncludePath
    [string]$metaEditorPath = Get-VstsInput -Name metaEditorPath

    if("$mql5IncludePath" -eq "")
    {
        $mql5IncludePath = $PSScriptRoot
    }

    if("$pathToSources" -eq "")
    {
        $pathToSources = "$($env:BUILD_SOURCESDIRECTORY)\*.mqproj"
    }

    if("$metaEditorPath" -eq "")
    {
        #download the file if not exist already
        $metaEditorPath = "$($env:AGENT_WORKFOLDER)\_mql5\metaeditor64.exe"
        if(-not (Test-Path $metaEditorPath -PathType Leaf))
        {
            Write-Host "Metatrader compiler not found. Downloading from $compilerDownloadLink"
            [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($metaEditorPath)) | Out-Null
            (New-Object System.Net.WebClient).DownloadFile($compilerDownloadLink, $metaEditorPath)
        }
    }

    $compileFiles = Find-VstsMatch -DefaultRoot $env:BUILD_SOURCESDIRECTORY -Pattern $pathToSources

    foreach($file in $compileFiles)
    {
        Write-Host "Compiling MQL5 files: $file"

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo.UseShellExecute = $false
        $proc.StartInfo.FileName = $metaEditorPath
        $proc.StartInfo.CreateNoWindow = $true
        $proc.StartInfo.Arguments = "/compile:`"$file`" /log /include:`"$mql5IncludePath`""
        $proc.Start() | Out-Null
        $proc.WaitForExit()
        $exitCode = $proc.ExitCode

        #find all log files created since we started compilation
        $logFile = [System.IO.Path]::ChangeExtension($file, ".log")
        if(Test-Path $logFile -PathType Leaf)
        {
            Write-Host "Compilation log $([System.IO.Path]::GetFileName($logFile)):"
            Write-Host "====================================================================="
            Write-Host (Get-Content $logFile -Raw)
        }
        else 
        {
            Write-Host "No log created during compilation."
        }
        
        #1 - when successful, 0 when fails
        if($exitCode -ne 1)
        {
            Write-Error "Compilation failed (exit code $exitCode)"
        }
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}