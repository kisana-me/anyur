# ANYUR
```sh
EDITOR="nano" rails credentials:edit
```

```credentials
smtp:
  user_name: your_name...
  password: zxcvbnm...

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: qwertyuiop...
```