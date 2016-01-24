; 
; ##########################
; #                        #
; #  google translator     #
; #   by rud0lf/IRCnet     #
; #                        #
; ##########################
; #                        #
; # this script uses       #
; #  $json snippet         #
; # Written by Timi        #
; # http://timscripts.com/ #
; #                        #
; ##########################
; #
; # warning: script won't work with unicode codepoints greater than 0x7FF (2047)
; # (i was too lazy to code it :P)
; # 
; # - don't forget to modify "preflang" alias to return your native language (used for parts of speech)
; # - you can also modify "out" alias (used to display results)
; #
; # commands:  (alter those if you wish)
; #  
; # /trdir <direction> <text>  -  translates text in given direction (i.e. it-en or auto-en)
; # /trp <text>                -  translates text from polish to english
; # /tr <text>                 -  translates text from english to polish
; # /trc                       -  flushes (closes) pending query (for stalled connection)
; 
; ! modify the alias below (out) to suit your needs
; ! ie. -a -> -s              for status window instead of active one
; !    -a -> -at             for a optional timestamp
; !    $color(normal) - > 4  for a red color of output
alias -l out {
  echo $color(normal) -a * GTranslate: $1-
}

; ! modify it to return your prefered language (default is polish - pl)
; ! change to "en" for english "it" for italian etc.
; ! used for google query for part of speech names in your native language
alias -l preflang {
  return pl
}

alias trc {
  if ($sock(gtranslate)) {
    sockclose gtranslate
    out Flushed pending query
  } 
  else {
    out no query in progress 
  }
}

; translates word in given direction (i.e. /trdir en-it potato)
alias trdir {
  if ($0 < 2) {
    out error: no parameters
    halt
  }
  google-translate $1 $2-
}

; translates word from english to polish (change "en-pl" to direction you wish, including "auto")
;                                          (i.e. it-en, auto-jp)
alias tr {
  if (!$0) {
    out error: no parameters
    halt
  }
  google-translate en-pl $1-
}

; translates word from polish to english
alias trp {
  if (!$0) {
    out error: no parameters
    halt
  }
  google-translate pl-en $1-
}


; 1st param - direction (i.e. en-pl)
; 2nd and more - word(s) to translate
alias -l google-translate {
  if ($sock(gtranslate)) {
    out Query already running (use /tlc to close current query)
    halt
  }

  var %dir = $1
  var %word = $2-

  var %from = $gettok(%dir, 1, 45)
  var %to = $gettok(%dir, 2, 45)

  set %gtr.word %word
  set %gtr.from %from
  set %gtr.to %to

  sockopen gtranslate translate.google.com 80
}

on *:SOCKOPEN:gtranslate: {
  if ($sockerr > 0) {
    out error: connection failed
    return
  }

  var %text = %gtr.word
  var %from = %gtr.from
  var %to = %gtr.to

  var %token = $calcgttoken(%text)
  var %tk = %token $+ $chr(124) $+ %token
  var %q = $quasiutf8encode(%text)

  var %query = /translate_a/single?client=t&dt=bd&dt=t&ie=UTF-8&oe=UTF-8&otf=2&ssel=0&tsel=0&q= $+ %q $+ &sl= $+ %from $+ &tl= $+ %to $+ &tk= $+ %tk

  sockmark gtranslate initial

  ;  out query: %query

  sockwrite -tn gtranslate GET %query HTTP/1.1
  sockwrite -tn gtranslate Host: translate.google.com
  sockwrite -tn gtranslate User-Agent: Mozilla/5.0 (Windows NT 6.0; rv:43.0) Gecko/20100101 Firefox/43.0
  sockwrite -tn gtranslate Accept: application/json;
  sockwrite -tn gtranslate Accept-Language: [ [ $preflang ] $+ ] ,en;q=0.7,en;q=0.3
  ;  sockwrite -tn gtranslate Accept-Language: pl;q=0.7,en;q=0.3
  sockwrite -tn gtranslate Accept-Encoding:
  sockwrite -tn gtranslate Connection: Close
  sockwrite -t gtranslate $crlf
  sockwrite -t gtranslate $crlf
}

on *:SOCKCLOSE:gtranslate: {
  ; out connection closed
}

on *:SOCKREAD:gtranslate: {
  if ($sockerr > 0) {
    out error: data read failed
    return
  }
  var %out = $null
  var %foo = $null
  sockread -f %out
  if ($sock(gtranslate).mark == initial) {
    if (HTTP/1.* 200 OK !iswm %out) {
      out error: request failed
      sockclose gtranslate
      return
    } 
    sockmark gtranslate fetching
  }
  var %fillmein = $true
  var %output = $null
  while ($sockbr > 0) {
    sockread -f %foo
    if (%fillmein) {
      if (%foo = $null) {
        sockread -f %foo
        var %output = %foo
        var %fillmein = $false  
      } 
    }
  }

  ;  out raw output: %output
  out  $+ %gtr.word $+  -> $gtparse(%output)
}


; param - word
alias calcgttoken {
  var %in = $1-
  var %d = $null

  var %f = 1
  var %le = $len(%in)
  while (%f <= %le) {
    var %g = $asc($mid(%in,%f,1))

    if (%g < 128) {
      %d = %d %g
    }
    else {
      if (%g < 2048) {
        var %h = $int($calc(%g / 64))
        %d = %d $or(%h, 192)
      }
      else {
        var %h = $int($calc(%g / 4096))
        %d = %d $or(%h, 224)
        var %h = $int($calc(%g / 64))
        var %h = $and(%h, 63)
        %d = %d $or(%h, 128)
      }
      var %h = $and(%g,63)
      %d = %d $or(%h,128) 
    }

    inc %f
  }

  var %tok = %d
  var %c = 0
  var %le = $numtok(%tok, 32)
  var %i = 1

  while (%i <= %le) {
    var %t = $gettok(%tok, %i, 32)

    var %c = $calc(%c + %t)

    var %o = $neg2cpl(%c)
    var %d = $calc(%o * 1024)    
    var %d = $dooverflow(%d)

    %c = $calc(%c + %d)

    var %o = $neg2cpl(%c)
    var %o = $int($calc(%o / 64))

    var %co = $neg2cpl(%c)
    var %co = $xor(%co, %o)

    var %c = $dooverflow(%co)

    inc %i
  }

  var %o = $neg2cpl(%c)
  var %d = $calc(%o * 8)   
  var %d = $dooverflow(%d)

  %c = $calc(%c + %d)

  var %o = $neg2cpl(%c)
  var %o = $int($calc(%o / 2048))

  var %co = $neg2cpl(%c)
  var %co = $xor(%co, %o)

  var %c = $dooverflow(%co)

  var %o = $neg2cpl(%c)
  var %d = $calc(%o * 32768)   
  var %d = $dooverflow(%d)

  %c = $calc(%c + %d)

  %c = $neg2cpl(%c)
  %c = $calc(%c % 1000000)

  return %c
}

alias -l neg2cpl {
  var %in = $1-
  var %out = %in
  if (%in < 0) {
    if (%in < -2147483648) {
      var %in = $calc(%in + 4294967296)
      if (%in < 0) {
        echo 4 * neg2cpl (google translator): negative overflow error!
        return 0;       
      }
      var %in = $base(%in, 10, 16, 8)
      var %in = $mid(%in, -8)
      var %in = $base(%in, 16, 10)
      %out = %in
    }
    else {
      %in = $calc(%in + 2147483648)
      %out = $or(%in, 2147483648)
    }
  }
  return %out
}

alias -l dooverflow {
  var %in = $1-
  var %ba = $base(%in,10,16,8)
  var %an = $mid(%ba,-8)
  var %in = $base(%an,16,10)
  var %s = $and(%in, 2147483648)
  if (%s) {
    %in = $and(%in, 2147483647)
    %in = $calc(%in - 2147483648)
  }
  return %in 
}

; encodes ONLY US-ASCII and 0080 - 07FF codepoint range
alias -l quasiutf8encode {
  var %in = $1-
  var %out = $null
  var %le = $len(%in)
  var %i = 1

  while (%i <= %le) {
    var %char = $mid(%in, %i, 1)
    var %cp = $asc(%char)
    if (%char isin abcdefghijklmnopqrstuvwxyz) {
      var %out = %out $+ %char
    }
    elseif (%cp < 128) {
      var %out = %out $+ % $+ $base(%cp,10,16,2)
    }
    else {
      if (%cp > 2047) {
        echo 4 * quasiutfencode (google translate): no support for codepoint %cp (character %char $+ )!
        halt
      }

      var %bin = $base(%cp, 10, 2, 11)
      var %bo1 = 110 $+ $mid(%bin, 1, 5)
      var %bo2 = 10 $+ $mid(%bin, 6, 6)

      %out = %out $+ % $+ $base(%bo1, 2, 16, 2)
      %out = %out $+ % $+ $base(%bo2, 2, 16, 2)    
    }

    inc %i  
  }

  return %out 
}

alias -l gtparse {
  var %out = $null
  var %reply = $1-

  var %len = $json(%reply,0).count
  var %i = 0
  while (%i < %len) {
    %out = %out  $+ $json(%reply, 0, %i, 0) $+ 
    inc %i
  }

  var %len = $json(%reply,1).count
  var %i = 0
  if (%len > 0) %out = %out (
  var %lenless = $calc(%len - 1)
  while (%i < %len) {
    var %pofspeech =  $+ $json(%reply,1,%i,0) $+ 

    %out = %out $+ %pofspeech $+ : $+ $chr(160)  
    var %len2 = $json(%reply,1,%i,1).count
    var %j = 0
    var %add = $null
    while (%j < %len2) {
      %add = %add $+ , $+ $chr(160) $+ $json(%reply,1,%i,1,%j)
      inc %j 
    }
    %out = %out $+ $mid(%add, 3)

    if (%i < %lenless) %out = %out $+ ; $+ $chr(160)

    inc %i
  }
  if (%len > 0) %out = %out $+ )

  return $replace(%out, $chr(160), $chr(32)) 
}

/*
$json
	Written by Timi
	http://timscripts.com/

	JSON, JavaScript Object Notation, is a popular format by which data is read and written.
	Many sites and APIs, such as Google's AJAX APIs, use this format, as it easy to parse and
	is widely supported.

	This snippet can read any value from valid JSON. It uses the MSScriptControl.ScriptControl object
	to input the data where is can be parsed using JavaScript. Calls are made to this object to
	retrieve the needed value.

	This script identifier also has the ability to get JSON data from a http://siteaddress.com
	source. This can be done by specifying a URL beginning with http://. Files on your computer can 
	also be used. With URLs, the data will also be cached so multiple calls to the same data won't 
	require getting the data over again. The cache will be cleared every 5 mins, but it can be cleared 
	manually using /jsonclearcache. The URL will also be encoded automatically.

	Syntax:
		$json(<valid JSON, file, or URL>,name/index,name/index2,...,name/indexN)[.count]
		Note: When inputting JSON, it is recommended that a variable is used because JSON uses commas
		to separate values. Also, URLs must begin with http://

		/clearjsoncache
		Clears the JSON cache created when JSON is retrieved from URLs

	Examples:
		var %json = {"mydata":"myvalue","mynumbers":[1,2,3,5],"mystuff":{"otherdata":{"2":"4","6":"blah"}}}

		$json(%json,mydata) == myvalue
		$json(%json,mynumbers,2) == 3 ;the array is indexed from 0
		$json(%json,mystuff,otherdata,"6") == blah      ;if a name is a number, quotes must be used as to not confuse
									;it with an array.
		----------
		Google Web Search example at end.


*/

alias json {
  if ($isid) {
    ;name of the com interface declared so I don't have to type it over and over again :D
    var %c = jsonidentifier,%x = 2,%str,%p,%v

    ;if the interface hasnt been open and initialized, do it.
    if (!$com(%c)) {
      .comopen %c MSScriptControl.ScriptControl
      ;add two javascript functions for getting json from urls and files
      noop $com(%c,language,4,bstr,jscript) $com(%c,addcode,1,bstr,function httpjson(url) $({,0) y=new ActiveXObject("Microsoft.XMLHTTP");y.open("GET",encodeURI(url),false);y.send();return y.responseText; $(},0))
      noop $com(%c,addcode,1,bstr,function filejson (file) $({,0) x = new ActiveXObject("Scripting.FileSystemObject"); txt1 = x.OpenTextFile(file,1); txt2 = txt1.ReadAll(); txt1.Close(); return txt2; $(},0))
      ;add function to securely evaluate json
      noop $com(%c,addcode,1,bstr,function str2json (json) $({,0) return !(/[^,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]/.test(json.replace(/"(\\.|[^"\\])*"/g, ''))) && eval('(' + json + ')'); $(},0))
      ;add a cache for urls
      noop $com(%c,addcode,1,bstr,urlcache = {})
    }
    if (!$timer(jsonclearcache)) { .timerjsonclearcache -o 0 300 jsonclearcache }

    ;get the list of parameters
    while (%x <= $0) {
      %p = $($+($,%x),2)
      if (%p == $null) { noop }
      elseif (%p isnum || $qt($noqt(%p)) == %p) { %str = $+(%str,[,%p,]) }
      else { %str = $+(%str,[",%p,"]) }
      inc %x
    }
    if ($prop == count) { %str = %str $+ .length }

    ;check to see if source is file
    if ($isfile($1)) {
      if ($com(%c,eval,1,bstr,$+(str2json,$chr(40),filejson,$chr(40),$qt($replace($1,\,\\,;,\u003b)),$chr(41),$chr(41),%str))) { return $com(%c).result }
    }
    ;check to see if source is url
    elseif (http://* iswm $1) {
      ;if url is in cache, used cached data
      if ($com(%c,eval,1,bstr,$+(str2json,$chr(40),urlcache[,$replace($qt($1),;,\u003b),],$chr(41),%str))) { return $com(%c).result }
      ;otherwise, get data
      elseif ($com(%c,executestatement,1,bstr,$+(urlcache[,$replace($qt($1),;,\u003b),]) = $+(httpjson,$chr(40),$qt($1),$chr(41)))) {
        if ($com(%c,eval,1,bstr,$+(str2json,$chr(40),urlcache[,$replace($qt($1),;,\u003b),],$chr(41),%str))) { return $com(%c).result }
      }
    }
    ;get data from inputted json
    elseif ($com(%c,eval,1,bstr,$+(x=,$replace($1,;,\u003b),;,x,%str,;))) { return $com(%c).result }
  }
}
alias jsonclearcache { if ($com(jsonidentifier)) { noop $com(jsonidentifier,executestatement,1,bstr,urlcache = {}) } }
;-------------------;

;;;Basic Google Web Search Identifier;;;
;;;Only the first 8 results are retrieved;;;
;;;Syntax: $gws(<search params>,<result number>,<count|url|title|content>)
;;;Requires $json
alias gws {
  ;ensure a proper property (count, etc) is selected and result number is between 1 and 8
  if (!$istok(count url title content,$3,32) && $2 !isnum 1-8) { return }

  var %url = http://ajax.googleapis.com/ajax/services/search/web?q= $+ $1 $+ &v=1.0&safe=active&rsz=large

  ;check to see if results were found
  ;since results often come back with bolds, remove them
  if ($json(%url,responseData,results,0)) { return $iif($3 == count,$json(%url,responseData,cursor,estimatedResultCount).http,$remove($json(%url,responseData,results,$calc($2 - 1),$3).http,<b>,</b>)) }
}
