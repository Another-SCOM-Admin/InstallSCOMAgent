Param (
[Switch]$uninstall,
[Switch]$install2016,
[Switch]$install2019
)

$scriptpath = split-path -parent $MyInvocation.MyCommand.Definition

####Custom names####
$MYMG="OM19MG"
$MYMS="OM19MS01"
####################

####setup logging####
function timing{
$a=(get-date).month
$b=(get-date).day
$c=(get-date).year
$d=(get-date).hour
$e=(get-date).minute
$f=(get-date).second
"$a-$b-$c ${d}:${e}:${f}"}

if(gi $env:windir\temp\InstallSCOMAgent.log -ErrorAction SilentlyContinue)
{write-host "log exists, continuing..."}
else
{write-host "log does not exist, creating..."
new-item $env:windir\temp\InstallSCOMAgent.log -type file |Out-Null}

Function logit{
Param
(
    [Parameter(Mandatory=$true)]
    [string]$logit
)
"$logit $(timing)“ | out-file $env:windir\temp\InstallSCOMAgent.log -append
}
#####################

function FindAgent
{
    [bool](Get-Service | where name -eq "HealthService")
}

function CheckPreReqs
{
    if (test-path 'HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\ServerVersion')
    {
        write-host "Found OM Server component, quitting"
        logit "Found OM server component, quitting"
        exit 99
    }
    else
    {
        write-host "No OM Server component found, continuing...“
    }
    if (test-path 'HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.6\Setup\UIVersion')
    {
        write-host "Found OM console, quitting"
        logit "Found OM console, quitting"
        exit 99
    }
    else
    {
        write-host "No OM console found, continuing..."
    }
    if (test-path 'HKLM\SOFTWARE\Microsoft\System Center\2010\5ervice Manager\Setup\ServerVersion')
    {
        write-host "Found Service Manager component, quitting"
        logit "Found Service Manager component, quitting."
        exit 99
    }
    else
    {
        write-host "Service Manager not found, continuing..."
    }
}

function GetAgentVersion
{
    if (FindAgent)
    {
        $healthkey ="Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\HealthService"
        $healthvalue = "imagepath"
        $agentpath=Get-ItemProperty -Path $healthkey -Name $healthvalue
        $agentpath2=$agentpath.ImagePath -replace "`"","" -replace "healthservice.exe","momscriptapi.dll"
        $agentver=get-item $agentpath2
        $agentverinfo=$agentver.Versioninfo
        $version=$agentverinfo.FileVersion
        if ($version -like '7.*')
        {
            "2012"
        }
        elseif ($version -like '8.*')
        {
            "2016"
        }
        elseif ($version -like '10.*')
        {
            "2019"
        }
        else
        {
            write-host "Agent version unexpected, quitting"
            logit "Agent version unexpected, quitting"
            exit 404
        }
    }
    else
    {
        write-host "Agent not found, quitting"
        logit "Agent not found, quitting"
        exit 404
    }
}

function UninstallAgent
{
    $agentversion=GetAgentVersion
    if ($agentversion -eq "2012")
    {
        write-host “version match for 2012, uninstalling agent..."
        $p1='/qb'
        $p2='/l*'
        $args=“/x $scriptpath\2012agent\momagent.msi $p1 $p2 $env:windir\temp\ScomAgentUninstall.log"
        $result=(start-process msiexec.exe -ArgumentList $args -wait -Passthru).ExitCode
        if ($result -eq 0)
        {
            write-host “Uninstall completed" -ForegroundColor Green
            logit "2012 agent uninstall completed"
        }
        else
        {
            write-host "2012 agent uninstall failed, quitting"
            logit "2012 agent uninstall failed"
            exit 88
        }
    }
    elseif ($agentversion -eq "2019")
    {
        write-host "version match for 2019, uninstalling agent..."
        $p1=‘/qb'
        $p2='/l*'
        $args="/x $scriptpath\momagent.msi $p1 $p2 $env:windir\temp\ScomAgentUninstall.log"
        $result=(start-process msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
        if ($result -eq 0)
        {
            write-host "2019 uninstall completed" -ForegroundColor Green
            logit "2019 uninstall completed"
        }
        else
        {
            write-host "2019 agent uninstall failed, quitting"
            logit "2019 agent uninstall failed"
            exit 88
        }
    }
        elseif ($agentversion -eq "2016")
    {
        write-host "version match for 2016, uninstalling agent..."
        logit "version match for 2016, uninstalling agent..."
        $p1=‘/qb'
        $p2='/l*'
        $args="/x $scriptpath\2016agent\momagent.msi $p1 $p2 $env:windir\temp\ScomAgentUninstall.log"
        $result=(start-process msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
        if ($result -eq 0)
        {
            write-host "2016 Uninstall completed" -ForegroundColor Green
            logit "2016 uninstall completed"
        }
        else
        {
            write-host "2016 uninstall failed, quitting"
            logit "2016 uninstall failed"
            exit 88
        }
    }
    else
    {
        write-host "couldn't match an expected version for the uninstall"
        logit "Couldn't match an expected version for the uninstall"
        exit 404
    }
}

function Install2012Agent
{
    $p1='/qn'
    $p2='/l*'
    $args="/i $scriptPath\2012agent\momagent.msi $p1 $p2 $env:windir\temp\Scom2012AgentInstall.log USE_SETTINGS_FROM_AD=0 NOAPM=1 MANAGEMENT_GROUP=$MYMG MANAGEMENT_SERVER_DNS=$MYMS USE_MANUALLY_SPECIFIED_SETTINGS=1 AcceptEndUserLicenseAgreement=1"
    $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
    if ($result -eq 0)
    {
        write-host "2012 Install succeeded" -ForegroundColor Green
        logit "2012 install succeeded"
    }
    else
    {
        write-host "2012 Install failed, quitting"
        logit "2012 Install failed, quitting"
        exit 992012
    }
}

function Install2019Agent
{
    $p1='/qn'
    $p2='/l*'
    $args="/i $scriptpath\momagent.msi $p1 $p2 $env:windir\temp\Scom2019AgentInstall.log USE_SETTINGS_FROM_AD=0 NOAPM=1 MANAGEMENT_GROUP=$MYMG MANAGEMENT_SERVER_DNS=$MYMS USE_MANUALLY_SPECIFIED_SETTINGS=1 AcceptEndUserLicenseAgreement=1“
    $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
    if ($result -eq 0)
    {
        write-host “2019 Install succeeded, need to install UR if one exists” -ForegroundColor Green
        logit "2019 Install succeeded, need to install UR if one exists"
        Install2019UR
    }
    else
    {
        write-host “2019 Install failed, quitting"
        logit "2019 Install failed, quitting"
        exit 992019
    }
}

function Install2016Agent
{
    $p1='/qn'
    $p2='/l*'
    $args="/i $scriptpath\2016agent\momagent.msi $p1 $p2 $env:windir\temp\Scom2016AgentInstall.log USE_SETTINGS_FROM_AD=0 NOAPM=1 MANAGEMENT_GROUP=$MYMG MANAGEMENT_SERVER_DNS=$MYMS USE_MANUALLY_SPECIFIED_SETTINGS=1 AcceptEndUserLicenseAgreement=1“
    $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
    if ($result -eq 0)
    {
        write-host “2016 Install succeeded, need to install UR if one exists” -ForegroundColor Green
        logit “2016 Install succeeded, need to install UR if one exists”
        Install2016UR
    }
    else
    {
        write-host “2016 Install failed, quitting"
        logit "2016 Install failed, quitting"
        exit 992016
    }
}

function Upgrade2016Agent
{
    $p1='/qn'
    $p2='/l*'
    $args="/i $scriptpath\momagent.msi $p1 $p2 $env:windir\temp\Scom2016AgentUpgrade.log AcceptEndUserLicenseAgreement=1“
    $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
    if ($result -eq 0)
    {
        write-host “Upgrade to 2019 succeeded” -ForegroundColor Green
        logit "Upgrade to 2019 succeeded"
    }
    else
    {
        write-host “Upgrade to 2019 failed, quitting"
        logit "Upgrade to 2019 failed, quitting"
        exit 9920192
    }
}

function Upgrade2012Agent
{
    $p1='/qn'
    $p2='/l*'
    $args="/i $scriptpath\2016agent\momagent.msi $p1 $p2 $env:windir\temp\Scom2012AgentUpgrade.log AcceptEndUserLicenseAgreement=1“
    $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
    if ($result -eq 0)
    {
        write-host “Upgrade to 2016 succeeded” -ForegroundColor Green
        logit "Upgrade to 2016 succeeded"
    }
    else
    {
        write-host “Upgrade to 2016 failed, quitting"
        logit "Upgrade to 2016 failed, quitting"
        exit 9920162
    }
}

function Install2016UR
{
    logit "Checking for UR"
    foreach ($_ in gci $scriptpath\2016agent)
    {
        if ($_ -like "*.msp")
        {
            write-host "Msp found: capturing filename of $_"
            $MSP="$_"
        }
        else
        {
            write-host "no MSP found, skipping file"
        }
    }
    if ($MSP)
    {
        $p1='/qn'
        $p2='/l*'
        $args="/p $scriptpath\2016agent\$MSP $p1 $p2 $env:windir\temp\$MSP.log“
        $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
        if ($result -eq 0)
        {
            write-host “$MSP succeeded” -ForegroundColor Green
            logit "$MSP succeeded"
        }
        else
        {
            write-host “$MSP failed, quitting"
            logit "$MSP failed, quitting"
            exit 9920163
        }
    }
    else
    {
        write-host "No MSPs found, not installing any UR"
        logit "No MSPs found, not installing any UR"
    }
}

function Install2019UR
{
    logit "Checking for UR"
    foreach ($_ in gci $scriptpath)
    {
        if ($_ -like "*.msp")
        {
            write-host "Msp found: capturing filename of $_"
            $MSP="$_"
        }
        else
        {
            write-host "no MSP found, skipping file"
        }
    }
    if ($MSP)
    {
        $p1='/qn'
        $p2='/l*'
        $args="/p $scriptpath\$MSP $p1 $p2 $env:windir\temp\$MSP.log“
        $result=(start-process -FilePath msiexec.exe -ArgumentList $args -Wait -Passthru).ExitCode
        if ($result -eq 0)
        {
            write-host “$MSP succeeded” -ForegroundColor Green
            logit "$MSP succeeded"
        }
        else
        {
            write-host “$MSP failed, quitting"
            logit "$MSP failed, quitting"
            exit 9920193
        }
    }
    else
    {
        write-host "No MSPs found, not installing any UR"
        logit "No MSPs found, not installing any UR"
    }
}


##### MAIN SCRIPT ######

logit "Starting InstallSCOMAgent script"
logit "Checking prereqs"
CheckPreReqs
logit "Prereqs passed, continuing"

if ($install2019 -eq $true)
{
write-host "Install 2019 selected, installing 2019 agent"
logit "Install 2019 selected, installing 2019 agent"
    if (FindAgent)
    {
        logit "Agent found, checking version"
        $ver=GetAgentVersion
        if($ver -eq "2012")
        {
            logit "Found 2012 agent, uninstalling"
            UninstallAgent
            logit "Installing 2019 agent"
            Install2019Agent
        }
        elseif ($ver -eq "2016")
        {
            logit "Found 2016 agent, upgrading"
            Upgrade2016Agent
            Install2019UR
        }
        else
        {
            logit "No other version to work on, quitting"
            exit 404
        }
    }
    else
    {
        logit "No agent found, installing 2019 agent"
        Install2019Agent
    }
}
elseif ($install2016 -eq $true)
{
write-host "Install 2016 selected, installing 2016 agent"
logit "Install 2016 selected, installing 2016 agent"
    if (FindAgent)
    {
        logit "Agent found, checking version"
        $ver=GetAgentVersion
        if($ver -eq "2012")
        {
            logit "Found 2012 agent, upgrading"
            Upgrade2012Agent
            Install2016UR
        }
        elseif ($ver -eq "2019")
        {
            write-host "Found 2019 agent, not downgrading to 2016, quitting"
            logit "Found 2019 agent, not downgrading to 2016, quitting"
            exit 0
        }
        elseif ($ver -eq "2016")
        {
            write-host "Found 2016 agent, nothing to do"
            logit "Found 2019 agent, nothing to do"
            exit 0
        }
        else
        {
            logit "No other version to work on, quitting"
            write-host "No other verison to work on, quitting"
            exit 404
        }
    }
    else
    {
        logit "No agent found, installing 2016 agent"
        Install2016Agent
    }
}
elseif ($uninstall -eq $true)
{
    write-host "Uninstall selected, uninstalling the agent"
    logit "Uninstall selected, uninstalling the agent"
    UninstallAgent
}
else
{
    write-host "No parameter matched: please use -install2019, -install2016, or -uninstall. Doing nothing"
}
