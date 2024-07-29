SHELL=/bin/bash

.PHONY: css-watch
css-watch:
	npm i && mkdir -p ../backend/priv/static && npx tailwindcss -i ./src/base.css -o ../backend/priv/static/style.css --watch

.PHONY: css-minify
css-minify:
	npm i && mkdir -p ../backend/priv/static && npx tailwindcss -i ./src/base.css -o ../backend/priv/static/style.css --minify