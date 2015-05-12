NAME=SplitShowDemo
OUTPUT_DIR=output

all: $(NAME).tex
	@echo "*******************************************"
	@mkdir -p $(OUTPUT_DIR)
	@pdflatex -output-directory=$(OUTPUT_DIR) $(NAME).tex
	@echo "*******************************************"

clean:
	-rm -f $(OUTPUT_DIR)/*
