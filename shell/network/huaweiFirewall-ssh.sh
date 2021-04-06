#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 10

spawn ssh c@$ip -p 8022
expect "Password:*" 
send "sx4CbV\n"
expect "<homsom-FW02>*" 
send "save\n"
expect "The current configuration*Are you sure to continue*"
send "y\n" 
expect "<homsom-FW02>*" 
send "tftp 192.1.3.6 put hda1:/vrpcfg.zip $filename-$date\n"
expect "<homsom-FW02>*" 
send "quit\n" 
expect eof

