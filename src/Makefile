ldfs=datatool-AU.ldf \
datatool-BE.ldf \
datatool-CA.ldf \
datatool-FK.ldf \
datatool-GB.ldf \
datatool-GG.ldf \
datatool-GI.ldf \
datatool-IE.ldf \
datatool-IM.ldf \
datatool-JE.ldf \
datatool-NZ.ldf \
datatool-US.ldf \
datatool-ZA.ldf

pdflatex=pdflatex-dev

all	: test-GB.pdf test-CA.pdf test-ZA.pdf test-CA+GB.pdf \
	test-US.pdf test-IE.pdf

test-GB.pdf	: test-GB.tex $(ldfs)
	$(pdflatex) test-GB.tex

test-CA.pdf	: test-CA.tex $(ldfs)
	$(pdflatex) test-CA.tex

test-ZA.pdf	: test-ZA.tex $(ldfs)
	$(pdflatex) test-ZA.tex

test-CA+GB.pdf	: test-CA+GB.tex $(ldfs)
	$(pdflatex) test-CA+GB.tex

test-IE.pdf	: test-IE.tex $(ldfs)
	$(pdflatex) test-IE.tex

test-US.pdf	: test-US.tex $(ldfs)
	$(pdflatex) test-US.tex

clean	:
	\rm -f *.out *.pdf *.log *.aux
