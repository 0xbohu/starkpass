# Starkpass Cairo Contract

`contracts > token > ERC721 > ERC721Starkpass.cairo`

# String test

`contracts > token > ERC721 > string_test.cairo`

test "string" felt split > base64 > concatenate > convert to felt array > return as view

example input: StarkPassNFT

```
python
>>> import utils
>>> utils.str_to_felt('StarkPassNFT')
25827951390457388155576141396
```

The felt for this string is `25827951390457388155576141396`, and character count is `12`. Pass these two parameters into view function base64_string.

Result:

```
arr: [U, 3, R, h, c, m, t, Q, Y, X, N, z, T, k, Z, U]
```

Base64 encode result is `U3RhcmtQYXNzTkZU` after decode is "StarkPassNFT"

try on voyager

https://goerli.voyager.online/contract/0x0203505221c4bb20cf5670c294e3a111e4316956ea675330ee1327d43c552d86#readContract
