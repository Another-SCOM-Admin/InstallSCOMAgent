# InstallSCOMAgent
SCOM Agent Install PowerShell Script

View this readme in RAW so the folder structure makes sense.

Run script with 1 of 3 parameters along with your Management Group and Management Server.  Parameters are -uninstall, -install2016, -install2019, -MYMG, -MYMS.
Example:
.\InstalLSCOMAgent -install2019 -MYMG OMMG01 -MYMS OM19MS01.domain.com
.\InstallSCOMAgent -uninstall

This script will also upgrade any 2012 or 2016 agent to the next version.  It will not downgrade clients.

Copy the script to a folder along with the MOMAgent.msi for 2019.  Inside that folder create two folders named "2012Agent" and "2016Agent".
Inside those subfolders copy the MOMAgent.msi for the respective agent version.
You can also copy an MSP (update rollup) for the agent into the folder and the script will install that automatically.

2019 files should go in the same folder as the script, as well as the MSP for 2019 agent if available.
You must have the momagent.msi in the correct folder to uninstall an agent.

So your folder structure should look similar to this:

<Root folder>
InstallSCOMAgent.ps1
MOMAgent.msi
<2012Agent>
        MOMAgent.msi
<2016Agent>
        KB4492182-AMD64-Agent.msp
        MOMAgent.msi

If you don't ever plan on installing a specific version, then there is no need to copy the MSI files.
