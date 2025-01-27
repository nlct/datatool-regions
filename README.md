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

The language support is distributed separately. Any setting that
depends on _both_ language and region should be supplied with the
applicable language bundle.

Further reading: [Localisation with datatool v3.0+](https://www.dickimaw-books.com/latex/tracklang/datatool-locale.shtml)

This material is subject to the LaTeX Project Public License.
See http://www.ctan.org/license/lppl1.3 for the details of that license.

https://www.dickimaw-books.com/
