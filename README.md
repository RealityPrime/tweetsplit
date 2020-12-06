# tweetsplit

This is a small MacOs application to split longer text chunks into individual threaded tweets, cutting at 280 minus the last whitespace. The common tweet#/total# notation is automatically appended to each tweet, keeping the total under 280 characters. To keep a punchy tweet much shorter than 280, add ___ (three underlines) and the app will respect this boundary for this tweet.

TODO: The app doesn't currently handle posting to twitter, only splitting into chunks. You can click on any computed tweet to copy it to the clipboard. Then paste into twitter, one tweet at a time.
