# matt-levine

Read Matt Levine's Bloomberg column (ARbTQlRLRjE) on Kindle.

<img style="width: 100%" src="https://sigwait.tk/~alex/junk/matt-levine.ss.gif">

Bloomberg RSS feeds contain no articles themselves, only links; raw
html doesn't contain article text either--Bloomberg 'hides' it inside
a script tag, hence this program:

1. fetches the RSS;
2. fetches articles;
3. creates a proper .html file for each article;
4. .html -> .mobi/.epub;
5. optionally sends .mobi/.epub files to your Kindle address.

## Reqs

* GNU Make
* Ruby 3.1+, `gem install nokogiri`
* `npm i puppeteer`
* curl
* mobi creation: Calibre (`ebook-convert` in PATH)
* epub creation: zip(1)
* optionally: mailx(1)

## Usage

Download a bunch of articles to generate .mobi files:

~~~
$ git clone https://github.com/gromnitsky/matt-levine
$ mkdir matt-levine/_out
$ cd !$
$ ../matt-levine
~~~

(In FreeBSD, run the last cmd as `gmake ../matt-levine`.)

This creates multiple directories like so:

~~~
YYYY-MM-DD
├── YYYY-MM-DD.html
├── YYYY-MM-DD.mobi
└── YYYY-MM-DD.raw
~~~

Send a particular article to Kindle (requires mailx(1) installed & a
working local MTA):

    ../matt-levine 2022-08-22/2022-08-22.send to=fella@example.com

'Catch-up' with the articles:

    $ rm rss.xml
    $ ../matt-levine catchup=1 to=@

Run this a couple times a week to detect new articles & automatically
send *only new ones* to Kindle:

    $ rm rss.xml; ../matt-levine to=fella@example.com

To create .epub files instead of .mobi, add `f=epub` argument. For
help, run `../matt-levine help`.

## License

MIT
