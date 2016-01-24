;  ###############################
;  #                             #
;  #  IRCnet penalty calculator  #
;  #   by rud0lf/IRCnet          #
;  #                             #
;  ###############################
;
;    calculates penalty in seconds for an outgoing commands
;    the result is visible under %since [ $+ [ $cid ] ], it 
;    is a timestamp advanced by penalty value from current $ctime
;    (as introduced in IRCnet's irc 2.11.2p3 source code)
;
;    you can see the result using $iif($calc(%since [ $+ [ $cid ] ] - $ctime) >= 0,$v1,0)
;    that result in current penalty (in seconds), if greater than 10 then server
;    will stop parsing incomming commands until it lowers to 10 or less
;
;    initially this script shows penalty in mIRC's titlebar, but it can be
;    altered by modifying "showdelta" alias (which is called every second btw)
;

on *:CONNECT: {
  if ($network == IRCnet) {
    if (%since [ $+ [ $cid ] ] < $ctime) { set -e %since [ $+ [ $cid ] ] $ctime }
    ; remove line below if you don't want penalty to be shown in titlebar
    .timerpenalty-meter [ $+ [ $cid ] ] 0 1 showdelta
  }
}


on *:PARSELINE:out:*: {
  if ($network != IRCnet) { return }

  var %cmd = $gettok($parseline, 1, 32)
  var %msg = $gettok($parseline, 2-, 32)
  var %i = $iif(%msg, $len(%msg), $len(%cmd))

  var %penalty = $calc(1 + %i // 100)

  if (%cmd == KICK) { 
    var %chans = $gettok(%msg, 1, 32)
    var %targets = $gettok(%msg, 2, 32)
    inc %penalty
    %penalty = $calc(%penalty + $numtok(%targets,44))
    var %i = %penalty
    var %penalty = $calc(%penalty + %i * $numtok(%chans,44))
  }
  elseif (%cmd == MODE) {
    var %chans = $gettok(%msg, 1, 32)
    var %modes = $gettok(%msg, 2, 32)
    var %i = 0

    if (!%modes) { inc %i }
    var %p = 1
    while (%p <= $len(%modes)) {
      var %modechar = $mid(%modes,%p,1)
      if (%modechar isin ntimps) {
        inc %i 3
      }
      elseif (%modechar !isin +-) {
        inc %i
      }      
      inc %p
    }
    var %targets = $gettok(%msg, 3-, 32)
    %i = $calc(%i + $numtok(%targets, 32) * 2)
    var %ii = $numtok(%chans, 44)
    var %penalty = $calc(%penalty + %i * %ii)
  }
  elseif (%cmd == TOPIC) {
    inc %penalty
    var %chan = $gettok(%msg, 1, 32)
    var %topic = $gettok(%msg, 2-, 32)
    if (%topic) {
      inc %penalty 2
      %penalty = $calc(%penalty + 2 * $numtok(%chan, 44)  
    }
  }
  elseif ((%cmd == PRIVMSG) || (%cmd == NOTICE)) {
    var %targets = $gettok(%msg, 1, 32)
    var %penalty = $calc(%penalty + $numtok(%targets, 44))
  }
  elseif (%cmd == AWAY) {
    inc %penalty $iif(%msg, 2, 1)
  }
  elseif (%cmd == INVITE) {
    inc %penalty 3
  }
  elseif (%cmd == JOIN) {
    inc %penalty 2
  }
  elseif (%cmd == PART) {
    inc %penalty 4
  }
  elseif (%cmd == VERSION) {
    inc %penalty 2
  }
  elseif (%cmd == TIME) {
    inc %penalty 2
  }
  elseif (%cmd == TRACE) {
    inc %penalty 2
  }
  elseif (%cmd == NICK) {
    inc %penalty 3
  }
  elseif (%cmd == ISON) {
    inc %penalty 1
  }
  elseif (%cmd == WHOIS) {
    inc %penalty 2
  }
  else {
    inc %penalty
  }
  if (%penalty < 2) { %penalty = 2 }

  if (%since [ $+ [ $cid ] ] < $ctime) { set -e %since [ $+ [ $cid ] ] $ctime }
  set -e %since [ $+ [ $cid ] ] $calc(%since [ $+ [ $cid ] ] + %penalty)

  showdelta
}

alias showdelta {
  var %delta = $calc(%since [ $+ [ $cid ] ] - $ctime)
  if (%delta < 0) { %delta = 0 }  
  titlebar $([) $+ D: %delta $+ $(])
}
