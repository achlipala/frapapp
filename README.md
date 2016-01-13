# Formal Reasoning About Programs course web app

This is the software running [a course at MIT](https://frap.csail.mit.edu/), based on [the Ur/Web language](http://www.impredicative.com/ur/) and [the UPO library](http://upo.csail.mit.edu/) (with [MIT extensions](https://github.com/achlipala/upo_mit)).  The primary author is [Adam Chlipala](http://adam.chlipala.net/).

## Notes on setting up MIT client-certificate authentication with Apache

* Go to an [IS&T certificates & Apache help page](http://kb.mit.edu/confluence/display/istcontrib/Check+MIT+Certificates+on+a+private+web+server) and grab the `mitCAclient.pem` file.

* Run:
```
sudo a2enmod ssl
sudo a2ensite default-ssl
```

* Add this line to `/etc/apache2/sites-available/default-ssl.conf`:
```
SSLCertificateFile /etc/ssl/certs/frap_csail_mit_edu_cert.cer
```

* Add this line, too (get the intermediate cert from CA):
```
SSLCertificateChainFile /etc/ssl/certs/frap_csail_mit_edu_interm.cer
```

* To require a CSAIL certificate for `/PATH`, use this in the same file:
```
<Location /PATH>
  SSLOptions +OptRenegotiate +StdEnvVars
  SSLRequireSSL
  SSLVerifyClient require
  SSLVerifyDepth 3
  SSLRequire %{SSL_CLIENT_S_DN_O} == "Massachusetts Institute of Technology"
</Location>
```

* To protect clients from recently discovered SSL vulnerabilities, add this configuration globally:
```
SSLProtocol All -SSLv2 -SSLv3
```

## Instructions to connect the application to Apache via FastCGI

* To install the FastCGI Apache module in Debian-flavored Linux (need to enable `multiverse` in Ubuntu):
```
sudo apt-get install libapache2-mod-fastcgi
```

* Apply the MIT-certificate recipe above to the path `/` of the `default-ssl` config.

* Again in the `default-ssl` config, set up a FastCGI server, substituting paths as appropriate:
```
ScriptAliasMatch ^/.*$ /home/adamc/git/frapapp/testing.exe
FastCgiServer /home/adamc/git/frapapp/testing.exe -idle-timeout 120
```

* If any funny business pops up about access control, add this to the same virtual host config:
```
<Location />
  Require all granted
</Location>
```

## A helpful command line to launch a dummy SMTP server for local testing

```
sudo python -m smtpd -n -c DebuggingServer localhost:25
```

## Info on keeping the server's clock up to date

Install package `ntp` and copy over `/etc/ntp.conf` from a CSAIL Ubuntu workstation.
