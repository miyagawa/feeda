# Feeda

feeda is a CLI tool to run actions on feed entries. Feed update is cached and the specified action is only acted on automatically detected new entries.

# Examples

Print title of new entries:

```
./feeda.rb update http://example.com/feed -e 'puts title'
```

You can access feed elements too:

```
./feeda.rb update http://example.com/feed -e 'puts [feed.title, entry.title].join(" - ")'
```

Print enclosure URL of new entries. Force all entries not just new entries:

```
./feeda.rb update --all http://example.com/feed -e 'puts enclosure_url'
```

Run through system command:

```
./feeda.rb update http://example.com/feed -e 'system("curl #{enclosure_url}")'
```

Or in a more UNIX way:

```
./feeda.rb update http://example.com/feed -e 'puts enclosure_url' | head -5 | xargs -n1 curl
```
