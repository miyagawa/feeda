# Feeda

feeda is a CLI tool to run actions on feed entries. Feed update is cached and the specified action is only acted on automatically detected new entries.

# Examples

Print title of new entries.

```
bundle exec ./feeda.rb http://example.com/feed 'puts title'
```

Print enclosure URL of new entries. Force all entries not just new entries.

```
bundle exec ./feeda.rb --all http://example.com/feed 'puts enclosure_url'
```

Run through system command

```
bundle exec ./feeda.rb --all http://example.com/feed 'system("curl #{enclosure_url}")'
```


