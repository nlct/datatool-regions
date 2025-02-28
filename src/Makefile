ldfs=datatool-CA.ldf \
datatool-GB.ldf \
datatool-ZA.ldf

pdflatex=pdflatex-dev

all	: test-GB.pdf test-CA.pdf test-ZA.pdf test-CA+GB.pdf

test-GB.pdf	: test-GB.tex $(ldfs)
	$(pdflatex) test-GB.tex

test-CA.pdf	: test-CA.tex $(ldfs)
	$(pdflatex) test-CA.tex

test-ZA.pdf	: test-ZA.tex $(ldfs)
	$(pdflatex) test-ZA.tex

test-CA+GB.pdf	: test-CA+GB.tex $(ldfs)
	$(pdflatex) test-CA+GB.tex

clean	:
	\rm -f *.out *.pdf *.log *.aux
