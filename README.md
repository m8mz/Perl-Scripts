# Perl Scripts

```
root:Perl-Scripts# perl cptheme.pl 
Updated cPanel theme for munix.
```

```
root@walsupport:~# gsuiteuser dot.test test@so*****.com
Next Available ACLID = 209331908
	{code}UPDATE GoogleApps SET Mailbox = test@so*****.com, Status = 'fulfilled' WHERE ACLID = '209331908' LIMIT 1;{code}
```

```
root@walsupport:~# gsuiteuser dot.test                         
ACLID      UserName             Mailbox                        Status         
194733789  dot.test          jordan@sou******.com      fulfilled      
194739247  dot.test          mike@sou******.com        fulfilled      
194739248  dot.test          franco@sou******.com      fulfilled      
197229550  dot.test          Not Available                  cancelled      
198071431  dot.test          miked@sou******.com       fulfilled      
200167552  dot.test          gerry@sou******.com       fulfilled      
200167555  dot.test          bookkeeper@sou******.com  fulfilled      
200427535  dot.test          kevin@sou******.com       fulfilled      
201157338  dot.test          Not Available                  cancelled      
201157339  dot.test          pabbatiello@sou******.com fulfilled      
209331650  dot.test          george@sou******.com      fulfilled      
209331908  dot.test          Available                      fulfillable
```

```
root@server.al******* [tmp]# perl clearexim.pl 
Shutting down exim:                                        [  OK  ]
Shutting down spamd:                                       [FAILED]
Killed exim processes.
Clearing Exim queue... this may take some time.
Deleted 1566390 file(s)
Starting exim:                                             [  OK  ]
Starting spamd: Gracefully terminating process: spamd-dorm with pid 2240 and owner root.
Waiting for 2240 to shutdown ....... terminated.
                                                           [  OK  ]
Exim cleared!
```

```
root:Perl-Scripts# perl traffic.pl 
MUNIX.TECH
	Top 10 IP Addresses:
	       2: 104.192.74.16                                     
	       1: 66.249.75.30                                      
	       1: 66.249.75.29                                      

	Num. of Request Types:
	       4: GET                                               

	Top 10 Resources:
	       2: /robots.txt                                       
	       2: /                                                 

	Top 10 Referrer:
	       2: -                                                 
	       1: http://www.munix.tech/robots.txt                  
	       1: http://www.munix.tech                             

	Top 10 UserAgents:
	       2: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko)
	       1: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)
	       1: Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)
```

```
root@server.al******* [public_html]# perl wpinfo.pl 
Database: jgintera_alanjack
Username: jgintera_alanjac    
Password: ********************   
Host: localhost
```

```
root@walsupport:working# wpurl
HOME   : http://working.wp********.com
SITEURL: http://working.wp********.com
```
