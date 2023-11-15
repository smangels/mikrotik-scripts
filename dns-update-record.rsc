# ----- Gandi.net LiveDNS dynamic DNS multi domain and subdomain write by Massimo Ciani  ------
#
#
#
#--------------- Change Values in this section to match your setup ------------------

# Your LiveDNS API KEY
:local apikey "YourPatKey"

# Set the domain and subdomain to be updated.
# Replace the value in the quotations below with your domain and subdomain name.
# To specify multiple domain and subdomain, separate them with commas.
# IMPORTANT: Before to start the script, remember to create manually the records for all domain.
:local domain "domain.com"
:local subdomain "mikrotik,gw"

# Set the name of interface where get the internet public IP
:local inetinterface "wan"

# Gandi LiveDNS API address
:local apiAddress "https://dns.api.gandi.net/api/v5/domains"

#------------------------------------------------------------------------------------
# No more changes need

# get current IP
:global currentIP
:if ([/interface get $inetinterface value-name=running]) do={
    :global currentIPa [/ip address get [find interface="$inetinterface" disabled=no] address]
# cancel netmask from interface IP address
    :for i from=( [:len $currentIPa] - 1) to=0 do={
        :if ( [:pick $currentIPa $i] = "/") do={ 
            :set currentIP [:pick $currentIPa 0 $i]
       } 
   }
} else={
    :log info "LiveDNS: $inetinterface is not currently running, so therefore will not update."
    :error [:log info "bye"]
}

# Recursively resolve all subdomain and update on IP changes
:global domainarray
:set domainarray [:toarray $domain]
:foreach host in=$domainarray do={
    :global subarray
    :set subarray [:toarray $subdomain]
    :foreach sub in=$subarray do={
        :global previousIP [:resolve "$sub.$host"]
        :if ($currentIP != $previousIP) do={
            :log info "LiveDNS $sub.$host: Current IP $currentIP is not equal to previous IP, update needed"
            :log info "LiveDNS $sub.$host: Sending update"
            /tool fetch mode=https \
                http-method=put \
                http-header-field="Content-Type:application/json,X-Api-Key:$apikey" \
                http-data="{\"rrset_name\": \"$sub\",\"rrset_type\": \"A\",\"rrset_ttl\": 300,\"rrset_values\": [\"$currentIP\"]}" \
                url="$apiAddress/$host/records/$sub/A" \
                dst-path="" \
                output=none
            :log info "LiveDNS $sub.$host: updated on Gandi with IP $currentIP"
        } else={
            :log info "LiveDNS $sub.$host: Previous IP $previousIP is equal to current IP, no update needed"
        }
    }
}
