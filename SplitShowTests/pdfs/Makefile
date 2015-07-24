TEX=$(wildcard *.tex)
PDF=$(TEX:.tex=.pdf)
OUTPUT_DIR=output

all: $(PDF)

%.pdf: %.tex
	@echo "*******************************************"
	@mkdir -p $(OUTPUT_DIR)
	@pdflatex -output-directory=$(OUTPUT_DIR) $<
	@echo "*******************************************"

clean:
	-rm -f $(OUTPUT_DIR)/*
