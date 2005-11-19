$ID = q$Id: DocumentTemplate.pm,v 1.6 2005-11-18 20:29:08 ind-network Exp $;
&printdebug('Module DocumentTemplate',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

#only parse the template if this is an html or xhtml page
if (($crimp->{ContentType} eq 'text/html') || ($crimp->{ContentType} eq 'text/xhtml+xml')) {
	@HttpRequest = split(/\//,$crimp->{HttpRequest});
	foreach $HttpRequest (@HttpRequest){
	  #print "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
	  if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
	}
	
	sysopen (FILE,$crimp->{DocumentTemplate}, O_RDONLY) or exit;
	@template_content=<FILE>;
	#$SIZE=@LINES;
	$status = 'pass';
	close(FILE);
	
	my $new_content = '';
	foreach $template_line(@template_content) {
	  $new_content = join '', $new_content, $template_line;
	}
	
	#printdebug ("Putting Page into Template");
	$new_content =~ s/<!--TITLE-->/$crimp->{PageTitle} - $Config->{_}->{SiteTitle}/gi;
	$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
	$crimp->{DisplayHtml} = $new_content;
	
	&printdebug("Module 'DocumentTemplate'","$status","Started With: $crimp->{DocumentTemplate}");
} else {
	&printdebug('Module \'DocumentTemplate\'', 'pass', "Skipped module for ContentType: $crimp->{ContentType}");
}


1;