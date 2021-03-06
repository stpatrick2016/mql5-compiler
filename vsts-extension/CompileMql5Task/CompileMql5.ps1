[CmdletBinding()]
param()

$compilerDownloadLink = "https://github.com/stpatrick2016/mql5-compiler/blob/master/engine/metaeditor64.exe?raw=true"
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
            Write-Output "Metatrader compiler not found. Downloading from $compilerDownloadLink"
            [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($metaEditorPath)) | Out-Null

            #fix the TLS issues, see here: https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
            [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

            #faster than Invoke-WebRequest, performance-wise
            (New-Object System.Net.WebClient).DownloadFile($compilerDownloadLink, $metaEditorPath)
        }
    }

    $compileFiles = Find-VstsMatch -DefaultRoot $env:BUILD_SOURCESDIRECTORY -Pattern $pathToSources

    foreach($file in $compileFiles)
    {
        Write-Output "Compiling MQL5 files: $file"

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
            Write-Output "Compilation log $([System.IO.Path]::GetFileName($logFile)):"
            Write-Output "====================================================================="
            Write-Output (Get-Content $logFile -Raw)
        }
        else 
        {
            Write-Output "No log created during compilation."
        }
        
        #1 - when successful, 0 when fails
        if($exitCode -ne 1)
        {
            Write-VstsTaskError -Message "Compilation failed (exit code $exitCode)"
            Write-VstsSetResult -Result 'Failed' -Message "Compilation failed"
        }
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}