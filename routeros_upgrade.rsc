# CD into update command tree
/system/package/update

# ensure that we switch back to stable channel
set channel=stable

# check whether there is new release
# delay the subsequent command
check-for-updates once
:delay 3s;

# compare the status variable content
:if ( [get status] = "New version is available") do={ install }
