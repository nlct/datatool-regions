# datatool-regions
Regional support for datatool.sty v3.0+

As from version 3.0, the `datatool` package will provide
localisation support (via the [`tracklang`](https://ctan.org/pkg/tracklang) package).
The `datatool-regions` bundle provides the language-independent
region ldf files.

The region files deal with defining (if applicable) the currency
symbol and switching to the region's currency in the captions hook.
Region files may additionally (if not dependent on the language) set
the number group and decimal characters and parsing numeric dates
and times.

The language support is distributed separately (except for
`datatool-undetermined.ldf` which is supplied with `datatool` v3.0+). Any setting that
depends on _both_ language and region should be supplied with the
applicable language bundle. This may occur for regions with multiple
official languages, where the number formatting or date/time parsing
depends on the language within the region. For example, 
[`datatool-english`](https://github.com/nlct/datatool-english)
provides `datatool-en-CA.ldf` and `datatool-en-ZA.ldf` in addition
to `datatool-english.ldf`.

If a pre-3.0 version of `datatool` is installed, these ldf files
will be ignored.

Example:
```latex
\documentclass{article}
\usepackage[locales={en-GB}]{datatool-base}% v3.0
\begin{document}
Currency: \DTLdecimaltocurrency{1234.56}{\result}\result.
\end{document}
```
If `datatool-regions` is correctly installed, the result will be:

 > Currency: £1,234.56.

In most cases the language and region are not inter-connected.
This means that you would get the same result for the above with
`locales={cy-GB}`, `locales={gd-GB}`, `locales={ga-GB}`,
`locales={sco-GB}`, or simply `locales={GB}.`

**Note:** bear in mind that if `tracklang` can't determine the
applicable dialect label for the captions hook, the settings may not
be applied when the language changes in multilingual documents.
In this case, you can either load `tracklang` before `datatool` and
set up the appropriate mappings or just add the applicable commands
to the relevant captions hook.

If you want to add new region files, you can use the Perl script
`src/createregion.pl`. It's an interactive command line script that doesn't take
any arguments. At each prompt you can type `?` for further
information or `x` to exit. The file is only created after all
information is supplied, so if you exit early no file will be
created.

Further reading: [Localisation with datatool v3.0+](https://www.dickimaw-books.com/latex/tracklang/datatool-locale.shtml)

This material is subject to the LaTeX Project Public License.
See http://www.ctan.org/license/lppl1.3 for the details of that license.

https://www.dickimaw-books.com/
