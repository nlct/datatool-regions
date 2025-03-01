#  Region (Numeric) Support for datatool v3.0+ (datatool-regions)

Version %%VERSION%% (%%DATE%%)

Author: Nicola L. C. Talbot [dickimaw-books.com](https://www.dickimaw-books.com/)

Licence: LPPL

Home Page: https://github.com/nlct/datatool-regions

Required Packages:
[datatool](https://ctan.org/pkg/datatool) (3.0+),
[tracklang](https://ctan.org/pkg/tracklang) (1.6.4+)
 

The `datatool-regions` bundle provides the language-independent
region ldf files for the `datatool` package (v3.0+).
The `*.ldf` files should all be placed on TeX's path.

These files don't require any explicit loading. They will
automatically be input by `datatool-base.sty` (or relevant
supplementary package) if they are found and required by the
`tracklang` localisation settings. See the `datatool` v3.0+ 
and `tracklang` user manuals for further details.

The region files deal with defining (if applicable) the currency
symbol and switching to the region's currency in the region's hook.
Region files may additionally (if not dependent on the language) set
the number group and decimal characters, and provide functions for 
parsing numeric dates and times.

Note that `datatool-base.sty` deals with appending the region's hook to 
the applicable language captions hook, if available.

The language support is distributed separately. Any setting that
depends on _both_ language and region should be supplied with the
applicable language bundle. This may occur for regions with multiple
official languages, where the number formatting or date/time parsing
depends on the language within the region. For example, `datatool-english`
provides `datatool-en-CA.ldf` and `datatool-en-ZA.ldf` in addition
to `datatool-english.ldf`.

If a pre-3.0 version of `datatool` is installed, these ldf files
will be ignored.

Example:

    \documentclass{article}
    \usepackage[locales={en-GB}]{datatool-base}% v3.0
    \begin{document}
    Currency: \DTLdecimaltocurrency{12345.67}{\price}\price.
    
    \DTLmul\result{\price}{-0.5}\result.
    Data type: \DTLgetDataTypeName{\DTLdatumtype{\result}}.
    Numeric value: \DTLdatumvalue{\result}.
    \end{document}

If `datatool-regions` is correctly installed, the result will be:

 > Currency: £12,345.67.  
 > −£6,172.84. Data type: currency. Numeric value: -6172.835.

In most cases the language and region are not inter-connected.
This means that you would get the same result (in terms of the
formatting and parsing of the numbers and currency) for the above with
`locales={cy-GB}`, `locales={gd-GB}`, `locales={ga-GB}`,
`locales={sco-GB}`, or simply `locales={GB}`.

The source code is on GitHub at
[github.com/nlct/datatool-regions](https://github.com/nlct/datatool-regions).
If you want to add new region files, you can use the Perl script
`src/createregion.pl` in the GitHub repository. It's an
interactive command line script that doesn't take any arguments
and will create a region ldf file based on your responses.
You can then add the new ldf via a pull request.

See also:

 - [`datatool-english` (GitHub)](https://github.com/nlct/datatool-english)
 - [Localisation with datatool v3.0+](https://www.dickimaw-books.com/latex/tracklang/datatool-locale.shtml)

This material is subject to the LaTeX Project Public License.
See http://www.ctan.org/license/lppl1.3 for the details of that license.
