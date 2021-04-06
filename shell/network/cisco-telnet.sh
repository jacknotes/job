#!/usr/bin/expect -f
set ip [lindex $argv 0 ]
set filename [lindex $argv 1 ]
set date [lindex $argv 2 ]
set timeout 10

spawn telnet $ip
expect "Password*" 
send "pass\n"
expect "SWI_CORE*>"
send "enable\n" 
expect "Password*" 
send "pass\n"
expect "SWI_CORE*#" 
send "copy running-config tftp:\n"
expect "*Address or name of remote host*" 
send "192.18.3.26\n"
expect "*Destination filename*" 
send "$filename-$date\n"
expect "SWI_CORE*#" 
send "exit\n"
expect eof

