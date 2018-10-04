$AIPclientURL = "https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AZInfoProtection_MSI_for_central_deployment.msi"
$AIPhash = "FB78C8760CE60A197CB9E11ADCC920F1B773D6DEAD12AA8107D9E0C93145361EF69B5AACF46A63782D23D31C4B3EDBF9"
$AIPOutputPath = [environment]::getfolderpath("desktop") + "\AZInfoProtection_MSI_for_central_deployment.msi"

Function Check-FileHash {
[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$true)]
        [string]$FileHash
    )
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA384
    return $hash

}

Function Install-AIPclient {
[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$MSIpath
    )

    
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = "AIPClient-Install-$DataStamp.log"
    $MSIArguments = @(
        "/i"
        $MSIpath
        "/qb"
        "/norestart"
        "/L*v"
        $logFile
     )
     Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow

}

Function Download-File {
[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$DownloadURL,
        [Parameter(Mandatory=$true)]
        [string]$DownloadPath
    )
            
    Invoke-WebRequest -Uri $DownloadURL -OutFile $DownloadPath
    
}

Function Validate-FileDownload {
[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$true)]
        [string]$FileHash,
        [Parameter(Mandatory=$true)]
        [string]$FileURL
    )

    # Check if we already have the AIP MSI.
    if (Test-Path $FilePath) {

        write-verbose "Existing File found. Checking hash."

        $File = Check-FileHash -FilePath $FilePath -FileHash $FileHash
        If ( $File.hash -eq $FileHash) {

            Write-Verbose "File hash match confirmed."    

        } else {

            Write-Verbose "File hash didn't match. Downloading again."
            Download-File -DownloadURL $FileURL -DownloadPath $FilePath

            $File = Check-FileHash -FilePath $FilePath -FileHash $FileHash
            If ( $File.hash -eq $FileHash) {


                Write-Verbose "File hash match confirmed."    

            } else {

                write-verbose "Something went wrong. Please restart."
                break
            }
        }

    } else {

        write-verbose "No existing File. Downloading .."
        Download-File -DownloadURL $FileURL -DownloadPath $FilePath
    
        $File = Check-FileHash -FilePath $FilePath -FileHash $FileHash
        If ( $File.hash -eq $FileHash) {


            Write-Verbose "File hash match confirmed."    

        } else {

            write-verbose "Something went wrong. Please restart."
        }
    }

}

## Main ##

Validate-FileDownload -FilePath $AIPOutputPath -FileHash $AIPhash -FileURL $AIPclientURL

write-host -nonewline "Continue on to install AIP client? (Y/N)"
$Continueresponse = read-host
If ( $Continueresponse -ne "y" ) { break }

Install-AIPclient -MSIpath $AIPOutputPath

Update-AIPScanner
Restart-Service AIPScanner