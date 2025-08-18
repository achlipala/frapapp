# Formal Reasoning About Programs course web app

This is the software running [a course at MIT](https://frap.csail.mit.edu/), based on [the Ur/Web language](http://www.impredicative.com/ur/) and [the UPO library](http://upo.csail.mit.edu/) (with [MIT extensions](https://github.com/achlipala/upo_mit)).  The primary author is [Adam Chlipala](http://adam.chlipala.net/).


## Instructions to connect the application to Apache via FastCGI

* To install the FastCGI Apache module in Debian-flavored Linux (need to enable `multiverse` in Ubuntu):
```
sudo apt-get install libapache2-mod-fastcgi
```

* In the `default-ssl` config, set up a FastCGI server, substituting paths as appropriate:
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
