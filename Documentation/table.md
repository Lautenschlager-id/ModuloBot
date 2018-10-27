## Static Methods
### clone(list, ignoreList)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| list | table |  |
>| ignoreList | table |  |
>
>Copies a table (not deeply) ignoring given indexes.
>
>**Returns:** `table`

### find(list, value, index, f)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| list | table |  |
>| value | string\|int\|boolean |  |
>| index | string\|int | ✔ |
>| f | function | ✔ |
>
>Verifies if a certain value exists in a table and returns the index.

### map(list, f)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| list | table |  |
>| f | function |  |
>
>Iters over the table inserting the value modified with a given function.
>
>**Returns:** `table`

### sum(src, add)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| src | table |  |
>| add | table |  |
>
>Returns a new table containing all the values of `src` and `add`.
>
>**Returns:** `table`

### random(list)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| list | table |  |
>
>Returns a random value of the given table.
>
>**Returns:** `*`

### tostring(list, depth, stop)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| list | table |  |
>
>Transforms a table into a string.
>
>**Returns:** `string`
