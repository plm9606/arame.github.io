make local:
	bundle exec jekyll s

make post:
	echo "Create new post ...";
	sh ./create_post.sh
	echo "Done!";