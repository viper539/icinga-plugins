 ##############################################################################
#
# NAME: ﻿  Check_Backup_Exec_2012.ps1
#
# AUTHOR: ﻿  Matthew Kohn, Mark Del Vecchio
# EMAIL: ﻿  it@hmcap.com﻿  
#
# COMMENT:  Checks the number of errors in BackupExec 2012
#
# Modified by viper539
# added Perfdata and different messages for ok, warning and critical
#
# GNU GPL v3
#
#﻿  ﻿  ﻿  Return Values for NRPE:
#﻿  ﻿  ﻿  return ok if 0 - OK (0)
#﻿  ﻿  ﻿  If less than the warning max - WARNING (1)
#﻿  ﻿  ﻿  if great than WarningMax - CRITICAL (2)
#﻿  ﻿  ﻿  Script errors - UNKNOWN (3)
#
#
##############################################################################

#Quantity of errors before
$WarningMax = 5

# Standard Nagios error codes
$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3


import-module "\program files\symantec\backup exec\modules\bemcli\bemcli"

$countCritical =  @(get-bealert -severity error).count
$countWarning =  @(get-bealert -severity warning).count
$countInfo =  @(get-bealert -severity information).count

if ($countWarning -eq 0) {
﻿  Write-Host "OK - No errors in BackupExec: $countInfo|Info=$countInfo Warning=$countWarning Error=$countCritical"
﻿  exit $returnStateOK
}

elseif ($countWarning -gt 0) {
﻿  Write-Host "Warning - Number of Errors: $countWarning Number of Infos: $countInfo|Info=$countInfo Warning=$countWarning Error=$countCritical"
﻿  exit $returnStateWarning
}

elseif ($countCritical -gt 0) {
﻿  Write-Host "Error - Number of Errors: $countCritical Number of Errors: $countWarning Number of Infos: $countInfo|Info=$countInfo Warning=$countWarning Error=$countCritical"
﻿  exit $returnStateCritical
}
else{
﻿  Write-Host "Unknown: There is a problem getting the number of errors"
﻿  exit $returnStateUnknown
}

Write-Host "UNKNOWN script state"
exit $returnStateUnknown
