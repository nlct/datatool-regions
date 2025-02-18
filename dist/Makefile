ldfs=../src/datatool-CA.ldf \
../src/datatool-GB.ldf \
../src/datatool-ZA.ldf

datatool-regions.zip	: datatool-regions.dtx datatool-regions.ins \
	datatool-regions.pdf README.md DEPENDS.txt
	mkdir -p datatool-regions
	cp datatool-regions.{dtx,ins,pdf} README.md DEPENDS.txt datatool-regions
	zip --exclude="*.swp" -r datatool-regions.zip datatool-regions

datatool-regions.pdf	: datatool-regions.dtx datatool-GB.ldf
	pdflatex datatool-regions.dtx
	makeindex -s gind.ist datatool-regions.idx
	makeindex -s gglo.ist -o datatool-regions.gls datatool-regions.glo
	pdflatex datatool-regions.dtx
	makeindex -s gind.ist datatool-regions.idx
	makeindex -s gglo.ist -o datatool-regions.gls datatool-regions.glo
	pdflatex datatool-regions.dtx
	pdflatex datatool-regions.dtx

datatool-GB.ldf	: datatool-regions.dtx datatool-regions.ins
	latex datatool-regions.ins

datatool-regions.dtx	: ../src/datatool-regions.tex ../src/version.txt $(ldfs)
	cd ../src; makedtx -author "Nicola Talbot" -section "chapter" \
	-src "(datatool-[A-Z]{2}\.ldf)\Z=>\1" \
	-doc datatool-regions.tex datatool-regions
	cp2dist -f ../src/version.txt ../src/datatool-regions.{dtx,ins} .
	rm -f ../src/datatool-regions.{dtx,ins}

README.md	: ../src/README.md
	cp2dist -f ../src/version.txt ../src/README.md .

clean	:
	\rm -f *.ldf *.out *.log *.aux *.pdf *.dtx *.ins *.ind *.idx *.ilg *.glo *.gls *.glg *.hd README.md
	\rm -f datatool-regions.zip
