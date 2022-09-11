# matt-levine

Read Matt Levine's Bloomberg column (ARbTQlRLRjE) on Kindle.

Bloomberg RSSs contain no articles themselves, only links; raw html
doesn't contain article text either--Bloomberg 'hides' it inside a
script tag, hence this program:

1. fetches the RSS;
2. fetches articles;
3. creates a proper .html file for each article;
4. .html -> .mobi;
5. optionally sends .mobi files to your Kindle address.

## Reqs

* GNU Make
* Ruby
* `gem install nokogiri`
* curl
* Calibre (`ebook-convert` in PATH)
* mailx (optional)

## Usage

Download a bunch of article to create .mobi files:

~~~
$ git clone ...
$ mkdir -p matt-levine/_out
$ cd !$
$ ../matt-levine -j4
~~~

This creates multiple directories like so:

~~~
YYYY-MM-DD
├── YYYY-MM-DD.html
├── YYYY-MM-DD.mobi
└── YYYY-MM-DD.raw
~~~

Send a particular article to Kindle:

    ../matt-levine 2022-08-22/2022-08-22.send to=fella@example.com

'Catch-up' with the articles:

    $ rm rss.xml
    $ ../matt-levine catchup=1 m=.send

Run this a couple times a week to detect new article & automatically
send only new ones to Kindle:

    $ rm rss.xml; ../matt-levine m=.send to=fella@example.com

## License

MIT