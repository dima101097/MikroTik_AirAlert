# =====================================================================
#  AirAlert monitor for MikroTik RouterOS v6 (6.43+)
#  API: https://wiki.ubilling.net.ua/doku.php?id=aerialalertsapi
#  Run from scheduler every 20-30s (API limit: max 2 req/s per host).
# =====================================================================

# ---------------------- SETTINGS -------------------------------------
# Region code (see list below)
:local region "kyiv"
# Script to run when air alert STARTS
:local scriptAlert "airalert-on"
# Script to run when air alert ENDS (all clear)
:local scriptClear "airalert-off"
# true = after reboot (flag is empty) run script for current state
:local runOnFirstCheck true
:local apiUrl "http://ubilling.net.ua/aerialalerts/"
# ---------------------------------------------------------------------

# Current state flag: "alert" / "clear" / "" (unknown, after reboot)
:global AirAlertState
# Time of last state change
:global AirAlertChanged

# Region codes:
#  sevastopol, vinnytska, volynska, dnipropetrovska, donetska,
#  zhytomyrska, zakarpatska, zaporizka, ivanofrankivska, kyivska,
#  kirovohradska, luhanska, lvivska, mykolaivska, odeska, poltavska,
#  rivnenska, sumska, ternopilska, kharkivska, khersonska, khmelnytska,
#  cherkaska, chernivetska, chernihivska, kyiv (m. Kyiv - city)
:local R [:toarray ""]
:set ($R->"sevastopol") "\\u0421\\u0435\\u0432\\u0430\\u0441\\u0442\\u043e\\u043f\\u043e\\u043b\\u044c"
:set ($R->"vinnytska") "\\u0412\\u0456\\u043d\\u043d\\u0438\\u0446\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"volynska") "\\u0412\\u043e\\u043b\\u0438\\u043d\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"dnipropetrovska") "\\u0414\\u043d\\u0456\\u043f\\u0440\\u043e\\u043f\\u0435\\u0442\\u0440\\u043e\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"donetska") "\\u0414\\u043e\\u043d\\u0435\\u0446\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"zhytomyrska") "\\u0416\\u0438\\u0442\\u043e\\u043c\\u0438\\u0440\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"zakarpatska") "\\u0417\\u0430\\u043a\\u0430\\u0440\\u043f\\u0430\\u0442\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"zaporizka") "\\u0417\\u0430\\u043f\\u043e\\u0440\\u0456\\u0437\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"ivanofrankivska") "\\u0406\\u0432\\u0430\\u043d\\u043e-\\u0424\\u0440\\u0430\\u043d\\u043a\\u0456\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"kyivska") "\\u041a\\u0438\\u0457\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"kirovohradska") "\\u041a\\u0456\\u0440\\u043e\\u0432\\u043e\\u0433\\u0440\\u0430\\u0434\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"luhanska") "\\u041b\\u0443\\u0433\\u0430\\u043d\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"lvivska") "\\u041b\\u044c\\u0432\\u0456\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"mykolaivska") "\\u041c\\u0438\\u043a\\u043e\\u043b\\u0430\\u0457\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"odeska") "\\u041e\\u0434\\u0435\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"poltavska") "\\u041f\\u043e\\u043b\\u0442\\u0430\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"rivnenska") "\\u0420\\u0456\\u0432\\u043d\\u0435\\u043d\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"sumska") "\\u0421\\u0443\\u043c\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"ternopilska") "\\u0422\\u0435\\u0440\\u043d\\u043e\\u043f\\u0456\\u043b\\u044c\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"kharkivska") "\\u0425\\u0430\\u0440\\u043a\\u0456\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"khersonska") "\\u0425\\u0435\\u0440\\u0441\\u043e\\u043d\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"khmelnytska") "\\u0425\\u043c\\u0435\\u043b\\u044c\\u043d\\u0438\\u0446\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"cherkaska") "\\u0427\\u0435\\u0440\\u043a\\u0430\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"chernivetska") "\\u0427\\u0435\\u0440\\u043d\\u0456\\u0432\\u0435\\u0446\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"chernihivska") "\\u0427\\u0435\\u0440\\u043d\\u0456\\u0433\\u0456\\u0432\\u0441\\u044c\\u043a\\u0430 \\u043e\\u0431\\u043b\\u0430\\u0441\\u0442\\u044c"
:set ($R->"kyiv") "\\u043c. \\u041a\\u0438\\u0457\\u0432"
:local key ($R->$region)

:if ([:len $key] = 0) do={
  :log error ("AirAlert: unknown region code '" . $region . "'")
} else={
  :local data ""
  :do {
    :local res [/tool fetch url=$apiUrl output=user as-value]
    :if (($res->"status") = "finished") do={ :set data ($res->"data") }
  } on-error={ :log warning "AirAlert: API request failed" }

  :local p [:find $data ("\"" . $key . "\":")]
  :if (([:len $data] = 0) || ([:typeof $p] = "nil")) do={
    :if ([:len $data] > 0) do={ :log warning ("AirAlert: region '" . $region . "' not found in API response") }
  } else={
    :local a [:find $data "\"alertnow\":" $p]
    :local val [:pick $data ($a + 11) ($a + 15)]
    :local newState "clear"
    :if ($val = "true") do={ :set newState "alert" }

    :if ($newState != $AirAlertState) do={
      :local firstCheck ([:len $AirAlertState] = 0)
      :set AirAlertState $newState
      :set AirAlertChanged ([/system clock get date] . " " . [/system clock get time])
      :log info ("AirAlert: " . $region . " -> " . $newState)

      :if ((!$firstCheck) || $runOnFirstCheck) do={
        :local runName $scriptClear
        :if ($newState = "alert") do={ :set runName $scriptAlert }
        :if ([:len [/system script find name=$runName]] > 0) do={
          :do { /system script run $runName } on-error={ :log error ("AirAlert: error in script " . $runName) }
        } else={
          :log error ("AirAlert: script '" . $runName . "' not found")
        }
      }
    }
  }
}
