#!/usr/bin/perl -w
# for commmand line interface, maybe need to take out the -wT options, tainting hard to avoid...
use strict;
use warnings;
my $version = "2019-09-Sep-16 11:46";
my $script_name = 'pdf.pl'; 
use Carp 'verbose';
# local $SIG{__DIE__} = sub { Carp::confess(@_) };
use Data::Dumper;
use CGI::Simple;
use CGI::Carp 'fatalsToBrowser';
use Unicode::Collate;
use Spreadsheet::Read;
use Spreadsheet::ParseXLSX;
use Getopt::Long;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS ) ;
use PDF::API2; 
use PDF::Table;
# good documentation... https://metacpan.org/pod/PDF::API2::Content Aug 9, 2019
##### good documentation... https://metacpan.org/pod/PDF::API2::Simple  Feb 10, 2008
# good documentation... https://metacpan.org/pod/PDF::API2 Aug 9, 2019
#
my ( $dir, $q , $book_copy );
if    ( $^O =~ /^MSWin32/xi ) { $dir = '/home/westmj/public_html/files/'; }
elsif ( $^O =~ /^linux/xi )   { $dir = '/home/westmj/public_html/files/'; }
elsif ( $^O =~ /^darwin/xi )  { $dir = '/Users/Headofschool/Downloads/'; }
my $source = 'MFSRoster 2019-2020.xlsx'; 
if ( defined( $ENV{'REQUEST_METHOD'} ) ) {  # in CGI mode, accessed from web 
    if ( $ENV{'REQUEST_METHOD'} eq 'GET' ) {
        get($script_name);
    }
    elsif ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
        post($script_name);
    }
    else { print "Where the hell am I in '$script_name' version '$version'? cgi-bin but not get or post? \n"; }
}
else {
    cli();   # CLI mode  
}

sub cli {
    GetOptions( 
# $ perl -w cli-cgi.pl --dir=/home/westmj/public_html/files/ --source='MFSRoster 2019-2020.xlsx' --book_store=store --workbook=directory.xls 
        "source=s"  => \$source, 
        "pdf=s"   => \$pdf
    ) or die("Error in command line arguments (see  https://github.com/westmj/mfs-directory ) \n");
    print "In the cli subroutine now..( https://github.com/westmj/mfs-directory ) 
      \$dir ='$dir' \$source = '$source'  \$book_store = '$book_store' \$workbook_name = '$workbook_name'  .\n";
    my $book =
      ReadData( "$dir" . $source  );   # xlsx;
    print " cli past ReadData...  \n";
    my $taint_store = $dir . $book_store;
    my $untaint_store;
    $taint_store =~ /^([A-Za-z0-9_\/]+)$/;
    $untaint_store = $1;  # $untaint_store = $dir . $untaint_store;
    print " cli at store = '$untaint_store'\n";
    store \$book, $untaint_store;
    print " cli book stored... "; 
    make_booklet_support(); 
    print " cli booklet made ... "; 
    exit;
}


sub make_pdf-01 {
my $pdf  = PDF::API2->new(-file => "$$.test");

my $page = $pdf->page;                               ## Create a new page.
my $txt = $page->text;                               ## Text Layer
$txt->compress;

## Create standard font references. 
# westmj only use core fonts 
my $HelveticaBold = $pdf->corefont('Helvetica-Bold');
my $Georgia = $pdf->corefont('Georgia-Italic', -encode=>'latin1');
my $y = 740;
my $x = 100;

$txt->font($HelveticaBold, 14);           ## set font
$txt->translate($x,$y);                   ## set insert location
$txt->text_center("Helvetica Bold, 14");  ## insert text
$y-=20;

$txt->font($Georgia, 12);
$txt->translate($x,$y); 
$txt->text_center("Georgia, 12"); 
$y -= 20;

#$txt->font($BroadView, 12);            ## this works just like the corefonts.
#$txt->translate($x,$y); 
#$txt->text_center("BroadView, 12"); 
#$y -= 20;

$pdf->finishobjects($page,$txt);
$pdf->saveas;
$pdf->end();

open (OUT, "$$.test");
while (){print}
close OUT;	
}



sub make_pdf-03 {
	use PDF::API2::Simple;
 
my $pdf = PDF::API2::Simple->new( 
                                 file => 'output.pdf'
                                );
 
$pdf->add_font('VerdanaBold');
$pdf->add_font('Verdana');
$pdf->add_page();
 
$pdf->link( 'http://search.cpan.org', 'A Hyperlink',
            x => 350,
            y => $pdf->height - 150 );
 
for (my $i = 0; $i < 250; $i++) {
     my $text = "$i - All work and no play makes Jack a dull boy";
 
     $pdf->text($text, autoflow => 'on');
}
 
$pdf->save();
}

sub getLoggingTime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $nice_timestamp = sprintf ( "%04d%02d%02d_%02d-%02d-%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $nice_timestamp;
}