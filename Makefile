all: output/lab-handout.html

output/lab-handout.html: .resources/metadata.md README.md .resources/pandoc.css
	mkdir -p output
	cat .resources/metadata.md README.md | pandoc -s -f markdown+task_lists -t html5 --css .resources/pandoc.css --lua-filter=.resources/enable-checkbox.lua --embed-resources -o output/lab-handout.html

clean:
	rm -f output/*.html
	rmdir -p output 2>/dev/null || true