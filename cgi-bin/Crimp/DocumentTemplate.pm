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
$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;

$crimp->{DisplayHtml} = $new_content;

&printdebug("Module 'DocumentTemplate'","$status","Started With: $crimp->{DocumentTemplate}");

1;