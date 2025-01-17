#!/usr/bin/env ksh93

#
# This file is a part of the NsCDE - Not so Common Desktop Environment
# Author: Hegel3DReloaded
# Licence: GPLv3
#

# Defaults and globals
OLD_LC_ALL="$LC_ALL"
IFS=" "
write_gwm_conf=0
write_gwm_script=0
prepare_piperead=0

function usage
{
   echo "Usage: ${0##*/} -w <vp width> -h <vp height> -f <reduction factor> -d <no of desks> [ -c <pager conf file> ] [ -s ] | [ -H ]"
   exit $1
}

while getopts w:h:f:d:c:sH Option
do
   case $Option in
      w)
         width=$OPTARG
      ;;
      h)
         height=$OPTARG
      ;;
      f)
         wfactor=$OPTARG
      ;;
      d)
         ndesks=$OPTARG
      ;;
      c)
         gwm_pgr_conf_file=$OPTARG
         write_gwm_conf=1
      ;;
      s)
         write_gwm_script=1
      ;;
      H)
         usage 0
      ;;
   esac
done

if [ -z $width ]; then
   usage 1
fi

if [ -z $height ]; then
   usage 1
fi

if [ -z $wfactor ]; then
   usage 1
fi

if [ -z $ndesks ]; then
   usage 1
fi

# Parse WSM.conf
WSMCONF="${FVWM_USERDIR}/WSM.conf"

if [ -r "${WSMCONF}" ]; then
   WsmReadRows=$(egrep "^GWM:${ndesks}:ROWS:[[:digit:]]" ${WSMCONF} 2>/dev/null)
   WsmRows="${WsmReadRows##*:}"

   WsmReadWscale=$(egrep "^GWM:${ndesks}:WSCALE:[10-20]" ${WSMCONF} 2>/dev/null)
   WsmWscale="${WsmReadWscale##*:}"

   WsmReadBackdrops=$(egrep "^GWM:0:BACKDROPS:(0|1)" ${WSMCONF} 2>/dev/null)
   WsmBackdrops="${WsmReadBackdrops##*:}"

   if [ "x$WsmBackdrops" == "x" ]; then
      WsmBackdrops=1
   fi

   WsmReadHlCurrent=$(egrep "^GWM:0:HLCURRENT:(0|1)" ${WSMCONF} 2>/dev/null)
   WsmHlCurrent="${WsmReadHlCurrent##*:}"

   if [ "x$WsmHlCurrent" == "x" ]; then
      WsmHlCurrent=0
   fi

   WsmReadLabelPos=$(egrep "^GWM:0:LABELPOS:(1|2)" ${WSMCONF} 2>/dev/null)
   WsmLabelPos="${WsmReadLabelPos##*:}"

   if [ "x$WsmLabelPos" == "x" ]; then
      WsmLabelPos=1
   fi

   WsmReadBalloons=$(egrep "^GWM:0:BALLOONS:(0|1)" ${WSMCONF} 2>/dev/null)
   WsmBalloons="${WsmReadBalloons##*:}"

   if [ "x$WsmBalloons" == "x" ]; then
      WsmBalloons=1
   fi

   WsmReadSkipList=$(egrep "^GWM:0:SKIPLIST:(0|1)" ${WSMCONF} 2>/dev/null)
   WsmSkipList="${WsmReadSkipList##*:}"

   if [ "x$WsmSkipList" == "x" ]; then
      WsmSkipList=1
   fi

   WsmReadWinContent=$(egrep "^GWM:0:WINCONTENT:(0|1)" ${WSMCONF} 2>/dev/null)
   WsmWinContent="${WsmReadWinContent##*:}"

   if [ "x$WsmWinContent" == "x" ]; then
      WsmWinContent=1
   fi
else
   WsmBackdrops=1
   WsmHlCurrent=0
   WsmLabelPos=1
   WsmBalloons=1
   WsmSkipList=1
   WsmWinContent=1
fi

if [ "$WsmBackdrops" == 1 ]; then
   back1=31
   back2=32
   back3=33
   back4=34
   back5=35
   back6=36
   back7=37
   back8=38
else
   back1=40
   back2=42
   back3=44
   back4=46
   back5=40
   back6=42
   back7=44
   back8=46
fi

if [ "$WsmHlCurrent" == 0 ]; then
   DeskHilight="NoDeskHilight"
else
   DeskHilight="DeskHilight"
fi

if [ "$WsmLabelPos" == 1 ]; then
   LabelsPos="LabelsAbove"
else
   LabelsPos="LabelsBelow"
fi

if [ "$WsmBalloons" == 1 ]; then
   BalloonsType="All"
else
   BalloonsType="Icon"
fi

if [ "$WsmSkipList" == 1 ]; then
   SkipListConf="*GWMPager: UseSkipList"
else
   SkipListConf=""
fi

if [ "$WsmWinContent" == 1 ]; then
   MiniIconsConf="*GWMPager: MiniIcons"
else
   MiniIconsConf=""
fi

if [ "x$WsmRows" != "x" ]; then
   Rows=$WsmRows
   case $ndesks in
   2)
      if (($Rows == 1)); then
         Cols=2
      else
         Cols=1
      fi
   ;;
   4)
      if (($Rows == 1)); then
         Cols=4
      elif (($Rows == 2)); then
         Cols=2
      elif (($Rows == 4)); then
         Cols=1
      fi
   ;;
   6)
      if (($Rows == 1)); then
         Cols=6
      elif (($Rows == 2)); then
         Cols=3
      elif (($Rows == 3)); then
         Cols=2
      elif (($Rows == 6)); then
         Cols=1
      fi
   ;;
   8)
      if (($Rows == 1)); then
         Cols=8
      elif (($Rows == 2)); then
         Cols=4
      elif (($Rows == 4)); then
         Cols=2
      elif (($Rows == 8)); then
         Cols=1
      fi
   ;;
   esac
else
   case $ndesks in
   2)
      Rows=2
      Cols=1
   ;;
   4)
      Rows=2
      Cols=2
   ;;
   6)
      Rows=2
      Cols=3
   ;;
   8)
      Rows=4
      Cols=2
   ;;
   esac
fi

if [ "x$WsmWscale" != "x" ]; then
   Width=$((($WsmWscale * 152) / 10))
else
   Width=$((($wfactor * 152) / 10))
   WsmWscale=$wfactor
fi

Width=${Width%%.*}
Height=$(((($Width * $height / $width) + 20)))

# Initial calculations
WindowWidth=$(($Width * $Cols))
PagerWidth=$(($Width * $Cols))
PagerHeight=$((((($Width * $height) / $width) + 20) * $Rows))
WindowHeight=$(($PagerHeight + 32))
WidgetHelpVisible=""

# Help menu item on the right calculations
# Just for the sake of having it Motif style.
WidgetWindowTitle=" Window|(De)Iconify|(De)Shade|Close Window|Terminate Application|Occupy Workspace ..."
WidgetHelpTitle=" Help|GWM Key Bindings|GWM Help"
case ${ndesks}${Rows}${Cols}${WsmWscale} in
22110|22111|44110|44111|66110|66111|88110|88111)
   WidgetWindowTitle=" Win.|(De)Iconify|(De)Shade|Close Window|Terminate Application|Occupy Workspace ..."
;;
22110|22111|22112|22113|44110|44111|44112|44113|66110|66111|66112|66113|88110|88111|88112|88113)
   HelpMenuPadding=""
   WidgetHelpVisible="HideWidget 4"
;;
22114|44114|66114|88114|22115|44115|66115|88115)
   HelpMenuPadding=""
   WidgetHelpTitle=" H.|GWM Key Bindings|GWM Help"
;;
22116|44116|66116|88116)
   HelpMenuPadding=""
;;
22117|44117|66117|88117)
   HelpMenuPadding=$(for n in {0..1}; do echo -ne 0; done)
;;
22118|44118|66118|88118)
   HelpMenuPadding=$(for n in {0..2}; do echo -ne 0; done)
;;
22119|44119|66119|88119)
   HelpMenuPadding=$(for n in {0..4}; do echo -ne 0; done)
;;
22120|44120|66120|88120)
   HelpMenuPadding=$(for n in {0..5}; do echo -ne 0; done)
;;
21210|42210|63210|84210)
   HelpMenuPadding=$(for n in {0..5}; do echo -ne 0; done)
;;
21211|42211|63211|84211)
   HelpMenuPadding=$(for n in {0..8}; do echo -ne 0; done)
;;
21212|42212|63212|84212)
   HelpMenuPadding=$(for n in {0..11}; do echo -ne 0; done)
;;
21213|42213|63213|84213)
   HelpMenuPadding=$(for n in {0..14}; do echo -ne 0; done)
;;
21214|42214|63214|84214)
   HelpMenuPadding=$(for n in {0..17}; do echo -ne 0; done)
;;
21215|42215|63215|84215)
   HelpMenuPadding=$(for n in {0..20}; do echo -ne 0; done)
;;
21216|42216|63216|84216)
   HelpMenuPadding=$(for n in {0..23}; do echo -ne 0; done)
;;
21217|42217|63217|84217)
   HelpMenuPadding=$(for n in {0..26}; do echo -ne 0; done)
;;
21218|42218|63218|84218)
   HelpMenuPadding=$(for n in {0..29}; do echo -ne 0; done)
;;
21219|42219|63219|84219)
   HelpMenuPadding=$(for n in {0..32}; do echo -ne 0; done)
;;
21220|42220|63220|84220)
   HelpMenuPadding=$(for n in {0..36}; do echo -ne 0; done)
;;
41410|82410)
   HelpMenuPadding=$(for n in {0..36}; do echo -ne 0; done)
;;
41411|82411)
   HelpMenuPadding=$(for n in {0..42}; do echo -ne 0; done)
;;
41412|82412)
   HelpMenuPadding=$(for n in {0..48}; do echo -ne 0; done)
;;
41413|82413)
   HelpMenuPadding=$(for n in {0..54}; do echo -ne 0; done)
;;
41414|82414)
   HelpMenuPadding=$(for n in {0..60}; do echo -ne 0; done)
;;
41415|82415)
   HelpMenuPadding=$(for n in {0..66}; do echo -ne 0; done)
;;
41416|82416)
   HelpMenuPadding=$(for n in {0..72}; do echo -ne 0; done)
;;
41417|82417)
   HelpMenuPadding=$(for n in {0..78}; do echo -ne 0; done)
;;
41418|82418)
   HelpMenuPadding=$(for n in {0..84}; do echo -ne 0; done)
;;
41419|82419)
   HelpMenuPadding=$(for n in {0..90}; do echo -ne 0; done)
;;
41420|82420)
   HelpMenuPadding=$(for n in {0..96}; do echo -ne 0; done)
;;
62310)
   HelpMenuPadding=$(for n in {0..20}; do echo -ne 0; done)
;;
62311)
   HelpMenuPadding=$(for n in {0..25}; do echo -ne 0; done)
;;
62312)
   HelpMenuPadding=$(for n in {0..29}; do echo -ne 0; done)
;;
62313)
   HelpMenuPadding=$(for n in {0..34}; do echo -ne 0; done)
;;
62314)
   HelpMenuPadding=$(for n in {0..38}; do echo -ne 0; done)
;;
62315)
   HelpMenuPadding=$(for n in {0..43}; do echo -ne 0; done)
;;
62316)
   HelpMenuPadding=$(for n in {0..48}; do echo -ne 0; done)
;;
62317)
   HelpMenuPadding=$(for n in {0..52}; do echo -ne 0; done)
;;
62318)
   HelpMenuPadding=$(for n in {0..57}; do echo -ne 0; done)
;;
62319)
   HelpMenuPadding=$(for n in {0..61}; do echo -ne 0; done)
;;
62320)
   HelpMenuPadding=$(for n in {0..66}; do echo -ne 0; done)
;;
61610)
   HelpMenuPadding=$(for n in {0..66}; do echo -ne 0; done)
;;
61611)
   HelpMenuPadding=$(for n in {0..75}; do echo -ne 0; done)
;;
61612)
   HelpMenuPadding=$(for n in {0..84}; do echo -ne 0; done)
;;
61613)
   HelpMenuPadding=$(for n in {0..93}; do echo -ne 0; done)
;;
61614)
   HelpMenuPadding=$(for n in {0..102}; do echo -ne 0; done)
;;
61615)
   HelpMenuPadding=$(for n in {0..112}; do echo -ne 0; done)
;;
61616)
   HelpMenuPadding=$(for n in {0..121}; do echo -ne 0; done)
;;
61617)
   HelpMenuPadding=$(for n in {0..130}; do echo -ne 0; done)
;;
61618)
   HelpMenuPadding=$(for n in {0..139}; do echo -ne 0; done)
;;
61619)
   HelpMenuPadding=$(for n in {0..148}; do echo -ne 0; done)
;;
61620)
   HelpMenuPadding=$(for n in {0..157}; do echo -ne 0; done)
;;
81810)
   HelpMenuPadding=$(for n in {0..96}; do echo -ne 0; done)
;;
81811)
   HelpMenuPadding=$(for n in {0..108}; do echo -ne 0; done)
;;
81812)
   HelpMenuPadding=$(for n in {0..120}; do echo -ne 0; done)
;;
81813)
   HelpMenuPadding=$(for n in {0..132}; do echo -ne 0; done)
;;
81814)
   HelpMenuPadding=$(for n in {0..144}; do echo -ne 0; done)
;;
81815)
   HelpMenuPadding=$(for n in {0..157}; do echo -ne 0; done)
;;
81816)
   HelpMenuPadding=$(for n in {0..169}; do echo -ne 0; done)
;;
81817)
   HelpMenuPadding=$(for n in {0..181}; do echo -ne 0; done)
;;
81818)
   HelpMenuPadding=$(for n in {0..193}; do echo -ne 0; done)
;;
81819)
   HelpMenuPadding=$(for n in {0..205}; do echo -ne 0; done)
;;
81820)
   HelpMenuPadding=$(for n in {0..218}; do echo -ne 0; done)
;;
esac

function WriteGwmConf
{
   # Write temporary GWMPager.conf
   mkdir -p ${FVWM_USERDIR}/tmp

   if [ "x$gwm_pgr_conf_file" == "x" ]; then
      gwm_pgr_conf_file="${FVWM_USERDIR}/tmp/GWMPager.conf"
   fi

   if [ "x$gwm_pgr_conf_file" == "x-" ]; then
       gwm_pgr_conf_file="/dev/stdout"
       prepare_piperead=1
   fi

   cat <<EOF > $gwm_pgr_conf_file 2>/dev/null
DestroyModuleConfig GWMPager:*
PipeRead "echo *GWMPager: Geometry \$(($Width * $Cols))x\$(($Height * $Rows))"
*GWMPager: Rows $Rows
*GWMPager: Columns $Cols
*GWMPager: Colorset 0 $back1
*GWMPager: Colorset 1 $back2
*GWMPager: Colorset 2 $back3
*GWMPager: Colorset 3 $back4
*GWMPager: Colorset 4 $back5
*GWMPager: Colorset 5 $back6
*GWMPager: Colorset 6 $back7
*GWMPager: Colorset 7 $back8
*GWMPager: HilightColorset * 2
*GWMPager: $DeskHilight
*GWMPager: $LabelsPos
*GWMPager: Font Shadow=2 0 C:\$[infostore.font.variable.normal.small]
*GWMPager: SolidSeparators
*GWMPager: SmallFont xft:Sans:style=Regular:pixelsize=8
*GWMPager: Balloons $BalloonsType
*GWMPager: BalloonColorset * 4
*GWMPager: BalloonFont \$[infostore.font.monospaced.normal.small]
*GWMPager: BalloonYOffset +1
*GWMPager: BalloonBorderWidth 1
*GWMPager: WindowColorsets 1 2
*GWMPager: WindowBorderWidth 2
$SkipListConf
*GWMPager: Window3DBorders
$MiniIconsConf
Test (EnvMatch FVWM_IS_FVWM3 1) *GWMPager: Monitor \$\$\$[monitor.current]
EOF

   if (($prepare_piperead == 1)); then
      echo "Module FvwmPager GWMPager 0 $(($ndesks - 1))" >> "$gwm_pgr_conf_file"
   fi
}

function WriteGwmScript
{
   # Generate script
   cat <<EOF
UseGettext {$NSCDE_ROOT/share/locale;NsCDE-GWM}
WindowLocaleTitle {GWM}
WindowSize ${WindowWidth} ${WindowHeight}
Colorset 22

Init
Begin
   Do {Read $[FVWM_USERDIR]/tmp/GWMPager.conf}
   Do {Schedule 250 Exec exec rm -f "$[FVWM_USERDIR]/tmp/GWM" "$[FVWM_USERDIR]/tmp/GWMPager.conf"}

   $WidgetHelpVisible

   Set \$MenuFont = (GetOutput {\$NSCDE_ROOT/bin/getfont -v -t normal -s medium -Z 14} 1 -1)
   ChangeFont 1 \$MenuFont
   ChangeFont 2 \$MenuFont
   ChangeFont 4 \$MenuFont

   # Locale flush right/left workaround
   ChangeLocaleTitle 1 (GetTitle 1)
   ChangeLocaleTitle 2 (GetTitle 2)
   ChangeLocaleTitle 4 (GetTitle 4)

   Key Q C 1 1 {Quit}
   Key Escape A 1 1 {Quit}
   Key M C 1 3 {Manage}
   Key R C 1 3 {Rename}
   Key O C 1 3 {Options}
   Key W C 2 1 {Occupy}
   Key Help A 4 1 {DisplayHelp}
   Key F1 A 4 1 {DisplayHelp}
End

Widget 1
   Property
   Type Menu
   Position 0 10
   Flags NoReliefString Left
   Value 0
   Title { Workspace|Manage Workspaces ...|Rename ...|Cascade All Windows|Tile All Windows Vertically|Tile All Windows Horizontally|Options ...|Exit}
   Font "xft:::pixelsize=18:charwidth=9.8"
   Main
      Case message of
      SingleClic :
      Begin
         # Manage Workspaces
         If (GetValue 1) == 1 Then
         Begin
            Do {f_ToggleFvwmModule FvwmScript WsPgMgr \$[infostore.desknum] \$[infostore.pagematrixX] \$[infostore.pagematrixY]}
            Do {Schedule 500 All (WsPgMgr, CirculateHit) PlaceAgain}
         End
         # Rename
         If (GetValue 1) == 2 Then
         Begin
            HideWidget 6
            Do {f_GWMRenameWorkspaceHelper}
            SendSignal 3 1
         End
         # Cascade All Windows
         If (GetValue 1) == 3 Then
         Begin
            HideWidget 6
            Do {Module FvwmRearrange -cascade -incx 8 -incy 6 6 2 \$[wa.width]p \$[wa.height]p}
            SendSignal 3 1
         End
         # Tile All Windows Vertically
         If (GetValue 1) == 4 Then
         Begin
            HideWidget 6
            Do {f_TileWindows}
            SendSignal 3 1
         End
         # Tile All Windows Horizontally
         If (GetValue 1) == 5 Then
         Begin
            HideWidget 6
            Do {f_TileWindows -h}
            SendSignal 3 1
         End
         # Options
         If (GetValue 1) == 6 Then
         Begin
            HideWidget 6
            Do {Module FvwmScript GWMOptions \$[infostore.glob_pg.desk_scale] \$[infostore.desknum]}
            SendSignal 3 1
         End
         # Exit
         If (GetValue 1) == 7 Then
         Begin
            HideWidget 6
            Do {Schedule 10 SendToModule $[FVWM_USERDIR]/tmp/GWM SendString 1 1 Quit}
         End
      End
      1 :
      Begin
         If (LastString) == {Quit} Then
         Begin
            Do {KillModule FvwmPager GWMPager}
            Do {Schedule 100 SendToModule GWMOptions SendString 19 1 Exit}
            Do {Schedule 250 SendToModule $[FVWM_USERDIR]/tmp/GWM SendString 1 2 QExit}
         End
      End
      2 :
      Begin
         If (LastString) == {QExit} Then
         Begin
            Quit
         End
      End
      3 :
      Begin
         If (LastString) == {Manage} Then
         Begin
            Do {f_ToggleFvwmModule FvwmScript WsPgMgr \$[infostore.desknum] \$[infostore.pagematrixX] \$[infostore.pagematrixY]}
            Do {Schedule 500 All (WsPgMgr, CirculateHit) PlaceAgain}
         End
         If (LastString) == {Rename} Then
         Begin
            Do {f_GWMRenameWorkspaceHelper}
         End
         If (LastString) == {Options} Then
         Begin
            Do {Module FvwmScript GWMOptions \$[infostore.glob_pg.desk_scale] \$[infostore.desknum]}
         End
      End
End

Widget 2
   Property
   Type Menu
   Position 0 20
   Flags NoReliefString Left
   Value 0
   Title {$WidgetWindowTitle}
   Font "xft:::pixelsize=18:charwidth=9.8"
   Main
      Case message of
      SingleClic :
      Begin
         If (GetValue 2) == 1 Then
         Begin
            HideWidget 6
            Do {Prev Iconify toggle}
            SendSignal 3 1
         End
         If (GetValue 2) == 2 Then
         Begin
            HideWidget 6
            Do {Prev WindowShade toggle}
            SendSignal 3 1
         End
         If (GetValue 2) == 3 Then
         Begin
            HideWidget 6
            Do {Prev Close}
            SendSignal 3 1
         End
         If (GetValue 2) == 4 Then
         Begin
            HideWidget 6
            Do {Prev Destroy}
            SendSignal 3 1
         End
         If (GetValue 2) == 5 Then
         Begin
            HideWidget 6
            Do {Prev f_SendToOccupy wsp nogo}
            SendSignal 3 1
         End
      End
      1 :
      Begin
         If (LastString) == {Occupy} Then
         Begin
            Do {Prev f_SendToOccupy wsp nogo}
         End
      End
End

Widget 3
   Property
   Type Menu
   Position 0 389
   Flags NoReliefString Left Hidden
   Value 0
   Title {$HelpMenuPadding}
   Font "xft:::pixelsize=12:spacing=mono:charwidth=10"
   Main
      Case message of
      SingleClic :
      Begin
      End
      1 :
      Begin
         Do {Schedule 168 SendToModule $[FVWM_USERDIR]/tmp/GWM SendString 3 2 ShowPager}
      End
      2 :
      Begin
         If (LastString) == {ShowPager} Then
         Begin
            ShowWidget 6
         End
      End
End

Widget 4
   Property
   Type Menu
   Position 0 389
   Flags NoReliefString Left
   Value 0
   Title {$WidgetHelpTitle}
   Font "xft:::pixelsize=18:charwidth=9.8"
   Main
      Case message of
      SingleClic :
      Begin
         SendSignal 4 1
      End
      1 :
      Begin
         If (GetValue 4) == 1 Then
         Begin
            HideWidget 6
            Do {Schedule 250 f_NotifierFromFile gwmkbd "$[gt.GWM Key Bindings]" "$[gt.Dismiss]" "NsCDE/Info.xpm" "$NSCDE_ROOT/share/doc/help/GWM_Keybindings.help" "NsCDE-GWM"}
            SendSignal 3 1
         End
         If (GetValue 4) == 2 Then
         Begin
            HideWidget 6
            Do {f_DisplayURL "\$[gt.GWM]" \$[NSCDE_ROOT]/share/doc/html/NsCDE-GWM.html}
            SendSignal 3 1
         End
      End
End

Widget 6
   Property
   Size ${PagerWidth} ${PagerHeight}
   Position 2 30
   Type SwallowExec
   Title {GWMPager}
   SwallowExec {Module FvwmPager GWMPager 0 \$[infostore.fvwmdesknum]}
   Flags NoReliefString Center
   Value 1
   Colorset 22
End
EOF
}

if (($write_gwm_conf == 1)); then
   WriteGwmConf
fi

if (($write_gwm_script == 1)); then
   WriteGwmScript
fi

