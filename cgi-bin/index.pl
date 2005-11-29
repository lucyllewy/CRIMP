#!perl
# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005 The CRIMP Team
# Authors:			The CRIMP Team
# Project Leads:	Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
# 						Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:			http://crimp.sourceforge.net/
my $Version = '0.1'; 
my $ID = q$Id: index.pl,v 1.36 2005-11-29 20:29:53 deadpan110 Exp $;

##################################################################################
# This library is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU Lesser General Public                     #
# License as published by the Free Software Foundation; either                   #
# version 2.1 of the License, or (at your option) any later version.             #
#                                                                                #
# This library is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU              #
# Lesser General Public License for more details.                                #
#                                                                                #
# You should have received a copy of the GNU Lesser General Public               #
# License along with this library; if not, write to the Free Software            #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA #
##################################################################################

package Crimp;
&printdebug('CRIMP [Content Redirection Internet Management Program] (Debug View)',
			'',
			'Authors: The CRIMP Team',
			'Project Leads:',
			'&nbsp;&nbsp;&nbsp;Martin "Deadpan110" Guppy [deadpan110@users.sourceforge.net]',
         '&nbsp;&nbsp;&nbsp;Daniel "Fremen" Llewellyn [diddledan@users.sourceforge.net]',
         "Public Version: $Version",
			"Internal Version: $ID",
			'http://crimp.sourceforge.net/'
			);
#
# default web settings are to use local files
# with 404 error document in place
#
# config file contains file and or directory actions
# whether file exists or not
# will try and use apache config style for settings...
#
# <[file] or [directory] = "[local server path to file/directory]"
# [OPTIONS GO HERE]
# ie: *.exe's are located on a number of remote servers
#   try a random server to redirect to 
# </[file] or [directory]>
# also enable file to contain # comments
#
#Produce apache style logs

use Config::Tiny;
use CGI;
use CGI::Carp qw/ fatalsToBrowser /;
use Fcntl;
# 

my $query = new CGI;

#print $query->header('text/html','200');

#our &printdebug;
#die;


########################
# BEGIN plguin parsing #
opendir(DIR, 'Crimp') or &printdebug('Plugins DIR', 'fail', "Could not open the plugins' dir for reading $!");
rewinddir(DIR);
my @plugins = readdir(DIR);
closedir(DIR);

my @inicmds;
foreach $plugin (@plugins) {
  # is the file we found a 'dot' file (.something - meaning hidden)?
  # if not, check it ends in '.pm'
  if ( ( !( $plugin =~ m/^\.+/ ) ) && ( $plugin =~ m/(\.pm){1}$/ ) ) {
    #remove the extension
    $plugin =~ s/(\.pm){1}$//;
    #add it to the list
    push @inicmds, $plugin;
  }
}

if (@inicmds = grep !/DocumentTemplate/, @inicmds) {
	#move DocumentTemplate to the end so that it is always called last (nasty hack I know)
	push @inicmds, 'DocumentTemplate';
}

if ( ! @inicmds ) { &printdebug('Plugins', 'fail', 'There appears to be no plugins in the plugin directory.'); }
else { &printdebug('Available Plugins', 'pass', join(',', @inicmds)); }
# END plugin parsing #
######################

#DocumentTemplate;ContentDirectory;ContentType
our $crimp;
$crimp = {
	#removed the quotes around the $ENV entries to speed up processing time.
	IniCommands => \@inicmds, # can't seem to get this to work properly (line 214)
    RemoteHost => $ENV{'REMOTE_ADDR'},
    ServerName =>  $ENV{'SERVER_NAME'},
    ServerSoftware =>  $ENV{'SERVER_SOFTWARE'},
    UserAgent =>  $ENV{'HTTP_USER_AGENT'},
    HttpRequest =>  $ENV{'REDIRECT_URL'},
    HttpQuery =>  $ENV{'REDIRECT_QUERY_STRING'},
    ContentType => 'text/html',
    PageTitle => 'CRIMP',
    ExitCode => '204',
    DebugMode => 'off',
    VarDirectory => '../cgi-bin/Crimp/var',
	 ErrorDirectory => '../cgi-bin/Crimp/errors'

};

#HTTP Error 204
#No Content. The requested completed successfully but the resource requested is empty (has zero length).


#use join here as it's the most efficient method of concatonating strings (Fremen)
if ($crimp->{HttpQuery}) { $crimp->{HttpQuery} = join '', '?', $crimp->{HttpQuery}; }

####################################################################
# this is a server beep (used for testing)
# Turns local and remote IP's into a tune
# gentoo users > emerge beep

$RemoteHost  = $ENV{'REMOTE_ADDR'};
$ServerHost  = $ENV{'SERVER_ADDR'};
($beep[4],$beep[3],$beep[2],$beep[1]) = split(/\./,$ServerHost);
($beep[5],$beep[6],$beep[7],$beep[8]) = split(/\./,$RemoteHost);

for ($i=1;$i<=8;$i++){
$note =($beep[$i]+25)*10;
$tune = "$tune -f $note -l 100 ";
if ($i < 8){$tune = "$tune -n ";}
}

# to activate, uncomment below
# $BEEP = `beep $tune`;
####################################################################

&printdebug(
    'System Variables',
    'pass',
    "ServerName: $crimp->{ServerName}",
    "ServerSoftware: $crimp->{ServerSoftware}"
);

&printdebug(
    'User Variables',
    'pass',
    "RemoteHost: $crimp->{RemoteHost}",
    "UserAgent: $crimp->{UserAgent}",
    "HttpRequest: $crimp->{HttpRequest}",
    "HttpQuery: $crimp->{HttpQuery}"
);

if ((!-e "crimp.ini")||(!-e "Config/Tiny.pm")){
    $crimp = {DebugMode => 'on'};
    &printdebug(
        'Crimp Files not found',
        'fail',
        'Please check the following files exist in the crimp directory',
        'crimp.ini',
        'Config/Tiny.pm'
    );
}

our $Config = Config::Tiny->new();
$Config = Config::Tiny->read( 'crimp.ini' );

#switch to debug mode if set in crimp.ini
if ($crimp->{DebugMode} ne 'on'){
    if (($query->param('debug') eq 'on') && ($Config->{_}->{DebugMode} eq 'page')) {
        $crimp->{DebugMode} = 'on';
    } else {
        $crimp->{DebugMode}=$Config->{_}->{DebugMode};
    }
}
####################################################################
## set default values ##
#######################

if ($Config->{_}->{ErrorDirectory} ne ''){
	$crimp->{ErrorDirectory}=$Config->{_}->{ErrorDirectory};
    }
 
 
####################################################################
## Main Routine ##
#################

#check requested versus config

#start with requested and work backwards to root until match found
#ie /home/news/index.html
#   /home/news
#   /home

@HttpRequest = split(/\//,$crimp->{HttpRequest});
my $tempstr = '';
foreach $HttpRequest (@HttpRequest){
    if ($HttpRequest ne '') {
        $tempstr = "$tempstr/$HttpRequest";
    }

    if ($Config->{$tempstr}){
        $crimp->{UserConfig}=$tempstr;
    }
}

if ($crimp->{UserConfig} eq ''){
    $crimp->{UserConfig}='/';
}

&printdebug(
    '\'crimp.ini\' Variables',
    'pass',
    "UserConfig: $crimp->{UserConfig}",
);

#setup a cookie holder
our @cookies;

####################################################################
# call the plugins in order
my %executedCommands;
$crimp->{skipRemainingPlugins} = 0;
foreach my $IniCommand (split /,/, $Config->{$crimp->{UserConfig}}->{PluginOrder}) {
	&executePlugin($IniCommand) unless (($crimp->{skipRemainingPlugins}) || ($executedCommands{$IniCommand}++));
}
foreach my $IniCommand (split /,/, $Config->{_}->{PluginOrder}) {
	&executePlugin($IniCommand) unless (($crimp->{skipRemainingPlugins}) || ($executedCommands{$IniCommand}++));
}
#foreach $IniCommand ($crimp->{IniCommands}) { # couldn't get this to work properly
foreach my $IniCommand (@inicmds) {
	&executePlugin($IniCommand) unless (($IniCommand ne 'DocumentTemplate') && (($crimp->{skipRemainingPlugins}) || ($executedCommands{$IniCommand}++)));
}

####################################################################
## The End ##
############

if ($crimp->{ExitCode} eq '204'){
    $crimp->{ExitCode} = '200';
}

#if ($crimp->{Debug} ne 'off'){
#    $crimp->{ExitCode} = '200';
#}

if ($crimp->{ContentType} eq ''){
    $crimp->{ContentType} = 'text/html';
}

#This is where we finish the document or file
#$crimp->{ExitCode} = '200';
print $query->header($crimp->{ContentType},$crimp->{ExitCode},\@cookies);

#if ($crimp->{PageTitle} ne ""){
#$crimp->{PageTitle} = join '', ' - ', $crimp->{PageTitle};
#$crimp->{DisplayHtml} =~ s|(</title>)|$crimp->{PageTitle}\1|i;;
#}


&printdebug('Crimp Exit','pass',"Error code: $crimp->{ExitCode}");
if ($crimp->{DebugMode} eq 'on'){
    $PRINT_DEBUG = join '', '<table class="crimpDebug">', $PRINT_DEBUG, "</table>\n";
    $PRINT_HEAD = "<link rel='stylesheet' type='text/css' href='/crimp_assets/debug.css'/>\n";
    $crimp->{DisplayHtml} =~ s|(</body>)|$PRINT_DEBUG\1|i;;
    $crimp->{DisplayHtml} =~ s|(</head>)|$PRINT_HEAD\1|i;;
}


print $crimp->{DisplayHtml};

####################################################################



#foreach $item (keys %ENV) { print "$item = $ENV{$item}\n<br />";}

####################################################################
####################################################################

sub executePlugin() {
	my $plugin = shift;
	if (!$crimp->{$plugin}) {
		if ($Config->{$crimp->{UserConfig}}->{$plugin}) {
			$crimp->{$plugin}=$Config->{$crimp->{UserConfig}}->{$plugin};
		} elsif ($Config->{_}->{$plugin}) {
				$crimp->{$plugin}=$Config->{_}->{$plugin};
		}
	}

	#Load Module
	if ($crimp->{$plugin} ne ''){
		if ( !-e "Crimp/$plugin.pm"){
			&printdebug("Module '$IniCommand' not found",'warn',"Check 'crimp.ini' for the following:","$IniCommand = $crimp->{$IniCommand}");
		}else{
			#&printdebug("Module '$IniCommands' loading","pass","click here to get this file");
			require "Crimp/$plugin.pm";
		}
	}
}

sub printdebug(){
    my $solut='';
    my $logger='';
    my $mssge=shift(@_);
    my $stats=shift(@_);
    my $fatal = 0;



    #print "$Config->{_}->{Debug};";
    while (my $extra = shift) {
    	if ($solut eq '' && $mssge eq '') { $solut = "&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>"; }
    	else { $solut="$solut<br/>&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>"; }
     	$logger="$logger, $extra";
    }
$log_this=`echo "$mssge,$stats,$logger\n" >> /home/martin/CVS/crimp/cgi-bin/crimp.log`;
  
    if ($stats eq 'pass') { $stats='[<span style="color: #0f0;">PASS</span>]' }
    if ($stats eq 'warn') { $stats='[<span style="color: #fc3;">WARN</span>]' }
    if ($stats eq 'exit') { $stats='[<span style="color: #33f;">EXIT</span>]'; $fatal = 1; }
    if ($stats eq 'fail') { $stats='[<span style="color: #f00;">FAIL</span>]'; $fatal = 1; }

    if (($solut ne '')&&($mssge ne '')) { $mssge="<b>&#8226;</b> $mssge $solut"; }
	if ($mssge eq ''){$mssge = "$solut";}
    $PRINT_DEBUG = "$PRINT_DEBUG<tr><td class='crimpDebugMsg'><pre class='crimpDebug'>$mssge</pre></td><td class='crimpDebugStatus'><pre class='crimpDebug'><span style='color: #fff;'>$stats</span></pre></td></tr>";
    
    
    #
    #<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>
  
 
 
    if ($fatal){
       # print $query->header('text/html',$crimp->{ExitCode});
#        print $query->header('text/html','200');
        print $PRINT_DEBUG;
      #  exit;
        #crimp_display("debug");
        #print "META <meta http-equiv='refresh' content='30;URL=../cgi-bin/crimp.pl?mode=config'>";
        #print "<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>";
    }
}


sub FileRead{
my $filename=shift(@_);
my $entry=shift(@_);
my $string=shift(@_);
my $fileopen = join '/',$crimp->{VarDirectory},$filename;

&printdebug('','',"FileRead: $filename");

if ( -f $fileopen ){
	sysopen (FILE,$fileopen,O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
		@FileRead=<FILE>;
		close(FILE);
			
		if (@FileRead){	
			
			foreach $FileRead(@FileRead){
				chop($FileRead) if $FileRead =~ /\n$/;
				($FileEntry,$FileString) = split(/\|\|/,$FileRead);
					if ($FileEntry eq $entry){return($FileString);}
			}
		
		}
	}
	return (&FileWrite($filename,$entry,$string));
}

sub FileWrite{
my $filename=shift(@_);
my $entry=shift(@_);
my $string=shift(@_);
my $filelock = join '/',$crimp->{VarDirectory},'lock',$filename;
my $fileopen = join '/',$crimp->{VarDirectory},$filename;

&printdebug('','',"FileWrite: $filename");

sysopen(LOCKED,$filelock, O_WRONLY | O_EXCL | O_CREAT) or &RetryWait($filename,$entry,$string);if ( -f $fileopen ){
	sysopen (FILE,$fileopen,O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
		@FileRead=<FILE>;
		close(FILE);
		
		if (@FileRead){	
			
			foreach $FileRead(@FileRead){
				chop($FileRead) if $FileRead =~ /\n$/;
				($FileEntry,$FileString) = split(/\|\|/,$FileRead);
			
			
					if ($FileEntry eq $entry){
					print LOCKED "$entry||$string\n";
					}else{print LOCKED "$FileEntry||$FileString\n";}
				
			}
		}
}else{
print LOCKED "$entry||$string\n";
	}

close(LOCKED);
$file1="$SYSROOT_SYSTEM/system_keys.bak";
$file2="$SYSROOT_SYSTEM/system_keys.txt";
rename($filelock, $fileopen) or die "cant rename";

return($string);


}

sub RetryWait{
my $filename=shift(@_);
my $entry=shift(@_);
my $string=shift(@_);

	if ($tries gt 5){
		#$requested = join '/', $crimp->{ErrorDirectory}, '500.html';
		$crimp->{ExitCode} = '500';
		&printdebug('','warn',"File lock in place on $filename");		
		return;
		}

	if ($tries ne 0){sleep 1;}
		
$tries++;
&FileWrite($filename,$entry,$string);

}



#print $PRINT_DEBUG;
#REALLY THE END#
