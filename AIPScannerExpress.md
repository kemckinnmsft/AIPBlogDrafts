# Azure Information Protection Scanner Express Installation

Installing the Azure Information Protection scanner is not terribly difficult as long as you follow the instructions explicitly and don't miss anything.  This is sometimes a challenge as there are a lot of steps involved with registering the Azure AD Applications and delegating rights.  To make this process a bit quicker, we have developed a scripted method that will allow you to fully install scanner in less than 10 minutes (assuming all prerequisites are in place).

>**WARNING: Although we have performed this installation many times in lab environments, this is not currently a supported method for installing scanner, so use at your own risk.**

## Scanner Prerequisites

The prerequisites below are still required for successful AIP scanner installation.

- A Windows Server 2012 R2 or 2016 Server to run the service
    - Minimum 4 CPU and 4GB RAM physical or virtual 
        >NOTE: **TL;DR: More RAM is better**.
        >
        >The scanner will allocate RAM 2.5-3 times of size of all files being scanned in parallel.  Thus, if you scan 40 files that are 20MB each at the same time, it should take about 20*2.5*40=2GB RAM. However, if you have one big 1GB file it can take 3GB of RAM just for that file.  
- Internet connectivity necessary for Azure Information Protection
- A SQL Server 2012+ local or remote instance (Any version from Express or better is supported)
    - Sysadmin role needed to install scanner service (user running Install-AIPScanner, not the service account)
        >NOTE: If using SQL Server Express, the SQL Instance name is ServerName\SQLExpress
- Service account created in On Premises AD (I will call this account AIPScanner in this document).
    - Service requires **Log on locally** right and **Log on as a service** right (the second will be given during scanner service install).
    - Service account requires **Read permissions** to each repository for **discovery** and **Read/Write permissions** for **classification/protection**.
- **AzInfoProtection.exe** available on the Microsoft Download Center (The scanner bits are included with the AIP Client)
- Azure AD Preview PowerShell module 
    ```PowerShell
    Install-Module AzureADPreview
    ```

## Scanner Installation

Now that we have verified that all prerequisites are in place, we can go through the basic scanner install.

1. Log onto the server where you will install the AIP Scanner service using an account that is a l**ocal administrator** of the server and has **permission to write to the SQL Server master database**. (more restrictive scenarios are documented in the official documentation)
2. Run **AzInfoProtection.exe** on the server and step through the client install (this also drops the AIP Scanner bits)
3. Next, open an **Administrative PowerShell** prompt.
4. At the PowerShell prompt, type the following command and press Enter:
    ```PowerShell
    Install-AIPScanner
    ```
5. When prompted, provide the **credentials for the on premises scanner service account** (YourDomain\AIPScanner) and password.
6. When prompted for **SqlServerInstance**, enter the name of your SQL Server and press Enter.
    >NOTE: If you get any errors at this point, verify network connectivity and resolve any permissions issues with the SQL Database before proceeding!

## Create Cloud Service Account

First, we will create a service account in the cloud tenant to use for AIP authentication.  If you have synced your on premises service account, you can skip this task.

1. Run the command below to connect to Azure AD.
    ```PowerShell
    Connect-AzureAD
    ````
1. When prompted, provide tenant Global Admin credentials.
1. To create an account in the cloud, you must first define a password profile object.  Run the commands below to define this object.
   
   ```PowerShell
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.EnforceChangePasswordPolicy = $false
    $Password = Read-Host -assecurestring "Please enter password for cloud service account"
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    $PasswordProfile.Password = $Password
   ```
1. When prompted, enter a password for the cloud service account.
1. To create the account, run the commands below.
   
   ```PowerShell
   $Tenant = Read-Host "Please enter tenant name for UserPrincipalName (e.g. contoso.com)"
   New-AzureADUser -AccountEnabled $True -DisplayName "AIP Scanner Cloud Service" -PasswordProfile $PasswordProfile -MailNickName "AIPScannerCloud" -UserPrincipalName "AIPScannerCloud@" + $Tenant
   ```
1. When prompted, enter the tenant name you want to use for the UserPrincipleName for the clous service account (e.g. contoso.com).

## Creating Azure AD Applications

In this task, we will configure the App Registrations for the Web App and Native App required to create the Set-AIPAuthentication command.  We will also assign the necessary Oauth2Permissions for the Web App to have delegated rights to the Native App.

1. Run the commands below to create the Web App, associated Service Principle, and key password.
   
   ```PowerShell
    New-AzureADApplication -DisplayName AIPOnBehalfOf -ReplyUrls http://localhost
    $WebApp = Get-AzureADApplication -Filter "DisplayName eq 'AIPOnBehalfOf'"
    New-AzureADServicePrincipal -AppId $WebApp.AppId
    $WebAppKey = New-Guid
    $Date = Get-Date
    New-AzureADApplicationPasswordCredential -ObjectId $WebApp.ObjectID -startDate $Date -endDate $Date.AddYears(1) -Value $WebAppKey.Guid -CustomKeyIdentifier "AIPClient"
    ```

2. Next, we need to run some commands to build the RequiredResourceAccess object that is needed to automate delegation of permissions for the native application. 
    
    ```PowerShell
    $AIPServicePrincipal = Get-AzureADServicePrincipal -All $true | ? {$_.DisplayName -eq 'AIPOnBehalfOf'}
    $AIPPermissions = $AIPServicePrincipal | select -expand Oauth2Permissions
    $Scope = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $AIPPermissions.Id,"Scope"
    $Access = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $Access.ResourceAppId = $WebApp.AppId
    $Access.ResourceAccess = $Scope
    ```

1. Now we can create the Native App and associated Service Principle using the commands below.
    
    ```PowerShell
    New-AzureADApplication -DisplayName AIPClient -ReplyURLs http://localhost -RequiredResourceAccess $Access -PublicClient $true
    $NativeApp = Get-AzureADApplication -Filter "DisplayName eq 'AIPClient'"
    New-AzureADServicePrincipal -AppId $NativeApp.AppId
    ```

1. At this point, we have everything we need to build the Set-AIPAuthentication command, but since we want to run this command in the context of the AIP Scanner account, we will output it to a text file and open it.
    ```PowerShell
    "Set-AIPAuthentication -WebAppID " + $WebApp.AppId + " -WebAppKey " + $WebAppKey.Guid + " -NativeAppID " + $NativeApp.AppId | Out-File ~\Desktop\Set-AIPAuthentication.txt
    Start ~\Desktop\Set-AIPAuthentication.txt
    ```

## Authenticating as the AIP Scanner Service

In this task, we will use the command created previously to authenticate the AIP Scanner to the AIP Service.

1. Open PowerShell using **Run as a different user** and use the **on premises Scanner Service account**.
1. Run the command in Set-AIPAuthentication.txt
    >NOTE: This command can be used on multiple servers to set up the scanner.  The Azure AD Applications only need to be configured once and you can save this command to create as many scanner instances as you require.
1. When prompted, enter the cloud service account information (AIPServiceCloud@>contoso>.com) and the password you defined.
1. Finally, in the Required permissions dialog, click Accept to acquire an authentication token.
1. The last step is to restart the scanner srevice so it can use the new token.
   
   ```PowerShell
   Restart-Service AIPScanner
   ```
   

## Scanner Configuration

Past this point, scanner configuration is the same as it is in the other articles.  I am including it here for convenience.

### Configuring Repositories

Repositories can be on-premises SharePoint 2010, 2013, or 2016 document libraries or lists and any accessible CIFS based share.  

> NOTE: In order to do discovery, the scanner service pulls the documents to the server, so having the scanner server located in the same LAN as your repositories is recommended. You can deploy as many servers as you like in your domain, so putting one at each major site is probably a good idea.

1. To add a file share repository, open a PowerShell window and run the command below
    
    ```PowerShell
    Add-AIPScannerRepository -Path \\fileserver\documents
    ```
2. To add a SharePoint 2013/2016 document library run the command below
    
    ```PowerShell
    Add-AIPScannerRepository -Path http://sharepoint/documents
    ```
3. To verify that the repositories that are configured, run the command below
    
    ```PowerShell
    Get-AIPScannerRepository
    ```

### Sensitive Data Discovery

One of the most useful features of the AIP Scanner is the discovery of sensitive data across all of your configured repositories.  You can do this by using Set-AIPScannerConfiguration with a switch called -DiscoverInformationTypes.  When this switch is set to All, the scanner will discover files that contain any data in the list of all Office 365 DLP sensitive data types so configuration of conditions in labels are not required.

>NOTE: Normally, custom data types based on string and regex values are also available, but these require AIP Premium P2 licensing.

 1. The PowerShell command below will allow you to scan your repositories against all information types.

    ```PowerShell
    Set-AIPScannerConfiguration -DiscoverInformationTypes All
    ```
 
1. To start the discovery, use the PowerShell command below

    ```PowerShell
    Start-AIPScan
    ```

 After running the scan, you can review the logs by opening the Event Viewer and clicking on

Application and Services Logs and then on Azure Information Protection.
you can view the detailed logs at C:\users\<Scanner Service Account Profile>\appdata\local\Microsoft\MSIP\Scanner\Reports.  There you will find the summary txt and detailed csv files.

Below is a screenshot showing the DetailedReport.csv file after a full discovery scan.

**INSERT SCREENSHOT**

As you can see, it shows the file name and all of the sensitive information types that were identified in each file.  This data can be reviewed manually, or more realistically, ingested into a SIEM for analysis and reporting.

### Protection Options

Although automated protection via the AIP scanner is more convenient, there are still options available with AIP P1 for classifying and/or protecting the sensitive data.  These options are 

- Manual Classification
    With Manual classification, a user must open each document containing sensitive information and classify it via the AIP toolbar.
- Manual or Bulk Classification via the AIP client Windows Explorer add-in
    Using the AIP client via the right-click context menu in Windows Explorer, you can classify and/or protect individual files or entire directories of files with a single label.
- Bulk Classification via the AIP PowerShell cmdlets
    Using the PowerShell cmdlets contained in the AzureInformationProtection PowerShell module (full details here) such as Set-AIPFileLabel, you can potentially script solutions for classifying and protecting the files that are identified to contain sensitive data in the DetailedReport.csv files produced by the AIP scanner.

You should now have a fully functional AIP Scanner instance.  You can repeat this process on multiple servers as necessary and use the same Set-AIPAuthentication command for each of them.  This is a simple setup for a basic AIP scanner server that can be used to discover a large amount of sensitive data easily.  I highly recommend reading the official documentation on deploying the scanner as there are some less common caveats that I have left out and they cover performance tips and other additional information.

Below is a full script you can use to automate everything we have covered in this post.  Again, this is not currently supported, so please test before deploying in a production environment.

```PowerShell
Install-Module AzureADPreview

Install-AIPScanner

Connect-AzureAD

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.EnforceChangePasswordPolicy = $false
$Password = Read-Host -assecurestring "Please enter password for cloud service account"
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$PasswordProfile.Password = $Password

$Tenant = Read-Host "Please enter tenant name for UserPrincipalName (e.g. contoso.com)"
New-AzureADUser -AccountEnabled $True -DisplayName "AIP Scanner Cloud Service" -PasswordProfile $PasswordProfile -MailNickName "AIPScannerCloud" -UserPrincipalName "AIPScannerCloud@" + $Tenant

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

### As On Premises Scanner Account

# Set-AIPAuthentication comand from Set-AIPAuthentication.txt

# Restart-Service AIPScanner

### Configure Repositories

# Set-AIPScannerConfiguration -DiscoverInformationTypes All
# Start-AIPScan
```

Thanks,

The Information Protection Customer Experience Team