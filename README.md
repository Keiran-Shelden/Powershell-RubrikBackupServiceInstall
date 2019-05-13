# Powershell-RubrikBackupServiceInstall

This script is to install the Rubrik Backup Service locally and connect it to the Rubrik Cluster for management. 

Example to run:  Set your running directory to where you've copied the .ps1 and environment folder to keep it simple. 

## Running the Script

```.\RBS_Install_Config.ps1 -EnvironmentFile .\Environment\Environment.json -OutFile .\RBS.zip``` 

## Environment.json
```
{
    "rubrikServer": "192.168.1.249",
    "rubrikCred": ".\rubrikCred.xml"
}
```


*If Rubrik module is not installed, it will be installed as part of this script.* 




### Credit to: 
-Andy Draper for "Volume Filter Driver" Installation API
-[vBrownBag API Zero to Hero Series with Chris Wahl and Rebecca Fitzhugh](https://vbrownbag.com/vbrownbag-technology-series/api-zero-to-hero/)
-[Rubrik Build Community] (https://build.rubrik.com/)

(c) Keiran Shelden 2019
