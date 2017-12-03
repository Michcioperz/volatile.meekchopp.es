#!/bin/bash
GENERATOR_VERSION=`git log -n 1 --pretty=format:%h -- build.sh`
WEBSITE_ROOT=https://volatile.meekchopp.es/
echo "Creating directory structure"
mkdir -p _site
mkdir -p _site/posts
LATEST_CHANGED=""
for post in posts/*.markdown
do
  POST_PREFIX=${post%.markdown}
  POST_ID=${POST_PREFIX#posts/}
  LAST_CHANGED=`git log -n 1 --pretty=format:%aI -- ${post}`
  FIRST_CHANGED=$(git log --pretty=format:%aI -- ${post} | tail -n 1)
  echo "Preparing post id ${POST_ID} from ${LAST_CHANGED}"
  if [ "$LATEST_CHANGED" \< "$LAST_CHANGED" ]; then
    LATEST_CHANGED="${LAST_CHANGED}"
  fi
  cp $post _site/$post
  cmark --to html --smart $post > _site/${POST_PREFIX}.html
  cat > _site/${POST_PREFIX}.xml <<EOF
  <entry>
    <id>${WEBSITE_ROOT}${POST_PREFIX}.xml</id>
    <title>#${POST_ID}</title>
    <content type="xhtml">
    $(cat _site/${POST_PREFIX}.html)
    </content>
    <published>${FIRST_CHANGED}</published>
    <updated>${LAST_CHANGED}</updated>
  </entry>
EOF
done
echo "Generating main feed"
cat > _site/index.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Volatile outlet of thoughts</title>
  <subtitle>a traditional microblog</subtitle>
  <link href="${WEBSITE_ROOT}" rel="self" />
  <link href="https://creativecommons.org/licenses/by/4.0/" rel="license" />
  <id>${WEBSITE_ROOT}</id>
  <author>
    <name>Michcioperz</name>
    <uri>https://meekchopp.es</uri>
    <email>public+microblog@meekchopp.es</email>
  </author>
  <generator uri="https://github.com/michcioperz/volatile.meekchopp.es" version="${GENERATOR_VERSION}">Michcioperz's Volatile (revision ${GENERATOR_VERSION})</generator>
  <updated>${LATEST_CHANGED}</updated>
EOF
for post in `ls _site/posts/*.xml | sort -V -r`
do
  echo "Adding and finalizing ${post#_site/posts/}"
  cat $post >> _site/index.xml
  sed -i '1i<?xml version="1.0" encoding="UTF-8"?>' $post
done
cat >> _site/index.xml <<EOF
</feed>
EOF
echo "Build complete."
