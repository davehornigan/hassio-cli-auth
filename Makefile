BASHLY=docker run --rm -it --user $(shell id -u):$(shell id -g) --volume "$(shell pwd):/app" dannyben/bashly

bashly:
	${BASHLY}

generate:
	${BASHLY} generate
