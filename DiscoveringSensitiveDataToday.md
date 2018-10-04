# Discovering Sensitive On Premises Data Today!

Defining a full Information Protection taxonomy can be a time-consuming and challenging task in a business environment. However, with the AIP Scanner, you can start identifying sensitive data that is sitting on your network in a single day.  Once you have an idea of the types of data you are wanting to classify and protect, this can help drive discussions about how your information protection taxonomy should develop.

## Prerequisites

At least one Server (Physical or Virtual) capable of running the AIP scanner
A SQL Server Instance to store configuration and scanned file list (Express is fine)
An install account with sysadmin rights to the SQL instance and local admin rights on the Server
An on premises user account to run the AIP scanner service (e.g. Contoso\AIPScanner)
Global Admin permissions for the tenant

## Installing the AIP Scanner

Once you have the prerequisites in place, installing the AIP Scanner is very quick (I have done it in under 5 minutes).  I have a full article on this [here](https://https://techcommunity.microsoft.com/t5/Azure-Information-Protection/Azure-Information-Protection-Scanner-Express-Installation/ba-p/265424) but in this post we will just use the full script.  Copy the PowerShell below into a new PowerShell ISE window.

This command will create a cloud account for the scanner to use for authentication and create the objects necessary for the Set-AIPAuthentication command.

```PowerShell
Install-Module AzureAD
Import-Module AzureAD

Connect-AzureAD

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.ForceChangePasswordNextLogin = $false
$Password = Read-Host -assecurestring "Please enter password for cloud service account"
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$PasswordProfile.Password = $Password

$Tenant = Read-Host "Please enter tenant name for UserPrincipalName (e.g. contoso.com)"
New-AzureADUser -AccountEnabled $True -DisplayName "AIP Scanner Cloud Service" -PasswordProfile $PasswordProfile -MailNickName "AIPScannerCloud" -UserPrincipalName "AIPScannerCloud@$Tenant"

New-AzureADApplication -DisplayName AIPOnBehalfOf -ReplyUrls http://localhost
$WebApp = Get-AzureADApplication -Filter "DisplayName eq 'AIPOnBehalfOf'"
New-AzureADServicePrincipal -AppId $WebApp.AppId
$WebAppKey = New-Guid
$Date = Get-Date
New-AzureADApplicationPasswordCredential -ObjectId $WebApp.ObjectID -startDate $Date -endDate $Date.AddYears(1) -Value $WebAppKey.Guid -CustomKeyIdentifier "AIPClient"

New-AzureADApplication -DisplayName AIPClient -ReplyURLs http://localhost -RequiredResourceAccess $Access -PublicClient $true
$NativeApp = Get-AzureADApplication -Filter "DisplayName eq 'AIPClient'"
New-AzureADServicePrincipal -AppId $NativeApp.AppId

"Set-AIPAuthentication -WebAppID " + $WebApp.AppId + " -WebAppKey " + $WebAppKey.Guid + " -NativeAppID " + $NativeApp.AppId | Out-File ~\Desktop\Set-AIPAuthentication.txt
Start ~\Desktop\Set-AIPAuthentication.txt

```

Next, we will download, verify, and install the AIP scanner binaries that are included with the AIP client.  The commands below will download the current GA (1.37.19.0) and install it on your server.  Follow the prompts in the script to perform these tasks. Finally, when prompted, enter the credentials for the AIP scanner service account (e.g. Contoso\AIPScanner). It will ask you for the SQL Server instance name (if using SQL Express remember to use ServerName\SQLExpress as the instance name). 

```PowerShell
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

Install-AIPScanner
```

Now that you have the AIP scanner installed, you can run the **Set-AIPAuthentication** command to get the auth token.  Open a PowerShell prompt **as the AIP scanner service account** and run the command from Set-AIPAuthentication.txt created earlier.

Finally, run the command below to initialize the service with the new token.

```PowerShell
Restart-Service AIPScanner
```

The scanner should be fully functional at this point and you can run the commands below to verify the state (should be idle) and see the default configuration.

```PowerShell
Get-AIPScannerStatus
Get-AIPScannerConfiguration
```

Next, you can configure the repositories you want to scan.  I recommend configuring these with the **-SetDefaultLabel** property set to **Off**.  That way, when/if you set a default label in your global policy, your scanner will not start to classify items inappropriately.

```PowerShell
Add-AIPScannerRepository -Path \\Fileserver\Documents -SetDefaultLabel Off
Add-AIPScannerRepository -Path https://SharePointServer/Documents -SetDefaultLabel Off
```

Next, we want to set the scanner configuration to discover data that contains any of the default sensitive information types and any custom ones you may define in the portal. I have also included the switch to disable enforcement even though this is the default. 

```PowerShell
Set-AIPScannerConfiguration -Enforce Off -DiscoverInformationTypes All
```

The last thing we need to do is actually run the scanner.  This can be done using the command below.

```PowerShell
# Before running this you may want to look at the Extra Credit section below. 
# This may save you from needing to rescan your repositories.

Start-AIPScan
```

At this point, you can wait for the scan to finish and review the logs at *C:\users\Scanner Service Account Profile\appdata\local\Microsoft\MSIP\Scanner\Reports*.  There you will find the summary txt and detailed csv files.

## Extra Credit

But wait, there's more! The AIP Log Analytics public preview went live in late September, so now instead of seeing the data in the log files on premises, you can see them in a fancy dashboard like the one below.  This takes a bit more configuration, but is a lot more fun.

**Insert Screenshot**

### Prerequisites for AIP Log Analytics

An Azure Subscription capable of creating an Azure Log Analytics workspace
The Preview AIP Client (1.38.7.0)

### Updating the AIP Scanner

Updating the AIP scanner is fairly easy and straight forward if you have already followed the instructions above for the GA install.  Run the script beliw to download, verify, install, and update the AIP scanner to the Preview client (1.38.7.0).

```PowerShell
$AIPclientURL = "https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AzInfoProtection_MSI_for_central_deployment__PREVIEW_1.38.7.0.msi"
$AIPhash = "08336CAE5A012D39F070F3EFB6CEA8FC5B0D096B3C627757E779950A9B58755951D49738A28595BBA256011138976A5F"
$AIPOutputPath = [environment]::getfolderpath("desktop") + "\AzInfoProtection_MSI_for_central_deployment__PREVIEW_1.38.7.0.msi"

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
```

### Configuring AIP Log Analytics

Lior from my team put out a full blog post about the Log Analytics and you can read more about it [here](https://techcommunity.microsoft.com/t5/Azure-Information-Protection/Data-discovery-reporting-and-analytics-for-all-your-data-with/ba-p/253854).