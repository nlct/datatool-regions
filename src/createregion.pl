#!/usr/bin/perl

binmode STDOUT, ':utf8';
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);

my $region = &regex_prompt(qr/^[A-Z]{2}$/,
  "Enter the two-letter region code.",
  "The region code should consist of two uppercase letters (e.g. XY) and will identify the filename as 'datatool-XY.ldf' where XY is the region code.");

my $ldf = "datatool-${region}.ldf";

if (-e $ldf)
{
   unless (&yes_no_prompt("File `$ldf' already exists. Do you want to overwrite it?",
     "Enter 'Y' if you want to overwrite the file, otherwise enter 'n', which will exit this script. Alternatively, you can enter 'x' to exit."))
   {
      die "Exiting\n";
   }
}

my $hasNumChars = &yes_no_prompt(
 "Is the number formatting in $region consistent across the region? (That is, either the region only has one official language, or the number group and decimal characters do not depend on the language.)",
 "Enter Y if the number formatting for region ${region} does not depend on the language, otherwise enter n.");

my $numGroupChar = '';
my $decimalChar = '';

my $numGroupChar2 = '';
my $decimalChar2 = '';

if ($hasNumChars)
{
   print "An 'official' number style will be created. You may also add an unofficial style later.\n";

   my @numGroupCharPrompts = (
    "comma)\t\ta comma separator (e.g. 1,234,567)",
    "dot)\t\ta period separator (e.g. 1.234.567)",
    "space)\t\ta space separator (e.g. 1 234 567)",
    "thinspace)\ta thin-space separator for formatting, normal space allowed when parsing",
    "apos)\t\tan apostrophe separator (e.g. 1'234'567)",
    "underscore)\tan underscore separator (e.g. 1_234_567)",
    "middot)\t\ta mid-dot separator (e.g. 1·234·567)"
   );

   $numGroupChar = &choice_prompt(qw/^(?:comma|dot|space|thinspace|apos|underscore|middot)$/,
     \@numGroupCharPrompts,
    "For the official style, what symbol is used for the number group separator?",
    "Enter the punctuation character used to separate number groups. For example, a comma, period or space character.");

   my @decimalCharPrompts = (
    "comma)\ta comma (e.g. 1,23)",
    "dot)\ta baseline dot (e.g. 1.23)",
    "middot)\ta mid-dot (e.g. 1·23)"
   );

   $decimalChar = &choice_prompt(qw/^(comma|dot|middot)$/,
     \@decimalCharPrompts,
    "For the official style, what symbol is used for the decimal character?",
    "Enter the type of punctuation character used to for the decimal character. For example, a c'omma' for a comma or 'dot' for a period.");

   if (&yes_no_prompt("Would you also like to create an unoffical style?",
        "Enter 'Y' if you want to add an 'unofficial' option, otherwise enter 'n'."))
   {
      $numGroupChar2 = &choice_prompt(qw/^(?:comma|dot|space|thinspace|apos|underscore|middot)$/,
        \@numGroupCharPrompts,
       "For the unofficial style, what symbol is used for the number group separator?",
       "Enter the punctuation character used to separate number groups. For example, a comma, period or space character.");

      $decimalChar2 = &choice_prompt(qw/^(comma|dot|middot)$/,
        \@decimalCharPrompts,
       "For the unofficial style, what symbol is used for the decimal character?",
       "Enter the type of punctuation character used to for the decimal character. For example, a c'omma' for a comma or 'dot' for a period.");
   }
}

my %currency = (
  'code' => '',
  'symbol' => '',
  'label' => '',
  'command' => '',
  'strvar' => '',
  'prefix' => ''
);

my $currfmt = 'dtlcurrprefixfmt';

my @before_after = (
 'before) symbol before number',
 'after) symbol after number'
);

if (&choice_prompt(qr/^(?:before|after)$/,
     \@before_after,
     "Does the currency symbol come before or after the number?",
     "Enter 'before' if the symbol comes before the number or enter 'after' if the symbol comes after the number") 
   eq 'after')
{
   $currfmt = 'dtlcurrsuffixfmt';
}

my @cur_sym_sep_choices = (
  'none) no spacing',
  'thin-space) thin space',
  'space) normal space',
  'nbsp) non-breaking space'
);

my $curr_sym_sep = &choice_prompt(qr/^(?:none|thin-space|space|nbsp)$/,
   \@cur_sym_sep_choices,
  "What type of spacing should occur between the currency symbol (not the code) and number?",
  "Enter 'none' for no spacing."
 );


while ($currency{'symbol'} eq '')
{
   my $currencySym = &any_prompt(
     "What is the currency symbol? Type in the actual Unicode character or U+<hex> where <hex> is the hexadecimal code point.",
     "Enter the currency symbol (for example, \$ or £ ) or the codepoint. Type 'x' to exit.");

   my $currencySymCp='';

   if ($currencySym=~/^U\+([0-9A-Ea-e]+)$/)
   {
      $currencySymCp=hex($1);
      $currency{'symbol'} = chr($currencySymCp);
   }
   else
   {
      $currencySymCp=ord($currencySym);
      $currency{'symbol'} = $currencySym;
   }

   &lookup_currency($currencySymCp, \%currency);

   printf("Currency symbol '%s' (U+%X)\n", $currency{'symbol'}, $currencySymCp);

   if ($currency{'label'} eq '')
   {
      unless (&yes_no_prompt(
       sprintf("I don't recognise currency '%s' (U+%X). Do you still want to proceed?", $currency{'symbol'}, $currencySymCp),
        "If the currency symbol is correct, you will be prompted for further information. Otherwise enter 'n' to try again."))
      {
         $currency{'symbol'} = '';
         next;
      }
   }

   if ($currency{'label'} eq 'euro')
   {
      $currency{'code'} = 'EUR';
   }
   else
   {
      my $chr = 'X';

      unless ($currency{'label'} eq '')
      {
         $chr = uc(substr($currency{'label'}, 0, 1));
      }

      $currency{'code'} = &regex_prompt(qr/^[A-Z]{3}$/,
       sprintf("What is the three letter currency code for region '%s'? (For example, %s%s)",
         $region, $region, $chr),
       "The currency code should consist of three uppercase letters.");
   }

   if ($currency{'command'} eq '')
   {
      $currency{'command'} = &any_prompt(
       "What is the LaTeX command used to create the symbol $currency{'symbol'}? Type 'none' if there isn't one.",
       "Is there a command, such as \\textcurrency, available to produce the currency symbol? If there is, enter it. If not, just enter 'none'");
   }

   if ($currency{'prefix'} eq '')
   {
      $currency{'prefix'} = &yes_no_prompt(
    "Can the currency symbol be prefixed with the region code? (${region}$currency{'symbol'})",
    "A prefix for the symbol is not shown by default but, in order to disambiguate it from other regional currencies with the same symbol, the region code may be used as a prefix. If this doesn't make sense for the currency, for example, the currency is only applicable to region ${region}, then enter 'n'.");
   }
}

my $currencyDigits = &regex_prompt(qw/^\d*$/,
  "How many digits should currencies be rounded to? (Empty if no rounding.)",
  "If any currencies are formatted, should the decimal part be rounded? If so, enter the number of digits otherwise press return without entering anything.");

my $hasDateFormat = &yes_no_prompt(
  "Is the numeric date formatting in $region consistent across the region? (That is, either the region only has one official language, or the order of the day, month, and year is not dependent on the language.)",
  "The region support only deals with numeric dates, not dates that include month names or other textual elements. Enter Y if the numeric date format for region ${region} does not depend on the language, otherwise enter n.");

my $dateOrder = '';
my $dateSep = '';
my $timeSep = '';
my %timezones = ();

if ($hasDateFormat)
{
   my @dateOrderPrompts = (
    'ymd) year month day',
    'dmy) day month year',
    'mdy) month day year'
   );

   $dateOrder = &choice_prompt(qr/^(?:ymd|dmy|mdy)$/,
     \@dateOrderPrompts,
     "What order should the year, month and day be in for region ${region}?",
     "Enter ymd for year month day (for example, 2025/2/23), or dmy for day month year (for example, 23/2/2025), or mdy for month day year (for example, 2/23/2025)");

   my @dateSepPrompts = (
     "slash)\tslash '/' separator",
     "hyphen)\thyphen '-' separator",
     "dot)\tdot '.' separator",
     "none)\tskip temporal parsing code"
   );

   $dateSep = &choice_prompt(qr/^(?:slash|hyphen|dot|none)$/,
     \@dateSepPrompts,
     "What separator is the default for numeric dates?",
     "There is currently only support for slash, hyphen and dot. Enter 'none' to cancel the date/time parsing code.");

   if ($dateSep eq 'none')
   {
      $hasDateFormat = 0;
   }
   else
   {
      my @timeSepPrompts = (
        "colon)\tcolon ':' separator",
        "dot)\tdot ',' separator",
        "none)\tskip temporal parsing code"
      );

     $timeSep = &choice_prompt(qr/^(?:colon|dot|none)$/,
       \@timeSepPrompts,
       "What separator is the default for numeric times?",
       "There is currently only support for colon or dot. Enter 'none' to cancel the date/time parsing code.");

      if ($timeSep eq 'none')
      {
         $hasDateFormat = 0;
      }
      else
      {
         my $tzprompt = 'Do you want to provide any time zone mappings?';

         while (&yes_no_prompt($tzprompt,
              'Enter Y if you want to provide a time zone mapping or n otherwise'))
         {
            $tzprompt = 'Do you want to provide another time zone mapping?';

            my $timeZoneLabel = &any_prompt(
             "Enter the time zone label (e.g GMT or CET) or empty to cancel this mapping.",
             "Enter just the zone identifier. You will be prompted for the offset next.");

            if ($timeZoneLabel ne '')
            {
               my $timeZoneOffset = &regex_prompt(qw/^[+\-]\d{2}:\d{2}$/,
                "Enter the time zone offset, including sign, in the form hh:mm (e.g. +01:00).",
                "Make sure that you include the + or - sign and use two digits for both the hour and the minute");

               $timezones{$timeZoneLabel} = $timeZoneOffset;
            }
         }
      }
   }
}

open (my $fh, '>:encoding(UTF-8)', $ldf)
 or die "Couldn't open '$ldf' $!\n";

print "Writing $ldf\n";

print $fh <<"_END";
%\\section{datatool-${region}.ldf}\\label{sec:datatool-${region}}
% Support for region ${region}.
%    \\begin{macrocode}
\\TrackLangProvidesResource{${region}}%%FILEVERSION%%
%    \\end{macrocode}
% Switch on \\LaTeX3 syntax:
%    \\begin{macrocode}
\\ExplSyntaxOn 
%    \\end{macrocode}
%
%\\subsection{Numbers and Currency}
_END

if ($hasNumChars)
{
      print $fh <<"_END";
%Set the number group and decimal symbols for this region.
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_set_numberchars_official:
 {  
_END

   print $fh '  ';

   if ($numGroupChar eq 'thinspace')
   {
      print $fh "\\datatool_set_thinspace_group_decimal_char:";

      print $fh &get_variant($decimalChar), ' ';

      print $fh &get_param($decimalChar), "\n";
   }
   elsif ($numGroupChar eq 'apos')
   {
      print $fh "\\datatool_set_apos_group_decimal_char:";

      print $fh &get_variant($decimalChar), ' ';

      print $fh &get_param($decimalChar), "\n";
   }
   elsif ($numGroupChar eq 'underscore')
   {
      print $fh "\\datatool_set_underscore_group_decimal_char:";

      print $fh &get_variant($decimalChar), ' ';

      print $fh &get_param($decimalChar), "\n";
   }
   else
   {
      print $fh "\\datatool_set_numberchars:";

      print $fh &get_variant($numGroupChar);
      print $fh &get_variant($decimalChar);

      print $fh ' ', &get_param($numGroupChar);
      print $fh ' ', &get_param($decimalChar), "\n";
   } 
   print $fh <<"_END";
 }
%    \\end{macrocode}
_END

   if ($numGroupChar2 ne '' and $decimalChar2 ne '')
   {
      print $fh <<"_END";
%Unofficial style.
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_set_numberchars_unofficial:
 {  
_END

      print $fh '  ';

      if ($numGroupChar2 eq 'thinspace')
      {
         print $fh "\\datatool_set_thinspace_group_decimal_char:";

         print $fh &get_variant($decimalChar2), ' ';

         print $fh &get_param($decimalChar2), "\n";
      }
      elsif ($numGroupChar2 eq 'apos')
      {
         print $fh "\\datatool_set_apos_group_decimal_char:";

         print $fh &get_variant($decimalChar2), ' ';

         print $fh &get_param($decimalChar2), "\n";
      }
      elsif ($numGroupChar2 eq 'underscore')
      {
         print $fh "\\datatool_set_underscore_group_decimal_char:";

         print $fh &get_variant($decimalChar2), ' ';

         print $fh &get_param($decimalChar2), "\n";
      }
      else
      {
         print $fh "\\datatool_set_numberchars:";

         print $fh &get_variant($numGroupChar2);
         print $fh &get_variant($decimalChar2);

         print $fh ' ', &get_param($numGroupChar2);
         print $fh ' ', &get_param($decimalChar2), "\n";
      } 

   print $fh <<"_END";
 }
%    \\end{macrocode}
_END
   } 

print $fh <<"_END";
%Hook to set the number group and decimal characters for the region:
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetNumberChars
 {
   \\bool_if:NT \\l_datatool_region_set_numberchars_bool
    {
      \\datatool_${region}_set_numberchars_official:
    }
 }
%    \\end{macrocode}
_END
}
else
{
   print $fh <<"_END";
% NB the number group and decimal symbols for this region should be
% set in the language file \\filemeta{datatool-}{lang}{${region}.ldf} as they depend
% on both the language and region. Those files should be included in the applicable
% \\sty{datatool} language module.
% However, a region hook is still needed to support 
%\\verb|\\DTLsetup{numeric={region-number-chars}}| although it's not
%added to the language hook:
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetNumberChars
 {
   \\bool_if:NT \\l_datatool_region_set_numberchars_bool
    {
      \\tl_if_empty:NTF \\l_datatool_current_language_tl
       {
          \\datatool_locale_warn:nn { datatool-${region} }
           {
              No ~ current ~ language: ~ can't ~ set ~
              number ~ group ~ and ~ decimal ~ characters
           }
       }
       {
         \\cs_if_exist_use:cF
          { datatool \\l_datatool_current_language_tl ${region}SetNumberChars }
           {
             \\datatool_locale_warn:nn { datatool-${region} }
              {
                 No ~ support ~ for ~ locale ~
                 ` \\l_datatool_current_language_tl - ${region}': ~ can't ~ set ~
                 number ~ group ~ and ~ decimal ~ characters
              }
           }
       }
    }
 }
%    \\end{macrocode}
_END
}

print $fh <<"_END";
%How to format the position of the currency symbol in relation to the value.
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_currency_position:nn
 {
   \\${currfmt} { #1 } { #2 }
 }
%    \\end{macrocode}
%Separator between currency symbol and value.
%    \\begin{macrocode} 
\\tl_new:N \\l_datatool_${region}_sym_sep_tl
%    \\end{macrocode}
_END

if ($currency{'code'} eq 'EUR')
{
   print $fh <<"_END";
% The EUR currency is already defined by \\sty{datatool-base}, but we
% need to register the currency code with this region:
%    \\begin{macrocode}
\\datatool_register_regional_currency_code:nn { ${region} } { EUR }
%    \\end{macrocode}
% Provide a command to set the currency for this region (for use
% with any hook used when the locale changes).
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetCurrency
 {
   \\bool_if:NT \l_datatool_region_set_currency_bool
    {
      \\DTLsetdefaultcurrency { EUR }
_END

   unless ($currencyDigits eq '')
   {
      print $fh <<"_END";
%    \\end{macrocode}
%Number of digits that \\cs{DTLdecimaltocurrency} should round to:
%    \\begin{macrocode}
      \\renewcommand \\DTLCurrentLocaleCurrencyDP { ${currencyDigits} }
_END
   }

   print $fh <<"_END";
%    \\end{macrocode}
%Update EUR format to reflect current region style:
%    \\begin{macrocode}
      \\renewcommand \\DTLdefaultEURcurrencyfmt
         { \\datatool_${region}_currency_position:nn }
%    \\end{macrocode}
%Separator between symbol and value:
%    \\begin{macrocode}
      \\renewcommand \\dtlcurrfmtsymsep { \\l_datatool_${region}_sym_sep_tl }
    }
 }
%    \\end{macrocode}
_END
}
else
{
   print $fh <<"_END";
% Set the currency format for this region.
%    \\begin{macrocode}
\\newcommand \\datatool${region}currencyfmt [ 2 ]
 {
   \\datatool_${region}_currency_position:nn
    {
_END

   if ($currency{'prefix'})
   {
      print $fh "      \\datatool${region}symbolprefix { ${region} }\n";
   }

   print $fh <<"_END";
      #1
    }
    { #2 }
 }
%    \\end{macrocode}
_END

   if ($currency{'prefix'})
   {
      print $fh <<"_END";
%Prefix for symbol, if required.
%    \\begin{macrocode}
\\newcommand \\datatool${region}symbolprefix [ 1 ] { }
%    \\end{macrocode}
_END
   }

   if ($currency{'command'} eq '')
   {
     $currency{'command'} = $currency{'symbol'};
   }

   print $fh <<"_END";
% Define the currency symbols for this region.
%    \\begin{macrocode}
_END

   if ($currency{label} eq '')
   {
      print $fh <<"_END";
\\datatool_def_currency:nnnn
 { \\datatool${region}currencyfmt }
 { $currency{code} }
 { $currency{command} }
 { $currency{symbol} }
_END
   }
   else
   {
      if ($currency{'strval'} eq '')
      {
          $currency{'strval'} = "\\l_datatool_$currency{label}_tl";
      }

      print $fh <<"_END";
\\datatool_def_currency:nnnV
 { \\datatool${region}currencyfmt }
 { $currency{code} }
 { $currency{command} }
 $currency{strval}
_END
   }

   print $fh <<"_END";
%    \\end{macrocode}
% Register the currency code with this region:
%    \\begin{macrocode}
\\datatool_register_regional_currency_code:nn { ${region} } { $currency{code} }
%    \\end{macrocode}
% Provide a command to set the currency for this region (for use
% with any hook used when the locale changes).
% NB this should do nothing with
% \\verb|\\DTLsetup{region-currency=false}|
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetCurrency
 {
   \\bool_if:NT \\l_datatool_region_set_currency_bool
    {
      \\DTLsetdefaultcurrency { $currency{code} }
_END

   unless ($currencyDigits eq '')
   {
      print $fh <<"_END";
%    \\end{macrocode}
%Number of digits that \\cs{DTLdecimaltocurrency} should round to:
%    \\begin{macrocode}
      \\renewcommand \\DTLCurrentLocaleCurrencyDP { ${currencyDigits} }
_END
   }

      print $fh <<"_END";
%    \\end{macrocode}
%Separator between symbol and value:
%    \\begin{macrocode}
      \\renewcommand \\dtlcurrfmtsymsep { \\l_datatool_${region}_sym_sep_tl }
    }
 }
%    \\end{macrocode}
_END
}

print $fh "%\n%\\subsection{Date and Time Parsing}\n";

if ($hasDateFormat)
{
   my $dateInfo = $dateOrder;

   my $dateSepChar = '';

   if ($dateSep eq 'hyphen')
   {
      $dateSepChar = '-';
   }
   elsif ($dateSep eq 'slash')
   {
      $dateSepChar = '/';
   }
   elsif ($dateSep eq 'dot')
   {
      $dateSepChar = '.';
   }

   my %dateNames = (
     'd' => 'day',
     'm' => 'month',
     'y' => 'year'
   );

   $dateInfo =~s/([ymd])([ymd])([ymd])/$dateNames{$1}${dateSepChar}$dateNames{$2}${dateSepChar}$dateNames{$3}/;

   my $dateStyle = $dateOrder;

   $dateStyle =~s/y/yyyy/;
   $dateStyle =~s/m/mm/;
   $dateStyle =~s/d/dd/;

   print $fh <<"_END";
% This defaults to $dateInfo but may be changed with \\cs{DTLsetLocaleOptions}. For example:
%\\begin{dispListing}
%\\DTLsetLocaleOptions{${region}}{date-style=dmyyyy, date-variant=slash}
%\\end{dispListing}
%An appropriate language file will need to also be installed to
%parse dates containing month names or day of week names.
%
%Provide a way to configure parsing style.
%    \\begin{macrocode}
\\tl_new:N \\l__datatool_${region}_datevariant_tl
\\tl_set:Nn \\l__datatool_${region}_datevariant_tl { $dateSep }
%    \\end{macrocode}
%NB These token lists are used to form command names. The following is not 
%a format string.
%    \\begin{macrocode}
\\tl_new:N \\l__datatool_${region}_datestyle_tl
\\tl_set:Nn \\l__datatool_${region}_datestyle_tl { ${dateStyle} }
\\tl_new:N \\l__datatool_${region}_timevariant_tl
\\tl_set:Nn \\l__datatool_${region}_timevariant_tl { $timeSep }
%    \\end{macrocode}
%
%Each parsing command defined below has final \\marg{true} and \\marg{false}
%arguments (\\code{TF}). These are used if parsing was successful (true) or if
%parsing failed (false). The internal commands used by
%\\sty{datatool-base} have no need for solo branches (only \\code{T} or only
%\\code{F}) so these commands are simply defined with \\verb|\\cs_new:Nn|
%not as conditionals.
%
%\\subsubsection{Time Stamp Parsing}
%Use command
%\\begin{definition}
%\\cs{datatool\\_}\\meta{date-style}\\verb|_hhmmss_tz_parse_timestamp:nnNnTF|
%\\end{definition}
%with date regular expression 
%\\begin{definition}
%\\cs{c\\_datatool\\_}\\meta{date-variant}\\verb|_|\\meta{date-style}\\verb|_date_regex|
%\\end{definition}
%and time regular expression
%\\begin{definition}
%\\cs{c\\_datatool\\_}\\meta{time-variant}\\verb|_hhmmss_time_regex|
%\\end{definition}
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_parse_timestamp:NnTF
 {
   \\cs_if_exist:cTF
     {
       datatool_
       \\l__datatool_${region}_datestyle_tl
       _hhmmss_tz_parse_timestamp:ccNnTF
     }
    {
      \\cs_if_exist:cTF
       {
          c_datatool_
          \\l__datatool_${region}_datevariant_tl
          _
          \\l__datatool_${region}_datestyle_tl
          _date_regex
       }
       {
         \\cs_if_exist:cTF
          {
            c_datatool_
            \\l__datatool_${region}_timevariant_tl
            _hhmmss_time_regex
          }
          {
            \\use:c
             {
               datatool_
              \\l__datatool_${region}_datestyle_tl
              _hhmmss_tz_parse_timestamp:ccNnTF
             }
             {
               c_datatool_
               \\l__datatool_${region}_datevariant_tl
               _
               \\l__datatool_${region}_datestyle_tl
               _date_regex
             }
             {
               c_datatool_
               \\l__datatool_${region}_timevariant_tl
               _hhmmss_time_regex
             }
              #1 { #2 } { #3 } { #4 }
          }
          {
            \\datatool_warn_check_head_language_empty:Vnnn
             \\l__datatool_${region}_timevariant_tl
             { datatool-${region} }
             {
               No ~ language ~ support ~ for ~ time ~ variant ~
               ` \\exp_args:Ne \\tl_tail:n { \\l__datatool_${region}_timevariant_tl } '
             }
             {
              No ~ support ~ for ~ time ~ variant ~
              ` \\l__datatool_${region}_timevariant_tl '
             }
            #4
          }
       }
       {
         \\datatool_warn_check_head_language_empty:Vnnn
           \\l__datatool_${region}_datevariant_tl
           { datatool-${region} }
           {
             No ~ language ~ support ~ for ~ date ~ style ~
              ` \\l__datatool_${region}_datestyle_tl '
           }
           {
             No ~ support ~ for ~ date ~ style ~
             ` \\l__datatool_${region}_datestyle_tl ' ~ with ~
             variant ~
             ` \\l__datatool_${region}_datevariant_tl '
           }
         #4
       }
    }
    {
      \\datatool_locale_warn:nn { datatool-${region} }
       {
          No ~ support ~ for ~ date ~ style ~
          ` \\l__datatool_${region}_datestyle_tl '
       }
      #4
    }
 }
%    \\end{macrocode}
%
%\\subsubsection{Date Parsing}
%Use command \\cs{datatool\\_}\\meta{style}\\verb|_parse_date:NNnTF|
%with regular expression 
%\\begin{definition}
%\\cs{c\\_datatool\\_}\\meta{variant}\\verb|_anchored_|\\meta{style}\\verb|_date_regex|
%\\end{definition}
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_parse_date:NnTF
 {
   \\cs_if_exist:cTF
     {
       datatool_
       \\l__datatool_${region}_datestyle_tl
       _parse_date:NNnTF
     }
    {
      \\cs_if_exist:cTF
       {
         c_datatool_
         \\l__datatool_${region}_datevariant_tl
         _anchored_
         \\l__datatool_${region}_datestyle_tl
         _date_regex
       }
       {
         \\exp_args:cc
         {
           datatool_
           \\l__datatool_${region}_datestyle_tl
           _parse_date:NNnTF
         }
         {
           c_datatool_
           \\l__datatool_${region}_datevariant_tl
           _anchored_
           \\l__datatool_${region}_datestyle_tl
           _date_regex
         }
          #1 { #2 } { #3 } { #4 }
       }
       {
         \\datatool_warn_check_head_language_empty:Vnnn
          \\l__datatool_${region}_datevariant_tl 
          { datatool-${region} }
          {
            No ~ language ~ support ~ for ~ date ~ style ~
             ` \\l__datatool_${region}_datestyle_tl '
          }
          {
             No ~ support ~ for ~ date ~ style ~
             ` \\l__datatool_${region}_datestyle_tl ' ~ with ~
             variant ~
             ` \\l__datatool_${region}_datevariant_tl '
          }
         #4
       }
    }
    {
      \\datatool_locale_warn:nn { datatool-${region} }
       {
          No ~ support ~ for ~ date ~ style ~
          ` \\l__datatool_${region}_datestyle_tl '
       }
      #4
    }
 }
%    \\end{macrocode}
%
%\\subsubsection{Time Parsing}
%Use command \\cs{datatool\\_}\\meta{style}\\verb|_parse_time:NNnTF|
%with regular expression 
%\\begin{definition}
%\\cs{c\\_datatool\\_}\\meta{variant}\\verb|_anchored_|\\meta{style}\\verb|_time_regex|
%\\end{definition}
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_parse_time:NnTF
 {
   \\cs_if_exist:cTF
    {
      c_datatool_
      \\l__datatool_${region}_timevariant_tl
      _anchored_hhmmss_time_regex
    }
    {
      \\datatool_hhmmss_parse_time:cNnTF
       {
        c_datatool_
        \\l__datatool_${region}_timevariant_tl
        _anchored_hhmmss_time_regex
       }
        #1 { #2 } { #3 } { #4 }
    }
    {
      \\datatool_warn_check_head_language_empty:Vnnn
        \\l__datatool_${region}_timevariant_tl 
        { datatool-${region} }
        {
           No ~ language ~ support ~ for ~ time ~ variant ~
           ` \\exp_args:Ne \\tl_tail:n { \\l__datatool_${region}_timevariant_tl } '
        }
        {
           No ~ support ~ for ~ time ~ variant ~
           ` \\l__datatool_${region}_timevariant_tl '
        }
      #4
    }
 }
%    \\end{macrocode}
%
%\\subsubsection{Time Zone Mappings}
_END

   if (%timezones)
   {
      print $fh <<"_END";
%Define time zone mapping command for this region:
%    \\begin{macrocode}
\\cs_new:Nn \\datatool_${region}_get_timezone_map:n
 {
   \\datatool_region_get_timezone_map:n { ${region} / #1 }
 }
%    \\end{macrocode}
%Define time zone IDs for this region (one-way map from ID to offset):
%    \\begin{macrocode}
_END

      foreach my $tz (keys %timezones)
      {
         print $fh "\\datatool_region_set_timezone_map:nn { ${region} / ${tz} } { $timezones{$tz} }\n";
      }

      print $fh "%    \\end{macrocode}\n";
   }
   else
   {
      print $fh "No time zone mappings provided.\n";
   }
}
else
{
   print $fh "%Not provided\n";
}

print $fh <<"_END";
%
%\\subsection{Options}
%Define options for this region:
%    \\begin{macrocode}
\\datatool_locale_define_keys:nn { ${region} }
 {
_END

if ($hasNumChars)
{
   print $fh "   number-style .choices:nn =\n    { official";

   unless ($numGroupChar2 eq '')
   {
      print $fh ", unofficial";
   }

   print $fh " }\n";

print $fh <<"_END";
    {
      \\exp_args:NNe \\renewcommand
        \\datatool${region}SetNumberChars
         {
           \\exp_not:N \\bool_if:NT
            \\exp_not:N \\l_datatool_region_set_numberchars_bool
             {
               \\exp_not:c { datatool_${region}_set_numberchars_ \\l_keys_choice_tl : }
             }
         }
      \\tl_if_eq:NnT \\l_datatool_current_region_tl { ${region} }
       {
         \\datatool${region}SetNumberChars
       }
    } ,
_END

}
else
{
print $fh <<"_END";
   number-style .code:n =
    { 
      \\keys_if_exist:nnTF
         { datatool / locale / \\l_datatool_current_language_tl - ${region} }
         { number-style }
       {
         \\keys_set:nn
          { datatool / locale / \\l_datatool_current_language_tl - ${region} }
          { number-style = { #1 } }
       }
       {
         \\datatool_locale_warn:nn { datatool-${region} }
          {
            No ~ number-style ~ available ~ for ~ current ~ locale ~
            (additional ~ language ~ module ~ may ~ need ~ installing)
          }
       }
    } ,
_END
}

print $fh <<"_END";
%    \\end{macrocode}
% Currency symbol before or after value:
%    \\begin{macrocode}
   currency-symbol-position .choice: ,
   currency-symbol-position / before .code:n = 
    {
      \\cs_set_eq:NN \\datatool_${region}_currency_position:nn \\dtlcurrprefixfmt
    } ,
   currency-symbol-position / after .code:n =
    {
      \\cs_set_eq:NN \\datatool_${region}_currency_position:nn \\dtlcurrsuffixfmt
    } ,
_END

if ($currency{'prefix'})
{
   print $fh <<"_END";
%    \\end{macrocode}
% Should the currency symbol be prefixed with the region code:
%    \\begin{macrocode}
   currency-symbol-prefix .choice: ,
   currency-symbol-prefix / false .code:n =
    {
      \\cs_set_eq:NN \\datatool${region}symbolprefix \\use_none:n
    } ,
   currency-symbol-prefix / true .code:n =
    {
      \\cs_set_eq:NN
       \\datatool${region}symbolprefix
       \\datatool_currency_symbol_region_prefix:n
    } ,
   currency-symbol-prefix .default:n = { true } ,
_END
}

print $fh <<"_END";
%    \\end{macrocode}
% Separator between currency symbol (not code) and value:
%    \\begin{macrocode}
   currency-symbol-sep .choice: ,
   currency-symbol-sep / none .code:n = 
    {
      \\tl_clear:N \\l_datatool_${region}_sym_sep_tl
    } ,
   currency-symbol-sep / thin-space .code:n = 
    {
      \\tl_set:Nn \\l_datatool_${region}_sym_sep_tl { \\, }
    } ,
   currency-symbol-sep / space .code:n = 
    {
      \\tl_set:Nn \\l_datatool_${region}_sym_sep_tl { ~ }
    } ,
   currency-symbol-sep / nbsp .code:n =
    {
      \\tl_set:Nn \\l_datatool_${region}_sym_sep_tl { \\nobreakspace }
    } ,
   currency-symbol-sep . initial:n = { $curr_sym_sep } ,
_END

if ($hasDateFormat)
{
print $fh <<"_END";
%    \\end{macrocode}
% Date and time styles:
%    \\begin{macrocode}
   date-style .choice: ,
   date-style / dmyyyy .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { ddmmyyyy }
    } ,
   date-style / mdyyyy .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { mmddyyyy }
    } ,
   date-style / yyyymd .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { yyyymmdd }
    } ,
   date-style / dmyy .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { ddmmyy }
    } ,
   date-style / mdyy .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { mmddyy }
    } ,
   date-style / yymd .code: n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datestyle_tl { yymmdd }
    } ,
   date-variant .choice: ,
   date-variant / slash .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datevariant_tl { slash }
    } ,
   date-variant / hyphen .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datevariant_tl { hyphen }
    } ,
   date-variant / dot .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datevariant_tl { dot }
    } ,
   date-variant / dialect .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_datevariant_tl
        { \\l_datatool_current_language_tl }
    } ,
   time-variant .choice: ,
   time-variant / colon .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_timevariant_tl { colon }
    } ,
   time-variant / dot .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_timevariant_tl { dot }
    } ,
   time-variant / dialect .code:n =
    {
      \\tl_if_eq:NnTF \\l__datatool_${region}_timevariant_tl { dot }
       {
         \\tl_set:Nn \\l__datatool_${region}_timevariant_tl
          { \\l_datatool_current_language_tl _dot }
       }
       {
         \\tl_if_in:NnF
           \\l__datatool_${region}_timevariant_tl
            { \\l_datatool_current_language_tl }
          {
            \\tl_set:Nn \\l__datatool_${region}_timevariant_tl
             { \\l_datatool_current_language_tl _colon }
          }
       }
    } ,
   time-variant / dialect-colon .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_timevariant_tl
        { \\l_datatool_current_language_tl _colon }
    } ,
   time-variant / dialect-dot .code:n =
    {
      \\tl_set:Nn \\l__datatool_${region}_timevariant_tl
        { \\l_datatool_current_language_tl _dot }
    } ,
_END
}

print $fh <<"_END";
 }
%    \\end{macrocode}
%
%\\subsection{Hooks}
_END

if ($hasDateFormat)
{
   print $fh <<"_END";
%Command to update temporal parsing commands for this region:
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetTemporalParsers
 {
   \\renewcommand \\DTLCurrentLocaleParseTimeStamp
    { \\datatool_${region}_parse_timestamp:NnTF }
   \\renewcommand \\DTLCurrentLocaleParseDate
    { \\datatool_${region}_parse_date:NnTF }
   \\renewcommand \\DTLCurrentLocaleParseTime 
    { \\datatool_${region}_parse_time:NnTF }
_END

   if (%timezones)
   {
      print $fh <<"_END";
   \\let
    \\DTLCurrentLocaleGetTimeZoneMap
    \\datatool_${region}_get_timezone_map:n
_END
   }

   print $fh <<"_END";
 }
%    \\end{macrocode}
%Set temporal formatting commands for this region. Currently this
%just resets to the default, but may change in future.
%Note that the defaults test if the applicable \\sty{datetime2}
%command is available and will fallback on ISO if not defined.
%Bear in mind that the default style for \\sty{datetime2} is
%\\texttt{iso} so there won't be a noticeable difference unless the
%\\sty{datetime2} regional setting is on.
%    \\begin{macrocode}
\\newcommand \\datatool${region}SetTemporalFormatters
 {
   \\let
    \\DTLCurrentLocaleFormatDate
    \\datatool_default_date_fmt:nnnn
   \\let
    \\DTLCurrentLocaleFormatTime
    \\datatool_default_time_fmt:nnn
   \\let
    \\DTLCurrentLocaleFormatTimeZone
    \\datatool_default_timezone_fmt:nn
   \\let
    \\DTLCurrentLocaleFormatTimeStampNoZone
    \\datatool_default_timestamp_fmt:nnnnnnn
   \\let
    \\DTLCurrentLocaleFormatTimeStampWithZone
    \\datatool_default_timestamp_fmt:nnnnnnnnn
   \\renewcommand \\DTLCurrentLocaleTimeStampFmtSep { ~ }
 }
%    \\end{macrocode}
%
_END
}

print $fh <<"_END";
%
%Command to update currency and temporal parsing commands for this region:
%    \\begin{macrocode}
\\newcommand \\DTL${region}LocaleHook
 {
_END

   if ($hasNumChars)
   {
      print $fh "  \\datatool${region}SetNumberChars\n";
   }

print $fh <<"_END";
  \\datatool${region}SetCurrency
_END

   if ($hasDateFormat)
   {
print $fh <<"_END";
  \\datatool${region}SetTemporalParsers
  \\datatool${region}SetTemporalFormatters
_END
   }

print $fh <<"_END";
%    \\end{macrocode}
%Allow language files to reference the region:
%    \\begin{macrocode}
  \\tl_set:Nn \\l_datatool_current_region_tl { ${region} }
 }
%    \\end{macrocode}
%
% Finished with \\LaTeX3 syntax.
%    \\begin{macrocode}
\\ExplSyntaxOff
%    \\end{macrocode}
%Note that the hook is added to the captions by \\sty{datatool-base}
%not by the region file.
_END

close $fh;

print "Please check '$ldf' and make any necessary modifications.\n";

sub get_variant{
   my ($option) = @_;

   if ($option eq 'middot')
   {
      return 'V';
   }
   else
   {
      return 'n';
   }
}

sub get_param{
   my ($option) = @_;

   if ($option eq 'middot')
   {
      return '\\l_datatool_middot_tl';
   }
   elsif ($option eq 'dot')
   {
      return '{ . }';
   }
   elsif ($option eq 'comma')
   {
      return '{ , }';
   }
   else
   {
      return '{ ~ }';
   }
}

sub choice_prompt{
   my ($regexp, $choices, $msg, $help) = @_;

   print &word_wrapped($msg), "\n\n";
   print "Type ? for help or x to exit.\n\n";

   my $result = '';

   while ($result eq '')
   {
      for (my $i = 0; $i < @$choices; $i++)
      {
         print $choices->[$i], "\n";
      }

      print "?) help\n";
      print "x) exit\n";
      print "> ";

      $_ = <STDIN>;
      chomp;

      if (/$regexp/)
      {
         $result = $_;
      }
      elsif ($_ eq '?')
      {
         print &word_wrapped($help), "\n\n";
      }
      elsif ($_ eq 'x')
      {
        exit;
      }
      else
      {
         print "Invalid response '$_' (type ? for help)\n";
      }
   }

   $result;
}

sub regex_prompt{
   my ($regexp, $msg, $help) = @_;

   print &word_wrapped($msg), "\n\n";
   print "Type ? for help or x to exit.\n\n";

   my $result = '';

   while ($result eq '')
   {
      print "> ";

      $_ = <STDIN>;
      chomp;

      if (/$regexp/)
      {
         $result = $_;
      }
      elsif ($_ eq '?')
      {
         print &word_wrapped($help), "\n\n";
      }
      elsif ($_ eq 'x')
      {
        exit;
      }
      else
      {
         print "Invalid response '$_' (type ? for help)\n";
      }
   }

   $result;
}

sub yes_no_prompt{
   my ($msg, $help) = @_;

   print &word_wrapped($msg), "\n\n";

   my $result = '';

   while ($result eq '')
   {
      print "Y) yes\n";
      print "n) no\n";
      print "?) help\n";
      print "x) exit\n";
      print "> ";

      $_ = <STDIN>;
      chomp;

      if ($_ eq 'Y')
      {
         $result = 1;
      }
      elsif ($_ eq 'n')
      {
         $result = 0;
      }
      elsif ($_ eq '?')
      {
         print &word_wrapped($help), "\n\n";
      }
      elsif ($_ eq 'x')
      {
        exit;
      }
      else
      {
         print "Invalid response '$_'.\n";
      }
   }

   $result;
}

sub any_prompt{
   my ($msg, $help) = @_;

   print &word_wrapped($msg), "\n\n";

   my $result = '';

   while ($result eq '')
   {
      print "Enter response or:\n";
      print "?) help\n";
      print "x) exit\n";
      print "> ";

      $_ = <STDIN>;
      chomp;

      if ($_ eq '?')
      {
         print &word_wrapped($help), "\n\n";
      }
      elsif ($_ eq 'x')
      {
        exit;
      }
      else
      {
         $result = $_;
      }
   }

   $result;
}

sub word_wrapped{

  if (length($_[0]) > 80)
  {
     $_[0] .= ' ';
     $_[0] =~s/(?:.{1,79}\S|\S+)\K\s+/\n/g;
  }

  $_[0]=~s/\s+$//;

  $_[0];
}

sub lookup_currency{
   my ($cp, $currency) = @_;

   if ($cp == 0x24)
   {
      $currency->{'label'} = 'dollar';
      $currency->{'command'} = '\\$';
      $currency->{'strval'} = '\\c_dollar_str';
   }
   elsif ($cp == 0xA3)
   {
      $currency->{'label'} = 'pound';
      $currency->{'command'} = '\\pounds';
   }
   elsif ($cp == 0xA5)
   {
      $currency->{'label'} = 'yen';
      $currency->{'command'} = '\\textyen';
   }
   elsif ($cp == 0x20A1)
   {
      $currency->{'label'} = 'colonsign';
      $currency->{'command'} = '\\textcolonmonetary';
   }
   elsif ($cp == 0x0E3F)
   {
      $currency->{'label'} = 'baht';
      $currency->{'command'} = '\\textbaht';
   }
   elsif ($cp == 0x20A2)
   {
      $currency->{'label'} = 'cruzerio';
   }
   elsif ($cp == 0x20A4)
   {
      $currency->{'label'} = 'lira';
      $currency->{'command'} = '\\textlira';
   }
   elsif ($cp == 0x20A6)
   {
      $currency->{'label'} = 'naira';
      $currency->{'command'} = '\\textnaira';
   }
   elsif ($cp == 0x20A9)
   {
      $currency->{'label'} = 'won';
      $currency->{'command'} = '\\textwon';
   }
   elsif ($cp == 0x20AA)
   {
      $currency->{'label'} = 'shekel';
   }
   elsif ($cp == 0x20AB)
   {
      $currency->{'label'} = 'dong';
      $currency->{'command'} = '\\textdong';
   }
   elsif ($cp == 0x20AC)
   {
      $currency->{'label'} = 'euro';
      $currency->{'command'} = '\\texteuro';
      $currency->{'prefix'} = 0;
   }
   elsif ($cp == 0x20AD)
   {
      $currency->{'label'} = 'kip';
   }
   elsif ($cp == 0x20AE)
   {
      $currency->{'label'} = 'tugrik';
   }
   elsif ($cp == 0x20AF)
   {
      $currency->{'label'} = 'drachma';
   }
   elsif ($cp == 0x20B1)
   {
      $currency->{'label'} = 'peso';
      $currency->{'command'} = '\\textpeso';
   }
   elsif ($cp == 0x20B2)
   {
      $currency->{'label'} = 'guarani';
      $currency->{'command'} = '\\textguarani';
   }
   elsif ($cp == 0x20B4)
   {
      $currency->{'label'} = 'hryvnia';
   }
   elsif ($cp == 0x20B5)
   {
      $currency->{'label'} = 'cedi';
   }
   elsif ($cp == 0x20B8)
   {
      $currency->{'label'} = 'tenge';
   }
   elsif ($cp == 0x20B9)
   {
      $currency->{'label'} = 'indianrupee';
   }
   elsif ($cp == 0x20BA)
   {
      $currency->{'label'} = 'turkishlira';
   }
   elsif ($cp == 0x20BC)
   {
      $currency->{'label'} = 'manat';
   }
   elsif ($cp == 0x20BD)
   {
      $currency->{'label'} = 'ruble';
   }
   elsif ($cp == 0x20BE)
   {
      $currency->{'label'} = 'lari';
   }
   elsif ($cp == 0x20BF)
   {
      $currency->{'label'} = 'bitcoin';
   }
   elsif ($cp == 0x20C0)
   {
      $currency->{'label'} = 'som';
   }
}

1;
