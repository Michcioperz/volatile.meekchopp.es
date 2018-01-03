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
  if [[ "${LAST_CHANGED}" == "${FIRST_CHANGED}" ]]; then
    sed -i "1i<h5>published: ${FIRST_CHANGED}</h5>" "_site/${POST_PREFIX}.html"
  else
    sed -i "1i<h5>published: ${FIRST_CHANGED} :: last updated: ${LAST_CHANGED}</h5>" "_site/${POST_PREFIX}.html"
  fi
  sed -i "1i<h3>${POST_TITLE}</h3>" "_site/${POST_PREFIX}.html"
done
echo "Generating main feed"
cat > _site/index.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>${WEBSITE_TITLE}</title>
  <subtitle>${WEBSITE_SUBTITLE}</subtitle>
  <link href="${WEBSITE_ROOT}index.xml" rel="self" />
  <link href="https://creativecommons.org/licenses/by/4.0/" rel="license" />
  <id>${WEBSITE_ROOT}index.xml</id>
  <author>
    <name>${WEBSITE_AUTHOR_NAME}</name>
    <uri>${WEBSITE_AUTHOR_URL}</uri>
    <email>${WEBSITE_AUTHOR_EMAIL}</email>
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
echo "Generating main HTML"
cat > _site/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width">
    <title>`xmlstarlet esc "${WEBSITE_TITLE}"`</title>
    <meta name="description" content="`xmlstarlet esc "${WEBSITE_SUBTITLE}"`">
    <meta name="generator" content="Michcioperz's Volatile (revision ${GENERATOR_VERSION})" />
    <link href="/style.css" rel="stylesheet">
    <link href="${WEBSITE_AUTHOR_URL}" rel="author">
    <link href="https://creativecommons.org/licenses/by/4.0/" rel="license">
    <link href="index.xml" rel="alternate" type="application/atom+xml">
  </head>
  <body>
    <header>
      <h1>`xmlstarlet esc "${WEBSITE_TITLE}"`</h1>
      <h2>`xmlstarlet esc "${WEBSITE_SUBTITLE}"`</h2>
    </header>
    <main>
EOF
for post in `find _site/posts -name "*.html" | xargs -n 1 basename | sort -n -r`
do
  post_id="${post%.html}"
  post="_site/posts/$post"
  echo -e "\tAdding and reformatting $post"
  cat >> _site/index.html <<EOF
      <section id="`xmlstarlet esc "$post_id"`">
        <a href="posts/$post_id.html">
EOF
  cat "$post" | sed '2i</a>' >> _site/index.html
  cat >> _site/index.html <<EOF
      </section>
EOF
  post_reformatted_file="${post%.html}.f.html"
  cat > "$post_reformatted_file" <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width">
    <title>Post #${post_id} :: `xmlstarlet esc "${WEBSITE_TITLE}"`</title>
    <meta name="generator" content="Michcioperz's Volatile (revision ${GENERATOR_VERSION})">
    <link href="${WEBSITE_AUTHOR_URL}" rel="author" />
    <link href="https://creativecommons.org/licenses/by/4.0/" rel="license" />
    <link href="${post_id}.xml" rel="self" type="application/atom+xml" />
    <link href="${post_id}.markdown" rel="alternate" type="text/markdown" />
    <link href="/style.css" rel="stylesheet" />
  </head>
  <body>
    <header>
      <h1>`xmlstarlet esc "${WEBSITE_TITLE}"`</h1>
      <h2>`xmlstarlet esc "${WEBSITE_SUBTITLE}"`</h2>
      <a href="/">posts list</a>
    </header>
    <main>
EOF
  cat "$post" >> "$post_reformatted_file"
  cat >> "$post_reformatted_file" <<EOF
    </main>
  </body>
</html>
EOF
  mv "$post_reformatted_file" "$post"
done
cat >> _site/index.html <<EOF
    </main>
  </body>
</html>
EOF
echo "Adding a stylesheet"
cp "style.css" "_site/style.css"
echo "Build complete."
