#!/usr/bin/env python3
import bleach, argparse, subprocess

def html2txt(filename):
    if filename.endswith('.markdown'):
        html = subprocess.check_output(['cmark', '--to', 'html', filename], universal_newlines=True)
    else:
        with open(filename) as f:
            html = f.read()
    return bleach.clean(html, tags=[], strip=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=str)
    parser.add_argument('-l', '--limit', type=int, default=500)
    args = parser.parse_args()
    text = html2txt(args.file)
    if len(text) > args.limit:
        text = text[:args.limit - 1] + "…"
    print(text)
