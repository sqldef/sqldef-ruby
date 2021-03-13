# sqldef-ruby

Ruby interface to call [sqldef](https://github.com/k0kubun/sqldef).

## Installation

```ruby
gem 'sqldef'
```

## Usage
### Download

You can download `mysqldef`, `psqldef`, or `sqlite3def`.

```rb
Sqldef.bin = './bin'
Sqldef.download(:psqldef)
```

`download` is automatically executed by the following methods too.

### Export

You can export the database schema to a file.

```rb
Sqldef.export(
  command:  :psqldef,
  host:     host,
  port:     port,
  user:     user,
  password: password,
  database: database,
  path:     'db/schema.sql',
)
```

### Dry Run

You can show DDLs to be executed.

```rb
Sqldef.dry_run(
  command:  :psqldef,
  host:     host,
  port:     port,
  user:     user,
  password: password,
  database: database,
  path:     'db/schema.sql',
)
```

### Apply

You can run DDLs to match the schema.

```rb
Sqldef.apply(
  command:  :psqldef,
  host:     host,
  port:     port,
  user:     user,
  password: password,
  database: database,
  path:     'db/schema.sql',
)
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
