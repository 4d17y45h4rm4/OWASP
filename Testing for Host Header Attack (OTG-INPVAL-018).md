Summary
--------

A web server commonly hosts several web application on the same IP address, referring to each application as a virtual host. In an incoming HTTP request, web servers often dispatch the request to the target virtual host of the value supplied in the Host Header. Without proper validation of the header value, the attacker can supply invalid input to cause the web server to dispatch requests to the first virtual host on the list, cause a 302 redirect to an attacker-controlled domain, perform web cache poisoning, or manipulate password reset functionality. 


How to Test
--------
Initial testing is as simple as supplying another domain (i.e. attacker.com) into the Host Header field. It is how the web server processes the header value that dictates the impact.

```
GET / HTTP/1.1
Host: www.attacker.com
Cache-Control: max-age=0
Connection: Keep-alive 
Accept-Encoding: gzip, deflate, br
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36
```

In the simplest case, this may cause a 302 redirect to the supplied domain.

```
HTTP/1.1 302 Found
...
Location: http://www.attacker.com/login.php

```

Alternatively, the web server may send the request to the first virtual host on the list.

### X-Forwarded Host Header Bypass

In the event that Host Header injection is mitigated by checking for invalid input supplied to the host header, you can supply the value to the `X-Forwarded-Host` header. 

```
GET / HTTP/1.1
Host: www.example.com
X-Forwarded-Host: www.attacker.com
...
```

Producing the following client-side output.

```
...
	<link src="http://www.attacker.com/link" />
...
```
Once again, this depends on how the web server processes the header value.

### Web Cache Poisoning

Using this technique, an attacker can manipulate a web-cache to serve poisoned content to anyone who requests it. This relies on the ability to poison the caching proxy run by the application itself, CDNs, or other downstream providers. This will cause the cache, with the victim having no control over receiving the malicious content on requesting the vulnerable application.

```
GET / HTTP/1.1
Host: www.attacker.com
...
```
The following will be served from the web cache, when a victim visits the vulnerable application.

```
...
	<link src="http://www.attacker.com/link" />
...
```

### Password Reset Poisoning

It is common for password reset functionality to include the Host Header value when creating password reset links that use a generated secret token. If the application processes an attacker-controlled domain to create a password reset link, the victim may click on the link in the email and allow the attacker to obtain the reset token. and reset the victim's password. 

```
... Email snippet ... 

1) Click on the following link to reset your password:

	http://www.attacker.com/index.php?module=Login&action=resetPassword&token=<SECRET_TOKEN>

... Email snippet ... 
```

References
------------
* [What is a Host Header Attack?](https://www.acunetix.com/blog/articles/automated-detection-of-host-header-attacks/)
* [Host Header Attack](https://www.briskinfosec.com/blogs/blogsdetail/Host-Header-Attack)
