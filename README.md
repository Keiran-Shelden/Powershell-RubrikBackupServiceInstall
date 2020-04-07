# Powershell-RubrikBackupServiceInstall

This script is to install the Rubrik Backup Service locally and connect it to the Rubrik Cluster for management. 

Example to run:  Set your running directory to where you've copied the .ps1 and environment folder to keep it simple. 

## Running the Script

```.\RBS_WinHost_Install_Config.ps1 -EnvironmentFile .\Environment\Environment.json -OutFile .\RBS.zip``` 

## Environment.json

This is where you set your Rubrik cluster IP. Rubrik credential file will be created during deployment, you will be asked to supply your Rubrik credentials which are stored in a secure xml. 

```
{
    "rubrikServer": "192.168.1.249",
    "rubrikCred": ".\rubrikCred.xml"
}
```



*If Rubrik module is not installed, it will be installed as part of this script.* 




### Credit to: 
- [Andy Draper](https://github.com/Draper1) for "Volume Filter Driver" Installation API
- [vBrownBag API Zero to Hero Series with Chris Wahl and Rebecca Fitzhugh](https://vbrownbag.com/vbrownbag-technology-series/api-zero-to-hero/)
- [Rubrik Build Community](https://build.rubrik.com/)
- [Rubrik Github](https://github.com/rubrikinc)

(c) Keiran Shelden 2019
