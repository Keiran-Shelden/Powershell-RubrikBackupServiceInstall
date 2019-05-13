param(
    [Parameter(Mandatory=$false)]
    [string]$RubrikCluster,
    
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentFile,

    [Parameter(Mandatory=$true)]
    [string]$OutFile,

    [Parameter(Mandatory=$false)]
    [String]$SLA
)
Write-Host "Starting Script" -ForegroundColor Green 

#Import Module 
Write-Output "Importing Rubrik Module"
if (Get-Module -ListAvailable -Name Rubrik) {
    Import-Module Rubrik
} 
else {
    Write-Host "Module does not exist and will be installed" -ForegroundColor Red
    Install-Module Rubrik -Confirm:$false -Force
}

#Get Rubrik Credentials
Write-Output "Getting Rubrik Credentials"
$rubrikCred = Get-Credential

$rubrikCred.Password | ConvertFrom-SecureString | Out-File ".\Environment\rubrikcred.xml" -Force


#Collect Environment
$Script:Environment = Get-Content -Path $EnvironmentFile | ConvertFrom-Json

#Get IPv4 address for local machine 
Write-Output "Getting local IPv4"
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address

#Check Firewall Port for RBS and add if required
Write-output "Checking required Firewall ports.."
$check=Invoke-Command -ComputerName (hostname) -ScriptBlock {Get-NetFirewallProfile -Profile Domain | Select-Object -ExpandProperty Enabled} -ErrorAction Inquire
$enabled=$check | ? value -EQ "true"
$disabled=$check | ? value -EQ "false"
If ($enabled -ne $null) {
    Write-Host "Windows Firewall is enabled - RBS port 12800 and 12801 will be opened after installation" -ForegroundColor Red;
}    
if ($disabled -ne $null)  {
    Write-Host "Windows Firewall is disabled - Please ensure port 12801 is open between this computer and the Rubrik Cluster" -ForegroundColor Yellow;
}

#Rubrik Backup Service Install file 
Write-output "Retrieving Rubrik Backup Service Installation from Rubrik Cluster"
$url =  "https://$($Environment.rubrikServer)/connector/RubrikBackupService.zip"

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
if (Test-Path -Path $OutFile)
{
    Remove-Item -Path $OutFile -Force
}
Invoke-WebRequest -Uri $url -OutFile $OutFile

#Expand ZIP file and extract Rubrik files
Write-Output "Extracting Rubrik Backup Service MSI"
Expand-Archive -LiteralPath $OutFile -DestinationPath "C:\Temp\RubrikBackupService\" -Force

#Install Rubrik Backup Service
Write-Output "Installing Rubrik Backup Service"
Start-Process -FilePath "C:\Temp\RubrikBackupService\RubrikBackupService.msi" -ArgumentList "/quiet" -Wait 

#Restart service
Write-Output "Restarting Rubrik Backup Service.."
Get-Service -Name "Rubrik Backup Service" | Stop-Service 
Get-Service -Name "Rubrik Backup Service" | Start-Service

#Add Firewall rules
Write-Output "Setting required firewall ports"
If ($enabled -ne $null)
{New-NetFirewallRule -DisplayName "Rubrik Backup Service Port 12800" -Direction Inbound -LocalPort 12800 -Protocol TCP  -Action Allow | Out-Null
 New-NetFirewallRule -DisplayName "Rubrik Backup Service Port 12801" -Direction Inbound -LocalPort 12801 -Protocol TCP  -Action Allow | Out-Null
}    
if ($disabled -ne $null)  {Write-Host"";
Write-Host "Windows Firewall disabled prior to install - Bypassing, please confirm any other external firewalls" -ForegroundColor Red; Write-output ""$disabled""; Write-host""
}

#Rubrik API - Connect Rubrik Cluster to Host 
#Get Rubrik Credential
$null = Connect-Rubrik -Server $Environment.rubrikServer -Credential $rubrikCred

#Add new Host
$GetHost = Get-RubrikHost -Name $ipV4
if ($GetHost -eq $true) {
    Write-Host "Host already exists on Rubrik Cluster - Please confirm to remove" -ForegroundColor Yellow
    Get-RubrikHost -Name $ipV4 | Remove-RubrikHost -Confirm:$true
    New-RubrikHost -Name $ipV4 -Confirm:$false
}
else {
Write-Output "Adding Host to Rubrik Cluster"
New-RubrikHost -Name $ipV4 -Confirm:$false | Out-Null
}

#Install Voume Filter Driver - Courtesy of Andy Draper 
Write-Output "Installing Volume Filter Driver"
$myHost = Get-RubrikHost -Hostname $IPv4
$body = New-Object -TypeName PSObject -Property  @{"hostIds" = @($myHost.id); "install" = $true}
$apiResp = Invoke-RubrikRESTCall -Endpoint 'host/bulk/volume_filter_driver' -Method POST -Api internal -Body $body
Write-Host "Host VFD State for $($myHost.name): $($apiResp.hostVfdDriverState)" -ForegroundColor Yellow

#Clean up Files
Write-Output "Cleaning up install files"
Remove-Item -Path .\Environment\ -Recurse 
Remove-Item -Path $OutFile
Remove-Item .\RBS_Winhost_Install_Config.ps1

Write-Host "Script Complete" -ForegroundColor Green

Write-Host "Restart Computer?" -ForegroundColor Yellow
Restart-Computer -Confirm:$true