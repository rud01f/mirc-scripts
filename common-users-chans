; #################################
; #                               #
; # common channels per user list #
; #  aka. /ccom                   #
; #              by rud0lf/IRCnet #
; #################################

; # example output (partially masked for privacy)
; #
; # channel: #dis***
; # {Ei***e}       also on: #pa**s
; # {N***r}        also on: #wo***t
; # {m**}          also on: #pa**s #wo***t
; # end of #dis*** report
;
;
; /ccom [#channel]
; if #channel is not present in args, will try active window 
alias ccom {
  var %chan = $chan
  if ($0) {
    %chan = $1-
    if ($me !ison %chan) { echo -a * ccom: not on channel %chan ! | return }
  }
  else {
    if (!$chan) { echo -a * ccom: current window is not a channel window! | return }
  }
  var %n = $nick(%chan,0)
  if (%n < 2) { echo -a * you're alone on %chan | return }
  if (!$window(@ccom)) { window -e0 @ccom }
  aline @ccom channel: %chan

  var %i = 1
  while (%i <= %n) {
    var %cn = $null
    var %ni = $nick(%chan,%i)
    var %ct = $comchan(%ni,0)
    var %j = 1
    while (%j <= %ct) {
      if (%chan != $comchan(%ni,%j)) { %cn = %cn $comchan(%ni,%j) }        
      inc %j
    }
    var %nipad = $left($chr(123) $+ %ni $+ $chr(125) $+ $str($chr(160),15), 17) 
    if ((%cn) && ($me != %ni)) { aline @ccom %nipad also on: %cn }
    inc %i 
  }
  aline @ccom end of %chan report
  aline @ccom -
}
