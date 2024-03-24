# pg_extism

**Note**: This is an experimental SDK.

## Getting started
Make sure [`plv8`](https://github.com/plv8/plv8) is installed:
```sql
create extension plv8;
```

Generate sql functions:
```
npm install
npm run build
```

Now you can find a `index.sql` in `dist`. Run the sql script in your database.
This gives you two functions: `extism_create_plugin`, `extism_call`.

## Use pg_extism

Assume you have a table called `plugins`:
```sql
CREATE TABLE public.plugins (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"data" bytea NULL,
	"name" varchar NULL,
	CONSTRAINT plugins_pk PRIMARY KEY (id)
);
```

Insert a few plugins into the table. And then call:

```
select extism_call(data, 'count_vowels', 'Hello World!') from plugins where id = 2;
```

**Note:** this assumes the plugin with id `2` has a function called `count_vowels`. You can find the plugin [here](https://github.com/extism/plugins/releases).