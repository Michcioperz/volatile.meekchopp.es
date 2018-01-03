#!/bin/bash
source config.sh
GENERATOR_VERSION=`git log -n 1 --pretty=format:%h -- build.sh`
echo "Creating directory structure"
mkdir -p _site
mkdir -p _site/posts
LATEST_CHANGED=""
for post in posts/*.markdown
do
  POST_PREFIX=${post%.markdown}
  POST_ID=${POST_PREFIX#posts/}
  POST_TITLE="#${POST_ID}"
  POST_JSON_APPENDIX="${POST_PREFIX}.json"
  if [[ -f "${POST_JSON_APPENDIX}" ]]; then
    CANDIDATE_POST_TITLE="`cat ${POST_JSON_APPENDIX} | jq -r .title`"
    if [[ -n "${CANDIDATE_POST_TITLE}" ]]; then
      POST_TITLE="${CANDIDATE_POST_TITLE}"
    fi
  fi
  POST_TITLE="`xmlstarlet esc "${POST_TITLE}"`"
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
    <link rel="self" type="application/atom+xml" href="${WEBSITE_ROOT}${POST_PREFIX}.xml" />
    <link rel="alternate" type="text/html" href="${WEBSITE_ROOT}${POST_PREFIX}.html" />
    <link rel="alternate" type="text/markdown" href="${WEBSITE_ROOT}${POST_PREFIX}.markdown" />
    <title>${POST_TITLE}</title>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
        $(cat _site/${POST_PREFIX}.html)
      </div>
    </content>
    <published>${FIRST_CHANGED}</published>
    <updated>${LAST_CHANGED}</updated>
  </entry>
EOF
  sed -i "1i<h1>${POST_TITLE}</h1>" "_site/${POST_PREFIX}.html"
done
echo "Generating main feed"
cat > _site/index.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Volatile outlet of thoughts</title>
  <subtitle>a traditional microblog</subtitle>
  <link href="${WEBSITE_ROOT}index.xml" rel="self" />
  <link href="https://creativecommons.org/licenses/by/4.0/" rel="license" />
  <id>${WEBSITE_ROOT}index.xml</id>
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
  sed -i 's/<entry>/<entry xmlns="http:\/\/www.w3.org\/2005\/Atom">/' $post
done
cat >> _site/index.xml <<EOF
</feed>
EOF
echo "Reformatting XMLs"
for i in `find _site -name "*.xml"`
do
  echo -e "\tReformatting $i"
  xmlstarlet format -s 2 "$i" > ${i%.xml}.f.xml && mv ${i%.xml}.f.xml $i || rm -rf ${i%.xml}.f.xml
done
echo "Adding the HTML index"
cp landing.html _site/index.html
echo "Build complete."
