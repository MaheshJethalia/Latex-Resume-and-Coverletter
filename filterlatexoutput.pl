#!/usr/bin/perl
###########################################################################
#   Copyright (C) 2008-2011 by Georg Martius <georg.martius@web.de>       #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################
#                                                                         #
#  This program filters the output of latex to make it more easier to     #
#  read, less verbose and suitable for emacs compile output parsing       #
#  Usage: latex pla.ps | filterlatexoutput.pl                             #
#                                                                         #
###########################################################################
# use strict;
$rv=0;
$warn = 0;
if ($ARGV[0]){
    if($ARGV[0] eq "-w"){ 
	$warn=1;
    }    
}

@LINES=<STDIN>;
@stack; # to hold the parenthese and the files since we are parsing a tree ((a.tex ...(b.tex ...) ... ))
# for each open ( we push a '#' to the stack and pop it at a closing ) 
# each tex file we find we push also to the stack

foreach my $l(@LINES){
    $firstopen=1;
    # we have to take care that multiple ( and ) can be on one line. We split the line
    #  first at the (. The first element is before the '(' (possible empty)
    foreach my $p (split('\(',$l)){
	if(!$firstopen){ # the first entry of the split is always before the (
	    #print "push # in $l";
	    push @stack, '#';
            #print "stack: " . join ("|", @stack) . "\n";           
	}
	$firstclose=1;
	foreach my $q (split('\)',$p)){
	    if(!$firstclose){ # the first entry of the split is always before the )
                # pop the '(' and a file if there is one
                # print "stack: " . join ("|", @stack) . "\n";
		$top = pop @stack; 
		#print "Pop: $top in  $l";                
		if(!($top eq '#')){
		    #print "Close: $top\n";
                    $top = pop @stack;
		    if(!($top eq '#')) { # assume to read '#'
                        print "Parsing error! read $top, expect #\n";
                    } 
		}
	    }

	    if( $q =~ /^([^\(]+?\.tex)/ || $q =~ /^([^\(]+?\.cls)/){
                $f = $1;
                chomp $f;
                #print "push $f \n";
                push @stack, $f;
                print "processing $f\n";
	    }
	    if( $l =~ /^LaTeX Warning: (.*)/ || ($warn && $l =~/^(.*full.*hbox.*)$/)){ 
                $warningfound=1;
                $warning=$1;
                # chomp $warning;
            }elsif($warningfound){
                if ($l =~ /^$/){ # end of warning
                    $warningfound = 0;
                    $file = lastfile(@stack);
                    if($warning =~ /input line (\d+)/){
                        $line = $1;
                        print "$file:$line: Warning: $warning";
                    }elsif($warning =~ /at lines (\d+)/){
                        $line = $1;
                        print "$file:$line: Warning: $warning";
                    }else{ 
                        print "Warning: $warning";   
                    }
                }else{
                    $warning = $warning . $l if(!($l =~ /^[ ]*\[\][ ]*$/)); 
                }
            }
	    if( $l =~ /^! (.*)/){	 
		$errorfound=1;
		$error=$1 . "\n";
	    }else{	                    
		if( $errorfound && $q =~ /^l\.(\d+)(.*)/){
		    $line=$1;
		    $error=$error . "\n    " . $2;
		    $rv++;
		} elsif ($errorfound) {
		    if( $q =~ /^\?.*/ ) {
			$file = lastfile(@stack);
			print "$file:$line: $error\n";
			$errorfound = 0;
		    }else{
			$error=$error . $q;		
		    }
		}

	    }
            $firstclose=0 if($firstclose);
	}
        $firstopen=0 if($firstopen);
	# print $l;
    }
}
if($errorfound){
    print "Error extraction problem! Probably you need to run latex without filterlatexoutput.pl\n";
    print "$file:$line: $error\n";
    exit 0;     
}


sub lastfile{
    do{
	$top = pop @_;
    } while($top eq '#');
    return $top;
}

exit $rv;
