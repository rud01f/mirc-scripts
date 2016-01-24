; 
; ##################################
; #                                #
; #  damerau-levenshtein distance  #
; #   by rud0lf/IRCnet             #
; #                                #
; ##################################
;
; #
; # - calculates damerau-levenshtein distance of two words
; # (minimal number of characters you have to replace, 
; #   insert,delete or swap to transform one word into another)
; #
; # - usage: distance = $damlev(word1, word2)
; #

alias damlev {
  var %a $1, %b $2
  var %al $len(%a)
  var %bl $len(%b)

  var %maxdist $calc(%al + %bl)

  var %d.-1.-1 %maxdist

  var %i 0
  while (%i <= %al) {
    var %d. [ $+ [ %i ] $+ .-1 ] %maxdist 
    var %d. [ $+ [ %i ] $+ .0 ] %i
    inc %i
  }

  var %j 0
  while (%j <= %bl) {
    var %d. [ $+ -1. $+ [ %j ] ] %maxdist
    var %d. [ $+ 0. $+ [ %j ] ] %j
    inc %j
  }

  var %i 1
  while (%i <= %al) {
    var %db 0

    var %j 1
    while (%j <= %bl) {
      var %bj = $asc($mid(%b,%j,1))
      if ($var(%da. [ $+ [ %bj ] ]),1) { var %k $var(%da. [ $+ [ %bj ] ]).value }
      else { var %k %j }
      var %l %db
      if ($mid(%a,%i,1) == $mid(%b,%j,1)) {
        var %cost 0
        var %db %j
      }
      else {
        var %cost 1
      }

      var %v1 $calc(%d. [ $+ [ $decr(%i) ] $+ . $+ [ $decr(%j) ] ] + %cost)
      var %v2 $calc(%d. [ $+ [ %i ] $+ . $+ [ $decr(%j) ] ] + 1)
      var %v3 $calc(%d. [ $+ [ $decr(%i) ] $+ . $+ [ %j ] ] + 1)
      var %v4 $calc(%d. [ $+ [ $decr(%k) ] $+ . $+ [ $decr(%l) ] ] + %i - %k - 1 + 1 + %j - %l - 1)

      var %m1 $iif(%v1 < %v2, %v1, %v2)
      var %m2 $iif(%v3 < %v4, %v3, %v4)
      var %mi $iif(%m1 < %m2, %m1, %m2)

      var %d. [ $+ [ %i ] $+ . $+ [ %j ] ] %mi

      inc %j
    }

    var %ai = $asc($mid(%a,%i,1))
    var %da. [ $+ [ %ai ] ] %i

    inc %i
  }

  var %re = %d. [ $+ [ %al ] $+ . $+ [ %bl ] ]
  return %re
}

alias -l decr {
  return $calc($1 - 1)
}
