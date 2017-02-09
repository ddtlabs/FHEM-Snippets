##JSON To Readings##

###Expand a JSON String into individual readings###

Eg. If you want to expand a reading that contains a JSON String into individual readings, you can use a notify to call j2r function.

Genrel usage: <code>define n notify device:reading:.* { j2r($NAME,$EVENT) }</code>

Eg. your FHEM device is named 'SONOFF' and the reading that contains the JSON string is named 'state'

<code>define n_j2r notify SONOFF:state:.* { j2r($NAME,$EVENT) }</code>
